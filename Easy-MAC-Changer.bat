@echo off
setlocal EnableDelayedExpansion
color 0A

:: Self-elevate to administrator
>nul 2>&1 net session
if %errorlevel% neq 0 (
  cls
  echo.
  echo [*] Requesting administrator privileges...
  timeout /t 1 >nul
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

cls
echo.
echo   ╔═══════════════════════════════════════════════════════════╗
echo   ║                                                           ║
echo   ║         Easy MAC Address Changer                          ║
echo   ║         Bypass WiFi Blockers by Changing MAC               ║
echo   ║                                                           ║
echo   ╚═══════════════════════════════════════════════════════════╝
echo.

:: Find active network adapter (prefer WiFi, fallback to Ethernet)
echo [*] Detecting network adapter...
set "ADAPTER_NAME="
set "CURMAC="

:: Try to find WiFi adapter first
for /f "tokens=1,2 delims=," %%a in ('getmac /v /fo csv /nh ^| findstr /i "Wi-Fi Wireless"') do (
  set "ADAPTER_NAME=%%a"
  set "CURMAC=%%b"
  set "ADAPTER_NAME=!ADAPTER_NAME:"=!"
  set "CURMAC=!CURMAC:"=!"
  if not "!CURMAC!"=="" goto :found_adapter
)

:: Fallback to any active adapter
for /f "tokens=1,2 delims=," %%a in ('getmac /v /fo csv /nh ^| findstr /v "Media disconnected"') do (
  set "ADAPTER_NAME=%%a"
  set "CURMAC=%%b"
  set "ADAPTER_NAME=!ADAPTER_NAME:"=!"
  set "CURMAC=!CURMAC:"=!"
  if not "!CURMAC!"=="" goto :found_adapter
)

echo.
echo [ERROR] No active network adapter found.
echo [INFO] Please ensure your WiFi or Ethernet adapter is connected.
echo.
pause
exit /b

:found_adapter
echo [SUCCESS] Active Adapter: %ADAPTER_NAME%
echo [INFO] Current MAC Address: %CURMAC%
echo.

:: Generate random locally-administered unicast MAC address
echo [*] Generating new MAC address...
for /f "usebackq delims=" %%M in (`
  powershell -NoProfile -Command ^
    "$r = New-Object byte[] 6; (New-Object System.Random).NextBytes($r);" ^
    "$r[0] = ($r[0] -bor 2) -band 0xFE;" ^
    "('{0:X2}{1:X2}{2:X2}{3:X2}{4:X2}{5:X2}' -f $r[0],$r[1],$r[2],$r[3],$r[4],$r[5])"
`) do set "NEWMAC=%%M"

echo [SUCCESS] New MAC Address: %NEWMAC%
echo.

:: Find registry key for the adapter
echo [*] Searching for adapter registry key...
set "FoundKey="

:: Search through network adapter registry keys and match by adapter name
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s 2^>nul ^| findstr "{4d36e972-e325-11ce-bfc1-08002be10318}"') do (
  reg query "%%K" /v DriverDesc 2^>nul | findstr /i "%ADAPTER_NAME%" >nul
  if !errorlevel! equ 0 (
    set "FoundKey=%%K"
    goto :found_key
  )
)

:: Alternative: find by matching MAC address
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s 2^>nul ^| findstr "{4d36e972-e325-11ce-bfc1-08002be10318}"') do (
  for /f "tokens=3" %%M in ('reg query "%%K" /v NetworkAddress 2^>nul') do (
    if /i "%%M"=="%CURMAC%" (
      set "FoundKey=%%K"
      goto :found_key
    )
  )
)

echo.
echo [ERROR] Could not find adapter registry key.
echo [INFO] Please ensure your network adapter is properly installed.
echo.
pause
exit /b

:found_key
echo [SUCCESS] Registry key found.
echo.

:: Set new MAC address in registry
echo [*] Applying new MAC address to registry...
reg add "%FoundKey%" /v NetworkAddress /t REG_SZ /d %NEWMAC% /f >nul 2>&1
if %errorlevel% neq 0 (
  echo.
  echo [ERROR] Failed to set MAC address in registry.
  echo [INFO] Make sure you're running as administrator.
  echo.
  pause
  exit /b
)

echo [SUCCESS] MAC address set in registry.
echo.

:: Disable and enable adapter to apply change
echo [*] Disabling network adapter...
netsh interface set interface "%ADAPTER_NAME%" admin=disabled >nul 2>&1
timeout /t 2 >nul

echo [*] Enabling network adapter...
netsh interface set interface "%ADAPTER_NAME%" admin=enabled >nul 2>&1
timeout /t 3 >nul

:: Verify new MAC address
echo [*] Verifying MAC address change...
for /f "tokens=2 delims=," %%a in ('getmac /v /fo csv /nh ^| findstr /i "%ADAPTER_NAME%"') do (
  set "READMAC=%%a"
  set "READMAC=!READMAC:"=!"
)

echo.
echo   ╔═══════════════════════════════════════════════════════════╗
echo   ║                                                           ║
echo   ║         MAC Address Changed Successfully!                 ║
echo   ║                                                           ║
echo   ╚═══════════════════════════════════════════════════════════╝
echo.
echo   Old MAC Address: %CURMAC%
echo   New MAC Address: %READMAC%
echo.
echo   [SUCCESS] Your WiFi connection should now be restored!
echo.
echo   Press any key to exit...
pause >nul

