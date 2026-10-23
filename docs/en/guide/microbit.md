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

Presses do not come from the keyboard: the `buttonA` and `buttonB` logical
inputs of the component are wired from the diagram (a `BooleanPulse`, a
sensor, an expression...). Pressing = pulling the pin (`P5`/`P11`) to
ground, like a finger on the board.

```python
if button_a.was_pressed():
    count += 1
while button_b.is_pressed():
    ...
```

### On-board sensors

Each sensor has a **constant value** (tab *Sensors*) and, when enabled
(`useAccelInput`, `useMagInput`, `useTempInput`, `useLightInput`), an
**input connector** to wire that overrides it - the value can therefore vary
during the simulation.

| Sensor | Sensors tab | API |
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

## micro:bit specific limits

- `microbit.radio` is not simulated: for a wireless link, wire a
  `Peripherals.Radio.RadioModem` on the UART (`machine.UART`), as with the
  other boards.
- No SPI (no board of the library has it), no touch logo, microphone or
  speaker (v2), no software `reset()` (the program stops; consistent with
  the absence of restart on power loss).
- The accelerometer gestures derived from gravity work (`face up`, `up`,
  `left`...); the dynamic gestures (`shake`, `freefall`) have no source in
  the simulation.
- `display.scroll`/`show` with `wait=False` use an internal `machine.Timer`
  (pool of 4).

See also: the `machine` API reference ("machine / time API" page), the
"Limits and troubleshooting" page, and `Examples.MicroBit`.
