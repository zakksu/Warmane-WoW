@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0set-wow-login.ps1"
exit /b %errorlevel%