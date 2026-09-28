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


def simulate(model, variables, stop, intervals, work):
    """Simule MicroPythonMCU.Examples.<model>, rend {variable: [valeurs]} et le temps."""
    prefix = model.replace(".", "_")
    regex = "|".join(v.replace("[", "\\\\[").replace("]", "\\\\]") for v in variables)
    mos = os.path.join(work, prefix + ".mos")
    with open(mos, "w", encoding="utf-8") as f:
        f.write('loadModel(Modelica); getErrorString();\n')
        f.write('loadFile("%s"); getErrorString();\n' % PACKAGE)
        f.write('r := simulate(MicroPythonMCU.Examples.%s, stopTime=%g, numberOfIntervals=%d, '
                'outputFormat="csv", variableFilter="time|%s", fileNamePrefix="%s"); getErrorString();\n'
                % (model, stop, intervals, regex, prefix))
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
    a2.annotate("DOUT descend : donnée prête,
l'IRQ du driver lance la lecture", (0, 0.3), (-35, 1.2),
                fontsize=7, arrowprops={"arrowstyle": "->"})
    a2.text(200, -1.3, "bits lus, poids fort en tête : 0x068DB9 = 429 497 (1 kg, gain 128)",
            fontsize=8, ha="center")
    a2.set_ylim(-1.7, 3.8)
    a1.set_title("Hx711Read : 25 impulsions de 5 µs produites par bit-banging (gpioOpTime), "
                 "24 bits lus sur DOUT", loc="left", fontsize=10)
    save(fig, "hx711-lecture")


def fig_regulation(work):
    c = simulate("Uart.Regulation", ["procede.y", "capteur.valueOut[1]"], 1.0, 2000, work)
    fig, ax = plt.subplots(figsize=(7, 2.8))
    ax.plot(c["time"], c["procede.y"], color=BLUE, label="mesure (procede.y)")
    ax.plot(c["time"], c["capteur.valueOut[1]"], color=ORANGE, drawstyle="steps-post",
            label="commande reçue par SET (capteur.valueOut[1])")
    ax.axhline(40, color=GREY, linestyle="--", linewidth=0.8, label="consigne (CONSIGNE du script)")
    style(ax, "temps (s)", "")
    ax.legend(fontsize=8, frameon=False)
    ax.set_title("Uart.Regulation : boucle fermée à travers la seule liaison série", loc="left",
                 fontsize=10)
    save(fig, "uart-regulation")


FIGURES = {"blink": fig_blink, "uart": fig_uart, "i2c": fig_i2c, "pwm": fig_pwm,
           "hx711": fig_hx711, "regulation": fig_regulation}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(FIGURES)
    plt.rcParams.update({"font.size": 9, "svg.fonttype": "none", "figure.facecolor": "white"})
    work = tempfile.mkdtemp(prefix="mpmcu_fig_")
    try:
        for name in wanted:
            FIGURES[name](work)
    finally:
        shutil.rmtree(work, ignore_errors=True)
