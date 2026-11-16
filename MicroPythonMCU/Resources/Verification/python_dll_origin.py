# Scenario n°29 : verifier le chemin du runtime Python effectivement charge.
from machine import Pin
import sys
import time


if sys.platform == "win32":
    import _winapi

    dll = _winapi.GetModuleFileName(sys.dllhandle)
    normalise = lambda chemin: chemin.replace('/', '\\').rstrip('\\').lower()
    expected = normalise(sys.prefix) + "\\python312.dll"
    actual = normalise(dll)
else:
    import ctypes

    class DlInfo(ctypes.Structure):
        _fields_ = [("name", ctypes.c_char_p), ("base", ctypes.c_void_p),
                    ("symbol", ctypes.c_char_p), ("address", ctypes.c_void_p)]

    dladdr = ctypes.CDLL(None).dladdr
    dladdr.argtypes = [ctypes.c_void_p, ctypes.POINTER(DlInfo)]
    dladdr.restype = ctypes.c_int
    info = DlInfo()
    if not dladdr(ctypes.cast(ctypes.pythonapi.Py_IsInitialized, ctypes.c_void_p),
                  ctypes.byref(info)) or not info.name:
        raise RuntimeError("dladdr n'a pas trouve la bibliotheque Python")
    dll = info.name.decode(sys.getfilesystemencoding())
    actual = dll.rstrip("/")
    expected = sys.prefix.rstrip("/") + "/linux-x86_64/lib/libpython3.12.so.1.0"

print("Bibliotheque Python chargee :", dll)
print("distribution embarquee :", sys.prefix)

if actual != expected:
    raise RuntimeError("Bibliotheque Python inattendue : " + dll + " (attendue : " + expected + ")")

Pin(0, Pin.OUT).on()
time.sleep(1)
