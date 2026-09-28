# ---------------------------------------------------------------------------
# Default script of Peripherals.UartEchoDevice (behaviour = Script).
#
# The shortest of the peripheral scripts: sends back each received line.
#
# Difference with Table mode: there, the echo is done BYTE BY BYTE, as soon as
# each one is decoded. Here, a script only sees complete LINES - the echo
# therefore only leaves once the terminator has been received, followed by a line feed.
# ---------------------------------------------------------------------------


def on_receive(line, t, v):
    return line + b'\n'
