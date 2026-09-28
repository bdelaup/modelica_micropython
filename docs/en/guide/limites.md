# Limits and troubleshooting

## Limits of the current version

**Environment**

- **64-bit Windows only**, with OpenModelica ([Installation](installation.md)).
- **One `MCU` per model.** Serial and I2C devices, even programmed in Python, can be as many as needed.

**Microcontroller**

- 8 pins (`GP0`-`GP7`) and the on-board LED, instead of the Pico's 29 pins; all of them can be analog inputs.
- `Pin.PULL_UP` / `Pin.PULL_DOWN` are accepted but have no electrical effect: put a real pull resistor in the diagram.
- No `SPI`.
- `UART`: a single link, 8N1 frames only, 50 to 115,200 baud, no receive interrupt.
- `I2C`: master only, a single bus, 1 kHz to 1 MHz.
- `Timer`: 4 timers at most, minimum period 1 ms.
- Interrupt callbacks (`Pin.irq()`, `Timer`) run at the next synchronisation point, never as an instant pre-emption of the program.

Function-by-function details: [API, limitations](api.md#known-limitations-v0).

**Peripherals**: see the end of each page ([serial devices](peripheriques/uart.md), [I2C](peripheriques/i2c.md), [weighing](peripheriques/pesee.md#limits)).

## Troubleshooting

??? question "The simulation stops with a Python error"
    An uncaught exception in the program stops the simulation. The simulation log shows the Python traceback: file, line number, error type and message. Results remain available up to the time of the error.

??? question "My `print()` calls do not show up"
    They go to OMEdit's simulation output window (and its log), not to a Python console. A `print()` from a serial or I2C device is prefixed with the component name.

??? question "`OSError: [Errno 110] ETIMEDOUT` on the I2C bus"
    No pull-up resistor on the bus: tick `usePullUp` on at least one device ([I2C devices](peripheriques/i2c.md#wiring)). Another possible cause: a line held low by a short circuit in the diagram.

??? question "`OSError: [Errno 5] EIO` on the I2C bus"
    No device answers the requested address. Check the device's `addresses` parameter and run `i2c.scan()`.

??? question "Bytes received on the serial link are wrong"
    The device's `baudrate` differs from the one passed to `UART(...)` in the program. Both must be identical, as on a real board.

??? question "The program does not see data received on the serial link"
    Reception does not wake the program up: it must poll the link (`uart.any()`, `uart.read()`, `uart.readline()`) and give the reply time to arrive, for instance with `time.sleep_ms()`.

??? question "Wiring two pins of the same `MCU` together makes the signal disappear"
    A direct `connect()` between two pins of the same microcontroller merges both nodes, and the driven voltage disappears from the results. Go through a 1 kΩ resistor, with a 1 nF capacitor to ground ([Serial devices](peripheriques/uart.md#looping-the-link-back-onto-the-microcontroller)).

??? question "« Chattering detected » message in the log"
    Harmless OpenModelica information: many events within a single output step, typically on an I2C bus. Reducing the output interval (*Interval*) makes it go away; results are correct either way.

??? question "The simulation is slow"
    Each edge on a pin is an event for the solver. A fast serial link, an I2C bus, a busy-wait (`while not button(): pass`, one event per pin access) or a `sleep_ms(1)` in a loop produce many of them. Prefer `time.sleep()` or `Pin.irq()` to busy-waiting, and simulate only the useful duration.

??? question "`open()` raises `OSError: [Errno 19] ENODEV`"
    The file system is not enabled: tick `fsEnabled` in the `MCU`'s *File system* tab ([The MCU block](mcu.md#file-system)).

??? question "Where are the files written by my program?"
    In the flash copy created at each simulation, in the `fsWorkspace` folder (the simulation folder by default). Its path is shown in the log at the start and end of the simulation, and Windows Explorer opens on it at the end of the simulation (`fsOpenExplorer`).

??? question "Two successive pin reads return a stale value"
    Only with `gpioOpTime = 0`: reading a pin right after writing another one may return the state from before the write. Leave `gpioOpTime` at its default, or insert a `time.sleep_us(1)`.
