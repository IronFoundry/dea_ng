@echo off

setlocal

echo.

set CC_IP=%1
set CC_DOMAIN=%2
set NATS_USER=%3
set NATS_PASS=%4

IF [%CC_IP%] == [] set /p CC_IP="Cloud controller IP: "
IF [%CC_DOMAIN%] == [] set /p CC_DOMAIN="Cloud controller domain: "
IF [%NATS_USER%] == [] set /p NATS_USER="NATS user (optional): "
IF [%NATS_PASS%] == [] set /p NATS_PASS="NATS password (optional): "

echo Cloud Controller address: '%CC_IP%'
echo Cloud Controller domain: '%CC_DOMAIN%'
echo NATS user: '%NATS_USER%'
echo NATS password: '%NATS_PASS%'

ping -n 1 -w 5000 %CC_IP% > nul
IF ERRORLEVEL 1 GOTO ping_exit

set RUBYBINDIR=C:\Ruby193\bin
echo Ruby directory is '%RUBYBINDIR%'
echo.

IF NOT EXIST %RUBYBINDIR%\rubyw.exe GOTO rubyw_exit

set ADDTOPATH=%RUBYBINDIR%
path | findstr /I /L "%ADDTOPATH%" > nul 2>&1
IF ERRORLEVEL 1 goto modify_path

:continue_1
sc delete dea_winsvc > nul 2>&1

echo Creating 'dea_winsvc' windows service ...
sc create dea_winsvc obj= "NT AUTHORITY\Local Service" start= delayed-auto binPath= "%RUBYBINDIR%\rubyw.exe -C C:\IronFoundry\dea_ng\app\bin dea_winsvc.rb C:\IronFoundry\dea_ng\app\config\dea_mswin-clr.yml"
IF ERRORLEVEL 1 GOTO error_exit

echo Configuring 'dea_winsvc' windows service ...
sc failure dea_winsvc reset= 86400 actions= restart/600000/restart/600000/restart/600000
IF ERRORLEVEL 1 GOTO error_exit

echo Running 'ruby.exe install.rb %CC_IP% %CC_DOMAIN% %NATS_USER% %NATS_PASS%' ...
%RUBYBINDIR%\ruby.exe install.rb %CC_IP% %CC_DOMAIN% %NATS_USER% %NATS_PASS%
IF ERRORLEVEL 1 GOTO error_exit

del /F C:\IronFoundry\run\*.pid
del /F C:\IronFoundry\log\*.log

echo Starting 'dea_winsvc' ...
sc start dea_winsvc
IF ERRORLEVEL 1 GOTO error_exit

:success_exit
echo.
exit /b 0

:error_exit
sc stop dea_winsvc
sc delete dea_winsvc
echo ERRORLEVEL: %ERRORLEVEL%
exit /b 1

:ping_exit
echo Failed to ping cloud controller using address '%CC_IP%'
exit /b 1

:rubyw_exit
echo Failed to find required binary C:\Ruby193\bin\rubyw.exe
exit /b 1

:modify_path
echo Adding "%ADDTOPATH%" to the system PATH ...
set PATH=%ADDTOPATH%;%PATH%
setx /M PATH "%PATH%"
IF ERRORLEVEL 1 GOTO error_exit
goto continue_1
