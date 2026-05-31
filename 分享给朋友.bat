@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0share_public.ps1"
pause
