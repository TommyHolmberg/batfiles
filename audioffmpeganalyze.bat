:: Takes the output from probewav.ps1
@echo off
setlocal

:: Set variables
set "SCRIPT_PATH=%~dp0probewav.ps1"

:: Check that PowerShell script exists
if not exist "%SCRIPT_PATH%" (
    echo Error: PowerShell script "%SCRIPT_PATH%" not found.
    pause
    exit /b 1
)

echo Running PowerShell script...

:: Option 1: Display Output in Console
echo.
echo Output to Console:
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
echo.
pause

echo Done.
endlocal