/* Comportement d'un peripherique serie decrit par un script Python.

   La mecanique commune a tous les peripheriques scriptes (espace de noms propre
   a chaque instance, prelude print, conversion des valeurs, arret propre en cas
   d'exception) vit dans devscript.c, partage avec les peripheriques I2C. Ne
   reste ici que ce qui est propre a la liaison serie : le contrat ci-dessous.

   Contrat du script - trois fonctions, toutes facultatives :
     on_receive(ligne, t, v) -> bytes | str | None   une fois par ligne complete
     on_tick(t, v)           -> bytes | str | None   une fois par periode (si definie)
     outputs()               -> nombre | sequence    relue apres chaque gestionnaire
   ligne : bytes, sans le terminateur. t : temps simule (s). v : tuple des
   UARTDEV_MAX_VALUES grandeurs de valueIn.

   Inclus TEXTUELLEMENT par UartDeviceImpl.c, jamais compile seul. */

#ifndef UARTDEVICE_SCRIPT_C_INCLUDED
#define UARTDEVICE_SCRIPT_C_INCLUDED

#define UARTDEV_COMPONENT "UartDevice"

/* Appelle un gestionnaire deja muni de ses arguments (reference volee), puis
   relit outputs(). Retourne la longueur de la charge utile a emettre. En cas
   d'exception dans le script, arrete la simulation (ne revient pas). */
static int uartdev_script_call(struct UartDevice* dev, PyObject* func, const char* name,
                                PyObject* args, char* out, int outmax) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject* r;
    int n;
    char what[96];

    if (!args) {
        devscript_fail(UARTDEV_COMPONENT, dev->script_path, gstate, "echec de construction des arguments");
        return 0;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    r = PyObject_CallObject(func, args);
    Py_DECREF(args);
    if (!r) {
        snprintf(what, sizeof(what), "%s() a leve une exception", name);
        devscript_fail(UARTDEV_COMPONENT, dev->script_path, gstate, what);
        return 0;
    }
    n = devscript_payload(r, out, outmax);
    Py_DECREF(r);
    if (n < 0) {
        snprintf(what, sizeof(what), "valeur de retour de %s() invalide", name);
        devscript_fail(UARTDEV_COMPONENT, dev->script_path, gstate, what);
        return 0;
    }
    if (devscript_read_outputs(dev->py_outputs, dev->value_out, UARTDEV_MAX_VALUES) != 0) {
        devscript_fail(UARTDEV_COMPONENT, dev->script_path, gstate, "outputs() a echoue");
        return 0;
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
    return n;
}

static int uartdev_script_on_line(struct UartDevice* dev, const char* line, int len, char* out, int outmax) {
    PyObject* args;
    PyObject* values;
    if (!dev->py_on_receive) {
        return 0;
    }
    {
        PyGILState_STATE gstate = PyGILState_Ensure();
        values = devscript_values(dev->value_in, UARTDEV_MAX_VALUES);
        args = values ? Py_BuildValue("(y#dN)", line, (Py_ssize_t) len, dev->now, values) : NULL;
        PyGILState_Release(gstate);
    }
    return uartdev_script_call(dev, dev->py_on_receive, "on_receive", args, out, outmax);
}

static int uartdev_script_on_tick(struct UartDevice* dev, char* out, int outmax) {
    PyObject* args;
    PyObject* values;
    if (!dev->py_on_tick) {
        return 0;
    }
    {
        PyGILState_STATE gstate = PyGILState_Ensure();
        values = devscript_values(dev->value_in, UARTDEV_MAX_VALUES);
        args = values ? Py_BuildValue("(dN)", dev->now, values) : NULL;
        PyGILState_Release(gstate);
    }
    return uartdev_script_call(dev, dev->py_on_tick, "on_tick", args, out, outmax);
}

/* Charge le script (devscript_load) et retient les trois gestionnaires. En cas
   d'echec, arrete la simulation (ne revient pas). */
static void uartdev_script_load(struct UartDevice* dev, const char* pythonHome, const char* instanceName) {
    PyGILState_STATE gstate;
    PyObject* globals = devscript_load(UARTDEV_COMPONENT, dev->script_path, pythonHome, instanceName);

    gstate = PyGILState_Ensure();
    dev->py_globals = globals;
    dev->py_on_receive = devscript_handler(globals, "on_receive");
    dev->py_on_tick = devscript_handler(globals, "on_tick");
    dev->py_outputs = devscript_handler(globals, "outputs");

    /* Valeurs initiales des sorties : celles que le script declare, s'il le fait. */
    if (devscript_read_outputs(dev->py_outputs, dev->value_out, UARTDEV_MAX_VALUES) != 0) {
        devscript_fail(UARTDEV_COMPONENT, dev->script_path, gstate, "outputs() a echoue au chargement");
        return;
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
}

#endif /* UARTDEVICE_SCRIPT_C_INCLUDED */
