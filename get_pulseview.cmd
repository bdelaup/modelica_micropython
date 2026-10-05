@echo off
rem Telecharge la copie portable de PulseView (logiciel libre du projet
rem sigrok, GPLv3) dans le dossier PulseView\ pose a cote de la bibliotheque,
rem la ou la sonde Peripherals.Analyzers.LogicAnalyzer la cherche d'elle-meme
rem (pulseViewPath vide). Rien a installer, aucun droit administrateur : un
rem double-clic suffit. Voir docs/fr/guide/peripheriques/analyseurs.md.
rem
rem Le zip n'est pas dans le depot git : il est publie a part, dans le
rem registre de paquets du projet GitLab, par make_pulseview_zip.sh, qui
rem reecrit aussi les lignes PV_VERSION et PV_SHA256 ci-dessous.
rem
rem Outils fournis avec Windows 10 (1803) et 11 : curl.exe pour telecharger,
rem certutil pour verifier l'empreinte SHA-256, tar.exe pour decompresser.
rem Pas de bloc entre parentheses affichant un chemin : un chemin qui en
rem contient une (Program Files (x86)) fermerait le bloc, d'ou les goto.
rem Messages en ASCII : cmd.exe lit ce fichier dans la page de codes OEM.
setlocal EnableExtensions

set "PV_VERSION=0.5.0-e2fe9df-20261005"
set "PV_SHA256=8340418ea49fdf21236e459c274edcf1a16e1c8dfbfa62917ae61b3c70c9c966"
set "PV_FILE=pulseview-%PV_VERSION%-win64-portable.zip"
set "PV_URL=https://gitlab.com/api/v4/projects/bdelaup%%2Fmodelica_micropython3/packages/generic/pulseview/%PV_VERSION%/%PV_FILE%"

set "DEST=%~dp0PulseView"
set "PART=%~dp0PulseView.part"
set "ZIP=%TEMP%\%PV_FILE%"
set "CURL=%SystemRoot%\System32\curl.exe"
set "TAR=%SystemRoot%\System32\tar.exe"
set "RC=1"

if exist "%DEST%\pulseview.exe" goto :already
if not exist "%CURL%" goto :old_windows
if not exist "%TAR%" goto :old_windows

echo Telechargement de PulseView %PV_VERSION%, environ 25 Mo...
"%CURL%" --fail --location --progress-bar --output "%ZIP%" "%PV_URL%"
if errorlevel 1 goto :download_failed

rem certutil : empreinte sur la 2e ligne (octets separes par des espaces
rem sur les Windows anciens, d'ou leur retrait).
set "GOT="
for /f "skip=1 delims=" %%H in ('certutil -hashfile "%ZIP%" SHA256') do if not defined GOT set "GOT=%%H"
if defined GOT set "GOT=%GOT: =%"
if /i not "%GOT%"=="%PV_SHA256%" goto :bad_hash

rem Decompression a cote de la destination (meme disque, pour un simple
rem deplacement), puis deplacement : un PulseView\ a moitie extrait ne passe
rem jamais pour une copie complete.
if exist "%PART%" rmdir /s /q "%PART%"
mkdir "%PART%"
"%TAR%" -xf "%ZIP%" -C "%PART%"
if errorlevel 1 goto :extract_failed
if not exist "%PART%\PulseView\pulseview.exe" goto :extract_failed
if exist "%DEST%" rmdir /s /q "%DEST%"
move "%PART%\PulseView" "%DEST%" >nul
if errorlevel 1 goto :move_failed
echo PulseView %PV_VERSION% installe dans %DEST%
echo La sonde LogicAnalyzer le trouvera d'elle-meme, avec openPulseView = true.
set "RC=0"
goto :cleanup

:already
echo PulseView est deja la : %DEST%
echo Pour le remplacer, supprimer ce dossier puis relancer ce script.
set "RC=0"
goto :end

:old_windows
echo curl.exe ou tar.exe introuvable dans %SystemRoot%\System32 : il faut
echo Windows 10 version 1803 ou plus recent. Sinon, telecharger a la main
echo %PV_URL%
echo et decompresser le zip a cote du dossier MicroPythonMCU.
goto :end

:download_failed
echo Echec du telechargement : %PV_URL%
goto :cleanup

:bad_hash
echo Fichier telecharge corrompu ou inattendu :
echo   empreinte SHA-256 obtenue  %GOT%
echo   empreinte SHA-256 attendue %PV_SHA256%
goto :cleanup

:extract_failed
echo Echec de la decompression de %ZIP%
echo L'archive doit contenir PulseView\pulseview.exe.
goto :cleanup

:move_failed
echo Impossible de creer %DEST%
goto :cleanup

:cleanup
if exist "%PART%" rmdir /s /q "%PART%"
if exist "%ZIP%" del "%ZIP%"

:end
rem Double-clic : l'Explorateur lance cmd /c ""<fichier>.cmd" ", dont la ligne
rem sans guillemets finit par une espace ; PowerShell et cmd, non.
set "CL=%cmdcmdline:"=%"
if "%CL:~-1%"==" " pause
exit /b %RC%
