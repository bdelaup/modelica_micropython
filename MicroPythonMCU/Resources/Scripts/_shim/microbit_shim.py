# Module `microbit` et module `radio` du profil « micro:bit v2 » (nRF52833).
#
# Ce fichier n'est PAS execute directement : machine_time_shim.py le charge
# (exec dans les globales du shim) uniquement quand le profil de carte est
# « microbit » - les autres cartes ne le compilent pas. Il s'execute dans
# l'espace de noms du shim, dont il partage toutes les globales : les classes
# machine/time (Pin, ADC, PWM, UART, I2C, sleep_ms, ticks_ms...), _mbit_check,
# le module natif _native ; en retour ses objets (_mbit_display, _MicroBitPin...)
# restent visibles du shim (_mbit_check et _pin_id les utilisent).
#
# L'API officielle du portage MicroPython de la micro:bit, construite par-dessus
# machine et le moteur de matrice LED du C (pyruntime_matrix.c), comme le vrai
# portage v2 qui expose aussi machine. Cf. requirements.md, decision « MCU
# micro:bit v2 » : display (matrice 5x5 multiplexee sur 10 GPIO, balayee a
# 60 Hz par le C), boutons A/B (P5/P11, tirage externe 10 k de la carte,
# appuye = LOW), capteurs integres lus comme des pseudo-broches ADC (valeurs
# fournies par le modele), uart/i2c (enveloppes de machine aux defauts micro:bit).
#
# ATTENTION : ce code s'execute pendant l'init du worker, AVANT le premier tour
# - aucune native qui rend la main a Modelica ici (deadlock, cf.
# matrix_boot_enable). Le display nait « on » sans rien appeler : c'est
# PyRuntime_sync qui active le moteur a la premiere synchro alimentee, comme le
# firmware active son driver d'affichage au boot. Tout ce qui appelle une
# native (display.on(), boutons, animations) est differe au premier appel.
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

# radio : le module du portage micro:bit, autonome (import radio) et
# aussi attache a microbit (microbit.radio) par commodite. Le protocole
# par paquets vit cote C (pyruntime_radio.c) : filtrage
# channel/group/address, file de reception de profondeur queue, duree de
# trame a l'air au debit data_rate. La config garde ici l'etat courant
# (meme defauts que le firmware) et repasse les SEPT valeurs a chaque
# radio.config() - la native n'a pas a se souvenir d'un "None veut dire
# inchange".
_radio_cfg = dict(length=32, queue=3, channel=7, power=6,
                  address=0x75626974, group=0, data_rate=1)

def _radio_on():
    _native.radio_on()

def _radio_off():
    _native.radio_off()           # le firmware vide la file, la config est conservee

def _radio_config(length=None, queue=None, channel=None, power=None,
                  address=None, group=None, data_rate=None):
    checks = (
        (length, 'length', 1, 251),
        (queue, 'queue', 0, 32),
        (channel, 'channel', 0, 100),
        (power, 'power', 0, 7),
        (group, 'group', 0, 255),
        (data_rate, 'data_rate', 1, 2),
    )
    for value, name, lo, hi in checks:
        if value is not None and not (lo <= value <= hi):
            raise ValueError('invalid %s %r (%d-%d expected)' % (name, value, lo, hi))
    if address is not None and not (0 <= address <= 2147483647):
        raise ValueError('invalid address %r (0-2147483647 expected)' % (address,))
    if length is not None:
        _radio_cfg['length'] = int(length)
    if queue is not None:
        _radio_cfg['queue'] = int(queue)
    if channel is not None:
        _radio_cfg['channel'] = int(channel)
    if power is not None:
        _radio_cfg['power'] = int(power)       # accepte, pas simule (pas de portee)
    if address is not None:
        _radio_cfg['address'] = int(address)
    if group is not None:
        _radio_cfg['group'] = int(group)
    if data_rate is not None:
        _radio_cfg['data_rate'] = int(data_rate)
    _native.radio_config(_radio_cfg['length'], _radio_cfg['queue'],
                         _radio_cfg['channel'], _radio_cfg['power'],
                         _radio_cfg['address'], _radio_cfg['group'],
                         _radio_cfg['data_rate'])

def _radio_send_bytes(message):
    _native.radio_send_bytes(bytes(message))

def _radio_receive_bytes():
    return _native.radio_read_bytes()         # bytes, ou None

def _radio_receive_bytes_into(buffer):
    b = _radio_receive_bytes()
    if b is None:
        return None
    if len(buffer) < len(b):
        raise ValueError('buffer too small (%d bytes, %d received)' % (len(buffer), len(b)))
    buffer[:len(b)] = b

def _radio_send(message):
    _radio_send_bytes(message.encode('utf-8') if isinstance(message, str) else bytes(message))

def _radio_receive():
    b = _radio_receive_bytes()
    return None if b is None else b.decode('utf-8')

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
_mbit_radio = types.ModuleType('radio')
_mbit_radio.RATE_1MBIT = 1
_mbit_radio.RATE_2MBIT = 2
_mbit_radio.on = _radio_on
_mbit_radio.off = _radio_off
_mbit_radio.config = _radio_config
_mbit_radio.send_bytes = _radio_send_bytes
_mbit_radio.receive_bytes = _radio_receive_bytes
_mbit_radio.receive_bytes_into = _radio_receive_bytes_into
_mbit_radio.send = _radio_send
_mbit_radio.receive = _radio_receive
sys.modules['radio'] = _mbit_radio
_microbit.radio = _mbit_radio
