@echo off
setlocal EnableDelayedExpansion
set "WOWPATH="

REM 1) Saved path (tools/wow-path.cfg — one line)
set "CFG=%~dp0wow-path.cfg"
if exist "%CFG%" (
  set /p CFGPATH=<"%CFG%"
  for /f "tokens=* delims= " %%A in ("!CFGPATH!") do set "CFGPATH=%%A"
  if defined CFGPATH if exist "!CFGPATH!\Wow.exe" set "WOWPATH=!CFGPATH!"
)
if defined WOWPATH goto found

REM 2) Environment override
if defined WARMANE_WOW_PATH if exist "!WARMANE_WOW_PATH!\Wow.exe" set "WOWPATH=!WARMANE_WOW_PATH!"
if defined WOWPATH goto found

REM 3) Common install locations
for %%P in (
  "C:\Games\Warmane"
  "C:\Games\Warmane\Wotlk"
  "C:\Program Files\Warmane"
  "C:\Program Files (x86)\Warmane"
  "D:\Games\Warmane"
  "D:\Games\Warmane\Wotlk"
  "E:\Games\Warmane"
  "%USERPROFILE%\Games\Warmane"
  "%USERPROFILE%\Desktop\Warmane"
  "%USERPROFILE%\Downloads\World.of.Warcraft.3.3.5a.Truewow"
) do (
  if exist "%%~P\Wow.exe" set "WOWPATH=%%~P"
  if defined WOWPATH goto found
)
for /d %%D in ("C:\Games\Warmane\*" "D:\Games\Warmane\*") do (
  if exist "%%D\Wow.exe" set "WOWPATH=%%D"
  if defined WOWPATH goto found
)

:found
for %%A in ("!WOWPATH!") do endlocal & set "WOWPATH=%%~A"
