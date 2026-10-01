# MicroPythonMCU

**A Python-programmable microcontroller to drop into an OpenModelica diagram.**

`MicroPythonMCU` is an [OpenModelica](https://openmodelica.org/) library whose `MCU` block runs a real Python script written against the [MicroPython](https://micropython.org/) API (`machine`, `time`) of the Raspberry Pi Pico. Its pins are real electrical nodes: the script drives and measures the Modelica circuit around it. You can develop embedded code on the digital twin of a system before flashing it onto the real board.

![The BasicBlink model being simulated: the LED blinks](images/BasicBlink.gif){ width="320" }

<div class="grid cards" markdown>

-   **User guide**

    ---

    Install the library, simulate a first example, write your own program and wire peripherals. No knowledge of the internals is needed.

    [Getting started](guide/premiers-pas.md) · [The MCU block](guide/mcu.md) · [API](guide/api.md) · [Examples](guide/exemples.md)

-   **Maintainer reference** *(in French)*

    ---

    For those who develop the library: architecture, CPython integration, synchronisation protocol with the solver, serial and I2C engines, verification suite, releases.

    [Architecture](https://bdelaup.gitlab.io/modelica_micropython3/fr/interne/architecture/) · [Life cycle](https://bdelaup.gitlab.io/modelica_micropython3/fr/interne/cycle-de-vie/) · [Tests](https://bdelaup.gitlab.io/modelica_micropython3/fr/interne/tests/)

</div>

## What the microcontroller can do

| Feature | Script-side API | Details |
|---|---|---|
| Digital inputs / outputs, interrupts, bit-banging | `Pin`, `Pin.irq()` | [API](guide/api.md#machinepin) |
| Analog input, PWM output | `ADC`, `PWM` | [API](guide/api.md#machineadc) |
| Timers, delays | `Timer`, `time.sleep()` | [API](guide/api.md#machinetimer) |
| Electrical serial link | `UART` | [Serial devices](guide/peripheriques/uart.md) |
| Open-drain I2C master bus | `I2C` | [I2C devices](guide/peripheriques/i2c.md) |
| Flash-like file system, `boot.py` / `main.py` | `open()`, `os` | [API](guide/api.md#file-system-open-and-os) |
| Module imports, off-the-shelf drivers | `import` | [The MCU block](guide/mcu.md#python-script) |

A `time.sleep(1)` costs no real time: the solver jumps straight to the deadline. One simulated hour runs in a fraction of a second.

## Supplied peripherals

LED, teaching display, serial devices (echo, temperature sensor, GPS, 20x2 display, generic device), I2C devices (Grove LCD RGB display, echo, generic device) and a complete weighing chain (load cell, strain-gauge bridge, HX711 converter). The 37 [examples](guide/exemples.md) use all of them, up to a kitchen scale that runs off-the-shelf MicroPython drivers unmodified.

## Current limits

Windows only, no SPI. A model can hold several microcontrollers, which talk through their pins, a serial link or an I2C bus. Full list: [Limits and troubleshooting](guide/limites.md).

## Background

Library designed by Benoit Delaup, an engineering science teacher, so that students can test their control code on the digital system before deploying it to a real prototype; it also fits an industrial embedded-software digital twin. Source code and issues: [GitLab repository](https://gitlab.com/bdelaup/modelica_micropython3). Architecture choices and their alternatives are recorded (in French) in [`requirements.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md).
