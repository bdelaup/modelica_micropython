# Limites et dépannage

## Limites de la version actuelle

**Environnement**

- **Windows 64 bits uniquement**, avec OpenModelica ([Installation](installation.md)).

**Microcontrôleur**

- 8 broches (`GP0`-`GP7`) et la LED embarquée, au lieu des 29 broches du Pico ; toutes peuvent servir d'entrée analogique.
- Pas de mode drain ouvert (`Pin.OPEN_DRAIN`) : seul le bus I2C pilote ses lignes ainsi. Les tirages internes (`Pin.PULL_UP`, `Pin.PULL_DOWN`) sont, eux, réellement modélisés.
- Pas de `SPI`.
- `UART` : une seule liaison, trame 8N1 uniquement, 50 à 115 200 bauds, pas d'interruption en réception.
- `I2C` : un seul bus maître, 1 kHz à 1 MHz ; `I2CTarget` : une seule cible, adresse sur 7 bits, plus de gestionnaire une fois le programme terminé.
- `Timer` : 4 minuteurs au plus, période minimale 1 ms.
- Les callbacks d'interruption (`Pin.irq()`, `Timer`) s'exécutent au prochain point de synchronisation, jamais en préemption instantanée du programme.
- Plusieurs `MCU` dans un modèle : chacun a son programme, ses modules et sa flash. Deux cartes qui se répondraient sans jamais laisser passer de temps (`gpioOpTime = 0` et deux recopies croisées) bloquent la simulation au même instant.

Détail fonction par fonction : [API, limitations](api.md#limitations-connues).

**Périphériques** : voir la fin de chaque page ([appareils série](peripheriques/uart.md), [I2C](peripheriques/i2c.md), [pesée](peripheriques/pesee.md#limites)).

## Dépannage

??? question "La compilation échoue : `'PyRuntimeImpl.c' file not found`"
    Le chemin du dossier de la bibliothèque contient un caractère accentué (par exemple un dossier `Téléchargements`). Déplacer le dossier dans un chemin sans accent, puis le recharger dans OMEdit (voir [Installation](installation.md)).

??? question "Avec OpenModelica 1.26 ou antérieur, les broches restent à 0 V"
    La simulation se termine sans erreur, mais les sorties ne bougent pas, et le bus I2C s'arrête sur `OSError: [Errno 110] ETIMEDOUT`. C'est un défaut des versions de la bibliothèque antérieures à sa correction : prendre la version la plus récente (voir [Installation](installation.md)).

??? question "La simulation s'arrête avec une erreur Python"
    Une exception non rattrapée dans le programme arrête la simulation. Le journal de simulation affiche la trace Python : chemin du fichier, numéro de ligne, ligne de code fautive, type d'erreur et message. Les résultats restent consultables jusqu'à l'instant de l'erreur.

??? question "La simulation semble figée, avec l'avertissement « the script has been running for more than 10 s of real time »"
    Le programme tourne dans une boucle qui ne rend jamais la main au circuit : ni `sleep()`, ni accès à une broche (attente sur `time.ticks_ms()`, calcul sans fin). Le temps simulé ne peut plus avancer. Ajouter un `time.sleep_ms()` dans la boucle, puis arrêter la simulation depuis OMEdit. La variante « acting for more than ... at the same simulated instant » désigne une boucle d'accès aux broches avec `gpioOpTime = 0`. Le délai se règle par `hangWarningTime` ([Le bloc MCU](mcu.md#temps-dexecution)) ; un calcul long mais légitime se termine normalement malgré l'avertissement.

??? question "Mes `print()` n'apparaissent pas"
    Ils s'affichent dans la fenêtre de sortie de la simulation d'OMEdit (et dans son journal), pas dans une console Python, précédés du temps simulé (`[t=0.250000 s] ...`). Un `print()` d'appareil série ou I2C porte en plus le nom du composant.

??? question "`OSError: [Errno 110] ETIMEDOUT` sur le bus I2C"
    Aucune résistance de tirage externe sur le bus (les tirages internes de 50 kΩ ne suffisent pas) : cocher `usePullUp` sur au moins un périphérique ([Périphériques I2C](peripheriques/i2c.md#cablage)). Autre cause possible : une ligne tenue basse par un court-circuit dans le schéma.

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
    Dans la copie de la flash créée à chaque simulation, dans le dossier `fsWorkspace` (par défaut le dossier de simulation). Son chemin s'affiche dans le journal au début et à la fin de la simulation, et l'Explorateur Windows s'ouvre dessus en fin de simulation (`fsOpenExplorer`). Un fichier que le programme n'a pas fermé l'est en fin de simulation, son contenu complet écrit sur disque.

??? question "Deux lectures successives d'une broche donnent une valeur périmée"
    Seulement avec `gpioOpTime = 0` : relire une broche juste après avoir écrit sur une autre peut renvoyer l'état d'avant l'écriture. Laisser `gpioOpTime` à sa valeur par défaut, ou intercaler un `time.sleep_us(1)`.
