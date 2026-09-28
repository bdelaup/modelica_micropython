# Limites et dépannage

## Limites de la version actuelle

**Environnement**

- **Windows 64 bits uniquement**, avec OpenModelica ([Installation](installation.md)).
- **Un seul `MCU` par modèle.** Les appareils série et I2C, même programmés en Python, peuvent être aussi nombreux que nécessaire.

**Microcontrôleur**

- 8 broches (`GP0`-`GP7`) et la LED embarquée, au lieu des 29 broches du Pico ; toutes peuvent servir d'entrée analogique.
- `Pin.PULL_UP` / `Pin.PULL_DOWN` sont acceptés mais sans effet électrique : mettre une vraie résistance de tirage dans le schéma.
- Pas de `SPI`.
- `UART` : une seule liaison, trame 8N1 uniquement, 50 à 115 200 bauds, pas d'interruption en réception.
- `I2C` : maître uniquement, un seul bus, 1 kHz à 1 MHz.
- `Timer` : 4 minuteurs au plus, période minimale 1 ms.
- Les callbacks d'interruption (`Pin.irq()`, `Timer`) s'exécutent au prochain point de synchronisation, jamais en préemption instantanée du programme.

Détail fonction par fonction : [API, limitations](api.md#limitations-connues-v0).

**Périphériques** : voir la fin de chaque page ([appareils série](peripheriques/uart.md), [I2C](peripheriques/i2c.md), [pesée](peripheriques/pesee.md#limites)).

## Dépannage

??? question "La simulation s'arrête avec une erreur Python"
    Une exception non rattrapée dans le programme arrête la simulation. Le journal de simulation affiche la trace Python : fichier, numéro de ligne, type d'erreur et message. Les résultats restent consultables jusqu'à l'instant de l'erreur.

??? question "Mes `print()` n'apparaissent pas"
    Ils s'affichent dans la fenêtre de sortie de la simulation d'OMEdit (et dans son journal), pas dans une console Python. Un `print()` d'appareil série ou I2C est préfixé du nom du composant.

??? question "`OSError: [Errno 110] ETIMEDOUT` sur le bus I2C"
    Aucune résistance de tirage sur le bus : cocher `usePullUp` sur au moins un périphérique ([Périphériques I2C](peripheriques/i2c.md#cablage)). Autre cause possible : une ligne tenue basse par un court-circuit dans le schéma.

??? question "`OSError: [Errno 5] EIO` sur le bus I2C"
    Aucun périphérique ne répond à l'adresse demandée. Vérifier le paramètre `addresses` du périphérique et lancer `i2c.scan()`.

??? question "Les octets reçus sur la liaison série sont faux"
    Le `baudrate` de l'appareil diffère de celui passé à `UART(...)` dans le programme. Les deux doivent être identiques, comme sur un vrai montage.

??? question "Le programme ne voit pas les données reçues par la liaison série"
    La réception ne réveille pas le programme : il doit interroger la liaison (`uart.any()`, `uart.read()`, `uart.readline()`) et laisser le temps à la réponse d'arriver, par exemple avec un `time.sleep_ms()`.

??? question "Relier deux broches du même `MCU` par un fil fait disparaître le signal"
    Un `connect()` direct entre deux broches du même microcontrôleur fusionne les deux nœuds, et la tension pilotée disparaît des résultats. Passer par une résistance de 1 kΩ, avec un condensateur de 1 nF vers la masse ([Appareils série](peripheriques/uart.md#boucler-la-liaison-sur-le-microcontroleur-lui-meme)).

??? question "Message « Chattering detected » dans le journal"
    Information bénigne d'OpenModelica : beaucoup d'événements dans un seul pas de sortie, typiquement sur un bus I2C. Réduire l'intervalle de sortie (*Interval*) le fait disparaître ; les résultats sont justes dans les deux cas.

??? question "La simulation est lente"
    Chaque front sur une broche est un événement pour le solveur. Une liaison série rapide, un bus I2C, une attente active (`while not bouton(): pass`, un événement par accès à la broche) ou un `sleep_ms(1)` en boucle en produisent beaucoup. Préférer `time.sleep()` ou `Pin.irq()` à l'attente active, et ne simuler que la durée utile.

??? question "`open()` lève `OSError: [Errno 19] ENODEV`"
    Le système de fichiers n'est pas activé : cocher `fsEnabled` dans l'onglet *File system* du `MCU` ([Le bloc MCU](mcu.md#systeme-de-fichiers)).

??? question "Où sont les fichiers écrits par mon programme ?"
    Dans la copie de la flash créée à chaque simulation, dans le dossier `fsWorkspace` (par défaut le dossier de simulation). Son chemin s'affiche dans le journal au début et à la fin de la simulation, et l'Explorateur Windows s'ouvre dessus en fin de simulation (`fsOpenExplorer`).

??? question "Deux lectures successives d'une broche donnent une valeur périmée"
    Seulement avec `gpioOpTime = 0` : relire une broche juste après avoir écrit sur une autre peut renvoyer l'état d'avant l'écriture. Laisser `gpioOpTime` à sa valeur par défaut, ou intercaler un `time.sleep_us(1)`.
