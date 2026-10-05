@echo off
rem Lance make_pyimports.sh avec Git Bash (cf. docs/fr/interne/outils-windows.md).
call "%~dp0gitbash.cmd" "%~dp0make_pyimports.sh" %*
exit /b %ERRORLEVEL%
