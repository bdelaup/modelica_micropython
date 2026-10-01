/* Moteur d'un peripherique I2C esclave : journal, crochets vers le script,
   construction, point de synchro appele par Modelica.

   Inclus TEXTUELLEMENT par I2cDeviceImpl.c, jamais compile seul.

   Le decodage du bus (START / adresse / octets / ACK / STOP, pilote par les
   FRONTS de SCL et SDA) vit dans i2ctarget.c, partage avec machine.I2CTarget du
   microcontroleur. Le "when" de Internal.PartialI2cDevice se declenche a chaque
   franchissement de seuil de SCL ou de SDA ; I2cDevice_sync transmet les
   niveaux au moteur, qui appelle en retour les crochets ci-dessous - on_write()
   a la fin d'une phase d'ecriture, on_read() quand le maitre lit.

   Rappeler la fonction au MEME instant avec les memes niveaux ne fait rien : il
   n'y a pas de front. C'est ce qui la rend sure face aux iterations d'evenements
   de Modelica, comme UartDevice_sync. */

#ifndef I2CDEVICE_ENGINE_C_INCLUDED
#define I2CDEVICE_ENGINE_C_INCLUDED

/* ===================== journal ===================== */

/* "ecriture 0x3E : 80 01" / "lecture 0x42 : 48 69" (tronque si long). */
static void i2cdev_log(struct I2cDevice* dev, const char* what, int addr, const unsigned char* data, int len) {
    int pos, k;
    pos = snprintf(dev->last_event, I2CDEV_EVENT_MAX + 1, "%s 0x%02X:", what, addr);
    for (k = 0; k < len && pos < I2CDEV_EVENT_MAX - 4; k++) {
        pos += snprintf(dev->last_event + pos, (size_t) (I2CDEV_EVENT_MAX + 1 - pos), " %02X", data[k]);
    }
    if (k < len && pos < I2CDEV_EVENT_MAX - 3) {
        snprintf(dev->last_event + pos, (size_t) (I2CDEV_EVENT_MAX + 1 - pos), " ...");
    }
    dev->event_seq++;
}

/* ===================== crochets du moteur cible ===================== */

/* Phase d'ecriture close. Une ecriture vide est une sonde d'adresse (scan()) :
   rien a livrer, rien a journaliser. */
static void i2cdev_hook_write_end(void* ctx, int addr, const unsigned char* data, int len) {
    struct I2cDevice* dev = (struct I2cDevice*) ctx;
    if (len > 0) {
        i2cdev_script_on_write(dev, addr, data, len);
        i2cdev_log(dev, "write", addr, data, len);
    }
}

/* Adresse reconnue : une lecture repart d'un lot vide. */
static void i2cdev_hook_addr_match(void* ctx, int addr, int read) {
    struct I2cDevice* dev = (struct I2cDevice*) ctx;
    if (read) {
        dev->rlen = 0;
        dev->rpos = 0;
    }
}

/* Octet suivant a sortir en lecture ; on_read() est (re)appelee quand le lot
   precedent est epuise, et la ligne reste relachee (0xFF) s'il ne rend rien. */
static int i2cdev_hook_read_byte(void* ctx, int addr, int may_defer) {
    struct I2cDevice* dev = (struct I2cDevice*) ctx;
    if (dev->rpos >= dev->rlen) {
        dev->rlen = i2cdev_script_on_read(dev, addr);
        dev->rpos = 0;
    }
    return dev->rpos < dev->rlen ? dev->rbuf[dev->rpos++] : 0xFF;
}

static void i2cdev_hook_read_end(void* ctx, int addr, const unsigned char* data, int len) {
    i2cdev_log((struct I2cDevice*) ctx, "read", addr, data, len);
}

static const struct I2cTargetHooks I2CDEV_HOOKS = {
    i2cdev_hook_addr_match, NULL, i2cdev_hook_write_end,
    i2cdev_hook_read_byte, i2cdev_hook_read_end
};

/* ===================== API exportee ===================== */

/* "0x3E, 0x62" -> {0x3E, 0x62}. Hexadecimal ou decimal (strtol base 0),
   separateurs virgule, point-virgule ou espace. */
static int i2cdev_parse_addresses(struct I2cDevice* dev, const char* s) {
    const char* p = s ? s : "";
    dev->bus.n_addr = 0;
    while (*p) {
        char* end;
        long v;
        while (*p == ' ' || *p == ',' || *p == ';' || *p == '\t') {
            p++;
        }
        if (!*p) {
            break;
        }
        v = strtol(p, &end, 0);
        if (end == p) {
            ModelicaFormatError("I2cDevice: unreadable address in \"%s\" (expected e.g. \"0x42\" or \"0x3E, 0x62\")", s);
            return -1;
        }
        if (v < 0 || v > 0x7F) {
            ModelicaFormatError("I2cDevice: address %ld out of range (0x00-0x7F, 7-bit address) in \"%s\"", v, s);
            return -1;
        }
        if (dev->bus.n_addr >= I2CDEV_MAX_ADDR) {
            ModelicaFormatError("I2cDevice: at most %d addresses per component (\"%s\")", I2CDEV_MAX_ADDR, s);
            return -1;
        }
        dev->bus.addresses[dev->bus.n_addr++] = (int) v;
        p = end;
    }
    if (dev->bus.n_addr == 0) {
        ModelicaFormatError("I2cDevice: no address given - give for example \"0x42\"");
        return -1;
    }
    return 0;
}

void* I2cDevice_new(const char* addresses, const char* scriptPath,
                     const char* pythonHome, const char* instanceName) {
    struct I2cDevice* dev = (struct I2cDevice*) calloc(1, sizeof(struct I2cDevice));
    if (!dev) {
        ModelicaFormatError("I2cDevice: allocation failed");
        return NULL;
    }
    if (i2cdev_parse_addresses(dev, addresses) != 0) {
        return NULL;
    }
    if (strlen(scriptPath ? scriptPath : "") > I2CDEV_PATH_MAX) {
        ModelicaFormatError("I2cDevice: script path too long");
        return NULL;
    }
    strcpy(dev->script_path, scriptPath ? scriptPath : "");
    i2ct_init(&dev->bus, &I2CDEV_HOOKS, dev);
    i2cdev_script_load(dev, pythonHome, instanceName);
    return (void*) dev;
}

void I2cDevice_destroy(void* dev_) {
    /* Meme choix delibere que PyRuntime_destroy et UartDevice_destroy : chaque
       simulation tourne dans son propre process, l'OS recupere tout. */
    (void) dev_;
}

static const char* i2cdev_modelica_string(const char* s) {
    char* out = ModelicaAllocateString(strlen(s));
    strcpy(out, s);
    return out;
}

void I2cDevice_sync(void* dev_, double currentTime, int sclLevel, int sdaLevel, const double* valueIn,
                     double* valueOut, int* sdaDriveLowOut, int* busyOut, int* eventSeqOut,
                     const char** lastEventOut, const char** line1Out, const char** line2Out) {
    struct I2cDevice* dev = (struct I2cDevice*) dev_;
    int k;

    dev->now = currentTime;
    for (k = 0; k < I2CDEV_MAX_VALUES; k++) {
        dev->value_in[k] = valueIn[k];
    }

    i2ct_sync(&dev->bus, sclLevel, sdaLevel);

    for (k = 0; k < I2CDEV_MAX_VALUES; k++) {
        valueOut[k] = dev->value_out[k];
    }
    *sdaDriveLowOut = dev->bus.drive_low;
    *busyOut = i2ct_busy(&dev->bus);
    *eventSeqOut = dev->event_seq;
    *lastEventOut = i2cdev_modelica_string(dev->last_event);
    *line1Out = i2cdev_modelica_string(dev->line1);
    *line2Out = i2cdev_modelica_string(dev->line2);
}

#endif /* I2CDEVICE_ENGINE_C_INCLUDED */
