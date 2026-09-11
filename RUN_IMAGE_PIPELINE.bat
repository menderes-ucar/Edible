@echo off
setlocal
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0RUN_IMAGE_PIPELINE.ps1"
if errorlevel 1 (
  echo.
  echo IMAGE PIPELINE FAILED.
  pause
  exit /b 1
)
echo.
echo IMAGE PIPELINE COMPLETE.
pause
