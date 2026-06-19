@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\automation\run-p1-tests.ps1" -Suite smoke %*
pause