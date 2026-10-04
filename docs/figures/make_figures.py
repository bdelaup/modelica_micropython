"""Génère les courbes de simulation de la documentation (docs/fr/images/sim/*.svg).

Chaque figure simule un exemple de MicroPythonMCU.Examples avec omc (sortie CSV
filtrée sur quelques variables), puis trace le résultat avec matplotlib. Les
images sont communes aux deux langues : textes des figures en français, légendes
traduites dans les pages anglaises.

    python docs/figures/make_figures.py            # toutes les figures
    python docs/figures/make_figures.py uart i2c   # seulement celles-ci

Prérequis : omc sur le PATH (ou OPENMODELICAHOME), matplotlib. Les simulations
tournent dans un dossier temporaire hors du dépôt (OneDrive verrouille les
fichiers neufs).
"""
import csv
import os
import shutil
import subprocess
import sys
import tempfile

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PACKAGE = os.path.join(ROOT, "MicroPythonMCU", "package.mo").replace("\\", "/")
OUT = os.path.join(ROOT, "docs", "fr", "images", "sim")

BLUE, ORANGE, GREEN, GREY = "#2f6fb5", "#d9822b", "#3a9a5b", "#8a8a8a"


def omc_exe():
    home = os.environ.get("OPENMODELICAHOME")
    if home and os.path.exists(os.path.join(home, "bin", "omc.exe")):
        return os.path.join(home, "bin", "omc.exe")
    exe = shutil.which("omc")
    if not exe:
        sys.exit("omc introuvable : positionner OPENMODELICAHOME ou compléter le PATH")
    return exe


def simulate(model, variables, stop, intervals, work, simflags=""):
    """Simule MicroPythonMCU.Examples.<model>, rend {variable: [valeurs]} et le temps.
    simflags="-emit_protected" pour tracer une variable protégée (mcu.pwmDuty...)."""
    prefix = model.replace(".", "_")
    regex = "|".join(v.replace("[", "\\\\[").replace("]", "\\\\]") for v in variables)
    mos = os.path.join(work, prefix + ".mos")
    with open(mos, "w", encoding="utf-8") as f:
        f.write('loadModel(Modelica); getErrorString();\n')
        f.write('loadFile("%s"); getErrorString();\n' % PACKAGE)
        f.write('r := simulate(MicroPythonMCU.Examples.%s, stopTime=%g, numberOfIntervals=%d, '
                'outputFormat="csv", variableFilter="time|%s", fileNamePrefix="%s", simflags="%s"); '
                'getErrorString();\n' % (model, stop, intervals, regex, prefix, simflags))
        f.write('print(r.messages);\n')
    log = subprocess.run([omc_exe(), mos], cwd=work, capture_output=True, text=True)
    res = os.path.join(work, prefix + "_res.csv")
    if not os.path.exists(res):
        sys.exit("échec de la simulation de %s :\n%s%s" % (model, log.stdout, log.stderr))
    with open(res, newline="") as f:
        rows = list(csv.reader(f))
    head = [h.strip('"') for h in rows[0]]
    cols = {h: [float(r[i]) for r in rows[1:]] for i, h in enumerate(head)}
    return cols


def window(t, ys, t0, t1):
    idx = [i for i, x in enumerate(t) if t0 <= x <= t1]
    return [t[i] for i in idx], [[y[i] for i in idx] for y in ys]


def save(fig, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".svg")
    fig.savefig(path, format="svg", bbox_inches="tight", metadata={"Date": None})
    plt.close(fig)
    print("écrit", os.path.relpath(path, ROOT))


def style(ax, xlabel, ylabel):
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.grid(True, color="#dddddd", linewidth=0.6)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)


def fig_blink(work):
    c = simulate("BasicBlink", ["mcu.GP0.v"], 4.5, 4500, work)
    fig, ax = plt.subplots(figsize=(7, 2.4))
    ax.plot(c["time"], c["mcu.GP0.v"], color=BLUE)
    style(ax, "temps (s)", "GP0 (V)")
    ax.set_title("BasicBlink : GP0 alterne 1 s allumée, 1 s éteinte", loc="left", fontsize=10)
    save(fig, "basicblink-gp0")


def fig_uart(work):
    c = simulate("Uart.Loopback", ["mcu.GP0.v"], 0.025, 25000, work)
    t, (v,) = window(c["time"], [c["mcu.GP0.v"]], 0.0035, 0.0235)
    t_ms = [x * 1e3 for x in t]
    fig, ax = plt.subplots(figsize=(8, 2.8))
    ax.plot(t_ms, v, color=BLUE)
    # Grille des bits de la première trame, calée sur son front de start.
    start = next(x for x, a, b in zip(t, v, v[1:]) if a > 1.6 >= b)
    bit = 1 / 1200
    labels = ["start"] + ["b%d" % i for i in range(8)] + ["stop"]
    for k, lab in enumerate(labels):
        x0 = (start + k * bit) * 1e3
        ax.axvline(x0, color=GREY, linewidth=0.5, linestyle=":")
        ax.text(x0 + bit * 1e3 / 2, 3.65, lab, ha="center", fontsize=7, color=GREY)
    ax.text((start + 5 * bit) * 1e3, -0.75, "'H' = 0x48, bits de poids faible en tête",
            ha="center", fontsize=8)
    ax.text((start + 15 * bit) * 1e3, -0.75, "'i' = 0x69", ha="center", fontsize=8)
    ax.set_ylim(-1.1, 4.0)
    style(ax, "temps (ms)", "GP0 = TX (V)")
    ax.set_title("Uart.Loopback : trame 8N1 de b'Hi' à 1200 bauds, tracée comme à l'oscilloscope",
                 loc="left", fontsize=10)
    save(fig, "uart-trame")


def fig_i2c(work):
    c = simulate("I2c.Echo", ["echo.SDA.v", "echo.SCL.v"], 0.00135, 27000, work)
    t, (sda, scl) = window(c["time"], [c["echo.SDA.v"], c["echo.SCL.v"]], 0.00098, 0.00125)
    t_us = [x * 1e6 for x in t]
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 3.4), sharex=True)
    a1.plot(t_us, scl, color=ORANGE)
    a2.plot(t_us, sda, color=BLUE)
    style(a1, "", "SCL (V)")
    style(a2, "temps (µs)", "SDA (V)")
    t0 = next(x for x, a, b in zip(t_us, sda, sda[1:]) if a > 1.6 >= b)
    a2.annotate("START", (t0, 0.2), (t0 - 25, 1.4), fontsize=8, arrowprops={"arrowstyle": "->"})
    # Coups d'horloge : fronts montants de SCL après le START ; un octet = 8 bits + l'acquittement.
    edges = [x for x, a, b in zip(t_us, scl, scl[1:]) if x > t0 and a < 1.6 <= b]
    names = ["adresse 0x42 + écriture", "'H'", "'e'"]
    for k, name in enumerate(names):
        if len(edges) < 9 * k + 9:
            break
        bits, ack = edges[9 * k:9 * k + 8], edges[9 * k + 8]
        a2.text((bits[0] + bits[-1]) / 2, 3.7, name, fontsize=8, ha="center")
        a2.text(ack, 3.7, "ACK", fontsize=7, ha="center", color=GREEN)
        a2.axvspan(ack - 3, ack + 3, color=GREEN, alpha=0.12, linewidth=0)
    a2.set_ylim(-0.3, 4.3)
    a1.set_title("I2c.Echo : début de writeto(0x42, b'Hello I2C') à 100 kHz, lignes en drain ouvert",
                 loc="left", fontsize=10)
    save(fig, "i2c-chronogramme")


def fig_pwm(work):
    c = simulate("Pwm.Led", ["mcu.GP0.v", "led0.p.i"], 0.03, 30000, work)
    t, (v, i) = window(c["time"], [c["mcu.GP0.v"], c["led0.p.i"]], 0.005, 0.025)
    t_ms = [x * 1e3 for x in t]
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(7, 3.2), sharex=True)
    a1.plot(t_ms, v, color=BLUE)
    a2.plot(t_ms, [x * 1e3 for x in i], color=ORANGE)
    style(a1, "", "GP0 (V)")
    style(a2, "temps (ms)", "courant LED (mA)")
    a1.set_title("Pwm.Led : PWM à 200 Hz, rapport cyclique ≈ 30 %", loc="left", fontsize=10)
    save(fig, "pwm-led")


def fig_hx711(work):
    # Première passe grossière pour trouver la lecture, puis seconde passe à 0,5 µs :
    # seuls les instants d'événement figurent sinon dans le résultat, et un front
    # enregistré au franchissement du seuil y paraît tenu à mi-hauteur.
    c = simulate("Weighing.Hx711Read", ["hx.PD_SCK.v"], 0.7, 700, work)
    first = next(x for x, a, b in zip(c["time"], c["hx.PD_SCK.v"], c["hx.PD_SCK.v"][1:])
                 if a < 1.6 <= b)
    stop = first + 500e-6
    c = simulate("Weighing.Hx711Read", ["hx.PD_SCK.v", "hx.DOUT.v"], stop, int(stop / 0.5e-6), work)
    t, sck, dout = c["time"], c["hx.PD_SCK.v"], c["hx.DOUT.v"]
    first = next(x for x, a, b in zip(t, sck, sck[1:]) if a < 1.6 <= b)
    t, (sck, dout) = window(t, [sck, dout], first - 40e-6, first + 460e-6)
    t_us = [(x - first) * 1e6 for x in t]
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 3.4), sharex=True)
    a1.plot(t_us, sck, color=ORANGE)
    a2.plot(t_us, dout, color=BLUE)
    style(a1, "", "PD_SCK (V)")
    style(a2, "temps depuis la première impulsion (µs)", "DOUT (V)")
    a2.annotate("DOUT descend : donnée prête,\nl'IRQ du driver lance la lecture", (0, 0.3), (-35, 1.2),
                fontsize=7, arrowprops={"arrowstyle": "->"})
    a2.text(200, -1.3, "bits lus, poids fort en tête : 0x068DB9 = 429 497 (1 kg, gain 128)",
            fontsize=8, ha="center")
    a2.set_ylim(-1.7, 3.8)
    a1.set_title("Hx711Read : 25 impulsions de 5 µs produites par bit-banging (gpioOpTime), "
                 "24 bits lus sur DOUT", loc="left", fontsize=10)
    save(fig, "hx711-lecture")


def fig_regulation(work):
    c = simulate("Uart.Regulation", ["plant.y", "sensor.valueOut[1]"], 1.0, 2000, work)
    fig, ax = plt.subplots(figsize=(7, 2.8))
    ax.plot(c["time"], c["plant.y"], color=BLUE, label="mesure (plant.y)")
    ax.plot(c["time"], c["sensor.valueOut[1]"], color=ORANGE, drawstyle="steps-post",
            label="commande reçue par SET (sensor.valueOut[1])")
    ax.axhline(40, color=GREY, linestyle="--", linewidth=0.8, label="consigne (SETPOINT du script)")
    style(ax, "temps (s)", "")
    ax.legend(fontsize=8, frameon=False)
    ax.set_title("Uart.Regulation : boucle fermée à travers la seule liaison série", loc="left",
                 fontsize=10)
    save(fig, "uart-regulation")


def fig_fade(work):
    c = simulate("Pwm.LedFade", ["mcu.pwmDuty[1]"], 3.0, 3000, work, "-emit_protected")
    z = simulate("Pwm.LedFade", ["mcu.GP0.v"], 1.26, 252000, work)
    fig = plt.figure(figsize=(8, 3.6))
    top = fig.add_subplot(2, 1, 1)
    top.plot(c["time"], [x * 100 for x in c["mcu.pwmDuty[1]"]], color=BLUE, drawstyle="steps-post")
    style(top, "temps (s)", "rapport cyclique (%)")
    top.set_title("Pwm.LedFade : rapport cyclique écrit par duty_u16() toutes les millisecondes, "
                  "PWM à 1 kHz", loc="left", fontsize=10)
    for k, (t0, lab) in enumerate([(0.75, "t = 0,75 s : 25 %"), (1.25, "t = 1,25 s : 75 %")]):
        ax = fig.add_subplot(2, 2, 3 + k)
        t, (v,) = window(z["time"], [z["mcu.GP0.v"]], t0, t0 + 0.003)
        ax.plot([(x - t0) * 1e3 for x in t], v, color=ORANGE)
        style(ax, "temps (ms)", "GP0 (V)" if k == 0 else "")
        ax.set_title(lab, loc="left", fontsize=9)
        top.axvline(t0, color=GREY, linestyle=":", linewidth=0.8)
    fig.tight_layout()
    save(fig, "pwm-fade")


def fig_reactivity(work):
    c = simulate("Gpio.InputReactivity", ["mcu.GP0.v", "mcu.GP1.v"], 20, 2000, work)
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(7, 3.2), sharex=True)
    a1.plot(c["time"], c["mcu.GP1.v"], color=ORANGE)
    a2.plot(c["time"], c["mcu.GP0.v"], color=BLUE)
    style(a1, "", "GP1, bouton (V)")
    style(a2, "temps (s)", "GP0, LED (V)")
    a2.text(1, 1.6, "le programme dort : sleep(3600)", fontsize=8)
    a2.annotate("réveillé par le front de GP1 :\nled.on() aussitôt", (10, 2.8), (11, 1.0), fontsize=8,
                arrowprops={"arrowstyle": "->"})
    a1.set_title("Gpio.InputReactivity : un front d'entrée interrompt un sleep() d'une heure",
                 loc="left", fontsize=10)
    save(fig, "input-reactivity")


def fig_timing(work):
    c = simulate("Gpio.Timing", ["mcu.GP0.v"], 0.2002, 400400, work)
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(8, 2.6), gridspec_kw={"width_ratios": [1, 2.4]})
    for ax, t0, t1, title in [(a1, 0.1 - 5e-6, 0.1 + 15e-6, "out.on(); out.off()"),
                              (a2, 0.2 - 10e-6, 0.2 + 115e-6, "10 × out(1); out(0)")]:
        t, (v,) = window(c["time"], [c["mcu.GP0.v"]], t0, t1)
        ax.plot([(x - t0) * 1e6 for x in t], v, color=BLUE)
        ax.set_title(title, loc="left", fontsize=9)
    style(a1, "temps (µs)", "GP0 (V)")
    style(a2, "temps (µs)", "")
    a1.text(7.5, 1.5, "5 µs", ha="center", fontsize=8)
    a2.text(62, 3.75, "20 accès = 100 µs, mesurés aussi par ticks_us()", ha="center", fontsize=8)
    a2.set_ylim(-0.3, 4.1)
    fig.suptitle("Gpio.Timing : chaque accès à une broche dure gpioOpTime = 5 µs de temps simulé",
                 x=0.01, ha="left", fontsize=10)
    fig.tight_layout()
    save(fig, "gpio-timing")


def fig_scale(work):
    c = simulate("Weighing.KitchenScale", ["totalMass.y", "hx.code"], 7, 7000, work)
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 3.8), sharex=True)
    a1.plot(c["time"], [x * 1e3 for x in c["totalMass.y"]], color=BLUE)
    a2.plot(c["time"], c["hx.code"], color=ORANGE, drawstyle="steps-post")
    style(a1, "", "masse posée (g)")
    style(a2, "temps (s)", "code du HX711")
    for ax in (a1, a2):
        ax.axvspan(3.5, 3.7, color=GREEN, alpha=0.15, linewidth=0)
    a1.text(3.6, 820, "TARE", ha="center", fontsize=8, color=GREEN)
    for x, txt in [(1.2, "« 0 g »"), (3.0, "« 350 g »"), (4.1, "« 0 g »"), (6.4, "« 250 g »")]:
        a1.text(x, 620, txt, ha="center", fontsize=8)
    a1.set_ylim(0, 900)
    a1.set_title("Weighing.KitchenScale : plateau de 200 g, bol de 350 g, tare, 250 g de farine "
                 "(entre guillemets : l'écran)", loc="left", fontsize=10)
    save(fig, "kitchen-scale")


def fig_radio(work):
    names = ["OOK", "ASK", "FSK", "BPSK"]
    c = simulate("Radio.Modulations", ["tx%s.sTx" % m for m in names] + ["txOOK.carrierOn"],
                 0.04, 16000, work)
    start = next(x for x, on in zip(c["time"], c["txOOK.carrierOn"]) if on > 0.5)
    bit = 1 / 1200
    t, ys = window(c["time"], [c["tx%s.sTx" % m] for m in names], start - bit, start + 11 * bit)
    t_ms = [x * 1e3 for x in t]
    fig, axes = plt.subplots(4, 1, figsize=(8, 6.2), sharex=True)
    labels = ["start"] + ["b%d" % i for i in range(8)] + ["stop"]
    values = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]   # 'U' = 0x55, bits de poids faible en tête
    for ax, m, y, col in zip(axes, names, ys, [BLUE, GREEN, ORANGE, "#8e5bb5"]):
        ax.plot(t_ms, y, color=col, linewidth=0.8)
        for k in range(11):
            ax.axvline((start + k * bit) * 1e3, color=GREY, linewidth=0.5, linestyle=":")
        ax.set_ylim(-1.25, 1.25)
        style(ax, "", "%s : sTx" % m)
    for k, (lab, v) in enumerate(zip(labels, values)):
        axes[0].text((start + (k + 0.5) * bit) * 1e3, 1.4, "%s\n%d" % (lab, v), ha="center",
                     fontsize=7, color=GREY)
    axes[-1].set_xlabel("temps (ms)")
    axes[0].set_title("Radio.Modulations : le caractère 'U' à 1200 bit/s, porteuse tracée à 4800 Hz\n",
                      loc="left", fontsize=10)
    save(fig, "radio-modulations")


def fig_radio_buffer(work):
    c = simulate("Radio.Overflow", ["radioA.txFill", "radioA.nDropped", "radioA.carrierOn"],
                 0.25, 25000, work)
    t_ms = [x * 1e3 for x in c["time"]]
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(8, 3.8), sharex=True)
    a1.plot(t_ms, c["radioA.txFill"], color=ORANGE, drawstyle="steps-post", label="txFill")
    a1.axhline(16, color=GREY, linewidth=0.6, linestyle="--")
    a1.text(150, 16.6, "txBufferSize = 16", fontsize=8, color=GREY)
    a1.plot(t_ms, c["radioA.nDropped"], color="#c0392b", drawstyle="steps-post", label="nDropped")
    a1.legend(loc="center right", fontsize=8, frameon=False)
    a2.plot(t_ms, c["radioA.carrierOn"], color=BLUE, drawstyle="steps-post")
    style(a1, "", "octets")
    style(a2, "temps (ms)", "carrierOn")
    a1.set_ylim(0, 21)
    a1.set_title("Radio.Overflow : 40 octets à 9600 bauds, émis à 1200 bit/s, tampon de 16 octets",
                 loc="left", fontsize=10)
    save(fig, "radio-overflow")


FIGURES = {"blink": fig_blink, "uart": fig_uart, "i2c": fig_i2c, "pwm": fig_pwm,
           "hx711": fig_hx711, "regulation": fig_regulation, "fade": fig_fade,
           "reactivity": fig_reactivity, "timing": fig_timing, "scale": fig_scale,
           "radio": fig_radio, "radio-buffer": fig_radio_buffer}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(FIGURES)
    plt.rcParams.update({"font.size": 9, "svg.fonttype": "none", "figure.facecolor": "white"})
    work = tempfile.mkdtemp(prefix="mpmcu_fig_")
    try:
        for name in wanted:
            FIGURES[name](work)
    finally:
        shutil.rmtree(work, ignore_errors=True)
