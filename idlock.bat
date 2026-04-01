@echo off
setlocal enabledelayedexpansion

:: Re-launch as admin if not already elevated, preserving the argument and working directory
>nul 2>&1 net session
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c cd /d \"%cd%\" && \"%~f0\" \"%~1\"' -Verb RunAs"
    exit /B
)

:: Capture the target from argument or prompt
set "target=%~1"
if "%target%"=="" set /p target="Enter file or folder name: "

:: Resolve to absolute path (check for drive letter to detect absolute)
if "%target:~1,1%"==":" (
    set "fullPath=%target%"
) else (
    set "fullPath=%cd%\%target%"
)

echo DEBUG target=[%target%]
echo DEBUG fullPath=[%fullPath%]

:: Check the file/folder exists before doing anything
if not exist "%fullPath%" (
    echo ERROR: "%fullPath%" not found.
    pause
    exit /B 1
)

echo.
echo [1/3] Searching for process locks on: %fullPath%
powershell -ExecutionPolicy Bypass -Command ^
    "$proc = Get-Process | Where-Object { try { $_.Path -like '*%target%*' -or $_.Modules.FileName -contains '%fullPath%' } catch { $false } };" ^
    "if ($proc) { $proc | ForEach-Object { Stop-Process -Id $_.Id -Force -Confirm }; Write-Host 'Processes terminated.' -ForegroundColor Green } else { Write-Host 'No active processes found.' -ForegroundColor Gray }"

echo.
echo [2/3] Taking Ownership...
:: /r = recursive, /d y = suppress confirmation
takeown /f "%fullPath%" /r /d y >nul 2>&1
if !errorlevel! equ 0 (
    echo Ownership claimed successfully.
) else (
    echo Failed to take ownership. Try running this script as Administrator.
)

echo.
echo [3/3] Granting Full Control to Users...
echo DEBUG icacls path=[%fullPath%]
icacls "%fullPath%" /grant Users:F /t /c /l /q
if !errorlevel! equ 0 (
    echo Permissions updated to Full Control.
) else (
    echo Permission update failed.
)

echo.
echo --- Task Complete. Try your 'ren' command now. ---
pause