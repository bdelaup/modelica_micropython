# ---------------------------------------------------------------------------
# Default script of Peripherals.UartTemperatureSensor (behaviour = Script).
#
# Reproduces the command table of Table mode, and adds what a table
# cannot do: answer ERR to an unknown or malformed command, like
# any real AT module, instead of staying silent.
#
#   AT+TEMP    -> TEMP=<valueIn[1]>
#   AT+ID      -> SIM-TEMP-1
#   SET <x>    -> OK, and x comes out on valueOut[1]
#   other      -> ERR
#
# Contract of a peripheral script: see the user guide, page "Serial devices (UART)".
# ---------------------------------------------------------------------------

setpoint = 0.0      # last setpoint received, published on valueOut[1]


def on_receive(line, t, v):
    global setpoint
    if line == b'AT+TEMP':
        return 'TEMP=%.1f\r\n' % v[0]
    if line == b'AT+ID':
        return b'SIM-TEMP-1\r\n'
    if line.startswith(b'SET '):
        try:
            setpoint = float(line[4:])
        except ValueError:
            return b'ERR\r\n'
        return b'OK\r\n'
    return b'ERR\r\n'


def outputs():
    return setpoint
