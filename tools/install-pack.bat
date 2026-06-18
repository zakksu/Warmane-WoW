@echo off
setlocal EnableDelayedExpansion
REM Usage: install-pack.bat WARLOCK|DRUID "C:\path\to\pack\"
set "PACK=%~1"
set "SRC=%~2"
if not defined PACK goto usage
if not defined SRC goto usage
if not exist "%SRC%Interface\AddOns" (
  echo ERROR: AddOns folder not found in pack:
  echo   %SRC%Interface\AddOns
  pause
  exit /b 1
)

if /I "%PACK%"=="WARLOCK" (
  set "TITLE=Phase One WARLOCK Pack"
  set "CLASS=Warlock"
  set "TIPS=/p1 for tips - /p1whud to toggle HUD - /p1guide for Adventure Guide"
) else if /I "%PACK%"=="DRUID" (
  set "TITLE=Phase One DRUID Pack"
  set "CLASS=Druid"
  set "TIPS=/p1d for tips - /p1hud to toggle HUD - /p1guide for Adventure Guide"
) else (
  goto usage
)

echo !TITLE! - Install Helper
echo.
call "%~dp0find-warmane-path.bat"
if defined WOWPATH (
  echo Using saved WoW path:
  echo   !WOWPATH!
  echo.
) else (
  set /p WOWPATH="Paste full path to your Warmane WoW folder (contains Wow.exe): "
)
if not exist "!WOWPATH!\Wow.exe" (
  echo.
  echo WARNING: Wow.exe not found in:
  echo   !WOWPATH!
  echo Common locations: C:\Games\Warmane\   C:\Program Files\Warmane\
  set /p WOWPATH="Try again - paste Warmane folder path: "
)
if not exist "!WOWPATH!\Wow.exe" (
  echo ERROR: Still no Wow.exe found. Install cancelled.
  echo Tip: run tools\set-wow-path.bat to save your path for next time.
  pause
  exit /b 1
)

REM Save path for future installs and SYNC_AND_PLAY.bat
> "%~dp0wow-path.cfg" echo !WOWPATH!

if not exist "!WOWPATH!\Interface\AddOns" (
  echo Creating Interface\AddOns...
  mkdir "!WOWPATH!\Interface\AddOns"
)
echo Copying addons...
xcopy /E /I /Y "%SRC%Interface\AddOns\*" "!WOWPATH!\Interface\AddOns\"

echo.
echo Updating AddOns.txt (enable P1 addons, disable conflicts)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0write-addons-txt.ps1" -WowPath "!WOWPATH!"
if errorlevel 1 (
  echo WARNING: AddOns.txt update failed — enable addons manually at character select.
)

echo.
echo Done!
echo.
echo NEXT STEPS:
echo   1. Start WoW - character select - AddOns
echo   2. Check "Load out of date AddOns" - required addons should already be on
echo   3. Log in on your !CLASS! - type /reload
echo.
echo Auto on first login: Questie, Leatrix, P1 class HUD, P1 Adventure Guide
echo !TIPS!
echo.
echo Daily dev updates: double-click PLAY.bat at repo root, then /reload in game.
pause
exit /b 0

:usage
echo Usage: install-pack.bat WARLOCK^|DRUID pack-folder-path
exit /b 1
