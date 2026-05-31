@echo off
cd /d "%~dp0"

echo ============================================
echo   Installing dependencies (offline)
echo ============================================
echo.

set "PYEXE=%~dp0python\python.exe"
if not exist "%PYEXE%" (
    set "PYEXE=python"
)

%PYEXE% --version
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python not found. Please install Python 3.10+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

echo.
echo [1/2] Installing dependencies...
if exist "%~dp0packages" (
    %PYEXE% -m pip install --no-index --find-links=packages -r requirements.txt
) else (
    %PYEXE% -m pip install -r requirements.txt
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARN] Offline install failed, trying online...
    %PYEXE% -m pip install -r requirements.txt
)

echo.
echo Done. Run run.bat to start.
pause
