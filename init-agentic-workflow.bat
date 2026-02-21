@echo off
SETLOCAL EnableDelayedExpansion

:: 1. Determine Target Directory
set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=%CD%"

echo [Agentic-Init] Setting up vibe in: %TARGET_DIR%

:: 2. Verify GitHub CLI Authentication
:: If not logged in, this triggers the official web-based flow
gh auth status >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [!] No active GitHub session found. Launching login...
    call gh auth login --web -h github.com
) else (
    echo [OK] GitHub CLI is already authenticated.
)

:: 3. Define Source (Update this to your public repo)
set "REPO_URL=https://raw.githubusercontent.com/TommyHolmberg/agentic-github-workflow/main"

:: 4. Download Master Instructions
echo [Agentic-Init] Fetching agentic-development-protocol.md...
curl -sL "%REPO_URL%/agentic-development-protocol.md" -o "%TARGET_DIR%\agentic-development-protocol.md"

:: 5. Create Unified Instruction Links (Symlinks)
:: This ensures Claude, Gemini, and Copilot all follow the same local "vibe."
cd /d "%TARGET_DIR%"

echo [Agentic-Init] Creating agent symlinks...
mklink CLAUDE.md agentic-development-protocol.md >nul
mklink GEMINI.md agentic-development-protocol.md >nul

if not exist ".github" mkdir .github
mklink ".github\copilot-instructions.md" "..\agentic-development-protocol.md" >nul

echo --------------------------------------------------
echo [SUCCESS] Initialization Complete!
echo --------------------------------------------------
echo AGENT READY: Your local agents now use your 'gh' session.
echo Try saying: "Claude, list my GitHub issues with the 'todo' label."
echo --------------------------------------------------