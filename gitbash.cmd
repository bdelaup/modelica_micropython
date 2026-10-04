@echo off
rem Lance un script bash du depot avec le bash de Git for Windows, depuis
rem PowerShell, cmd ou l'Explorateur (double-clic) :
rem
rem   gitbash.cmd <script.sh> [arguments...]
rem
rem Les lanceurs run_tests.cmd, make_docs.cmd, make_pyimports.cmd et
rem make_debugpy.cmd l'appellent. Voir docs/fr/interne/outils-windows.md.
rem
rem - Jamais le bash.exe du PATH : dans PowerShell, c'est celui de WSL, qui
rem   n'a ni omc ni le toolchain MinGW d'OpenModelica.
rem - Chemin du script en barres obliques : sur un chemin a antislashs,
rem   dirname "$0" rend "." et les scripts ne retrouvent plus leur dossier.
rem - OPENMODELICAHOME vide mais omc dans le PATH : deduit de omc, pour cet
rem   appel seulement.
rem - Console en UTF-8 le temps du script (messages accentues), page de codes
rem   d'origine remise ensuite.
rem - Lance par double-clic : pause a la fin, pour lire le recapitulatif.
rem Messages en ASCII : cmd.exe lit ce fichier dans la page de codes OEM.
setlocal EnableExtensions

if "%~1"=="" (
  echo usage: gitbash.cmd script.sh [arguments...]
  set "RC=2"
  goto :end
)
if not exist "%~f1" (
  echo Script introuvable : %~f1
  set "RC=2"
  goto :end
)

rem Git Bash : a cote du git.exe du PATH (<Git>\cmd ou <Git>\mingw64\bin),
rem sinon aux emplacements d'installation habituels.
set "GITBASH="
for /f "delims=" %%G in ('where git 2^>nul') do (
  if not defined GITBASH if exist "%%~dpG..\bin\bash.exe" set "GITBASH=%%~dpG..\bin\bash.exe"
  if not defined GITBASH if exist "%%~dpG..\..\bin\bash.exe" set "GITBASH=%%~dpG..\..\bin\bash.exe"
)
for %%P in ("%ProgramFiles%" "%ProgramW6432%" "%LOCALAPPDATA%\Programs") do (
  if not defined GITBASH if exist "%%~P\Git\bin\bash.exe" set "GITBASH=%%~P\Git\bin\bash.exe"
)
if not defined GITBASH (
  echo Git Bash introuvable : installer Git for Windows, https://git-scm.com/download/win
  set "RC=2"
  goto :end
)

if not defined OPENMODELICAHOME (
  for /f "delims=" %%O in ('where omc 2^>nul') do (
    if not defined OPENMODELICAHOME for %%R in ("%%~dpO..") do set "OPENMODELICAHOME=%%~fR"
  )
)

set "SCRIPT=%~f1"
set "SCRIPT=%SCRIPT:\=/%"
set "ARGS="
:collect
shift
if "%~1"=="" goto :run
set ARGS=%ARGS% %1
goto :collect

:run
set "OLDCP="
for /f "tokens=2 delims=:" %%C in ('chcp') do set "OLDCP=%%C"
if defined OLDCP set "OLDCP=%OLDCP: =%"
if defined OLDCP set "OLDCP=%OLDCP:.=%"
chcp 65001 >nul
"%GITBASH%" "%SCRIPT%"%ARGS%
set "RC=%ERRORLEVEL%"
if defined OLDCP chcp %OLDCP% >nul

:end
rem Double-clic : l'Explorateur lance cmd /c ""<fichier>.cmd" ", dont la ligne
rem sans guillemets finit par une espace ; PowerShell et cmd, non.
set "CL=%cmdcmdline:"=%"
if "%CL:~-1%"==" " pause
exit /b %RC%
