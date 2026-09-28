# main.py: run after boot.py. Data logger: reads the voltage on GP0 (ADC)
# at regular intervals and appends it to /data/measurements.csv.
# The settings come from /config.txt, the DataLog module from /lib.
import os
import time
from machine import ADC, Pin
from datalog import DataLog

settings = {}
with open('config.txt') as f:
    for line in f:
        if '=' in line:
            key, value = line.strip().split('=', 1)
            settings[key] = value
period_ms = int(settings['period_ms'])
samples = int(settings['samples'])

adc = ADC(0)
log = DataLog('/data/measurements.csv', 't_ms;voltage_V')
for i in range(samples):
    voltage = adc.read_u16() * 3.3 / 65535
    log.add('%d;%.3f' % (time.ticks_ms(), voltage))
    time.sleep_ms(period_ms)

# Self-check (used by the verification scenario): the LED on GP1
# lights up if everything above went as expected.
with open('/data/measurements.csv') as f:
    lines = f.read().split('\n')
ok = lines[0] == 't_ms;voltage_V' and len(lines) == samples + 2 and lines[-1] == ''
ok = ok and [int(l.split(';')[0]) for l in lines[1:-1]] == [i * period_ms for i in range(samples)]
ok = ok and os.getcwd() == '/' and os.stat('/data')[0] == 0x4000
ok = ok and os.listdir('/lib') == ['datalog.py']       # no __pycache__ in the flash
with open('../../outside_flash.txt', 'w') as f:        # ".." stops at the root:
    f.write('stays in the flash\n')                     # the file lands in /outside_flash.txt
ok = ok and os.listdir('/') == ['boot.py', 'config.txt', 'data', 'lib', 'main.py', 'outside_flash.txt']
print('main.py:', len(lines) - 2, 'samples logged, self-check', 'OK' if ok else 'FAILED')
Pin(1, Pin.OUT).value(1 if ok else 0)
