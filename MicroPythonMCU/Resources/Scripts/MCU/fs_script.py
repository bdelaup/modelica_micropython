# Program run instead of main.py, after the boot.py of the flash - like
# Thonny running the open script on an already booted board.
import os
from machine import Pin

# boot.py has run: it created /data. main.py has not run: /data is
# still empty (no measurements.csv).
ok = 'data' in os.listdir('/') and os.listdir('/data') == []

with open('/data/notes.txt', 'w') as f:
    f.write('written by the script\n')
with open('/data/notes.txt') as f:
    ok = ok and f.read() == 'written by the script\n'

print('fs_script.py: boot.py run, main.py replaced -', 'OK' if ok else 'FAILED')
Pin(1, Pin.OUT).value(1 if ok else 0)
