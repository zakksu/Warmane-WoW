@echo off
setlocal
echo Phase One DRUID Pack - Install Helper (Warmane Icecrown)
echo.
set /p WOWPATH="Paste full path to your Warmane WoW folder (contains Wow.exe): "
if not exist "%WOWPATH%\Interface\AddOns" (
  echo Creating Interface\AddOns...
  mkdir "%WOWPATH%\Interface\AddOns"
)
echo Copying addons...
xcopy /E /I /Y "%~dp0Interface\AddOns\*" "%WOWPATH%\Interface\AddOns\"
echo Done!
echo.
echo NEXT STEPS:
echo   1. Start WoW - character select screen
echo   2. AddOns - check "Load out of date AddOns" - enable all
echo   3. Log in on your Druid - type /reload
echo.
echo Everything auto-configures on first login:
echo   - Questie leveling settings
echo   - Leatrix auto-repair / sell greys
echo   - P1 Feral HUD (energy, combo points, debuffs)
echo.
echo Optional: /wa for extra WeakAuras (not required)
pause
