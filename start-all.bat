@echo off
REM Batch wrapper to execute start-all.ps1 with execution policy bypass
echo Launching backend microservices starter...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-all.ps1"
pause
