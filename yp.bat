@echo off
:: Check if an argument is provided
if "%~1"=="" (
    echo %cd% | clip
    echo Copied path to clipboard: %cd%
    exit /b 0
)

:: Check if the specified file exists
if not exist "%~1" (
    echo Error: File "%~1" not found.
    echo Usage: %~nx0 [filename]
    echo If no argument is provided, the current directory path is copied.
    exit /b 1
)

:: Copy the file path to the clipboard
echo %~f1 | clip
echo File path copied to clipboard: %~f1
exit /b 0
