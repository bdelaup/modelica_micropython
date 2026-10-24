/* microbit.radio : moteur de paquets de la radio 2,4 GHz embarquee de la
   micro:bit v2 (profil "microbit"), cf. requirements.md decision "Radios
   micro:bit".

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul.

   Modele : le protocole par paquets du firmware (radio.on/off/config/send/
   receive, filtrage channel/group/address, file de reception de profondeur
   queue, troncation a length) vit ENTIEREMENT ici, cote C - pas de forme
   d'onde a tracer, une trame a 1 ou 2 Mbit/s serait des milliers de points de
   synchro par paquet. La TOPOLOGIE, elle, vient du schema : le modele passe
   a PyRuntime_sync l'identifiant du reseau radio porte par l'antenne (une
   liaison logique vers un Peripherals.Radio.RadioAir, qui donne son
   identifiant a toutes les antennes cablees a lui) ; deux moteurs
   s'entendent s'ils partagent ce meme identifiant.

   Threadage : tous les constructeurs (PyRuntime_new) et destructeurs passent
   sur le thread Modelica avant t=0 et en fin de simulation - le registre
   ci-dessous n'est touche que la. Un ENVOI s'execute sur le thread worker de
   l'emetteur, pendant que le thread Modelica est bloque DANS la synchro de
   l'emetteur (la discipline de tour n'autorise qu'un worker a la fois, cf.
   pyruntime_core.h) : la file d'arrivee du recepteur n'a donc jamais deux
   proprietaires simultanes. Le verrou global g_radio_cs reste pose autour de
   chaque acces (inbox et registre), pour la visibilite memoire entre threads
   et par robustesse future ; aucun cycle ne peut naitre : un emetteur ne
   prend jamais le cs d'un autre handle, et les deux disciplines (worker :
   son cs puis g_radio_cs ; thread Modelica : cs du handle puis g_radio_cs)
   respectent le meme ordre. Les avertissements de paquets perdus, eux, ne
   partent QUE du thread Modelica (radio_step : la GIL n'y est pas tenue,
   ModelicaFormatWarning est le canal idoine, meme discipline que les erreurs
   UART) ; les envois depuis le worker previennent par PyErr_WarnEx, remonte
   au journal par le relais stderr. */

/* Registre des moteurs radio du process : un par microcontroleur construit
   avec useRadio. Initialisation paresseuse mais en pratique au premier
   PyRuntime_new (thread Modelica, avant tout worker). */
static struct PyRuntimeHandle* g_radio_registry[RADIO_REGISTRY_MAX];
static int g_radio_registry_len = 0;
static CRITICAL_SECTION g_radio_cs;
static int g_radio_cs_ready = 0;

static void radio_cs_init(void) {
    if (!g_radio_cs_ready) {
        InitializeCriticalSection(&g_radio_cs);
        g_radio_cs_ready = 1;
    }
}

/* Valeurs par defaut du firmware : calloc met tout a zero, l'init est
   explicite (requis par PyRuntime_new, avant la premiere synchro). */
static void radio_engine_init(struct PyRuntimeHandle* h) {
    h->radio.on = 0;
    h->radio.network_id = -1;
    h->radio.length = RADIO_DEFAULT_LENGTH;
    h->radio.queue = RADIO_DEFAULT_QUEUE;
    h->radio.channel = RADIO_DEFAULT_CHANNEL;
    h->radio.group = RADIO_DEFAULT_GROUP;
    h->radio.address = RADIO_DEFAULT_ADDRESS;
    h->radio.power = RADIO_DEFAULT_POWER;
    h->radio.data_rate = 1;
    h->radio.inbox_len = 0;
    h->radio.rx_len = 0;
    h->radio.rx_dropped = 0;
    h->radio.warned = 0;
}

/* Thread Modelica (PyRuntime_new) : enregistre le moteur. Au-dela de
   RADIO_REGISTRY_MAX microcontroleurs avec radio, les suivants n'en ont
   simplement pas (cas d'ecole : mieux vaut un message clair qu'une limite
   silencieuse fausse). */
static void radio_registry_add(struct PyRuntimeHandle* h) {
    radio_cs_init();
    EnterCriticalSection(&g_radio_cs);
    if (g_radio_registry_len < RADIO_REGISTRY_MAX) {
        g_radio_registry[g_radio_registry_len++] = h;
    } else {
        ModelicaFormatWarning("PyRuntime (%s): more than %d radio-equipped microcontrollers in the model - "
                              "this one gets no radio\n", h->instanceName, RADIO_REGISTRY_MAX);
    }
    LeaveCriticalSection(&g_radio_cs);
}

/* Thread Modelica (PyRuntime_destroy) : retire le moteur, pour ne pas
   laisser des paquets partir vers un handle detruit. */
static void radio_registry_remove(struct PyRuntimeHandle* h) {
    int i, j;
    if (!g_radio_cs_ready) {
        return;
    }
    EnterCriticalSection(&g_radio_cs);
    for (i = 0; i < g_radio_registry_len; i++) {
        if (g_radio_registry[i] == h) {
            for (j = i; j < g_radio_registry_len - 1; j++) {
                g_radio_registry[j] = g_radio_registry[j + 1];
            }
            g_radio_registry_len--;
            break;
        }
    }
    LeaveCriticalSection(&g_radio_cs);
}

/* Paquets perdus : avertissement plafonne, meme discipline que les erreurs
   UART. Thread Modelica uniquement (radio_step, radio_report) : warned suit
   le nombre de pertes deja signalees - des pertes comptees par un emetteur
   (thread worker, file d'arrivee pleine) sont ainsi rattrapees au prochain
   passage du recepteur. */
static void radio_warn_drop(struct PyRuntimeHandle* h) {
    if (h->radio.rx_dropped <= h->radio.warned || h->radio.warned >= RADIO_WARN_MAX) {
        return;
    }
    h->radio.warned = h->radio.rx_dropped;
    ModelicaFormatWarning("PyRuntime (%s): radio: dropped packets (%d so far, receive queue full or packets in flight) - "
                          "raise queue in radio.config(), or read with receive() more often\n",
                          h->instanceName, h->radio.rx_dropped);
}

/* Livraison : appelee par PyRuntime_sync a chaque point de synchro. Sort de
   la file d'arrivee les paquets dont l'instant est atteint, filtre comme le
   materiel (le canal est une frequence physique, l'adresse et le groupe sont
   dans l'en-tete emis, compares a la config du RECEPTEUR) et met en file de
   reception a la profondeur queue - la plus ancienne part la premiere, les
   nouveaux sont jetes quand la file est pleine. Tronque le contenu a length,
   comme la reception du firmware. Rien n'est livre si la radio est eteinte. */
static void radio_step(struct PyRuntimeHandle* h, double now) {
    int i, j;
    radio_warn_drop(h);
    if (!h->radio.on || h->radio.inbox_len == 0) {
        return;
    }
    EnterCriticalSection(&g_radio_cs);
    for (i = 0; i < h->radio.inbox_len; ) {
        struct RadioPacket* p = &h->radio.inbox[i];
        if (p->arrival > now + PYRUNTIME_EPS) {
            break;
        }
        if (p->channel == h->radio.channel && p->group == h->radio.group
                && p->address == h->radio.address) {
            if (h->radio.rx_len < h->radio.queue) {
                struct RadioPacket* dst = &h->radio.rx[h->radio.rx_len];
                *dst = *p;
                if (dst->len > h->radio.length) {
                    dst->len = h->radio.length;
                }
                h->radio.rx_len++;
            } else {
                h->radio.rx_dropped++;
                radio_warn_drop(h);
            }
        }
        /* sorti de l'air (livre ou filtre) : compacter la file d'arrivee */
        for (j = i; j < h->radio.inbox_len - 1; j++) {
            h->radio.inbox[j] = h->radio.inbox[j + 1];
        }
        h->radio.inbox_len--;
    }
    LeaveCriticalSection(&g_radio_cs);
}

/* Plus proche arrivee radio, ou 1e300 si rien ne vole vers ce moteur : entre
   dans le calcul du prochain reveil cote Modelica, pour qu'un recepteur qui
   ne dort pas se reveille a l'arrivee exacte du paquet. La file d'arrivee
   est triee par arrival croissante (radio_send insere), l'indice 0 suffit. */
static double earliest_radio_deadline(struct PyRuntimeHandle* h) {
    double t;
    if (!h->radio.inbox_len) {
        return 1.0e300;
    }
    EnterCriticalSection(&g_radio_cs);
    t = h->radio.inbox_len ? h->radio.inbox[0].arrival : 1.0e300;
    LeaveCriticalSection(&g_radio_cs);
    return t;
}

/* Emission : native_radio_send_bytes (thread worker de l'emetteur, son
   propre cs tenu par l'appelant). Pose le paquet dans la file d'arrivee de
   chaque moteur du MEME reseau dont la radio est allumee (l'emetteur ne
   s'entend pas), triee par arrival croissante ; l'instant de livraison
   couvre la trame a l'air (contenu plus l'en-tete de RADIO_OVERHEAD octets
   au debit data_rate). Renvoie le nombre de moteurs qui ecoutent. */
static int radio_send(struct PyRuntimeHandle* h, const unsigned char* data, int len) {
    double arrival;
    int k, i, heard = 0;
    if (len > h->radio.length) {
        len = h->radio.length;   /* le firmware emet au plus length octets */
    }
    arrival = h->sim_time + (len + RADIO_OVERHEAD) * 8.0 / (h->radio.data_rate * 1.0e6);
    EnterCriticalSection(&g_radio_cs);
    for (k = 0; k < g_radio_registry_len; k++) {
        struct PyRuntimeHandle* dst = g_radio_registry[k];
        struct RadioPacket* p;
        if (dst == h || !dst->radio.on
                || dst->radio.network_id != h->radio.network_id) {
            continue;
        }
        heard++;
        if (dst->radio.inbox_len >= RADIO_INBOX_MAX) {
            dst->radio.rx_dropped++;   /* rattrape par radio_warn_drop du recepteur */
            continue;
        }
        /* insertion triee par arrival croissante, apres les arrivals egaux */
        for (i = dst->radio.inbox_len; i > 0; i--) {
            if (dst->radio.inbox[i - 1].arrival <= arrival) {
                break;
            }
            dst->radio.inbox[i] = dst->radio.inbox[i - 1];
        }
        p = &dst->radio.inbox[i];
        p->arrival = arrival;
        p->channel = h->radio.channel;
        p->group = h->radio.group;
        p->address = h->radio.address;
        memcpy(p->payload, data, len);
        p->len = len;
        dst->radio.inbox_len++;
    }
    LeaveCriticalSection(&g_radio_cs);
    return heard;
}

/* Bilan de fin de simulation (thread Modelica, PyRuntime_destroy) :
   statistiques de pertes, meme esprit que uart_report_errors. */
static void radio_report(struct PyRuntimeHandle* h) {
    radio_warn_drop(h);
}

/* ---- primitives natives exposees au shim (thread worker) ---- */

/* Le shim n'expose le module radio que sur le profil microbit ; la garde
   reste ici, la native pouvant etre appelee directement. */
static int radio_profile_ok(void) {
    return strcmp(g_current->board_profile, "microbit") == 0;
}

static PyObject* native_radio_on(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    if (!radio_profile_ok()) {
        PyErr_SetString(PyExc_RuntimeError, "radio exists only on the micro:bit profile");
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    if (g_current->radio.network_id < 0) {
        LeaveCriticalSection(&g_current->cs);
        PyErr_SetString(PyExc_RuntimeError,
                        "radio.on(): the antenna is not wired - wire the Antenna port of the board "
                        "to the antenna of a Peripherals.Radio.RadioAir in the diagram");
        return NULL;
    }
    g_current->radio.on = 1;
    LeaveCriticalSection(&g_current->cs);
    Py_RETURN_NONE;
}

static PyObject* native_radio_off(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    if (!radio_profile_ok()) {
        PyErr_SetString(PyExc_RuntimeError, "radio exists only on the micro:bit profile");
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->radio.on = 0;
    g_current->radio.rx_len = 0;      /* radio eteinte : la file de reception se vide */
    LeaveCriticalSection(&g_current->cs);
    Py_RETURN_NONE;
}

static PyObject* native_radio_config(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int length, queue, channel, power, address, group, data_rate;
    if (!PyArg_ParseTuple(args, "iiiiiii", &length, &queue, &channel, &power,
                          &address, &group, &data_rate)) return NULL;
    if (!radio_profile_ok()) {
        PyErr_SetString(PyExc_RuntimeError, "radio exists only on the micro:bit profile");
        return NULL;
    }
    if (length < 1 || length > RADIO_MAX_PAYLOAD) {
        PyErr_Format(PyExc_ValueError, "invalid length %d (1-%d expected)", length, RADIO_MAX_PAYLOAD);
        return NULL;
    }
    if (queue < 0 || queue > RADIO_MAX_QUEUE) {
        PyErr_Format(PyExc_ValueError, "invalid queue %d (0-%d expected)", queue, RADIO_MAX_QUEUE);
        return NULL;
    }
    if (channel < 0 || channel > 100) {
        PyErr_Format(PyExc_ValueError, "invalid channel %d (0-100 expected)", channel);
        return NULL;
    }
    if (power < 0 || power > 7) {
        PyErr_Format(PyExc_ValueError, "invalid power %d (0-7 expected)", power);
        return NULL;
    }
    if (group < 0 || group > 255) {
        PyErr_Format(PyExc_ValueError, "invalid group %d (0-255 expected)", group);
        return NULL;
    }
    if (data_rate != 1 && data_rate != 2) {
        PyErr_Format(PyExc_ValueError, "invalid data_rate %d (radio.RATE_1MBIT or radio.RATE_2MBIT expected)", data_rate);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->radio.length = length;
    g_current->radio.queue = queue;
    g_current->radio.channel = channel;
    g_current->radio.power = power;
    g_current->radio.address = address;
    g_current->radio.group = group;
    g_current->radio.data_rate = data_rate;
    LeaveCriticalSection(&g_current->cs);
    Py_RETURN_NONE;
}

static PyObject* native_radio_send_bytes(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    const char* data;
    Py_ssize_t len;
    int heard;
    if (!PyArg_ParseTuple(args, "y#", &data, &len)) return NULL;
    if (!radio_profile_ok()) {
        PyErr_SetString(PyExc_RuntimeError, "radio exists only on the micro:bit profile");
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    if (!g_current->radio.on) {
        LeaveCriticalSection(&g_current->cs);
        PyErr_SetString(PyExc_RuntimeError, "radio is off - call radio.on() first");
        return NULL;
    }
    if (g_current->radio.network_id < 0) {
        LeaveCriticalSection(&g_current->cs);
        PyErr_SetString(PyExc_RuntimeError,
                        "radio.send(): the antenna is not wired - wire the Antenna port of the board "
                        "to the antenna of a Peripherals.Radio.RadioAir in the diagram");
        return NULL;
    }
    if (len > g_current->radio.length) {
        len = g_current->radio.length;   /* comme le firmware : au plus length octets partent a l'air */
    }
    heard = radio_send(g_current, (const unsigned char*) data, (int) len);
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    if (!heard) {
        PyErr_WarnEx(NULL, "radio.send(): nobody listens on this network "
                    "(no other board with radio on, on the same air)", 1);
    }
    Py_RETURN_NONE;
}

static PyObject* native_radio_any(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    long n;
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    EnterCriticalSection(&g_current->cs);
    n = g_current->radio.on ? g_current->radio.rx_len : 0;
    LeaveCriticalSection(&g_current->cs);
    return PyLong_FromLong(n);
}

static PyObject* native_radio_read_bytes(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    PyObject* bytes;
    int i;
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    EnterCriticalSection(&g_current->cs);
    if (!g_current->radio.on || g_current->radio.rx_len == 0) {
        LeaveCriticalSection(&g_current->cs);
        Py_RETURN_NONE;
    }
    bytes = PyBytes_FromStringAndSize((const char*) g_current->radio.rx[0].payload,
                                      g_current->radio.rx[0].len);
    g_current->radio.rx_len--;
    for (i = 0; i < g_current->radio.rx_len; i++) {
        g_current->radio.rx[i] = g_current->radio.rx[i + 1];
    }
    LeaveCriticalSection(&g_current->cs);
    return bytes;
}
