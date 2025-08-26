@echo off
setlocal enabledelayedexpansion

if "%~1"=="--help" (
    echo Opens a nested subfolder path from the arguments.
    echo e.g., 'repos cpp vnn' opens D:\Repos\cpp\vnn
    echo If the path does not exist, or if no arguments are given, opens the base path.
    echo.
    echo Usage: repos [subfolder1] [subfolder2] ...
    echo        repos --help
    goto :eof
)

set "TARGET_PATH=D:\Repos"

if not "%~1"=="" (
    set "SUB_PATH="
    for %%a in (%*) do (
        set "SUB_PATH=!SUB_PATH!\%%a"
    )
    set "FULL_PATH=%TARGET_PATH%!SUB_PATH!"
    if exist "!FULL_PATH!" (
        set "TARGET_PATH=!FULL_PATH!"
    )
)

explorer.exe "%TARGET_PATH%"