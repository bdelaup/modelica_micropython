/* Moteur d'un peripherique I2C esclave : decodage du bus, construction, point de
   synchro appele par Modelica.

   Inclus TEXTUELLEMENT par I2cDeviceImpl.c, jamais compile seul.

   PILOTE PAR LES FRONTS, pas par des echeances : l'esclave n'a pas d'horloge
   propre, il suit celle du maitre. Le "when" de Internal.PartialI2cDevice se
   declenche a chaque franchissement de seuil de SCL ou de SDA, et I2cDevice_sync
   compare les niveaux recus a ceux du dernier appel :
     SDA descend pendant que SCL est haute   -> START (ou START repete)
     SDA monte pendant que SCL est haute     -> STOP
     SCL monte                               -> un bit est lu (octet recu) ou
                                                l'ACK du maitre est lu (lecture)
     SCL descend                             -> l'esclave positionne SDA pour le
                                                bit suivant : ACK, bit de donnee
                                                lue, ou relache
   Changer SDA juste apres le front descendant de SCL garantit qu'un esclave ne
   fabrique jamais de faux START/STOP : la ligne bouge pendant que SCL est basse.

   Rappeler la fonction au MEME instant avec les memes niveaux ne fait rien : il
   n'y a pas de front. C'est ce qui la rend sure face aux iterations d'evenements
   de Modelica, comme UartDevice_sync. */

#ifndef I2CDEVICE_ENGINE_C_INCLUDED
#define I2CDEVICE_ENGINE_C_INCLUDED

/* ===================== journal ===================== */

/* "ecriture 0x3E : 80 01" / "lecture 0x42 : 48 69" (tronque si long). */
static void i2cdev_log(struct I2cDevice* dev, const char* what, int addr, const unsigned char* data, int len) {
    int pos, k;
    pos = snprintf(dev->last_event, I2CDEV_EVENT_MAX + 1, "%s 0x%02X :", what, addr);
    for (k = 0; k < len && pos < I2CDEV_EVENT_MAX - 4; k++) {
        pos += snprintf(dev->last_event + pos, (size_t) (I2CDEV_EVENT_MAX + 1 - pos), " %02X", data[k]);
    }
    if (k < len && pos < I2CDEV_EVENT_MAX - 3) {
        snprintf(dev->last_event + pos, (size_t) (I2CDEV_EVENT_MAX + 1 - pos), " ...");
    }
    dev->event_seq++;
}

/* ===================== phases ===================== */

/* Clot la phase en cours (sur STOP, START repete, ou NACK du maitre en lecture).
   UNE SEULE FOIS par phase : c'est ce qui permet a un script d'y loger une
   machine d'etat sans qu'elle rejoue ses transitions. */
static void i2cdev_close_phase(struct I2cDevice* dev) {
    if (dev->write_open) {
        dev->write_open = 0;
        /* Une ecriture vide est une sonde d'adresse (scan()) : rien a livrer. */
        if (dev->wlen > 0) {
            i2cdev_script_on_write(dev, dev->addr, dev->wbuf, dev->wlen);
            i2cdev_log(dev, "ecriture", dev->addr, dev->wbuf, dev->wlen);
        }
        dev->wlen = 0;
    }
    if (dev->read_open) {
        dev->read_open = 0;
        i2cdev_log(dev, "lecture", dev->addr, dev->rlog, dev->rlog_len);
        dev->rlog_len = 0;
    }
}

/* Octet suivant a sortir en lecture ; on_read() est (re)appelee quand le lot
   precedent est epuise, et la ligne reste relachee (0xFF) s'il ne rend rien. */
static void i2cdev_load_read_byte(struct I2cDevice* dev) {
    if (dev->rpos >= dev->rlen) {
        dev->rlen = i2cdev_script_on_read(dev, dev->addr);
        dev->rpos = 0;
    }
    dev->cur = dev->rpos < dev->rlen ? dev->rbuf[dev->rpos++] : 0xFF;
    if (dev->rlog_len < I2CDEV_BUF_MAX) {
        dev->rlog[dev->rlog_len++] = dev->cur;
    }
}

/* Bit numero 7-nbits de l'octet a sortir : un 0 tire SDA, un 1 la relache. */
static void i2cdev_drive_bit(struct I2cDevice* dev) {
    dev->drive_low = !((dev->cur >> (7 - dev->nbits)) & 1);
}

static int i2cdev_matches(const struct I2cDevice* dev, int addr) {
    int k;
    for (k = 0; k < dev->n_addr; k++) {
        if (dev->addresses[k] == addr) {
            return 1;
        }
    }
    return 0;
}

/* ===================== fronts ===================== */

static void i2cdev_on_start(struct I2cDevice* dev) {
    i2cdev_close_phase(dev);
    dev->state = I2CDEV_ADDR;
    dev->nbits = 0;
    dev->shift = 0;
    dev->drive_low = 0;
}

static void i2cdev_on_stop(struct I2cDevice* dev) {
    i2cdev_close_phase(dev);
    dev->state = I2CDEV_IDLE;
    dev->drive_low = 0;
}

static void i2cdev_on_scl_rise(struct I2cDevice* dev, int sda) {
    switch (dev->state) {
    case I2CDEV_ADDR:
    case I2CDEV_WRITE:
        if (dev->nbits < 8) {
            dev->shift = ((dev->shift << 1) | (unsigned int) (sda ? 1 : 0)) & 0xFF;
        }
        break;
    case I2CDEV_READ:
        if (dev->nbits == 8) {
            dev->master_ack = !sda;
        }
        break;
    default:
        return;
    }
    /* Les impulsions se comptent sur les fronts MONTANTS : le front descendant
       qui suit un START n'est pas un coup d'horloge de donnee. */
    dev->nbits++;
}

/* nbits = nombre d'impulsions deja vues dans l'octet courant (compte au front
   montant). Au front descendant qui suit la n-ieme, on prepare le bit n+1. */
static void i2cdev_on_scl_fall(struct I2cDevice* dev) {
    if (dev->state == I2CDEV_IDLE || dev->state == I2CDEV_WAIT) {
        dev->drive_low = 0;
        return;
    }
    if (dev->nbits == 0) {
        return;   /* SCL qui descend juste apres un START : aucun bit encore */
    }

    if (dev->nbits == 8) {
        /* 8 bits passes : place du bit d'acquittement */
        switch (dev->state) {
        case I2CDEV_ADDR: {
            int addr = (int) (dev->shift >> 1);
            if (i2cdev_matches(dev, addr)) {
                dev->addr = addr;
                dev->drive_low = 1;          /* ACK */
            } else {
                dev->state = I2CDEV_WAIT;    /* pas pour nous : silence jusqu'au STOP/START */
                dev->drive_low = 0;
            }
            break;
        }
        case I2CDEV_WRITE:
            if (dev->wlen < I2CDEV_BUF_MAX) {
                dev->wbuf[dev->wlen++] = (unsigned char) dev->shift;
            }
            dev->drive_low = 1;              /* ACK : on accepte tout octet en v0 */
            break;
        case I2CDEV_READ:
            dev->drive_low = 0;              /* c'est le maitre qui acquitte */
            break;
        default:
            break;
        }
        return;
    }

    if (dev->nbits == 9) {
        /* bit d'acquittement termine : octet suivant */
        int rw = (int) (dev->shift & 1);
        dev->nbits = 0;
        dev->shift = 0;
        switch (dev->state) {
        case I2CDEV_ADDR:
            if (rw) {
                dev->state = I2CDEV_READ;
                dev->read_open = 1;
                dev->rlen = 0;
                dev->rpos = 0;
                dev->rlog_len = 0;
                i2cdev_load_read_byte(dev);
                i2cdev_drive_bit(dev);
            } else {
                dev->state = I2CDEV_WRITE;
                dev->write_open = 1;
                dev->wlen = 0;
                dev->drive_low = 0;
            }
            break;
        case I2CDEV_WRITE:
            dev->drive_low = 0;
            break;
        case I2CDEV_READ:
            if (dev->master_ack) {
                i2cdev_load_read_byte(dev);
                i2cdev_drive_bit(dev);
            } else {
                /* NACK : le maitre a lu son dernier octet */
                i2cdev_close_phase(dev);
                dev->state = I2CDEV_WAIT;
                dev->drive_low = 0;
            }
            break;
        default:
            dev->drive_low = 0;
            break;
        }
        return;
    }

    /* bits 1 a 7 de l'octet */
    if (dev->state == I2CDEV_READ) {
        i2cdev_drive_bit(dev);
    }
}

/* ===================== API exportee ===================== */

/* "0x3E, 0x62" -> {0x3E, 0x62}. Hexadecimal ou decimal (strtol base 0),
   separateurs virgule, point-virgule ou espace. */
static int i2cdev_parse_addresses(struct I2cDevice* dev, const char* s) {
    const char* p = s ? s : "";
    dev->n_addr = 0;
    while (*p) {
        char* end;
        long v;
        while (*p == ' ' || *p == ',' || *p == ';' || *p == '\t') {
            p++;
        }
        if (!*p) {
            break;
        }
        v = strtol(p, &end, 0);
        if (end == p) {
            ModelicaFormatError("I2cDevice : adresse illisible dans \"%s\" (ex. attendu : \"0x42\" ou \"0x3E, 0x62\")", s);
            return -1;
        }
        if (v < 0 || v > 0x7F) {
            ModelicaFormatError("I2cDevice : adresse %ld hors bornes (0x00-0x7F, adresse sur 7 bits) dans \"%s\"", v, s);
            return -1;
        }
        if (dev->n_addr >= I2CDEV_MAX_ADDR) {
            ModelicaFormatError("I2cDevice : au plus %d adresses par composant (\"%s\")", I2CDEV_MAX_ADDR, s);
            return -1;
        }
        dev->addresses[dev->n_addr++] = (int) v;
        p = end;
    }
    if (dev->n_addr == 0) {
        ModelicaFormatError("I2cDevice : aucune adresse donnee - indiquer par exemple \"0x42\"");
        return -1;
    }
    return 0;
}

void* I2cDevice_new(const char* addresses, const char* scriptPath,
                     const char* pythonHome, const char* instanceName) {
    struct I2cDevice* dev = (struct I2cDevice*) calloc(1, sizeof(struct I2cDevice));
    if (!dev) {
        ModelicaFormatError("I2cDevice : allocation impossible");
        return NULL;
    }
    if (i2cdev_parse_addresses(dev, addresses) != 0) {
        return NULL;
    }
    if (strlen(scriptPath ? scriptPath : "") > I2CDEV_PATH_MAX) {
        ModelicaFormatError("I2cDevice : chemin de script trop long");
        return NULL;
    }
    strcpy(dev->script_path, scriptPath ? scriptPath : "");
    dev->state = I2CDEV_IDLE;
    i2cdev_script_load(dev, pythonHome, instanceName);
    return (void*) dev;
}

void I2cDevice_destroy(void* dev_) {
    /* Meme choix delibere que PyRuntime_destroy et UartDevice_destroy : chaque
       simulation tourne dans son propre process, l'OS recupere tout. */
    (void) dev_;
}

static const char* i2cdev_modelica_string(const char* s) {
    char* out = ModelicaAllocateString(strlen(s));
    strcpy(out, s);
    return out;
}

void I2cDevice_sync(void* dev_, double currentTime, int sclLevel, int sdaLevel, const double* valueIn,
                     double* valueOut, int* sdaDriveLowOut, int* busyOut, int* eventSeqOut,
                     const char** lastEventOut, const char** line1Out, const char** line2Out) {
    struct I2cDevice* dev = (struct I2cDevice*) dev_;
    int scl = sclLevel ? 1 : 0;
    int sda = sdaLevel ? 1 : 0;
    int k;

    dev->now = currentTime;
    for (k = 0; k < I2CDEV_MAX_VALUES; k++) {
        dev->value_in[k] = valueIn[k];
    }

    if (!dev->levels_known) {
        /* premier appel : simple releve, aucun front a interpreter */
        dev->levels_known = 1;
        dev->scl = scl;
        dev->sda = sda;
    } else if (scl != dev->scl) {
        /* Front d'horloge. Si SDA a change en meme temps (cas degenere : lignes
           qui montent ensemble a la mise sous tension), ce n'est ni un START ni
           un STOP : on prend seulement le nouveau niveau. */
        dev->scl = scl;
        if (scl) {
            i2cdev_on_scl_rise(dev, sda);
        } else {
            i2cdev_on_scl_fall(dev);
        }
        dev->sda = sda;
    } else if (sda != dev->sda) {
        dev->sda = sda;
        if (scl) {
            if (!sda) {
                i2cdev_on_start(dev);
            } else {
                i2cdev_on_stop(dev);
            }
        }
    }

    for (k = 0; k < I2CDEV_MAX_VALUES; k++) {
        valueOut[k] = dev->value_out[k];
    }
    *sdaDriveLowOut = dev->drive_low;
    *busyOut = (dev->state == I2CDEV_WRITE || dev->state == I2CDEV_READ) ? 1 : 0;
    *eventSeqOut = dev->event_seq;
    *lastEventOut = i2cdev_modelica_string(dev->last_event);
    *line1Out = i2cdev_modelica_string(dev->line1);
    *line2Out = i2cdev_modelica_string(dev->line2);
}

#endif /* I2CDEVICE_ENGINE_C_INCLUDED */
