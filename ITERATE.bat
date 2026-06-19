@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\automation\run-iterate.ps1" -MaxIterations 50 %*
exit /b %errorlevel%