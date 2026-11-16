@echo off
rem Lance les tests Linux dans Docker (cf. docs/fr/interne/outils-windows.md).
call "%~dp0gitbash.cmd" "%~dp0run_tests_docker_linux.sh" %*
exit /b %ERRORLEVEL%
