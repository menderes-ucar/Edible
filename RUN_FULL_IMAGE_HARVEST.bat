@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0RUN_FULL_IMAGE_HARVEST.ps1"
if errorlevel 1 pause
