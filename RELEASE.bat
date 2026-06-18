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
echo    INSTALL.bat              - pick Warlock or Druid (easiest)
echo    INSTALL_WARLOCK.bat      - Warlock only
echo    INSTALL_DRUID.bat        - Feral Druid only
echo    Or inside each pack folder: PhaseOne_* \INSTALL.bat
echo.
echo  Shareable zips (optional):
echo    PhaseOne_LevelingPack.zip
echo    PhaseOne_Druid_LevelingPack.zip
echo.
echo  First login auto-configures everything. No WA import required.
echo.
pause
