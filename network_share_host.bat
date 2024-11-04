@echo off
setlocal EnableDelayedExpansion

:: ======================
:: CONFIGURATION OPTIONS
:: ======================
:: Set to 1 for fully automatic mode, 0 for interactive
set "AUTOMATIC=1"

:: Share settings
set "SHARE_PATH=C:\Share"
set "SHARE_NAME=Share"
set "SHARE_DRIVE_LETTER=Z:"

:: User settings
set "SHARE_USER=ShareUser"
set "SHARE_PASSWORD=Pass123!"

:: Network settings
set "ICS_IP=192.168.137.1"
:: ======================

:: Admin check
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

:: Create a local user for sharing
echo Creating local user for sharing...
net user %SHARE_USER% %SHARE_PASSWORD% /add /y >nul 2>&1
net localgroup "Users" %SHARE_USER% /add >nul 2>&1
wmic useraccount where "name='%SHARE_USER%'" set PasswordExpires=FALSE >nul 2>&1

:: Create folder if it doesn't exist
if not exist "%SHARE_PATH%" (
    mkdir "%SHARE_PATH%"
    echo Created folder: %SHARE_PATH%
)

:: Remove existing share if it exists
net share "%SHARE_NAME%" /delete /y >nul 2>&1

:: Configure network settings
echo Configuring network settings...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
powershell -Command "Set-NetConnectionProfile -NetworkCategory Private" >nul 2>&1

:: Configure sharing with full permissions
echo Setting up network share...
net share "%SHARE_NAME%"="%SHARE_PATH%" /GRANT:Everyone,FULL >nul 2>&1

:: Set NTFS permissions
echo Setting NTFS permissions...
icacls "%SHARE_PATH%" /reset >nul 2>&1
icacls "%SHARE_PATH%" /grant Everyone:(OI)(CI)F >nul 2>&1
icacls "%SHARE_PATH%" /grant "%SHARE_USER%":(OI)(CI)F >nul 2>&1

:: Create a test file
echo This is a test file > "%SHARE_PATH%\test.txt"

echo.
echo Share setup complete!
echo.
echo Share Information:
echo ------------------
echo Path: %SHARE_PATH%
echo Network path: \\%ICS_IP%\%SHARE_NAME%
echo.
echo Login Credentials:
echo Username: %SHARE_USER%
echo Password: %SHARE_PASSWORD%
echo.

if "%AUTOMATIC%"=="0" (
    pause
)
