# Limits and troubleshooting

## Limits of the current version

**Environment**

- **64-bit Windows only**, with OpenModelica ([Installation](installation.md)).

**Microcontroller**

- 8 pins (`GP0`-`GP7`) and the on-board LED, instead of the Pico's 29 pins; all of them can be analog inputs.
- No open-drain mode (`Pin.OPEN_DRAIN`): only the I2C bus drives its lines that way. The internal pull resistors (`Pin.PULL_UP`, `Pin.PULL_DOWN`), on the other hand, are really modelled.
- No `SPI`.
- `UART`: a single link, 50 to 115,200 baud, no receive interrupt; a byte received with an error (parity, stop) is reported in the log, not to the program.
- `I2C`: a single controller bus, 1 kHz to 1 MHz; `I2CTarget`: one target, 7-bit address, no handler any more once the program has ended.
- `Timer`: 4 timers at most, minimum period 1 ms.
- Interrupt callbacks (`Pin.irq()`, `Timer`) run at the next synchronisation point, never as an instant pre-emption of the program.
- Several `MCU` in a model: each has its own program, modules and flash. Two boards that would answer each other without ever letting time pass (`gpioOpTime = 0` and two crossed copies) freeze the simulation at that instant.
- Debugging ([with VS Code](debogage.md)): one debugged `MCU` per model; only the microcontroller program can be debugged, not the scripts of serial or I2C devices.

Function-by-function details: [API, limitations](api.md#known-limitations).

**Peripherals**: see the end of each page ([serial devices](peripheriques/uart.md), [I2C](peripheriques/i2c.md), [weighing](peripheriques/pesee.md#limits), [radio](peripheriques/radio.md#limits)).

## Troubleshooting

??? question "Compilation fails: `'PyRuntimeImpl.c' file not found`"
    The path of the library folder contains an accented character (for instance a `Téléchargements` folder). Move the folder to a path without accents, then reload it in OMEdit (see [Installation](installation.md)).

??? question "With OpenModelica 1.26 or earlier, the pins stay at 0 V"
    The simulation ends without error, but the outputs never change, and the I2C bus stops with `OSError: [Errno 110] ETIMEDOUT`. This is a defect of library versions older than its fix: take the latest version (see [Installation](installation.md)).

??? question "The simulation stops with a Python error"
    An uncaught exception in the program stops the simulation. The simulation log shows the Python traceback: file path, line number, offending line of code, error type and message. Results remain available up to the time of the error.

??? question "The simulation looks frozen, with the warning « the script has been running for more than 10 s of real time »"
    The program runs a loop that never hands control back to the circuit: no `sleep()`, no pin access (waiting on `time.ticks_ms()`, endless computation). Simulated time can no longer advance. Add a `time.sleep_ms()` in the loop, then stop the simulation from OMEdit. The variant « acting for more than ... at the same simulated instant » points to a loop of pin accesses with `gpioOpTime = 0`. The delay is set by `hangWarningTime` ([The MCU block](mcu.md#execution-time)); a long but legitimate computation ends normally despite the warning.

??? question "The simulation stays at t = 0, the log shows “waiting for VS Code”"
    Debugging is enabled (`debugEnabled`, *Debugging* tab of the `MCU`): the microcontroller waits until VS Code attaches. Attach from VS Code ([Debugging with VS Code](debogage.md)), or untick `debugEnabled` to simulate without the debugger.

??? question "VS Code cannot attach to the `MCU`"
    Check that the simulation is running and that the log shows `waiting for VS Code on port ...`, then that the port in `launch.json` is the one in `debugPort`. If the simulation stops at start-up with `failed to start the debugger`, the port is already taken (another simulation running, for instance): pick another one in `debugPort` and in `launch.json`.

??? question "My breakpoints are never hit"
    The file annotated in VS Code must be the one the `MCU` runs: `scriptPath`, or for the flash the files of the `fsSource` image. Breakpoints set in `machine` and `time` (the library's shim) are ignored.

??? question "My `print()` calls do not show up"
    They go to OMEdit's simulation output window (and its log), not to a Python console, preceded by the simulated time (`[t=0.250000 s] ...`). A `print()` from a serial or I2C device also carries the component name.

??? question "`OSError: [Errno 110] ETIMEDOUT` on the I2C bus"
    No external pull-up resistor on the bus (the 50 kΩ internal pull-ups are not enough): tick `usePullUp` on at least one device ([I2C devices](peripheriques/i2c.md#wiring)). Another possible cause: a line held low by a short circuit in the diagram.

??? question "`OSError: [Errno 5] EIO` on the I2C bus"
    No device answers the requested address. Check the device's `addresses` parameter and run `i2c.scan()`.

??? question "Bytes received on the serial link are wrong, or the log reports `parity error` / `framing error`"
    The device's baud rate or frame format (`baudrate`, `dataBits`, `parity`, `stopBits`) differs from what is passed to `UART(...)` in the program. Both must be identical, as on a real board ([Frame format](peripheriques/uart.md#frame-format)).

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
    In the flash copy created at each simulation, in the `fsWorkspace` folder (the simulation folder by default). Its path is shown in the log at the start and end of the simulation, and Windows Explorer opens on it at the end of the simulation (`fsOpenExplorer`). A file the program did not close is closed at the end of the simulation, its full content written to disk.

??? question "Two successive pin reads return a stale value"
    Only with `gpioOpTime = 0`: reading a pin right after writing another one may return the state from before the write. Leave `gpioOpTime` at its default, or insert a `time.sleep_us(1)`.
