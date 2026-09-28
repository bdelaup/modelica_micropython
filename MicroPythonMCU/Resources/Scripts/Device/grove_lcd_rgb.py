# ---------------------------------------------------------------------------
# Script of Peripherals.I2cGroveLcdRgb: Grove - LCD RGB Backlight screen.
#
# A single module carries TWO chips on the I2C bus, hence two addresses:
#   0x3E  JHD1313: 16x2 character display controller, HD44780-compatible
#   0x62  PCA9633: 4-channel (PWM) LED driver, which drives the RGB
#         backlight (channel 0 = blue, channel 1 = green, channel 2 = red)
# The component decodes the I2C protocol; this script only emulates, byte by
# byte, what these two chips do with the received data - following their
# datasheets, without knowing anything about the program driving them. Any
# driver written for the real module must therefore work unchanged.
#
# Outputs: outputs() -> (red, green, blue, display on), intensities 0-255;
#          lines()   -> the two visible 16-character lines.
# ---------------------------------------------------------------------------

LCD_ADDR = 0x3E          # any other address of the component is the LED driver

COLS = 16                # visible characters per line
LINE_LEN = 40            # the display memory (DDRAM) holds 40 characters per line
CLEAR_DURATION = 1.52e-3 # clear and home are slow (HD44780 datasheet); the rest takes ~40 us

# ======================= JHD1313 (HD44780) =======================
# State at power-up (internal reset): display off, memory empty,
# cursor at the start, writing from left to right.
ddram = bytearray(b' ' * 128)
ac = 0                   # address counter (write position)
increment = True         # I/D: the cursor moves on after each character
entry_shift = False      # S: the display scrolls at each character
display_on = False
two_lines = True         # N: 2 lines (the Grove module is always wired as 16x2)
offset = 0               # display offset (scroll commands)
to_cgram = False         # data sent to the custom characters (not shown here)
busy_until = 0.0         # end of the last slow command (clear, home)


def _next_address(a, step):
    # In 2-line mode, line 1 occupies 0x00-0x27 and line 2 0x40-0x67:
    # the counter jumps from one to the other.
    a = (a + step) & 0x7F
    if two_lines:
        if step > 0 and a == 0x28:
            a = 0x40
        elif step > 0 and a == 0x68:
            a = 0x00
        elif step < 0 and a == 0x3F:
            a = 0x27
        elif step < 0 and a == 0x7F:
            a = 0x67
    return a


def lcd_command(cmd, t):
    global ac, increment, entry_shift, display_on, two_lines, offset, to_cgram, busy_until
    if cmd & 0x80:                      # write position (DDRAM address)
        ac = cmd & 0x7F
        to_cgram = False
    elif cmd & 0x40:                    # custom characters (CGRAM): accepted, not shown
        to_cgram = True
    elif cmd & 0x20:                    # function set
        two_lines = bool(cmd & 0x08)
    elif cmd & 0x10:                    # shift of the cursor or of the whole display
        step = 1 if cmd & 0x04 else -1
        if cmd & 0x08:
            offset = (offset + step) % LINE_LEN
        else:
            ac = _next_address(ac, step)
    elif cmd & 0x08:                    # display on/off, cursor, blink
        display_on = bool(cmd & 0x04)
    elif cmd & 0x04:                    # entry mode
        increment = bool(cmd & 0x02)
        entry_shift = bool(cmd & 0x01)
    elif cmd & 0x02:                    # home
        ac = 0
        offset = 0
        busy_until = t + CLEAR_DURATION
    elif cmd & 0x01:                    # clear
        for i in range(len(ddram)):
            ddram[i] = 0x20
        ac = 0
        offset = 0
        increment = True
        busy_until = t + CLEAR_DURATION


def lcd_data(byte):
    global ac, offset
    if to_cgram:
        return
    ddram[ac] = byte
    ac = _next_address(ac, 1 if increment else -1)
    if entry_shift:
        offset = (offset + (1 if increment else -1)) % LINE_LEN


def lcd_write(data, t):
    # Each data byte is preceded by a CONTROL byte:
    #   bit 7 (Co): 1 = another control byte will follow, 0 = all the rest
    #               of the transaction is data
    #   bit 6 (RS): 0 = command, 1 = character to display
    # The reference driver sends [0x80, command] and [0x40, character].
    if t < busy_until:
        # On the real module, the byte would be lost: the controller is busy.
        print("t=%.4f s: display busy (clear/home started less than %.2f ms ago), bytes ignored:"
              % (t, CLEAR_DURATION * 1e3), data.hex(' '))
        return
    i = 0
    while i < len(data):
        control = data[i]
        i += 1
        rs = control & 0x40
        last = not (control & 0x80)
        while i < len(data):
            if rs:
                lcd_data(data[i])
            else:
                lcd_command(data[i], t)
            i += 1
            if not last:
                break


def _visible(base):
    out = ''
    for col in range(COLS):
        c = ddram[base + (offset + col) % LINE_LEN]
        out += chr(c) if 0x20 <= c <= 0x7D and c != 0x5C else ' '   # ROM A00: ASCII from 0x20 to 0x7D, except 0x5C (yen)
    return out


# ======================= PCA9633 =======================
# Registers: 0 MODE1, 1 MODE2, 2-5 PWM0-PWM3, 6 GRPPWM, 7 GRPFREQ, 8 LEDOUT,
# 9-12 secondary addresses. Values at power-up (datasheet):
# MODE1 = 0x11 (oscillator asleep), LEDOUT = 0 (all channels off).
regs = bytearray([0x11, 0x05, 0, 0, 0, 0, 0xFF, 0x00, 0x00, 0xE2, 0xE4, 0xE8, 0xE0])
pointer = 0
auto_increment = 0       # bits AI2-AI0 of the control byte


def _advance():
    global pointer
    if auto_increment == 0b100:      # all registers
        pointer = (pointer + 1) % len(regs)
    elif auto_increment == 0b101:    # individual brightnesses only
        pointer = 2 if pointer >= 5 else pointer + 1
    elif auto_increment == 0b110:    # group registers only
        pointer = 6 if pointer >= 7 else pointer + 1
    elif auto_increment == 0b111:    # individual + group
        pointer = 2 if pointer >= 7 else pointer + 1


def rgb_write(data):
    global pointer, auto_increment
    # First byte: control register (pointer + auto-increment flags),
    # then the values, written from the pointed register on.
    auto_increment = data[0] >> 5
    pointer = (data[0] & 0x0F) % len(regs)
    for value in data[1:]:
        regs[pointer] = value
        _advance()


def rgb_read():
    value = regs[pointer]
    _advance()
    return value


def _channel(n):
    mode = (regs[8] >> (2 * n)) & 0x03
    asleep = regs[0] & 0x10          # oscillator stopped: no more PWM
    if mode == 0:
        return 0
    if mode == 1:
        return 255                   # channel forced fully on
    if asleep:
        return 0
    if mode == 2:
        return regs[2 + n]
    return regs[2 + n] * regs[6] // 255   # individual PWM x group dimming


# ======================= contract of the component =======================

def on_write(addr, data, t, v):
    if addr == LCD_ADDR:
        lcd_write(data, t)
    else:
        rgb_write(data)


def on_read(addr, t, v):
    if addr == LCD_ADDR:
        return ac        # read of the address counter (busy flag always 0)
    return rgb_read()


def outputs():
    return (_channel(2), _channel(1), _channel(0), 1 if display_on else 0)


def lines():
    if not display_on:
        return ('', '')
    if not two_lines:
        return (_visible(0x00), '')
    return (_visible(0x00), _visible(0x40))
