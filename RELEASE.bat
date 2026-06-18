@echo off
setlocal
echo ========================================
echo  Warmane-WoW Phase One - BUILD RELEASE
echo ========================================
echo.
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\tools\build-all.ps1"
if errorlevel 1 (
  echo Build failed.
  pause
  exit /b 1
)
echo.
echo ========================================
echo  RELEASE READY
echo ========================================
echo.
echo  Install packs (copy to Warmane):
echo    PhaseOne_LevelingPack\INSTALL.bat      - Warlock
echo    PhaseOne_Druid_LevelingPack\INSTALL.bat - Feral Druid
echo.
echo  Shareable zips (optional):
echo    PhaseOne_LevelingPack.zip
echo    PhaseOne_Druid_LevelingPack.zip
echo.
echo  First login auto-configures everything. No WA import required.
echo.
pause
