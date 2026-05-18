@echo off
setlocal

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher\Launch-BACH-Exporter.ps1"

if errorlevel 1 (
  echo.
  echo BACH Exporter failed to launch.
  echo Please copy the error above and send it to the study team.
  echo.
  pause
)
