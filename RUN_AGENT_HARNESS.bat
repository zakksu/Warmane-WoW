@echo off
cd /d "%~dp0"
echo P1 Agent Harness - WoW must be open, druid toon, windowed mode
echo Report: tools\automation\reports\harness-latest.json
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\automation\run-agent-harness.ps1" -Suite smoke -UntilPass -MaxAttempts 3 -Reload %*
if errorlevel 1 (
  echo.
  echo Harness failed. Open harness-latest.json and screenshots in tools\automation\reports\
)
pause