@echo off
rem Lance run_tests.sh avec Git Bash (cf. docs/fr/interne/outils-windows.md).
call "%~dp0gitbash.cmd" "%~dp0MicroPythonMCU\Resources\Verification\run_tests.sh" %*
exit /b %ERRORLEVEL%
