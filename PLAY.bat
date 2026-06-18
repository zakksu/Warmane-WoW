@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo ========================================
echo  Phase One Quest Pack - PLAY
echo ========================================
echo.

where git >nul 2>&1
if not errorlevel 1 (
  git pull origin main >nul 2>&1
)

call "%~dp0tools\find-warmane-path.bat"
if not defined WOWPATH (
  echo Warmane folder not saved yet - paste it once ^(must contain Wow.exe^):
  echo.
  set /p WOWPATH="WoW folder: "
  for /f "tokens=* delims= " %%A in ("!WOWPATH!") do set "WOWPATH=%%A"
  if not exist "!WOWPATH!\Wow.exe" (
    echo.
    echo ERROR: Wow.exe not found in:
    echo   !WOWPATH!
    echo Run tools\set-wow-path.bat to fix, then try PLAY.bat again.
    pause
    exit /b 1
  )
  > "%~dp0tools\wow-path.cfg" echo !WOWPATH!
  echo Saved WoW path for next time.
  echo.
)

set "ADDONS=!WOWPATH!\Interface\AddOns"
set "PACK=DRUID"
set "PACK_FLAG=-Pack DRUID"
if exist "!ADDONS!\PhaseOneLoader\PhaseOneLoader.lua" (
  findstr /C:"Warlock Pack" "!ADDONS!\PhaseOneLoader\PhaseOneLoader.lua" >nul 2>&1
  if not errorlevel 1 (
    set "PACK=WARLOCK"
    set "PACK_FLAG=-Pack WARLOCK"
  )
) else if exist "!ADDONS!\P1WarlockHUD" (
  set "PACK=WARLOCK"
  set "PACK_FLAG=-Pack WARLOCK"
)

set "SYNC_FLAG="
if /I "%~1"=="/FULL" set "SYNC_FLAG=-Full"
if /I "%~1"=="FULL" set "SYNC_FLAG=-Full"
if not exist "!ADDONS!\PhaseOneLoader" (
  echo First run - installing quest pack ^(!PACK!^)...
) else if not exist "!ADDONS!\P1RangeRadar" (
  echo P1RangeRadar missing - syncing quest pack ^(!PACK!^)...
) else if not exist "!ADDONS!\P1QuestNav" (
  echo P1QuestNav missing - syncing quest pack ^(!PACK!^)...
) else if not exist "!ADDONS!\Questie-335" (
  echo Questie-335 missing - syncing quest pack ^(!PACK!^)...
) else if not exist "!ADDONS!\TomTom" (
  echo TomTom missing - syncing quest pack ^(!PACK!^)...
) else if not exist "!ADDONS!\!Astrolabe" (
  echo !Astrolabe missing - syncing quest pack ^(!PACK!^)...
) else if not defined SYNC_FLAG (
  echo Updating quest pack addons ^(!PACK!^)...
) else (
  echo Full sync ^(dev only, !PACK!^)...
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\sync-addons.ps1" -WowPath "!WOWPATH!" !SYNC_FLAG! !PACK_FLAG!
if errorlevel 1 (
  echo ERROR: addon sync failed.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\cleanup-wow-addons.ps1" -WowPath "!WOWPATH!"
if errorlevel 1 (
  echo ERROR: addon cleanup failed.
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
echo  Done! Log in and type /reload
echo ========================================
echo.
echo Quest pack: Questie + Auto Q + Nav + Range radar + Mats guide.
echo Press any key to close (auto in 3s)...
timeout /t 3 /nobreak >nul
pause >nul
exit /b 0
