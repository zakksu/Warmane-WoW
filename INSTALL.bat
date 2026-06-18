@echo off
setlocal
cd /d "%~dp0"
echo ========================================
echo  Warmane-WoW Phase One - INSTALL
echo ========================================
echo.
echo Choose your leveling pack (install ONE per character):
echo.
echo   1  Warlock     (PhaseOne_LevelingPack)
echo   2  Feral Druid (PhaseOne_Druid_LevelingPack)
echo   Q  Quit
echo.
choice /C 12Q /N /M "Pick 1, 2, or Q: "
if errorlevel 3 exit /b 0
if errorlevel 2 goto druid
if errorlevel 1 goto warlock

:warlock
call "%~dp0tools\install-pack.bat" WARLOCK "%~dp0PhaseOne_LevelingPack\"
exit /b %ERRORLEVEL%

:druid
call "%~dp0tools\install-pack.bat" DRUID "%~dp0PhaseOne_Druid_LevelingPack\"
exit /b %ERRORLEVEL%
