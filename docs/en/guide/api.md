# `machine` / `time` API

This page lists what a program run by the [`MCU`](mcu.md) can call: the subset of the Raspberry Pi Pico's MicroPython `machine`/`time` API that is actually implemented. A program written for the board runs unchanged as long as it sticks to this subset. The exact implementation (source of truth) is the file [`MicroPythonMCU/Resources/Scripts/_shim/machine_time_shim.py`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/MicroPythonMCU/Resources/Scripts/_shim/machine_time_shim.py), loaded and run as is before the user script. How these modules are built is described in the (French) maintainer reference: [Python integration](https://bdelaup.gitlab.io/modelica_micropython3/fr/interne/integration-python/) and [Life cycle](https://bdelaup.gitlab.io/modelica_micropython3/fr/interne/cycle-de-vie/).

**Key notion**: a call that *synchronises* hands control back to Modelica (the solver may advance simulated time, possibly up to a pending `sleep`) before the script continues — this is what makes an input transition or a `sleep` visible, and compressible, in the simulation. A call that does not synchronise is a plain immediate read of state the script already knows.

**Time cost of pin accesses**: each `value()`, `on()`, `off()` or `pin(x)` keeps the processor busy for `MCU.gpioOpTime` of simulated time (*Execution time* tab, **5 µs by default**, the order of magnitude of MicroPython on an RP2040). Two writes without a `sleep` in between therefore produce a real pulse, visible to the circuit: this is what enables bit-banging (HX711 driver, see [Weighing chain](peripheriques/pesee.md)), and what makes time advance in a busy-wait loop (`while not button(): pass`). Pure Python computation, `Pin()`, `irq()`, the ADC, PWM and `ticks_*` remain instantaneous. `gpioOpTime = 0` makes all accesses instantaneous.

## `machine.Pin`

```python
from machine import Pin
led = Pin(0, Pin.OUT)          # or Pin(Pin.LED, Pin.OUT) for the on-board LED
```

### Constants

| Constant | Value | Use |
|---|---|---|
| `Pin.IN` | `0` | input mode, passed to `mode=` |
| `Pin.OUT` | `1` | output mode, passed to `mode=` |
| `Pin.PULL_UP` | `2` | passed to `pull=` — accepted but **with no electrical effect** (see Limitations) |
| `Pin.PULL_DOWN` | `3` | same |
| `Pin.LED` | `25` | identifier of the on-board LED (wired inside the `MCU`, not a `GPx` connector) |

### Constructor

`Pin(id, mode=None, pull=None)`

- `id`: `0`-`7` (pins `GP0`-`GP7`), or `25`/`Pin.LED`/`"LED"` (on-board LED). Any other value raises `ValueError` at the first call that uses it.
- `mode`: `Pin.IN` or `Pin.OUT`. If omitted, the direction is not (re)configured — handy to just read the current state. **Synchronises** if given.
- `pull`: accepted for signature compatibility with MicroPython, ignored.

### Methods

| Method | Signature | Behaviour | Synchronises? |
|---|---|---|---|
| `.value()` | `value() -> int` | Waits `gpioOpTime`, then reads the resolved pin state (0/1) at the end of the access, whatever its direction | Yes |
| `.value(x)` | `value(x)` | Drives the pin to `x` (0/1) right away — no effect if the pin is currently an input —, then waits `gpioOpTime` | Yes |
| `pin()` / `pin(x)` | `__call__(x=None)` | Shorthand for `value()` / `value(x)`, common in MicroPython drivers | Yes |
| `.on()` | `on()` | Same as `value(1)` | Yes |
| `.off()` | `off()` | Same as `value(0)` | Yes |
| `.toggle()` | `toggle()` | Inverts the current state (reads, then writes the opposite) | Yes (through `value()`, twice) |
| `.irq(handler, trigger)` | `irq(handler=None, trigger=IRQ_RISING|IRQ_FALLING, **kwargs)` | Registers (or clears, if `handler=None`) a callback called on an edge matching `trigger`. The callback receives the `Pin` object (`handler(pin)`), as on real MicroPython. `**kwargs` absorbs `hard=`/`priority=`/`wake=` for signature compatibility, with no effect (see Limitations) | Yes |

`trigger` constants: `Pin.IRQ_RISING = 1`, `Pin.IRQ_FALLING = 2` (combine with `|` for both edges; always use the symbolic names). The callback runs "soft": it is executed at the next wake-up point of the program, never as an immediate pre-emption of the script. An input transition wakes the script up even without a registered `irq()`; registering an `irq()` adds the callback call to that wake-up, and a pending `sleep()` still returns early.

## `machine.ADC`

```python
from machine import ADC
adc = ADC(1)                   # or ADC(Pin(1))
v = adc.read_u16()             # 0-65535
```

### Constructor

`ADC(id)` — `id`: `0`-`7` (any of the `GP0`-`GP7` pins, used as analog rather than digital — **all** of them are ADC-capable here, unlike the real Pico where only `GP26`-`GP28` are) or a `Pin` object (its `.id` is used). The on-board LED is not ADC-capable. Synchronises. Changes neither the direction nor the driven state of the pin, but **disconnects its digital input**, as on the RP2040: logic-threshold crossings of the analog voltage no longer wake a pending `sleep()` nor trigger IRQs. A later `Pin(id, mode)` gives the pin back to the GPIO.

### Methods

| Method | Signature | Behaviour | Synchronises? |
|---|---|---|---|
| `.read_u16()` | `read_u16() -> int` | Reads the voltage on the pin and returns it on 16 bits (`round(v / 3.3 * 65535)`, clamped to `[0, 65535]`) | Yes |

## `machine.PWM`

```python
from machine import Pin, PWM
pwm = PWM(Pin(0))
pwm.freq(1000)          # Hz
pwm.duty_u16(32768)     # 0-65535 (~50%)
```

Once configured, the square wave is generated **continuously on the Modelica side**, without a round trip to the Python program at each edge — the script may end, PWM keeps running, as the RP2040 hardware peripheral does.

### Constructor

`PWM(pin, freq=None, duty_u16=None)` — `pin`: `0`-`7` (integer) or `Pin` object. Makes the pin an output (as on the real RP2040). `freq`/`duty_u16` are optional, equivalent to calling `.freq()`/`.duty_u16()` right after construction.

### Methods

| Method | Signature | Behaviour | Synchronises? |
|---|---|---|---|
| `.freq(f)` | `freq(f)` | Sets the PWM frequency (Hz); also makes the pin an output | Yes |
| `.freq()` | `freq() -> int` | Returns the last frequency set (cached value) | **No** |
| `.duty_u16(d)` | `duty_u16(d)` | Sets the duty cycle (0-65535, clamped) | Yes |
| `.duty_u16()` | `duty_u16() -> int` | Returns the last duty cycle set (cached value) | **No** |
| `.deinit()` | `deinit()` | Stops PWM; the pin goes back to a plain digital output (low by default) | Yes |

## `machine.Timer`

```python
from machine import Timer
tim = Timer()
tim.init(period=500, mode=Timer.PERIODIC, callback=lambda t: led.toggle())
tim.deinit()
```

Software timer: once armed, the callback keeps firing **during** a `sleep()` pending elsewhere in the script, without ever making it return early.

### Constants

| Constant | Value | Use |
|---|---|---|
| `Timer.ONE_SHOT` | `0` | the callback fires once, then the timer disarms itself |
| `Timer.PERIODIC` | `1` | the callback fires again every `period` ms, indefinitely |

### Constructor

`Timer(id=-1)` — `id` accepted for signature compatibility, ignored (a fixed pool of 4 software timers is shared by all `Timer()`s, see Limitations). Does not synchronise.

### Methods

| Method | Signature | Behaviour | Synchronises? |
|---|---|---|---|
| `.init(period, mode, callback)` | `init(period=1000, mode=PERIODIC, callback=None)` | Arms (or re-arms) the timer: `period` in **milliseconds** (as in real MicroPython), `mode` = `ONE_SHOT`/`PERIODIC`, `callback` receives the `Timer` object (`callback(timer)`) | Yes |
| `.deinit()` | `deinit()` | Stops and frees the timer | Yes |

## `machine.Display`

```python
from machine import Display
display = Display(0)
display.write("Hello")          # to a Peripherals.Display wired to MCU.Display0
```

Single, **write-only** logical link to a teaching display (`Display0` on the `MCU`). Not a real UART/serial protocol: no reception, no addressing. Unlike the `GPx` pins, the link is not electrical: the message is delivered **instantly** at the next synchronisation point, with no simulated baud rate nor bit-level waveform — component and wiring: [LED and display](peripheriques/led-afficheur.md).

### Constructor

`Display(id=0, **kwargs)` — `id`: only `0` is supported (`ValueError` otherwise). `**kwargs` accepted, with no effect. Does not synchronise.

### Methods

| Method | Signature | Behaviour | Synchronises? |
|---|---|---|---|
| `.write(text)` | `write(text)` | Sends `text` (converted to `str` if needed) to the display wired to `MCU.Display0`; instant delivery of the whole message | Yes |

## `machine.UART`

```python
from machine import Pin, UART
uart = UART(0, baudrate=1200, tx=Pin(0), rx=Pin(1))
uart.write(b'Hi')
if uart.any():
    print(uart.read())
```

**Electrically real** serial link, on two real `GPx` pins — unlike `machine.Display`, which is a logical link. The TX pin carries a real 8N1 frame (start bit at 0, 8 data bits least significant first, stop bit at 1, idle high), each bit lasting `1/baudrate`: plotting it in OMEdit is like looking at it on an oscilloscope.

The waveform is produced by the runtime, without the Python program driving each edge — like the RP2040 hardware UART, which runs on its own once programmed. Reception is decoded from the line's edges, reading each bit in its middle as a real receiver does.

**A pin assigned to UART reception no longer generates GPIO interrupts and no longer wakes a pending `sleep()`**: its edges belong to the serial peripheral, not to the script — as on real hardware.

Wiring and devices to connect at the other end: [Serial devices](peripheriques/uart.md).

### Constructor

`UART(id=0, baudrate=1200, tx=None, rx=None, **kwargs)` — `id`: only `0` is supported. `tx`/`rx`: required, a `Pin` object or a pin number, two distinct pins among `0`-`7`. `baudrate`: 50 to 115200 (`ValueError` outside). `**kwargs` absorbs `bits`/`parity`/`stop`, accepted for API compatibility but **with no effect** (only 8N1 is sent). Synchronises.

### Methods

| Method | Signature | Behaviour | Synchronises? |
|---|---|---|---|
| `.write(data)` | `bytes`, `str` (UTF-8 encoded) or any convertible object | Queues the bytes for sending and returns the number accepted. **Non-blocking**: the script continues while Modelica plays the waveform; frames follow each other with no gap. 256-byte queue; extra bytes are silently lost | Yes |
| `.any()` | — | Number of received bytes waiting to be read | Yes |
| `.read(n=None)` | `n` bytes, or everything available | Returns `bytes`, or `None` if nothing is available | Yes |
| `.readline()` | — | Reads up to and including `\n`; otherwise returns what is available, or `None` if nothing | Yes |
| `.init(baudrate, tx, rx)` | same as constructor | Reconfigures the link | Yes |
| `.deinit()` | — | Releases the link and its pins | Yes |

## `machine.I2C`

```python
from machine import Pin, I2C
i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=100000)   # or I2C(scl=Pin(4), sda=Pin(5))
print(i2c.scan())                                   # e.g. [66]
i2c.writeto(0x42, b'Hello')
print(i2c.readfrom(0x42, 5))
print(i2c.readfrom_mem(0x42, 0x10, 2))              # register 0x10, after a repeated START
```

**Electrically real**, open-drain I2C bus on two `GPx` pins: the microcontroller is the **master**, it generates the clock and only pulls SDA/SCL low or releases them. The lines only go back up thanks to pull-up resistors carried by a peripheral (`usePullUp = true`) — without them, every transaction raises `OSError(ETIMEDOUT)`. Wiring and components: [I2C devices](peripheriques/i2c.md).

**Each transaction is blocking**: the script resumes only at the real end of the sequence on the bus, in simulated time (about 9 bits per byte, at `1/freq` per bit). **Both pins are reserved**: their edges do not generate GPIO interrupts and do not wake a `sleep()`.

### Constructor

`I2C(id=0, *, scl, sda, freq=400000)` — `id` optional (a single bus exists: `0`, or `1` accepted as an alias), which makes both the rp2 form `I2C(0, scl=..., sda=...)` and the form of drivers written for other ports, `I2C(scl=..., sda=...)`, work. `scl`/`sda`: required, a `Pin` object or a number, two distinct pins among `0`-`7`. `freq`: 1 kHz to 1 MHz (`ValueError` outside). `SoftI2C` is an alias of `I2C`. Synchronises.

### Methods

| Method | Behaviour | Synchronises? |
|---|---|---|
| `.scan()` | List of the addresses (0x08-0x77) that acknowledge a probe (empty write); `[]` if the bus is stuck | Yes (one transaction per address) |
| `.writeto(addr, buf, stop=True)` | Writes `buf`; returns the number of acknowledged bytes. `stop=False` keeps the bus: the next transaction starts with a repeated START | Yes, blocking |
| `.readfrom(addr, nbytes, stop=True)` | Reads `nbytes` bytes (`bytes`) | Yes, blocking |
| `.readfrom_into(addr, buf, stop=True)` | Same, into an existing buffer | Yes, blocking |
| `.writevto(addr, vector, stop=True)` | Writes the concatenation of the buffers of `vector` | Yes, blocking |
| `.writeto_mem(addr, memaddr, buf, *, addrsize=8)` | Writes `buf` starting at register `memaddr` | Yes, blocking |
| `.readfrom_mem(addr, memaddr, nbytes, *, addrsize=8)` | Writes the register number, then reads after a repeated START | Yes, blocking |
| `.readfrom_mem_into(addr, memaddr, buf, *, addrsize=8)` | Same, into an existing buffer | Yes, blocking |
| `.init(scl=, sda=, freq=)` / `.deinit()` | Reconfigures / releases the bus and its pins | Yes |

**Errors**: `OSError(EIO)` (errno 5) if the address is not acknowledged; `OSError(ETIMEDOUT)` (errno 110) if a line stays low (no pull-up, stuck bus); `OSError(EBUSY)` (errno 16) for a call from a Timer/IRQ callback during a transaction.

## File system: `open()` and `os`

```python
import os

with open('/data/measures.csv', 'a') as f:
    f.write('%d;%.3f\n' % (t, u))
print(os.listdir('/data'))
```

Active only if `MCU.fsEnabled` is ticked (*File system* tab, see [MCU parameters](mcu.md#file-system)). Each simulation copies `MCU.fsSource` (empty = blank flash) into a new `<instance>_<FS name>_<date>_<time>` folder of the `MCU.fsWorkspace` workspace (`"."` by default: the simulation folder), whose path is shown in the log at the start and end of the simulation; Windows Explorer opens on it at the end (`MCU.fsOpenExplorer`); the script sees this copy as the flash root `/`, without being able to leave it (`..` stops at the root). Without a file system, `open()` and the `os` functions raise `OSError(ENODEV)` (errno 19). The root and `/lib` are on the import path. Program run: `boot.py` of the copy if it exists, then `MCU.scriptPath` instead of `main.py`, or the copy's `main.py` if `scriptPath` is empty.

| Call | Effect | Synchronisation point? |
|---|---|---|
| `open(path, mode='r')` | File on the flash. Text in UTF-8, line endings never translated | **No** (instant write) |
| `os.listdir(dir='.')` / `os.ilistdir(dir='.')` | Sorted names / tuples `(name, type, 0, size)`, type `0x4000` (folder) or `0x8000` (file) | **No** |
| `os.mkdir(path)` / `os.rmdir(path)` / `os.remove(path)` | Creates a folder / removes an empty folder / removes a file | **No** |
| `os.rename(old, new)` | Renames, replacing an existing target | **No** |
| `os.stat(path)` | 10-tuple: `[0]` type, `[6]` size; dates at 0 | **No** |
| `os.statvfs('/')` | 1.4 MB flash in 4 KB blocks, free blocks computed from the contents | **No** |
| `os.chdir(dir)` / `os.getcwd()` | Current folder (`/` at start-up) | **No** |
| `os.sync()`, `os.uname()`, `os.sep` | No effect / `rp2` identity / `'/'` | **No** |

`import uos` gives the same module. **Errors**: those of MicroPython (`OSError: [Errno 2] ENOENT`, `EEXIST`, `EISDIR`...), never the real host path; `EINVAL` for a path containing `\`, `:` or a character forbidden by Windows. Nothing the script observes depends on the copy's timestamp: two simulations produce the same files.

## Modules, `print()` and errors

```python
import my_module               # my_module.py placed next to the program
import sensors                 # /lib/sensors.py on the flash, or folder given by libraryPath
```

- **Imports**: the program's folder is on the import path (`MCU.addScriptDirToPath`, on by default), like the flash root on the board. `MCU.libraryPath` adds a shared library folder. With a file system enabled, the flash root and `/lib` are on it too. The CPython 3.12 standard library is available, but a program meant for the board must stick to what MicroPython offers.
- **`print()`**: shown in OMEdit's simulation output window.
- **Uncaught exception**: stops the simulation; the Python traceback is shown in the log (`Program.Error` example).

## `machine` functions

```python
from machine import disable_irq, enable_irq, idle
state = disable_irq()
# ... section where no callback may interleave ...
enable_irq(state)
```

| Function | Behaviour | Synchronises? |
|---|---|---|
| `disable_irq()` | Masks `Pin.irq()` and `Timer` callbacks and returns the previous masking state. Callbacks due while masked are **deferred, not lost** | No |
| `enable_irq(state)` | Restores the state returned by `disable_irq()`; if unmasked, deferred callbacks run right away | No |
| `idle()` | Yields until the next whole millisecond (the RP2040 system tick), earlier if an input pin changes — like a `sleep` | Yes |

## `time`

```python
import time
time.sleep(1)
```

| Function | Signature | Behaviour | Synchronises? |
|---|---|---|---|
| `sleep(s)` | seconds (`float`/`int`) | Suspends the script until `sim_time + s`; simulated time may jump straight to that point (sleep compression) | Yes |
| `sleep_ms(ms)` | milliseconds | Same as `sleep(ms/1000)` | Yes |
| `sleep_us(us)` | microseconds | Same as `sleep(us/1e6)` | Yes |
| `ticks_ms()` | — | Current simulated clock, in ms (`sim_time * 1000`, **rounded** to the nearest ms: a wake-up planned at 200 ms gives 200, never 199) | **No** — plain read |
| `ticks_us()` | — | Current simulated clock, in µs (true microsecond resolution, rounded: a `sleep_us(250)` measures 250) | **No** |
| `ticks_diff(a, b)` | — | `a - b` | **No** |

`ticks_ms()`/`ticks_us()` are deliberately excluded from synchronisation: a non-blocking polling loop (`while ticks_diff(...) < ...`) thus stays cheap instead of triggering a synchronisation point at each iteration.

## Known limitations (v0)

- `pull` (`Pin.PULL_UP`/`Pin.PULL_DOWN`) accepted as a parameter but no pull-up resistor is actually modelled: put a real resistor in the diagram.
- Only pins `0`-`7` and `25`/`Pin.LED` are recognised (not the 29 pins of the real Pico).
- No `SPI`.
- File system: a fresh copy of the image at each simulation (no persistence from one run to the next; to chain runs, point `fsSource` to a previous copy). Sandboxing is limited to `open()` and `os` — `io.open` or `pathlib` are not subject to it. Case-insensitive host (Windows), no `os.urandom`, nor `mount`/`VfsLfs2`/`dupterm`.
- `machine.I2C`: **master only**, a single bus, no clock stretching (SCL held low = `ETIMEDOUT`) nor multi-master arbitration, at most 256 bytes per transaction, RP2040 internal pull-ups not modelled (`usePullUp` is needed on a peripheral).
- `machine.UART`: a single peripheral (`UART(0)`), **fixed 8N1 frame** (`bits`/`parity`/`stop` accepted but with no effect), baud rate limited to 50-115200. 256-byte queues, silent overflow; a frame whose stop bit is not high is ignored with no framing error. No `uart.irq()` (reception does not wake the script: poll it with `any()`/`read()`), no RTS/CTS flow control.
- `machine.Display`: a single logical link, **write-only**, instant delivery of the whole message (no simulated baud rate).
- `Pin.irq()`: every callback runs "soft" (deferred to the program's next wake-up point); `hard=` accepted but with no effect. An exception raised in a callback stops the whole simulation (same policy as the main script).
- `machine.Timer`: fixed pool of 4 timers shared by all `Timer()`s (beyond that, `Timer()` raises `RuntimeError`); minimum period 1 ms (`ValueError` below).
- `ADC.read_u16()`: conversion reference (3.3 V) hard-coded, not tied to the `MCU`'s `VOH` parameter; no periodic sampling nor threshold event (unlike a digital input, a change on the ADC never wakes the script up, even when crossing the logic threshold — it must be polled explicitly).
- `PWM`: each pin has its own frequency/duty cycle (the real RP2040 shares a frequency channel between two neighbouring pins, not modelled here); `deinit()` sets the pin back to a **low** digital output, not high impedance.
- An uncaught exception stops the simulation: the Python traceback is shown in the log, and results remain available up to the time of the error.
- `gpioOpTime`: a single duration for every pin access, read or write, with no spread. A busy-wait costs one simulation event per access (≈ 200,000 per simulated second at 5 µs): prefer `sleep` or `Pin.irq()` when possible.
- **With `gpioOpTime = 0` only: reading a pin right after writing another one (even physically connected) may return the state from *before* the write.** Several consecutive calls that request no real delay stay in the same runtime pass, without the Modelica circuit being solved in between. An explicit synchronisation point between the two is needed (any non-zero `sleep`/`sleep_ms`/`sleep_us`, even very short). Concrete example: [`Examples/PinEcho.mo`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/MicroPythonMCU/Examples/PinEcho.mo) (script [`pin_echo.py`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/MicroPythonMCU/Resources/Scripts/MCU/pin_echo.py)).
