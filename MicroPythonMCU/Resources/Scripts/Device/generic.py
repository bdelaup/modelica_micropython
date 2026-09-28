# ---------------------------------------------------------------------------
# Default script of Peripherals.UartGenericDevice (behaviour = Script).
# Starting point to copy when describing a new serial device.
#
# The script is run ONCE, when the component is built. Its module variables
# then persist from one call to the next: this is where the state of the
# device lives. Two instances of the same file each have their own.
#
# Three functions, all optional:
#
#   on_receive(line, t, v)   called once per complete line received
#       line  : bytes, without the terminator
#       t     : simulated time (s)
#       v     : tuple of the quantities of the valueIn connector
#       return: bytes or str to transmit (after responseDelay), or None
#
#   on_tick(t, v)            called every `period` seconds, if defined
#       return: bytes or str to transmit, or None
#
#   outputs()                read again after each call of the two above
#       return: a number or a sequence of numbers -> valueOut connector
#
# These functions run on the simulation thread: they must run to completion
# without waiting. No sleep(), no access to machine - to delay a reply,
# the responseDelay parameter takes care of it. print() is prefixed with
# the component name in the simulation log.
# ---------------------------------------------------------------------------

received = 0


def on_receive(line, t, v):
    global received
    received += 1
    return b'ACK ' + line + b'\r\n'


# def on_tick(t, v):
#     return 'VAL=%.2f\r\n' % v[0]


def outputs():
    return received
