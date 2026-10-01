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

# CPython avertit a la compilation de tournures que MicroPython accepte sans
# rien dire - typiquement "gain is 128" (driver HX711 de robert-hh). Le code
# fonctionne a l'identique (petits entiers partages), l'avertissement ne ferait
# que polluer le journal de simulation d'un driver du commerce.
_warnings.filterwarnings('ignore', category=SyntaxWarning)

class Pin:
    IN = 0
    OUT = 1
    PULL_UP = 2
    PULL_DOWN = 3
    LED = 25  # doit rester aligne sur LED_PIN_ID cote C (PyRuntimeImpl.c)
    IRQ_RISING = 1   # doit rester aligne sur IRQ_TRIGGER_RISING cote C
    IRQ_FALLING = 2  # doit rester aligne sur IRQ_TRIGGER_FALLING cote C

    def __init__(self, id, mode=None, pull=None):
        if id == 'LED':
            id = Pin.LED
        self.id = id
        if mode is not None:
            _native.pin_init(self.id, 1 if mode == Pin.OUT else 0)

    def value(self, x=None):
        if x is None:
            return 1 if _native.pin_read(self.id) else 0
        _native.pin_write(self.id, 1 if x else 0)

    def __call__(self, x=None):
        # pin() lit, pin(1) ecrit - raccourci de MicroPython, courant dans les drivers
        return self.value(x)

    def on(self):
        _native.pin_write(self.id, 1)

    def off(self):
        _native.pin_write(self.id, 0)

    def toggle(self):
        self.value(0 if self.value() else 1)

    def irq(self, handler=None, trigger=IRQ_RISING | IRQ_FALLING, **kwargs):
        _native.pin_irq_set(self.id, self, handler, trigger)

class ADC:
    def __init__(self, id):
        if isinstance(id, Pin):
            id = id.id
        self.id = id
        _native.adc_init(self.id)   # coupe l'entree numerique de la broche, comme sur le RP2040

    def read_u16(self):
        v = _native.adc_read(self.id)
        raw = round(v / 3.3 * 65535)
        return 0 if raw < 0 else (65535 if raw > 65535 else raw)

class PWM:
    def __init__(self, pin, freq=None, duty_u16=None):
        if isinstance(pin, Pin):
            pin = pin.id
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
    def __init__(self, id=0, **kwargs):
        self.id = id  # kwargs : signature volontairement minimale, composant
                      # pedagogique (Peripherals.Display), pas un vrai protocole

    def write(self, text):
        _native.display_write(self.id, text if isinstance(text, str) else str(text))

class UART:
    # bits/parity/stop sont absorbes par **kwargs : acceptes pour compatibilite
    # d'API mais sans effet, seul le format 8N1 est emis en v0 (meme approche
    # que pull= sur Pin). Le format de trame vit entierement cote C.
    def __init__(self, id=0, baudrate=1200, tx=None, rx=None, **kwargs):
        self.id = id
        self.init(baudrate, tx=tx, rx=rx, **kwargs)

    def init(self, baudrate=1200, tx=None, rx=None, **kwargs):
        if tx is None or rx is None:
            raise ValueError('tx and rx must be given (e.g. UART(0, tx=Pin(0), rx=Pin(1)))')
        if isinstance(tx, Pin):
            tx = tx.id
        if isinstance(rx, Pin):
            rx = rx.id
        self._baudrate = baudrate
        self.tx = tx
        self.rx = rx
        _native.uart_init(self.id, tx, rx, float(baudrate))

    def write(self, data):
        if isinstance(data, str):
            data = data.encode()
        elif not isinstance(data, (bytes, bytearray)):
            data = str(data).encode()
        return _native.uart_write(self.id, bytes(data))

    def any(self):
        return _native.uart_any(self.id)

    def read(self, n=None):
        return _native.uart_read(self.id, -1 if n is None else int(n))

    def readline(self):
        buf = b''
        while True:
            chunk = _native.uart_read(self.id, 1)
            if chunk is None:
                return buf if buf else None
            buf += chunk
            if chunk == b'\n':
                return buf

    def deinit(self):
        _native.uart_deinit(self.id)

class I2C:
    # Maitre I2C en drain ouvert (un seul bus en v0). L'identifiant est
    # facultatif : I2C(0, scl=..., sda=...) (forme rp2) et I2C(scl=..., sda=...)
    # (forme des drivers ecrits pour d'autres ports) sont acceptes tous les deux.
    # Chaque transaction est BLOQUANTE jusqu'a la fin de la sequence sur le bus,
    # en temps simule. Erreurs : OSError(EIO) si l'adresse n'est pas acquittee,
    # OSError(ETIMEDOUT) si une ligne reste basse (bus sans tirage).
    def __init__(self, id=0, *, scl=None, sda=None, freq=400000, **kwargs):
        self.id = id
        self.init(scl=scl, sda=sda, freq=freq, **kwargs)

    def init(self, scl=None, sda=None, freq=400000, **kwargs):
        if scl is None or sda is None:
            raise ValueError('scl and sda must be given (e.g. I2C(0, scl=Pin(4), sda=Pin(5)))')
        if isinstance(scl, Pin):
            scl = scl.id
        if isinstance(sda, Pin):
            sda = sda.id
        self.scl = scl
        self.sda = sda
        self._freq = freq
        _native.i2c_init(self.id, scl, sda, float(freq))

    def deinit(self):
        _native.i2c_deinit(self.id)

    def scan(self):
        trouves = []
        for addr in range(0x08, 0x78):
            try:
                _native.i2c_xfer(self.id, addr, b'', 0, True)
                trouves.append(addr)
            except OSError as e:
                if e.errno == 110:   # ETIMEDOUT : bus bloque, inutile d'insister
                    break
        return trouves

    def writeto(self, addr, buf, stop=True):
        acks, _ = _native.i2c_xfer(self.id, addr, bytes(buf), 0, bool(stop))
        return acks

    def writevto(self, addr, vector, stop=True):
        return self.writeto(addr, b''.join(bytes(b) for b in vector), stop)

    def readfrom(self, addr, nbytes, stop=True):
        _, data = _native.i2c_xfer(self.id, addr, None, int(nbytes), bool(stop))
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
        _, data = _native.i2c_xfer(self.id, addr, I2C._memaddr(memaddr, addrsize), int(nbytes), True)
        return data

    def readfrom_mem_into(self, addr, memaddr, buf, *, addrsize=8):
        data = self.readfrom_mem(addr, memaddr, len(buf), addrsize=addrsize)
        buf[:len(data)] = data

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
        if scl is None or sda is None:
            raise ValueError('scl and sda must be given (e.g. I2CTarget(0, 0x42, scl=Pin(5), sda=Pin(4)))')
        if isinstance(scl, Pin):
            scl = scl.id
        if isinstance(sda, Pin):
            sda = sda.id
        self.id = id
        self._mem = mem          # garde le tampon en vie : le C ecrit dedans
        self._irq = _I2CTargetIRQ()
        _native.i2ct_init(id, addr, addrsize, scl, sda, mem, mem_addrsize)

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

    def __init__(self, id=-1):
        self._slot = _native.timer_new()

    def init(self, period=1000, mode=PERIODIC, callback=None):
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
_machine.SoftI2C = I2C   # meme maitre : en simulation, logiciel ou materiel ne se distinguent pas
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
    if not enabled:
        return
    ws = _fs_host_dir(workspace or '.')
    src = None
    name = 'vierge'
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
    # du microcontroleur tourne dans __main__, sans __file__ : "<string>".
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
    return _fs_call(_host_open, real, mode, buffering, encoding, errors, newline)

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
