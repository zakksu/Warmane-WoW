@echo off
setlocal
echo Phase One WARLOCK Pack - Install Helper
echo.
set /p WOWPATH="Paste full path to your Warmane WoW folder (contains Wow.exe): "
if not exist "%WOWPATH%\Interface\AddOns" (
  echo Creating Interface\AddOns...
  mkdir "%WOWPATH%\Interface\AddOns"
)
echo Copying addons...
xcopy /E /I /Y "%~dp0Interface\AddOns\*" "%WOWPATH%\Interface\AddOns\"
echo.
echo Done!
echo.
echo NEXT STEPS:
echo   1. Start WoW - character select - AddOns
echo   2. Check "Load out of date AddOns" - enable all
echo   3. Log in on Warlock - type /reload
echo.
echo Auto on first login: Questie, Leatrix, P1 Warlock HUD
echo Optional: /wa for extra WeakAuras
pause
