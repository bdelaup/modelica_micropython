# The micro:bit board

`MicroBit_v2` is the replica of the **BBC micro:bit v2** board (nRF52833):
real pinout and dimensions, multiplexed 5x5 LED matrix, A/B buttons, on-board
sensors, USB power supply. It runs the same program as on a physical
micro:bit, written for the official API (`from microbit import *`).

## Quick start

1. Drop a `MicroBit_v2` component in the diagram, connect its `GND` pin to a
   ground. With `usbConnected = true` (default), the board is powered through
   its USB cable - nothing else to wire.
2. In the component parameters, point **Script path** to your program (the
   *...* button):

   ```python
   from microbit import *

   display.show(Image.HEART)
   while True:
       sleep(1000)
       display.show(Image.HAPPY)
       sleep(1000)
   ```

3. Simulate: the dots of the matrix light up on the icon (animated replay of
   the results in OMEdit) - they are the **real currents** through the 25
   LEDs, computed by the solver.
4. Ready-to-run examples: `Examples.MicroBit.Heart`, `Buttons`, `GpioEdge`.

## The program: the `microbit` module

The API of the official micro:bit MicroPython port. `machine` remains
available too (as on the real v2). `microbit.sleep()` takes **milliseconds**,
like on the board.

### `display` - the 5x5 LED matrix

```python
display.show(Image.HEART)                   # one image (or a character, a digit)
display.show(Image.ALL_CLOCKS, delay=100)   # animation, 100 ms per image
display.scroll('Hello!', delay=150)         # scrolling text
display.set_pixel(0, 0, 9)                  # brightness 0 (off) to 9 (max)
display.clear()
display.read_light_level()                  # light level 0-255
```

As on the real board, the matrix is **multiplexed over 10 GPIO** (5 rows +
5 columns) and scanned at 60 Hz: `display.show()` does not drive 25 outputs,
it writes pixels that the driver scans. The 5 columns (`P3`, `P4`, `P6`,
`P7`, `P10`) are shared with the edge connector:

- while the display is on, they belong to the driver (driving them as GPIO
  raises an explicit error);
- `display.off()` releases them (high impedance, like the firmware
  `disable()`); `display.on()` resumes the scan.

### Buttons A and B

Presses do not come from the keyboard. Each button is driven by its **source
dropdown** (`buttonASource`, `buttonBSource`, tab *Buttons*):

- **Connector** (default): the `buttonA`/`buttonB` logical input is wired
  from the diagram (a `BooleanPulse`, a sensor, an expression...). Pressing =
  pulling the pin (`P5`/`P11`) to ground, like a finger on the board.
- **Table**: internal time table, column 1 = time (s), column 2 = 0
  (released) or 1 (pressed). Default table for A:
  `{{0,0},{1,0},{2,1},{3,0},{4,0},{5,1},{6,0}}` — two presses at t=2 s
  and t=5 s.
- **Constant**: fixed state (`buttonAPressed`), nothing to wire.

```python
if button_a.was_pressed():
    count += 1
while button_b.is_pressed():
    ...
```

### On-board sensors

Each sensor is driven by its own **source dropdown** (`accelXSource`...
`lightSource`, tab *Sensors*): **Constant** (default) for a parameter value,
**Table** for an internal (time, value) time table, or **Connector** for an
input wired from the diagram - its **labelled port then appears on the
matching edge of the icon**, turned towards the board (accelerometer on the
right edge, compass on the left edge, temperature and light on the top edge),
so the value can vary during the simulation. The example
`Examples.MicroBit.SensorInputs` wires **all** the sensors and both buttons
to `TimeTable`, `Constant` and `BooleanPulse` blocks.

| Sensor | Parameters (unit) | API |
|---|---|---|
| Accelerometer | `accelX`, `accelY`, `accelZ` (m/s^2, gravity on Z by default) | `accelerometer.get_x()` (milli-g), `get_values()`, gestures `current_gesture()` |
| Compass | `magX`, `magY`, `magZ` (uT) | `compass.get_x()` (nano-tesla), `heading()` (instant calibration) |
| Thermometer | `temp` (degC) | `temperature()` |
| Light | `light` (0-255) | `display.read_light_level()` |

### Edge pins: `pin0`...`pin20`

```python
pin1.write_digital(1)     # output
v = pin0.read_digital()    # input
a = pin2.read_analog()     # 0-1023 (P0-P4, P10 have the ADC)
pin8.write_analog(512)    # PWM 0-1023
pin12.set_pull(Pin.PULL_UP)
```

Pull resistors as on the board: 10 MOhm to 3V on the P0/P1/P2 rings, 4.7
kOhm on P19/P20 (I2C bus, `i2c.init()` defaults: `scl=pin19`, `sda=pin20`),
10 kOhm on the buttons. There is no P17/P18 pin.

### A complete scenario: sources in *Table* mode

To simulate a complete scenario without wiring any external source, set the
dropdown of each button and sensor to **Table** and fill the time tables
(column 1 = time (s), column 2 = value in the sensor's unit, or 0/1 for the
buttons). The example `Examples.MicroBit.Scenario` shows a complete
scenario driven only by time tables (button presses, shake, temperature and
light ramps).

### `uart`

No USB console in the simulation: `tx` and `rx` are **mandatory**.

```python
uart.init(9600, tx=pin0, rx=pin1)
uart.write('hello')
uart.any(); uart.read()
```

## Power supply

`usbConnected = true` (default): 5 V through the USB cable (parameters
`VUsb`, `RUsb`) -> buck-boost regulator -> **3.0 V rail** exposed on the
`3V` pin (parameter `VTgt`). The program starts when the rail rises above
`VPowerOn` and stops for good if it falls below `VPowerOff` (no restart
simulated). The `3V` pin also supplies external circuits.

## Radio: `microbit.radio`

The on-board 2.4 GHz radio is an **ordinary radio modem mounted inside the
board** (the same engine as `Peripherals.Radio.RadioModem`, wired internally
to two pins of the core) - **always present, as on the real hardware**. Its
**Antenna** port (top of the icon) is wired with **one single wire** between
all the boards that must hear each other - exactly as between two
`RadioModem`. The firmware protocol (framing, `channel`/`group`/`address`
filtering, receive queue, truncation) lives in the Python shim; the program
API:

```python
import radio
radio.on()                     # always present: succeeds unconditionally;
                                # an unwired antenna transmits into the void,
                                # like an isolated modem
radio.config(channel=7, group=0, power=6)   # channel/group/address filtering,
                                            # receive queue (default 3)
radio.send('PING 1')            # or send_bytes(b'...'), at most length bytes
msg = radio.receive()          # str or None (receive_bytes(): bytes or None)
```

A packet travels at the pace of the modem (internal link at 115200 bauds, air
at 1 Mbit/s); the firmware semantics apply (filtering, queue, truncation to
`length`), `power` is accepted but has no effect (no range simulated), and
`data_rate` must match on both sides (a frame from another rate is ignored,
like two incompatible real radios). Two fresh boards on the same wire hear
each other - same default `channel`/`group`/`address`, like two real
micro:bits. No modulated signal is plotted on the board; the `RadioModem`
remains the tool for modulations. The example `Examples.MicroBit.RadioChat`
makes two boards talk, and the radio coexists with `machine.UART` (two
distinct engines, one internal to the radio, one for the program).

## micro:bit specific limits

- No SPI (no board of the library has it), no touch logo, microphone or
  speaker (v2), no software `reset()` (the program stops; consistent with
  the absence of restart on power loss).
- The accelerometer gestures derived from gravity work (`face up`, `up`,
  `left`...); the dynamic gestures (`shake`, `freefall`) have no source in
  the simulation.
- `display.scroll`/`show` with `wait=False` use an internal `machine.Timer`
  (pool of 4).
- Radio: an **unwired** antenna is not reported (an acausal antenna wire
  cannot say "nobody at the other end") - the emission goes into the void,
  like an isolated modem; the pace of the
  exchanges is that of the internal modem (link at 115200 bauds, air at
  1 Mbit/s), not the exact frame duration of the hardware, and a dense
  continuous stream costs more simulation events than a sporadic send.

See also: the `machine` API reference ("machine / time API" page), the
"Limits and troubleshooting" page, and `Examples.MicroBit`.
