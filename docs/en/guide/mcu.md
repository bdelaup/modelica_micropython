# The `MCU` block

`MicroPythonMCU.MCU` is the microcontroller: a package with 8 input/output pins, a ground, a link to a teaching display and an on-board LED. Its behaviour is entirely described by the Python program given by `scriptPath`. Its reference is the Raspberry Pi Pico (RP2040), whose MicroPython API it reproduces; the icon deliberately reads "MCU".

!!! note "French labels"
    The library's parameter dialogs, tab names and descriptions are in French. This page gives the parameter names as they appear in the dialog, with their meaning.

## Connectors

| Connector | Type | Role |
|---|---|---|
| `GP0` … `GP7` | Electrical pin (`PositivePin`) | Each one, at the program's choice: digital input or output (`Pin`), analog input (`ADC`), PWM output (`PWM`), serial line (`UART`) or I2C bus line (`I2C`). `GP0`-`GP3` are on the left edge of the icon, `GP4`-`GP7` on the right edge |
| `GND` | Electrical pin (`NegativePin`) | Common reference of all pins. **Connect it to the circuit ground** (`Ground`), as on a real board |
| `Display0` | Logical link (`DisplayLinkOutput`) | To a `Peripherals.Display`: text sent by `machine.Display(0).write()`. Not electrical: see [LED and display](peripheriques/led-afficheur.md) |

The **on-board LED** (`Pin.LED`, pin 25 on the Pico) is wired inside the block, with its series resistor: it has no connector. It lights up on the icon, and its current can be plotted under `mcu.builtinLed`.

## Electrical model of a pin

Each `GPx` pin is a small circuit, solved together with the rest of the diagram:

- **as an output**, a voltage source `VOH` (high) or `VOL` (low) behind a resistance `ROut`. The actual pin voltage therefore depends on what is connected: ≈ 3.07 V with an LED and 330 Ω, for instance;
- **as an input**, the output is disconnected by an open switch. What remains is the leakage of that switch, **≈ 100 kΩ to ground**. The program reads 1 above `VIH`, 0 below `VIL`;
- **as an analog input** (`ADC`), the voltage is measured as is, on 16 bits, with a 3.3 V reference.

A pin that the program does not use can be left unconnected.

## Parameters

Double-clicking the `MCU` opens its parameter dialog. The defaults suit most uses: only the script path needs setting.

### Python script

*General* tab, "Script Python" group.

| Parameter | Default | Role |
|---|---|---|
| `scriptPath` | `Resources/Scripts/MCU/demo.py` | **Program to run** (pick it with the *…* button). With a file system enabled, it runs after `boot.py`, instead of `main.py`; if empty, the flash's `main.py` runs |
| `addScriptDirToPath` | `true` | Makes the `.py` files next to the script importable (`import my_module`), as on the board, where the flash root is on the import path |
| `libraryPath` | `""` | Optional: any `.py` file of a shared library folder. Its folder is added to the import path |

A program is therefore split up as on the board: `main.py` + modules, or an off-the-shelf driver placed next to the program that imports it (examples `ImportDemo`, `I2c.GroveLcd`, `Weighing.KitchenScale`).

### Synchronisation

*General* tab.

| Parameter | Default | Role |
|---|---|---|
| `tickPeriod` | `0.1` s | Period of the minimal synchronisation point between the program and the circuit: outputs are read back at least at this rate, even if the program never sleeps. The default is fine |

### Execution time

*Temps d'exécution* tab.

| Parameter | Default | Role |
|---|---|---|
| `gpioOpTime` | `5e-6` s | Duration of a pin access (`value()`, `on()`, `off()`, `pin(x)`), the order of magnitude of MicroPython on an RP2040. Two successive writes without a `sleep` thus produce a real 5 µs pulse, which enables bit-banging (HX711 driver). `0` makes accesses instantaneous |

Pure Python computation, creating a pin, the ADC, PWM and reading the clock remain instantaneous.

### Electrical

*Électrique* tab. The defaults approximate an RP2040 powered at 3.3 V.

| Parameter | Default | Group | Role |
|---|---|---|---|
| `VOH` | 3.3 V | Niveaux logiques (logic levels) | Output voltage in the high state |
| `VOL` | 0 V | Niveaux logiques | Output voltage in the low state |
| `VIH` | 2.0 V | Niveaux logiques | Above it, an input reads 1 |
| `VIL` | 0.8 V | Niveaux logiques | Below it, an input reads 0 |
| `ROut` | 100 Ω | Étages de sortie (output stages) | Series resistance of each output (current the pin can deliver) |
| `ledSeriesR` | 330 Ω | Étages de sortie | Series resistance of the on-board LED |

### File system

*Système de fichiers* tab, "Flash simulée" group. What the program sees: [API, file system](api.md#file-system-open-and-os).

| Parameter | Default | Role |
|---|---|---|
| `fsEnabled` | `false` | Enables the simulated flash. When disabled, `open()` and `os` raise `OSError` |
| `fsSource` | `""` | Initial flash image: a folder (data, `boot.py`, `main.py`, `lib/`), given by any of its files, by its path or by a `modelica://` URI. Empty: blank flash |
| `fsWorkspace` | `"."` | Folder where each simulation creates its copy of the flash, named `<instance>_<FS name>_<date>_<time>`. Relative to the simulation folder |
| `fsOpenExplorer` | `true` | Opens Windows Explorer on the copy at the end of the simulation |

The source image is never modified: each simulation starts from a fresh copy, whose path is shown in the log. To chain two simulations, use the copy left by the previous one as `fsSource`. Example image supplied: `Resources/FileSystems/datalogger/` (examples `FileSystem` and `FileSystemScript`).

## Variables to plot

| Variable | Contents |
|---|---|
| `mcu.GP0.v` … `mcu.GP7.v` | Voltage of each pin: the signal as an oscilloscope would see it (serial frames, PWM and I2C bus included) |
| `mcu.GP0.i` … | Current flowing into the pin |
| `mcu.builtinLed.…` | On-board LED |
| `mcu.Display0.seq` | Number of messages sent to the display |

## One microcontroller per model

A model can hold only one `MCU` in this version: the Python interpreter is shared. Python-programmable peripherals (serial and I2C devices) are not affected and can be as many as needed.
