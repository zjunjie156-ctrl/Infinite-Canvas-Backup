@echo off
cd /d "%~dp0"
echo Starting...
echo Open http://127.0.0.1:3000/
echo Press Ctrl+C to stop.
echo.

set "PYEXE=%~dp0python\python.exe"
if not exist "%PYEXE%" set "PYEXE=python"

"%PYEXE%" main.py
pause
