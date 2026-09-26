/* Constantes, etat partage (struct PyRuntimeHandle) et handle courant.

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

#define NUM_PINS 9          /* 0-7 = GP0-GP7 (broches externes) ; 8 = LED embarquee (interne, pas de connecteur electrique) */
#define LED_PIN_INDEX 8
#define LED_PIN_ID 25       /* numero reel de la broche sur le Raspberry Pi Pico, non expose par MCU */
#define TURN_MODELICA 0
#define TURN_WORKER 1
#define PYRUNTIME_EPS 1e-9

#define MAX_TIMERS 4                 /* pool fixe de machine.Timer, meme esprit que les 8 broches GPIO plutot que 29 */
#define TIMER_MIN_PERIOD 0.001       /* plancher (1 ms) : evite une tempete d'evenements Modelica a duree simulee nulle si period<=0, cf. requirements.md */
#define IRQ_TRIGGER_RISING 1
#define IRQ_TRIGGER_FALLING 2

#define DISPLAY_MSG_MAX_LEN 128      /* tres au-dessus des 40 caracteres d'un afficheur 20x2, buffer fixe modeste (meme esprit que g_stdout_buf) */

/* machine.UART : un seul peripherique (id 0) en v0, sur deux broches GPx au choix
   du script. Les constantes du protocole (UART_TX_BUF_LEN, UART_MAX_FRAME_BITS,
   UART_MIN_BAUD/UART_MAX_BAUD, UART_RX_IDLE/RECEIVING) et la mecanique bit/octet
   vivent desormais dans uartcore.h / uartcore.c, a la racine d'Include/ : le meme
   moteur sert aux peripheriques serie externes (Peripherals.UartDevice), qui n'ont
   ni Python ni thread. Ne restent ici que les notions propres au microcontroleur :
   quelle broche fait TX, quelle broche fait RX, et le drapeau de reservation. */

/* machine.I2C : maitre unique (un seul bus en v0), sur deux broches GPx au choix
   du script, en DRAIN OUVERT - la broche est soit tiree a la masse, soit relachee
   (haute impedance), jamais forcee a l'etat haut : ce sont les resistances de
   tirage du bus qui remontent la ligne. Cf. pyruntime_i2c.c et requirements.md,
   decision "Bus I2C electrique en drain ouvert". */
#define I2C_XFER_MAX 256             /* octets ecrits ou lus par transaction (meme ordre que la file UART) */
#define I2C_MIN_FREQ 1000.0          /* garde-fou : evite une horloge si lente qu'une trame durerait des secondes */
#define I2C_MAX_FREQ 1000000.0       /* garde-fou contre une tempete d'evenements Modelica (Fast-mode Plus) */
#define I2C_ERR_EIO 5                /* valeurs errno de MicroPython (OSError(errno)) */
#define I2C_ERR_EBUSY 16
#define I2C_ERR_ETIMEDOUT 110

struct I2cMaster {
    int busy;                        /* transaction en cours */
    int done;                        /* transaction terminee (resultat disponible) */
    int error;                       /* 0 ou errno (EIO : adresse sans ACK, ETIMEDOUT : ligne bloquee basse) */
    int held;                        /* bus garde apres writeto(stop=False) : SCL tenue basse, la suite commencera par un START repete */
    int phase;                       /* action a executer a next_time, cf. I2CM_* dans pyruntime_i2c.c */
    double next_time;                /* 1e300 si rien n'est programme */
    double quarter;                  /* quart de periode d'horloge (1/(4 freq)) : pas elementaire de la sequence */

    /* description de la transaction : [START adr+W, donnees] [START repete adr+R, lecture] STOP */
    int addr;
    int has_write;                   /* segment d'ecriture present (meme vide : sonde d'adresse, cf. scan) */
    unsigned char wbuf[I2C_XFER_MAX];
    int nwrite;
    int nread;
    int stop;                        /* 0 : garder le bus (START repete a la transaction suivante) */

    /* avancement */
    int segment;                     /* 0 = ecriture, 1 = lecture */
    int index;                       /* -1 = octet d'adresse, sinon rang de l'octet de donnees dans le segment */
    unsigned char cur;               /* octet en cours (emis ou recu) */
    int bit;                         /* 0-7 = bits de donnees (poids fort en tete), 8 = bit d'acquittement */
    int rx;                          /* l'octet en cours est recu par le maitre (segment de lecture, hors adresse) */
    int ack;                         /* dernier acquittement lu (1 = ACK, SDA basse) */
    unsigned char rbuf[I2C_XFER_MAX];
    int rcount;
    int acks;                        /* octets de donnees acquittes (valeur de retour de writeto) */
};

struct PyRuntimeHandle {
    char* scriptPath;

    CRITICAL_SECTION cs;
    CONDITION_VARIABLE cv;
    int turn;

    double sim_time;
    double wake_requested_at;
    int wake_pending;
    int wake_had_input_change;  /* pose par PyRuntime_sync avant de reveiller le worker : distingue un reveil "authentique" (deadline propre du worker atteinte, ou vraie transition d'entree) d'un simple "pitstop" (callback de Timer/IRQ a executer, sans faire revenir l'appel bloquant en cours), cf. yield_to_modelica */

    int pin_is_output[NUM_PINS];
    int pin_driven_value[NUM_PINS];
    int pin_sensed_value[NUM_PINS];
    double pin_analog_value[NUM_PINS];
    double pwm_freq[NUM_PINS];   /* 0 = pas en mode PWM */
    double pwm_duty[NUM_PINS];   /* 0-1, pertinent seulement si pwm_freq > 0 */

    /* machine.Pin.irq() : au plus un handler par broche */
    PyObject* pin_irq_handler[NUM_PINS];  /* NULL = pas de callback enregistre */
    PyObject* pin_irq_self[NUM_PINS];     /* l'instance Python Pin, passee en argument au handler comme sur le vrai MicroPython */
    int pin_irq_trigger[NUM_PINS];        /* bitmask IRQ_TRIGGER_RISING/FALLING */
    int pin_irq_pending[NUM_PINS];        /* pose par PyRuntime_sync sur un front correspondant, consomme par run_due_callbacks */

    /* machine.Timer : pool fixe de MAX_TIMERS minuteurs logiciels */
    int timer_allocated[MAX_TIMERS];   /* slot occupe par un objet Timer() (initialise ou non) */
    int timer_active[MAX_TIMERS];      /* arme (init() appele, pas encore deinit()/tire une fois pour un ONE_SHOT) */
    double timer_period[MAX_TIMERS];   /* secondes */
    int timer_mode[MAX_TIMERS];        /* 0 = ONE_SHOT, 1 = PERIODIC */
    double timer_next_fire[MAX_TIMERS]; /* temps simule absolu */
    PyObject* timer_callback[MAX_TIMERS];
    PyObject* timer_self[MAX_TIMERS];  /* l'instance Python Timer, passee en argument au callback comme sur le vrai MicroPython */

    /* machine.Display : liaison logique unique (MCU.Display0), ecrite
       uniquement par native_display_write (jamais par PyRuntime_sync) -
       peripherique pedagogique, pas un vrai protocole (pas de reception
       modelisee), cf. requirements.md decision "Périphérique d'affichage
       pédagogique". */
    int display_seq;
    char display_payload[DISPLAY_MSG_MAX_LEN + 1];

    /* machine.UART : contrairement a Display, cet etat est ecrit des DEUX cotes -
       par les natives (uart_init/uart_write) ET par PyRuntime_sync, qui fait
       avancer l'emission et le decodage de la reception a chaque point de synchro.
       La forme d'onde elle-meme est generee en continu par Modelica a partir de
       uart.tx_bits/uart.tx_start_time (motif PWM), pas front par front depuis ici.
       Cf. requirements.md, decision "UART electrique reel". */
    int uart_configured;
    int uart_tx_pin;             /* index interne 0-8, -1 si non affecte */
    int uart_rx_pin;
    int uart_rx_claimed[NUM_PINS]; /* broche affectee a la reception UART : ses fronts ne reveillent pas le script et ne declenchent pas d'IRQ GPIO (fidele au materiel reel), cf. PyRuntime_sync */

    struct UartEngine uart;      /* files TX/RX, trame 8N1, decodage : cf. uartcore.h (partage avec Peripherals.UartDevice) */

    /* machine.I2C : sequence cadencee par echeances (nextWakeTime), comme la
       reception UART. Le script est bloque dans i2c_xfer jusqu'a la fin de la
       transaction ; i2c_done_wake rend son reveil "authentique" (cf.
       yield_to_modelica), sans quoi il serait pris pour un simple pitstop. */
    int i2c_configured;
    int i2c_scl_pin;             /* index interne 0-7, -1 si non affecte */
    int i2c_sda_pin;
    int i2c_claimed[NUM_PINS];   /* broche prise par le bus : ses fronts ne reveillent pas le script et ne declenchent pas d'IRQ GPIO */
    int i2c_done_wake;
    struct I2cMaster i2cm;

    int script_done;
    int script_error;
    char* error_message;

    HANDLE thread;
    DWORD worker_thread_id;  /* thread autorise a appeler les natives du shim, cf. worker_context_ok */
};

/* Handle du PyRuntime en cours d'execution sur le thread worker courant.
   Un seul worker actif a la fois (restriction v0 "une seule instance"),
   donc une variable globale suffit pour que les fonctions natives du shim
   (appelees depuis Python, qui ne recoivent pas le handle directement)
   retrouvent leur contexte. */
static struct PyRuntimeHandle* g_current = NULL;
