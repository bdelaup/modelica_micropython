# Exemples

Le paquetage `MicroPythonMCU.Examples` contient 31 modèles prêts à simuler : ouvrir le modèle, simuler, tracer les grandeurs indiquées. Chacun exécute le programme nommé dans la colonne « Programme », à lire en parallèle : dans [`Resources/Scripts/MCU/`](https://gitlab.com/bdelaup/modelica_micropython3/-/tree/main/MicroPythonMCU/Resources/Scripts/MCU), ou dans [`Resources/Verification/`](https://gitlab.com/bdelaup/modelica_micropython3/-/tree/main/MicroPythonMCU/Resources/Verification) pour ceux marqués *(V)*. Les exemples servent aussi de scénarios à la suite de vérification de la bibliothèque.

<!-- ILLUSTRATION exemples-vignettes : une vignette (vue Diagramme) par exemple phare : BasicBlink, Gpio.LedChaser, Pwm.LedFade, Uart.Sensor, I2c.GroveLcd, Weighing.KitchenScale (cf. docs/ILLUSTRATIONS.md) -->

## Pour commencer

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `BasicBlink` | Le programme par défaut : `GP0` et la LED embarquée clignotent à 0,5 Hz | `mcu.GP0.v`, icônes des LED | `demo.py` |

## Broches numériques (`Examples.Gpio`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `Gpio.LedChaser` | Chenillard sur 8 LED disposées autour du microcontrôleur | icônes des LED (relecture animée) | `led_chaser.py` |
| `Gpio.PinEcho` | `GP1` oscille, `GP2` relit son état électrique, `GP3` le recopie | `mcu.GP1.v`, `mcu.GP3.v` | `pin_echo.py` |
| `Gpio.InputReactivity` | Un bouton sur `GP1` réveille le programme pendant un `sleep(3600)` | `mcu.GP1.v`, sortie du programme | `input_reactive.py` *(V)* |
| `Gpio.Timing` | Coût d'un accès aux broches (`gpioOpTime`) : impulsion `on()`/`off()` sans `sleep`, rafale, attente active, IRQ masquée | `mcu.GP0.v` (zoom à la µs) | `gpio_timing.py` *(V)* |

## Entrées analogiques (`Examples.Adc`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `Adc.Read` | `GP1` en entrée analogique sur un pont diviseur (≈ 2,2 V) ; seuil recopié sur une LED | `mcu.GP1.v`, `mcu.GP0.v` | `adc_read.py` |
| `Adc.Sleep` | Une entrée analogique qui traverse le seuil logique ne réveille pas le programme | `mcu.GP0.v`, `mcu.GP1.v` | `adc_sleep.py` |

## PWM (`Examples.Pwm`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `Pwm.Led` | PWM à 200 Hz, rapport cyclique ≈ 30 % | `mcu.GP0.v`, `led0.p.i` | `pwm_led.py` |
| `Pwm.LedFade` | Variation progressive du rapport cyclique : la LED s'allume en fondu | icône de la LED, `led0.p.i` | `pwm_led_fade.py` |

![PWM à 200 Hz](../images/sim/pwm-led.svg)

## Interruptions et minuteurs (`Examples.Irq`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `Irq.Pin` | `Pin.irq()` sur front montant seulement : la LED bascule à chaque front montant du créneau | `mcu.GP1.v`, `mcu.GP0.v` | `pin_irq_demo.py` *(V)* |
| `Irq.Timer` | Un `Timer` périodique de 500 ms bascule une LED pendant que le programme dort | `mcu.GP0.v` | `timer_toggle.py` *(V)* |

## Exécution du programme (`Examples.Program`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `Program.SleepCompression` | Deux `sleep(3600)` simulés en une fraction de seconde de calcul | durée de la simulation | `sleep_long.py` *(V)* |
| `Program.Error` | Une exception non rattrapée arrête la simulation, trace Python dans le journal | journal | `script_error.py` *(V)* |
| `Program.Imports` | Import d'un module posé à côté du programme et d'une bibliothèque d'un autre dossier (`libraryPath`) | LED de `GP0` et `GP1` | `import_demo.py` |

## Système de fichiers (`Examples.FileSystem`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `FileSystem.Boot` | Sans script : `boot.py` puis `main.py` d'une image de flash ; mesures de l'ADC enregistrées dans `/data/measurements.csv` | dossier de la copie (ouvert en fin de simulation) | image `datalogger/` |
| `FileSystem.Script` | `boot.py` de la flash, puis un programme externe à la place de `main.py` | journal, fichiers écrits | `fs_script.py` |

## Afficheur pédagogique (`Examples.Display`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `Display.Demo` | Deux messages envoyés à un `Peripherals.Display` ; le premier descend en ligne 2 | icône de l'afficheur, journal | `display_demo.py` |

## Liaison série (`Examples.Uart`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `Uart.Loopback` | Trame 8N1 bouclée sur le microcontrôleur | `mcu.GP0.v` | `uart_loopback.py` |
| `Uart.EchoPy` | Dialogue avec un appareil d'écho décrit par un script Python | `mcu.GP5.v`, `mcu.GP4.v`, journal | `uart_echo.py` |
| `Uart.Echo` | Même montage, écho réglé dans la table de l'appareil | idem | `uart_echo.py` |
| `Uart.Sensor` | Interrogation d'un capteur de température, puis envoi d'une consigne | `sensor.valueOut[1]`, journal | `uart_sensor.py` |
| `Uart.Regulation` | Régulation en boucle fermée à travers la seule liaison série | `plant.y`, `sensor.valueOut[1]` | `uart_regulation.py` |
| `Uart.GpsPy` | Un module GPS émet ses trames sans être interrogé | journal | `uart_gps.py` |
| `Uart.StateMachinePy` | Appareil dont la réponse dépend de son historique (machine d'état Python) | journal | `uart_state_machine.py` |
| `Uart.Lcd` | Deux lignes écrites sur un afficheur série 20x2 | icône de l'afficheur | `uart_lcd.py` |

![Trame série](../images/sim/uart-trame.svg)

## Bus I2C (`Examples.I2c`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `I2c.Echo` | Écriture et relecture d'une trame, lecture d'un registre derrière un START répété | `echo.SDA.v`, `echo.SCL.v` | `i2c_echo.py` |
| `I2c.MultiDevice` | Trois périphériques sur un bus à 400 kHz, trouvés par `scan()` | journal | `i2c_multi.py` |
| `I2c.NoPullUp` | Bus sans résistances de tirage : `OSError(ETIMEDOUT)` | lignes à 0 V, journal | `i2c_nopullup.py` |
| `I2c.GroveLcd` | Écran Grove LCD RGB piloté par un driver du commerce non modifié | icône de l'écran | `i2c_grove_lcd_rgb.py` |

## Pesée (`Examples.Weighing`)

| Exemple | Ce qu'il montre | À observer | Programme |
|---|---|---|---|
| `Weighing.Hx711Read` | Lecture d'un HX711 par le driver de robert-hh : gain 128, gain 64, veille et réveil | `hx.code`, `hx.PD_SCK.v`, `hx.DOUT.v`, afficheur | `hx711_read.py` |
| `Weighing.KitchenScale` | Balance de cuisine complète, bouton TARE | icône de l'écran | `kitchen_scale.py` |

<!-- ILLUSTRATION kitchen-scale-gif : animation GIF de la balance (écran Grove qui affiche 0 g, 350 g, Tare..., 250 g) (cf. docs/ILLUSTRATIONS.md) -->
