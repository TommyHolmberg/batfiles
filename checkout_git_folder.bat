@echo off
@echo on
setlocal enabledelayedexpansion

:: ====================================================================
:: BATCH SCRIPT: Dynamic Sparse Checkout for a Specific GitHub Folder
:: This script requires arguments to run.
:: ====================================================================
set "DEFAULT_BRANCH=master"

:: --- Help Check ---
if /i "%~1"=="/?" goto :help
if /i "%~1"=="/h" goto :help
if /i "%~1"=="--help" goto :help

:: --- Argument Check ---
if "%~1"=="" (
echo ERROR: Arguments are required to run this script.
goto :help
)

:: --- Argument Parsing ---
set "INPUT_ARG_1=%~1"

:: --- Argument Mode Branching ---
:: If the user provided a second argument, use Explicit Arguments mode.
if not "%~2"=="" goto :explicit_args

:: No second arg -> check for '/tree/' in the URL. If not present, error.
set "TMP=%INPUT_ARG_1%"
set "TMP_TREE=%TMP:/tree/=%"
if not "%TMP_TREE%"=="%TMP%" goto :parse_tree

echo ERROR: You provided only the repository URL, but no folder path.
echo To use the Full GitHub Tree URL mode, provide a URL like:
echo   https://github.com/user/repo/tree/^<branch^>/^<path/to/folder^>
echo Or provide the folder as the second argument:
echo   checkout_git_folder.bat ^<REPO_URL.git^> ^<FOLDER_PATH^>
goto :end

:: Check if the first argument looks like a full GitHub /tree/ URL
set "TMP_TREE=%INPUT_ARG_1:/tree/=%"
if not "%TMP_TREE%"=="%INPUT_ARG_1%" (
	goto :parse_tree
) else (
	goto :explicit_args
)

:parse_tree
set "TMP=%INPUT_ARG_1%"
echo Detected GitHub tree URL. Attempting to parse...

:: 1. Extract BRANCH (first token after /tree/) and FOLDER_PATH (the rest)
set "URL_PART_AFTER_TREE=!INPUT_ARG_1:*/tree/=!"
for /f "tokens=1* delims=/" %%i in ("!URL_PART_AFTER_TREE!") do (
	set "BRANCH=%%i"
	set "FOLDER_PATH=%%j"
)
rem Parsed BRANCH and FOLDER_PATH from URL
rem Ready to construct REPO_URL

:: Ensure we extracted a folder path; otherwise warn and exit
if not defined FOLDER_PATH (
	echo ERROR: Could not determine the folder path from the GitHub tree URL.
	echo Make sure the URL has the form: https://github.com/user/repo/tree/^<branch^>/^<path/to/folder^>
	goto :end
)

:: 3. Construct the REPO_URL by removing the /tree/<branch>/<path> suffix
set "REPO_URL=!INPUT_ARG_1!"
set "strip=/tree/%BRANCH%/%FOLDER_PATH%"
set "REPO_URL=!REPO_URL:%strip%=!"

:: Fix: Check for trailing slash and remove if present before appending .git
if "!REPO_URL!" neq "" (
	if "!REPO_URL:~-1!" == "/" set "REPO_URL=!REPO_URL:~0,-1!"
)
set "REPO_URL=!REPO_URL!.git"

goto :final_validation

:explicit_args
echo Detected explicit arguments.
set "REPO_URL=%~1"
if "!REPO_URL:~-4!" neq ".git" set "REPO_URL=!REPO_URL!.git"
set "FOLDER_PATH=%~2"
set "BRANCH=%~3"

if "%FOLDER_PATH%"=="" (
	echo ERROR: You provided only the repository URL, but no folder path.
	echo.
	echo To use the Explicit Arguments Mode, you must provide the folder path as the second argument:
	echo   checkout_git_folder.bat ^<REPO_URL.git^> ^<FOLDER_PATH^>
	echo.
	echo Alternatively, use the recommended Full GitHub Tree URL mode.
	goto :end
)
if "%BRANCH%"=="" set "BRANCH=%DEFAULT_BRANCH%"

goto :final_validation

:final_validation
:: --- Final Validation and Setup ---
set "DIR_NAME=%FOLDER_PATH%"

echo.
echo ====================================================================
echo Configuration Summary:
echo Repository: !REPO_URL!
echo Folder Path: !FOLDER_PATH!
echo Branch: !BRANCH!
echo Target Directory: !DIR_NAME!
echo ====================================================================
echo.

:: 1. Check if the Git command is available
where git >nul 2>nul
if %errorlevel% neq 0 (
echo ERROR: Git is not installed or not available in the system PATH.
echo Please install Git and try again.
goto :end
)

:: 2. Create the target directory and navigate into it
if not exist "!DIR_NAME!" (
echo Creating directory: !DIR_NAME!
mkdir "!DIR_NAME!"
 set "CREATED_DIR=1"
) else (
echo ERROR: Target directory "!DIR_NAME!" already exists.
echo Please delete or rename it before running the script.
goto :end
)

cd "!DIR_NAME!"

:: 3. Initialize Git
echo Initializing Git repository...
git init >nul 2>&1

:: 4. Connect the local repository to the remote one
echo Adding remote origin...
git remote add origin "!REPO_URL!" >nul 2>&1

:: 5. Enable sparse-checkout
echo Enabling sparse checkout mode...
git config core.sparseCheckout true

:: 6. Specify the exact folder path
echo Configuring folder path: !FOLDER_PATH!/
:: Write the path into the sparse-checkout file in a way that avoids syntax errors
(
	echo !FOLDER_PATH!/
) > ".git\info\sparse-checkout"

:: 7. Fetch the requested branch shallowly and check it out
echo Fetching branch "!BRANCH!" (depth 1) for folder "!FOLDER_PATH!"...
git fetch --depth=1 origin "!BRANCH!"

:: Verify fetch succeeded
if %errorlevel% neq 0 (
	echo ERROR: 'git fetch' failed when trying to fetch branch "!BRANCH!" from the remote.
	if defined CREATED_DIR (
		echo Removing incomplete directory "!DIR_NAME!"...
		cd ..
		rmdir /S /Q "!DIR_NAME!"
	)
	goto :end
)

:: Checkout the shallow fetched commit
git checkout -q --force FETCH_HEAD
if %errorlevel% neq 0 (
	echo ERROR: 'git checkout' of FETCH_HEAD failed.
	if defined CREATED_DIR (
		echo Removing incomplete directory "!DIR_NAME!"...
		cd ..
		rmdir /S /Q "!DIR_NAME!"
	)
	goto :end
)

:: Create a named branch locally to match the remote branch (if desired)
git branch -f "!BRANCH!" FETCH_HEAD >nul 2>&1
git checkout -q "!BRANCH!" >nul 2>&1

:: Check if git pull succeeded. If not, cleanup the created folder and exit with error.
if %errorlevel% neq 0 (
	echo ERROR: Failed to download branch "!BRANCH!" from the remote.
	if defined CREATED_DIR (
		echo Removing incomplete directory "!DIR_NAME!"...
		cd ..
		rmdir /S /Q "!DIR_NAME!"
	)
	goto :end
)

echo.
echo ====================================================================
echo SUCCESS!
echo The contents of the folder "!FOLDER_PATH!" have been downloaded to the "!DIR_NAME!" folder.
echo ====================================================================

goto :final_exit

:help
echo.
echo ====================================================================
echo GIT SPARSE CHECKOUT UTILITY
echo ====================================================================
echo This script clones a specific folder from a Git repository using
echo sparse checkout, saving storage space and time.
echo.
echo Usage (Choose ONE of the following modes):
echo.
echo Mode 1: Full GitHub Tree URL (Recommended)
echo   checkout_git_folder.bat ^<FULL_GITHUB_TREE_URL^>
echo     - Example: checkout_git_folder.bat https://www.google.com/search?q=https://github.com/user/repo/tree/main/src/app
echo     - Automatically extracts repo URL, branch, and folder path.
echo.
echo Mode 2: Explicit Arguments
echo   checkout_git_folder.bat ^<REPO_URL.git^> ^<FOLDER_PATH^> [BRANCH]
echo     - Example: checkout_git_folder.bat https://github.com/user/repo.git src/app dev
echo     - Note: BRANCH is optional and defaults to '%DEFAULT_BRANCH%'.
echo.
echo Mode 3: Help
echo   checkout_git_folder.bat [^--help ^| /h ^| /?]
echo.

:end
echo.
pause

:final_exit
endlocal