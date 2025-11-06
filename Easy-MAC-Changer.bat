@echo off
setlocal EnableDelayedExpansion

:: Self-elevate to administrator
>nul 2>&1 net session
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

cls
echo.
echo ========================================
echo    Easy MAC Address Changer
echo ========================================
echo.

:: Find active network adapter
set "ADAPTER_NAME="
set "CURMAC="
set "ADAPTER_DRIVER="

:: Try to find WiFi adapter first
for /f "tokens=2 delims=," %%a in ('getmac /v /fo csv /nh ^| findstr /i "Wi-Fi Wireless"') do (
  set "CURMAC=%%a"
  set "CURMAC=!CURMAC:"=!"
  if not "!CURMAC!"=="" (
    set "ADAPTER_DRIVER=Wi-Fi"
    set "INTERFACE_NAME=Wi-Fi"
    goto :found_adapter
  )
)

:: Fallback to Ethernet/Realtek
for /f "tokens=2 delims=," %%a in ('getmac /v /fo csv /nh ^| findstr /i "Realtek"') do (
  set "CURMAC=%%a"
  set "CURMAC=!CURMAC:"=!"
  if not "!CURMAC!"=="" (
    set "ADAPTER_DRIVER=Realtek PCIe GbE Family Controller"
    set "INTERFACE_NAME=Ethernet"
    goto :found_adapter
  )
)

:: Fallback to any active adapter
for /f "tokens=2 delims=," %%a in ('getmac /v /fo csv /nh ^| findstr /v "Media disconnected"') do (
  set "CURMAC=%%a"
  set "CURMAC=!CURMAC:"=!"
  if not "!CURMAC!"=="" (
    set "INTERFACE_NAME=Ethernet"
    goto :found_adapter
  )
)

echo ERROR: No active network adapter found.
pause
exit /b

:found_adapter
echo Current MAC: %CURMAC%
echo.

:: Generate random locally-administered unicast MAC address
for /f "usebackq delims=" %%M in (`
  powershell -NoProfile -Command ^
    "$r = New-Object byte[] 6; (New-Object System.Random).NextBytes($r);" ^
    "$r[0] = ($r[0] -bor 2) -band 0xFE;" ^
    "('{0:X2}{1:X2}{2:X2}{3:X2}{4:X2}{5:X2}' -f $r[0],$r[1],$r[2],$r[3],$r[4],$r[5])"
`) do set "NEWMAC=%%M"

echo New MAC: %NEWMAC%
echo.

:: Find registry key for the adapter
set "FoundKey="
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /f "%ADAPTER_DRIVER%" 2^>nul ^| findstr "{4d36e972-e325-11ce-bfc1-08002be10318}"') do set "FoundKey=%%K"

if not defined FoundKey (
  echo ERROR: Could not find adapter registry key.
  pause
  exit /b
)

:: Set new MAC address in registry
reg add "%FoundKey%" /v NetworkAddress /t REG_SZ /d %NEWMAC% /f >nul 2>&1
if %errorlevel% neq 0 (
  echo ERROR: Failed to set MAC address in registry.
  pause
  exit /b
)

:: Disable and enable adapter to apply change
netsh interface set interface "%INTERFACE_NAME%" admin=disabled >nul 2>&1
timeout /t 2 >nul
netsh interface set interface "%INTERFACE_NAME%" admin=enabled >nul 2>&1
timeout /t 3 >nul

:: Verify new MAC address
set "READMAC="
for /f "tokens=2 delims=," %%a in ('getmac /v /fo csv /nh ^| findstr /i "%ADAPTER_DRIVER%"') do (
  set "READMAC=%%a"
  set "READMAC=!READMAC:"=!"
)

:: Fallback verification
if not defined READMAC (
  for /f "tokens=2 delims=," %%a in ('getmac /v /fo csv /nh ^| findstr /v "Media disconnected"') do (
    set "READMAC=%%a"
    set "READMAC=!READMAC:"=!"
    goto :done_verify
  )
)
:done_verify

echo.
echo ========================================
echo    MAC Address Changed Successfully!
echo ========================================
echo.
echo Old MAC: %CURMAC%
echo New MAC: %READMAC%
echo.
echo Your WiFi connection should now be restored.
echo.
pause
