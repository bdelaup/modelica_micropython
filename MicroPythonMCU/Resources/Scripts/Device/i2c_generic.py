# ---------------------------------------------------------------------------
# Default script of Peripherals.I2cGenericDevice: starting point to copy
# when describing a new I2C slave peripheral. It models here the most
# common case, a REGISTER BANK with an auto-incremented pointer (like
# most sensors, EEPROMs, LED drivers...).
#
# The script is run ONCE, when the component is built. Its module variables
# then persist from one call to the next: this is where the state of the
# peripheral lives. Two instances of the same file each have their own.
#
# The component handles the protocol on its own (START, address, acknowledges,
# STOP): the script only sees TRANSACTIONS. Four functions, all optional:
#
#   on_write(addr, data, t, v)   a write phase addressed to it has just
#                                ended (STOP or repeated START)
#       addr : 7-bit address used by the master (useful if the component
#              has several, see the addresses parameter)
#       data : bytes received (never empty)
#       t    : simulated time (s)
#       v    : tuple of the quantities of the valueIn connector
#
#   on_read(addr, t, v)          the master starts reading
#       return : the bytes to send to it - bytes, str, list of integers or
#                integer. They go out one by one; if the master reads more,
#                on_read is called again (and 0xFF goes out if it returns nothing)
#
#   outputs()                    read again after each call -> valueOut connector
#       return : a number or a sequence of numbers
#
#   lines()                      read again after each call -> text shown on
#                                the icon of a screen (line1, line2)
#       return : one string, or two
#
# These functions run on the simulation thread: they must run to completion
# without waiting. No sleep(), no access to machine. print() is
# prefixed with the component name in the simulation log.
#
# On the microcontroller side, this template answers:
#   i2c.writeto_mem(0x42, 3, b'\x10\x20')   # writes registers 3 and 4
#   i2c.readfrom_mem(0x42, 3, 2)            # reads back b'\x10\x20'
# ---------------------------------------------------------------------------

registers = bytearray(16)
pointer = 0


def on_write(addr, data, t, v):
    global pointer
    # First byte: register number; the following ones are written from there on.
    pointer = data[0] % len(registers)
    for byte in data[1:]:
        registers[pointer] = byte
        pointer = (pointer + 1) % len(registers)


def on_read(addr, t, v):
    global pointer
    # One byte at a time: the pointer moves on at each byte read.
    value = registers[pointer]
    pointer = (pointer + 1) % len(registers)
    return value


def outputs():
    return registers[0]
