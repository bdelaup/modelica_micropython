# ---------------------------------------------------------------------------
# Default script of Peripherals.UartGpsModule (behaviour = Script).
#
# Transmits a complete NMEA RMC sentence at each period: UTC time, validity,
# latitude and longitude in degrees-minutes format with their hemisphere, speed,
# date, and CHECKSUM. This is what the command table cannot do - it is
# limited to substituting values into a fixed template.
#
# Quantities received from the model (valueIn):
#   v[0] latitude  (decimal degrees, positive north)
#   v[1] longitude (decimal degrees, positive east)
#   v[2] speed     (knots)
# Quantity returned to the model (valueOut):
#   [1] number of sentences transmitted since the start of the simulation
#
# Contract of a peripheral script: see the user guide, page "Serial devices (UART)".
# The functions run on the simulation thread: they run to completion,
# without sleep() and without access to machine.
# ---------------------------------------------------------------------------

START_TIME_S = 12 * 3600        # the UTC clock of the module starts at 12:00:00
DATE = '250926'                 # ddmmyy
sentences = 0                   # persists from one call to the next


def _degrees_minutes(value, positive, negative, degree_width):
    """47.24 -> ('4714.4000', 'N'); 5.9876 -> ('00559.2560', 'E')."""
    hemisphere = positive if value >= 0 else negative
    value = abs(value)
    degrees = int(value)
    minutes = (value - degrees) * 60.0
    return '%0*d%07.4f' % (degree_width, degrees, minutes), hemisphere


def _utc_time(t):
    s = START_TIME_S + t
    h = int(s // 3600) % 24
    m = int(s // 60) % 60
    return '%02d%02d%05.2f' % (h, m, s % 60)


def _checksum(body):
    """Exclusive OR of all the characters between '$' and '*'."""
    x = 0
    for c in body:
        x ^= ord(c)
    return '%02X' % x


def on_tick(t, v):
    global sentences
    lat, ns = _degrees_minutes(v[0], 'N', 'S', 2)
    lon, ew = _degrees_minutes(v[1], 'E', 'W', 3)
    body = 'GPRMC,%s,A,%s,%s,%s,%s,%.1f,0.0,%s,,' % (
        _utc_time(t), lat, ns, lon, ew, v[2], DATE)
    sentences += 1
    return '$%s*%s\r\n' % (body, _checksum(body))


def outputs():
    return sentences
