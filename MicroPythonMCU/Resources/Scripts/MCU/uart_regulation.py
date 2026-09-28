from machine import Pin, UART
import time

# Control loop closed ENTIRELY inside the model, through the serial link
# alone:
#
#   microcontroller --AT+TEMP--> sensor --{v1}--> reads valueIn  (the measurement)
#   microcontroller --SET x----> sensor --{o1}--> writes valueOut (the command)
#   valueOut --> thermal model (FirstOrder) --> valueIn
#
# The sensor is therefore not only a sensor: the command it republishes
# on its real output drives the plant, whose response comes back on its
# input. No extra wire, everything goes through the same two pins.
BAUD = 9600
TIMEOUT_MS = 200
SETPOINT = 40.0       # degC
PLANT_GAIN = 0.5      # degC per command unit, in steady state
KP = 4.0              # proportional gain of the controller
CMD_MIN, CMD_MAX = 0.0, 100.0
CYCLES = 18

uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))


def request(command):
    uart.write(command)
    line = b''
    deadline = time.ticks_ms() + TIMEOUT_MS
    while time.ticks_diff(deadline, time.ticks_ms()) > 0:
        if uart.any():
            line += uart.read()
            if line.endswith(b'\n'):
                return line
        else:
            time.sleep_ms(1)
    return line


def measure():
    try:
        return float(request(b'AT+TEMP\n').split(b'=')[1].strip())
    except Exception:
        return None


time.sleep_ms(10)

for i in range(CYCLES):
    t = measure()
    if t is None:
        continue
    # Proportional controller with compensation of the static gain of the plant.
    cmd = SETPOINT / PLANT_GAIN + KP * (SETPOINT - t)
    if cmd < CMD_MIN:
        cmd = CMD_MIN
    elif cmd > CMD_MAX:
        cmd = CMD_MAX
    request(b'SET %.1f\n' % cmd)
    print("cycle", i, "measurement", t, "command", cmd)

print("Control: setpoint", SETPOINT, "last measurement", measure())
