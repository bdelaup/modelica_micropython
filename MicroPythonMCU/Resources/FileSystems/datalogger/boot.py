# boot.py : execute en premier au demarrage de la carte, avant main.py.
# Prepare le dossier des mesures s'il n'existe pas encore.
import os

print('boot.py : demarrage')
if 'data' not in os.listdir('/'):
    os.mkdir('/data')
