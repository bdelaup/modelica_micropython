# ---------------------------------------------------------------------------
# Default script of Peripherals.I2cEchoDevice: what the master writes, it
# reads back. Used to test the bus (multi-byte frames, repeated START,
# several peripherals at different addresses).
#
# Contract of an I2C peripheral (all functions are optional):
#   on_write(addr, data, t, v)   a write phase addressed to it has just ended
#   on_read(addr, t, v)          the master reads: return the bytes to send to it
#   outputs()                    -> valueOut connector
#   lines()                      -> displayed text (screens)
# See Resources/Scripts/Device/i2c_generic.py for the details.
# ---------------------------------------------------------------------------

memory = b''     # bytes of the last write
writes = 0       # write phases received
total = 0        # bytes received in total


def on_write(addr, data, t, v):
    global memory, writes, total
    memory = data
    writes += 1
    total += len(data)


def on_read(addr, t, v):
    # Called again if the master reads more bytes than the last write
    # contained: it then reads the same thing again, in a loop.
    return memory


def outputs():
    return (writes, total, memory[0] if memory else -1)
