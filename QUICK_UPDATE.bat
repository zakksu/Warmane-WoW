@echo off
setlocal
echo ========================================
echo  Warmane-WoW Phase One - QUICK RELEASE
echo ========================================
echo.
echo Bumps patch version, rebuilds zips, commits, pushes, tags, and
echo tries to publish a GitHub release (skips if gh is not set up).
echo.
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\tools\quick-release.ps1" %*
if errorlevel 1 (
  echo.
  echo Quick release failed.
  pause
  exit /b 1
)
echo.
pause
