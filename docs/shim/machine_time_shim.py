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

class ADC:
    def __init__(self, id):
        if isinstance(id, Pin):
            id = id.id
        self.id = id

    def read_u16(self):
        v = _native.adc_read(self.id)
        raw = round(v / 3.3 * 65535)
        return 0 if raw < 0 else (65535 if raw > 65535 else raw)

_machine = types.ModuleType('machine')
_machine.Pin = Pin
_machine.ADC = ADC
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
