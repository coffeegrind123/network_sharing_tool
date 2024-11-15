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
echo   Network Interface Sharing Tool
echo ================================
echo.
echo Available Network Interfaces:
echo ---------------------------

:: List all network adapters and store them in an array
set "index=0"
for /f "skip=3 tokens=1,2,3,*" %%i in ('netsh interface show interface') do (
    set /a "index+=1"
    set "adapter_!index!=%%l"
    echo !index!. %%l
)
set "total_adapters=!index!"

echo ---------------------------
echo.
echo Sharing Options:
echo 1. Share between interfaces
echo 2. Disable All Sharing
echo 3. Exit
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" goto :share_select
if "%choice%"=="2" goto :disable
if "%choice%"=="3" exit /b 0
goto :menu

:share_select
cls
echo Select source interface (sharing FROM):
echo ---------------------------
for /l %%i in (1,1,%total_adapters%) do (
    echo %%i. !adapter_%%i!
)
echo ---------------------------
echo.
set /p source="Enter number of source interface: "

cls
echo Select target interface (sharing TO):
echo ---------------------------
for /l %%i in (1,1,%total_adapters%) do (
    echo %%i. !adapter_%%i!
)
echo ---------------------------
echo.
set /p target="Enter number of target interface: "

if not defined adapter_%source% (
    echo Invalid source interface selection!
    pause
    goto :menu
)
if not defined adapter_%target% (
    echo Invalid target interface selection!
    pause
    goto :menu
)

:: Enable sharing between selected interfaces
echo.
echo Configuring Internet Connection Sharing...
echo FROM: !adapter_%source%! TO: !adapter_%target%!

:: Use PowerShell to set up ICS
powershell -Command "$source='!adapter_%source%!'; $target='!adapter_%target%!'; $netsharing = New-Object -ComObject HNetCfg.HNetShare; $connections = @($netsharing.EnumEveryConnection | ForEach-Object { $props = $netsharing.NetConnectionProps.Invoke($_); $config = $netsharing.INetSharingConfigurationForINetConnection.Invoke($_); [PSCustomObject]@{ Name = $props.Name; Connection = $_; Config = $config } }); $sourceConn = $connections | Where-Object { $_.Name -eq $source }; $targetConn = $connections | Where-Object { $_.Name -eq $target }; if ($sourceConn) { $sourceConn.Config.EnableSharing(0) } else { Write-Host 'Source adapter not found in sharing configuration' }; if ($targetConn) { $targetConn.Config.EnableSharing(1) } else { Write-Host 'Target adapter not found in sharing configuration' }"

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
