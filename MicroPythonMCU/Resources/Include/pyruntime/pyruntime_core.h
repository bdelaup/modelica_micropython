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

/* machine.UART : un seul peripherique (id 0) en v0, sur deux broches GPx au choix du script. */
#define UART_TX_BUF_LEN 64           /* FIFO d'emission (le FIFO materiel du vrai RP2040 fait 32 octets) */
#define UART_RX_BUF_LEN 64           /* FIFO de reception, meme dimensionnement */
#define UART_MAX_FRAME_BITS 13       /* 1 start + 9 data + 1 parite + 2 stop : dimensionne pour un futur format parametrable, seul 8N1 (10 bits) est emis en v0 */
#define UART_MIN_BAUD 50
#define UART_MAX_BAUD 115200         /* garde-fou contre une tempete d'evenements Modelica (un evenement par front de bit), meme esprit que TIMER_MIN_PERIOD */
#define UART_RX_IDLE 0
#define UART_RX_RECEIVING 1

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
       uart_tx_bits/uart_tx_start_time (motif PWM), pas front par front depuis ici.
       Cf. requirements.md, decision "UART electrique reel". */
    int uart_configured;
    int uart_tx_pin;             /* index interne 0-8, -1 si non affecte */
    int uart_rx_pin;
    double uart_bit_dur;         /* 1/baudrate, en secondes */
    int uart_rx_claimed[NUM_PINS]; /* broche affectee a la reception UART : ses fronts ne reveillent pas le script et ne declenchent pas d'IRQ GPIO (fidele au materiel reel), cf. PyRuntime_sync */

    unsigned char uart_tx_buf[UART_TX_BUF_LEN];
    int uart_tx_head, uart_tx_tail;   /* file circulaire : head = prochaine ecriture, tail = prochaine lecture */
    int uart_tx_active;               /* une trame est en cours d'emission */
    double uart_tx_start_time;        /* instant du front de start de la trame en cours */
    double uart_tx_end_time;          /* instant de fin de la trame en cours (rechargement de la suivante) */
    double uart_tx_bits[UART_MAX_FRAME_BITS]; /* motif de bits complet (start + data + stop), publie tel quel vers Modelica */
    int uart_tx_num_bits;

    unsigned char uart_rx_buf[UART_RX_BUF_LEN];
    int uart_rx_head, uart_rx_tail;
    int uart_rx_state;                /* UART_RX_IDLE | UART_RX_RECEIVING */
    int uart_rx_last_level;           /* niveau vu au dernier point de synchro : le start se detecte sur un FRONT descendant, pas sur un niveau bas (cf. uart_rx_step) */
    double uart_rx_next_sample;       /* prochain instant d'echantillonnage, remonte a Modelica via nextWakeTime */
    int uart_rx_bit_index;            /* 0-7 : bit de donnee en cours */
    unsigned int uart_rx_shift;       /* registre a decalage */

    int script_done;
    int script_error;
    char* error_message;

    HANDLE thread;
};

/* Handle du PyRuntime en cours d'execution sur le thread worker courant.
   Un seul worker actif a la fois (restriction v0 "une seule instance"),
   donc une variable globale suffit pour que les fonctions natives du shim
   (appelees depuis Python, qui ne recoivent pas le handle directement)
   retrouvent leur contexte. */
static struct PyRuntimeHandle* g_current = NULL;
