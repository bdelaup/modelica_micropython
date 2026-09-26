/* Comportement d'un peripherique I2C decrit par un script Python - le seul mode
   qui existe pour l'I2C (pas de table de commandes, contrairement a l'UART).

   La mecanique commune a tous les peripheriques scriptes (espace de noms propre
   a chaque instance, prelude print, conversions, arret propre sur exception) vit
   dans devscript.c. Ne reste ici que le contrat propre a l'I2C, au niveau
   TRANSACTION - le script ne voit jamais les bits, ni les START/STOP, ni les ACK :

     on_write(addr, data, t, v)      une phase d'ecriture adressee vient de se
                                     clore (STOP ou START repete), data = bytes
                                     recus (jamais vide : une sonde d'adresse
                                     comme celle de scan() n'appelle rien)
     on_read(addr, t, v) -> octets   le maitre commence a lire : bytes, bytearray,
                                     str, liste d'entiers ou entier. Les octets
                                     sortent un par un ; si le maitre en demande
                                     plus, on_read() est rappelee, et 0xFF sort
                                     si elle ne rend rien (ligne relachee)
     outputs() -> nombre | sequence  relue apres chaque gestionnaire -> valueOut
     lines() -> (str, str)           relue apres chaque gestionnaire -> texte
                                     affiche (sert aux ecrans), facultative

   addr : l'adresse sur 7 bits a laquelle le maitre s'est adresse (un composant
   peut en avoir plusieurs). t : temps simule (s). v : tuple des
   I2CDEV_MAX_VALUES grandeurs de valueIn.

   Inclus TEXTUELLEMENT par I2cDeviceImpl.c, jamais compile seul. */

#ifndef I2CDEVICE_SCRIPT_C_INCLUDED
#define I2CDEVICE_SCRIPT_C_INCLUDED

#define I2CDEV_COMPONENT "I2cDevice"

static void i2cdev_copy_text(char* dst, int dstmax, const char* src, Py_ssize_t len) {
    if (len > dstmax) {
        len = dstmax;
    }
    memcpy(dst, src, (size_t) len);
    dst[len] = '\0';
}

/* Relit outputs() et lines(). GIL tenu. 0 ou -1 (PyErr positionne). */
static int i2cdev_script_refresh(struct I2cDevice* dev) {
    PyObject* r;
    if (devscript_read_outputs(dev->py_outputs, dev->value_out, I2CDEV_MAX_VALUES) != 0) {
        return -1;
    }
    if (!dev->py_lines) {
        return 0;
    }
    r = PyObject_CallNoArgs(dev->py_lines);
    if (!r) {
        return -1;
    }
    if (PyUnicode_Check(r)) {
        Py_ssize_t len;
        const char* s = PyUnicode_AsUTF8AndSize(r, &len);
        if (!s) {
            Py_DECREF(r);
            return -1;
        }
        i2cdev_copy_text(dev->line1, I2CDEV_TEXT_MAX, s, len);
        dev->line2[0] = '\0';
    } else if (PySequence_Check(r)) {
        Py_ssize_t n = PySequence_Size(r);
        int k;
        for (k = 0; k < 2; k++) {
            char* dst = k == 0 ? dev->line1 : dev->line2;
            PyObject* item;
            const char* s;
            Py_ssize_t len;
            if (k >= n) {
                dst[0] = '\0';
                continue;
            }
            item = PySequence_GetItem(r, k);
            if (!item) {
                Py_DECREF(r);
                return -1;
            }
            if (!PyUnicode_Check(item)) {
                Py_DECREF(item);
                Py_DECREF(r);
                PyErr_SetString(PyExc_TypeError, "lines() doit retourner des chaines");
                return -1;
            }
            s = PyUnicode_AsUTF8AndSize(item, &len);
            if (s) {
                i2cdev_copy_text(dst, I2CDEV_TEXT_MAX, s, len);
            }
            Py_DECREF(item);
            if (!s) {
                Py_DECREF(r);
                return -1;
            }
        }
    } else {
        Py_DECREF(r);
        PyErr_SetString(PyExc_TypeError, "lines() doit retourner une chaine ou une sequence de deux chaines");
        return -1;
    }
    Py_DECREF(r);
    return 0;
}

/* Octets rendus par on_read() : en plus de ce qu'accepte devscript_payload
   (bytes, bytearray, str, None), un entier seul ou une liste d'entiers, plus
   naturels pour un registre. GIL tenu. Longueur, ou -1 avec PyErr. */
static int i2cdev_script_read_payload(PyObject* r, unsigned char* out, int outmax) {
    char tmp[I2CDEV_BUF_MAX + 1];
    int n;
    if (PyLong_Check(r)) {
        long v = PyLong_AsLong(r);
        if (PyErr_Occurred()) {
            return -1;
        }
        if (v < 0 || v > 255) {
            PyErr_SetString(PyExc_ValueError, "on_read() : un entier rendu doit etre un octet (0-255)");
            return -1;
        }
        out[0] = (unsigned char) v;
        return 1;
    }
    if (r == Py_None || PyBytes_Check(r) || PyByteArray_Check(r) || PyUnicode_Check(r)) {
        n = devscript_payload(r, tmp, outmax < I2CDEV_BUF_MAX ? outmax : I2CDEV_BUF_MAX);
    } else {
        /* liste/tuple d'entiers : bytes(r) fait la validation (0-255) */
        PyObject* b = PyBytes_FromObject(r);
        if (!b) {
            return -1;
        }
        n = devscript_payload(b, tmp, outmax < I2CDEV_BUF_MAX ? outmax : I2CDEV_BUF_MAX);
        Py_DECREF(b);
    }
    if (n > 0) {
        memcpy(out, tmp, (size_t) n);
    }
    return n;
}

static void i2cdev_script_fail_call(struct I2cDevice* dev, PyGILState_STATE gstate, const char* name, const char* what) {
    char msg[128];
    snprintf(msg, sizeof(msg), "%s() %s", name, what);
    devscript_fail(I2CDEV_COMPONENT, dev->script_path, gstate, msg);
}

/* Une phase d'ecriture adressee s'est close. */
static void i2cdev_script_on_write(struct I2cDevice* dev, int addr, const unsigned char* data, int len) {
    PyGILState_STATE gstate;
    PyObject* values;
    PyObject* r;
    if (!dev->py_on_write) {
        return;
    }
    gstate = PyGILState_Ensure();
    values = devscript_values(dev->value_in, I2CDEV_MAX_VALUES);
    r = values ? PyObject_CallFunction(dev->py_on_write, "iy#dN", addr, (const char*) data, (Py_ssize_t) len, dev->now, values) : NULL;
    if (!r) {
        i2cdev_script_fail_call(dev, gstate, "on_write", "a leve une exception");
        return;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    Py_DECREF(r);
    if (i2cdev_script_refresh(dev) != 0) {
        i2cdev_script_fail_call(dev, gstate, "outputs/lines", "a echoue apres on_write");
        return;
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
}

/* Le maitre lit : remplit rbuf. Retourne le nombre d'octets fournis. */
static int i2cdev_script_on_read(struct I2cDevice* dev, int addr) {
    PyGILState_STATE gstate;
    PyObject* values;
    PyObject* r;
    int n;
    if (!dev->py_on_read) {
        return 0;
    }
    gstate = PyGILState_Ensure();
    values = devscript_values(dev->value_in, I2CDEV_MAX_VALUES);
    r = values ? PyObject_CallFunction(dev->py_on_read, "idN", addr, dev->now, values) : NULL;
    if (!r) {
        i2cdev_script_fail_call(dev, gstate, "on_read", "a leve une exception");
        return 0;
    }
    n = i2cdev_script_read_payload(r, dev->rbuf, I2CDEV_BUF_MAX);
    Py_DECREF(r);
    if (n < 0) {
        i2cdev_script_fail_call(dev, gstate, "on_read", "a rendu une valeur invalide (bytes, str, entier ou liste d'entiers attendu)");
        return 0;
    }
    if (i2cdev_script_refresh(dev) != 0) {
        i2cdev_script_fail_call(dev, gstate, "outputs/lines", "a echoue apres on_read");
        return 0;
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
    return n;
}

/* Charge le script (devscript_load) et retient les gestionnaires. En cas
   d'echec, arrete la simulation (ne revient pas). */
static void i2cdev_script_load(struct I2cDevice* dev, const char* pythonHome, const char* instanceName) {
    PyGILState_STATE gstate;
    PyObject* globals = devscript_load(I2CDEV_COMPONENT, dev->script_path, pythonHome, instanceName);

    gstate = PyGILState_Ensure();
    dev->py_globals = globals;
    dev->py_on_write = devscript_handler(globals, "on_write");
    dev->py_on_read = devscript_handler(globals, "on_read");
    dev->py_outputs = devscript_handler(globals, "outputs");
    dev->py_lines = devscript_handler(globals, "lines");
    if (i2cdev_script_refresh(dev) != 0) {
        devscript_fail(I2CDEV_COMPONENT, dev->script_path, gstate, "outputs() ou lines() a echoue au chargement");
        return;
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
}

#endif /* I2CDEVICE_SCRIPT_C_INCLUDED */
