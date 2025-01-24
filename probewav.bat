:: Takes the output from probewav.ps1
@echo off
setlocal

:: Set variables
set "SCRIPT_PATH=%~dp0probewav.ps1"
set "OUTPUT_FILE=audio_analysis_output.txt"

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

:: Option 2: Save Output to File (overwrite existing file)
echo.
echo Saving output to file: %OUTPUT_FILE%
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" > "%OUTPUT_FILE%"
echo Saved output to %OUTPUT_FILE%
echo.
pause


:: Option 3: Save output to CSV with the -CSV flag
echo.
echo Saving output to CSV file: audio_analysis.csv
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -CSV
echo Saved output to audio_analysis.csv
echo.
pause

:: Option 4: Save output to CSV with a custom path.
echo.
echo Saving output to CSV file: my_custom_analysis.csv
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -CSV -CSVPath "my_custom_analysis.csv"
echo Saved output to my_custom_analysis.csv
echo.
pause

echo Done.
endlocal