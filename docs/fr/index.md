# MicroPythonMCU

**Un microcontrôleur programmable en Python, à poser dans un schéma OpenModelica.**

`MicroPythonMCU` est une bibliothèque [OpenModelica](https://openmodelica.org/) dont le bloc `MCU` exécute un vrai script Python, écrit avec l'API [MicroPython](https://micropython.org/) (`machine`, `time`), celle du Raspberry Pi Pico. Ses broches sont de vrais nœuds électriques : le script pilote et mesure le circuit Modelica qui l'entoure. On met ainsi au point un programme embarqué sur le jumeau numérique d'un système, avant de le téléverser sur la carte réelle.

![Le modèle BasicBlink en cours de simulation : la LED clignote](images/BasicBlink.gif){ width="320" }

<div class="grid cards" markdown>

-   **Guide utilisateur**

    ---

    Installer la bibliothèque, simuler un premier exemple, écrire son propre programme et brancher des périphériques. Aucune connaissance du fonctionnement interne n'est nécessaire.

    [Premiers pas](guide/premiers-pas.md) · [Le bloc MCU](guide/mcu.md) · [API](guide/api.md) · [Exemples](guide/exemples.md)

-   **Référence interne**

    ---

    Pour qui fait évoluer la bibliothèque : architecture, intégration de CPython, protocole de synchronisation avec le solveur, moteurs série et I2C, suite de vérification, livraisons.

    [Architecture](interne/architecture.md) · [Cycle de vie](interne/cycle-de-vie.md) · [Tests](interne/tests.md)

</div>

## Ce que sait faire le microcontrôleur

| Fonction | API côté script | Détails |
|---|---|---|
| Entrées / sorties numériques, interruptions, *bit-banging* | `Pin`, `Pin.irq()` | [API](guide/api.md#machinepin) |
| Entrée analogique, sortie PWM | `ADC`, `PWM` | [API](guide/api.md#machineadc) |
| Minuteurs, attentes | `Timer`, `time.sleep()` | [API](guide/api.md#machinetimer) |
| Liaison série électrique | `UART` | [Appareils série](guide/peripheriques/uart.md) |
| Bus I2C maître en drain ouvert | `I2C` | [Périphériques I2C](guide/peripheriques/i2c.md) |
| Système de fichiers façon flash, `boot.py` / `main.py` | `open()`, `os` | [API](guide/api.md#systeme-de-fichiers-open-et-os) |
| Import de modules, drivers du commerce | `import` | [Le bloc MCU](guide/mcu.md#script-python) |

Un `time.sleep(1)` ne coûte aucun temps réel : le solveur avance directement à l'échéance. Une heure simulée s'exécute en une fraction de seconde.

## Périphériques fournis

LED, afficheur pédagogique, appareils série (écho, capteur de température, GPS, afficheur 20x2, appareil générique), périphériques I2C (écran Grove LCD RGB, écho, périphérique générique) et une chaîne de pesée complète (corps d'épreuve, pont de jauges, convertisseur HX711). Les 38 [exemples](guide/exemples.md) les mettent tous en œuvre, jusqu'à une balance de cuisine qui exécute sans modification des drivers MicroPython du commerce.

## Limites actuelles

Windows uniquement, pas de SPI. Un modèle peut contenir plusieurs microcontrôleurs, qui dialoguent par leurs broches, une liaison série ou un bus I2C. Liste complète : [Limites et dépannage](guide/limites.md).

## Contexte

Bibliothèque conçue par Benoit Delaup, professeur de sciences de l'ingénieur, pour que des élèves testent leur code de pilotage sur le système numérique avant de le déployer sur un prototype réel, et utilisable pour un jumeau numérique de logiciel embarqué dans un cadre industriel. Code source et suivi : [dépôt GitLab](https://gitlab.com/bdelaup/modelica_micropython3). Les choix d'architecture et leurs alternatives sont consignés dans [`requirements.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md).
