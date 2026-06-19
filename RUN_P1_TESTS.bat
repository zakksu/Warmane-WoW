@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\automation\run-autonomous.ps1" -Suite smoke -MaxCycles 3 %*
exit /b %errorlevel%