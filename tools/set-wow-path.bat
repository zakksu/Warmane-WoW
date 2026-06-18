@echo off
setlocal EnableDelayedExpansion
set "CFG=%~dp0wow-path.cfg"

if not "%~1"=="" (
  set "NEWPATH=%~1"
  goto validate
)

echo Phase One — set Warmane WoW folder
echo.
if exist "%CFG%" (
  set /p OLDPATH=<"%CFG%"
  echo Current saved path:
  echo   !OLDPATH!
  echo.
)
set /p NEWPATH="Paste full path to your WoW folder (contains Wow.exe): "

:validate
if not defined NEWPATH (
  echo ERROR: No path given.
  pause
  exit /b 1
)
for /f "tokens=* delims= " %%A in ("!NEWPATH!") do set "NEWPATH=%%A"
if not exist "!NEWPATH!\Wow.exe" (
  echo.
  echo ERROR: Wow.exe not found in:
  echo   !NEWPATH!
  pause
  exit /b 1
)
> "%CFG%" echo !NEWPATH!
echo.
echo Saved WoW path:
echo   !NEWPATH!
echo.
echo Installers and PLAY.bat will use this path automatically.
pause
exit /b 0
