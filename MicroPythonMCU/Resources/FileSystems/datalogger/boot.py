# boot.py: run first when the board starts, before main.py.
# Creates the measurements folder if it does not exist yet.
import os

print('boot.py: starting')
if 'data' not in os.listdir('/'):
    os.mkdir('/data')
