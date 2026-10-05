@echo off
rem Lance make_pulseview_zip.sh avec Git Bash (cf. docs/fr/interne/outils-windows.md).
call "%~dp0gitbash.cmd" "%~dp0make_pulseview_zip.sh" %*
exit /b %ERRORLEVEL%
