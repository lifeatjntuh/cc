@echo off
setlocal

rem Campus Companion repo scaffolder -- batch launcher.
rem
rem This just hands off to PowerShell (bundled with every Windows install
rem since Win7 -- nothing to install) to do the actual work, since generating
rem many multi-line JSON/YAML/Markdown files reliably isn't something plain
rem batch can do without risking corrupted output.
rem
rem Run this FROM YOUR REPO ROOT (double-click it there, or run it from a
rem terminal already cd'd into the repo). It scaffolds files into the
rem current directory and does NOT push anywhere.
rem
rem Optional: drop a remote URL as the first argument to also set "origin":
rem   setup-repo.bat https://github.com/you/campus-companion.git

where powershell >nul 2>nul
if errorlevel 1 (
    echo.
    echo ERROR: powershell.exe was not found on PATH.
    echo This script requires PowerShell, which ships with Windows by default.
    echo.
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "REMOTE_URL=%~1"

if "%REMOTE_URL%"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\Setup-CampusCompanionRepo.ps1" -ProjectPath "." -SourceDocsPath "%SCRIPT_DIR%"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\Setup-CampusCompanionRepo.ps1" -ProjectPath "." -SourceDocsPath "%SCRIPT_DIR%" -RemoteUrl "%REMOTE_URL%"
)

echo.
pause
endlocal
