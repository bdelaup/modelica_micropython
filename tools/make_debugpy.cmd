@echo off
rem Lance make_debugpy.sh avec Git Bash (cf. docs/fr/interne/outils-windows.md).
call "%~dp0gitbash.cmd" "%~dp0make_debugpy.sh" %*
exit /b %ERRORLEVEL%
