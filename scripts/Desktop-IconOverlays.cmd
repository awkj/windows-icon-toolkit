@echo off
setlocal
echo 1. Hide shortcut arrows
echo 2. Hide arrows and try to hide UAC shields
echo 3. Restore previous settings
echo 4. Show current settings
choice /c 1234 /n /m "Select [1-4]: "
if errorlevel 4 goto status
if errorlevel 3 goto restore
if errorlevel 2 goto both
:arrows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desktop-IconOverlays.ps1" -Action Hide -Pause
exit /b
:both
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desktop-IconOverlays.ps1" -Action Hide -IncludeShield -Pause
exit /b
:restore
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desktop-IconOverlays.ps1" -Action Restore -Pause
exit /b
:status
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desktop-IconOverlays.ps1" -Action Status -Pause
