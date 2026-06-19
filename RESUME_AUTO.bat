@echo off
cd /d "%~dp0"
del "tools\automation\control\PAUSED" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\automation\harness-control.ps1" -Action resume
echo Automation resumed.
exit /b 0