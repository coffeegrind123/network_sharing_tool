@echo off
setlocal EnableDelayedExpansion

:: ======================
:: CONFIGURATION OPTIONS
:: ======================
:: Set to 1 for fully automatic mode, 0 for interactive
set "AUTOMATIC=1"

:: Share settings
set "SHARE_NAME=Share"
set "SHARE_DRIVE_LETTER=Z:"

:: User settings
set "SHARE_USER=ShareUser"
set "SHARE_PASSWORD=Pass123!"

:: Network settings
set "HOST_IP=192.168.137.1"
:: ======================

:: Admin check
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

:: Create matching local user
echo Creating local user for sharing...
net user %SHARE_USER% %SHARE_PASSWORD% /add /y >nul 2>&1
net localgroup "Users" %SHARE_USER% /add >nul 2>&1
wmic useraccount where "name='%SHARE_USER%'" set PasswordExpires=FALSE >nul 2>&1

:: Configure network settings
echo Configuring network settings...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
powershell -Command "Set-NetConnectionProfile -NetworkCategory Private" >nul 2>&1

:: Clear any existing network drives
echo Removing any existing network drives...
net use * /delete /y >nul 2>&1

:: Test connection
echo Testing connection to host...
ping -n 1 -w 1000 %HOST_IP% >nul 2>&1

if errorlevel 1 (
    echo Cannot reach host at %HOST_IP%
    echo.
    echo Troubleshooting steps:
    echo 1. Verify the ethernet cable is connected
    echo 2. Check that ICS is enabled on the host PC
    echo 3. Verify IP settings on both computers
    echo.
    echo Current Settings:
    echo Host IP: %HOST_IP%
    echo Share Name: %SHARE_NAME%
    if "%AUTOMATIC%"=="0" pause
    exit /b 1
)

:: Try to map the drive
echo Attempting to map network drive...
net use %SHARE_DRIVE_LETTER% \\%HOST_IP%\%SHARE_NAME% /user:%SHARE_USER% %SHARE_PASSWORD% /persistent:yes >nul 2>&1

if errorlevel 1 (
    echo Failed to map network drive. Error: 
    net helpmsg %errorlevel%
    echo.
    echo Manual connection:
    echo Windows Explorer: \\%HOST_IP%\%SHARE_NAME%
    echo Username: %SHARE_USER%
    echo Password: %SHARE_PASSWORD%
    echo.
    echo Current Settings:
    echo Drive Letter: %SHARE_DRIVE_LETTER%
    echo Host IP: %HOST_IP%
    echo Share Name: %SHARE_NAME%
) else (
    echo Successfully mapped share to %SHARE_DRIVE_LETTER%
)

echo.
if "%AUTOMATIC%"=="0" (
    pause
)
