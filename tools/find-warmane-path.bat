@echo off
setlocal EnableDelayedExpansion
set "WOWPATH="
if defined WARMANE_WOW_PATH if exist "!WARMANE_WOW_PATH!\Wow.exe" set "WOWPATH=!WARMANE_WOW_PATH!"
if defined WOWPATH goto found
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
) do (
  if exist "%%~P\Wow.exe" set "WOWPATH=%%~P"
  if defined WOWPATH goto found
)
for /d %%D in ("C:\Games\Warmane\*" "D:\Games\Warmane\*") do (
  if exist "%%D\Wow.exe" set "WOWPATH=%%D"
  if defined WOWPATH goto found
)
:found
endlocal & if defined WOWPATH set "WOWPATH=%WOWPATH%"
