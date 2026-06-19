@echo off
cd /d "%~dp0"
if exist "tools\automation\control\daemon.pid" (
  for /f %%i in (tools\automation\control\daemon.pid) do (
    tasklist /FI "PID eq %%i" 2>nul | find "%%i" >nul && (
      echo P1 Auto daemon already running PID %%i
      exit /b 0
    )
  )
)
echo Starting P1 Auto Control minimized to tray ...
start "P1 Auto Control" /MIN powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0tools\automation\automation-panel.ps1" -Minimized
exit /b 0