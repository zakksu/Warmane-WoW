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
  echo Detected Warmane client:
  echo   !WOWPATH!
  echo.
  set /p USEDETECTED="Use this path? [Y/n]: "
  if /I "!USEDETECTED!"=="n" set "WOWPATH="
)
if not defined WOWPATH (
  set /p WOWPATH="Paste full path to your Warmane WoW folder (contains Wow.exe): "
)
if not exist "%WOWPATH%\Wow.exe" (
  echo.
  echo WARNING: Wow.exe not found in:
  echo   %WOWPATH%
  echo Common locations: C:\Games\Warmane\   C:\Program Files\Warmane\
  set /p WOWPATH="Try again - paste Warmane folder path: "
)
if not exist "%WOWPATH%\Wow.exe" (
  echo ERROR: Still no Wow.exe found. Install cancelled.
  pause
  exit /b 1
)
if not exist "%WOWPATH%\Interface\AddOns" (
  echo Creating Interface\AddOns...
  mkdir "%WOWPATH%\Interface\AddOns"
)
echo Copying addons...
xcopy /E /I /Y "%SRC%Interface\AddOns\*" "%WOWPATH%\Interface\AddOns\"
echo.
echo Done!
echo.
echo NEXT STEPS:
echo   1. Start WoW - character select - AddOns
echo   2. Check "Load out of date AddOns" - enable all
echo   3. Log in on your !CLASS! - type /reload
echo.
echo Auto on first login: Questie, Leatrix, P1 class HUD, P1 Adventure Guide
echo !TIPS!
pause
exit /b 0

:usage
echo Usage: install-pack.bat WARLOCK^|DRUID pack-folder-path
exit /b 1
