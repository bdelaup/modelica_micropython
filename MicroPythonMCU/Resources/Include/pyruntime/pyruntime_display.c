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

/* Ajoute un message a la file de l'instant (cs tenu). Un message est une
   ligne : un saut de ligne passe par un appel direct a la native devient une
   espace (le shim decoupe deja le texte en lignes). File pleine : les plus
   anciens messages tombent, l'afficheur ne montre de toute facon que les
   derniers. */
static void display_queue(struct PyRuntimeHandle* h, const char* text) {
    char msg[DISPLAY_MSG_MAX_LEN + 1];
    size_t n = strlen(text);
    size_t i;
    if (n > DISPLAY_MSG_MAX_LEN) n = DISPLAY_MSG_MAX_LEN;  /* tronque si trop long, restriction assumee */
    for (i = 0; i < n; i++) {
        msg[i] = (text[i] == '\n' || text[i] == '\r') ? ' ' : text[i];
    }
    msg[n] = '\0';
    if (h->display_queued == 0) {
        strcpy(h->display_payload, msg);
    } else {
        size_t len = strlen(h->display_payload);
        while (len > 0 && len + 1 + n > DISPLAY_QUEUE_MAX_LEN) {
            char* nl = strchr(h->display_payload, '\n');
            if (!nl) {
                len = 0;
                h->display_payload[0] = '\0';
                break;
            }
            memmove(h->display_payload, nl + 1, strlen(nl + 1) + 1);
            len = strlen(h->display_payload);
        }
        if (len > 0) {
            h->display_payload[len] = '\n';
            strcpy(h->display_payload + len + 1, msg);
        } else {
            strcpy(h->display_payload, msg);
        }
    }
    h->display_queued++;
    h->display_seq++;
}

/* Sorties displaySeq/displayPayload d'un point de synchro : tous les messages
   ecrits depuis la publication precedente, puis la file repart de zero (le
   texte reste publie tel quel jusqu'au prochain write(), seq ne bouge pas). */
static void publish_display(struct PyRuntimeHandle* h, int* displaySeqOut, const char** displayPayloadOut) {
    *displaySeqOut = h->display_seq;
    *displayPayloadOut = ModelicaAllocateString(strlen(h->display_payload));
    strcpy((char*) *displayPayloadOut, h->display_payload);
    h->display_queued = 0;
}

static PyObject* native_display_write(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id;
    const char* text;
    if (!PyArg_ParseTuple(args, "is", &id, &text)) return NULL;
    if (resolve_display_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "Display %d not supported (only Display(0) exists)", id);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    display_queue(g_current, text);
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}
