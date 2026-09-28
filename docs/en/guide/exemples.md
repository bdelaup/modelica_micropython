# Examples

The `MicroPythonMCU.Examples` package holds 31 ready-to-simulate models: open the model, simulate, plot the listed variables. Each one runs the program named in the "Program" column, to be read alongside: in [`Resources/Scripts/MCU/`](https://gitlab.com/bdelaup/modelica_micropython3/-/tree/main/MicroPythonMCU/Resources/Scripts/MCU), or in [`Resources/Verification/`](https://gitlab.com/bdelaup/modelica_micropython3/-/tree/main/MicroPythonMCU/Resources/Verification) for those marked *(V)*. The examples also serve as scenarios for the library's verification suite. Program comments and printed messages are in French.

## Digital pins

| Example | What it shows | What to watch | Program |
|---|---|---|---|
| `BasicBlink` | The default program: `GP0` and the on-board LED blink at 0.5 Hz | `mcu.GP0.v`, LED icons | `demo.py` |
| `LedChaser` | Chaser on 8 LEDs placed around the microcontroller | LED icons (animated replay) | `led_chaser.py` |
| `PinEcho` | `GP1` toggles, `GP2` reads back its electrical state, `GP3` copies it | `mcu.GP1.v`, `mcu.GP3.v` | `pin_echo.py` |
| `InputReactivity` | A button on `GP1` wakes the program during a `sleep(3600)` | `mcu.GP1.v`, program output | `input_reactive.py` *(V)* |
| `SleepCompression` | Two `sleep(3600)` simulated in a fraction of a second of computation | simulation duration | `sleep_long.py` *(V)* |
| `ScriptError` | An uncaught exception stops the simulation, Python traceback in the log | log | `script_error.py` *(V)* |

## Analog and PWM

| Example | What it shows | What to watch | Program |
|---|---|---|---|
| `AdcRead` | `GP1` as an analog input on a voltage divider (≈ 2.2 V); threshold copied to an LED | `mcu.GP1.v`, `mcu.GP0.v` | `adc_read.py` |
| `AdcSleep` | An analog input crossing the logic threshold does not wake the program | `mcu.GP0.v`, `mcu.GP1.v` | `adc_sleep.py` |
| `PwmLed` | 200 Hz PWM, duty cycle ≈ 30 % | `mcu.GP0.v`, `led0.p.i` | `pwm_led.py` |
| `PwmLedFade` | Gradual change of the duty cycle: the LED fades in | LED icon, `led0.p.i` | `pwm_led_fade.py` |

![200 Hz PWM](../images/sim/pwm-led.svg)

*Figure labels are in French: « temps » = time, « courant LED » = LED current, « rapport cyclique » = duty cycle.*

## Interrupts and time

| Example | What it shows | What to watch | Program |
|---|---|---|---|
| `PinIrq` | `Pin.irq()` on rising edges only: the LED toggles on each rising edge of the square wave | `mcu.GP1.v`, `mcu.GP0.v` | `pin_irq_demo.py` *(V)* |
| `TimerToggle` | A 500 ms periodic `Timer` toggles an LED while the program sleeps | `mcu.GP0.v` | `timer_toggle.py` *(V)* |
| `GpioTiming` | Cost of a pin access (`gpioOpTime`): `on()`/`off()` pulse without `sleep`, burst, busy-wait, masked IRQ | `mcu.GP0.v` (zoom to the µs) | `gpio_timing.py` *(V)* |

## Program, modules and files

| Example | What it shows | What to watch | Program |
|---|---|---|---|
| `ImportDemo` | Import of a module placed next to the program and of a library from another folder (`libraryPath`) | LEDs on `GP0` and `GP1` | `import_demo.py` |
| `FileSystem` | No script: `boot.py` then `main.py` of a flash image; ADC readings logged to `/data/mesures.csv` | copy folder (opened at the end of the simulation) | `datalogger/` image |
| `FileSystemScript` | `boot.py` from the flash, then an external program instead of `main.py` | log, written files | `fs_script.py` |

## Teaching display

| Example | What it shows | What to watch | Program |
|---|---|---|---|
| `DisplayDemo` | Two messages sent to a `Peripherals.Display`; the first one moves down to line 2 | display icon, log | `display_demo.py` |

## Serial link (`Examples.Uart`)

| Example | What it shows | What to watch | Program |
|---|---|---|---|
| `Uart.Loopback` | 8N1 frame looped back onto the microcontroller | `mcu.GP0.v` | `uart_loopback.py` |
| `Uart.EchoPy` | Dialogue with an echo device described by a Python script | `mcu.GP5.v`, `mcu.GP4.v`, log | `uart_echo.py` |
| `Uart.Echo` | Same setup, echo set in the device's table | same | `uart_echo.py` |
| `Uart.Sensor` | Querying a temperature sensor, then sending a setpoint | `capteur.valueOut[1]`, log | `uart_sensor.py` |
| `Uart.Regulation` | Closed-loop control through the serial link alone | `procede.y`, `capteur.valueOut[1]` | `uart_regulation.py` |
| `Uart.GpsPy` | A GPS module sends its frames without being asked | log | `uart_gps.py` |
| `Uart.StateMachinePy` | Device whose reply depends on its history (Python state machine) | log | `uart_state_machine.py` |
| `Uart.Lcd` | Two lines written to a 20x2 serial display | display icon | `uart_lcd.py` |

![Serial frame](../images/sim/uart-trame.svg)

## I2C bus (`Examples.I2c`)

| Example | What it shows | What to watch | Program |
|---|---|---|---|
| `I2c.Echo` | Writing and reading back a frame, reading a register after a repeated START | `echo.SDA.v`, `echo.SCL.v` | `i2c_echo.py` |
| `I2c.MultiDevice` | Three devices on a 400 kHz bus, found by `scan()` | log | `i2c_multi.py` |
| `I2c.NoPullUp` | Bus without pull-up resistors: `OSError(ETIMEDOUT)` | lines at 0 V, log | `i2c_nopullup.py` |
| `I2c.GroveLcd` | Grove LCD RGB display driven by an unmodified off-the-shelf driver | display icon | `i2c_grove_lcd_rgb.py` |

## Weighing (`Examples.Weighing`)

| Example | What it shows | What to watch | Program |
|---|---|---|---|
| `Weighing.Hx711Read` | Reading an HX711 with robert-hh's driver: gain 128, gain 64, power-down and wake-up | `hx.code`, `hx.PD_SCK.v`, `hx.DOUT.v`, display | `hx711_read.py` |
| `Weighing.KitchenScale` | Complete kitchen scale, TARE button | display icon | `kitchen_scale.py` |
