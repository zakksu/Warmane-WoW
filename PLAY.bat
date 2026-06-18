@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo ========================================
echo  Phase One — PLAY
echo ========================================
echo.

where git >nul 2>&1
if not errorlevel 1 (
  git pull origin main >nul 2>&1
)

call "%~dp0tools\find-warmane-path.bat"
if not defined WOWPATH (
  echo Warmane folder not saved yet — paste it once ^(must contain Wow.exe^):
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
if exist "!ADDONS!\P1FeralHUD" (
  set "PACK=DRUID"
) else if exist "!ADDONS!\P1WarlockHUD" (
  set "PACK=WARLOCK"
) else (
  set "PACK=DRUID"
)

set "SYNC_FLAG="
set "PACK_FLAG=-Pack !PACK!"
if /I "%~1"=="/FULL" set "SYNC_FLAG=-Full"
if /I "%~1"=="FULL" set "SYNC_FLAG=-Full"
if not exist "!ADDONS!\PhaseOneLoader" (
  echo First run — installing !PACK! pack...
  set "SYNC_FLAG=-Full"
) else if not defined SYNC_FLAG (
  echo Updating P1 addons ^(!PACK!^)...
) else (
  echo Full sync ^(!PACK!^)...
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\sync-addons.ps1" -WowPath "!WOWPATH!" !SYNC_FLAG! !PACK_FLAG!
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
echo  Done! Log in and type /reload
echo ========================================
echo.
powershell -NoProfile -Command "$Host.UI.RawUI.Write('Press any key to close (auto in 3s)...'); $sw=[Diagnostics.Stopwatch]::StartNew(); while($sw.Elapsed.TotalSeconds -lt 3){if([Console]::KeyAvailable){[void][Console]::ReadKey($true); break}; Start-Sleep -m 50}"
exit /b 0
