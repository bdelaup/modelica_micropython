# Shim `machine`/`time` : l'API MicroPython (RP2040) vue par le script utilisateur.
#
# Ce fichier EST la source de verite : il est lu et execute tel quel par
# PyRuntime_new (PyRuntimeImpl.c) au demarrage de l'interpreteur, avant le
# script utilisateur, par-dessus le module natif `_pyruntime_native`.
# Son chemin est resolu depuis MCU.shimPath (Modelica.Utilities.Files.loadResource).
#
# Voir docs/fr/guide/api.md pour la reference de l'API cote script, et
# docs/fr/interne/integration-python.md pour le contexte d'integration.

import sys, types, _pyruntime_native as _native
# Pour le systeme de fichiers (fin de fichier) : importes avant que le faux
# module time ne remplace le vrai dans sys.modules.
import builtins as _builtins, errno as _errno, os as _host_os
import datetime as _host_datetime, shutil as _host_shutil
import warnings as _warnings
import atexit as _atexit, weakref as _weakref

# CPython avertit a la compilation de tournures que MicroPython accepte sans
# rien dire - typiquement "gain is 128" (driver HX711 de robert-hh). Le code
# fonctionne a l'identique (petits entiers partages), l'avertissement ne ferait
# que polluer le journal de simulation d'un driver du commerce.
_warnings.filterwarnings('ignore', category=SyntaxWarning)

# Profil de carte, donne par le modele (_native.board()) : 'generic' pour MCU,
# qui accepte l'UART et l'I2C sur n'importe quelle broche et l'ADC sur GP0-GP7,
# 'pico' pour RPi_Pico, fidele au RP2040 : ADC(0-3) = GP26-GP29,
# ADC(4) = capteur de temperature, multiplexage des broches UART/I2C et broches
# par defaut du port rp2. Cf. requirements.md, decision "Carte Raspberry Pi Pico
# et alimentation".
_PICO = _native.board() == 'pico'
_PICO_ADC_TEMP = 30   # pseudo-broche du capteur de temperature, alignee sur RPi_Pico
# Par peripherique : broches possibles (TX ou SCL), (RX ou SDA), broches par defaut
_PICO_UART = {0: ((0, 12, 16, 28), (1, 13, 17, 29), (0, 1)),
              1: ((4, 8, 20, 24), (5, 9, 21, 25), (4, 5))}
_PICO_I2C = {0: ((1, 5, 9, 13, 17, 21, 25, 29), (0, 4, 8, 12, 16, 20, 24, 28), (5, 4)),
             1: ((3, 7, 11, 15, 19, 23, 27), (2, 6, 10, 14, 18, 22, 26), (7, 6))}
# Un seul moteur UART et un seul maitre I2C dans la simulation : sur la Pico,
# UART(0) et UART(1) (I2C(0) et I2C(1)) y aboutissent tous deux, un a la fois.
_pico_owner = {}

# Profil micro:bit v2 (MicroBit_v2, nRF52833) : 19 broches edge (pas de P17/P18),
# les 5 colonnes de la matrice LED partagees avec l'edge tant que le driver
# d'affichage est actif, ADC sur P0-P4/P10. Les lignes (21-25) et les capteurs
# integres (26-33) sont des pseudo-broches du modele, jamais visibles du
# script : elles ne passent QUE par le module microbit et les natives. Cf.
# requirements.md, decision "MCU micro:bit v2".
_MBIT = _native.board() == 'microbit'
_MBIT_PINS = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 19, 20)
_MBIT_ADC = (0, 1, 2, 3, 4, 10)
_MBIT_COLS = (3, 4, 6, 7, 10)

def _mbit_check(id, what, write=False):
    # Profil micro:bit : broches edge seulement ; write=True pour tout ce qui
    # prend la direction d'une broche (sortie, tirage, PWM, ADC, UART, I2C) -
    # les colonnes appartiennent alors au driver d'affichage s'il est actif,
    # comme sur la vraie carte ou display.off() les libere.
    if not _MBIT:
        return id
    if id not in _MBIT_PINS:
        raise ValueError('%s %d not supported on this board (valid: 0-16, 19-20)' % (what, id))
    if write and id in _MBIT_COLS and _mbit_display._on:
        raise ValueError('pin%d is driven by the LED display - display.off() releases it' % (id,))
    return id

def _pin_id(p):
    if isinstance(p, Pin):
        return p.id
    if _MBIT and isinstance(p, _MicroBitPin):
        return p.id
    return p

def _pico_pins(table, kind, id, a, b, names):
    # Broches du peripherique id du RP2040 : celles qui manquent sont celles du
    # port rp2 par defaut, les autres doivent etre permises par le multiplexage.
    if id not in table:
        raise ValueError("%s(%d) doesn't exist" % (kind, id))
    valid_a, valid_b, default = table[id]
    a = default[0] if a is None else _pin_id(a)
    b = default[1] if b is None else _pin_id(b)
    if a not in valid_a:
        raise ValueError('bad %s pin' % names[0])
    if b not in valid_b:
        raise ValueError('bad %s pin' % names[1])
    owner = _pico_owner.get(kind)
    if owner is not None and owner != id:
        raise ValueError('%s(%d) is in use: the simulation has a single %s, deinit() it first' % (kind, owner, kind))
    _pico_owner[kind] = id
    return a, b

def _pico_release(kind):
    _pico_owner.pop(kind, None)

class Pin:
    IN = 0
    OUT = 1
    PULL_UP = 1      # valeurs du port rp2, alignees sur PIN_PULL_UP/PIN_PULL_DOWN cote C
    PULL_DOWN = 2
    LED = 25  # doit rester aligne sur LED_PIN_ID cote C (PyRuntimeImpl.c)
    IRQ_RISING = 1   # doit rester aligne sur IRQ_TRIGGER_RISING cote C
    IRQ_FALLING = 2  # doit rester aligne sur IRQ_TRIGGER_FALLING cote C

    def __init__(self, id, mode=None, pull=None):
        if id == 'LED':
            id = Pin.LED
        id = _mbit_check(id, 'GPIO')
        self.id = id
        # Comme le port rp2 : Pin(n) seul ne touche a rien, un mode ou un pull
        # reconfigure la broche (init)
        if mode is not None or pull is not None:
            self.init(mode, pull)

    def init(self, mode=None, pull=None):
        # Le tirage est toujours reecrit : pull=None coupe celui pose avant
        if mode is not None or pull is not None:
            _mbit_check(self.id, 'GPIO', write=True)
        _native.pin_init(self.id, -1 if mode is None else (1 if mode == Pin.OUT else 0), 0 if pull is None else pull)

    def value(self, x=None):
        if x is None:
            return 1 if _native.pin_read(self.id) else 0
        _mbit_check(self.id, 'GPIO', write=True)
        _native.pin_write(self.id, 1 if x else 0)

    def __call__(self, x=None):
        # pin() lit, pin(1) ecrit - raccourci de MicroPython, courant dans les drivers
        return self.value(x)

    def on(self):
        _mbit_check(self.id, 'GPIO', write=True)
        _native.pin_write(self.id, 1)

    def off(self):
        _mbit_check(self.id, 'GPIO', write=True)
        _native.pin_write(self.id, 0)

    # high()/low() : alias d'on()/off() propres au port rp2
    def high(self):
        _mbit_check(self.id, 'GPIO', write=True)
        _native.pin_write(self.id, 1)

    def low(self):
        _mbit_check(self.id, 'GPIO', write=True)
        _native.pin_write(self.id, 0)

    def toggle(self):
        self.value(0 if self.value() else 1)

    def irq(self, handler=None, trigger=IRQ_RISING | IRQ_FALLING, **kwargs):
        _native.pin_irq_set(self.id, self, handler, trigger)

class ADC:
    CORE_TEMP = 4   # canal du capteur de temperature du RP2040 (Pico seulement)

    def __init__(self, id):
        if isinstance(id, Pin):
            id = id.id
        if _PICO:
            # Comme le port rp2 : un canal 0-4, ou une broche GP26-GP29
            if 0 <= id <= 3:
                id = 26 + id
            elif id == ADC.CORE_TEMP:
                id = _PICO_ADC_TEMP
            elif not 26 <= id <= 29:
                raise ValueError('Pin doesn\'t have ADC capabilities')
        if _MBIT:
            # micro:bit : P0-P4 et P10 seulement ; les capteurs integres
            # (pseudo-broches du modele) ne passent que par le module microbit.
            _mbit_check(id, 'ADC input on GPIO')
            if id not in _MBIT_ADC:
                raise ValueError('Pin doesn\'t have ADC capabilities')
            _mbit_check(id, 'ADC input on GPIO', write=True)
        self.id = id
        _native.adc_init(self.id)   # coupe l'entree numerique de la broche, comme sur le RP2040

    def read_u16(self):
        v = _native.adc_read(self.id)   # fraction de la tension de reference (VOH pour MCU, ADC_VREF pour la Pico)
        raw = round(v * 65535)
        return 0 if raw < 0 else (65535 if raw > 65535 else raw)

class PWM:
    def __init__(self, pin, freq=None, duty_u16=None):
        if isinstance(pin, Pin):
            pin = pin.id
        _mbit_check(pin, 'PWM on GPIO', write=True)
        self.id = pin
        self._freq = 0
        self._duty = 0
        if freq is not None:
            self.freq(freq)
        if duty_u16 is not None:
            self.duty_u16(duty_u16)

    def freq(self, f=None):
        if f is None:
            return self._freq
        _native.pwm_set_freq(self.id, float(f))
        self._freq = int(f)

    def duty_u16(self, d=None):
        if d is None:
            return self._duty
        _native.pwm_set_duty(self.id, d / 65535.0)
        self._duty = d

    def deinit(self):
        _native.pwm_deinit(self.id)
        self._freq = 0

class Display:
    # Texte en attente de son '\n', par id : partage entre les objets Display
    # d'un meme id, comme le tampon de sortie de print().
    _pending = {}

    def __init__(self, id=0, **kwargs):
        # Verifie des la construction : une ligne sans '\n' n'appelle pas le C
        if id != 0:
            raise ValueError("Display %s not supported (only Display(0) exists)" % (id,))
        self.id = id  # kwargs : signature volontairement minimale, composant
                      # pedagogique (Peripherals.Display), pas un vrai protocole

    def write(self, *args, sep=' ', end='\n'):
        # Comme print() : arguments convertis par str(), joints par sep, suivis
        # de end ; chaque '\n' envoie la ligne qui le precede (un message par
        # ligne), le reste attend le '\n' d'un appel suivant.
        if sep is None:
            sep = ' '
        if end is None:
            end = '\n'
        if not isinstance(sep, str) or not isinstance(end, str):
            raise TypeError("sep and end must be None or strings")
        text = Display._pending.get(self.id, '') + sep.join(str(a) for a in args) + end
        lines = text.split('\n')
        Display._pending[self.id] = lines.pop()
        for line in lines:
            _native.display_write(self.id, line)

class UART:
    # Format de trame comme le port rp2 : bits 5-8, parity None/0 (paire)/1
    # (impaire), stop 1 ou 2 - la trame elle-meme vit entierement cote C
    # (uartcore.c). Les autres arguments du port (timeout, txbuf, rxbuf,
    # flow...) sont absorbes par **kwargs, sans effet.
    def __init__(self, id=0, baudrate=1200, bits=8, parity=None, stop=1, tx=None, rx=None, **kwargs):
        self.id = id
        self.init(baudrate, bits, parity, stop, tx=tx, rx=rx, **kwargs)

    def init(self, baudrate=1200, bits=8, parity=None, stop=1, tx=None, rx=None, **kwargs):
        if _PICO:
            tx, rx = _pico_pins(_PICO_UART, 'UART', self.id, tx, rx, ('TX', 'RX'))
            self._nid = 0   # le moteur UART unique de la simulation
        else:
            if tx is None or rx is None:
                raise ValueError('tx and rx must be given (e.g. UART(0, tx=Pin(0), rx=Pin(1)))')
            tx = _pin_id(tx)
            rx = _pin_id(rx)
            if _MBIT:
                # micro:bit : moteur UART unique, broches edge, pas de colonne
                # de la matrice LED tant que l'affichage est actif
                _mbit_check(tx, 'GPIO', write=True)
                _mbit_check(rx, 'GPIO', write=True)
                self._nid = 0
            else:
                self._nid = self.id
        if bits not in (5, 6, 7, 8):
            raise ValueError('invalid bits')
        if parity not in (None, 0, 1):
            raise ValueError('invalid parity')
        if stop not in (1, 2):
            raise ValueError('invalid stop')
        self._baudrate = baudrate
        self._bits = bits
        self._parity = parity
        self._stop = stop
        self.tx = tx
        self.rx = rx
        _native.uart_init(self._nid, tx, rx, float(baudrate), bits, -1 if parity is None else parity, stop)

    def __repr__(self):
        return 'UART(%d, baudrate=%d, bits=%d, parity=%s, stop=%d, tx=%d, rx=%d)' % (
            self.id, self._baudrate, self._bits, self._parity, self._stop, self.tx, self.rx)

    def write(self, data):
        if isinstance(data, str):
            data = data.encode()
        elif not isinstance(data, (bytes, bytearray)):
            data = str(data).encode()
        return _native.uart_write(self._nid, bytes(data))

    def any(self):
        return _native.uart_any(self._nid)

    def read(self, n=None):
        return _native.uart_read(self._nid, -1 if n is None else int(n))

    def readline(self):
        buf = b''
        while True:
            chunk = _native.uart_read(self._nid, 1)
            if chunk is None:
                return buf if buf else None
            buf += chunk
            if chunk == b'\n':
                return buf

    def deinit(self):
        _native.uart_deinit(self._nid)
        if _PICO:
            _pico_release('UART')

class I2C:
    # Maitre I2C en drain ouvert (un seul bus). L'identifiant est
    # facultatif : I2C(0, scl=..., sda=...) (forme rp2) et I2C(scl=..., sda=...)
    # (forme des drivers ecrits pour d'autres ports) sont acceptes tous les deux ;
    # sur la Pico, sans identifiant, celui des broches choisies.
    # Chaque transaction est BLOQUANTE jusqu'a la fin de la sequence sur le bus,
    # en temps simule. Erreurs : OSError(EIO) si l'adresse n'est pas acquittee,
    # OSError(ETIMEDOUT) si une ligne reste basse (bus sans tirage).
    _soft = False   # SoftI2C : n'importe quelles broches, meme sur la Pico

    def __init__(self, id=None, *, scl=None, sda=None, freq=400000, **kwargs):
        if id is None:
            id = 1 if _PICO and not self._soft and _pin_id(scl) in _PICO_I2C[1][0] else 0
        self.id = id
        self.init(scl=scl, sda=sda, freq=freq, **kwargs)

    def init(self, scl=None, sda=None, freq=400000, **kwargs):
        if _PICO and not self._soft:
            scl, sda = _pico_pins(_PICO_I2C, 'I2C', self.id, scl, sda, ('SCL', 'SDA'))
            self._nid = 0   # le maitre I2C unique de la simulation
        else:
            if scl is None or sda is None:
                raise ValueError('scl and sda must be given (e.g. I2C(0, scl=Pin(5), sda=Pin(4)))')
            scl = _pin_id(scl)
            sda = _pin_id(sda)
            if _MBIT:
                # micro:bit : maitre unique, broches edge, pas de colonne de la
                # matrice LED tant que l'affichage est actif
                _mbit_check(scl, 'GPIO', write=True)
                _mbit_check(sda, 'GPIO', write=True)
                self._nid = 0
            else:
                self._nid = 0 if self._soft else self.id
        self.scl = scl
        self.sda = sda
        self._freq = freq
        _native.i2c_init(self._nid, scl, sda, float(freq))

    def deinit(self):
        _native.i2c_deinit(self._nid)
        if _PICO and not self._soft:
            _pico_release('I2C')

    def scan(self):
        trouves = []
        for addr in range(0x08, 0x78):
            try:
                _native.i2c_xfer(self._nid, addr, b'', 0, True)
                trouves.append(addr)
            except OSError as e:
                if e.errno == 110:   # ETIMEDOUT : bus bloque, inutile d'insister
                    break
        return trouves

    def writeto(self, addr, buf, stop=True):
        acks, _ = _native.i2c_xfer(self._nid, addr, bytes(buf), 0, bool(stop))
        return acks

    def writevto(self, addr, vector, stop=True):
        return self.writeto(addr, b''.join(bytes(b) for b in vector), stop)

    def readfrom(self, addr, nbytes, stop=True):
        _, data = _native.i2c_xfer(self._nid, addr, None, int(nbytes), bool(stop))
        return data

    def readfrom_into(self, addr, buf, stop=True):
        data = self.readfrom(addr, len(buf), stop)
        buf[:len(data)] = data

    @staticmethod
    def _memaddr(memaddr, addrsize):
        return int(memaddr).to_bytes(addrsize // 8, 'big')

    def writeto_mem(self, addr, memaddr, buf, *, addrsize=8):
        self.writeto(addr, I2C._memaddr(memaddr, addrsize) + bytes(buf))

    def readfrom_mem(self, addr, memaddr, nbytes, *, addrsize=8):
        _, data = _native.i2c_xfer(self._nid, addr, I2C._memaddr(memaddr, addrsize), int(nbytes), True)
        return data

    def readfrom_mem_into(self, addr, memaddr, buf, *, addrsize=8):
        data = self.readfrom_mem(addr, memaddr, len(buf), addrsize=addrsize)
        buf[:len(data)] = data

class SoftI2C(I2C):
    # Bus logiciel du port rp2 : sans identifiant, sur n'importe quelles
    # broches. En simulation, le meme maitre que I2C (logiciel ou materiel ne
    # se distinguent pas).
    _soft = True

    def __init__(self, scl=None, sda=None, *, freq=400000, **kwargs):
        I2C.__init__(self, 0, scl=scl, sda=sda, freq=freq, **kwargs)

class _I2CTargetIRQ:
    # Objet rendu par I2CTarget.irq() : flags() donne les evenements en cours
    # de traitement, comme sur MicroPython.
    def flags(self):
        return _native.i2ct_flags()

_UNSET = object()

class I2CTarget:
    # Cible (esclave) I2C en drain ouvert, une seule par microcontroleur. Adresse
    # sur 7 bits. Avec mem= (bytearray), la cible se comporte comme une memoire
    # sans aucun gestionnaire : les premiers octets ecrits par le maitre
    # (mem_addrsize bits) choisissent l'adresse, les suivants y sont ecrits, une
    # lecture sort la memoire a partir de cette adresse. Sans mem=, readinto()
    # lit les octets recus et write() prepare ceux a sortir, typiquement depuis
    # un gestionnaire irq(). Tous les gestionnaires s'executent au meme instant
    # simule que l'evenement, qu'ils soient hard ou non : IRQ_READ_REQ peut donc
    # fournir l'octet demande sans clock stretching (non modelise).
    IRQ_ADDR_MATCH_READ = 0x01   # doivent rester alignes sur I2CT_IRQ_* cote C
    IRQ_ADDR_MATCH_WRITE = 0x02
    IRQ_READ_REQ = 0x04
    IRQ_WRITE_REQ = 0x08
    IRQ_END_READ = 0x10
    IRQ_END_WRITE = 0x20

    def __init__(self, id=0, addr=None, *, addrsize=7, mem=None, mem_addrsize=8, scl=None, sda=None):
        if addr is None:
            raise TypeError('addr must be given (e.g. I2CTarget(0, 0x42, scl=Pin(5), sda=Pin(4)))')
        if _PICO:
            # Multiplexage du RP2040 ; la cible n'occupe pas le maitre (_pico_owner)
            if id not in _PICO_I2C:
                raise ValueError("I2CTarget(%d) doesn't exist" % id)
            valid_scl, valid_sda, default = _PICO_I2C[id]
            scl = default[0] if scl is None else _pin_id(scl)
            sda = default[1] if sda is None else _pin_id(sda)
            if scl not in valid_scl:
                raise ValueError('bad SCL pin')
            if sda not in valid_sda:
                raise ValueError('bad SDA pin')
            nid = 0   # la cible unique de la simulation
        else:
            if scl is None or sda is None:
                raise ValueError('scl and sda must be given (e.g. I2CTarget(0, 0x42, scl=Pin(5), sda=Pin(4)))')
            scl = _pin_id(scl)
            sda = _pin_id(sda)
            if _MBIT:
                # micro:bit : cible unique, broches edge, pas de colonne de la
                # matrice LED tant que l'affichage est actif
                _mbit_check(scl, 'GPIO', write=True)
                _mbit_check(sda, 'GPIO', write=True)
                nid = 0
            else:
                nid = id
        self.id = id
        self._mem = mem          # garde le tampon en vie : le C ecrit dedans
        self._irq = _I2CTargetIRQ()
        _native.i2ct_init(nid, addr, addrsize, scl, sda, mem, mem_addrsize)

    @property
    def memaddr(self):
        return _native.i2ct_memaddr()

    def deinit(self):
        _native.i2ct_deinit()

    def readinto(self, buf):
        return _native.i2ct_readinto(buf)

    def write(self, buf):
        return _native.i2ct_write(bytes(buf))

    def irq(self, handler=_UNSET, trigger=IRQ_END_READ | IRQ_END_WRITE, hard=False):
        # irq() sans argument ne reconfigure rien et rend l'objet IRQ (flags()),
        # comme sur MicroPython ; hard= est accepte et sans effet.
        if handler is not _UNSET or trigger != I2CTarget.IRQ_END_READ | I2CTarget.IRQ_END_WRITE or hard:
            _native.i2ct_irq(None if handler is _UNSET else handler, trigger, self)
        return self._irq

class Timer:
    ONE_SHOT = 0
    PERIODIC = 1

    def __init__(self, id=-1, **kwargs):
        self._slot = _native.timer_new()
        # Comme MicroPython : les arguments de init() passes au constructeur
        # demarrent le minuteur aussitot (Timer(period=..., callback=...)).
        if kwargs:
            self.init(**kwargs)

    def init(self, period=1000, mode=PERIODIC, callback=None, freq=None):
        if freq is not None:
            if freq <= 0:
                raise ValueError("freq must be positive")
            period = 1000.0 / freq
        _native.timer_init(self._slot, period / 1000.0, mode, callback, self)

    def deinit(self):
        _native.timer_deinit(self._slot)

_machine = types.ModuleType('machine')
_machine.Pin = Pin
_machine.ADC = ADC
_machine.PWM = PWM
_machine.Display = Display
_machine.UART = UART
_machine.I2C = I2C
_machine.SoftI2C = SoftI2C
_machine.I2CTarget = I2CTarget
_machine.Timer = Timer
_machine.idle = _native.idle
_machine.disable_irq = _native.disable_irq
_machine.enable_irq = _native.enable_irq
sys.modules['machine'] = _machine

def sleep(s):
    _native.sleep(float(s))

def sleep_ms(ms):
    _native.sleep(ms / 1000.0)

def sleep_us(us):
    _native.sleep(us / 1000000.0)

def ticks_ms():
    return _native.ticks_ms()

def ticks_us():
    return _native.ticks_us()

def ticks_diff(a, b):
    return a - b

_time = types.ModuleType('time')
_time.sleep = sleep
_time.sleep_ms = sleep_ms
_time.sleep_us = sleep_us
_time.ticks_ms = ticks_ms
_time.ticks_us = ticks_us
_time.ticks_diff = ticks_diff
sys.modules['time'] = _time

# --- Module microbit (profil « micro:bit v2 », nRF52833) ---
#
# L'API officielle du portage MicroPython de la micro:bit, construite par-dessus
# machine et le moteur de matrice LED du C (pyruntime_matrix.c), comme le vrai
# portage v2 qui expose aussi machine. Cf. requirements.md, decision « MCU
# micro:bit v2 » : display (matrice 5x5 multiplexee sur 10 GPIO, balayee a
# 60 Hz par le C), boutons A/B (P5/P11, tirage externe 10 k de la carte,
# appuye = LOW), capteurs integres lus comme des pseudo-broches ADC (valeur
# fournies par le modele), uart/i2c (enveloppes de machine aux defauts micro:bit).
#
# ATTENTION : ce bloc s'execute pendant l'init du worker, AVANT le premier tour
# - aucune native qui rend la main a Modelica ici (deadlock, cf.
# matrix_boot_enable). Le display nait « on » sans rien appeler : c'est
# PyRuntime_sync qui active le moteur a la premiere synchro alimentee, comme le
# firmware active son driver d'affichage au boot. Tout ce qui appelle une
# native (display.on(), boutons, animations) est differe au premier appel.

if _MBIT:
    import math

    _MBIT_ROW_IDS = (21, 22, 23, 24, 25)   # lignes internes de la matrice (pseudo-GPIO du modele)
    _MBIT_COL_IDS = (4, 7, 3, 6, 10)       # COL1..COL5 = broches edge P4, P7, P3, P6, P10
    _MBIT_ACCEL_IDS = (26, 27, 28)         # X, Y, Z en m/s^2
    _MBIT_MAG_IDS = (29, 30, 31)           # X, Y, Z en µT
    _MBIT_TEMP_ID = 32                     # degres Celsius
    _MBIT_LIGHT_ID = 33                    # niveau de lumiere 0-255

    # Police officielle « pendolino3 » du firmware micro:bit (microbit-dal,
    # MicroBitFont.cpp, licence MIT) : 95 glyphes ASCII 0x20-0x7E, 5 octets par
    # glyphe, un octet par ligne, bits 0x10..0x01 = colonnes 1..5.
    _MBIT_FONT = bytes.fromhex(
        '000000000008080800080a4a4000000a5fea5fea0ed92ed36e19324489330c924c924d0808000000048808080408048'
        '48488000a448a4000048ec480000000048800000ec000000000080001224488100c9252524c048c84848e1c824c901e'
        '1ec244924c06ca525fe21ff01ec13e02448ed12e1fe24488100ed12ed12e0ed12ec4880008000800000480048802448'
        '80482000ec00ec008048244880ed126c0040ed135b36c0c925ed2521c925c925c0ed010100e1c9252525c1ed01c901e'
        '1ed01c90100ed013712e12525ed2521c8808081c1fe242524c1254981492101010101e113b75b131113935b3710c925'
        '2524c1c925c90100c92524c861c925c92510ed00c825c1fe4848484125252524c1131312a44113135bb7112524c9252'
        '112a4484841ec488101e0ec808080e10080482410ec242424e048a400000000000001f0804800000000ed2524f10101'
        'c925c000ed0100e02424ed24e0c925c900e06c81c88080ed24ec24c10101c92520800080808024002424c1014981492'
        '0808080806001b75b131001c925252000c92524c001c925c90000ed24ec2000ed010100006c8049808080ec80700125'
        '2524f0011312a4400113135bb00124c8c9200112a4498001ec4881e06c48c8486080808080818080c881800000c8360'
    )

    def _mbit_glyph(ch):
        # Glyphe 5x5 (niveaux 0/9) ; hors ASCII imprimable : glyphe vide, le
        # vrai afficheur ignore aussi les caracteres inconnus.
        o = (ord(ch) - 32) * 5 if 32 <= ord(ch) <= 126 else -1
        rows = []
        for r in range(5):
            b = _MBIT_FONT[o + r] if o >= 0 else 0
            rows.append([9 if b & (0x10 >> c) else 0 for c in range(5)])
        return rows

    def _mbit_glyph_width(rows, monospace):
        # Largeur reelle du glyphe (les colonnes vides de droite ne defilent
        # pas) : c'est ce qui rend le defilement proportionnel, sauf monospace.
        if monospace:
            return 5
        w = 0
        for r in rows:
            for c in range(5):
                if r[c] and c + 1 > w:
                    w = c + 1
        return max(w, 1)

    def _mbit_text_columns(text, monospace):
        # Colonnes du defilement : une vide entre caracteres (« exactly 1 blank
        # pixel-column between each character » de la reference).
        cols = []
        for i, ch in enumerate(text):
            if i:
                cols.append([0] * 5)
            rows = _mbit_glyph(ch)
            w = _mbit_glyph_width(rows, monospace)
            for c in range(w):
                cols.append([rows[r][c] for r in range(5)])
        return cols if cols else [[0] * 5]

    # --- Image ---
    class _MicroBitImage:
        # Image de niveaux 0-9, pas forcement 5x5 (crop/blit/shift). Les
        # constantes integrees sont des instances en lecture seule, comme
        # Image.HEART du vrai portage.
        def __init__(self, *args):
            self._readonly = False
            if len(args) == 0:
                self._init_buf(5, 5, None)
            elif len(args) == 1 and isinstance(args[0], str):
                s = args[0]
                if len(s) == 1:
                    rows = _mbit_glyph(s)
                    self._init_buf(5, 5, [v for r in rows for v in r])
                else:
                    lines = [ln for ln in s.replace(chr(10), ':').split(':') if ln != '']
                    if not lines:
                        lines = ['00000']
                    for ln in lines:
                        if len(ln) != 5 or not all('0' <= c <= '9' for c in ln):
                            raise ValueError('invalid image string: five digits 0-9 per line')
                    self._init_buf(5, len(lines), [int(c) for ln in lines for c in ln])
            elif len(args) in (2, 3) and isinstance(args[0], int) and isinstance(args[1], int):
                w, h = args[0], args[1]
                if not (0 < w and 0 < h):
                    raise ValueError('invalid image size')
                buf = None
                if len(args) == 3:
                    src = args[2]
                    if len(src) < w * h:
                        raise ValueError('buffer too small')
                    buf = [self._level(src[i]) for i in range(w * h)]
                self._init_buf(w, h, buf)
            else:
                raise TypeError('Image(string) or Image(width, height[, buffer])')

        @staticmethod
        def _level(v):
            v = int(v)
            return 0 if v < 0 else (9 if v > 9 else v)

        def _init_buf(self, w, h, buf):
            self._w = w
            self._h = h
            self._b = list(buf) if buf is not None else [0] * (w * h)

        def width(self):
            return self._w

        def height(self):
            return self._h

        def set_pixel(self, x, y, value):
            if self._readonly:
                raise TypeError("can't modify a built-in image - copy() it first")
            if not (0 <= x < self._w and 0 <= y < self._h):
                raise ValueError('x or y is out of bounds')
            self._b[y * self._w + x] = self._level(value)

        def get_pixel(self, x, y):
            if not (0 <= x < self._w and 0 <= y < self._h):
                raise ValueError('x or y is out of bounds')
            return self._b[y * self._w + x]

        def fill(self, value):
            if self._readonly:
                raise TypeError("can't modify a built-in image - copy() it first")
            self._b = [self._level(value)] * (self._w * self._h)

        def copy(self):
            img = _MicroBitImage(self._w, self._h)
            img._b = list(self._b)
            return img

        def invert(self):
            img = self.copy()
            img._b = [9 - v for v in img._b]
            return img

        def _shift(self, dx, dy):
            img = _MicroBitImage(self._w, self._h)
            for y in range(self._h):
                for x in range(self._w):
                    sx, sy = x - dx, y - dy
                    if 0 <= sx < self._w and 0 <= sy < self._h:
                        img._b[y * self._w + x] = self._b[sy * self._w + sx]
            return img

        def shift_left(self, n):
            return self._shift(n, 0)

        def shift_right(self, n):
            return self._shift(-n, 0)

        def shift_up(self, n):
            return self._shift(0, n)

        def shift_down(self, n):
            return self._shift(0, -n)

        def crop(self, x, y, w, h):
            if not (0 < w and 0 < h):
                raise ValueError('invalid crop size')
            img = _MicroBitImage(w, h)
            for yy in range(h):
                for xx in range(w):
                    sx, sy = x + xx, y + yy
                    if 0 <= sx < self._w and 0 <= sy < self._h:
                        img._b[yy * w + xx] = self._b[sy * self._w + sx]
            return img

        def blit(self, src, x, y, w, h, xdest=0, ydest=0):
            if self._readonly:
                raise TypeError("can't modify a built-in image - copy() it first")
            if not isinstance(src, _MicroBitImage):
                raise TypeError('blit source must be an Image')
            for yy in range(h):
                for xx in range(w):
                    sx, sy = x + xx, y + yy
                    v = 0
                    if 0 <= sx < src._w and 0 <= sy < src._h:
                        v = src._b[sy * src._w + sx]
                    dx, dy = xdest + xx, ydest + yy
                    if 0 <= dx < self._w and 0 <= dy < self._h:
                        self._b[dy * self._w + dx] = v

    class _MicroBitImageReadOnly(_MicroBitImage):
        def __init__(self, digits):
            self._readonly = True
            self._init_buf(5, 5, [int(c) * 9 for c in digits])

    # Images integrees : donnees officielles du portage (microbitconstimage.cpp,
    # formes 0/1 converties en niveaux 0/9).
    _MBIT_CONST_IMAGES = {
        'HEART': '0101011111111110111000100',
        'HEART_SMALL': '0000001010011100010000000',
        'HAPPY': '0000001010000001000101110',
        'SMILE': '0000000000000001000101110',
        'SAD': '0000001010000000111010001',
        'CONFUSED': '0000001010000000101010101',
        'ANGRY': '1000101010000001111110101',
        'ASLEEP': '0000011011000000111000000',
        'SURPRISED': '0101000000001000101000100',
        'SILLY': '1000100000111110010100111',
        'FABULOUS': '1111111011000000101001110',
        'MEH': '0101000000000100010001000',
        'YES': '0000000001000101010001000',
        'NO': '1000101010001000101010001',
        'CLOCK12': '0010000100001000000000000',
        'CLOCK1': '0001000010001000000000000',
        'CLOCK2': '0000000011001000000000000',
        'CLOCK3': '0000000000001110000000000',
        'CLOCK4': '0000000000001000001100000',
        'CLOCK5': '0000000000001000001000010',
        'CLOCK6': '0000000000001000010000100',
        'CLOCK7': '0000000000001000100001000',
        'CLOCK8': '0000000000001001100000000',
        'CLOCK9': '0000000000111000000000000',
        'CLOCK10': '0000011000001000000000000',
        'CLOCK11': '0100001000001000000000000',
        'ARROW_N': '0010001110101010010000100',
        'ARROW_NE': '0011100011001010100010000',
        'ARROW_E': '0010000010111110001000100',
        'ARROW_SE': '1000001000001010001100111',
        'ARROW_S': '0010000100101010111000100',
        'ARROW_SW': '0000100010101001100011100',
        'ARROW_W': '0010001000111110100000100',
        'ARROW_NW': '1110011000101000001000001',
        'TRIANGLE': '0000001000111001111111000',
        'TRIANGLE_LEFT': '1000011000101001001011111',
        'CHESSBOARD': '0101010101010101010101010',
        'DIAMOND': '0010001010100010101000100',
        'DIAMOND_SMALL': '0000000100010100010000000',
        'SQUARE': '1111110001100011000111111',
        'SQUARE_SMALL': '0000001110010100111000000',
        'MUSIC_CROTCHET': '0010000100001001110011100',
        'MUSIC_QUAVER': '0010000110001011110011100',
        'MUSIC_QUAVERS': '0111101001010011101111011',
        'PITCHFORK': '1010110101111110010000100',
        'XMAS': '0010001110001000111011111',
        'PACMAN': '0111111010111001111001111',
        'TARGET': '0010001110110110111000100',
        'TSHIRT': '1101111111011100111001110',
        'ROLLERSKATE': '0001100011111111111101010',
        'DUCK': '0110011100011110111000000',
        'HOUSE': '0010001110111110111001010',
        'TORTOISE': '0000001110111110101000000',
        'BUTTERFLY': '1101111111001001111111011',
        'STICKFIGURE': '0010011111001000101010001',
        'GHOST': '1111110101111111111110101',
        'SWORD': '0010000100001000111000100',
        'GIRAFFE': '1100001000010000111001010',
        'SKULL': '0111010101111110111001110',
        'UMBRELLA': '0111011111001001010001100',
        'SNAKE': '1100011011010100111000000',
    }
    for _name, _digits in _MBIT_CONST_IMAGES.items():
        setattr(_MicroBitImage, _name, _MicroBitImageReadOnly(_digits))
    _MicroBitImage.ALL_CLOCKS = tuple(getattr(_MicroBitImage, 'CLOCK%d' % n) for n in (12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11))
    _MicroBitImage.ALL_ARROWS = (getattr(_MicroBitImage, 'ARROW_' + d) for d in ('N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'))
    _MicroBitImage.ALL_ARROWS = tuple(_MicroBitImage.ALL_ARROWS)

    def _mbit_buf_from_image(img):
        # Trame 5x5 centree sur l'image (les images plus grandes sont recadrees,
        # les plus petites ancrées en haut a gauche), comme le vrai afficheur.
        w, h = img.width(), img.height()
        x0 = (w - 5) // 2 if w > 5 else 0
        y0 = (h - 5) // 2 if h > 5 else 0
        buf = []
        for y in range(5):
            for x in range(5):
                buf.append(img.get_pixel(x0 + x, y0 + y) if x0 + x < w and y0 + y < h else 0)
        return buf

    # --- display ---
    class _MicroBitDisplay:
        def __init__(self):
            self._buf = [0] * 25    # niveaux 0-9, ligne*5 + colonne
            self._on = True        # moteur active au boot par PyRuntime_sync
            self._frames = None    # animation en arriere-plan (show/scroll wait=False)
            self._fi = 0
            self._loop = False
            self._clear_after = False
            self._timer = None

        def _push(self):
            _native.matrix_set_pixels(bytes(self._buf))

        def _set_buf(self, buf):
            self._buf = list(buf)
            self._push()

        def _stop_anim(self):
            if self._timer is not None:
                self._timer.deinit()
                self._timer = None
            self._frames = None

        def _frame(self, x):
            if isinstance(x, _MicroBitImage):
                return _mbit_buf_from_image(x)
            if isinstance(x, (str, int, float)):
                s = str(x)
                if len(s) == 1:
                    rows = _mbit_glyph(s)
                    return [rows[y][c] for y in range(5) for c in range(5)]
                raise ValueError('show one character at a time, or an Image')
            raise TypeError('show() expects an Image, a string or a number')

        def _frames_of(self, image):
            if isinstance(image, (str, int, float)):
                s = str(image)
                return [self._frame(ch) for ch in s]
            return [self._frame(it) for it in image]

        def _play(self, frames, delay, wait, loop, clear):
            if not frames:
                return
            if wait:
                # Premieres trame visible aussitot, sleep entre les suivantes ;
                # loop=True bloque jusqu'a la fin de la simulation (comme le
                # vrai portage, le programme ne rend plus la main).
                self._stop_anim()
                self._set_buf(frames[0])
                while True:
                    for f in frames[1:]:
                        sleep(delay / 1000.0)
                        self._set_buf(f)
                    if not loop:
                        break
                if clear:
                    self.clear()
            else:
                # Arriere-plan : un Timer cache avance les trames (matrix_set_pixels
                # ne rend pas la main a Modelica, appelable depuis un callback).
                self._stop_anim()
                self._frames = frames
                self._fi = 0
                self._loop = loop
                self._clear_after = clear
                self._timer = Timer(period=delay, mode=Timer.PERIODIC, callback=self._tick)

        def _tick(self, timer):
            if self._frames is None:
                return
            self._fi += 1
            if self._fi >= len(self._frames):
                if self._loop:
                    self._fi = 0
                else:
                    self._stop_anim()
                    if self._clear_after:
                        self.clear()
                    return
            self._set_buf(self._frames[self._fi])

        def show(self, image, delay=400, *, wait=True, loop=False, clear=False):
            if isinstance(image, _MicroBitImage) or (isinstance(image, str) and len(image) == 1):
                self._stop_anim()
                self._set_buf(self._frame(image))
                return
            self._play(self._frames_of(image), delay, wait, loop, clear)

        def scroll(self, text, delay=150, *, wait=True, loop=False, monospace=False):
            cols = _mbit_text_columns(str(text), monospace)
            stream = [[0] * 5] * 4 + cols + [[0] * 5] * 4
            frames = []
            for i in range(len(stream) - 4):
                win = stream[i:i + 5]
                frames.append([win[x][y] for y in range(5) for x in range(5)])
            self._play(frames, delay, wait, loop, False)

        def set_pixel(self, x, y, value):
            if not (0 <= x <= 4 and 0 <= y <= 4):
                raise ValueError('x or y is out of bounds')
            self._buf[y * 5 + x] = _MicroBitImage._level(value)
            self._push()

        def get_pixel(self, x, y):
            if not (0 <= x <= 4 and 0 <= y <= 4):
                raise ValueError('x or y is out of bounds')
            return self._buf[y * 5 + x]

        def clear(self):
            self._buf = [0] * 25
            self._push()

        def on(self):
            if not self._on:
                self._stop_anim()
                _native.matrix_enable(*(_MBIT_ROW_IDS + _MBIT_COL_IDS))
                self._on = True
                self._push()

        def off(self):
            self._stop_anim()
            if self._on:
                _native.matrix_disable()
                self._on = False

        def is_on(self):
            return self._on

        def read_light_level(self):
            return int(round(_native.adc_read(_MBIT_LIGHT_ID) * 255))

    # --- broches pin0..pin20 ---
    class _MicroBitPin:
        # MicroBitPin du portage : read_digital/write_digital (0/1),
        # read_analog/write_analog (0-1023, periode 20 ms par defaut),
        # set_pull/get_pull, get_mode (approximatif). Les colonnes de la matrice
        # refusent toute prise de direction tant que l'affichage est actif -
        # cf. _mbit_check.
        def __init__(self, id):
            self.id = id
            self._id = id
            self._mode = 'unused'
            self._pull = 0
            self._period_ms = 20

        def read_digital(self):
            self._mode = 'read_digital'
            return 1 if _native.pin_read(self._id) else 0

        def write_digital(self, value):
            _mbit_check(self._id, 'GPIO', write=True)
            self._mode = 'write_digital'
            _native.pin_init(self._id, 1, self._pull)
            _native.pin_write(self._id, 1 if value else 0)

        def read_analog(self):
            if self._id not in _MBIT_ADC:
                raise ValueError('pin%d has no analog capabilities' % (self._id,))
            _mbit_check(self._id, 'ADC input on GPIO', write=True)
            self._mode = 'read_analog'
            _native.adc_init(self._id)
            return int(round(_native.adc_read(self._id) * 1023))

        def write_analog(self, value):
            _mbit_check(self._id, 'PWM on GPIO', write=True)
            if not (0 <= value <= 1023):
                raise ValueError('value must be 0-1023')
            self._mode = 'write_analog'
            _native.pwm_set_freq(self._id, 1000.0 / self._period_ms)
            _native.pwm_set_duty(self._id, value / 1023.0)

        def set_analog_period(self, ms):
            if not (0 < ms):
                raise ValueError('period must be positive')
            self._period_ms = ms

        def set_analog_period_microseconds(self, us):
            if not (0 < us):
                raise ValueError('period must be positive')
            self._period_ms = us / 1000.0

        def set_pull(self, mode):
            # Pin.PULL_UP/PULL_DOWN de machine (le vrai portage v2 expose les
            # memes constantes), None ou 0 pour couper le tirage.
            _mbit_check(self._id, 'GPIO', write=True)
            if mode not in (None, 0, 1, 2):
                raise ValueError('pull must be None, Pin.PULL_UP or Pin.PULL_DOWN')
            self._pull = 0 if mode is None else mode
            _native.pin_init(self._id, -1, self._pull)

        def get_pull(self):
            return self._pull

        def get_mode(self):
            if self._id in _MBIT_COLS and _mbit_display._on:
                return 'display'
            return self._mode

    # --- boutons A/B ---
    class _MicroBitButton:
        # Tirage externe 10 k de la carte : HIGH au repos, LOW appuye. Les
        # appuis sont comptes par une IRQ interne sur les deux fronts (un
        # appui bref entre deux appels n'est pas perdu) ; l'inscription de
        # l'IRQ est differee au premier appel : aucune native a l'init du shim.
        # was_pressed() et get_presses() ont des compteurs independants, comme
        # sur la vraie carte (appeler l'un ne consomme pas les appuis vus par
        # l'autre).
        def __init__(self, id):
            self._id = id
            self._count = 0
            self._seen_was = 0
            self._seen_get = 0
            self._armed = False

        def _ensure_irq(self):
            if not self._armed:
                self._armed = True
                _native.pin_init(self._id, 0, 0)
                _native.pin_irq_set(self._id, self, self._edge, Pin.IRQ_RISING | Pin.IRQ_FALLING)

        def _edge(self, pin_self):
            if not _native.pin_read(self._id):
                self._count += 1

        def is_pressed(self):
            self._ensure_irq()
            return not _native.pin_read(self._id)

        def was_pressed(self):
            self._ensure_irq()
            n = self._count
            r = n > self._seen_was
            self._seen_was = n
            return r

        def get_presses(self):
            self._ensure_irq()
            n = self._count
            r = n - self._seen_get
            self._seen_get = n
            return r

    # --- capteurs integres : pseudo-broches ADC alimentees par le modele ---
    class _MicroBitAccelerometer:
        # ±2 g (LSM303AGR), valeurs du modele en m/s^2, API en milli-g comme la
        # reference. Gestes : orientation deduite de la gravite (face up/down,
        # up/down/left/right), freefall si |a| < 300 mg ; shake/3g/6g/8g sans
        # dynamique en simulation, toujours faux.
        def __init__(self):
            self._counts = {}
            self._last = None

        def _mg(self, i):
            return int(round((2.0 * _native.adc_read(_MBIT_ACCEL_IDS[i]) - 1.0) * 2000))

        def get_x(self):
            return self._mg(0)

        def get_y(self):
            return self._mg(1)

        def get_z(self):
            return self._mg(2)

        def get_values(self):
            return (self.get_x(), self.get_y(), self.get_z())

        def current_gesture(self):
            x, y, z = self.get_values()
            ax, ay, az = abs(x), abs(y), abs(z)
            if max(ax, ay, az) < 300:
                g = 'freefall'
            elif az >= ax and az >= ay:
                g = 'face up' if z < 0 else 'face down'
            elif ay >= ax:
                g = 'up' if y > 0 else 'down'
            else:
                g = 'right' if x > 0 else 'left'
            if g != self._last:
                self._counts[g] = self._counts.get(g, 0) + 1
                self._last = g
            return g

        def is_gesture(self, name):
            return self.current_gesture() == name

        def was_gesture(self, name):
            n = self._counts.get(name, 0)
            self._counts[name] = 0
            return n > 0

        def get_gestures(self):
            out = [k for k, v in self._counts.items() if v]
            self._counts = {}
            return out

    class _MicroBitCompass:
        # ±200 µT (valeurs du modele), API en nano-tesla comme la reference.
        # calibration instantanee en simulation (le vrai jeu de calibration
        # n'a pas de sens sans utilisateur qui tourne la carte).
        def __init__(self):
            self._calibrated = False

        def calibrate(self):
            self._calibrated = True
            print('microbit.compass.calibrate(): instant in the simulation')

        def is_calibrated(self):
            return self._calibrated

        def clear_calibration(self):
            self._calibrated = False

        def _nt(self, i):
            return int(round((2.0 * _native.adc_read(_MBIT_MAG_IDS[i]) - 1.0) * 200000))

        def get_x(self):
            return self._nt(0)

        def get_y(self):
            return self._nt(1)

        def get_z(self):
            return self._nt(2)

        def heading(self):
            if not self._calibrated:
                raise RuntimeError('compass not calibrated - call compass.calibrate() first')
            x, y = self._nt(0), self._nt(1)
            return int(round(math.atan2(y, x) * 180.0 / math.pi)) % 360

        def get_field_strength(self):
            x, y, z = self._nt(0), self._nt(1), self._nt(2)
            return int(round(math.sqrt(x * x + y * y + z * z)))

    # --- uart : pas de console USB en simulation, tx/rx obligatoires ---
    class _MicroBitUart:
        ODD = 1
        EVEN = 0

        def __init__(self):
            self._u = None

        def init(self, baudrate=9600, bits=8, parity=None, stop=1, *, tx=None, rx=None):
            if tx is None or rx is None:
                raise ValueError('the simulated micro:bit has no USB serial console - give pins, e.g. uart.init(115200, tx=pin0, rx=pin1)')
            if bits != 8:
                raise ValueError('the micro:bit supports 8 data bits')
            if stop != 1:
                raise ValueError('the micro:bit supports 1 stop bit')
            if parity not in (None, 0, 1):
                raise ValueError('parity must be None, uart.ODD or uart.EVEN')
            self._u = UART(0, baudrate=baudrate, bits=8, parity=parity, stop=1, tx=_pin_id(tx), rx=_pin_id(rx))

        def write(self, buf):
            if self._u is None:
                raise RuntimeError('uart not initialised - call uart.init(...)')
            return self._u.write(buf)

        def any(self):
            if self._u is None:
                raise RuntimeError('uart not initialised - call uart.init(...)')
            return self._u.any()

        def read(self, nbytes=None):
            if self._u is None:
                raise RuntimeError('uart not initialised - call uart.init(...)')
            return self._u.read(nbytes)

        def readinto(self, buf, nbytes=None):
            if self._u is None:
                raise RuntimeError('uart not initialised - call uart.init(...)')
            if nbytes is None:
                nbytes = len(buf)
            data = self._u.read(nbytes)
            if data:
                buf[:len(data)] = data
                return len(data)
            return None

        def readline(self):
            if self._u is None:
                raise RuntimeError('uart not initialised - call uart.init(...)')
            return self._u.readline()

    # --- i2c : defauts reels de la v2 (SCL = P19, SDA = P20, tirages 4,7 k
    # poses par la carte, cable par le modele) ---
    class _MicroBitI2c:
        def __init__(self):
            self._bus = None

        def init(self, freq=100000, sda=None, scl=None):
            sda = 20 if sda is None else _pin_id(sda)
            scl = 19 if scl is None else _pin_id(scl)
            self._bus = I2C(0, scl=scl, sda=sda, freq=freq)

        def _ready(self):
            if self._bus is None:
                raise RuntimeError('i2c not initialised - call i2c.init(...)')
            return self._bus

        def scan(self):
            return self._ready().scan()

        def read(self, addr, n, repeat=False):
            return self._ready().readfrom(addr, int(n), stop=not repeat)

        def write(self, addr, buf, repeat=False):
            return self._ready().writeto(addr, bytes(buf), stop=not repeat)

    def _mbit_temperature():
        return int(round(_native.adc_read(_MBIT_TEMP_ID) * 100 - 20))

    def _mbit_panic(n=255):
        print('PANIC %d' % (n,))
        raise SystemExit

    def _mbit_reset():
        print('microbit.reset() is not simulated - the program stops (no restart, cf. documentation)')
        raise SystemExit

    def _mbit_scale(value, from_, to):
        lo, hi = from_
        dlo, dhi = to
        if hi == lo:
            raise ValueError('empty source range')
        out = (value - lo) * (dhi - dlo) / (hi - lo) + dlo
        if isinstance(dlo, int) and isinstance(dhi, int):
            return int(round(out))
        return out

    _mbit_display = _MicroBitDisplay()
    _microbit = types.ModuleType('microbit')
    _microbit.display = _mbit_display
    _microbit.Image = _MicroBitImage
    _microbit.button_a = _MicroBitButton(5)
    _microbit.button_b = _MicroBitButton(11)
    _microbit.accelerometer = _MicroBitAccelerometer()
    _microbit.compass = _MicroBitCompass()
    _microbit.uart = _MicroBitUart()
    _microbit.i2c = _MicroBitI2c()
    _microbit.temperature = _mbit_temperature
    _microbit.panic = _mbit_panic
    _microbit.reset = _mbit_reset
    _microbit.scale = _mbit_scale
    _microbit.sleep = sleep_ms
    _microbit.running_time = ticks_ms
    for _n in _MBIT_PINS:
        setattr(_microbit, 'pin%d' % (_n,), _MicroBitPin(_n))
    sys.modules['microbit'] = _microbit

# --- Systeme de fichiers (flash simulee) ---
#
# Si MCU.fsEnabled, le dossier MCU.fsSource (vide = flash vierge) est recopie a
# l'initialisation dans un nouveau dossier de l'espace de travail MCU.fsWorkspace
# (vide ou relatif = depuis le dossier de simulation), nomme
# <instance>_<nom du FS>_<date>_<heure>. La source n'est jamais
# touchee : chaque simulation repart du meme etat. Le script voit cette copie
# comme la racine "/" de la flash : open() et le module os facon MicroPython y
# sont cloisonnes, et rien de ce qu'il peut observer ne depend de l'horodatage
# ni du disque hote (chemins, dates de modification, ordre des listdir), pour
# que la simulation reste deterministe. Cf. requirements.md, decision
# "Systeme de fichiers".
#
# Le cloisonnement ne vise que le code du microcontroleur : les appels venant
# d'un autre thread (scripts de peripheriques, qui partagent l'interpreteur) ou
# de la stdlib (qui a besoin du vrai disque, ex. linecache pour les traces)
# passent au vrai open()/os. Pedagogique, pas une barriere de securite : io.open
# ou pathlib restent des echappatoires pour qui les cherche.

_FS_BLOCK = 4096
_FS_BLOCKS = 352          # 1,4 Mo : taille de la flash utilisateur du Pico sous MicroPython
_FS_DIR = 0x4000          # types de os.stat()/os.ilistdir(), valeurs MicroPython
_FS_FILE = 0x8000
_fs_root = None           # dossier hote de la copie ; None = pas de systeme de fichiers
_fs_cwd = '/'
_fs_stdlib = ()           # prefixes de co_filename du code de la stdlib, jamais cloisonne
_host_open = _builtins.open
_host_import = _builtins.__import__
_fs_files = _weakref.WeakSet()   # fichiers ouverts par le programme, fermes en fin de simulation

def _fs_err(code):
    # Message MicroPython ("[Errno 2] ENOENT") plutot que celui de l'hote, qui
    # contiendrait le chemin reel de la copie, donc l'horodatage.
    return OSError(code, _errno.errorcode.get(code, 'EIO'))

def _fs_call(fn, *args):
    try:
        return fn(*args)
    except OSError as e:
        raise _fs_err(e.errno or _errno.EIO) from None

def _fs_host_dir(p):
    if p[:8].lower() == 'file:///':
        p = p[8:]
    p = _host_os.path.abspath(p.strip())
    return _host_os.path.dirname(p) if _host_os.path.isfile(p) else p

def _fs_name(s):
    return ''.join(c if c.isalnum() or c in '-_' else '_' for c in s) or 'fs'

def _fs_mount():
    global _fs_root, _fs_stdlib
    enabled, source, workspace, instance, home = _native.fs_config()
    _fs_stdlib = (_host_os.path.normcase(_host_os.path.abspath(home)) + _host_os.sep, '<frozen ')
    # Debogage (MCU.debugEnabled) : le code de debugpy, qui evalue des
    # expressions sur ce thread, n'est pas celui du microcontroleur non plus.
    _debug = sys.modules.get('_mcu_debug')
    if _debug is not None and _debug.DEBUGPY_DIR:
        _fs_stdlib += (_host_os.path.normcase(_host_os.path.abspath(_debug.DEBUGPY_DIR)) + _host_os.sep,)
    if not enabled:
        return
    ws = _fs_host_dir(workspace or '.')
    src = None
    name = 'blank'
    if source:
        src = _fs_host_dir(source)
        if not _host_os.path.isdir(src):
            raise OSError('source file system not found: %s' % src)
        nsrc, nws = _host_os.path.normcase(src), _host_os.path.normcase(ws)
        if nws == nsrc or nws.startswith(nsrc.rstrip(_host_os.sep) + _host_os.sep):
            # Chaque copie serait recopiee dans la suivante : le contenu de la
            # flash dependrait des simulations precedentes.
            raise OSError('the workspace (%s) must not be inside the source file system (%s)' % (ws, src))
        name = _host_os.path.basename(src.rstrip('\\/'))
    d = _host_datetime.datetime.now()
    base = '%s_%s_%04d-%02d-%02d_%02d-%02d-%02d' % (
        _fs_name(instance.split('.')[-1]), _fs_name(name),
        d.year, d.month, d.day, d.hour, d.minute, d.second)
    _host_os.makedirs(ws, exist_ok=True)
    dest = _host_os.path.join(ws, base)
    n = 2
    while _host_os.path.exists(dest):
        dest = _host_os.path.join(ws, '%s_%d' % (base, n))
        n += 1
    if src:
        _host_shutil.copytree(src, dest, ignore=_host_shutil.ignore_patterns('__pycache__'))
    else:
        _host_os.mkdir(dest)
    _fs_root = dest
    _native.fs_set_root(dest)
    # Pas de __pycache__ dans la copie : il apparaitrait dans os.listdir('/lib').
    sys.dont_write_bytecode = True
    # Comme sur la carte : la racine et /lib de la flash sont sur le chemin d'import.
    sys.path.append(dest)
    sys.path.append(_host_os.path.join(dest, 'lib'))
    print('File system: workspace %s' % ws)
    print('File system: copy of %s created in %s' % (src or 'the blank flash', dest))

def _fs_user(depth):
    # Vrai si le code appelant (depth cadres au-dessus de l'appelant de
    # _fs_user) est celui du microcontroleur et pas celui de la stdlib.
    if not _native.on_worker():
        return False
    try:
        f = sys._getframe(depth + 1)
    except ValueError:
        return False
    # __file__ du module plutot que co_filename : les modules de la stdlib
    # charges depuis python312.zip ont un co_filename relatif ("ctypes\
    # __init__.py"), mais un __file__ dans le zip, donc sous home. Le programme
    # du microcontroleur tourne dans __main__, sans __file__ : co_filename est
    # alors le chemin de son fichier (cf. run_source, pyruntime_module.c).
    name = f.f_globals.get('__file__') or f.f_code.co_filename
    return not _host_os.path.normcase(name).startswith(_fs_stdlib)

def _fs_path(path):
    # Chemin MicroPython (absolu ou relatif au dossier courant) -> (chemin
    # normalise vu du script, chemin reel dans la copie). ".." s'arrete a la
    # racine : impossible de sortir de la copie.
    if _fs_root is None:
        raise _fs_err(_errno.ENODEV)
    if isinstance(path, (bytes, bytearray)):
        path = bytes(path).decode()
    if not isinstance(path, str):
        raise TypeError('path expected (str), not %s' % type(path).__name__)
    if any(c in path for c in '\\:*?"<>|\0'):
        raise _fs_err(_errno.EINVAL)   # separateurs et caracteres propres a Windows
    parts = []
    for part in (path if path.startswith('/') else _fs_cwd + '/' + path).split('/'):
        if part in ('', '.'):
            continue
        if part == '..':
            if parts:
                parts.pop()
        else:
            parts.append(part)
    return '/' + '/'.join(parts), _host_os.path.join(_fs_root, *parts)

def _fs_open(file, mode='r', buffering=-1, encoding=None, errors=None, newline=None, closefd=True, opener=None):
    if isinstance(file, int) or not _fs_user(1):
        return _host_open(file, mode, buffering, encoding, errors, newline, closefd, opener)
    real = _fs_path(file)[1]
    if _host_os.path.isdir(real):
        raise _fs_err(_errno.EISDIR)
    if 'b' not in mode:
        # Comme MicroPython : UTF-8, et aucune traduction des fins de ligne
        # (sinon "\n" deviendrait "\r\n" sur un hote Windows).
        encoding = encoding or 'utf-8'
        newline = '' if newline is None else newline
    f = _fs_call(_host_open, real, mode, buffering, encoding, errors, newline)
    _fs_files.add(f)
    return f

def _fs_close_files():
    # Fin de simulation (fin du sous-interpreteur, cf. PyRuntime_destroy) : les
    # fichiers que le programme n'a pas fermes le sont ici, tampons vides sur
    # disque. Sans cela, ils restaient ouverts jusqu'a la fin du process et
    # leurs dernieres ecritures etaient perdues (constate : l'espace de noms
    # __main__, que le programme partage avec le shim, survit a la
    # finalisation des modules - une simple reference faible sur __main__
    # suffisait a changer ce comportement, d'ou une fermeture explicite plutot
    # que de compter sur le ramasse-miettes). Enregistre avant tout atexit du
    # programme, donc execute apres eux.
    for f in list(_fs_files):
        try:
            f.close()
        except Exception:
            pass

_atexit.register(_fs_close_files)

def _fs_import(name, globals=None, locals=None, fromlist=(), level=0):
    # "import os" (ou uos) depuis le code du microcontroleur donne le module os
    # de MicroPython ; la stdlib, elle, garde le vrai.
    if level == 0 and (name in ('os', 'uos') or name.startswith('os.')) and _fs_user(1):
        return _fs_os
    return _host_import(name, globals, locals, fromlist, level)

def _os_getcwd():
    _fs_path('/')
    return _fs_cwd

def _os_chdir(path):
    global _fs_cwd
    virt, real = _fs_path(path)
    if not _host_os.path.isdir(real):
        raise _fs_err(_errno.ENOENT)
    _fs_cwd = virt

def _os_listdir(path='.'):
    return sorted(_fs_call(_host_os.listdir, _fs_path(path)[1]))

def _os_ilistdir(path='.'):
    real = _fs_path(path)[1]
    for name in _os_listdir(path):
        p = _host_os.path.join(real, name)
        if _host_os.path.isdir(p):
            yield (name, _FS_DIR, 0, 0)
        else:
            yield (name, _FS_FILE, 0, _host_os.path.getsize(p))

def _os_mkdir(path):
    _fs_call(_host_os.mkdir, _fs_path(path)[1])

def _os_rmdir(path):
    virt, real = _fs_path(path)
    if virt == '/':
        raise _fs_err(_errno.EACCES)
    _fs_call(_host_os.rmdir, real)

def _os_remove(path):
    real = _fs_path(path)[1]
    if _host_os.path.isdir(real):
        raise _fs_err(_errno.EISDIR)
    _fs_call(_host_os.remove, real)

def _os_rename(old, new):
    old_virt, old_real = _fs_path(old)
    new_virt, new_real = _fs_path(new)
    if old_virt == '/' or new_virt == '/':
        raise _fs_err(_errno.EACCES)
    _fs_call(_host_os.replace, old_real, new_real)   # remplace une cible existante, comme littlefs

def _os_stat(path):
    # Dates a zero : celles de l'hote dependraient de l'instant de la copie.
    real = _fs_path(path)[1]
    if _host_os.path.isdir(real):
        return (_FS_DIR, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    return (_FS_FILE, 0, 0, 0, 0, 0, _fs_call(_host_os.path.getsize, real), 0, 0, 0)

def _os_statvfs(path='/'):
    # Taille de la flash du Pico ; blocs occupes calcules d'apres le contenu
    # (un bloc par dossier, arrondi au bloc pour chaque fichier), donc stables
    # d'une simulation a l'autre.
    _fs_path(path)
    used = 0
    for dirpath, dirnames, filenames in _host_os.walk(_fs_root):
        used += 1
        for f in filenames:
            used += -(-_host_os.path.getsize(_host_os.path.join(dirpath, f)) // _FS_BLOCK)
    free = max(0, _FS_BLOCKS - used)
    return (_FS_BLOCK, _FS_BLOCK, _FS_BLOCKS, free, free, 0, 0, 0, 0, 255)

def _os_sync():
    pass

class _Uname(tuple):
    sysname = property(lambda self: self[0])
    nodename = property(lambda self: self[1])
    release = property(lambda self: self[2])
    version = property(lambda self: self[3])
    machine = property(lambda self: self[4])

def _os_uname():
    return _Uname(('rp2', 'rp2', '1.23.0', 'v1.23.0 (simulation MicroPythonMCU)', 'MCU simule (API RP2040)'))

_fs_os = types.ModuleType('os')
_fs_os.sep = '/'
_fs_os.getcwd = _os_getcwd
_fs_os.chdir = _os_chdir
_fs_os.listdir = _os_listdir
_fs_os.ilistdir = _os_ilistdir
_fs_os.mkdir = _os_mkdir
_fs_os.rmdir = _os_rmdir
_fs_os.remove = _os_remove
_fs_os.rename = _os_rename
_fs_os.stat = _os_stat
_fs_os.statvfs = _os_statvfs
_fs_os.sync = _os_sync
_fs_os.uname = _os_uname

_fs_mount()
_builtins.open = _fs_open
_builtins.__import__ = _fs_import
