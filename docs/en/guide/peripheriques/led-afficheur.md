# LED and teaching display

Two simple components to see what the program does: an LED whose icon lights up according to the current flowing through it, and a text display connected to the microcontroller by a logical link.

## `Peripherals.LED`

A two-pin light-emitting diode. Electrically, it is a diode with a smooth exponential characteristic and a 1.8 V threshold by default (red LED). Its icon goes from `colorOff` to `colorOn` according to the average current flowing through it: you see the LED light up when replaying the result in OMEdit, and PWM makes it look more or less bright.

### Connectors

| Connector | Role |
|---|---|
| `p` | Anode, microcontroller pin side |
| `n` | Cathode, ground side |

### Parameters

| Parameter | Default | Role |
|---|---|---|
| `Vknee` | 1.8 V | Diode threshold voltage. About 2 V for a yellow or green LED, 3 V for a blue or white one |
| `IMax` | 3.5 mA | Current at which the icon reaches its full colour. **Display scale only**, not a physical limit. The default matches an LED driven by a pin through 330 Ω |
| `colorOn` | `{255, 0, 0}` | RGB colour of the icon at full brightness |
| `colorOff` | `{90, 25, 25}` | RGB colour of the icon when off |

### Typical wiring

As on a real board, a resistor limits the current: `GP0` → 330 Ω resistor → LED `p`, `n` → ground. Wiring the LED straight to the pin works (the 100 Ω output resistance limits the current), but is not representative of a real circuit.

The current is plotted under `led0.p.i` (for an LED named `led0`).

## `Peripherals.Display`

A text display with 2 lines of 20 characters, which shows **on its icon** the messages sent by the program with `machine.Display(0).write(...)`. It displays a result without having to set up a real serial or I2C link.

```python
from machine import Display
import time

screen = Display(0)
screen.write("Hello")
time.sleep(1)
screen.write("It works")      # "Hello" moves down to line 2
```

### Connector

| Connector | Role |
|---|---|
| `displayLink` | To connect to `mcu.Display0`. It is a **logical link**: it carries the text directly, with no voltage nor waveform |

The component has no parameters.

### Behaviour

- Each message is shown on **line 1**; the previous message moves down to **line 2**.
- Beyond 20 characters, the message is cut on the icon, but appears in full in the simulation log (each message is printed there too).
- Displayable characters: unaccented letters, digits, space and `! ' , - . ?`. Others are shown as spaces. Messages are limited to 128 characters.
- The link is instantaneous: the message arrives at the very moment of the `write()`, with no transmission delay. Write-only: the display never answers.

For a display connected by a **real** electrical link, see `UartLcd20x2` ([Serial devices](uart.md)) or the Grove LCD RGB display ([I2C devices](i2c.md)).

Examples: `DisplayDemo`, `Weighing.Hx711Read`.
