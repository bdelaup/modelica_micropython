"""Produit docs/fr/images/pico-alimentation-en.svg (page anglaise de la Pico) à partir du
schéma français pico-alimentation.svg, dessiné à la main : mêmes tracés, textes traduits
par la table T. Retoucher d'abord le schéma français, compléter la table si un texte
change, puis relancer :

    python docs/figures/make_pico_alimentation_en.py
"""
import os
import sys

IMAGES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "fr", "images")
src = os.path.join(IMAGES, "pico-alimentation.svg")
dst = os.path.join(IMAGES, "pico-alimentation-en.svg")
s = open(src, encoding='utf-8').read()
T = [
    ("Raspberry Pi Pico (RPi_Pico) : arbre d'alimentation", "Raspberry Pi Pico (RPi_Pico): power supply tree"),
    (">Câble USB<", ">USB cable<"),
    (">0,2 Ω<", ">0.2 Ω<"),
    (">ou : 5 V externe<", ">or: external 5 V<"),
    (">sur VBUS<", ">on VBUS<"),
    (">ou : pile(s) sur VSYS<", ">or: cell(s) on VSYS<"),
    (">Schottky ≈ 0,3 V<", ">Schottky ≈ 0.3 V<"),
    (">Régulateur buck-boost<", ">Buck-boost regulator<"),
    (">RT6150, modèle moyen<", ">RT6150, averaged model<"),
    (">VSYS 1,8 à 5,5 V → 3,3 V<", ">VSYS 1.8 to 5.5 V → 3.3 V<"),
    (">rendement η = 0,9<", ">efficiency η = 0.9<"),
    (">vers les périphériques<", ">to the peripherals<"),
    (">(leur broche VCC, useSupplyPin)<", ">(their VCC pin, useSupplyPin)<"),
    (">rail 3,3 V : pico.vRail<", ">3.3 V rail: pico.vRail<"),
    (">vers vref : référence<", ">to vref: reference<"),
    (">de l'ADC<", ">of the ADC<"),
    (">vdd : consommation ICore<", ">vdd: consumption ICore<"),
    (">(20 mA, programme en marche)<", ">(20 mA, program running)<"),
    (">sorties GPx : niveau haut<", ">GPx outputs: high level<"),
    (">= rail, courant pris sur le rail<", ">= rail, current from the rail<"),
    (">démarre : rail &gt; 1,8 V et RUN haut<", ">starts: rail &gt; 1.8 V and RUN high<"),
    (">arrêt définitif : rail &lt; 1,6 V<", ">stops for good: rail &lt; 1.6 V<"),
    (">ou RUN à la masse<", ">or RUN grounded<"),
    (">vref (gauche) · run (bas)<", ">vref (left) · run (bottom)<"),
    (">tirage interne 50 kΩ<", ">pull-up 50 kΩ<"),
    (">5,6 kΩ<", ">5.6 kΩ<"),
    (">USB présent ?<", ">USB present?<"),
    (">GP24 : Pin(24)<", ">GP24: Pin(24)<"),
    (">lit VSYS / 3<", ">reads VSYS / 3<"),
    (">à la masse : régulateur arrêté<", ">grounded: regulator off<"),
    (">Courant tiré de VSYS : I = P(rail) / (η · V(VSYS)) + courant de repos du régulateur  (pico.iSys)<",
     ">Current drawn from VSYS: I = P(rail) / (η · V(VSYS)) + quiescent current of the regulator  (pico.iSys)<"),
    (">Deux piles AA (3 V), programme seul : 20 mA × 3,3 V / (0,9 × 3 V) ≈ 24,5 mA ; chaque LED allumée en ajoute.<",
     ">Two AA cells (3 V), program alone: 20 mA × 3.3 V / (0.9 × 3 V) ≈ 24.5 mA; each lit LED adds to it.<"),
    (">rail 3,3 V<", ">3.3 V rail<"),
    (">mesures<", ">sensing<"),
    (">commandes<", ">control<"),
    (">masse<", ">ground<"),
    ("Schéma de principe de l'alimentation de RPi_Pico, dessiné à la main d'après make_pico.py.",
     "Block diagram of the power supply of RPi_Pico, drawn by hand after make_pico.py (English version of pico-alimentation.svg)."),
    ("Couleurs des réseaux identiques au schéma interne d'OMEdit.", "Net colours identical to the internal diagram in OMEdit."),
]
for fr, en in T:
    n = s.count(fr)
    if n == 0:
        sys.exit('absent: ' + fr)
    s = s.replace(fr, en)
open(dst, 'w', encoding='utf-8').write(s)
print('écrit', os.path.relpath(dst))
