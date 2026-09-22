/* machine.Display : peripherique pedagogique d'affichage, ecriture seule.

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

/* --- machine.Display : périphérique pédagogique, un seul sens (ecriture) --- */

/* Un seul id supporte pour l'instant (0, MCU.Display0) - meme esprit que
   resolve_pin_index. */
static int resolve_display_index(int id) {
    if (id == 0) return 0;
    return -1;
}

static PyObject* native_display_write(PyObject* self, PyObject* args) {
    int id;
    const char* text;
    if (!PyArg_ParseTuple(args, "is", &id, &text)) return NULL;
    if (resolve_display_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "Display %d non supporte pour la v0 (seul Display(0) existe)", id);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    strncpy(g_current->display_payload, text, DISPLAY_MSG_MAX_LEN);
    g_current->display_payload[DISPLAY_MSG_MAX_LEN] = '\0';  /* tronque si trop long, restriction v0 assumee */
    g_current->display_seq++;
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}
