@echo off
rem Lance make_docs.sh avec Git Bash (cf. docs/fr/interne/outils-windows.md).
call "%~dp0gitbash.cmd" "%~dp0make_docs.sh" %*
exit /b %ERRORLEVEL%
