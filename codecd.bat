:: Opens current directory in VS Code
@echo off
:: Check if VS Code is installed by checking the `code` command
where code >nul 2>nul
if %errorlevel% neq 0 (
    echo Visual Studio Code is not installed or not in PATH.
    exit /b 1
)

:: Open the current directory in VS Code
code "%cd%"
echo Opened current folder in Visual Studio Code.
exit /b 0
