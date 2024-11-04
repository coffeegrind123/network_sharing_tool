@echo off
setlocal EnableDelayedExpansion

:: Run as administrator check
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :admin
) else (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

:admin
:: Menu
:menu
cls
echo ================================
echo   WiFi to Ethernet Sharing Tool
echo ================================
echo.
echo 1. Enable Internet Sharing
echo 2. Disable Internet Sharing
echo 3. Exit
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" goto :enable
if "%choice%"=="2" goto :disable
if "%choice%"=="3" exit /b 0
goto :menu

:enable
:: Get network adapter names
echo Detecting network adapters...

:: List all network adapters and their status
for /f "skip=3 tokens=1,2,3,*" %%i in ('netsh interface show interface') do (
    if "%%l"=="Wi-Fi" (
        set "wifi_adapter=%%l"
        echo Found WiFi adapter: !wifi_adapter!
    )
    if "%%l"=="Ethernet" (
        set "ethernet_adapter=%%l"
        echo Found Ethernet adapter: !ethernet_adapter!
    )
)

if not defined wifi_adapter (
    echo WiFi adapter not found!
    pause
    goto :menu
)

if not defined ethernet_adapter (
    echo Ethernet adapter not found!
    pause
    goto :menu
)

:: Enable sharing
echo.
echo Configuring Internet Connection Sharing...

:: Use PowerShell to set up ICS
powershell -Command "$wifi='%wifi_adapter%'; $eth='%ethernet_adapter%'; $netsharing = New-Object -ComObject HNetCfg.HNetShare; $connections = @($netsharing.EnumEveryConnection | ForEach-Object { $props = $netsharing.NetConnectionProps.Invoke($_); $config = $netsharing.INetSharingConfigurationForINetConnection.Invoke($_); [PSCustomObject]@{ Name = $props.Name; Connection = $_; Config = $config } }); $wifiConn = $connections | Where-Object { $_.Name -eq $wifi }; $ethConn = $connections | Where-Object { $_.Name -eq $eth }; if ($wifiConn) { $wifiConn.Config.EnableSharing(0) } else { Write-Host 'WiFi adapter not found in sharing configuration' }; if ($ethConn) { $ethConn.Config.EnableSharing(1) } else { Write-Host 'Ethernet adapter not found in sharing configuration' }"

echo.
echo Configuration complete. Please wait a moment for the changes to take effect...
timeout /t 5 >nul
goto :menu

:disable
:: Disable sharing
echo Disabling Internet Connection Sharing...

powershell -Command "$netsharing = New-Object -ComObject HNetCfg.HNetShare; $netsharing.EnumEveryConnection | ForEach-Object { $config = $netsharing.INetSharingConfigurationForINetConnection.Invoke($_); $config.DisableSharing() }; Write-Host 'Internet Connection Sharing disabled successfully.'"

echo.
echo Please wait a moment for the changes to take effect...
timeout /t 5 >nul
goto :menu