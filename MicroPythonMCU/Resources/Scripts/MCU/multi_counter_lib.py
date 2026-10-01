"""Helper module with module-level state, imported by multi_counter.py.

Examples.MultiMcu.Independent runs that program on two microcontrollers: each
must get its own copy of this module, so each counts only its own ticks."""

count = 0


def tick():
    global count
    count += 1
    return count
