@echo off
cd /d "%~dp0"
if not exist "tools\automation\control" mkdir "tools\automation\control"
powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'tools\automation\control' | Out-Null; Set-Content -Path 'tools\automation\control\PAUSED' -Value (Get-Date -Format o) -NoNewline"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . '%~dp0tools\automation\harness-control.ps1'; Set-HarnessControlPaused -Reason 'STOP_AUTO.bat killswitch' }" 2>nul
echo.
echo  P1 automation PAUSED — safe to play WoW.
echo  Agents and file-watch will skip until you run RESUME_AUTO.bat
echo.
exit /b 0