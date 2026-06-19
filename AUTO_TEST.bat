@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\automation\run-autonomous.ps1" -Suite smoke -MaxCycles 5 %*
exit /b %errorlevel%