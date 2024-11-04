@echo off
setlocal EnableDelayedExpansion

:: Admin check
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Cleaning up all sharing and network settings...

:: Remove network drives
net use * /delete /y

:: Remove shares
net share Share /delete /y
net share C:\Share /delete /y

:: Remove test folder if it exists
if exist "C:\Share" (
    rd /s /q "C:\Share"
)

:: Remove user accounts we created
net user ShareUser /delete 2>nul
net user guest /active:no

:: Reset network settings
netsh advfirewall reset

:: Reset registry settings
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "NullSessionShares" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "RestrictNullSessAccess" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "everyoneincludesanonymous" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "NoLMHash" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LmCompatibilityLevel" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "AllowInsecureGuestAuth" /f 2>nul

:: Reset SMB settings
powershell "Disable-WindowsOptionalFeature -Online -FeatureName 'SMB1Protocol' -NoRestart" 2>nul

:: Reset network discovery and file sharing
netsh advfirewall firewall set rule group="Network Discovery" new enable=No
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=No

:: Set network back to public
powershell "Set-NetConnectionProfile -NetworkCategory Public"

echo.
echo Cleanup complete! Settings have been reset to defaults.
echo Please restart your computer for all changes to take effect.
echo.
echo Run this script on both computers.
echo.
pause
