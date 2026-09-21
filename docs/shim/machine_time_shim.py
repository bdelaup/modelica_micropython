# Miroir lisible du shim `machine`/`time`
#
# Ce fichier N'EST PAS exécuté par PyRuntime : la source de vérité réellement
# injectée dans l'interpréteur (via PyRun_SimpleString) est la chaîne C
# SHIM_BOOTSTRAP dans MicroPythonMCU/Resources/Include/PyRuntimeImpl.c
# (recherche "SHIM_BOOTSTRAP"). Ce miroir en est une transcription fidèle
# (dé-échappée), maintenue à la main pour la lisibilité — à resynchroniser
# manuellement si SHIM_BOOTSTRAP change. Voir docs/api-machine.md pour la
# référence de l'API côté script, et docs/integration-python.md pour le
# contexte d'intégration (couche native _pyruntime_native en dessous).

import sys, types, _pyruntime_native as _native

class Pin:
    IN = 0
    OUT = 1
    PULL_UP = 2
    PULL_DOWN = 3
    LED = 25  # doit rester aligné sur LED_PIN_ID côté C (PyRuntimeImpl.c)
    IRQ_RISING = 1   # doit rester aligné sur IRQ_TRIGGER_RISING côté C
    IRQ_FALLING = 2  # doit rester aligné sur IRQ_TRIGGER_FALLING côté C

    def __init__(self, id, mode=None, pull=None):
        if id == 'LED':
            id = Pin.LED
        self.id = id
        if mode is not None:
            _native.pin_init(self.id, 1 if mode == Pin.OUT else 0)

    def value(self, x=None):
        if x is None:
            return 1 if _native.pin_read(self.id) else 0
        _native.pin_write(self.id, 1 if x else 0)

    def on(self):
        _native.pin_write(self.id, 1)

    def off(self):
        _native.pin_write(self.id, 0)

    def toggle(self):
        self.value(0 if self.value() else 1)

    def irq(self, handler=None, trigger=IRQ_RISING | IRQ_FALLING, **kwargs):
        _native.pin_irq_set(self.id, self, handler, trigger)

class ADC:
    def __init__(self, id):
        if isinstance(id, Pin):
            id = id.id
        self.id = id

    def read_u16(self):
        v = _native.adc_read(self.id)
        raw = round(v / 3.3 * 65535)
        return 0 if raw < 0 else (65535 if raw > 65535 else raw)

class PWM:
    def __init__(self, pin, freq=None, duty_u16=None):
        if isinstance(pin, Pin):
            pin = pin.id
        self.id = pin
        self._freq = 0
        self._duty = 0
        if freq is not None:
            self.freq(freq)
        if duty_u16 is not None:
            self.duty_u16(duty_u16)

    def freq(self, f=None):
        if f is None:
            return self._freq
        _native.pwm_set_freq(self.id, float(f))
        self._freq = int(f)

    def duty_u16(self, d=None):
        if d is None:
            return self._duty
        _native.pwm_set_duty(self.id, d / 65535.0)
        self._duty = d

    def deinit(self):
        _native.pwm_deinit(self.id)
        self._freq = 0

class Timer:
    ONE_SHOT = 0
    PERIODIC = 1

    def __init__(self, id=-1):
        self._slot = _native.timer_new()

    def init(self, period=1000, mode=PERIODIC, callback=None):
        _native.timer_init(self._slot, period / 1000.0, mode, callback, self)

    def deinit(self):
        _native.timer_deinit(self._slot)

_machine = types.ModuleType('machine')
_machine.Pin = Pin
_machine.ADC = ADC
_machine.PWM = PWM
_machine.Timer = Timer
sys.modules['machine'] = _machine

def sleep(s):
    _native.sleep(float(s))

def sleep_ms(ms):
    _native.sleep(ms / 1000.0)

def sleep_us(us):
    _native.sleep(us / 1000000.0)

def ticks_ms():
    return _native.ticks_ms()

def ticks_us():
    return _native.ticks_ms() * 1000

def ticks_diff(a, b):
    return a - b

_time = types.ModuleType('time')
_time.sleep = sleep
_time.sleep_ms = sleep_ms
_time.sleep_us = sleep_us
_time.ticks_ms = ticks_ms
_time.ticks_us = ticks_us
_time.ticks_diff = ticks_diff
sys.modules['time'] = _time
