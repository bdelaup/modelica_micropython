# The Seeed Studio XIAO RP2040 board

`MicroPythonMCU.XIAO_rp2040` is a simplified replica of the **standard Seeed Studio XIAO RP2040**, built around the same `Internal.McuCore` programmable core as `MCU`, `RPi_Pico` and `MicroBit_v2`. It exposes pads D0-D10, the 3.3 V rail and 5 V input, as well as both on-board LEDs. The XIAO RP2040 Plus variant is not modelled.

The board starts from USB-C by default. It can also be supplied by an external 5 V source connected to `V5` with `usbConnected` disabled. Its regulator is a simplified averaged model, not a component-level replica.

![XIAO_rp2040 icon: the board seen from above, pads D0-D10, 5V, GND and 3V3, lightning bolt on the USB-C connector when powered by the cable](../images/xiao-icone.png){ width="220" }

## Pinout

MicroPython scripts use the RP2040 GPIO numbers, not the D0-D10 pad names:

| Pad | GPIO | API | Analog function |
|---|---:|---|---|
| `D0` | 26 | `Pin(26)` | `ADC(0)` |
| `D1` | 27 | `Pin(27)` | `ADC(1)` |
| `D2` | 28 | `Pin(28)` | `ADC(2)` |
| `D3` | 29 | `Pin(29)` | `ADC(3)` |
| `D4` | 6 | `Pin(6)` | — |
| `D5` | 7 | `Pin(7)` | — |
| `D6` | 0 | `Pin(0)` | — |
| `D7` | 1 | `Pin(1)` | — |
| `D8` | 2 | `Pin(2)` | — |
| `D9` | 4 | `Pin(4)` | — |
| `D10` | 3 | `Pin(3)` | — |

`ADC(4)` reads the RP2040's internal temperature sensor. GPIOs not exposed on the standard XIAO are rejected by the shim, even though they exist on the chip.

Peripheral pin multiplexing follows the MicroPython `rp2` port:

- `UART(0)` defaults to TX = GPIO0 and RX = GPIO1, i.e. `D6` and `D7`.
- `I2C(1)` defaults to SCL = GPIO7 and SDA = GPIO6, i.e. `D5` and `D4`.

The on-board RGB LED uses GPIO17 (red), GPIO16 (green) and GPIO25 (blue), which are not external pads. All three channels are **active low**: `0` turns a channel on, `1` turns it off. Since `Pin.LED` is GPIO25 in the RP2040 shim, it addresses this board's blue channel.

```python
from machine import Pin
import time

red = Pin(17, Pin.OUT)
green = Pin(16, Pin.OUT)
blue = Pin(25, Pin.OUT)

for led in (red, green, blue):
    led.value(1)  # all channels off

while True:
    red.value(0)
    time.sleep_ms(200)
    red.value(1)
```

The BOOT and RESET buttons are drawn on the icon but are decorative; they do not control the program.

## Power supply

| Connector | Role |
|---|---|
| `V5` | 5 V input for an external supply when `usbConnected = false` |
| `V3V3` | Regulated 3.3 V output for external circuits |
| `GND` | Common ground to connect to the circuit |

By default, `usbConnected = true` enables a 5 V USB-C source. To use an external source, disable USB and connect its terminals to `V5` and `GND`:

```modelica
MicroPythonMCU.XIAO_rp2040 xiao(usbConnected = false);
Modelica.Electrical.Analog.Sources.ConstantVoltage supply(V = 5);
Modelica.Electrical.Analog.Basic.Ground ground;
equation
  connect(supply.p, xiao.V5);
  connect(supply.n, ground.p);
  connect(xiao.GND, ground.p);
```

![Internal diagram of XIAO_rp2040 in OMEdit: pads D0-D10 on the left, RP2040 core and RGB LED in the middle, regulator, USB and power LED on the right](../images/xiao-schema-interne.png){ width="700" }

Do not connect another 5 V source to `V5` while `usbConnected` is true. The `V3V3` rail supplies the core, pins and on-board LEDs. The model starts when the rail crosses `VPowerOn` and stops permanently below `VPowerOff`; restart after a loss of power is not simulated.

The green power LED is connected to the 3.3 V rail. The LED-specific parameters are `ledSeriesR` and `powerLedSeriesR`. The `vInput`, `vRail` and `iInput` variables expose the power supply state.

## Examples

The [`Examples.XIAO_rp2040`](exemples.md#seeed-xiao-rp2040) package contains:

| Example | Demonstration |
|---|---|
| `XIAO_rp2040.Blink` | USB supply, active-low RGB LED and external LED on `D6` / GPIO0 |
| `XIAO_rp2040.Adc` | Read 1.65 V on `D0` / GPIO26 using `ADC(0)` |
| `XIAO_rp2040.ExternalSupply` | External 5 V supply on `V5`, USB disabled |

For common core parameters (script, simulated time, file system and electrical levels), see [The MCU block](mcu.md#parameters). The board reuses the shim's RP2040 profile; this does not enable GPIOs absent from the XIAO pinout, because the board pin table filters them.

## References

- [Official Seeed Studio XIAO RP2040 documentation](https://wiki.seeedstudio.com/XIAO-RP2040/)
- [MicroPython quick reference for the rp2 port](https://docs.micropython.org/en/latest/rp2/quickref.html)
- [API reference](api.md)
