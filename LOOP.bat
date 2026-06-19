@echo off
setlocal
cd /d "%~dp0"

echo ========================================
echo  Warmane WoW - Agent Loop
echo  Grok ^<-^> Cursor autonomous handoff
echo ========================================
echo.
echo Leave this window open. Press Ctrl+C to stop.
echo Log: Docs\grok-handoff\loop.log
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\agent-loop.ps1" %*
if errorlevel 1 (
  echo.
  echo Agent loop exited with error %errorlevel%.
  pause
)
exit /b %errorlevel%
