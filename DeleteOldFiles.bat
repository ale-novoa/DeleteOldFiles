@echo off
REM ============================================================================
REM DeleteOldFiles.bat
REM
REM Wrapper to run DeleteOldFiles.ps1 - schedule THIS file weekly in
REM Windows Task Scheduler on the server.
REM
REM DeleteOldFiles.ps1 must be in the same folder as this .bat file.
REM
REM Created : 2026-08-20
REM Author  : Alejandro Novoa
REM ============================================================================

set SCRIPT_DIR=%~dp0

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%DeleteOldFiles.ps1"

exit /b %ERRORLEVEL%
