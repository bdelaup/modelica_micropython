/* Moteur I2C cible : decodage du bus et pilotage de SDA (cf. i2ctarget.h).

   PILOTE PAR LES FRONTS, pas par des echeances : la cible n'a pas d'horloge
   propre, elle suit celle du maitre. L'hote appelle i2ct_sync() a chaque point
   de synchro avec les niveaux courants, et le moteur les compare a ceux de
   l'appel precedent :
     SDA descend pendant que SCL est haute   -> START (ou START repete)
     SDA monte pendant que SCL est haute     -> STOP
     SCL monte                               -> un bit est lu (octet recu) ou
                                                l'ACK du maitre est lu (lecture)
     SCL descend                             -> la cible positionne SDA pour le
                                                bit suivant : ACK, bit de donnee
                                                lue, ou relache
   Changer SDA juste apres le front descendant de SCL garantit que la cible ne
   fabrique jamais de faux START/STOP : la ligne bouge pendant que SCL est basse.

   Rappeler i2ct_sync() au MEME instant avec les memes niveaux ne fait rien : il
   n'y a pas de front. C'est ce qui le rend sur face aux iterations d'evenements
   de Modelica.

   Inclus TEXTUELLEMENT par un chapeau, apres i2ctarget.h, jamais compile seul. */

#ifndef I2CTARGET_C_INCLUDED
#define I2CTARGET_C_INCLUDED

static void i2ct_init(struct I2cTarget* t, const struct I2cTargetHooks* hooks, void* ctx) {
    int n_addr = t->n_addr;
    int addresses[I2CT_MAX_ADDR];
    memcpy(addresses, t->addresses, sizeof(addresses));
    memset(t, 0, sizeof(*t));
    memcpy(t->addresses, addresses, sizeof(addresses));
    t->n_addr = n_addr;
    t->state = I2CT_IDLE;
    t->hooks = hooks;
    t->ctx = ctx;
}

/* Clot la phase en cours (sur STOP, START repete, ou NACK du maitre en lecture).
   UNE SEULE FOIS par phase : c'est ce qui permet a un script d'y loger une
   machine d'etat sans qu'elle rejoue ses transitions. */
static void i2ct_close_phase(struct I2cTarget* t) {
    if (t->write_open) {
        t->write_open = 0;
        if (t->hooks->write_end) {
            t->hooks->write_end(t->ctx, t->addr, t->wbuf, t->wlen);
        }
        t->wlen = 0;
    }
    if (t->read_open) {
        t->read_open = 0;
        t->read_deferred = 0;
        if (t->hooks->read_end) {
            t->hooks->read_end(t->ctx, t->addr, t->rlog, t->rlog_len);
        }
        t->rlog_len = 0;
    }
}

/* Bit numero 7-nbits de l'octet a sortir : un 0 tire SDA, un 1 la relache. */
static void i2ct_drive_bit(struct I2cTarget* t) {
    t->drive_low = !((t->cur >> (7 - t->nbits)) & 1);
}

static void i2ct_take_byte(struct I2cTarget* t, int b) {
    t->cur = (unsigned char) (b < 0 ? 0xFF : b);
    if (t->rlog_len < I2CT_BUF_MAX) {
        t->rlog[t->rlog_len++] = t->cur;
    }
    i2ct_drive_bit(t);
}

/* Octet suivant a sortir en lecture. Si l'hote le differe, SDA reste relachee
   jusqu'a i2ct_resume(), au meme instant. */
static void i2ct_load_read_byte(struct I2cTarget* t) {
    int b = t->hooks->read_byte ? t->hooks->read_byte(t->ctx, t->addr, 1) : 0xFF;
    if (b == I2CT_DEFER) {
        t->read_deferred = 1;
        t->drive_low = 0;
        return;
    }
    i2ct_take_byte(t, b);
}

/* Fournit l'octet differe (l'hote a laisse son programme le preparer). */
static void i2ct_resume(struct I2cTarget* t) {
    if (!t->read_deferred) {
        return;
    }
    t->read_deferred = 0;
    i2ct_take_byte(t, t->hooks->read_byte ? t->hooks->read_byte(t->ctx, t->addr, 0) : 0xFF);
}

static int i2ct_matches(const struct I2cTarget* t, int addr) {
    int k;
    for (k = 0; k < t->n_addr; k++) {
        if (t->addresses[k] == addr) {
            return 1;
        }
    }
    return 0;
}

static void i2ct_on_start(struct I2cTarget* t) {
    i2ct_close_phase(t);
    t->state = I2CT_ADDR;
    t->nbits = 0;
    t->shift = 0;
    t->drive_low = 0;
}

static void i2ct_on_stop(struct I2cTarget* t) {
    i2ct_close_phase(t);
    t->state = I2CT_IDLE;
    t->drive_low = 0;
}

static void i2ct_on_scl_rise(struct I2cTarget* t, int sda) {
    switch (t->state) {
    case I2CT_ADDR:
    case I2CT_WRITE:
        if (t->nbits < 8) {
            t->shift = ((t->shift << 1) | (unsigned int) (sda ? 1 : 0)) & 0xFF;
        }
        break;
    case I2CT_READ:
        if (t->nbits == 8) {
            t->master_ack = !sda;
        }
        break;
    default:
        return;
    }
    /* Les impulsions se comptent sur les fronts MONTANTS : le front descendant
       qui suit un START n'est pas un coup d'horloge de donnee. */
    t->nbits++;
}

/* nbits = nombre d'impulsions deja vues dans l'octet courant (compte au front
   montant). Au front descendant qui suit la n-ieme, on prepare le bit n+1. */
static void i2ct_on_scl_fall(struct I2cTarget* t) {
    if (t->state == I2CT_IDLE || t->state == I2CT_WAIT) {
        t->drive_low = 0;
        return;
    }
    if (t->nbits == 0) {
        return;   /* SCL qui descend juste apres un START : aucun bit encore */
    }

    if (t->nbits == 8) {
        /* 8 bits passes : place du bit d'acquittement */
        switch (t->state) {
        case I2CT_ADDR: {
            int addr = (int) (t->shift >> 1);
            if (i2ct_matches(t, addr)) {
                t->addr = addr;
                t->drive_low = 1;          /* ACK */
                if (t->hooks->addr_match) {
                    t->hooks->addr_match(t->ctx, addr, (int) (t->shift & 1));
                }
            } else {
                t->state = I2CT_WAIT;      /* pas pour nous : silence jusqu'au STOP/START */
                t->drive_low = 0;
            }
            break;
        }
        case I2CT_WRITE:
            if (t->wlen < I2CT_BUF_MAX) {
                t->wbuf[t->wlen++] = (unsigned char) t->shift;
            }
            t->drive_low = 1;              /* ACK : on accepte tout octet */
            if (t->hooks->write_byte) {
                t->hooks->write_byte(t->ctx, t->addr, (unsigned char) t->shift);
            }
            break;
        case I2CT_READ:
            t->drive_low = 0;              /* c'est le maitre qui acquitte */
            break;
        default:
            break;
        }
        return;
    }

    if (t->nbits == 9) {
        /* bit d'acquittement termine : octet suivant */
        int rw = (int) (t->shift & 1);
        t->nbits = 0;
        t->shift = 0;
        switch (t->state) {
        case I2CT_ADDR:
            if (rw) {
                t->state = I2CT_READ;
                t->read_open = 1;
                t->rlog_len = 0;
                i2ct_load_read_byte(t);
            } else {
                t->state = I2CT_WRITE;
                t->write_open = 1;
                t->wlen = 0;
                t->drive_low = 0;
            }
            break;
        case I2CT_WRITE:
            t->drive_low = 0;
            break;
        case I2CT_READ:
            if (t->master_ack) {
                i2ct_load_read_byte(t);
            } else {
                /* NACK : le maitre a lu son dernier octet */
                i2ct_close_phase(t);
                t->state = I2CT_WAIT;
                t->drive_low = 0;
            }
            break;
        default:
            t->drive_low = 0;
            break;
        }
        return;
    }

    /* bits 1 a 7 de l'octet */
    if (t->state == I2CT_READ) {
        i2ct_drive_bit(t);
    }
}

/* Point de synchro : niveaux courants de SCL et SDA (0/1). Retourne drive_low. */
static int i2ct_sync(struct I2cTarget* t, int scl, int sda) {
    scl = scl ? 1 : 0;
    sda = sda ? 1 : 0;
    if (!t->levels_known) {
        /* premier appel : simple releve, aucun front a interpreter */
        t->levels_known = 1;
        t->scl = scl;
        t->sda = sda;
    } else if (scl != t->scl) {
        /* Front d'horloge. Si SDA a change en meme temps (cas degenere : lignes
           qui montent ensemble a la mise sous tension), ce n'est ni un START ni
           un STOP : on prend seulement le nouveau niveau. */
        t->scl = scl;
        if (scl) {
            i2ct_on_scl_rise(t, sda);
        } else {
            i2ct_on_scl_fall(t);
        }
        t->sda = sda;
    } else if (sda != t->sda) {
        t->sda = sda;
        if (scl) {
            if (!sda) {
                i2ct_on_start(t);
            } else {
                i2ct_on_stop(t);
            }
        }
    }
    return t->drive_low;
}

static int i2ct_busy(const struct I2cTarget* t) {
    return (t->state == I2CT_WRITE || t->state == I2CT_READ) ? 1 : 0;
}

#endif /* I2CTARGET_C_INCLUDED */
