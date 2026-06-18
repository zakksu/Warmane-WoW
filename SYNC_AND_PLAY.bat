@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo ========================================
echo  Phase One — SYNC_AND_PLAY
echo ========================================
echo.

call "%~dp0tools\find-warmane-path.bat"
if not defined WOWPATH (
  echo ERROR: WoW path not configured or Wow.exe missing.
  echo Run tools\set-wow-path.bat and try again.
  pause
  exit /b 1
)
echo Using WoW path:
echo   !WOWPATH!
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo git not found — skipping pull.
) else (
  echo Pulling latest from origin/main...
  git pull origin main 2>nul
  if errorlevel 1 (
    echo git pull skipped or failed — continuing with local files.
  )
)
echo.

set "SYNC_FLAG="
if /I "%~1"=="/FULL" set "SYNC_FLAG=-Full"
if /I "%~1"=="FULL" set "SYNC_FLAG=-Full"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\sync-addons.ps1" -WowPath "!WOWPATH!" !SYNC_FLAG!
if errorlevel 1 (
  echo ERROR: addon sync failed.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\write-addons-txt.ps1" -WowPath "!WOWPATH!"
if errorlevel 1 (
  echo ERROR: AddOns.txt update failed.
  pause
  exit /b 1
)

echo.
echo ========================================
echo  Done! In game: /reload
echo ========================================
echo.
pause
exit /b 0
