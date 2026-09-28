# Module of the flash (/lib is on the import path, as on the board):
# appends lines to a CSV file, writing the header when the file is created.
import os


class DataLog:
    def __init__(self, path, header):
        self.path = path
        folder, name = path.rsplit('/', 1)
        if name not in os.listdir(folder or '/'):
            with open(path, 'w') as f:
                f.write(header + '\n')

    def add(self, line):
        with open(self.path, 'a') as f:
            f.write(line + '\n')
