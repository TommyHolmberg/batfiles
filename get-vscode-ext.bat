@echo off
REM Usage: install-latest-vsix.bat [repo] [-u username]

setlocal

REM Default username
set USERNAME=TommyHolmberg

REM Parse arguments
set REPO=
:parse
if "%~1"=="" goto afterparse
if /i "%~1"=="-u" (
    shift
    set USERNAME=%~1
) else (
    if not defined REPO set REPO=%~1
)
shift
goto parse
:afterparse

if not defined REPO (
    echo Usage: %~nx0 [repo] [-u username]
    exit /b 1
)

REM Compose full repo string
set FULLREPO=%USERNAME%/%REPO%

REM Download the latest VSIX asset from the latest release
gh release download --repo %FULLREPO% --pattern *.vsix --clobber

REM Find the newest VSIX file in the current directory
for /f "delims=" %%F in ('dir /b /o-d *.vsix 2^>nul') do (
    set VSIX=%%F
    goto :found
)
echo No VSIX file found.
exit /b 1

:found
REM Install the VSIX in VS Code
code.cmd --install-extension "%VSIX%" --force

endlocal