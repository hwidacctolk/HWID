@setlocal DisableDelayedExpansion
@echo off



::============================================================================
::
::   This script is a part of 'Microsoft Activation Scripts' (MAS) project.
::
::   Homepage: massgrave.dev
::      Email: windowsaddict@protonmail.com
::
::============================================================================



::  To activate with Downlevel method (default), run the script with /a parameter or change 0 to 1 in below line
set _acti=0

::  To only generate GenuineTicket.xml with Downlevel method (default), run the script with /g parameter or change 0 to 1 in below line
set _gent=0

::  To enable LockBox method, run the script with /k parameter or change 0 to 1 in below line
::  You need to use this option with either activation or ticket generation. 
::  Example,
::  HWID_Activation.cmd /a /k
::  HWID_Activation.cmd /g /k
set _lock=0

::  Note about Lockbox method: It's working method is not very clean. We don't suggest to run it on a production system.

::  If value is changed in ABOVE lines or any ABOVE parameter is used then script will run in unattended mode
::  Incase if more than one options are used then only one option will be applied


::  To disable changing edition if current edition doesn't support HWID activation, change the value to 0 from 1 or run the script with /c parameter
set _chan=1



::========================================================================================================================================

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="r1" set r1=1
if /i "%%#"=="r2" set r2=1
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
exit /b
)

::  Set Path variable, it helps if it is misconfigured in the system

set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

::  Check LF line ending

pushd "%~dp0"
>nul findstr /rxc:".*" "%~nx0"
if not %errorlevel%==0 (
echo:
echo Error: This is not a correct file. It has LF line ending issue.
echo:
echo Press any key to exit...
pause >nul
popd
exit /b
)
popd

::========================================================================================================================================

cls
color 07
title  HWID Activation

set _args=
set _elev=
set _unattended=0

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="/a"  set _acti=1
if /i "%%A"=="/g"  set _gent=1
if /i "%%A"=="/k"  set _lock=1
if /i "%%A"=="/c"  set _chan=0
if /i "%%A"=="-el" set _elev=1
)
)

for %%A in (%_acti% %_gent% %_lock%) do (if "%%A"=="1" set _unattended=1)

::========================================================================================================================================

set winbuild=1
set "nul=>nul 2>&1"
set psc=powershell.exe
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 2>nul | find /i "0x0" 1>nul && (set _NCS=0)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
set     "Red="41;97m""
set    "Gray="100;97m""
set   "Green="42;97m""
set "Magenta="45;97m""
set  "_White="40;37m""
set  "_Green="40;92m""
set "_Yellow="40;93m""
) else (
set     "Red="Red" "white""
set    "Gray="Darkgray" "white""
set   "Green="DarkGreen" "white""
set "Magenta="Darkmagenta" "white""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :dk_color %Red% "==== ERROR ====" &echo:"
if %~z0 GEQ 500000 (set "_exitmsg=Go back") else (set "_exitmsg=Exit")

::========================================================================================================================================

if %winbuild% LSS 10240 (
%eline%
echo Unsupported OS version detected.
echo Project is supported for Windows 10/11.
goto dk_done
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo Unable to find powershell.exe in the system.
goto dk_done
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_ttemp=%temp%"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_batf!" | find /i "!_ttemp!" 1>nul && (
if /i not "!_work!"=="!_ttemp!" (
%eline%
echo Script is launched from the temp folder,
echo Most likely you are running the script directly from the archive file.
echo:
echo Extract the archive file and launch the script from the extracted folder.
goto dk_done
)
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

%nul% reg query HKU\S-1-5-19 || (
if not defined _elev %nul% %psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
%eline%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'.
goto dk_done
)

::========================================================================================================================================

:dl_menu

:: Lockbox method is not shown in menu because it's working method is not very clean. We don't suggest to run it on a production system.
:: Will enable it back when we have a better method for it. Till then, if you want to use Lockbox, you can use parameters, check at the top.

REM if %_unattended%==0 (
REM cls
REM mode 76, 25
REM title  HWID Activation

REM echo:
REM echo:
REM echo:
REM echo:
REM echo         ____________________________________________________________
REM echo:
REM if !_lock!==0 (
REM echo                 [1] HWID Activation
REM ) else (
REM call :dk_color2 %_White% "                [1] HWID Activation       " %_Yellow% "  [LockBox Method]"
REM )
REM echo                 ____________________________________________
REM echo:
REM if !_lock!==0 (
REM echo                 [G] Generate Ticket
REM ) else (
REM call :dk_color2 %_White% "                [G] Generate Ticket       " %_Yellow% "  [LockBox Method]"
REM )
REM echo                 ____________________________________________
REM echo:      
REM echo                 [C] Change Method
REM echo:
REM echo                 [0] %_exitmsg%
REM echo         ____________________________________________________________
REM echo: 
REM call :dk_color2 %_White% "              " %_Green% "Enter a menu option in the Keyboard:"
REM choice /C:1GC0 /N
REM set _el=!errorlevel!
REM if !_el!==4  exit /b
REM if !_el!==3  (
REM if !_lock!==0 (
REM set _lock=1
REM ) else (
REM set _lock=0
REM )
REM cls
REM echo:
REM call :dk_color %_Green% " Downlevel Method:"
REM echo  It creates downlevelGTkey ticket for activation with simplest process.
REM echo:
REM call :dk_color %_Yellow% " LockBox Method:"
REM echo  It creates clientLockboxKey ticket which better mimics genuine activation,
REM echo  But requires more steps such as,
REM echo  - Cleaning ClipSVC licences
REM echo  - Deleting a volatile and protected registry key by taking ownership
REM echo  - System may need a restart for succesful activation
REM echo  - Microsoft Account and Store Apps may need relogin-restart in the system
REM echo:
REM call :dk_color2 %_White% " " %Green% "Note:"
REM echo  Microsoft accepts both types of tickets and that's unlikely to change.
REM call :dk_color2 %_White% " " %Green% "On a production system we suggest to use Downlevel [default] Method only."
REM echo:
REM call :dk_color %_Yellow% " Press any key to go back..."
REM pause >nul
REM goto :dl_menu
REM )
REM if !_el!==2  set _gent=1&goto :dl_menu2
REM if !_el!==1  goto :dl_menu2
REM goto :dl_menu
REM )

:dl_menu2

cls
mode 102, 34
if %_gent%==1 (set _title=title  Generate HWID GenuineTicket.xml) else (set _title=title  HWID Activation)
if %_lock%==0 (%_title%) else (%_title% [Lockbox Method])

::========================================================================================================================================

if %_gent%==1 if exist %Systemdrive%\GenuineTicket.xml (
set _gent=0
%eline%
echo File '%Systemdrive%\GenuineTicket.xml' already exist.
if %_unattended%==0 (
echo:
call :dk_color %_Yellow% "Press any key to go back..."
pause >nul
goto dl_menu
) else (
goto dk_done
)
)

::========================================================================================================================================

call :dk_initial

::  Check if system is permanently activated or not

cls
call :dk_product
call :dk_checkperm
if defined _perm if not %_gent%==1 (
echo ___________________________________________________________________________________________
echo:
call :dk_color2 %_White% "     " %Green% "Checking: %winos% is Permanently Activated."
call :dk_color2 %_White% "     " %Gray% "Activation is not required."
echo ___________________________________________________________________________________________
if %_unattended%==1 goto dk_done
echo:
choice /C:12 /N /M ">    [1] Activate [2] %_exitmsg% : "
if errorlevel 2 exit /b
)
cls

::========================================================================================================================================

::  Check Evaluation version

set _eval=
set _evalserv=

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-*EvalEdition~*.mum" set _eval=1
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*EvalEdition~*.mum" set _evalserv=1
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*EvalCorEdition~*.mum" set _eval=1 & set _evalserv=1

if defined _eval (
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID 2>nul | find /i "Eval" 1>nul && (
%eline%
echo [%winos% ^| %winbuild%]
if defined _evalserv (
echo Server Evaluation cannot be activated. Convert it to full Server OS.
echo:
echo Check 'Change Edition Option' in Extras section in MAS.
) else (
echo Evaluation Editions cannot be activated. Download ^& Install full version of Windows OS.
echo:
echo https://massgrave.dev/
)
goto dk_done
)
)

::========================================================================================================================================

::  Check SKU value / Check in multiple places to find Edition change corruption

set osSKU=
set regSKU=
set wmiSKU=

for /f "tokens=3 delims=." %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\ProductOptions" /v OSProductPfn 2^>nul') do set "regSKU=%%a"
if %_wmic% EQU 1 for /f "tokens=2 delims==" %%a in ('"wmic Path Win32_OperatingSystem Get OperatingSystemSKU /format:LIST" 2^>nul') do if not errorlevel 1 set "wmiSKU=%%a"
if %_wmic% EQU 0 for /f "tokens=1" %%a in ('%psc% "([WMI]'Win32_OperatingSystem=@').OperatingSystemSKU" 2^>nul') do if not errorlevel 1 set "wmiSKU=%%a"

set osSKU=%wmiSKU%
if not defined osSKU set osSKU=%regSKU%

if not defined osSKU (
%eline%
echo SKU value was not detected properly. Aborting...
goto dk_done
)

::========================================================================================================================================

::  Check if HWID key (Retail,OEM,MAK) is already installed or not

set _hwidk=
call :dk_channel
for %%A in (Retail OEM:SLP OEM:NONSLP OEM:DM Volume:MAK) do (if /i "%%A"=="%_channel%" set _hwidk=1)

::========================================================================================================================================

::  Detect Key

set app=
set key=
set pkey=
set altkey=
set changekey=
set curedition=
set altedition=
set notworking=

if defined applist call :hwiddata attempt1
if not defined key call :hwiddata attempt2
if defined notworking call :hwidfallback

if defined altkey (set key=%altkey%&set changekey=1&set notworking=)

set pkey=
if not defined key call :dk_hwidkey %nul%

::========================================================================================================================================

if not defined key if not defined _hwidk (
%eline%
%psc% $ExecutionContext.SessionState.LanguageMode 2>nul | find /i "Full" 1>nul || (
echo PowerShell is not responding properly. Aborting...
goto dk_done
)
echo [%winos% ^| %winbuild% ^| SKU:%osSKU%]
echo Unable to find this product in the supported product list.
echo Make sure you are using updated version of the script.
echo:
if not "%regSKU%"=="%wmiSKU%" (
echo Difference Found In SKU Value- WMI:%wmiSKU% Reg:%regSKU%
echo Restart the system and try again.
goto dk_done
)
goto dk_done
)

::========================================================================================================================================

set error=
set activ=

::  Check Internet connection

cls
echo:
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set arch=%%b
echo Checking OS Info                        [%winos% ^| %winbuild% ^| %arch%]

set _intcon=
if not %_gent%==1 (
for /f "delims=[] tokens=2" %%# in ('ping -n 1 licensing.mp.microsoft.com') do if not [%%#]==[] set _intcon=1
if defined _intcon (
echo Checking Internet Connection            [Connected]
) else (
set error=1
call :dk_color %Red% "Checking Internet Connection            [Failed To Connect licensing.mp.microsoft.com]"
)
)

::========================================================================================================================================

set "_serv=ClipSVC wlidsvc sppsvc LicenseManager Winmgmt wuauserv"

::  Client License Service (ClipSVC)
::  Microsoft Account Sign-in Assistant
::  Software Protection
::  Windows License Manager Service
::  Windows Management Instrumentation
::  Windows Update

::  Check disabled services

set serv_ste=
for %%# in (%_serv%) do (
set serv_dis=
reg query HKLM\SYSTEM\CurrentControlSet\Services\%%# /v Start %nul% || set serv_dis=1
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\%%# /v Start 2^>nul') do if /i %%b equ 0x4 set serv_dis=1
if defined serv_dis (if defined serv_ste (set "serv_ste=!serv_ste! %%#") else (set "serv_ste=%%#"))
)

::  Change disabled services startup type to default

set serv_csts=
set serv_cste=

if defined serv_ste (
for %%# in (%serv_ste%) do (
if /i %%#==ClipSVC        sc config %%# start= demand %nul%
if /i %%#==wlidsvc        sc config %%# start= demand %nul%
if /i %%#==sppsvc         sc config %%# start= delayed-auto %nul%
if /i %%#==LicenseManager sc config %%# start= demand %nul%
if /i %%#==Winmgmt        sc config %%# start= auto %nul%
if /i %%#==wuauserv       sc config %%# start= demand %nul%
if !errorlevel!==0 (
if defined serv_csts (set "serv_csts=!serv_csts! %%#") else (set "serv_csts=%%#")
) else (
set error=1
if defined serv_cste (set "serv_cste=!serv_cste! %%#") else (set "serv_cste=%%#")
)
)
)

if defined serv_csts echo Enabling Disabled Services              [Successful] [%serv_csts%]
if defined serv_cste call :dk_color %Red% "Enabling Disabled Services              [Failed] [%serv_cste%]"

if not "%regSKU%"=="%wmiSKU%" (
set error=1
call :dk_color %Red% "Checking WMI/REG SKU                    [Difference Found - WMI:%wmiSKU% Reg:%regSKU%] [Restart System]"
)

::========================================================================================================================================

::  Install key

echo:
if defined changekey (
call :dk_color %Magenta% "[%altedition%] Edition product key will be used to enable HWID activation."
echo:
)

set _partial=
if not defined key (
if %_wmic% EQU 1 for /f "tokens=2 delims==" %%# in ('wmic path SoftwareLicensingProduct where "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' and PartialProductKey<>null" Get PartialProductKey /value 2^>nul') do set "_partial=%%#"
if %_wmic% EQU 0 for /f "tokens=2 delims==" %%# in ('%psc% "(([WMISEARCHER]'SELECT PartialProductKey FROM SoftwareLicensingProduct WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f'' AND PartialProductKey IS NOT NULL').Get()).PartialProductKey | %% {echo ('PartialProductKey='+$_)}" 2^>nul') do set "_partial=%%#"
call echo Checking Installed Product Key          [Partial Key - %%_partial%%] [%_channel%]
)

set _channel=
set error_code=
if defined key (
if %_wmic% EQU 1 wmic path SoftwareLicensingService where __CLASS='SoftwareLicensingService' call InstallProductKey ProductKey="%key%" %nul%
if %_wmic% EQU 0 %psc% "(([WMISEARCHER]'SELECT Version FROM SoftwareLicensingService').Get()).InstallProductKey('%key%')" %nul%
if not !errorlevel!==0 cscript //nologo %windir%\system32\slmgr.vbs /ipk %key% %nul%
set error_code=!errorlevel!
cmd /c exit /b !error_code!
if !error_code! NEQ 0 set "error_code=[0x!=ExitCode!]"

if !error_code! EQU 0 (
call :dk_refresh
call :dk_channel
call echo Installing Generic Product Key          [%key%] [%%_channel%%] [Successful]
) else (
call :dk_color %Red% "Installing Generic Product Key          [%key%] [Failed] !error_code!"
)
)

::========================================================================================================================================

::  Files are copied to temp to generate ticket to avoid possible issues in case the path contains special character or non English names

echo:
set "temp_=%SystemRoot%\Temp\_Temp"
if exist "%temp_%\.*" rmdir /s /q "%temp_%\" %nul%
md "%temp_%\" %nul%

pushd "%temp_%\"
setlocal
set "TMP=%SystemRoot%\Temp"
set "TEMP=%SystemRoot%\Temp"
%nul% %psc% "$b=[IO.File]::ReadAllText('!_batp!')-split'[:]batfile[:].*';iex $b[1]; B 1"
endlocal
popd

if not exist "%temp_%\gatherosstate.exe" (
call :dk_color %Red% "Extracting Required Files to Temp       [%temp_%] [Failed]"
call :dk_color %Magenta% "Most likely Antivirus is interfering with the process"
call :dk_color %Magenta% "Use MAS separate files version"
goto :dl_final
)

for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "%temp_%\gatherosstate.exe" SHA1^|findstr /i /v CertUtil') do set "hash_g=%%#"
set "hash_g=%hash_g: =%"
if /i not "%hash_g%"=="FABB5A0FC1E6A372219711152291339AF36ED0B5" (
call :dk_color %Red% "Extracted files verification failed. Aborting..."
goto :dl_final
)

echo Extracting Required Files to Temp       [%temp_%] [Successful]

::========================================================================================================================================

::  Modify gatherosstate.exe

pushd "%temp_%\"
%nul% %psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':hex\:.*';iex ($f[1]);"
popd

if not exist "%temp_%\gatherosstatemodified.exe" (
call :dk_color %Red% "Creating Modified Gatherosstate         [Failed] Aborting..."
goto :dl_final
)

set _hash=
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "%temp_%\gatherosstatemodified.exe" SHA1^|findstr /i /v CertUtil') do set "_hash=%%#"
set "_hash=%_hash: =%"

if /i not "%_hash%"=="3FCCB9C359EDB9527C9F5688683F8B3C5910E75D" (
call :dk_color %Red% "Creating Modified Gatherosstate         [Failed] [Hash Not Matched] Aborting..."
goto :dl_final
) else (
echo Creating Modified Gatherosstate         [Successful]
)

::========================================================================================================================================

::  Clean ClipSVC Licences
::  This code runs only if Lockbox method to generate ticket is manually set by the user in this script.

if %_lock%==1 (
for %%# in (ClipSVC) do (
sc query %%# | find /i "STOPPED" %nul% || net stop %%# /y %nul%
sc query %%# | find /i "STOPPED" %nul% || sc stop %%# %nul%
)

rundll32 clipc.dll,ClipCleanUpState

if exist "%ProgramData%\Microsoft\Windows\ClipSVC\*.dat" del /f /q "%ProgramData%\Microsoft\Windows\ClipSVC\*.dat" %nul%

if exist "%ProgramData%\Microsoft\Windows\ClipSVC\tokens.dat" (
call :dk_color %Red% "Cleaning ClipSVC Licences               [Failed]"
) else (
echo Cleaning ClipSVC Licences               [Successful]
)
)

::========================================================================================================================================

::  Below registry key (Volatile & Protected) gets created after the ClipSVC License cleanup command, and gets automatically deleted after 
::  system restart. It needs to be deleted to activate the system without restart.

::  This code runs only if Lockbox method to generate ticket is manually set by the user in this script.

set "RegKey=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState"
set "_ident=HKU\S-1-5-19\SOFTWARE\Microsoft\IdentityCRL"

if %_lock%==1 (
%nul% call :regown "%RegKey%"
reg delete "%RegKey%" /f %nul% 

reg query "%RegKey%" %nul% && (
call :dk_color %Red% "Deleting a Volatile Registry            [Failed]"
call :dk_color %Magenta% "Restart the system, that will delete this registry key automatically"
) || (
echo Deleting a Volatile Registry            [Successful]
)

REM Clear HWID token related registry to fix activation incase if there is any corruption

reg delete "%_ident%" /f %nul%
reg query "%_ident%" %nul% && (
call :dk_color %Red% "Deleting a Registry                     [Failed] [%_ident%]"
) || (
echo Deleting a Registry                     [Successful] [%_ident%]
)
)

::========================================================================================================================================

::  Multiple attempts to generate the ticket because in some cases, one attempt is not enough.

echo:
set "_noxml=if not exist "%temp_%\GenuineTicket.xml""

set pfn=
for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\ProductOptions" /v OSProductPfn 2^>nul') do set "pfn=%%a"

"%temp_%/gatherosstatemodified.exe" Pfn=%pfn%;DownlevelGenuineState=1
%_noxml% timeout /t 3 %nul%
%_noxml% net stop sppsvc /y %nul%
%_noxml% call "%temp_%/gatherosstatemodified.exe" Pfn=%pfn%;DownlevelGenuineState=1
%_noxml% timeout /t 3 %nul%

::  Refresh ClipSVC (required after cleanup) with below command, not related to generating tickets

if %_lock%==1 (
for %%# in (wlidsvc LicenseManager sppsvc) do (net stop %%# /y %nul% & net start %%# /y %nul%)
call :dk_refresh
)

%_noxml% (
call :dk_color %Red% "Generating GenuineTicket.xml            [Failed] [%pfn%]"
goto :dl_final
)

if %_lock%==1 (
find /i "clientLockboxKey" "%temp_%\GenuineTicket.xml" >nul && (
echo Generating GenuineTicket.xml            [Successful] [%pfn%]
) || (
call :dk_color %Red% "Generating GenuineTicket.xml            [Failed] [%pfn%]"
call :dk_color %Red% "downlevelGTkey Ticket created. Aborting..."
goto :dl_final
)
) else (
echo Generating GenuineTicket.xml            [Successful] [%pfn%]
)

::========================================================================================================================================

::  Copy GenuineTicket.xml to the root of C drive and exit if ticket generation option was used in script

if %_gent%==1 (
echo:
copy /y /b "%temp_%\GenuineTicket.xml" "%Systemdrive%\GenuineTicket.xml" %nul%
if not exist "%Systemdrive%\GenuineTicket.xml" (
call :dk_color %Red% "Copying GenuineTicket.xml to %Systemdrive%\        [Failed]"
) else (
call :dk_color %Green% "Copying GenuineTicket.xml to %Systemdrive%\        [Successful]"
)
goto :dl_final
)

::========================================================================================================================================

::  clipup -v -o -altto <path> & clipup -v -o both methods may fail if the username have spaces/special characters/non English names
::  Most correct way to apply a ticket is by restarting ClipSVC service but we can not check the log details in this way
::  To get the log details and also to correctly apply ticket, script will install tickets two times (service restart + clipup -v -o -altto <path>)

set "tdir=%ProgramData%\Microsoft\Windows\ClipSVC\GenuineTicket"
if exist "%tdir%\*.xml" del /f /q "%tdir%\*.xml" %nul%
if not exist "%tdir%\" md "%tdir%\" %nul%
copy /y /b "%temp_%\GenuineTicket.xml" "%tdir%\GenuineTicket.xml" %nul%

if not exist "%tdir%\GenuineTicket.xml" (
call :dk_color %Red% "Copying Ticket to ClipSVC Location      [Failed]"
)

set "_xmlexist=if exist "%tdir%\GenuineTicket.xml""

%_xmlexist% (
net stop ClipSVC /y %nul%
net start ClipSVC /y %nul%
%_xmlexist% timeout /t 2 %nul%
%_xmlexist% timeout /t 2 %nul%

%_xmlexist% (
if exist "%tdir%\*.xml" del /f /q "%tdir%\*.xml" %nul%
call :dk_color %Red% "Installing GenuineTicket.xml            [Failed With ClipSVC Service Restart Method]"
)
)

clipup -v -o -altto %temp_%\

::==========================================================================================================================================

call :dk_product

echo:
echo Activating...
echo:

call :dk_act
call :dk_checkperm
if defined _perm (
set activ=1
call :dk_color %Green% "%winos% is permanently activated."
goto :dl_final
)

::  Refresh some services and license status

if %_lock%==1 set _retry=1
if defined _intcon set _retry=1

if defined _retry (
for %%# in (wlidsvc LicenseManager sppsvc) do (net stop %%# /y %nul% & net start %%# /y %nul%)
call :dk_refresh
call :dk_act
)

call :dk_checkperm

set "_unsup=call :dk_color %Magenta% "At the time of writing this, HWID Activation was not supported for this product.""

if defined _perm (
set activ=1
call :dk_color %Green% "%winos% is permanently activated."
) else (
call :dk_color %Red% "Activation Failed %error_code%"
if defined key if defined pkey %_unsup%
if not defined key             %_unsup%
if defined notworking          %_unsup%
if not defined notworking if defined key if not defined pkey call :dk_color %Magenta% "Restart the system and try again / Check troubleshooting steps in MAS Extras option"
)

::========================================================================================================================================

:dl_final

echo:
if exist "%temp_%\.*" rmdir /s /q "%temp_%\" %nul%
if exist "%temp_%\" (
call :dk_color %Red% "Cleaning Temp Files                     [Failed]"
) else (
echo Cleaning Temp Files                     [Successful]
)

if %osSKU%==175 (
call :dk_color %Red% "ServerRdsh Editon does not officially support activation on non-azure platforms."
)

if not defined activ call :dk_checkerrors

if not defined activ if not defined error (
echo Basic Diagnostic Tests                  [Error Not Found]
)

goto :dk_done

::========================================================================================================================================

::  A lean and mean snippet to set registry ownership and permission recursively
::  Written by @AveYo aka @BAU
::  pastebin.com/XTPt0JSC

::  Modified by @abbodi1406 to make it work in ARM64 Windows 10 (builds older than 21277) where only x86 version of Powershell is installed.

::  This code runs only if Lockbox method is manually set by the user in this script.

:regown

pushd "!_work!"
setlocal DisableDelayedExpansion

set "0=%~nx0"&%psc% $A='%~1','%~2','%~3','%~4','%~5','%~6';iex(([io.file]::ReadAllText($env:0)-split':Own1\:.*')[1])&popd&setlocal EnableDelayedExpansion&exit/b:Own1:
$D1=[uri].module.gettype('System.Diagnostics.Process')."GetM`ethods"(42) |where {$_.Name -eq 'SetPrivilege'} #`:no-ev-warn
'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege'|foreach {$D1.Invoke($null, @("$_",2))}
$path=$A[0]; $rk=$path-split'\\',2; switch -regex ($rk[0]){'[mM]'{$hv=2147483650};'[uU]'{$hv=2147483649};default{$hv=2147483648};}
$HK=[Microsoft.Win32.RegistryKey]::OpenBaseKey($hv, 256); $s=$A[1]; $sps=[Security.Principal.SecurityIdentifier]
$u=($A[2],'S-1-5-32-544')[!$A[2]];$o=($A[3],$u)[!$A[3]];$w=$u,$o |% {new-object $sps($_)}; $old=!$A[3];$own=!$old; $y=$s-eq'all'
$rar=new-object Security.AccessControl.RegistryAccessRule( $w[0], ($A[5],'FullControl')[!$A[5]], 1, 0, ($A[4],'Allow')[!$A[4]] )
$x=$s-eq'none';function Own1($k){$t=$HK.OpenSubKey($k,2,'TakeOwnership');if($t){0,4|%{try{$o=$t.GetAccessControl($_)}catch{$old=0}
};if($old){$own=1;$w[1]=$o.GetOwner($sps)};$o.SetOwner($w[0]);$t.SetAccessControl($o); $c=$HK.OpenSubKey($k,2,'ChangePermissions')
$p=$c.GetAccessControl(2);if($y){$p.SetAccessRuleProtection(1,1)};$p.ResetAccessRule($rar);if($x){$p.RemoveAccessRuleAll($rar)}
$c.SetAccessControl($p);if($own){$o.SetOwner($w[1]);$t.SetAccessControl($o)};if($s){$($subkeys=$HK.OpenSubKey($k).GetSubKeyNames()) 2>$null;
foreach($n in $subkeys){Own1 "$k\$n"}}}};Own1 $rk[1];if($env:VO){get-acl Registry::$path|fl} #:Own1: lean & mean snippet by AveYo

::========================================================================================================================================

::  Get Windows permanent activation status

:dk_checkperm

if %_wmic% EQU 1 wmic path SoftwareLicensingProduct where (LicenseStatus='1' and GracePeriodRemaining='0' and PartialProductKey is not NULL) get Name /value 2>nul | findstr /i "Windows" 1>nul && set _perm=1||set _perm=
if %_wmic% EQU 0 %psc% "(([WMISEARCHER]'SELECT Name FROM SoftwareLicensingProduct WHERE LicenseStatus=1 AND GracePeriodRemaining=0 AND PartialProductKey IS NOT NULL').Get()).Name | %% {echo ('Name='+$_)}" 2>nul | findstr /i "Windows" 1>nul && set _perm=1||set _perm=
exit /b

::  Refresh license status

:dk_refresh

if %_wmic% EQU 1 wmic path SoftwareLicensingService where __CLASS='SoftwareLicensingService' call RefreshLicenseStatus %nul%
if %_wmic% EQU 0 %psc% "$null=(([WMICLASS]'SoftwareLicensingService').GetInstances()).RefreshLicenseStatus()" %nul%
exit /b

::  Get Windows installed key channel

:dk_channel

if %_wmic% EQU 1 for /f "tokens=2 delims==" %%# in ('wmic path SoftwareLicensingProduct where "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' and PartialProductKey<>null" Get ProductKeyChannel /value 2^>nul') do set "_channel=%%#"
if %_wmic% EQU 0 for /f "tokens=2 delims==" %%# in ('%psc% "(([WMISEARCHER]'SELECT ProductKeyChannel FROM SoftwareLicensingProduct WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f'' AND PartialProductKey IS NOT NULL').Get()).ProductKeyChannel | %% {echo ('ProductKeyChannel='+$_)}" 2^>nul') do set "_channel=%%#"
exit /b

::  Activation command

:dk_act

set error_code=
if %_wmic% EQU 1 wmic path SoftwareLicensingProduct where "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' and PartialProductKey<>null" call Activate %nul%
if %_wmic% EQU 0 %psc% "(([WMISEARCHER]'SELECT ID FROM SoftwareLicensingProduct WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f'' AND PartialProductKey IS NOT NULL').Get()).Activate()" %nul%
if not %errorlevel%==0 cscript //nologo %windir%\system32\slmgr.vbs /ato %nul%
set error_code=%errorlevel%
cmd /c exit /b %error_code%
if %error_code% NEQ 0 (set "error_code=[Error Code: 0x%=ExitCode%]") else (set error_code=)
exit /b

::  Get Windows Activation IDs

:dk_actids

set applist=
if %_wmic% EQU 1 set "chkapp=for /f "tokens=2 delims==" %%a in ('"wmic path SoftwareLicensingProduct where (ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f') get ID /VALUE" 2^>nul')"
if %_wmic% EQU 0 set "chkapp=for /f "tokens=2 delims==" %%a in ('%psc% "(([WMISEARCHER]'SELECT ID FROM SoftwareLicensingProduct WHERE ApplicationID=''55c92734-d682-4d71-983e-d6ec3f16059f''').Get()).ID ^| %% {echo ('ID='+$_)}" 2^>nul')"
%chkapp% do (if defined applist (call set "applist=!applist! %%a") else (call set "applist=%%a"))
exit /b

::  Get Product name (WMI/REG methods are not reliable in all conditions, hence winbrand.dll method is used)

:dk_product

set winos=
set d1=[DllImport(\"winbrand\",CharSet=CharSet.Unicode)]public static extern string BrandingFormatString(string s);
set d2=$AP=Add-Type -Member '%d1%' -Name D1 -PassThru; $AP::BrandingFormatString('%%WINDOWS_LONG%%')
for /f "delims=" %%s in ('"%psc% %d2%"') do if not errorlevel 1 (set winos=%%s)
echo "%winos%" | find /i "Windows" 1>nul || (
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "winos=%%b"
if %winbuild% GEQ 22000 (
set winos=!winos:Windows 10=Windows 11!
)
)
exit /b

::  Check wmic.exe

:dk_ckeckwmic

set _wmic=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "computersystem" 1>nul && set _wmic=1
)
exit /b

:dk_initial

echo:
echo Initializing...

::  Check and enable WinMgmt, sppsvc services if required

for %%# in (WinMgmt sppsvc) do (
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\%%# /v Start 2^>nul') do if /i %%b NEQ 0x2 (
echo:
echo Enabling %%# service...
if /i %%#==sppsvc  sc config %%# start= delayed-auto %nul% || echo Failed
if /i %%#==WinMgmt sc config %%# start= auto %nul% || echo Failed
)
sc start %%# %nul%
if !errorlevel! NEQ 1056 if !errorlevel! NEQ 0 (
echo:
echo Starting %%# service...
sc start %%#
echo:
call :dk_color %Red% "Failed to start [%%#] service, rest of the process may take a long time..."
)
)

::  Check WMI and SPP Errors

call :dk_ckeckwmic

set e_wmi=
set e_wmispp=
call :dk_actids

if not defined applist (
net stop sppsvc /y %nul%
cscript //nologo %windir%\system32\slmgr.vbs /rilc %nul%
if !errorlevel! NEQ 0 cscript //nologo %windir%\system32\slmgr.vbs /rilc %nul%
call :dk_refresh

if %_wmic% EQU 1 wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "computersystem" 1>nul
if %_wmic% EQU 0 %psc% "Get-CIMInstance -Class Win32_ComputerSystem | Select-Object -Property CreationClassName" 2>nul | find /i "computersystem" 1>nul
if !errorlevel! NEQ 0 set e_wmi=1

if defined e_wmi (set e_wmispp=WMI, SPP) else (set e_wmispp=SPP)
call :dk_actids
)
exit /b

::========================================================================================================================================

::  Get Product Key from pkeyhelper.dll for future new editions
::  It works on Windows 10 1803 (17134) and later builds. (Partially on 1803 & 1809, fully on 1903 and later)

:dk_pkey

set pkey=
set d1=[DllImport(\"pkeyhelper.dll\",CharSet=CharSet.Unicode)]public static extern int SkuGetProductKeyForEdition(int e, string c, out string k, out string p);
set d2=$AP=Add-Type -Member '%d1%' -Name D1 -PassThru; $k=''; $null=$AP::SkuGetProductKeyForEdition(%1, %2, [ref]$k, [ref]$null); $k
for /f %%a in ('%psc% "%d2%"') do if not errorlevel 1 (set pkey=%%a)
exit /b

::  Get channel name for the key which was extracted from pkeyhelper.dll

:dk_pkeychannel

set k=%1
set pkeychannel=
set p=%SystemRoot%\System32\spp\tokens\pkeyconfig\pkeyconfig.xrm-ms
set m=[System.Runtime.InteropServices.Marshal]
set d1=[DllImport(\"PidGenX.dll\",CharSet=CharSet.Unicode)]public static extern int PidGenX(string k,string p,string m,int u,IntPtr i,IntPtr d,IntPtr f);
set d2=$AP=Add-Type -Member '%d1%' -Name D1 -PassThru; $k='%k%'; $p='%p%'; $r=[byte[]]::new(0x04F8); $r[0]=0xF8; $r[1]=0x04; $f=%m%::AllocHGlobal(1272); %m%::Copy($r,0,$f,1272);
set d3=%d2% [void]$AP::PidGenX($k,$p,\"00000\",0,0,0,$f); %m%::Copy($f,$r,0,1272); %m%::FreeHGlobal($f); [System.Text.Encoding]::Unicode.GetString($r, 1016, 128).Replace('0','')
for /f %%a in ('%psc% "%d3%"') do if not errorlevel 1 (set pkeychannel=%%a)
exit /b

:dk_hwidkey

for %%# in (pkeyhelper.dll) do @if "%%~$PATH:#"=="" exit /b
for %%# in (Retail OEM:NONSLP OEM:DM Volume:MAK) do (
call :dk_pkey %osSKU% '%%#'
if defined pkey call :dk_pkeychannel !pkey!
if /i [!pkeychannel!]==[%%#] (
set key=!pkey!
exit /b
)
)
exit /b

::========================================================================================================================================

:dk_checkerrors

::  Check if the services are able to run or not
::  Workarounds are added to get correct status and error code because sc query doesn't output correct results in some conditions

set serv_e=
for %%# in (%_serv%) do (
set errorcode=
set checkerror=
sc query %%# | find /i ": 4  RUNNING" %nul% || net start %%# /y %nul%
sc start %%# %nul%
set errorcode=!errorlevel!
if !errorcode! NEQ 1056 if !errorcode! NEQ 0 set checkerror=1
sc query %%# | find /i ": 4  RUNNING" %nul% || set checkerror=1
if defined checkerror if defined serv_e (set "serv_e=!serv_e!, %%#-!errorcode!") else (set "serv_e=%%#-!errorcode!")
)

if defined serv_e (
set error=1
call :dk_color %Red% "Starting Services                       [Failed] [%serv_e%]"
)

::  Various error checks

set token=0
if exist %Systemdrive%\Windows\System32\spp\store\2.0\tokens.dat set token=1
if exist %Systemdrive%\Windows\System32\spp\store_test\2.0\tokens.dat set token=1
if %token%==0 (
set error=1
call :dk_color %Red% "Checking SPP tokens.dat                 [Not Found]"
)

DISM /English /Online /Get-CurrentEdition %nul%
set error_code=%errorlevel%
cmd /c exit /b %error_code%
if %error_code% NEQ 0 set "error_code=[0x%=ExitCode%]"
if %error_code% NEQ 0 (
set error=1
call :dk_color %Red% "Checking DISM                           [Not Responding] %error_code%"
)

%psc% $ExecutionContext.SessionState.LanguageMode 2>nul | find /i "Full" 1>nul || (
set error=1
call :dk_color %Red% "Checking Powershell                     [Not Responding]"
)

for %%# in (wmic.exe) do @if "%%~$PATH:#"=="" (
set error=1
call :dk_color %Gray% "Checking WMIC.exe                       [Not Found]"
)

reg query "HKU\S-1-5-20\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\PersistedTSReArmed" %nul% && (
set error=1
call :dk_color %Red% "Checking Rearm                          [System Restart Is Required]"
)

reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ClipSVC\Volatile\PersistedSystemState" %nul% && (
set error=1
call :dk_color %Red% "Checking ClipSVC                        [System Restart Is Required]"
)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "SkipRearm" 2^>nul') do if /i %%b NEQ 0x0 (
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "SkipRearm" /t REG_DWORD /d "0" /f %nul%
call :dk_color %Red% "Checking SkipRearm                      [Default 0 Value Not Found, Changing To 0]"
net stop sppsvc /y %nul%
net start sppsvc /y %nul%
set error=1
)

set _wsh=1
reg query "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _wsh=0)
reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _wsh=0)
if %_wsh% EQU 0 (
set error=1
call :dk_color %Gray% "Checking Windows Script Host            [Disabled]"
)

cscript //nologo %windir%\system32\slmgr.vbs /dlv %nul%
set error_code=%errorlevel%
cmd /c exit /b %error_code%
if %error_code% NEQ 0 set "error_code=[0x%=ExitCode%]"
if %error_code% NEQ 0 (
set error=1
call :dk_color %Red% "Checking slmgr /dlv                     [Not Responding] %error_code%"
)

if not defined applist (
set error=1
call :dk_color %Red% "Checking WMI/SPP                        [Not Responding] [%e_wmispp%]"
)

set nil=
set _sppint=
if not %_gent%==1 if not defined error (
for %%# in (SppE%nil%xtComObj.exe,sppsvc.exe) do (
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ima%nil%ge File Execu%nil%tion Options\%%#" %nul% && set _sppint=1
)
)

if defined _sppint (
call :dk_color %Red% "Checking SPP Interference In IFEO       [Found] [Uninstall KMS Activator If There Is Any]"
set error=1
)
exit /b

::========================================================================================================================================

:dk_color

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3'
)
exit /b

:dk_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3' -NoNewline; write-host -back '%4' -fore '%5' '%6'
)
exit /b

::========================================================================================================================================

:dk_done

echo:
if %_unattended%==1 timeout /t 2 & exit /b
call :dk_color %_Yellow% "Press any key to %_exitmsg%..."
pause >nul
exit /b

::========================================================================================================================================

::  1st column = Activation ID
::  2nd column = Generic Retail/OEM/MAK Key
::  3rd column = SKU ID
::  4th column = 1 = activation is not working (at the time of writing this), 0 = activation is working
::  5th column = Key Type
::  6th column = WMI Edition ID
::  7th column = Version name incase same Edition ID is used in different OS versions with different key
::  Separator  = _

::  Key preference is in the following order. Retail > OEM:NONSLP > OEM:DM > Volume:MAK


:hwiddata

for %%# in (
8b351c9c-f398-4515-9900-09df49427262_XGVPP-NMH47-7TTHJ-W3FW7-8HV2C___4_0_OEM:NONSLP_Enterprise
23505d51-32d6-41f0-8ca7-e78ad0f16e71_D6RD9-D4N8T-RT9QX-YW6YT-FCWWJ__11_1_____Retail_Starter
c83cef07-6b72-4bbc-a28f-a00386872839_3V6Q6-NQXCX-V8YXR-9QCYV-QPFCT__27_0_Volume:MAK_EnterpriseN
211b80cc-7f64-482c-89e9-4ba21ff827ad_3NFXW-2T27M-2BDW6-4GHRV-68XRX__47_1_____Retail_StarterN
4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c_VK7JG-NPHTM-C97JM-9MPGT-3V66T__48_0_____Retail_Professional
9fbaf5d6-4d83-4422-870d-fdda6e5858aa_2B87N-8KFHP-DKV6R-Y2C8J-PKCKT__49_0_____Retail_ProfessionalN
f742e4ff-909d-4fe9-aacb-3231d24a0c58_4CPRK-NM3K3-X6XXQ-RXX86-WXCHW__98_0_____Retail_CoreN
1d1bac85-7365-4fea-949a-96978ec91ae0_N2434-X9D7W-8PF6X-8DV9T-8TYMD__99_0_____Retail_CoreCountrySpecific
3ae2cc14-ab2d-41f4-972f-5e20142771dc_BT79Q-G7N6G-PGBYW-4YWX6-6F4BT_100_0_____Retail_CoreSingleLanguage
2b1f36bb-c1cd-4306-bf5c-a0367c2d97d8_YTMG3-N6DKC-DKB77-7M9GH-8HVX7_101_0_____Retail_Core
2a6137f3-75c0-4f26-8e3e-d83d802865a4_XKCNC-J26Q9-KFHD2-FKTHY-KD72Y_119_0_OEM:NONSLP_PPIPro
e558417a-5123-4f6f-91e7-385c1c7ca9d4_YNMGQ-8RYV3-4PGQ3-C8XTP-7CFBY_121_0_____Retail_Education
c5198a66-e435-4432-89cf-ec777c9d0352_84NGF-MHBT6-FXBX8-QWJK7-DRR8H_122_0_____Retail_EducationN
cce9d2de-98ee-4ce2-8113-222620c64a27_KCNVH-YKWX8-GJJB9-H9FDT-6F7W2_125_1_Volume:MAK_EnterpriseS_2021
d06934ee-5448-4fd1-964a-cd077618aa06_43TBQ-NH92J-XKTM7-KT3KK-P39PB_125_0_OEM:NONSLP_EnterpriseS_2019
706e0cfd-23f4-43bb-a9af-1a492b9f1302_NK96Y-D9CD8-W44CQ-R8YTK-DYJWX_125_0_OEM:NONSLP_EnterpriseS_2016
faa57748-75c8-40a2-b851-71ce92aa8b45_FWN7H-PF93Q-4GGP8-M8RF3-MDWWW_125_0_OEM:NONSLP_EnterpriseS_2015
2c060131-0e43-4e01-adc1-cf5ad1100da8_RQFNW-9TPM3-JQ73T-QV4VQ-DV9PT_126_1_Volume:MAK_EnterpriseSN_2021
e8f74caa-03fb-4839-8bcc-2e442b317e53_M33WV-NHY3C-R7FPM-BQGPT-239PG_126_1_Volume:MAK_EnterpriseSN_2019
3d1022d8-969f-4222-b54b-327f5a5af4c9_2DBW3-N2PJG-MVHW3-G7TDK-9HKR4_126_0_Volume:MAK_EnterpriseSN_2016
60c243e1-f90b-4a1b-ba89-387294948fb6_NTX6B-BRYC2-K6786-F6MVQ-M7V2X_126_0_Volume:MAK_EnterpriseSN_2015
a48938aa-62fa-4966-9d44-9f04da3f72f2_G3KNM-CHG6T-R36X3-9QDG6-8M8K9_138_1_____Retail_ProfessionalSingleLanguage
f7af7d09-40e4-419c-a49b-eae366689ebd_HNGCC-Y38KG-QVK8D-WMWRK-X86VK_139_1_____Retail_ProfessionalCountrySpecific
eb6d346f-1c60-4643-b960-40ec31596c45_DXG7C-N36C4-C4HTG-X4T3X-2YV77_161_0_____Retail_ProfessionalWorkstation
89e87510-ba92-45f6-8329-3afa905e3e83_WYPNQ-8C467-V2W6J-TX4WX-WT2RQ_162_0_____Retail_ProfessionalWorkstationN
62f0c100-9c53-4e02-b886-a3528ddfe7f6_8PTT6-RNW4C-6V7J2-C2D3X-MHBPB_164_0_____Retail_ProfessionalEducation
13a38698-4a49-4b9e-8e83-98fe51110953_GJTYN-HDMQY-FRR76-HVGC7-QPF8P_165_0_____Retail_ProfessionalEducationN
1ca0bfa8-d96b-4815-a732-7756f30c29e2_FV469-WGNG4-YQP66-2B2HY-KD8YX_171_1_OEM:NONSLP_EnterpriseG
8d6f6ffe-0c30-40ec-9db2-aad7b23bb6e3_FW7NV-4T673-HF4VX-9X4MM-B4H4T_172_1_OEM:NONSLP_EnterpriseGN
df96023b-dcd9-4be2-afa0-c6c871159ebe_NJCF7-PW8QT-3324D-688JX-2YV66_175_0_____Retail_ServerRdsh
d4ef7282-3d2c-4cf0-9976-8854e64a8d1e_V3WVW-N2PV2-CGWC3-34QGF-VMJ2C_178_0_____Retail_Cloud
af5c9381-9240-417d-8d35-eb40cd03e484_NH9J3-68WK7-6FB93-4K3DF-DJ4F6_179_0_____Retail_CloudN
c7051f63-3a76-4992-bce5-731ec0b1e825_2HN6V-HGTM8-6C97C-RK67V-JQPFD_183_1_____Retail_CloudE
8ab9bdd1-1f67-4997-82d9-8878520837d9_XQQYW-NFFMW-XJPBH-K8732-CKFFD_188_0_____OEM:DM_IoTEnterprise
ed655016-a9e8-4434-95d9-4345352c2552_QPM6N-7J2WJ-P88HH-P3YRH-YY74H_191_0_OEM:NONSLP_IoTEnterpriseS
d4bdc678-0a4b-4a32-a5b3-aaa24c3b0f24_K9VKN-3BGWV-Y624W-MCRMQ-BHDCD_202_0_____Retail_CloudEditionN
92fb8726-92a8-4ffc-94ce-f82e07444653_KY7PN-VR6RX-83W6Y-6DDYQ-T6R4W_203_0_____Retail_CloudEdition
) do (
for /f "tokens=1-8 delims=_" %%A in ("%%#") do if %osSKU%==%%C (

if %1==attempt1 if not defined key (
echo "!applist!" | find /i "%%A" 1>nul && (
set app=%%A
set key=%%B
if %%D==1 set notworking=1
)
)

if %1==attempt2 if not defined key (
set 7th=%%G
if not defined 7th (
set app=%%A
if %%D==1 set notworking=1
if %winbuild% GTR 19044 call :dk_hwidkey %nul%
if not defined key set key=%%B
) else (
echo "%winos%" | find /i "%%G" 1>nul && (
set app=%%A
if %%D==1 set notworking=1
if %winbuild% GTR 19044 call :dk_hwidkey %nul%
if not defined key set key=%%B
)
)
)
)
)
exit /b

::========================================================================================================================================

::  Below code is used to get alternate edition name and key if current edition doesn't support HWID activation

::  ProfessionalCountrySpecific won't be converted because it's not a good idea to change CountrySpecific editions

::  1st column = Current Edition Activation ID
::  2nd column = Alternate Edition Activation ID
::  3rd column = Alternate Edition Key
::  4th column = Current Edition Name
::  5th column = Alternate Edition Name
::  Separator  = _

::  Key preference is in the following order. Retail > OEM:NONSLP > OEM:DM > Volume:MAK


:hwidfallback

if %_chan%==0 exit /b

for %%# in (
cce9d2de-98ee-4ce2-8113-222620c64a27_ed655016-a9e8-4434-95d9-4345352c2552_QPM6N-7J2WJ-P88HH-P3YRH-YY74H_EnterpriseS-2021____________IoTEnterpriseS
a48938aa-62fa-4966-9d44-9f04da3f72f2_4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c_VK7JG-NPHTM-C97JM-9MPGT-3V66T_ProfessionalSingleLanguage__Professional
) do (
for /f "tokens=1-5 delims=_" %%A in ("%%#") do if "%app%"=="%%A" (
echo "!applist!" | find /i "%%B" 1>nul && (
set altkey=%%C
set curedition=%%D
set altedition=%%E
)
)
)
exit /b

::========================================================================================================================================

::  Script changes below values in official gatherosstate.exe so that it can generate usable ticket in Windows unlicensed state

:hex:[
$bytes  = [System.IO.File]::ReadAllBytes("gatherosstate.exe")
$bytes[320] = 0x9c
$bytes[321] = 0xfb
$bytes[322] = 0x05
$bytes[13672] = 0x25
$bytes[13674] = 0x73
$bytes[13676] = 0x3b
$bytes[13678] = 0x00
$bytes[13680] = 0x00
$bytes[13682] = 0x00
$bytes[13684] = 0x00
$bytes[32748] = 0xe9
$bytes[32749] = 0x9e
$bytes[32750] = 0x00
$bytes[32751] = 0x00
$bytes[32752] = 0x00
$bytes[32894] = 0x8b
$bytes[32895] = 0x44
$bytes[32897] = 0x64
$bytes[32898] = 0x85
$bytes[32899] = 0xc0
$bytes[32900] = 0x0f
$bytes[32901] = 0x85
$bytes[32902] = 0x1c
$bytes[32903] = 0x02
$bytes[32904] = 0x00
$bytes[32906] = 0xe9
$bytes[32907] = 0x3c
$bytes[32908] = 0x01
$bytes[32909] = 0x00
$bytes[32910] = 0x00
$bytes[32911] = 0x85
$bytes[32912] = 0xdb
$bytes[32913] = 0x75
$bytes[32914] = 0xeb
$bytes[32915] = 0xe9
$bytes[32916] = 0x69
$bytes[32917] = 0xff
$bytes[32918] = 0xff
$bytes[32919] = 0xff
$bytes[33094] = 0xe9
$bytes[33095] = 0x80
$bytes[33096] = 0x00
$bytes[33097] = 0x00
$bytes[33098] = 0x00
$bytes[33449] = 0x64
$bytes[33576] = 0x8d
$bytes[33577] = 0x54
$bytes[33579] = 0x24
$bytes[33580] = 0xe9
$bytes[33581] = 0x55
$bytes[33582] = 0x01
$bytes[33583] = 0x00
$bytes[33584] = 0x00
$bytes[34189] = 0x59
$bytes[34190] = 0xeb
$bytes[34191] = 0x28
$bytes[34238] = 0xe9
$bytes[34239] = 0x4f
$bytes[34240] = 0x00
$bytes[34241] = 0x00
$bytes[34242] = 0x00
$bytes[34346] = 0x24
$bytes[34376] = 0xeb
$bytes[34377] = 0x63
[System.IO.File]::WriteAllBytes("gatherosstatemodified.exe", $bytes)
:hex:]

::========================================================================================================================================

:HWID_KMS38_Files:
:

:batfile:
$a='.,;{-}[+](/)_|^=?'+'O123456789ABCDeFGHyIdJKLMoN0PQRSTYUWXVZabcfghijklmnpqrstuvwxz'+'!@#$&~E<*`%\>'; $91=@"
using System.IO; public class Bat{public static void File(int x,string fo,string d,ref string[] f){unchecked{int n=0,c=0xff,q=0
,v=0x5b,z=f[x].Length; byte[]b=new byte[0x100]; while(c>0) b[c--]=0x5b; while(c<0x5b) b[d[c]]=(byte)c++; using (FileStream o=new
FileStream(fo,FileMode.Create)){for(int i=0;i!=z;i++){c=b[f[x][i]];if(c==0x5b)continue;if(v==0x5b){v=c;}else{v+=c*0x5b;q|=v<<n;if(
(v&0x1fff)>88){n-=1;}n+=14;v=0x5b;do{o.Writ`eByte((byte)q);n-=8;q>>=8;}while(n>0x7);}}if(v!=0x5b)o.Writ`eByte((byte)(q|v<<n));}}}}
"@; $c=new-object CodeDom.Compiler.CompilerParameters; $c.GenerateInMemory=1; $s=new-object Microsoft.CSharp.CSharpCodeProvider
function B([int]$i=1){[Bat]::File($i+1,$i,$a,[ref]$b);expand -R $i -F:* .;del $i -force}; $9=$s.CompileAssemblyFromSource($c,$91)

<#
: Text to File conversion and vice-versa
: Compressed2TXT
: github.com/AveYo/Compressed2TXT
:
: Encoded file details:
:
: gatherosstate.exe          SHA-1: FABB5A0FC1E6A372219711152291339AF36ED0B5
:
: https://massgrave.dev/unreadable-codes-in-mas-aio.html
#>

:batfile:<
::AVEYO...,PUT;.....*D........j}?.k...RnK;..K{..N=qGy+Q5M.......Q5Cf#gn}!V9TmIpUBzO$?]Nl6lL-iy1oT49@Dz-.Fkv;$q;PNfzoU,Ixf{p_;.3.Q5G]
::[[vzAKrv0]B).8-stdriz/7i%(EkOX19x2&s>T[*noQL8fYZ+dMt(Ff8z>#Fp_j2;d$ze,C6}W*D@)KcU!GJ#G#1yaa-[PO}/cQ5X6(^V-iJV;sf2*U8U>5?1;zx/;u}wj
::2K1Q3.Z!s8d-u8g%Fb^t`$D4;OLTgoz7H1wL]o_ZXI.mO18zok?Oa]vzc?8P<MDn]Pb}#$4U,.!h8>w\`0f_k]....+{?.h4du)FiiH>n|HoXnH,l!Q\rL>-\G6A/[ZT)H
::i;%]m<6VnjvUrSFK.d=;qQ81^FFi9cvRiLUqhr&qMWB1!p0t-N+yh@vx;q|t@v[T{#<\[!N2TqGJ4jMV<i0zJs3a~LT%In=o6@ylm\TJM?jL73tvB$~d@Z{TBIm6XL]cAB
::^F*t,l(!x`zm1}+Et<<l,z(G95Gu3<`=,n^\ZBM6Itk4KnK)5x+D{h3=W!8,,0_?IGGY]`wW7t3TAx+~`$c`idVnI,6w|?{Lc;W*qJ&*GC6E2#L6wh]o,~8\BvU}dC|`3T
::1aiYlAZY$o@&ilH[4E7$`}O[z0^n15o@3qM$)cAm`r=$Tmcukl!;|#*AEA!2yH+HY0rh@s6Fy3@LrHf*#\H<d5LXg`3GE_Z`O*knXNOZn\>QX^L9=9UHuQO=^QU<J%4cu+
::4%c1rIu!2=s`o@vC,f,%0XtuYj*SqeUq(06a5|<&gppe#`cko+U}iN?htJRv1sM--,fQM]`(7!Zc}&kM<gO<];x;<!X*C1.w>xADiRD]/br?UnhQbjS#=(]N>bz3L\4xO1
::Q$-X8i(Y9=@9+Y2TXEtBeB@iSsl9K_#J]|6+{nMI_fK0+^.{;f/fslq$nQZdx^}Za/WcxIjW=|M7goOTg4)|l)Eo^3WUe`qco-V(hZo!+dof%v377XwlDWr?{u&Jy}s^*Z
::e]34I$OpPR+2aiRNy;!tN%kR6S%;6`!?)o_K]%<x8tBEc$&EQh!fD+~`v(pr<<D0!59kX&cD^m=jI*_r\>&WO}gGOZ3zY;>fbAfQw=W0U`.[dsYgq<U{O,`e{7jY|Mpu]8
::S09G2|3/?[Exuialc$_1O~+bKt%g?fb2e*WSqDZrG6{y+?UU|2B4BA4!`9J&m/Wuo3E9lmk`~80aF]rJ%*v<o/Gz`!e<g!Bf0bu6)KCe*[;85_`YwC{]V*l;7s{]+MoKJG
::\do+;uRv<#$A)fw]PMB1JM455Dpz5{ftK\(/T~}6qiUatC?7;<dBE{MNEc1fkJRqV+7gR!K@B*1u>a+=XKI6-`1%WZD}eB=,lL>l}2xEp1_}kbvhJP#WAwfz8&2<m<{lBG
::ph*gtfS%VayAB~1L<_^TjH+f?D@b7L,9xPhF)IeI1#f15{Vkd&uU&tn6(G|`pOdFq6ed&%]Lp%LicIK~!&<C`$;$;7I#lNoiiph~1M,%43.9%9B\1_7}oJuwX03)wcsT%-
::D8EW)?ZyOGuC[~Q[.{f)C5/baZTBYVOjF3bYOjtk?g<Vgg_bgOPHMi,HL7-zYD^nVO!/;)4QTh7aAs;Ip^(0IkmP|q*JP!.v]>fGhkUN>M/v._${=n9dWTU[e}qMlMbI\I
::$!#i%a<DGo5{f[2)<AlqJN2GmK5WFL{i|s(bui+B2qjfrg9&vjFTOuA*?EQH~kENCTBDK8_VWSs1O$UG%KQ$4bd,j+8FvBq)@w~t7VM6EylG)j=Q6`<N5D#Rb56WJ3uV!v
::vhcC72<x8]$)RY0q7A?f,wx|LV]gaWw1u7Es^?2_2.$d3yEU59QuXKHba,INAfr#Kq&Sc7h{-#[/RWUwDhn&rawz3)g||Mpuahw(R~05Wh*;F{SPgi85IoRmyO@Z62F)pn
::tFO(+]]lvUss+T_[x=VC^jyrZL@;6>h+BI4F7!Hv`9McZ{uA#YwT*&NDmS=OzEh0qP>l~5lMJb+i221-l<-Jwg8Jug}`zIY[P!R~T{/POgLz5L\b7{$R>nV4|IlA`z[Nk%
::%<>/)!Va)\&]xY-c(-y!=&Q00;h=zA>#A^4hvv6UOOLYWF*)Ia)#QB+4}cstIe\->xi!3*KjsEGr#<we~xS+V9s`Ty>,]?J6W$ZZ$}WG)FkhhXLA)KTk|1O#|q~)}&{KCc
::>S4l;lXMw[I<tvI`MRPaB`Y7dUg1Cqfe&*W^&d[Y=B(Rd\CxdN&C,h3Dpst,>|2Dz3GsrJ%6lSAD%}4<QYR.&QNQYlA($QleCxDx2GlRsv4jPA\?3_!~BsijGvaej|JmR{
::/%R?rYE6Mp-N`7+jqQZw|Q@yKu,IpfxpZ_>mC6)=Um)2$r7Dn%!6`lJxIJb6KF94.Y/C]mzu!J(#=#0O_Z`yAG|\j\JC.,AM[aWH^-*vu-LMC}7-7yX[d{YBMU{X\9iW?5
::a#.o_sv8+[%x&x59~;{Nj*SfECvqUO&=CI-U./Yh8dBFh6k5+Cb[G1Hic_C6J9Xp\**Q&*DA\bBrvfDY)9F8SuuC>DF1%_-f.,uWVEGC3_uX$[Y4S\GChOCvR62N{hcj\o
::KiC#GAodZl&N8WG)wo2d%l,,`~$]$lS]Ceau`<^|=k{;0D1{e88}8la0Z\uF0K<Dq~Y8tbDM1)0Y*{G*>v^86Uc665dba-v,n]^l`bDO@x0WJK);1]EoOBnH%-.%/Rara`
::LHld@[$xzT7WTN!7>z`g>;!;ZS}HBODO_x*[?~MD<+[>@,m/0rZm#8[RG2$-u50-]T*_%`oVFS<}oz_\?X2FxCvEgZf@7/C&-+II&R2XnOc`sTnY%*#-g4`iWN#Y-ihF2y
::H6i)^d>|?}#x$/&.ur-F`AAu,t&QTQvmNWv7$b$Z<PpO{/4iB2tF1wbxX62lF0|^o8J,tWWjg0`|C9J/Bct={(MwxW4$^P0^Zy\Px[/$a{e_;dPEn/pp#N]Q$W@ufF2rOB
::gYvA$&(|t3v1r^[8XjW&JH!|PqJ&1pPjM=faL#Wb$sMf\GQC?g,#jn%from}f\W%iW0<zPZ{#lBcfGs}lgRw;#>ire;_F(Ls|GNT[{ygX<GcMV/E1!-]6pibOD(]kQgl!K
::ZOoe)E+0Wt(l3yHuIC%{YU^;_?Sr9a7s~Ve8/_a@t}~T;9miV5}s$bI{bnl8~aJRD_sYw*2+V=cM*FZ*KH6(9XYAKI7Picr[>62u>D)V.&bq`s<aRhIr!ODn@{I|NBo-g3
::fdu,4n;7!_4bqXge&Bxp(tJ=w7WP9sV^RV#B01T)Y&3|hI=9zU~7+x*XJt^_}6$h.i-c6(qBYig[mP>wM<oIIZ!c;6~d.+}6c9`3],,,mdcpRW1\aWQTufkh(}O?<5>rC4
::D{7Oy*,1eQMjbt[IA3Tj=}li~$Z[?)66\E$(y?|//N7WSX&@fp`4Qx^W\)?pD8/SA{zSS5(%^$!-ON`CI1W;DhMtxP\a&`gRS)0K(Mus$2*=_suE.6t)wKI)wjpCw{Inl~
::r;&WagW4Wxp1FO]d(?)F^_{Ra5ug4.8s5R&}D@eAq<L)+ij9O82mwF@D7;3|&ay&_PV>?q$W*{+Fd`u;-Wl83-XSoD)DPw6PnLFYLI-Ic[}qQ@4_/wfDE8zaB?V~/OM9<Z
::_&,lG-@-G^~@dbC36m[WvlM;/4^,{fL-x]LipS~eJLI}^u7L.T04uG!$(eS1iCd*@BxUTk\D@f4v*RJcJ^a=YUmU%@usutesoL2I4`Mt-bI}3i@DP&Wr<qE)rY7[&9Xy_t
::PgTt|u9G`rD4V4r9jBXfE9b7b!*lt^7u>(T8tl^\,FSOv}ICDJ<R[%e(Nc[O,--jLcBg*_qc]mY7B5xwDHC1hOBCx-j@$VL,<%iwNllXsSYV|o?fv[[nCRY5C=9|)sRBn@
::%9\x}+~{,k#,W6jCX[7wGh%rP#JDgZA!k)8(AAvUjTar9uS^,(nS1RvFIyV-4|]ppv\y?%}@)z;@x)l,rC[9Ed]Lb,zC|QcK9m,v6=3g.V|CKOiY>V)JdLFM~OOz0k/w,f
::OYHW#,\i>_/G02|3+v/;px!Hv4UVa13y]bVs>1~i3Qa&dDI,|pC$Itu+HJLUN,{tKsfcM#2OL<GJuNlC6u,S53Td_q,V*S|q|))T*xIf_t}W3>3R_sC=|i9>Q[A]UH8gS#
::y~&tV|g*K`;SrMjz%JLx{wkvDd_;pmos5}maaiJyz9p4J*3BAOqWFZ8%@f(Xpr@_0we67v0J;7.h%Edx!k]LEn?C|+kjTV|FK8Z0Ox{JV%SH;yq)~=Hus9l[@_,K0{5vX6
::@>}^rXn&K9aH>HA>Fhkj[bb*{vRq@y7cO(lH5-y=Y5;*KMbB!}*_[]IhyKR=~)@8Eea5_kknGY}/3MkM=VN]2vnh>$WNL#+vbj,d=QZX5<d)|v&GtTH(Ayc-8AUIY.{Q,r
::+O(g^VWfyL6j%0}&[weUXAsz(dg;*<x@A!&Qs,wkq#ESPHN?,vD94@AS$}xr(Cov=|j&RK[$Ienblx9`SM6^U5Dq&nty2+%Mf[JE{dU*oWViuz`B0cQt#0BHobh+=]6`-D
::x-+Zx^(gTUO9HXMex?#ACI^vY{t*}MEaEgLD,dV.@FQ?i}a#V+A(ag3#N7SSGU8_*@x@B&65b;>AGu;nQlh@16jO+vW;zL3mm<<_Xb2r&ewpxNz_CpM!rkH3>13Ud6sg$T
::d~2<=9,t&FUu-HGDgK07Dkx[|9{H}v9@7DG<,/xpq#LZ&N}6`7E|ODB}.X7DI/s``bTmNfCCC-6>`(1m!S/=6JWVh_11OWpq{vfAMf%XKZKAet/h3r0cK1{g451I@sm%sb
::5$.OoCoPFKc10xypvmZTF-5M5QkhF1!+rBH(&1e(WFO3^acmyYDM6lz)8S55McPLNU~j-VSBut0[#{8Q.cFV(}dh$Z83IQ&8bI^IUu3.GrhvY[#dM7};KmnoLd](+|QJp@
::-N%gClH%N9btT]{9aWJQ|$QWQDq_uOX$8IHs*4N%#a6rW%!a6v9(vq1+,4+vw7(52pz(U#,CyDun#!d;HM.s^~_ZvD8C_;u,7Df+p\db<dDlI-tBLQAdq[2f8H1ZVO6X%I
::lMZF0d?mK90j!,+S;Q?/~@5zCxOnV6Jh+iji\fzyp8`upx-kj6E\\g/X0-`WljI6z!bUm{oA,Qiz3BAkQ-[#-IG-~P#WNCoEa|z_EH^NfJNVIn@oCs.mAG7]#Ov|w$exRD
::C$.1a56h_t=1BU%{,(7OEmqipj3<-ta_bP7ym(C7.*q)|253fdm,PB1Dg;)/7W{V]5ghmnG3q7s{@CS[~+)Ve(6{E4[Q[OozQeu?(k#wbj?QnlwfVyaa~ua}ymp^%TpdTE
::~==e@%poe{CnrMYu^Ib_Hz~qiU{@_mO3i;v.$b@g=%,fm/LAQ=ZLBnO?*+q{f)#r/[Sm0cC)KogS7weLsS{go+sbvd?Nif/~sGe^v]uS4+by#Q(0Tw{)}e[}fPX*Lhe/q|
::)^T74iD(@(-e_io(V*Gj7pX<$b2,hHnu_xl^6WnvB;;t/by<nW&3e}B?\;$]dSfsLVk&4+H_GSQdaKtf?zGC84ZPy|+ZZKpTxGNo%dW,$QQ<U}~El==WdiEma2pw7J|-Ff
::H94GIS.=rWSfgPITM^&b2;4VH>r*dYn7n9qoNLQj(ly*I>dR\kg5y-prZ1OjR6cl|A[C04H&`}RjCMXB;+Z]KQ0]tk<l*N&((es_]kZa?eC9`F(/lDyTrgzU`y)C)H7H\H
::W?9}d(TjQRnw<*3[`d]r%Y3;2^f/5O+n59U1^4]XzR5qGM(Ph}K6o,d85i8/x$I|C<89a%;tZq~&=4O$,[q%\/Z<NCO<UotFC+$t^MOGj+^6e594N10j%LIi!F<+s[@[tU
::O6ab.&`(Z,S+!\wKalv72)]5TBC<SAj)b6<\QnU`i^%<,0ViWS(71DP/tm{Q9|pq;]u1N9M\hY(UWxI+yWap~2B*hgLX|-,QA6e)>}ZQi997bM\?)M]+0y~-xM_P9*6w{V
::InW{!mklZNXv`k,q9_n9hVv/vl)jV3*Rg@F]a2iBD_b<2#sXZ8WCvy*ji|=SLYz|m483.!%~#^N<TKj5_V/oajnPlP@}a4uLL3lw8>r]uGoiS(*6.?d}h}a)}F3]%-t)A$
::[1&}q-oD,|La.&m8&6.SLVe/?_SY@1_*w=IJoJ+khxVIDv-)7g-ZUEpbYjQ,u@V#opG)[_QUV2I`~s~k]s~VVRue?]#F+m!p$QHGN(2w`~L3)9fH,*|fE3agj7s`Ba&>`2
::mHJp<_oS(O{x-C0XL5nN3&]ySU_R~a|P]SjKzxgCs|B5v6@qX|EyB=nN5O1d+@i^FXx-Em-]{eDw^_tU^sYu/R*@T51GwfzW>*S{iFHpes37ZX,6[BGg/`k+0G!HpWb_.B
::t1D8Z}%i\?,u?u\?\[l3!-\__{$<rEkf(pK$]-nos^>B$/fTU4ZyH~Og4HiPChKGX;_N^1oKzB`LWj2m=|=p-=z|zI6\pE/ZFQ0.Q8%Y0Y5FDbH<|oR1$f_!ZXt}r+Ph$M
::Ql%zRm?$t{7\h4b2S]}b!!_@vT_^9q5)q#,?^3oQ1Joa^x1``)bXdI5y)?WEHPtik8[@ej4pW5j/dYt|VV!j%u)bE[MZ-?mJ,FYk<?E;J{f(Td@s<cu<HP!K3q#aS9cDM1
::*sEU-DVd3]1o3~9EPaE_[EQ*8@0PD0wl@Re7Do0-?EZqx@Q\h)vqV%7]2+Lm_qj;$hcOoUo]99k4h=[[dTX,Zx>nOp!$2Ug3,Z(Ml}WHo][b=)tfkS++qRrT}c2+4L-Sn4
::536QF45[&*ppIS+sayPH~UY`pEg@]?5xbP|+yNdN{#_mW#3<P`F]jU~`%6pP!I_+#)g+|]GTu\8<^<gfjatJ]*rJDqYX%s|tv<<$G@,iYq5U8E!w13=;w!9`kR?lD9uo)(
::91j$V]}S\RbGBckw=`h&^1P}9!eaZQH_)Gt4@DV-b4ojr.YQ>d;FsNp_3eZngi2y,qBiwU}}}_c6BQiP\)PO7@AzWR;7s{htYyvw(`N.|6>{=Kk*kS^f]eg|Gq4]vI3kWi
::j;s$;T-}+rUYv*|DGbqJzLPr+tmPAS1A5}rJo16vE(KkGh<aC4nV)nSK8x#)_Q0Y9zR79~frbcfWm.&FU}FuXG]Lfvy#,&(*z8<V.vOQ4DHrZl1P;{qHtg}T*Oj~1n)l8}
::R-}){,3#/H(4ob>c7]q~QB=1@)O{@v(Cn9{&s@|OI-9#FymUM-nB^a+B;p9X_vayoHgWp(VDMU%k5?d%@@kEr_Tn0{qX$\<>1rQ5I)lH*b8hy2))ud/iu#NHSQQbAcV2I4
::5T=L,Z~CoxgCy,ivu#;<g++((-2`Kr<?!;0$S0t5e\#J&~DbEucb!#_.^54*i&tB=jA$flnC^MQ5WPQD/7@4@z+j2OZPf[*]?xexXt~$EtMY7u>_QUjsEwnhnwa?|(n#Hd
::`H#$/-cs^CRPjT6860+[Cop4w21T{4CjhIN0H6CXS?iCr/dr,Z1S@/d)E6-a^}._&QY}7UrTu6QREpAQUtQ.wS6.&jKcnRTwe7-zZzlR{DIvdJrKULuJVR20rSOP^iHzwK
::Vlcu~~2P7)5F774!S6j|B]cmwnO{ORc6uIP|Y*mR<,6.eHd^I^![E.7p0`b}{3vt11tkeeZ`sNX|kld|fob$CbLEi=o@2BHQn|buGq;q}LySbSy[Upl\z80H_Y,Af6pb7p
::TH,Wfc5re7Ddra3/iQDJl~diwZLh|bb?W@A?b.aot93Bl[&SB7QM=_2X4C{UB]b`n9v;@_d|bS]~dC&&/7r_.*s\&`xnur-icTb&}0k{P7D%Y.X!/0]n~pJj*lR#2]STn!
::;o=oJE8<*n;xuzA(\\DNIMAr-8,)!T1C,yB(uzDm>N7qj|vD.[WH,8c/mnqrR^~SYu+{aSGz5u_{lILVe?]~uAFv3^;ce_i^+^xQ|CZ?drS$C/mgr5O+T\G6lWk!q|1O.n
::oZN]x~h^@FS4w}<V[!~s^4Q;WA(Jrvafk+ZpW.xfNP~9cVM,K_eSfH[mX!t`$\,Dd!y%3`0Gcw)u(Ed<iq4Q6t&NA(\P6%wfqvw<!1/6*_.L.dG^BQ;H=r19^0#Q}\Y*c/
::;r/L0vAD\<E*s43CJOB1R[.dK\EP!*Lfy<(i{8a_=aoZFg;m!IBG?_y_jY$-qMDY+B)oN!P!qOX`GW/8J^DpwM_<2nYrG<{wv)Q}V#`^4!N)?|v+Eg2&X9AZ{hmD%Dg0Pw
::Xv,8aB6#G$`NS|G$Cm*Zb2f3-hE1,R7ncQaIqG|g3Mt0Xi9I],sN`CmC^0D\a\&[A`2=56>c<N4)SnL.%hQR12@|gAskm\T&N9Y~pMnq/5)cl#>\Ut@q}y#4+m$)E@{99G
::;sZ&Cr]%AIwU]b+Zq!2#nBSz7E=,J,]aUca_7lG@\aVqN2y})b(M$*rf,3SQK7sG|~bt$jmcmBf0mf,,W@WMAEqvJ4j4,uFCztXKRA(\}Lr/=5=,fDXrL~\[+e<d[UFsIn
::be9P)sM5aSp]J\jjnBC#o=D)etYI[2N-HmRYJ6!IainT~00s$iade\8!Bn7a#1xj$Zg1K#pwDKm,dzg2Fxuyh2h%Wmux.S?\D,5w]vstg|9#p4\NCyIp*7z6s`_!1u3b[e
::}%L*K\=&3Vq*(-_`M%,\0EGa1Z&E<c7^0239HaLX[EI%w4%B-S*%Oh^vMAo`ywj;7GC0/KU`O872wCuY.vE+&-w+N~t3i`F|])q*.1)Mrq>_[%7A5=!R+0HHET<U&Rl5d4
::v=dEQ*ECg$7I3]}#oSK25Ox&[GMhYPS\`lfb4f+%h2)R3Wc~~lQ2.^hX$56/R(=3-5X]X+i0DCl|`J#X5jy+w\Udx`FnI`AiqJmfd@\E@d*%j4qC+fFq^LmdVZ_MzCbn\P
::zSS]LMB@UZoos[i,/h+Al~K|NPR7tZUiw+,Tn0$~b?/GcCy+k_<t`XuRkU3A/N[^6Y+eHgwM=kWh&RG)L_V}&{$z${N2VPyzC$dhHx/(s[-Msn?/<|[83/]+.K>A=q>xU5
::JC(dMAm3bo5}b[N[nHW,H;_\}8!-CdYS!!rrVr-6.FDevzV(AQY?OMpUkC@%bs<[+KXh^=_w0NHRw?tU91Fh~$[+J3M38MJ5(-ZP*YB<BG[i&|gnnc&5DZ!p]*zcniZvyX
::7KDZyLe\#&j<&>z5oC7-}NlO\PT937G/0GUz,?vhmXnv;vNY7r9U(iU%}+v0e$$R04P0<\<NI$KHRkqtdBqJNEC3m`{lo%hUa?@2l^r$rpqyEW,s;\=94K{f{!=aR_Ha)x
::|oIrL+1!RSWq,B-VZZiB[y9ra\Hn;81X^cn#@l-3QlHE#0.9vt^ZRh6*d5=n0Jk*R#*&*&b\_wS}lQ0p\J?d(ojkv=p<7\@0[,wl1ez\+}_;0F//VJ\P=[|*hC\tsQgN|W
::!b>N`Krx}>trsJW]B+Td3I},..SWk/I)VVH+et;~&?}IlV[>R?[bJEqpOGY6`GF8~\oH}R@FE.owQkUN9Xe\F=LdJodLPs]0b~FmrzD%NDw`I;sfZCcO]D%RF77p!>;hwE
::d;6tRTUe^17)9`&rQ]y;YVli+UmM6x<l.?m#I<(~vPi(&J%Qy#o_/EOh~Xc1HR$Rj()sU.xRy%3||\i%2a0n>)$}....6)].i=6N3El!#hlj0idt#K<l?AxJ~UVZS`i;G-
::g*vj=C4+qA%S-4_Mgng/&x)z0MPlt<FRD~>\pN\w,&d5f$9J9^*<i7Nk0xT1]-HN0RY*v>7l}933#T1z*uB%394=Glc@I0coLsj(#{LkFV0jN#d}+|%}wGB=a,((b$`v!#
::NSd)zFZAlXe<}}@[E5ZBFCd18M2]cAytWcO]rqUkJrTmVB[=41b96t.Km_oq]1pvp%0=[{ay,?TmfJm(qO{suT)~#HUoPf[Bauw.BUpNlF)$.glCSWGg%7}T,xo7SC#ga[
::Uut2cCvlc!?+#CyB!cJ&,NN9E6zp|H[K>v\NzaK|0BBBu#$(wkxJIDue3fXy~ui`L&z4HalfP`XOb+F}{Bq/XJC-6)&eAo#/QcRH/5<^~&LrQcB+MAUvQZXQ?NM+W6}R/i
::Fh`&?I},=sH(L7FqhH;l#[<#WR(Q(_=QzyLKi@)|b[j!\N4/SQH|`~rjfK00S;TW/)j*|qu=uVZ?4&J]K$d=5?1y7GDcS3cILGZT+\k!!MiSaxVT5|lhyIRvK5G,[unSR]
::T8ZSTuYy}m2&*NqzfW@_-9ghrqeITVg%+X9Vf953MepF7k3}-e?or%G{{N@w0hlH]rdr|nxWH~/-P*k_YytQb&(+PfeS&=|XEbdCA-%iSsQMaz>I;{}v(iC\mvJ^ib3EB!
::b{{t-QJT-.<Ari}u;Lis+$-gX2;N9$=|tmob5!=U6YFU>m[NJEY<c27Kc!ZY-(n9E<X;i_!A8bm&o+~ybmH+W#](1QYI!,xM}ev3IF~%=Om,5^7f0YQkwG#r2{X7#IM|A2
::?1F24@g8Dbr{H_.=,qFMVjgls|Yn!miy&bG!@s@r].cu]]c;0C,chacD0T6ss}K?,]3(!u8slld[Le#>^Fd|?o^k{%gn,m>_E/efK$Tr^*}LF(RFDJ/sB<t<],Jno1@+.Q
::\BiQTQL&se^p),zutM~q)vF2-Ob~di}1p]ci;Q=yfLjD?BNGpg|sG|.x&#8SIXel24rq\g&VirmL%F>ljzkPWFD-@_V4O&H42al]AcA,jLncm<L~S?tdt;>u%o7I,jOjs<
::L37x?Ts]&#=@}WST^-_6gs7YLnPO@UJv&q5uLlge}@BC|ouu!L74yvMcO(m#AXQPYT7yfyDTrgKwN6@ntHv<A`6_r*[nf_4Xns/V>7c1$2,r)3g~,e+mdhiOR>a,%np=X,
::/N`w6!YX3w|c#2ELdy$~#N!zfQzau^&kQ<jw*57ZcG*GcPFfhJ;tjDi!)R$]ja7I`|5wR=|1BiJirU.IArK``<3M/pw#FOj~hsI]YX67x@n>(;bvbjP<e]F]9Esf$68fs^
::9ib8,D$[|K2VMd^)Pr(!4r$P_AL-nghoCQ&cWr5UI,=B6%@)fruVq<A+2vmk9X7qbtGOZ?V5`n?Sza^dJ`mhZ`RV>h46f1e)?9oSvAo0#F*Ghaoxoix=g|wc>LhFI]]xZK
::|LeW#+k&3XNpu3_h<V2HntA/}EwVVUpKWC*GwD0*>~1d7RC\UQqCnj*TG?*s)a)%PtNf1c$3u\v[~!Z,e,*MvSQz|g5=_?CiWwkxo,G1NZ,=^rov0%5(nQfEbM{B~*gfM+
::Ite*M8$-{C{Jyb\@t?NNes$[[,izxDC]p_V~g0[+|9`1Ks^Mm+r2bH/2z_,H3P<5wuev1H2YE/)YnNQ=oMzKaXBH91?_\6{},7XmrDh_2JOdOOGD@Uy@@PLHe~e0w-Nx_v
::[_I|-fdykRsT9pMRhnfqgxYC^VIPZ@ri|A(q,ogjJ.lTAwr2L}PqL3?@h>+(WrxKqxx_tm~bM0T=}$87$H6Ts2@e6d1Bp.(hI\~#MZ$Al?jFRAuAJ28Jr5cV*[OqQ//3LR
::nYMN\78g9/WUK6H-\Ej#~WA;-O/^Yq,!{CFust}Gm-CO/OKYv>V.6oE((B&V<hjN^r\)3amR<W`X9o$HDp(FiqsEMwIy7&Sv_@6SxtU6&2@5$cA^fcQ~OIL^Zj!4|z/HoH
::oCNPAU>[{p3uFStSlXmaaOgp=[7xGvb&M9-;ADtT&4~Co2CHmKJMDd9.NSWl5iwD_2Df\v,xJwW)Mx]{Xq`l-h,ZngIl?(HbHSE(owpEHDYz<Xt`pfps~OrVW\.YE6u,[3
::2~%<i1UJ%w\)ttmGf4F%2z,e;C7=xGWB<M4?%~~wD`B!*m`O)wwqwqs^.jw^us]sjQb.pN7e_wS|6]b@BPZdf]*)^9~A_7h2>O9BlDx@tu~(89+En}O%o8;~E5K~Y!4!#<
::TwVj)g3pcz}W+qWMUSrBKwvO+.-E?23X_^pvV}jT;yq=J,5uNAgb$roV5\mI$(dQD5TNHeqbw_!v#o?NZ|m4y)CmV${<i^*/m#B|O\?~*t,~5E)yF(l!N[*;(6/}P)e<f,
::=*t(5u)+)|QMF%aPiT<T[*gOMSI.$Oj]Ma)Mj}wa#11G%XS5t{#+O/Tb\!jHj+e1`*_X<pL;gT~Q]V4rngPV=1n_o}&!N3LbNq[b/#eHo/RQ^}Xjx_>3_F]p!O.oqZq#>h
::cPT5o;lI+}mw9DrDZb[3o4G|)~z|KKS*{)k[yg[]%v<(c|y$?!)&#xSv[5m=N0G=EHJael<w[~uD&]AmnG^d+-F(d+kq[b*k<=i1a33NjIfTL#VG(1584E%+kaF]}y\X`S
::rN3Y1X>;S1v/n0Ndv(2,moz,ep]f,=zIy6gde=w=iY&d#xQS<3rifCHs(n>yNv<@+5k;l,M3_KgnFF7Bafwy#&FX2O]Lh_M<AG|YA@|[<-.n4_>OGUwmu/wG{v2CzmkO}[
::pBg]Br;^&k6fkjk09?P;[x$\pe5/*cQOw^`O$x3zTqQM!Z/%Smi*&@{5\mZ#Ai\O](Cq?)`{#Db|OS%;<5Ev2XRXm~(mXQr4_e1Sv]%tA3I(06PF?491lv78?+B96DmkNF
::6v](U!&`?pEW2D2`0kn-]Qp8}(r-0KLI0zADa1<?C/Xtbjui\O]%Xq\`[7iS#S.1GdJadUcOD.}hoUAj[r7}yF~$(%0@F|k`v;O$[3(ejc[$=RX/p^vjwu5wrF;RcKDrns
::i/LCy<9L>Ti{c37]>9zvDi>[jq`t_E6J~rzOX5#8\+aXfaniTEJy1giK|N%,;##7p5P-$d(R$Ww@q`gr3bHSF#\F4~ij(RR7Fok%~9_,bd3eKX.ha%#Ni94OB;T{|JKXn}
::mgp$]L_N=SjQThd[H`(uG3qVAg|PD3;zV=>xS_,6p\Gpam3{/kAYg|*_?f_1g]J3DvuGr<Snv?Q|ya5S%?@FS9Y)2#}JKMK(rUN8TB~Z-1,1Xo>9$xyhCP~zTcwz$i%fSu
::m2Gixhn|7KkzXFXS6O.Fe{^AP{Hpuj`1r|QI(AJ77VE,0)!bW\FiXTyMw9*(rEm7MyK4All,05)ve!0IJ4.6T&n4>zR~\be%CT+uQ?1<Y|mNtjvpB5Blb-s==62I-V(jq0
::\XxfPXV,UN&C@9!`2Cd*3NKf_Emp+p8jDs+nethp@9ucy&mVTOsa%EYm5ix0y}@$bWnk_Xti7x]|Z9cp*B=1*BiR/d5!KYQ;#w[E^2W[JK+Mela$xB4pKdvEmAGR`ZS(VI
::_GY].8>%.irX4Q6jiQ7BXc>>M|4+a!d$es4YCA1u*=k;ih#HxtYERA>Yn*q=ZiAZuf#g=awnr=O0{N^L0~vx?G4DwqR_/e<eAAFX9#)Mv;0aJn55KL@fGEdW^W&oXJ(;[b
::t}[(rez?iG-Gfs}u8FCef(j>$<ODY(Ilygg1^/erJi@qkUBX=ry=PZm`0+VIRrhF[QI}BrRx`mr~F{t|3OH^Ea/LDB5H*=xYTjOJbeV+d$rihL.i~y;iTeHX-eqfP-jJ#A
::[cK7Y#CLbunM(6,RTw+f[eI\$Qk6#B&$kCZ)w8N\D*h4v?7aAd;K6dD5=MSyiue9=a;;]C@mtj8Ukvq&B~1(Z!8#mt8X8N{M!XN{5L=PfMLIJXnK)P%LLVNrXTb]!Sp*@X
::|9l^5~D@11d4kS=<XwuM_ogZF=$J[%0Mgl6%w[M6rU3tAywLWY_qETDu=2$J?_R_JLwnAgz<Wz{Kop`FJ>BM*=oCsFc$d5C7lT!,B4IE/q$]gT;FHW4(vb`iY!Hr!~B3D!
::X52Jur#g0EOZ@r$RGs@x1Db&%pH7}d}m<L@}l%XP*f01#G;D|W|,[`a[thf]TE>F=S=Lx$w3p=8j}?lX;7^=C[@(e5+No9&#G%7bR9zo+<Tv16e?Z7Zvs3|dvPW_d8#Kqz
::z!N7DuGN[o5nRujm=_&))gG_LO=S8=*8>%7l_T8/]s%3@14m;Ycwq9)C;&O$puayHNae=Tao52YE`^{*{b{ira2%F9\ah49.B4(Gz<;7Xi66lLa{_H%$((e5v=<_iAeGoA
::EXlB-P+oc;t)>fWds~$DG%~n448l3D!OnKTLUxmut#iljks[e-<;urHfb3rh-n!+UH3%vbe!YwpG+$*9&xfV.uVF-\|}h5a}0SC-w@!8-4qILCu$Q8<1SIyBYEsxvW@B+=
::3kqy#w%o<jmusqd&V~42s*sft=lqwwyvr3XkuiL2h!BKMclICPElI1!0701!7?J}M+`0929}Z7*3Zw/_P$1^u6mp+LFr*zU+h%)UIx5?5!#qzv7Hf4-P9I&NrF(`V~gn}f
::=j)3YFc#,J}!s]hST*Wjl!4L-qfmavl=CEam|kCq]`+ynyz4sJ2(|J4(Gd}Wk`ZLv>v*`_SDh_wBa6DAC\kcHv_LKJfVgGkGh7|VG@Drn0T}hDmq#xZz|~zhZYa<BP?#`7
::lx*a,mA5&Mk[6#n/fM2F.Grtaz0R}KB\}E4^XHzD6Eht9u$E7<89!0Z^!nTuh4D!@Li!(5&3;|,E$p.<`Ft$}aMzp*Xev*~MkK/@Nzw$Ek{!Vj(o&6DCzMcd2<VL0h3}Md
::Wq3}cJ_V2DiPT`miXJ\90T=F]E/5<l*zn(!mdN$*v4#-.Ea;dI/;H58lIt}EWd(V7c[u!\-pY\T*B2}lz*Y@3zHHk#=LQnXYGP}7x#;wq._f)5H9z#h[>m@?q;<4r;1E?X
::mY<pBurL(MzxU$I5T4#t<!%J?z(q\I!2!{*`u\PBX$TW]jsGRS|Lk4{`y\jJT*$#)pi\-omRDk?+N5d2La-un-T\KM-ErdAgwO@`}!NRLhhJT><*j*6\x;K~gJ\YFHn!V2
::Z.W$N,c4AR$0v`DQe,-?#h+>C){Bb~?hoBX$[K~~[L,<M_3\`zVL>2}!%yZ~803(w?/5n`]t@-Annk#a^`9e<;s~;uS`E-FopEs!>0@/I9c&EMY)Iug\K;Wn,+~/wKVV@h
::9`Sn+m6IwwkP\1R0z\W`VnY)~xtj=vLh]ne4qlJNE)DKF5g01oYvR?Nn=0wj~o\\!JWEPn%*T5NupYNh_)Z%El$aqt4/!/02+)XX%\%J=AAna}Drckj.`0S;>/=%q%1$QN
::(\=qa7R#j.C)^%l0IKK~G*4fXY|]rm48,K\d<DZ}X}#(sNQPqR?|KRT\RB7``z!RPrZ;^EX[\R1$~3ynNOE-F4]lWG$`#ySq.nkzkmd1`NN@w0zv4l$pJ5cJwRp!{p|B4E
::P?>H!\.K#xgq;ZlDt<9{FrHl{*w%Nr~E/K2zN%-Ek!C)|uyQK5x\g0n`U+ytNJrK2B$/zTRSX%V%Q@/WiL/@Jg(5+`jkvG#wt;NZ`zkzj.J;w~>).>RFcYOiDz3lWk#\\*
::5$(+&*Ktj.DQg[nG|5}!M}\T0*XI,P3\1Rqk=oO$MjBNp-#U]\E.+@uz*/7Rw6YnATE7Sny[=wl^,;&(Rob;LIxEb}oWJ?N+l<u]Tc4dY!LfvuyLRo;ml`FV7ut|`@2O8S
::,CjMa=y$qHF))XCnk`_(|T~ROuexp}0p~F|oCU2`[&gNG?4xqtI4Ojegk=m&]+VTmwOt(ZHSE90Ha^LWPyCdzUP#*_Lc.}&KP-\NydZ&qf[sOv{!R(MDm}eTG^qpJqI_&[
::5?;Hgulry&VzCX7Pmx/[|.O[gKsulFme,},?~l8t}GTq9kQv5zQ`/M^/>tN$tW7el(nDZ>nicSK/J}28_L0/c{ruZX1GFC$QXugTlhxJyXQ\}T2L.a[V[&ut&U6!<q7o\b
::KIinyEb|$Ir(a.$;nGe}=_W|}F6Cf/&WS42B).>RRu{|4T)W)datFKxxJ3+(IrdJ\ES6nz!EcusJ)H~Okr3<I>4P$B?o,g~.k0+U3In[a/jfwW{h|YxA#H-d-*g|.o%&1k
::_NeD_99D+AxPUG7`?Dm(qzoQ!li6,FnqJJHl;IdVXg<?ay[olqI`k#)TaugR6SwtH7-h~aK2px9<.Fbc-Sm~inqO=cbN}</49cOaviMIy#2dLWHE8{y3Og#hi`Lq1Baox^
::iG}r_p;;l%k!GG#TC5%f_!S7x2,=i|^+`<ZH\BVUMV-l6)hWv)_srWb@(XYxt*iy,8/#[Jz_H^$QTr]O1soCn=9`B,UGb.NkJfY[Da;oh;|\Q?v6inKTJi^^ABOQDd\pvp
::13G6/z9yT%_Xko=TyHkTm}lUqBMaSV<{_@*([=H%T-u_%*w+vU_@4=shfDO}25yLyqXHke2h0@&D*1A+LqbX@XZfdaP7-xH~hqO6g5[cNn99TmqbS*D_#++oI2*hm,pVNK
::zblG\+2]tM]Dwuiq<O-G`DoFgM)bJuJZ&_pLp$T]Or~hHA<</V{e7UH^@UGPWra[#\1d+G*K`[L3`;pI,,wSO0k{St#v>DHNQ+;<QvhMH8,nb3@`m5?Mr-11W%UXG1{s>\
::Mz@h&Cm)gJw2o2VeJ@9fpn5-Csu2cGO|L`]oBdBi,79R0{@Y|/`#@s<Oa&)C1D@l2YrfN]~Me3UVx`VKy\DudK>?@u;YGd?Y1?{02UL|@r)Iwq(ZMFxB5W<[Favl~,B-%E
::O1115G4S>H_8y[56Nhw#_u1}iHA}qp#1$Ghg|p15m=_fn0{9lLJ?&D1U`?g4y!;!2uAG-jRb5ldw7R}Y+c^wK4Tik^{,B@aR9bM<}C4iD>f;uI!$~p%d)s=Z/omf8xCZmV
::c_zHdiIU9]wD>.Y1bFp)Am~Xc&lYno4sQc87qRf9++VK?Iy)]q/{Y8hTNhn=13kIXu=G4?{7v;HmC1pJw+bj]K6r9xDJntUJ1,zAgln/aX^c^v[Z@!Ihq)\o_ELFI<]hz0
::XOmWd/g6^w+~[2!]D}3{w{hPNl[EmF<`<c1l(QPJ&nSK5[]~>05T/8;hd_wswN=BR;3+Nx*G2iZ-h9]grj]J~]}EHP\o+FBkL&rIC@v)]~eQc4er|T6IN<[%s+eg?g=l]p
::}(\a^Uj@Srp,piB#e-.H)d^L.i[X+_.`mCX?Bmz9/Tu2WTm41TxA.T)yEHVmL&+z7}(~9aiJg2(P,uC*p~{BcRHNA6C3H!@-(<7]d0@iipoyceTr8H~{#Z9UlCKsOw,o{C
::]Fvj0QFoJjiO_5xsA6,%RN5hFyik>C%xg[r?Dom}~,X0fqaLy|P)t)Zeo.J``98NJ\)8fKl12=Wa1TWA.){H=8x9WT;QW+>+S\Tb6V}2Xc*Q*Hzwb4jAvZ]@Bj*MX;c@D2
::lJ.{m(q=f!A0+,lp)(5(UC&W6+,E$?rrRozt;Vncis,/eO--3</8bE\#gm#,M/_~tk}._N_ACYj&5n-(M--200B}WMdUH{oMH#5}/~;tgWTlkA8eN<y+cMo]N?7#u[zel2
::b/,CGaREs01C^QbbcJ_}ITDRJK1=G)|?R+;vn,Hy?7?<bTv]uA_Aq;i{1qrmal#[qp5fYSee0}ZKzNt%@j7PUujRI~Yt/k{kq(xt&b|?BQ=We_HO<O5d(LGHI~B?7xGXK{
::FPE!&`c+oQzfxGp,qLcEYWcv^<ub^#[U<|Q[Dp,x\<mTrjZ*cG{4w{CixQRk4EKUebXx1`z,2s@\c3(1&hao=otFaTMU(.(&l\)$H4|&eQRY}+<{*kL*bNNw;&Vaa%pvo]
::F!(QX5r(~W+R&8{>WE`ZBI2ZuC6&`=r\#GV>5DEU;[qNKVtO|^tEOXjqji4>iE!I|$T7VC(Y2,t(SJ`a~6-kuugpWPDv4`I+6D`~*Sq|-%?1^BBVf&EYSmAS)UVQ,,nW1h
::FX8![@&|pU@dOzp(7sm33ra-Tdbhu3\1_]Sm8C3)hugsC!O\jN9,wp[FA!u8^N4/io_X<#;BcQvK.i-DT/Z+|NB>&vM\)zwbV0/(C.YGohP@OmkU&d5G?_hqLscd&[*mVt
::@Ocn>0+?jJ{=0ISHK(}pTm#H|n%bABy2\(8Jx@@kB~ubtN8CK0Ag~vtZi$\nVXGw]K}Jb|aaa|t)nknpwU.X!uN.t!Z4!jrydKL7t+S<DuHpcVbW%~4~Zt@xxblg@VSS)/
::vUFjx*lsG7JAdXz?^Lj5Si<$w2DQqifjm7k^onUGeD<0_rL$f{T+aZkunB;hn5o4pMYA/Pi\!Grf$G#WVccLy2~}.E2%|O)I\OIO-~nE{y>]aTr#AC+]`QiD$/#s%D!NcD
::U@$?[(p(qX+{%#8|,}Wh7c5$TJi8S1LxMY!Rj>HAo)BT&_a<Wckv#Z*FKP4eO)%{[B2iEt$$l}o(#31IVNz{\/rdH3ni@N6+(RkM[8JsC)yV,[HwZ&4@^F#Tv2/@dm7*kQ
::,e9]23[cIZUlr=P=&%C=#|F0]y[?VmPQZP.@MMY.JRK=[D@a<As/xmVHOpvb~mT`St3Y(ta,OpRCqjejh>}5B+^_ddH1pk15SizQ69%dO#+Sp^?Rr<&O}o2m>Z|DI,iG@#
::wtn#?(?QT{uP*XA9<3pyFO~dQPq^u_7aG8gx-MhArngMk19[v$vs(%v-zo|^@in84Tea9^3L<L_y%$psCZ}_G5D,zmb(e8z,2!c<iGh+,vIfhCiZpkc>t`M=[ZxD2+<gc[
::Uzhb6|!!T+a9nA{dNEBZ^X55F0O#7k#%>||c!6}Yyg`\F&=fMOv.5g\=.D2R+\7E|>9KH!4rl&#gD1,2g=/$Y>x6qpr.\p0X==`sw9_t7f@XkfSo53]Bf|w5M9EQ),rvMN
::9gB#Jb35tOm47j]5{%gd]q7OsbG=Dt7i4./o=wjR&|1^Ne+87A*urkO)tUDq[FZ,wK([|>4V,xfVwZ?ZE|@&JDKR/i34d,)E|){OID#AFA|Iyl*R6=FH``wH]t1<iR4$-{
::P[f;!A.l`>8W[/!__NQCZ^t^y[*cDrWp.S&sipG{3W62{8RYK4(7$]~&7Z;}^d~Go>GD!(QAVo~fnq$WMJn;Sk@r||D5EJh?r7ewOus]K|PFett\U\b<nJ|K?+>(~+L@@\
::Sg6__gS.*QlPx2]Tr-XhUCsed=L}BM&HS`M5&T32R{I3UPKq7RtxY?!{1MT?xqu$UNU&OYR-gm/9eJ/C0]rv2|~eQ=~RNN;S*1lB$9ff33v&znPZrU;qimXEemq~cREcSl
::^e9I;l^TtTH}|#W#_]H]YXK3)/mzq=p)p}!~wFR5N*mvJZXDKXVTw3[PiO`[+xD8bcjE&Z[jSI[l?M\28+o*/zWKyDq?k!G{o[/Ty0MrJGn7Tgx~*M8!WXMG8O(*lG>wip
::>9Yic]oH,aptZ+([fE(6Y3W>W/V(63Lh1X#GC0d/k@&#/D<kj9U]H%;V1?K$1]5C$4<2]A,HxXZ7E;AJo%zRR}s4>*c4\vFcMlKNZ9\dO8@8?Nj&LH%%U_*59Y|&fO5M6&
::`yK*!G+f_)Vqkl=tfiT9fQ%M@(mD~$ru$w#peZ=0MkP+7*RJDT+U_4l)o&MT`uga{E/X]2\2(~.F=-o)#jr,9XG[szNQpKozhtsszTaC}sS8OLUh;z4%c/Z]<-|dIDXu{n
::[pP/xhi{zRV.5R)4G0M,PX6`igI`VbKM7=B02&E0)fQ]%}Q_Ay8sbfI[~;xi*!uJMC$MON_gIHbp.@D*2XhXR4<VPQ!KnTdEF)NO6(iaMip87/p+t_V60tXK(j~^<[6IGF
::wFuvdv37!pi[Jt?!Z3dFDtx\yFUC`F$OO<~ynLZk2sKjc;QZ5h%VF`u?%Rv7So^7s!a6C|bKJ?oFEL}+tzF%Y[P0Pew5Si-lYn1s}G0Mb/JV51kelF<+a)FfS=fy=b8_3Q
::PFl/F,IehHJ3b2\50KY,coBqWf*X#AixcvV+HS#AaC%iTq!7CPMJ5S?gVvQmlo&d&,E)NRqE[H<CkC`[;7N6@vA>@BRGz[45#A7/;d}WrBse7z`jN)!u+3ZSE$EIUUVL`+
::ol3~k$=mds}b[vap)Ms#W{aQ0vQv/xT=wF5KCNQ2[Xtg$xo,m=1f&X08[z3ov?MYu,r88k|(~=hi9@om;>~~->(N]S~}4D%<`ThlKn3mj^D$1hO_>{WFWCw&[q]WCt0/q-
::1,|,Npa_~nSS{1xUvnu+h0ZUb%U^mWgHx3^vgZp!av)1YQvL})L_y[P/XC7`%#l&)UkOH{wu7=Ry@|i_`g5=8QGcOZ?n0mdKW[0EnUGwV%0jp5{C(&~Sf6)Na;m7}I6+1L
::as_Ha)HGI@{3!%uxR,D7!GBa;P/...,P/9J,Ad/2?y<\u^1*/+u3k)qxzXWA-6-U0BAoSR)CdBGr$b\hs&~ci19{Q-R&HVlgg#]JAasC}W.7UbEfU{$}1uARH1UV#ncqRy
::s[<NQ/47\oIG\o.d!{*cJ}_BR2{.y68NC4yo$|VCvytzoF82KIcug;ZW?3/\Z[qor=V@=4xvujQ$m@t[p~pnEnxS]^nNo1@*P!oGO)+kB?*#h|YTi4[t(LY2x_qnBnGewG
::cmKip{FtQzc(fn.`g9MXcsp!Y`-,/^..HT(2qPwz_67!4ajssELc#Ml?I$[we=s9p>A6Rwq+N@GK6!CVn@#FQ$4BQtL[~MHmFSkg,t/|JM}XX;FbGuHm5*A1g^kbXv{FSU
::z0i88p{~Qyca=CU{DSF_*+yVLco3VjSo[LEk</u?>|9]&|o(dQUvOH\X6?J1N|Uq2pab@bB4-ZZ]Z2%{zVUJ-$UM\l|Ecd3X{gVa&`wTX8Qr\hPUhs=~1;Gy~s}PZ;jO8d
::gY2g~0~TCmD+\F;1B!/)p*M0Jc?uQp3ROK8f<)d!-=^3~+T@R2Koko/Ib&-tkh|3%KTi=!W}@)c!Sf<~kr#58y/q_EAX/bW*0MZ<uX0#mDEJ;HI4;9A5&&$WJ[NL6Rl$ww
::EV/).?no_vZfRZ%]cJmALA&)H[8x+OzyA\N#)uu]xboH{Y<sTZlsN?[4A[v@lKqBg)sJJ0@=CKmV.rpC]MMn,#vs!Up8!IsKia.%Ftn<uBJkH\EMNWPAvaG~.P~0E2mTm#
::kBNbR#t2$@G>uYW?P7vB-_I8)1rk3L%.USyx-_o`[1Gdw,p9+QnZL}@Y.[dW~By#vN,l{ApA<9j]V8%P}dzv2VP5YYR\$vIe;yno9Gy\.=0Iem}8=Uyk!cM[*Qb/w(d`I$
::LiIjId{z#B_a6AL/~oa]M?_KQnCa2@NTV*<OT%\Roi-e3x<X`NuA8OOvcxku)WHT{SQ`3Mj0F3DSZZ\S/ACjTZs>#W=W-<6Z/9{Zw0*0c<-wg0i=)AZ/VB%cXhL9Vt?iZR
::-HFf4}@\E$PweR]3m,pb|vmofI}8(gl@X^5tdQ{9Zn#\P3ntM,.b95@4k\C}evXF5x`E!8(~;*bZI380im-Ux]]pdX&0Oq(,nq_,UTDWED)6sP^yUzSJ|Vcq~3[00<s2AX
::J\jQ00._tAIc91\\=_]I>]T,^s|dLF_W*aTc1_UIw<RqIpxmwH0GOyF8-98yJO0|%?R,mXN0d&8#LT&\7X.Zk]v@*6Uz;?Ea5)K9DSH@%mW2`?pojQwk>X#ciqFrXrITA[
::fEAVLXyVAU>23ywoJfo%AE_dCp8bb_x<P_iB;UO8W8IYvrq69Ac=W1tO^fKb1*l7huc/g99vE*c=ZpZ+WOj&hK#CB6DFX8Lmg3sQjBWzKRjf}J5aS3gTU?c_[%@LEeh,=5
::w(z*FLNs3OU8pwGC{/Dq[A_\((S|>wMT7trP)ka0dx*7KsauWhVtcV<<q`C3z_r`G0d4q0diLK0Qk}G(QxS9g~TvrKL5aXHLl`uPRB@e3B~SNfv)7_8T/A3MJW}%6YZjV,
::s+rX/J73A-3TT9JO)pQc>Zpr%mS&6$&JRfXyMtewAy@NYQ#2|*`pRw]4[U\UDZDVk*4Gq&g88&eeYL<ZQxDI<9G=GT;j~oM]Qs4E^e*Wjv|?H[jrNgah#PTEsD1{b`?4N_
::)lwRB$H{1TUmP!$spMbb&q.b+__|=&`k3)w9_j[Ux%qge{Xp+c~b4Ki<BFQV36+ZkOt+&e#>C1+Zk<pHuN/.d2RI_Rhzr254K9L_[\96!gv)~(<VRxHePFwtQK9Va3l]0L
::[JrRO+nX>KwblzJ[[EQ<02xm*s_#LUpeM7^8H4oBjoQypkS&zU_&k9t274&<(FN!.%FWLM~TZ)n`X!W]HPe0a&G3a<r4g[-!}MZ&/{i$Cn+K6k[@Y@[QkdIl1v?+&4WU>9
::\/{u$2-^K`]u(E7glo\$OU.AAD%#N)}TJ@L919dkIF^?nUHYCqQ/SN.^?xD<?zCr8@^6mEDq.4eNB/0v>S-jRX55cCCH_o5&gX9tqE(PJ=Ec`eKa73{7=ZPCWxJc\R3a;u
::=EP\k@lLa;m8R`UMBJAnIe@&_|/y/h`K,dh&;@oyv*LPpLE8vsEj&$.K+ooy-!ZcWB+$`j4\@1d!t!4bjZCFNd/zSMX\Q/(R\BQv=twr;R$+I`)N%Po&sZy?^7K$aF`B.E
::~80w~G(%LIda}bkmBT^K]M6*~9P!;RbbPYo@!`Q+EF19*Q-87<JlRZy4UF8K)*g8Pzuk{\{+2Dg#~V%89C]lv9nj*{R%hezsH~[JL*KG;p*$.Ay!6hw]V~xppX|K{XhzMx
::nhYe7QB~*upr9e[qJykMSuGy-Y=wZp14bl)dv<h~hEat@gxll6wcXZ0mnC4s#F6EvJB[NDTDH/GG79hYCU39#8Ib|oR8<)J~,m.-$>?t#OdvYXb&@k+J}X[E=!IuLdhbh#
::Wz6!Z<U~tOse8#tgYqxkf|mGQ70NG],@{h.Bu5.6*yi[l]++hq3gLly1JURY&4-p#<;6a$y%F?v//`JWP^{Tc6TawUK7e/ZGhR}Y4*pk~a{N=SiselkM\2lBP#X#B6dUGf
::&E/_n@NaM3hvfBc\]fUGA~TtSS_?[\7q&a8J6,Rrahk9E>BEu9aJ2Q63*yy)8#q!1S8mw`RSEMG+^tY<qh{qdLi*%_Gih!yoI[\lMq;GirzqjRI<m()^s/Ab<`Ay,5+lJV
::mV5!2`&^FS4E/1(3dN86v2hcNbEN_rBt?\u0~9bm3Bx[11@rZ2H]vd)E,!(;h^-\11<E-<;=4N\E}<hW/=(Xig>EEE^@*u2k<@G1ozlYdQb^~Bh#zdn0gcK\$oQ{cJZ7[-
::Y`>@M3QAQZnn?rK=iW)8?X-ciwnj}0DUaz37^CON\E/2{S~pw3EE3@CmY576n<=\Y5d0HaL*z0`hOQX+,g[ybZ3Os$yK+_<@lq;7;;-_b;2j*6@=YBugCYQ![o4BRlK%_N
::d^p@?BAqXN-;NH?pAA?O\s/\p|b@y%5Bcklo}%^7.gFUA%TS;R/\!)}o_u}4LG,g%47XUo1xf8b|A86C15K3t;1SJE+,*Z;%CCZ]WjeBmuEN-!HiAGr}Yp-sk$ItbntK%k
::H6pGLbN4o,J;4%>}|SWV4,c~FXzRwM%l(i6jE<,P[eG?-lA+W0CUF;/a6Im}oqIW-!+s)<56OE!j%f9Jr.ID@|0AO!wmK5;Y39^1sUFPQTrA?%^gNSEB9,i|nIGj2u&14d
::AXxZkam~\>$.IWz,bNx#Y/r!L?pjtU34qh=ish`bI^\^B8c$7e`.D.L%Hs9fcY~1Y=aHThv3#}fR&VBM.=jQz,WI4Xl2G,5g!QWaNmM-&)9tinK|B1}aIej]}5}REIw)!k
::\z`@z1j7c9$_!xk|z?jXDy_3rM]O(cw}oW.f_4H{ar;^Ub`_pfj_s!Esz@E<)$XKU7T(<c}ITKarLW%dA|?[[v.;+Mp#k@;22-ieA241*yGh({GBKA9}9N|3)4+t`B8D,1
::O?7!e24fXp.\S^o)A<l#4SD_Nh|qQ^_q<w\<T#m]*u#Zdx|<!~Hx~v,>]hP8Ix,/Q3dqPaq[]lV`hBJOaK.bm?gwfb-hcH19F%F+i$1>;VwLsboFcFu{@<f59%a-+OuW3L
::=4^zBjOJE*rHP9\AKX&;BzYV8b3$sL),,rEUi~gX*V&tYux))d,gY!6K/dd<sURA&UO<Z!\Je|Wrz(Rc*l.1.@frpzCgv`u0$i*V3a+,il^AXd%pAP9y4j}qU}\D6K@bjT
::.wzb6@/kfQBjK[lw3vKVT~n9PJ^Q@Be(~<FhJz;a!OT*AG>\ja+7?_(|SimHY&VS3MP{.I#fz?}$Y}d2+G=C/Qicvb)Sv}L5!OR^^(#)%,&+HMQH#Q6>^zF(/B(fp8/#yI
::@TBF&#0Md{QQaqJRXAL\B~VE2(me^aKRTKfVK^1j1g,E_Ata[$RU06CJ$bR4O&q2vN|UL63z<<+%f*#)M71oUoQoOiJFY3>Wwi7HP-.ID}6-v0P.oV);&1oy$=or>yI]Wc
::m?IO3C^)}2(1X1y53S5@*eY~z&`+)Sk/Fm6%6gA6yI>ROQBFbs#rzF6\ZBjX!_XM<_.y=(3vrhCqtzSckZ-W*(cYd&+bl{X{cN]cQg/DCka+y{j#my)YN\$i9(M[3S+>KL
::fx(MIDv[dGGtTQn*J,/(HDaToGIue(i~B(h\.q|q!c`&vP7ndPmkTc{W,&et-jD.{yOTl&Bi0<OHeC3ka%`RFJ+OpBUtpdQsOS/~hBC(#9!x.kWV)UD^yl5)E^~bWa)&$\
::=zTuPIdRu_@X~=F~!t}|6[H/2RpwaX#qaYythcos)qY9Jwx(}2hQm%3;-1NUTU6WrwPliCF%&yq`Z]=Z5M}qH,zy#m5-v9w~wHZ;uUkMfKoJS,eVyl}>8FeRCijR)i5_lM
::C~j8>ayK;{E[_RKP8eeCUPyf?|$eF7#W4IR\{>tE@.mQY.{~1YD7x/6f2<}y62By+{^|xW0~pOyP.(J.>|+U]R9&|<T(<0/1g}x_ZN,k,.I->1F|K()ti#wQ?{/j*V#$R\
::t~3Ov544/h/u$#WW=FWtB5>H-Sj`u5Um2QZeaH?hb5o/S_jMAzyQ0\Wc#N`q>6#h5X*ovg*goGM}ic$A<Kxu94nZBP^\66riE*CcfH1c5Nyu6t.y..>G8Q{3?tPUxm{&I}
::7/3-ob&6TP2[;>nQXg8^WAV7#[NEwP9YP5}<I/R%eo7CY7`U@Dz!U_1RZ[We6xj.mzhTT-bCRR^k6^/I{<&\~K{3|p]na5X|_{6)pi4@n<z}U2h%liHu+qYg;W`SB;a}%G
::f^ImeN3\j#+}7yeDIHuGoSyu#A]2_@q=g]B65Ip|6[Gd<nu%8ldN1b,;@^,=%hTU]WXvMVYi{YXg_/^BSb`+,Y[``0!awpP)hbd78!%%b,yl8I*rj07fa^w^0v/lJwZ^[W
::{P[t7udwB52sdloAM)^~1r}k3vG#16!Y^+}ISjf`^++wwHIUY}rOZ.V8>1abgFK_h/V,|m[T;`];NSB*FUe_|+66exyDL3(snz+AbjtkVb-BLn7&jv*(=&kJC+cM_F(RRc
::9n&P)AR2_G^08eE62<6u[HOhV49zfmpnq^p[k\\zi6?qnI=Mw^zV%Z/fAg7UQMF6H<tPv?-`Z[|=0$!y!UGP${M7m#Mg2$Yo}Ue}\2fBa*)jHWMuAIQ}a@r\QaHK16(lL`
::YNscqNCVQyf}~$hU%%oVj<1=~m_<t72hh[;+Y!1KK\>)_7.2@e1z&}hS1<I$z`f0vS@M\[0_[UEqDV;`O7-jTNJCXZ(?vRv(YBlKfPAimMV2<[__!7S~iY;qDgqY6~q)/V
::mn,.\?qpLf|Y=,Bgqy&.(]qtm;`Rl|yma)/.*o8!+\CYbZe[-#,|R5J~.(f<$<XV^<;KJi[\q!kg.2*y,U\q~Bxt$VKdgX@FB^yS~STQe~Wy3lmy\jU]`wp<gJLKu,zPS^
::Ub^yJj8TXtq+,,2x\k4(a+?#!Yce^~JA`NXgxAxu7o_+yP|O`Rex*9Ot2F{62u&XyHUC.srXj,rjJk-_N[mF(kT|l{i02HJyj/jmAJ%o#MU(#g\LkNJy)vzW&l+98ME3=w
::YL<T=8wUK3\^1~t@^6G7E.)RQ@8GIoIa3R}_j=P[YncB[A\HiZ]W@&]D6F?gY^7wbJ\hTAsrlON0tV({I7D44ahyBbl\I#BI\yLUS-#GRq|.+DBC0(*whkwmMajJ,NMS.9
::P#OdR%#P}^y%swjy}>b\^Ueam62|tUvJkH/jzB_U],uqXn51^GWA_\lGgeHdc~Gx+bVvud0?9jYnz*_aaMA]bb*qLnoz$,]1=VPy,f)_q!~7~%B(*^xb2wiO=zK}q@)u^k
::6WQAVL1@VOyv0?Ws@vkvap4i+Uft@.Q`SBO&\|?7tPyw7$QA2~OX_`<C*HE}uIzEw0^h&rb/SDe|ptsqjaU7NCs=2)_xR^M<mrwt!tv[pA#x5S)Cnl9]+!)FB0fdO16xUc
::*EOB?Xj]`#W4%Ob`pm0p|!fV}`B\IN!so%,_!)U[pCTX/L5P^c+P?&2oYLZk1\l]IM3j;c||*SceCXA.OMMhBx,PECV{3c[TojH*Cf>Yn1tlKikygsU6)_gJnklo.i`-hg
::T$[MWV{twiviNt3nmES^5M92}Ceo(5q*Nb\nh?Oo0~#R2)lMr$)5ou65%+d0B<>RrJ,)`gfNvCiRwJ3s2Gedz)mG\\kd#@X8K*?AH,@X}iPE,y-h>_~bs%7G+41{dCS*(Y
::ulpg/9bS$^!7)jImZahR(~$Jp*nTcu89v>N2O~#hsuG,\lkK$eS_hsWh#u~|I8DjdT<Du,o9`LHzY1tcENC]F\{WCZ,|1s)\*t7T7RmAX_Q*BUaKJ2!`cZ=TZ/FNR1{9vK
::cPy7Y#m!pxlLd%GIjZm810g$P[Tk/0U~rx%/dG}0ldIt;ih<6v?-DvtA3-kA99V.S?UQ%!16JG0Rqu<6J)=Ffv+#vAqbyK@vVIQ;H*)b|0$tUbUl@y!41)d=|0Cx~n}lqK
::w!;P1/qCu%C1doWSC`%Ca#Y$,*Nh0E`zNgm=,CJRXM/boP.Y6aKbK/%TS}05vto.EIN5?S]Twy`xKy>Z!O$R-URBkO>p^k.ON#Li;>Bu3Na->n+1R?bO+tIZjwbEv\5&Ie
::O5X=6l$A*<8Y<*aZL*\tYT>A#3/m)<!3aV^.HX!`IC>wPT\joak~k~=S/D~]MM\+Bu|_J!/o`iF6,|!Dc#(V\UP_,xP(}cY,`\>p?^aFwCeTV)=~Nwv4T]H0shIy]j<4ua
::%,O-(L)T&/W$VciZu-rqY!>UErKy~^l-7}yt#=a7e.3t-E;x$,LUHo;8?=y_>%DA0Q{vA+F[Z5HTDm@Dx2\u9j06/#0G+1Vrg5&d2$kb(0H%u87j{t8.kSL?^4KtjdqY;P
::.]<O;U`ck(+R\%0CY=Q%|A*~v6l]7s!oR_`vw*=tv~B<J*kTcuWI&30jm]w2D/CatLgJZa)&fEk<cS[ELUdB0U1TNf~rL<7(0&M{O[B~eY5)nn%\-cD$K7UJXVOLKGz.]L
::7XIuReU2f4XAg(d9,6.P5Y(w^^^<g`6r\4TY]d=%|}~r(UncJ}jxz1Vm/mO/hevy-7_Thp{os&a2UI09VhZY@!{nJ|ahnlG~2S>n\Sg*<-b`<nT|C{_5A\Sq/IF@x\xqg*
::0vQM6AcW}8,o&08EmxpYKx|7~P93(@c4p8m_{`+\tamhB;PkF07AXH8=n;I!>5;]k[x;+1wI2+@j<&)j/he55)%ff2E1I,)O2_Ql!;3_V,h/c8m5NGY7bE&jU;V~/jc.2}
::!5\7R9!7dBX<s%tQY4O1H4hKE3?G[34K3YTeDRCJ}=A9%3d;sMY$=LLQ]yj$hd[AZ`sN|K(;F](Dt#+!qVi?)/$q1^jN/s9-zV85|J(VmOyWBAcMDmU#Y$wwDRBu`1XhGn
::tW==bC!n[&[BK!BKutoYH@c(souY7kQv2Pvx_%Sx;iE0@XQ$)!fh052oV]C^a|0(dDz-?q^9<Td2?AUk;f>.MK0+afVMeLTZcT8+b`MF)k6]KyA{PU3IyFig1JC`U%+KC[
::ES,h;+[]xzjmOk$AZuTo^hbU,H#0/$LVA8=%`jbB_~jl}<J9|pAc+zKC1vzhhX;Xvjlf_$(cO3943<H8l;;tJ3GpDv!{lcG_AEGbEfae^etN*u(\}>!G;[Z5F{07yv<xP-
::a%jtx1/`fA#`wkgg9o5+<XPNoZ,Tl7(mpBCi-_\0ee22Zs&Ld{J+rwyhd49su[^Yv2N|L~g?wljkb8j(}nQbe>974lP<w,c,R!ih4Y|jvwQJgI`|ZPJ~5ktu(M>\c)lgU@
::a90@~TEhQwRTB,.D7oyL+@_Q&Et<Gv4ZMQq$_1Gr5Sj4f.wUFGk3ODnOMWM&;+S+,5kxCn3a!w(ep]M-+}Dv;[+uuuYhSoDu`ys-vVfOcRChr`kXEz+_D,\01u8rS/7dfN
::9t`5[M)TPf5cWdv.OW@Io\px6_^XT\P<@SC~|U@LkGbYoah[W-vh;lDz)3j4VfbFAm*GTMpyBoy#07gf-LEuM~`S)K6,xkDt7dnW]$dA2kKLLc#*V.m1L]k1usgxdd2}Is
::{v$x,uMG,7e3&|`iM~JAX^*jY?9h61*bid*8EK6K[4Kbg3`g]Zn5Y}~3u/xk)GZ~#CFy[u++3L[7M#GpLGuZQ#^c.].^k>8HiTxISJ)-Cq-zMTcfNO~F\jcGL\}lWo.}Oy
::_sr%(mfG;P-dE[Zy?guRbQoAQ}#@D#\wvre-bQwL10W43jE*PTC)qoCF8ETzU~Wz`dI!v[Zo^Fc!3Wg{Sc@A_a}c+]9Hn<U^\##)$7Y\W+_&mznM;BOM(x-H>st<ts#kB<
::O$}-nr)[fS+~Uet@Y,Gt`q{Qt@aBo%370W~KKi6dx1ZDP]LgXcpOtmg*k]uH#-Y9vDM=vL[-D\>?<tEF.1e1_Qi+w~Mr|3mZT];%k|XCT6in*\M[tM%>e9OR?sBvA_ax|$
::>t,-LDYdKKx5=d<jdyNO9Qu3vu;s[$sYjzxV-;!G>M0\/?h0?1o`.~fu~yE`rUlAol=yW[VR;tumO;4ZV%t=uF5,%v>A~i?Nb{81|\ZrORi+I66vy^U2{i%Wn/m01=[`G%
::{22l4tMJ]ZI##-Ht=\_Ik\;d1XI1e?_2()BQ=<\spHOynCks{W@KFR4;@GjKegpGomAp)-Z)E8GqZFG1I|WI/h{=}IVJ=27a53i47\i%O*5Zi7e;nmEjShdKqF+z_\{rN#
::i1U$_fK$!=I}A;6A7;EM<$5xzbvTWoMy{j54;%8KS)B)=VkaY;<{Dxt=ac4ckbu6cTCEzbKsyTVLM[eekyof/aC0Jxv=S_(+x~g%@\aZpR6Gj4y@,j6C6FQ]p-=dY?kE;@
::,jKHd=qu8<ER.<t(b$iK)^/-Hjdo87I7}!mTW6_aJ{5tQ|HTDx=2[r(*x|SAL%}9@o7A)6a2cJEmaa^4S*H5XdNSH;65UTp*DMevDGC3jq^jo9MfsNfiZ`c2zOnv*BkA7|
::$K>33ZK2dg5>FjxEGpxJ.v/ifq=#$Hq0-8F+hY$cH7}UU|;4<@$zLN^IQ#)/mRj!3@@U)l4X~V&d{Aj|T]eZBG+9XC{a4(Y?bC+ElYNxiy?EO7Bq6HKy$+XEkw8~!|H|h4
::[(w%U(}FlI?D=h3Ajx=sI!CbKm{c0_<UzPVcz}BX-U\dyxZCr0zx-x_99-h24n@U*YVy1mxd9~BsL$vRTa$N1!gTZF&Gs_lf,fOJ+/9mlzvDv/@*Y~w,05#?x#IzV[CA4J
::f!;?SJoU.L}}[xK#Dv*Y0p#sDfF;k`k7PSuuCMPcoUnh]/<q|sb2NF=j=#PxA\9(8F#@E2A?,\ZbL~]YFf!%Ps7i.bct\t1<jCQ?JNB3|4KNS3V7-,wlbcJ`yjoUKAlh{-
::s9InrJrHxc]-M>l(AX-?zrRHfrE3HdH*z^><nJ=0Qy;7AzBk^(S$+a9(rkDnw%q2iz;rC(D;Y=swx`=!dn/*;cHnRGi~<)PsN<z?pSItW5RDlj8ZQGm?NjI~S#Z!-BH3Oh
::yo1Xp&{Y,`0-w_d|v.ZETV%H$xulm<H#JOk6l.,i@+Ga?sP;\0_jU,dA(r\x>V;VksXUKt-UIzP[}?64yu5jdf,jVe}x,V)l\8Jr4(]@a/|dsj+m!;dMQ#/WER&B>Hks*3
::<fx)Hg$HulW%v75cH@SZG-!tKU[\1\&B]uSPt}k=RTAOJ5!\b7d=&nAKXAJ[?=DtXw]k2$IO2kUkwichMZ-jzY[)[F/?U%UGr$mZ%H-Ml3NN/c*x]*vw3fq-&GA$35?RPl
::S)2pRWkRag](_5FTVGn^jo4\)AtG({vJx8BXt@6@)}}Awg(_e%aw9AXP8fZIMYNRz=;THJTYKn38&2XLD%H.Fc\.1`.1^4LOVpuo15SK[-ApqOI42pSCs|$NYzV|VVAhut
::/,Z*&<_I(x}#eeQa^b&L]q*\&XP=F1>EL`e0.*NF<$ST1&P9<b>N-8IUH+e<ytY[#4@{bDrYYFc^208wX^[HC>FUG|~HA%J<`I?&>8tH>JEa.q|p-E1V51ksl/%wf|zC_b
::RFIt-qJ_<X`oO=[Kb$cBdHXyFx$kThoXaguwFd$ZV(o\g/tQY|u)dYnV%@NO]sG*i=,#Fn,^EU[v4cqIO@U|7vo<dS3MwB!Gay@{M=2J&((x\sM1lSL%_j?N2hYn\sOk;<
::G$qH<&qVjylZ~YvYO6`\1U}k(n=a}\<*@1+N_g*UJ0aq]zKBsG@/0M]6x=pV-p0EQ39hDB^@*$+aw?)-1g0n8n,d.;Tk[y|%if};Arn[xw1!VlmB>XFY|6H8Qz[lIAzv>q
::u9BvTQ)#U_M.scb]^<Y^U>](C?zoLRH\eVe$Tu?Ra\=?hJGv(Rm9ih$?_.ZKuNhm\r8Z{1Uid+[C^me[WG[cMAhvPllMl/y4lV[){RLznjr2;q;#j/XV[Z;oJY4n{vGUy6
::Sw[EA6vuL&NopAo^e0<(!(S3sNuCO8GEXJ2`C<.QMUjM~~iKP-pisNQd>1aRc@bSh0qB3fMP,S}E.7=njS2s\B+=nNIRE1=hv[yAJ]/16c[.rWjofU>vx^<mm\A<w,{A5<
::aMj*Q{s|=r)fX)5|K)?L$w_V(BL`THc~KS|V9gtcS>c@tT@v<1jZtuGr\KTY4[CzIZ3D.%7^E$B8G+Q.#/RL]*c|7ap\Lo;!R(G`@{z\k2KB`<!8o;Yd,_DR7IgHz`;N~V
::Z;*TxxbOt@`/4Fs(vff$b_$q<hx);)[r(|~]X/FO]46cxLSwdoIh$H&Sx^*W{I5#f2Bv\4w3uz3J{Oh\K|6s9V}MI!XULvD?Rh??<1PtGv8vnaV!8Wx8QTuSm%AT!Z+tLg
::bcPxyZ&|Hd4MH%X+hYgVs-I^MT$+l2YNkQmDZt#omV[/D<,N{m!Lt-At=Lg>=nGlRpSqLtsh@Cwx_k]JeIKBi<I;4)2ZP<d>2aYA_KQsrX|vbfQDO2%f*z}olzU~`%DR2]
::R[!ju{D}@8(0Vx@h6IR8.=TiLr=%XyR2Ae7sR|WH{-jGfBhQh-AUWcolB-B,Y8T(&e6bK@;V\|HM]F!y+Gfh,>u20a#^[B@MRyJtf7u1eoo~l78Y2d>s\]J{[p_>NaUCD@
::s9Bj*haeYL~UxaLYyI0+221tP\Sl.|4^F0y{Vj8FQb#1c8k*`\!$7M?(#(LLmAP{cni/+IY%g7qr3GhU?i<kL%2<7G1E{$N#Ae5aUf)YTA5~H*d4teH43.|(C<J^&(Ae7t
::eAV4ifY)qO&_ZNSKPLO$QcPV1mz9pT^KCyw)48zyA/IVhQwnPK&r~pv)xv1rSn^cX<3=<S1v1~20/JjLfT[|ben2Wd!iVE&^j(.<I.sp^2s7cLei..NpiGhbE3V%`!21aC
::Tl\EIER84$WKAI1j({r3fS!I\N9~c`NNA+`so=w.n!RU^2nSAuHZDs/2F3;fnk_*K`p!i[%PK4`FhUi0LQP7%&$=hEerKF3^!o[t1jKNu?R^d`#V6cZy]np~21%os}3^?b
::jnPd_zct}n_Hjz~!#4Ix//K;x[v[?wTWnb]8HG4u79GKu4&+4MHM0%c%HK[NWGX{oY2kk_QsjC@oXLye3Inh|^CN%ccCxs>Z%~lG!LG\b+ox4+AQSxggZpp=KxJvuM]1W<
::;~12S|4^AiH^+SAn)aKP!Aa>WDc,x8w[ETR3NA|om}H8%zv]WkkW@qM<a2@l9Qd7_$l\bynXM#%rQ2qN1NtMUoyt!-~|`T@Td|#[Q|rT_m57^R$J`=E~PAj2ToSQBl,>7T
::\\!(`@mle5UGT%,bJZXtE]=ng^g_%wDJD(Da,OkG/z\U2e/$/V7v#e2HM7nx^=qr%\KhX)+=m?J7D}Ng)8$CBf2?|%FEc(XO/jtn]VFV8(-7Zt,mZ5zt9Fub@`M6D.;zcN
::U^%]Y-\q|1DU<-ihjpZK5%sLx<1TVN!y7b\\WN`XX0B5F*z4`U^QVo;*2%_b#t?&WQ^_RO?VL!KAO!}Se2y!#Xr5]CJW}|sqP<otf~^Y8(\rr@5w-_X1`OerU)Xa`{S\~k
::!~^jqwE`v]EVL@0&bxdBwv&%Er`*7L/^T%k0!58g9|/&FMbR]jgyOit|E\,F%9CM[u?bsur].%ZZOtZ+u=-h?oW69j7W@`0<]T~w|)d*LB/BT<kh4/3vPaWYi^;3Bn]opb
::GWqx2+{6BZ.g7;S*^`=XDDP/7v{D38)W\cN^iq%O91fnc?Te@;0\Fl!tUPC=EVz*lc}L*EtJ8V+q-(</6]>BGyp+W`pu*$t?af000-i)acR<lutA_*hQc\m0[$>CB!mW`|
::-|Bv\7i\yhDFs{M[7dXEw8?,-r(l,Iycq3CnSc.g7,;I;ERl;\RG*GY+g|-@Y4dg!=E9+m1dR0QK2$Z1ypw9\c6n2j6u&<x`7brAE<K//eE>RL0O937O>tm^nZH=1z11}X
::E\C5<puCY*-N]i9Rv~V&/z/K?6j-NUp6Wu62kXEVA0E`dnrK*g[BZ15$oZZA[hJN-M?Cet(*oZmi&iS0|0hLV4`GKmh3W4bCiw#P?m\#n-}+}}8F;+~*]zNQ<r69Yc<M=O
::m\2+jYi}o^/nX2igN{xq>]i#n>22.GXU|ss>lGLMiVA]$\k#8+4L_bU@|S?WYM?[*%sYsUtyK,EHZtvQUV%HK3$t.+Pww_>^Vu(/G@0dU}dj2P&wrX)FhZqMrQYWez4X.&
::+Vw`=6S)vf5W?\Nf$3<eIGv2ue4O(c@[lI[u`;NiB5XuNvpD0]D!=YW#7*!OjIrw\B(}gJzlcq&;<@M_ZqB,yp!%mqL5cLQy,+L}wuBz(HINrQ*;mO@YLa\AoqhlRAD!jP
::4g/eD64T<J6d;yKNX7%253QTc-0J2K9^.V}V|01^%GY,IT1b9%f)5xYT}GKkw1!ku5W4fs@^edcphnR4a*N/9bb15w%Dyg=2]j*6n%,lgW+11bZxaEp*#y^rIS\\UolqLn
::/bw~PEkq^...`Uc6svpfaUnr\FiZIl$}5F/2zMp{!x7<;)N{L0BNBmTJ[HG>+K;r9nZ=cmiJv9iz19(x^^>6mBCbg;MGkAM8IewS7j~Pd|9rikGn|^SoM-z}SS.~O&1(ix
::#+(TG=C2Oj(GB2Cf#9>4M(Y\Srh?{-oqWH.dVzz15p$!]IZB3Cy1(b7Hkgb3)*_e3B-.g-T(!}4(%NIZ0Ue7>uh!#!Mxhsiz?2>YBvPk>FyZv^^Z\kemanIzdM]a2*Kzs9
::KusA==72W$K&q&1+&ix[]v#O8Clj.Qcyj?gZjTARirX[<q,1xkvz9QIrxr8^kPe&M^|FLSDHyYhrwB2Yf^XBs2KXw;0XC]tp;_[4>?JKHf\b4Qw>QBJTfsU-VvPTjO[o$2
::n4z2#h|Z*Rg]y2Ct1/&#oL}kf(jICRtxgK>]&Hb)QucWGmr=Z+5Bt4&Hh%%\T1`L|ro|7HAzfE(C8M7Tr-\9`!kGfk9C8WhMdu1D>8#C/Xn>$k\6w1IuIo]~[jf-g/G2eV
::1fP5KhSHna6@vR<_2Y*qGEQ]iqgMIX3Pr\20Ua@M!vTotL#^J_;+6F7AU,`6R1yn.c}P^85|St$3ocw}A,Zkxn6^}QjHs<6(X!q~i7Hrc|K?{#>}4p*{{}^K.OrnppcXu@
::F`f_jp7VyJZOd1a4{@xI%#at3IHH&,zB4qvQ=]!;i6@WB]CpaDvVaUjB,jm]#x*d]zC7lN#OH^70hQP*R(X,GxSY1n2+=pX}&)2A[S7CMTn|ZU;T^+z*~ADn}s56g$f&=d
::#BqYl\$Uarry06_ILgUnUto<LZZXrZyW5!x%0STIEQ9\qrY,=X3kRr$]VTou.it1Wc#&pr,%=#*&Pu~}=0IiGFmK>?A}Z{=K=wF@.BP&Re[G4bium_H;PZKZKMp/H1=!\!
::}2;8Mv94RbzM9yr>D&9iBA/61Tj!8lA1~j\?(c5)%c+WLOJ]~7d~*r^d@H|<pG6?k<th~5^m7~a5=P^e)d^a~sg^Fp-Jhv.Hk(<ycZDxNK._p\\z#;z}bJc4P(/~U6|EXw
::_#(`P2BsXc2{!nQ6P2ETv[.AqB!KiNWx@j[Ta~}hJM=tk|$&2#(VYF*k<24btLk~D5ndPhXQqs8*|H/3a`_Gil?)JjF2\HGHkx6iBz)_[ag8Pv]QflE8[wg`UGbI=Lx8?6
::{\hCabB9<25xXLM(V=i8jylhbjV6q12DjkKFj{X|B,&w&**xWYPz^qFHT!d`EN&J7/qx}wcC%~e=]Orh~I~21w`BW|z4pbHtIbOMmXs1lGm3Nj;uPh.W$R9q};I~qbRB(z
::%fG7ZTn)yVHV>xNfm?(pnS8wPv%C9y\ppiwj15Z/B.@lT4TbkmQps[WZi4MlRYVm633bOv&m>X6Hr&D8cxokj(647unuZY1wCEy8\u2V9cd@`3p&UGif)FJ{-g9l<n<B!#
::D([!mF{$q}&jrY_&%MDUcOA1-b+VY4$F])P\nmP5f5DR]OyE.bk2<8NX.T(^w^uc(kDCk,64Mpy/n1Fa`;YsOl#?=+S76;Q~Gxz$)9<!Cl+N%GLkoZ?I[j(_azu(;IjI7R
::|wq&G!z|=guR?|DDcw|8gK*VeZeuTj?h+M*hHu6iZ=<?22oRdU[{.g5GR$cQ(Ins?jzFEX!k72?5M!?nZo/L5x&k?ForIgCp&CL^]6}Wp&>3{wQV!XT]M08_ZNC+wT{okr
::$v<7JFAMYx2F[;IlY|xKN{wg=xaf3.Tq>8#~7x35Cjt>L$^F%t;28agQ/+mX$bpV)T}wLNL26+uBJV/B.<_7Vdz$U154;9i`5+eA^2Kd9T>/jxFQo[;45(LyXR}izWHD2>
::ZKjDBnr=&`;%+,Tl0\-eSS]lA.+zxa]l[P`d<e3aJleS3qKcIF-VS}Oql@DG!Bnss34J9`Zh&4!;y%5T,L9A!`^f)&`J9OP2KW*FqEk}(3>K=\j2Sz(dsef$,#A^TqBIxV
::PIx?@6)g2l?u4o|@0{BD@\q_k}PH5StvnRhrML*C30_fs!%x;/;vMr%4[u`TZ?nC)MuAA%9=^j5WU<V]<@>X?T@W2?GNw_v9WO$2gF*HZY#eY0tG+nP@@T!r``Os-~u1fL
::7W$91i2]hD@o&#`Q!c3zIf{B6e<$`L9wZ}(9,CGz<KanK4Ah,O?nrY)=oz$3oE{lTUN{)X$IA)h.9U}yZ`2(~ThI6&G_T/?/$a^whYr8H=wfv#TQd<2b`[6Ua^ejK\8r/J
::pXl~9JZE8.FZ=R@icS-|MA$X[^-{[uec&x,vX+N[_U*2!|hqdAzsTlp9,KWZ_i7}u;g{TX<;MPMCUWh$t#x1~^-j^Zl,l\*$[VXDMlJCCv0[16r,tn`??a/U<Z/@Q^d@Eg
::TJz8UPO%b)XV5.&ZC@UbLM*3B9mgrrKD|H}\820I8t$9m)qOm5wfw{|7r=Pd{3Z4|aNDcsJp&h5Ln`U.xxFF>e;`b\5U#qZw|D$kB^EjlFR*i*$Xj|$\*=56euI8,|D6gm
::v;qO*UDgV@H~P3@+d}tZ}7q|C(M@YyVR8z3$l6k&{WW&2\e+_57j=a\Ss7(K\DbmkQM&@3}nj9F<ayjxHxF}?w`$+Gy#Yi$j-J]|WT<\eIfw]FS6{!ihI1$h5RO5sNs#X0
::qtAUu$-^/[>gn{16uZR^OgqA4tg00x@e^TpPLrL2THO!!%mayJh>YTW)V@lmcDa3lI\{D(\o_H!k5@pp{$^;k(>QGSK=t7eU5-Mlw%|#11x{+xcJ_udNA-Q3R&b~$H(AK/
::>he%Z-5vhS7|Le^$+(\8J3<Fg{^LcUde.[]k<Cn]GC.5NYKvtSAFbawdbM9o*wDD~@$!!%`.5oSaq6+TXSC(5>Mfu$hGgM;Oo}{64<zWEv]$~~vflT]A])k|9Z[fO,p;e{
::+cc3oY1UAG*2BTRyjl~[RX|GW<nIAlJ`4Xj{hP~J2E7YEkeIg<XI$nGo[QK,I0PO@t-j^t}cUb$qf[<ge1UAKo_tt`DLa3@wA8nA=Do2xB_(F~yI>{%6fVu(/8;UtBq,+s
::Zm#cEQazwx)}~cHA%NUXPPF$wtvus4x77.<rY|n&yaH{ACU*79)&FeKCA&.!oH7>2M8l?xo]M9UOMUEM29HQeik+-od$z}|/|\3_iRh|7_W5PjhnXTEDd_gQpohGP&@Q~h
::>Vovi#925,X.!nW\m${Gn[Jqt8YKfoiCPo!B86F^rcX8\`~qMrH~cQv?PB6pR}+PDE.^56}E\lwlztkJ8*]a+=~u+@uykP>&!E&HcZ|}V?nQJ+r$KM8AG,8Vdik{<lded%
::?WEGz%),T)r{p\?x^j?bg2,TN~5U15<;ZOZ2*Xx%fGN!d.>?y{#VH|0a1*Xg@nv)|6B7JEM&og=+O/VF*Y]t@5^/w){F_z})X&9QF@g|<]{m+[odiP>)Q`tpq|kKKdfRH1
::6~y6O]Jsc~=3\EUgUEOLj?D0u#XR8pFF}Cpqn5nJZLn\EM@aC(V~iftt%Jg|p<Y~/S$c%;8ylK4+N3]w\\nhP+zWK-PnVWdi((btrLZ}]+,sUi`afUzP#-Y@k,[o7\ygSO
::3o3%*NSjenE/DWrGybSp&9cx`WmHz-h*stS^H[Z/dMA//kPIZ){,6),n5$FSlPKBhJq8@l6ln2l}[<*kPG{\oJxPMG[GQD~E9$U+?1>9Qs`p&bV0mRCo-[e28u1lAITMwU
::*HZe\lQ^O?@Nv)ptSK2OD0gkJu1C[=i\y(*ycd>HeRoo]Lq)K!`T(os7JfkvI<n2-m]cH/]mw,WM^z_=5h[^{%9EYF/k0rh#({=dI3j)RWFlnY6}bt0\zaA\T4VH_Kz`(|
::fXE}`_P!%#o3_gCy0-IP0},cTJIbOwFFqJOyH3$Hdu?@_AF|My_6^L\TtbuB9wT-=_vx{?,L.,ooa/_hdHGkF$&/Kdg!%H\X%ENs_RuCamfJERPq9ROmsL1Lenl1?GDXXk
::t$q7D~-gdBiGR?k^#X1d8MQ#!`7Lm!f#~100atoaZ9Qp>JPd4wcAfn-O\*3nIe;DZG&/~8/#*?X[~MvfoJbDQCdIvVJlfrCm3eNfW2d9Wd5[AKt/ZWMAe8R<zx]i<C9ysx
::(9f>;oMy/*d_+5uY[JJb#Z-R!j?TmPK)`apb70X~Ks7zBjKyS?@r1#/4deWh8IHF0Wnqi-232/GV@*Bz#@$|vCT`kQxBSHVpOvggSl|@HZM8XQ4fR;7%O{ozp+)GH$dq*b
::L&dkhtCn~owT0utRt^!nml|S(m83ojU-_pg?jq3`y,T|68(Tb|PbYA#dri(WrETj;vMUnq;jyCyb7gq=~^N8-yq@8XluhXAo0{0{iR]y3or(vk<b(l<oP$(`)Pig<CCN`B
::ve>htbc`pi*ZvU*Af>DwO,/|lzCA<KOAG`A2-R=;jWAOt3ru`zXyuVNZO?H#NWa$>^74jbjfIlm\U{M6\^\^1{RPV_7W?32[uyQo`!Q=\(<UDA\6u3y\Xa`yiR2{>6J{7p
::4w4|Ewu-6a+8\.dj3@iSm(CKK3u*L8rcVm>6Vfkt|jcU`j8.,pE%tuyP$c];/Z;=R&l#e0!JqM74+%-w%wRaJN4i)R~`x;V8Xy5!SI}IzfmwrMoCKn~hcD(wv`P3ttuhbb
::X%Y7gw?`Iz;<{%EiKKe&^s*~uj_~=$#c.IU7EKL@Imx9oaKSI&c&}\B*pRO=Zctt&*sM(hfFZ3`_7j\IAo-qB2&t!wf)8CLR=Zy{3h_%1Y^^tW`k|LrkT`4=Nx_QKamm8K
::p[D6t{Pph7An9b1&(qNj$)%V+rnrUxy14qqM1sR)29]g^6!frbXUi?_a9[<k^>R!G6p=E3lVW5cP.c[^~Fiao6[[9h\9Z%5J;5yv-qvvi#[9!M7eM%!vYmekEse%aHVlMm
::%DL{[6G2.nao2mtSWL3+N-a_6<]SE;*IMs)^m1-/iQ<0(S1g9_|XJnv=;>!lDiC`2-f/-w4t3Kcc{eeNocR9G,k_m*\sZLEEW@y)UGbFf_T!-R0+N%Wf.YH3rWhJ<?!P`h
::-OC-T{n9oQ)PuFF>,[M\PZ1Jl0^dBz=C8S|7S6#_ciESsbMr*8D6frILc@js^V^R-9^N;sjkRBHmU7BuzF$ponALU7vqAEs->-;Jj#jIpK#8jiueb*=P=<0l@Nt.7)z@d5
::0cHId(;}}o>=2!LVSaQlq\yl%=7`uVMEm,+25pXPju4WsE0I;YnukQ_|1Q)F5bAM(6!PMo{8#aARb*<FmNM>\5{R3A1lVJHc}ehmzwHJaxh#$i[Ws1z{vY][W+P6=k/&Ji
::L]r?wo,vKHL}?j-}9nm2;>kGRC`KVySI99L&WBL_G(}YYCd`=Le#Ry8,N-&K>n7q4QOWYq,|P12?SWu(~z8{_ZQ6?Z_N\p-,cQkPi[aS[)f[?Bclab0u,B^XW+GF^.Uoyb
::m,]2hrcJC|0_DZr*U5@3uX0|>S3gKVlw2%!;99um*[x`5#ADfi)|[m$>o+}}T.\u<(^eGguZSpcMlH%o!_*8jx~CF<8l6f9a/aE9~$TMKfxN)UAc`BIf!{@JgkQaHSla88
::|Dq{/p>+2VEGGjXwJ]=6a{9tvZC7$dta6FNJe,C^&X,1[{lwF63b(|%f?/z%D8[H|~$t\wlI)(F*p4}/e]Wov}*IN6Sz*%B2nmPDUxF[lghQUa/0\j&[x\e!Bz^_U<%bhd
::&JRA{-PiX<\%!jUg)K-n+kzjhPtyHU.3UH]lA{(G(e9@eKTy8y1?/a;[rqazzm%v^i>Qe4^}SO!|!sQoy\}W}xcW|^)-%*5HaW?Ki4t1OTE#j%oC72r_bm}Za|6b@ScL$P
::F<3D]FaiZYf4H+;#7`UsZh*+qG%bDZcl->Y;;JN-+~U<g-qjne$-,gw\x`qnuS(4?dZ1|?`JnaU;Kp</{_@]b0tD0Of`k)L!vGlA%h^q3Y4=dcWx,,|c5,uo,g|ez$?&K`
::`#,y_I|3jOiLCG2S9kqx?pj(9MdX=LQ^\BDhhNxYEM/cXS?V5rjXp;-D-eP.bB=V/i!_%T{`gGFVBMq0rwC3\G)f@qA7*~F6nS\@zV+_?X(?<x}15B\Rp?l~462EuseNz]
::W<o%x3~LE;s2Ac_tNg^hnr.dChFleOD<81L[DGt6#jA0EM?&.nHLuip9enR;1hN<iVfzOlB&i/#|(p(D$I<<<zzOy,\aFt!-m8coILX{yee$71B=v=);m27pSPL..}RDss
::-9FI#mD;fedullGTn+L2J-|+uqG-+LLDj!NLftkeHK,RPEx=s6|-Jx6EubI.IpsO`C7c0!$S/HIvY9u1i6e4L/75BN?sqC.35Gyb!~$IRo`MoF>W-X0Y&!6aD=uk2AwIsB
::O$m`TXhCL?O[%o7AJ;e?XVy-RgN(57csOPYDqh-OqOmK1/,oLTGy6]J/o,NEC9N&$JaZm4W|xzONi&$hY|-ZAxkTJoo$N;\l$p>/^c0G.tA/*\TG.q9@t-o&~WgIK;7_p\
::_cMZ_`qf@|[,r626lPhwbEC]1*b|~_Vl0i4?,xr@2&9F2=j9t5Q,JLmpOPm6(cT5Y$Gt28lNq!A}Q1-8ci#XK?yZ8n2i!&mET`e\rE2?k{SMkt7UYbk4KGaLs7bCP;B@~Z
::|n+ISgKa+AXHlDs,dn8Ax{FqC%-GM[,lkItS8@+Ol*/llhdhfHy`WLcQgg@|ZgEh%%aKzptry}o)l%g&w,aJ[mw6`Z{D=gj<FuN}GL<fJ`lv{h*Mxz*~KL(4);pn(-jqSX
::f/j15Hub9^UlhKo{~JE&pbYk4ocJQNW%gA$TiQ7|0Gx2(a6KT(A2^`;|tAq(JLev02Nc?~a4QARdT0.NqbyA7D#wgyAVi{5U]r2BU9Zz&!PT5cQUhG|7^jhQ-\DxKriepK
::pe29>Im+0%;4X+qR,#.3rph^LX.ixI@]6u(vU5%j1mIna7I7>>{2?2,[i_X\[$Ktu1-BM4.px(ANRzsy0T@@*0,/%S@ZRNAojcfprlr$BHb,Km2.wX-l{KFeG\YJ1)my\n
::e{K%D#V!XmyK!J5Y3c!S#i4Ma53*P$;F_kx5<T1azW%uFrVRUQ4T]^{I8WIGs?&81,6ED+qqEiy&5Hi)~IMW[}CK-,yiY)uBsARRe-QTxGNxyydK}p2Iu}f!/df$Fwh*8~
::rZ8>`}*.k=!dJJSx&KW;o%]&k^0X0ds5>WK|7&h^}\}3d1aZZ]sN<o)H\4=?hvoXU??[XM(mcQ9c$P=`WZCjF4oEK)(hfqu/xXa&Q8K+d!&/XzXjf/et;BSbS;%,@pm@F?
::BO@\I$7H.L)c6U^Xa;@imCQ*YE?T61wQ{i*C/#0.=iI0g$RQoI,|B^Y(-7w;*=|\yCEEyEb%{mpruY@plYEPr,wR(/RCueC$\JQw_g[KC$u4}uObLHoJ6qdw\U5&F3V=5B
::POP2pJbOGP-`w8wFWRT,XiNO%}euSv\JQyM^uqWQ(A?mT0$^LozlHT/q+?GDs&2fs-843M01C2[Dfm`6]-[N2vyRV{\sBR>!u,Q~}WrA!9]!&3nXd;9JnUW~N`LGJ{e(--
::KPWfu4NIXW0\@IGCNr?\QI[C$@qY\;4GA8t]7PVt5oP`N|FxqG>.O-Ym>D/6>/CNuR}GlHto)M-PdAF&JpQ!#=55]3686Y?!?JWf.+uPre-J\Y?l#aDANq;T]&8#Z6.@DP
::2kkP3^ew2n+s{o=0t1>IJ|4d6d4M?Fag$m62/dGKqLGQ(R|_>O,e$IXEC{cBq+@gN^eCU5>`_vB`~49X%!~t8;w7y4R%8U1sA|-UTdBFqLYXmL/MVZ0[.2$V1iYv4m.Hbg
::m[^qk7cEMqhQiAw{@IhH~VTrxFh[9(?V8}QH%X1#.z0ljnKw&MMhhmC]->8EedpMyI^n*${`Ug]eScly]q)*0$Uo+HAGhD<{K0\Zi*/c#3Dl\t,G0kOr[l2nSx_*^`/{?h
::A(~XJB=oqp5{aIMvXa{szAnS8wPUpn9W(?=[yqr}F=6l<b5]KErOU)G7o/lHU~Fm9p[$Knt*l@UioFq)VF<yQcHW!KJ|[D|RSt2TK4R^b#b,_NrK5d^fz@A$7Wy0X[)pbJ
::f3uM\MNT>6_[3s@h6Sur>t|-,T0gz[QkP&<lLbTYv9H9V1k%_kcW76x4c;XZ=b4RUrf~1.ApV5[$Yox)C~R>Ff8R>D{o/2N_h8~#H<q~_Pb$zjxtPH+~_xL?w&So{|MLC\
::m$=ZQq^<[%haaH#82t(j{rRHxsJg[oM##v%a7lb8!477m7`5MYU-u$PMXus2k*wZWggX=boCUBxR_^i^G?8l,>jLqk{Zi4PAyuLSmcZJ-dgD/F*0UFWNmL,%7RF#iobbg)
::f#\#V\9q/Z8gR>hXv#pNMV|62LK/=/hy0?@|e_9ta6P/x97fA%-&r$KlN`/{*lQodWd`O(]UB`@J3|?s7`|6&#@C89~Gr84<J0Re%{TE{74&;S,PJW]s!|Cb-pcM?m$Z9O
::?#*s@o9R(AFKxcqvejJItlj52^sAPJ7*wcx-3XPkw2d&Z$/z%&bY]P3Ou5QeR.xxiiFfG}3?$$s9fBEPl,lbW^Qi^Jkg>]a5C-1X5^)V.>jP>E8|GVZTR3(WT(,Ia,VqOY
::?q}8UBen$gIhV/AL-HqZOB[VrxZy5=AbOc+`p,/UM&ipQ,VA,~5Cs);o3b#kszkILXljewVyD?~/>fjcI[~J5O\dM)jUsvON]{TWoy06RFkbD|z7~Xnjw0(UiD{$w4.t4B
::%mvE9gb!CK~rp`!t4$|EGa_9a?GmK@Q~,UhQL6Z)wSg-mESZ>Z0fPH1{3L-d/jHGsd#[`YmjB#PnpTo(E&*|N8WAXZA\Qe@2kvw~bDjeY\3;)c&2/lm1uNMLo}38J]LpSs
::.\^Q1COTqo}~48Gh&Uc1mYRJK3wVt`fhc+agi4Y$*YSX$m`BKW$i^pX,+BNAfwb]5L-d1ugyGhg<5Q5z_QBO+S=VDO>R7|R3{P|e!fAT;l[PY@OE#sP8?YZG}L`I6T}%<B
::bSV({K_@d(~]gJp-jc,E}Kpe[|lECkab5]CzB)D^OpU~]~,rXR`6q_jI*V*QtG}`hF1tHUbz$!tuk!l7-|a2BV0c5B6%~o<Ved)z<#QAM<7a0?POzJ2`-MPkd9_=~s?Gac
::bI%R)B0Mjcbfe-aPwLzylG[0Bpp{T4I[8tFC^,%HP9gNWc,JyEF;3x2h\FS6ci>WH~e{zN-,]A}`PB6``61gAj{%6O1Y6ONeU-R,!+2}mehV=C%O-aCGKFNmMozU9QjjIJ
::EvLSpa~^YSP2+?-^tlMn8`?@ccUCnEUe!S@n,6LF!eR&*R)?q<dAZV][bZ[^i2<zlXG*%8R/ofK%e!tX[bq>sO${rKuxj]=1iSCijxB;u4A)aDqUi(C5BThb]tCPLmgfpD
::UcT*2Kx/w3g.gW$9A^(v?W+2U7M+]O/VYKe6iycIEZL[cx7m`d$cAD+M5D\KP_&yb9}#Zb.m>T8qWX7J@q^Xy>YwG=0;sd4Y;MCfr8Tw%S.gRaN}Vwhr0z(LTnj,s6C`_{
::e7Al`?G?C-\9FEyw({>Mj?$N3ep5tIV&!(4n=KYkK^VOXf_OZuB/+Lv<_jHnW,ZR*RtuM-f]=t!a%3KM^l%FfnbQf,#hXtO|oAo6mkzbIt;l_L9F8[hMOR81K/.B+o2;Af
::C--{p~u?\QV6Rn|$k$,!)UkbTen,88PG2LgU*SMK+G!i;fS4D6xeGi^k_,.O>JaiZ}Q+xB/eZ)_*<zwVkoJsNP=Ao}&O?w;{yKbH/ky]BM~gLw,fL3jNO7lx?(ZR+fPb/#
::nnmxe0rxG1)RTj_0z%`8^&bbR$,)SO[y%sC}~&{0(Y(eh3WNp,g&sRY[,s<QLGWvouOR}nF2>HL{upOlpH+wF|<LAL{V^0ws]Sd8mzM~eh_Km{ba].=[cN<ErpZGNtfDVY
::WL_&[]-$oy||[F!;dWgA8H|u.FG(twX(%Jh7Ozh?MuFjua4fZ-*ZUP;%au7BG|B08ZiS?q!rcyBqKg%g]<kC2L~lgue&/]~eVi4!YqmRAujhx-WO02ttOMJcp6#LA.tMjw
::*YfYQj\%46D#Qx1KwYdtd[~^E$wm!00-h=z-/*I0ZjDRBqQsZ?FahT/<|gu?v;}W1.,L\<Pfrse0g;r9&rLG9)f7Zp?.b}UtsY[Z&0w}3~\F!!3Rs$4`r;D+5{~Ter&coR
::|/5HcVEp1RIo,qR+=_QP2LIk;@dZ`3*[nZhk8Op^[B(8Eb^p&`RfbT}c.l\wcGIs%UnFAwPw9I7n(trf4hP9_J/X;r`LKX\>dza|?{s@J,I]j^rwS]9do8*i=Hio*}n}*<
::W^mKH`*q.5tUeG{NNc|Uo;b$fVxF2~yLJ[P|*eH2,{/MPw.eTHexRV1i`-sOHLkChD^g&~}`/qbSrDds4eYok.W`=/\Od+p4lWJHt89-A+8s5hJy7~o}<Bq_y76T3F^LB`
::lr`X3p<FeJX>@>uL5eqL43FMuNz-&TC$5L&^0B5qm1i44zDML75=pHpC]`V8zw|;ADl>^uE<Tn?kAu1nm9XW,v/BquRCyp`mG=(MyJPU~=*f^JVN\e87FT0(|]0&%qOpj@
::ptvuc_%h]zF0~GYwI>Zm(pOIPwqK}EXPy+{@,n.Y\pgi|*<C>2m[p*-Ql>QtNJImrnhx`%jMW#b\LZOsxsqI`p+g5BOopv9X|[l{T?,#JI)T+!<lvbJe?qMSN6e7hY\GJm
::)7?!vc;;=<M|V{53,ISze0B@E5V#DFD(sV>3o[^d0L<cy3MGvVgtV;L(BvdsrDas*-@30Sj9EIy%7]kl8]-+(6N\TkeRU[(7)%r{RCnf+`57q82!96vr;^Q`O=^cs#@vTq
::B||VI~g`z(6kW2Tp|oKqP3?KO{Z9S7&~7k0=MW4U`tWW`3]NQ<;l>l5FvhzKmf/4g302`l{G{$Wj#g276Zq=YK5&H3O)T0*&5]416ejHHlDSx~6#v;X5d%RehF;;89|1gw
::lLf*M]^a-36b[?(d&pF6rshDmqLDT`,O%uBGdTX_[vb/|HvL7lFrvYVVvz0]oDtP8E&l+z?D%x-S#n{<3|G^IWLD%sw<tH<RYy)11e^&mhca;Aoyr9>?xQ}ZWu$IFc;Y`6
::eCg4j2EzVCI)_TQM>_j^R\I8@*eQ/az%wu/Ayu+[\AQfi,5!;Wby4-BHe3S{i(XH|Sk)xa&3&nZC?o\Vx[C,S<8LS8L5F~.V]x-ny.+c3(JXJ4(WbJvFT[#!s*OW*}~mmn
::*nRyJ>iJg?&HQ<;q[A@SaqI8~/z;#?-Io*aeL`Fcl$h=Lh*[+sv;vPcvh#_T0WT9*ZiU7%m<yiM_S2ECvQE%(SPKl23HiWVw((w@y4iR*82#2bsdGjMI!BA<>9<r?9B/Y4
::*{u+9c^/92fOk4xN&e2`<qU&zDy_0OxDb~rlOk?74K6eys/-9is)(~;mREVIkW#N3i=P]=[H&#J]F~k!*8=q@<btSa|\ll6/]#N-1sL(?RJ$VXO6ti\\V4VA{Z\f&8ZddS
::1WHli&cw,{|3#h}rk}@,lSQBo1%~#c?*=&`ab3m4vvW6mk/4oJ|!Jk58@6UwTC$V]F&uXtaVFj{}90!Y3<3i%Mm2=Y.FU@oW(;hwtUg6_@p0<GOw$N<>l.0O3p9QXJUTO]
::Pvlk+t}!TzUQ5oabN5&m;sZGRRM2v<GS/BN9f^}v!<&xbZ^~/u>?HE`i9w)V=i[l7H01q[sm>_#@Z$E)v/ga*%?a;f_2K9Ad;T9s!Nwna1Mg~CSjt8vEuS\Ek;g$.2n%BP
::IjU&H/rj@@6$PMXudyMg$tLE$A4&k;`ti|,CE9a>*BgBc]$<2fZ;mb56A(;u%cheDJJFeaD5i~R!&<>{bk}_{YWt*?=9]=4RJ$]bXXf25a.8G4h/}r[jsvlY|X6jEtoYB,
::4Z)<R56O*\%a]2A\BeKtMP<,KDW;d(*%s}hC8V9gfklR!jS7iQa^`3EO$Zxd.vK*4w?i5\jt@$7Fg&0=_D?L>(k8GB[,K(WBH7iQT{#;7E]hSv2!O>\;ov8#v*6~oLRjmy
::F.rqfv})0E`/TK($9+%tJ,LC[/eKEO]ObB,[C8(7zg%)IS.f|6p7eBuq.FM`5%?L/awW\ei}&/qI>Y?yX8Tlj2r!gTN;k.$[)tnkeWyPsFGP7#9@Hd}Ztw,5x2E]LPPeW.
::Dxp`dnTN,1Jjj8|QMu*_qZ|f{?)!4+Qt/Qnth(qp>Dq7E|]+bMIZz\y{gBElt3nDJTti$,#d+i*LoK,j3Oz=~{2jbXqO&oS#x\[^,4H=l?7/f~d&r{?g}Hj;d-#)gwV4pC
::X_j^+<Slz&A-#piB@5)o~9}b}QhPf(jX}Y!5D\4Q}mW=MghFUa)8I9PNVe=PdB%)iuliFZ;mI/F3g)hXj$L4?m}V)dZBVS=HD2G[d46/>=nym^!w|<Tcz+-mJnVsIKl*#e
::0qlfIzp]7,)A/]Q$Q@xczxK48dfkDedt]qxK?0]22QX2O?O$yhZ2*X[|cdEBt*It)iW@z=+e]w*l]vDF4^g4Voa\D/IFtv(Ys9)RWq~q!XOQt]W*G32x>H?{R_W)~qK;Y2
::s-GrVT^=Z$`i}9ckFZJCh?h#z`}K>_94P|BaZ|(?XCdHl5dF5B}MuDb8#vV=5QO[Nj@kcqEHS?J74b\uRPw+o_\0,Z,^9-vlB/PO^jY~v,9llPJ5Bjaj%MsiR_1gGzU;ev
::BcyQSvhV4ScWj>H+]@LVzCnA9H4Y<S5|w$n]YYv}An=p&g.`SW\CCWj?5IJmlFsdAalDVEb26fuvTfPS7$nMaq}rtB&+8Dmn>Ztmilto;C{M+_f5XJ2mFRPj5SnCq!7Zua
::2Ek[pOJa0<3MkP#\tk^Tn~i-~A}gdcDqdSaM$+%&H[+l|D(wrg_hkl-b_+3ZSO%`e2-Ne5t>&>skpQNd*_Ocpmf~1j}uM%}UBj.!JJ=^ETd_HR_pHD0V$(^-~%LVZ!leK`
::{luV(TUY%]--rtP-XI!0mM;4|g5zeTV-\6KtLTsVyemc7I~85QU_UxTaYJ>vvPN?y+Xfm+ibC/M{20Q&4NA{2+f-as2KZty6!74ja)/R$UC&C5O;z,2`]MMHvT8]NYe{wD
::>&zTLl}^oLT+tRj$VlVLQhNcgb<13`7%FZ-)](`TX[p{ZRJ02#FMNh`9kc]0aR}@s21A3BN@@EFhQ@`3+8={c2!uk9QK3n@io+!y9tb\QI^E(~WN)&qw1u4M6}.[ORRQPN
::B;LFHfSEc;t2C,%g%4<M\zhcJP6(LvaYPUBKs&G8\Xf/zTEt2?cky{@T^AtTK+LexQo&B|!r+9+Z7R!A6>jPtL9/(wM`fBG{Y-atH^@|uU8Qy]}SG8k\;*HQT2GV#Zw7B2
::tjp(F6eGt)$6_5N2S,^[Bxh(%OJgb,\ypg{r7;Y((u`nTh`3+06L@?5ffu|Fod;EW|gF=Q}Xz11Gz[-l+C|}d@f2uVp*b#g7ztb+B&-^upiEwP3c$0*YAPT5z<.QD4iNYH
::wV$J`pE}T0bNKM-p1c`e%+/`q;a0nq(*+J4$XdIxNMujrs*SUsg/lli0UwkKb)C[Y!#._T<$Uj=50M606$`.k%JU!vz~7o1HbA9)9*p~ZGQGiYQw\jGn82Y0/_pfpHpN)n
::z=4~Tm_A|}L5VKg\,WbI[o%6puk|W}}&?Vp4J_YQN%L+R?*5du|CSA$nwvZ3#&.?E^?Ft3lCEuMeZArKf3^RJ+0\AH9RyDg92zE)!IqKx%VTr#FIa@7w%zkM&v[`q{XCN\
::,T\cq*.RSh_=yx*J(co_Htz?FR{]>oT1)}NG?_1lzMmU+>)4v]_x?3h[)1,s%U7`.(=qeHJ3,\\mYbnO*D@{*=o]vzjcu_D]-3+enk;[f&VU+XKN.k#XOQ&).1,`oo~t9l
::r4Kn2lmC54_=3pypqSK)DlBDFg0;Ik}{=YM6FF30KKo}JUKZ34<F.qnTB~%K_l)Pzj\?QBy^gq<}~[hx9k)b/l228ah]Np$_v!_s$n@PXFH/A$b8H7J@HH4*]sL!)f#,?&
::C;GIAj4vUiB{k)8RXEJcvAD!W~j;h]YLYN>xyvm(,%3jVD`psLQ,7m%lF*A5|@P+F@mIzsPdDk>Rr-k^><A!P)~}E}(wZU@D`|[(0\nlfd{zIyThe$J-j0h-cL)Qv$iJ\M
::&ueKxG(!C7@\ys2#~RgRWpdpExct%1>n*[/T,Gjj~B}(-)J95m?IJ00;{i~P)+m2Y}zQn(yp;leH{ry{X[>JCSMO|*qw3UfvVy5qQ=KpBvd,F*&Fj&}$%(=-Y_m<QAfi7,
::nzK&uW&^.j^tNb<Dk*H-$F2L&mA0FWPSs|IER8)^jOn;,PYkN0D7;XP*sU(40]Bol,|nQ0[FjIq,xi96}DZ$<-02b}.50<%KSXeML,X{>pz$@D]hkbh[ZvJyoMfn69-\VU
::i<B~|Ds[+8^Hyg)-N7$?H<5tg]1d9w0Z4P`*78b5O*&Obs?vhlBFn#LF#i96YC1ZogrEHh0Af0a^tMN0{c[G,&r~K+{VWS}}SNKDbXbn(vpa9BdH?,^3tz;@cohaGIhNYJ
::Lm1tH!GZmoq!XE6oJ%(+H3>|p5M7bOZFNg)5G/XjT$.Vkx|?[Ccj1iJ9lO\lBl[e1ub_!0T}]eeF-y0fjZJNci9G/[(;lw!Y|iA2>a.ep$kuy,gU;Nf9p[-MoNA]~=^lv_
::$(eh{AUoS7/[#iD?4Ct<0uz=;;WB%`g8AwMg$=ZNZs|%c$.qo!U7*{ttwF%^Q*i~(JvzMKti5+T55aHR}K=CS{(L@jIaM$xgTBU%^X|&Lc*f#G^\vVnt>O+Wbsp6qF!PlS
::Zu=x/_Mm6tmYg=,f<gZ6X&Qc6-_/V[^e,}w8>8N`4VWZe8roC`l|!g3+g<=O1V1sIqc0(&W!lR&YLE+8Y1IN;$hJfh_ke~-ShHWu{=F+=r}FXE;AI&rpa1BEiP(o%4.eq(
::P{Xo~QJqc^O9%Al#}U@,7&T?<w?wZJMpx|b~LF`yB.s(<4ucoyqjqfl/iF1QHN/A{hv8GB_ITKtNzhnZg5DF3ABK.lgUhB2@f5v~[Z30%IBSNUUOEpm;o+zz8<V6%G8A%2
::WSqLu6t1Z{a_*d@8d]DU^;M)H8%/Mr,{/&~)e5j6`JMJ@Iih~t;{7BWtT13L&PT%suZsQ]g\sh$@`d\+gOx?71ypi<{et_25<xjL6=W%OEM{#SoDqVUV!Npy38Vv1`,bk0
::GE>{m\Ho13{@7zWUUqQvX`0Mq`pr>r-,r]djT1{aaar/g5*KMAA)TnWS[gGN\QaTcnh(A+$)b!{.B2n_+ai5G,Pf.A)5=[.$Swh[yb8\l)Fl}AT!9&vx|U&n1zL-dy7ld]
::{4Cz~_=J38PZ^i)Syq1OW\A]Ado^?YRLLfW?\N)a2=^lx]^UW`H=Z21nWuNFd^t,vAwD}R%[3f/U$JqG6md#&4_0@M)rzx`P{X`lF?5uD3kaDd$QK\`]0-7T!+vg9c-~kB
::,M.-Q>\Q9Q>4>eRr,)C|-sQRM0HdiVS[nJ,PoX+P^$F(=!Ba;K{<2e?Gn?Q]X@3MyG9w0!~4a)i^yV@3z3)v6MB0f3E9,bj5;Ko1\1qEhJ?T;pc8Zwg%7YF4v)B(KI<|E4
::3/p0fLeQcw3,2\rD8,Pg{A~[4aFi/zEq~<h7[aG7j~^Hi!@CjU@kZ8X3ZvmY%gIEu-,DI;Rh;@y,@79P%=j.!5X$HS@V_[TWdk/Du-Bk/T+SwLM;|AH_Kv{2^<J8f3StW#
::$D9).j4W.KMCb|J$aHN2f-g^SN_wQG`<GxE6Jv#<4&nu9$4+*}YB$p1K[7gZlzVnBP,s8}E$cqA^0_*Drvi^jFZY9-}Hr0l}%U322[[VqH_-M)EKc`X3M~qihT52z7`YjH
::El&gW8`L9oP#TEPe^F7p0U>+_[72z3sA@-qDl`kcHy/?qxw{4)QQ4{;-U@H7K`n4)YDP$LI,ON*^wEMQ1tf[b)CJ<k`cTEahxLMqKQ5$VdLg=$=H-uZQ8L)!+A{N41{3|b
::[5b)>#hY{tnDL{Qp1Z9^;iuS*`k9wt5O+r21]/R@OXA+POn=V5p[Rl>!R&G!ih8$.s})|,Ms9ANVvGpvX[3+?}3ZSfluZ6upV*eM75tehvj35nN[,epVa$Y\\MFuVg0Z|o
::@Fvx4A+$F<t^%N.^K20,i1>Bmj?`5I%P3_0dt7rAs_dNc_U_/;4_Wh\;?sZ;)@#z^N]qaZDfU|A6oYNbd)1OM0lc(QfdZEc1UmiKBgLqII?N<_(T%y)VDX986;6#LARLqc
::p2^fL7+xx)is2ai!oKa|*W&IfxwvmKV&GVbsEcHYWIxJwx8x2]uOE;`aw?ag\!l7$Y5Q#DUvB|qIAxxRG~&K`YN2?\OSbI#sj8Bak#MFVpt2DslCz#=@`=h@zw<h,h<Qmk
::azFl*\7sUF%L(7-6_}g1|[Iy>oPBv\P?OLVPqHF%nGs5q;WY,I^,14t5%rWyw,R|[#CJJsQtZwKTHc&[g6U?CFCX_A{6I[c]zI&-0$M!,jRp40Se;7*dbHE{j1!U^Yd$jG
::VXmmO}^#SEuKMeKj>yTe&`(>]>;TDx=\Pmnwv5}ElVqSu~Q0.7q|<Dv!7=|!e_&e4cM@PK4y$9_@f[[9o!-MBaj|Pb]u}Ja,-Z$xjH]$9aNZ6eeeVF2UUFJg!Cc6nZAf[R
::6(x(nmyc^y6@ClZKq;[~_gt*_sDK8pK3ZXk9@U{F9y};fiafkGO1VTd-r0#*M2rmx^j5%_~QbCh;6$4kdVT)-/`vv(=51}v4LA<en)>+xuXd5W4dx@hh_m8A3[2dvuZ,AC
::Y.V4Gp9A_!R#ov{QG3[C5R4@X@4LiU|y;F~Auc0[}b9Q?0^9Gu~cw\yk%~<]LdJhiX2`9)zl}P*9vz+I++={+y8`6Xq,%&3/y|ef/`ui~UGw(l/g][MB4;-S4^XXHj(WA#
::?VQIH[4z2rkDyHt*e!k+kg8nA;LO;B,%-P|wGNUr>R_Xg-1mKT6#9l-]`O$&?tV-uAz@.rA3!>FzNy_B#<ZcN#lE^WJqTY)Bxlc2o{9Qb]>K6DMiWDSk8y]_R@M^^-{,<Q
::S!L@ycOuOQ?z``r$/`0DN15zS?0(1(m\tQOqWFO^OIG-u@~{@T9=Fc1}SYkc8Vf,\9sOI|v\Ay0,d(BtnpQA^Smo=|E96b[0p>FXV7#ks{Qbc_HL_$c^e4^P2zo*Qr*kbH
::-Q-^Q_|[k0!t!JiA,%j<D3kS_hlPQvO5V~Ne<K.Rg=CF;i=zGujX%J1r0|Az`%/1TjJ;0q2tN/u}sejtV@+r{yZMwa^evG|Qfmi;sH/kC_NwfOnL_fT9bYdmzJ|jnxA(GM
::<Yl0I?\%;yaFL*0#slB,Ch~za8mr>;~A<(Cpl6.E*[7r[?]W,ooHn<GJ;erLh<p^d%`o_@ZFtuTA^_oWl8bKMt+?]@;q|BBB}od[.zqS9f8kz#;2\*-~[1F]7xU<6@AUd!
::V~Zu(t^bGasMTg\k1x?}fk[Le)DMHf}0yK<}AT*n?,!CQp,!i|,~ZH^K>r&ec]qF>[f}lB`3BjR!a4]?(YP&&xi,O/40Ks]82QD`AhAsNIBX5pCpA,$t{VX>h/g{B,o!OI
::[yh-_3#Y+]@}ja*Lk{~LHyGn8|7khj4fb.n6%t~eF=;^URQBanGEq)S1{i}+H9Zgchxzk$Mky4@QI&a)S*5NMa#52Lv;,i]mu)RRphLSWm@4U_;)=zg$y6w{ef!ONDhZ$q
::`y1&,k%kQb\oU){Bj+Y*.d4(s%@tPT~GkT$Gw)y3Zbb4)B{yNa`\\MnlWHyHej<0Ny~[#~Q!tJ\yndQ67?bQ$PeQw$|`u|`gJ8wt4b`RbtvLD.@^H-6XU!wp_<Afk^b^_T
::=)87Z)c.;6.e_4MWk=2WRyY^Oo@!SY}QBryAgZ9prSi/7w{lsPnLI$@T][vtx8MCP;^Tv_nxvs;n^uXLB1&+Q8&}F<*~kac{ab{j*[G#1ebf&Pl/G-4]QHh7G,D$m/0[XR
::v%>4#2*m|-5;|.Jf^RLrjL,J&F|LB`14|XBAIF>##S#Dsfttn7SU6EZ<}x\$Ovf?W)*Z%4g}!&<hoQV~97!geH%N[6I!1KBwa5V?Q[N-!V>D<i6H9Xc\HHJ4B@l7uJC(b7
::0{vu^{ZZqJ]wse]sAPM16yyF$jBuPg3j]D[w85;/2<K!?ggYqscNWp]9]vlx%uy#qnlI0cwbK_T>/QI_e1\O*-\QjiY@Ibm[h_6d/m[I\xa&NJ<bxIYsY9<$CH\)eHv%B!
::lPZUX|EW+I$#|l!~uQ@^rx)IuqPQC=Z1{E*_woyj*FVm?D3HR`O$]vce,/3,qqW7,[r+\QZt@#f;Bu*AghT<N!]5@a7xuZnhB\Pq&&t{gg6-DntsB5DxZ>n+H/Ou(2Bf95
::|Ql0T.As6J-\(^mYM-ZneJ\lg1]ziFJBL%\ArgNbxLU;9.54rc+uK1^YbQ{v^DIgO)K522@8HNM6y0{+^v&X8,VU+/xLl-#Qrqu&|LYO3K=Ms-88jIr(ZJ!5_xbVS&HVZz
::#oRC<w.wB+%j40|Xp(4v9L4HHS[[Uwib<;=yW|FvF~s_P%z%_TPie%d@I4{x##o)>fYq!;n$y#,r|j<l~-%fMox1A@mPB1%HM(gfo&W9|=Kf7.)c(Ge\~ZPe)HRysZ.|AC
::7r=u6x;nir]%B`^CW$|_%}o)p1\G{z<&|H4X!(jln<m^OOKXrG3&Y*+$K;4=3o+[dw{pSDy0sh^;lI^ANa}vv-WFTRH!R8yr-g^`aL+o)_A^^mk!]3yav;}(iU?{q]lu;|
::U=B90Lj[i6;*%1}c]GY1$#X^9iLQzIPN^erM4a7~I)VflQ={1bw,Qs18N]2Nm`a#W*Uk(*n)$Qe;NCsw/*$P53-x0BUbG~N8Ud=Ly+4WiyNmO_r[=;/_UCz?IQqaM1Hc,B
::8fVF=G}|<T}.f,L;`*yt[3x9URuq[w+v[MTxwRfS7dv!xOn*2$Msqkot*Z4%8F7_y]i5;Z;wWh*;!z/_`~K7$Qr9T`TM9el)j~G2&66Uwe%uNKn5W}WG<Jset^u/z4MZcO
::Lav`,wWZZdiziCh/yt5zlCg~HRAfdg&rk}kqT_Id1z=fdH4F]JaR3}FH(CcUFEsf3pCuefA@o$$|\3Vl<ne-{j?q+\G&.+aI+_Z4;*t-rt|@OFhFD>r5yUeID9MF_*nf.U
::gzh0}4hWv=B2~@w&kA!o]M\``WjGKeC?ixw%K$-vX`uc]%NP;0qi2/zE\9cJS$l,C/{p+D*UhZs4A/)%{;|}lIzlqoug|c^]=T7aZ*Qn>u%}NCetYlf-zE}g~C7z!f_X^f
::\TdFMw37u/D3pKyj$|lI<Lb1xTWuX<2_f.b~*1Z;@dJXM]Z4l5ZuT$|ngKK{=<NZ}bq?zJBea2cp\0r)vkN77|oG)K*)~!IkJTU#3R<1[@VwdKb)/E[S^LSKp5bu&d1zkw
::xA8zX/zlQFcWe$3M`lDT,xNcRceQBs-]yk5[?g/X2aF8hv^,8R@3833z85&3P_^8XX!es%R6tf1Kva$`g*z[SYoKS)\q<~)~J^WkPA$WPCC6G`lp-%GBl1OyA9C/tr5?K&
::iD85HFjh`];w$&i(b5&3zqiZ5*I2zL41?QSv4;ZoFi$*^(%0^#d{tpiwQ2no?;5S/!AP4!9|k@r]/gWg,$NPjPTDH/@=<,0K[|ER,IH1/fH%Ou`$9H]/=K=@tMBAp?pyt?
::=&nUtR7F&VlHJQD3$Yy/$v,$}f=e/rM6u4wTO82\cz7(CguPm.{),3jyam3-$_g>Mqs-j7CL@L3lb1qMP-,\%-vxW)F$eg2\}*H|p}m}2A^!HQKaA%}PQ*&oUJ%kQ.*37Y
::kyzj/MY!5F7DIL]#QOFB[E(a|7-=E-^Rr}nw8_<FvHl}7GZTCv=EujtI/=EcbF^2Se5Wn7uF4V2JvuhRDX2wYJEg]_v14}Wr+m0+j>zFS5nK]<dw;,sPw-`^bV=8?HvDTl
::R,=9`XJ\4`Q}2q,!**gQ59RXC0p^XC|0t<R3WZJRk;%nnl1,y46,A;DamJ!=Pt>|$4v5mqIObgn3&3<O0}yZu;2RtHZq=lT\X972\Qq{ZxD$Z=YKn>=B_as+2QNSayIWO^
::izn~CH2=V(B4i&r?}C1?cY;p6.r8#QLjBTju(o{~mi`iVzYU]n2XLU\J.O72e}M[uYgg1$a=XoiB->+ycp}XGdh^Cndv/q5Gm|Q%7}#`4cvLSKf0x)O[jJjI0?r@r-?BvY
::lV-KTgIC-hLVXxu82+o8n/^koI[r_/Czu<J]z[#V;g8Ds$vS{,kD;<#}n{s1=p245CZn-@Vk!!zSvr-mN83r#BS#|K24VxUD^Kx-VJMW}nTO-)w.=[m?9aR~C7@2=A1[bN
::TF$!B`2X.MwBM(*m64Qb5[v6>*IKjo<?q))WD|=sv0N>Zf7gjLHL|y;wkBV6~>CK}t?-n[=QC-@~s^/(731^+vB\1jwxg12tP@fNo|KtMtiWBYp2T</\VG=@->&3{[&A4d
::+LBN,$<Ew!OD{y4?%*[,_6/M_NvaXt/Pe|uyYaZc.L,hnj5j4/@sHg%h-/nitC4ZMk7%@?9}W*]E8`o6;b1|2a!lCSrBp<2iDk15IOrMkeH}L9LsoBc#{YnjVhkU>?H@5#
::oKrwM@@~/+6PLgw?Hp/b#F6ylnnvwG`K]Pa*Ecxhn$mMie${Q|;*NJ$]?k\##ema*Mll\%5R*zDsgyk@1ZnW~lrKvMos%cCvah,z2~a)FCS/-[sLa(Oc=]=j&FE<o9[>DN
::r/Mm)[|LP~<T4wOK[{d&9$AV9%K/G4heNE=Pc(jZ`rY~3.EZ{X*f0jkJC^Ym`CaCoL`-g*xjq/[W^?F[lK;6^L1_j0~57jG}l/LQG@g\y$l\72Y5xry5uq}ssUX`J4;<j\
::>Yo}Xg_bIG\9,8n&Y+UvrR;5|Cwjp81Yy2k`X7`vGpC8CR_$DU1G(|*@!X.5>A#|C|-o3V~6]6(kL1ztOIs!5AR[,n^(%i1gdH=]^h(%\VuqT{Q+<xIXXUFpe-Jz+m?1&c
::\&!47HAMSokGm&dbwHf;Zu/=&MdAJz|yr56wR;Oo#X+wX^@)LAuoCDFtmQIoqY];txI~oP/t.bZSr[~H~FB%Jecb!o+,#2yUkEwEUqP3Rqv;2R>G,(8X3vYIoQ^7F6d1~b
::$ucbUUzfAGd3vs+]UR[+)b-FlR34QN;i4XI&gkEqkb$4H)fb0u.Sp0C{?[V)+NJOY{>34M[g=6NthgYLj}BheLm?lGEgA?A2|j[?O/5j?XK,UpH9EtcACT;jf@6/w[^_?=
::D3xbKjd;V?%ORu[_}yfWq*GWjrozGvK_tkogcE%6Cm_7,pf5/p`g4L){KD{D9Gpo_O/`(OZ7+.CM;8GWX5^D1/O8U==&88/+XIgTD&2_^pgl>Ca-k=UE$K`zo24j4tSrgc
::7(J4BfO&1Wo[nH65=WV7>-/jYu&sU|ql,Ch-[MxK~;R@Mi|6RhlW>2G<-(a;qQ;qE@+`~=&v@~4R*H!?6K\dxX.l5Z{DtsVAisKzSRGjEM9wv5/VVzG^B;+;Vnq{Mn!2Nx
::teR_xN>S$RBw~+(hjl61TNR6kXEPpLK3ek4d1D)N|E9uj0WKz8,Y<ESQML]Ilg*!whrw~tk;WlA-GEj8;~m9=5G*j(eju/DA!gLjYJWvXr-%qa!sEfN0-3\CLL2M?ot%W\
::L)8G_V<Mg{}yWTRJW^O@YO8Qee<$~mP`&=/ar^S~Y%GL)aywztXCH[PSDs=_<Nj;rW%$`C{kIGjz[{jwclsJ=,i{I%*Sw[EG[GPAM7HY*o>{)88[tr#S,)Nv_Mpd18pD%b
::TLsQ|$=,9n5Pan/S]h\?GH\ZYVP*\`5n.3q7I2>I)!jRpF_Ui]b}BVwN7J.0d(h]uKs,+<DImz|jYYDJt)o\Zj3u8zn@uVpW|jB92y+PO7[]z{A/&tN(YEq1e+KQ^-D8E5
::S.;vYHIXMEwL}#jHxr;yTR~]Qwi0!Y)R{5bz-5G(]XZljd_tt>]&jDOr5HYzE>6KR}?YC<Il#e1BA;$8UZ0YF[e-}1~[GKzAx6`4)Ec43CPq$ghO<~=WX[43Us0ee0vk,$
::qe;,lBwGYES&T+k#oE4M=k><oem{Y2bp7j`gB`2mJBPzhLAQ$i|n@oN9!BPK]a?9|8cWWqw8XYnEMDc@k/{Q|L<-6IL]g@Z_q1]V]aU$]+=,cB)iSoM**O*#9AZy-1*B={
::YVB0`5.1/&5eH}l<Q1#svK}BS&xxky>b7nFcJN`g4f3pSx+c!56Nu$77%_m{=P{rM=*p*l;Tg5aUI9CQ9HqIZ-?(U8c/DfLJKCo2@Ij`mzXGd+EU(<m\_rd}S?8P@*9m~k
::Iz<6z-=;YvH*D3@Gu7)*@fcjcPLS$9ts8Ya7s/zNIT3(\^,f/SL4%n^9a%f-TMe9[IE9m-NTz<U0H6c~[+nw^0JE;3v|XAr@\3W[{K?*rx2Zk%WJLDtJ=haWQDeldZA,`M
::S#/M_KZ/BeWKptW1J`3o;cNdHqOowSF/EupWO1QJbP&&\_B0FR&;#~vLA<;zE-8b!;6YIe+vOaRi0fl//bvJjg~irTZ4\hVh%X7y<x-E1~.&!<mOkEjq~Lo,>;i[UIxrd@
::$c4/pNe;M+i|1Iu[;+#=XkLP&rF0b14Zy235`jhnKJ&8.Bt^(kv69RzGySZ+;.fx9.(XTKmd3,+n1yd=Q>N/dE#V^*ixN%u.hM,Q;*03[FE{f{W<KP9YPA)ex{V&PNw}N{
::sA/YDVNJ<x57A(Z@tJtpbM5tFNV;mSiM#=cB.8@Wo~HUdvO%m&HPf)\mI\|o{(M+Nd9TzI[zpUn2{_N#X1dWPFq}3\i$=VYE~BvH]c5Gc!y5ctE6nE08CB[-l$Q6vjmW6+
::WE<hk^MJxKsTb<?j~p}5(GNE&l^KDk@M6Km$zSk{6raN{Y(``pG~dO9l-(gZj`@o=1/xw2^wm5-b{hMoQ}_BqH4THh\JZYj~=PAu/\$^9Xb\p;#J6iEtF_B);;f4v!0{^9
::=mn37aq|n6Dk]!5{J=A)@SN/y~oEAGb<$%.8!Vm5aPE5r)uy+z1OG7S_ai`85TMJB%UdO65E-ssp5[LQ*s|)4hCb(WV3Dx@0;`ekC^`__YG0{yc-U3\KPJq~(e[UdF2mB6
::Dp&$gUiNR7Vf>S#Ia9%k%6NmcMq(c(4NC$/`mY?YTc;=C[g*,(KwO9~H;E!Te1=E-l_Zqp?nz,~Y{v%v!e}WO~f#lgLKuY\EzJs3VR4q{cJyr&.mK\;VZ\FSpg^{?A2K=P
::L\W;iTF#Dt#H4k#`+Nn(sm~46W]z)iBCIi`Fm~=%.a13|T@M?oT4d(VB7z-aEM@38!P~BWyQ{o#L_<hUHz*R2WQ!wm?)jCx*Kz#lyw1$gW,}[Kv;1!}%LCYQ@eFt(9PN>I
::!ATJuk.aZa,JpfsIqhIO!M~l+-7Rc=x<yrM)\)<nOpd6mf7nrOsR(~)NCesB(B)NR071,=EM9C65t\P0*~h|L?V\=d/?~eNv{lx/G|qAw[}}8`tIOST#6%uDNSV=IgTOE;
::6Mj{#WJg5x`iUO7LQw*y3E7J{h8ilWp[3]C5zPNQam&!d%Yd,;ar*178=..FQvcNHP<|]N&d,n;fm#NQ(o<{ZE(T]jz~#g,9jt;Ph3.H/ky=@gLY^Uv78;LW;+r,3\/oOE
::yQm-eL7jgCUa,*sgD@(%\`;i944czB0{)keB4(`);61dVlJO)i}q5;qAmsGO29Eo.&kxz|*<}MAK2\@6UG3S*XlzX\PL!^FQ]V85<VlHiI00U6}C*vuIQ+G%l8!q5Q`uT*
::R<17l{Jky-CNsa1?sJ@Z<u=yZ{<r4Bq,\?@5#LTCzW9\-aM#5JdDJoYgT;HT#H*XRL4l/{Yx;{YI)omt+dn55#qE.81s!E?*CEIG_Iy3-*!$lNhl`tk^2E?RTm<l8_\TEa
::]YX*3SjV$lS~h-&ng\0]d`-/Z~J@m=gf1?KF@8`+#_^99tagsm+t?C!?m0?sl4^.WyQq7xz*{PY}mS_k4l8azlq3F\+hK?X=Q@^]Odat]CwT=yo@O}!?Zu|KbFal,1nkT2
::$xne0Akf_fvJGt5V$E()x*/ACRLa!U~HP*MFZI_tE!R5_mLew=yOtWLWqe>k+R3inF~SPYIX|`*9UxSQVszU;rf?iO3-sa@9qRmTqZ]!-q&hYC]^6+}m,0L\=,0Gs,/h4W
::q|yrDCZcHD;o`0`~=|*c>_3vW5hhrh.H{DVzW`ci{;DlO=gL7{*mE8M*lia4)9-}qRFL6S{cEQfc^8Nq1?V1pL/C{V#2\}?Mg)Fd54!ISS+jzLywL17w-!Vwn9iUULh4bm
::D_![fRCjZyoOEJ$|Kk1EWa~W81]XhJ\_8U,w@@;s6TSKy*WI)H4NogA~_,io80(2d<-<&}TA[^n2punkW{$W`Y!{B),$(_UC5Weyv08gRK-M86U/wgQm!5|FWo2?Mk;0uK
::ApH(6STF_&Sj_yu@)$BHMj7W}|Q0om;1aBt&.u;ZG![JpGb$`mSN8st5.}`3|,G&J!wpUQr/!oE6t~hW[V|nl*@5KauO3U~;@<}!}J;mWm$0?aT?Fx?F~xG;t50+I-%\;^
::9*3Fx><<dq@cW7qDSEaFxy/%<p!8ZrvjBOK_X}U2D3;YZnVZLcSYWB-k5NX$)VHGoMbRR#5`g}o6U~1<,r[LjbG(5Aq~5K2U5Y%G&^E-|}FYgPX2Ah36!U}T}-/bCUm_ti
::|6=@L5SA5+63c;1s|QAQ1iJl\5*%,Rha$E;={1schS\y@-gGA@C)1?_`v^q-Ew}Je-7Ybap!!rOH>d&dqKzH\nTcjFOt(ZzE}u]AIwtyhEk=>xU*)j(WFl?_{hilv8#={$
::FQ]m9=izl>jEHLB,q0cIPC9ZIh+nq6i9UHS]FAL-TlGee9gxf}}Px!aKCDl.]&LNp?mFt<bA>P(@3`J0Gr~^MoIc$N?[[*XgCLb7LFR;J}xOHXPda1B)pw-sy/s9\[9ry3
::WDyVZIrac)YP4.6o\g4y,@+<$^hz0y4VB;K[kPdz@R5!ZCv}fkqG\|{7mgFqt}do=cn6f3,X9g~!9@NBZzdW9Jm}&^#qKJrN;3kNGsjIfNQrY1=dBJceBc*0*(l\ZEqg~#
::q6y7~xXX$j]KrH$*6KEg?vW6^{Umy;2\?>xe3}ID%/C/gAGO?}-`%C>{aH\$WVWP5!12A@<r}4rL%eiT;R,^n--]=J7~8o$2N7DmQ8eOJWj0MtBtTQfKD6^V`P>#J,#mB/
::x,*fMpH`a_K!0T-|D((/hD.FMA>1Xgo.9+]|JQRY(Ym2Xj|K,(Q1Nu1nJ,YnEGLQi;6y_!$mTtI,>#dD3Ly<$PD6_8`Db1P@Z]VzcjJ!U)H&0U`yKV?Xp_~%ong;Ie=$dI
::_XphLMvYRAp}s14sX~vP&_vS0~8Z8}kZv2Jpl}vZE@T_jZUBRx,@b!55XETD)/,Y%4$un2D8e^OcQJGU,!1wl<-|{b!p}[2/s*Tv[<epgFxzE(;5()rVmwBj3d6i<<M}Mb
::pW2cS*RU/o\YEc,+-]{xAd$=3#yQ\O5)AwN*{3uY1DVwgPvb+gEl(97NV%%iqd=zATsI3]$EawI0.2+>7Y9GG3zMs3#7GS5h;3$nbsTBi\h0B)p.3WH*MnFn^</XtGTm48
::e4P{hK#lj.[vx[,ct]$t|{-yAt4&1a?8%GRES(7x>!@YA/RhCY?A\&W8Zq+5f@Xn>3rNFMgq{.+O;5nTFQ&>&0i?vDJmD~Wx5L_q}Jg<iq5<v#n<k|z5od4UohIw/HlXKT
::^z8~^+(zFlE@+7jPuPrY2Xsk;NXIgr8,%[FlRV]o`z}4`hmo=}tn~Aiq,~6]$dG]W/Pz]ikAEjb6*|eYm0mNX&,pC67]a,fh#(G7Qr?1`64!T59D/*Od|<]_TG7^4*+{oY
::M5KWcVL{~_`%U1f*R30o*aB3;4)p+3^*.p3osD0a`hI4gOS<#U1Y~Mt1s?z-q?wpwhK6p<DPSP)MW3.~|&),=}HAt*Uzc6%Bfcv`jH<PIQ?f68Ie%F_NF8GGV}nfZx[D;e
::?fr\Pz?72-m+L?}Ng0t6!EdfWpKc-K3k6l}0Tb0qfV!X({P[?Wgm];OEfjKA-|Hv?kX@K;$m)W-AG)Z=zB-yD2b-U_VpQ_OLdTeo5lGOF}<VzHH{c93Q*_%/Q^x)GHq/qo
::gbj!,N1=<ZwkLgnMCp]Kf%kqC0I#+NxH7BfNzyMhB`e>)snW*88jW,H,TY\U$;Y^EAMcVw^KZ/SRoU\-HKpmq#S\xt_S_y,[h>F%fGD-Fx%Yomv_cp^#@zw#y$W]MZ_\0y
::Fg4GP_Y*=%hmb$[ko$;kz51B.Fk3t9b/>}.T&FYj@F\mo0PxjP>/W(uv}u0_Opu3g=5I{PGQW?yh.o(jj;?<rLdL)J$%ziAYg3gHh3hEGxZ]@jYry8*sEH,uK)/%QRZEfA
::;`%\g*<fN7O45<Q8m/P_O92*DwrquOd%hT12d1K`-t03uM5!nvb3H&+\08T;b;Tnj{71~C+4CX[pS#t]pw~Nti2`E6DvoP[aaNV12neEUc,faJKC[_=\PX9CDTO[C[-?NR
::@k*V$F}u._YosM_M!GoLYgGLP)4u3pNL3/Rk;Y|0F?,WmRqE]<],=v1Dys\ew`}I0<\fs4Eex*|oCJrJ(GJ$#v9`nrnWqUIIxyzQz#H^lhI>=gM>}YHBmcEXdj787?bP-|
::xs*0FKeddxP/WGXiTc;38xO&ivd*eKlWZasp[NDP8a?@h(o9<xsrif|ELe)E>H_,X+HR?$T,N`?!o9S~pU\V&hLD4`/HNhU6OOG+B3A\pR(I}+jr)q}.ygu0|SNpJgLQK2
::KrnI2Hr+{yv?|/rbM)/9tA04EtwrPY#Q21x=VZ[@Qy%ZGq_S<||hezEmSZ]e>C_Qn6=).U7qA\-E#uQBcOn~4,Dtf`Q;g9O$0La3p3v`8aoxv_X`@!Y{UC0$/CN@$Es=0R
::c<e1J-^eS%vFFexr~R#ANWg}&[faIpTNZlGKV*|*kU)J)VsUp/awJNj$TO{WO][Y1kWT@~)*EcrL.M0|kG@PeI$M-Py{iKGJ^w;IM##w{r$i]<(]TAxXI6j,k|=.iR,#=1
::1^;6I>>D)glK}<\B;Wk/4EJ@0u~voEv.}i{H2,y-S[a;O/V`d5RutKL}J_{U-3yj5$uD2EFa`an?Y5@y\~[`>.)crwh&z\[n`e#NLe~tYU;LiCpeE5H^[,WPjLa4&/0}Xy
::>aar6Gg!K.z35jYE1gaR};bh}3/z5RJ|7NTceUDARjK%mG%`ktGvVR}wAtsQnb&2]q,9Ga.CUxZByXu8GZ?yBB=7PAk`RGzb`a!1._rw@.2%%|pG15Tnz;xL3{@8V7!c%4
::j_?h&S|w?i`ydQ~lI$R_u[{#;*u(fbK[S<hjC\^.LtZ.![x(03G*%ANXn;=e-o.P*\8#1R{h0SFw4tbxvu4jm)9_mW0vi~<vHK-l,M>qX+tYL[!l0e,(ANE?N!6T/`i!9B
::!S]5kSH]C7(Vyx2BhCL-Kq-my/z<a;XrU0Ll2>B(UV3fapz](EHkII4*G/v3zZ*Z[Kd&)6/@4bat=]mX(#YOi~#5^?,7z}eg@N[>zes6{{%G`2JYciC_X#T*G#BxS3{9XX
::Ks;T7ow^Y=boJtk*l(c0nxH,m!c62h?2=uRb&6M<lU?6[zQ7z/$lAat|0o1^\mad1ge*Po@?Qv]M2SlI>v>s!Zj;1?JJz+4;UROH^jYjdBBFuE]QEjKwTM&Oo<Dp5|iqxr
::7NOZPeu\57)esRv4<L<0GD0XQe-W&0b(JNkEc3<(nMIkE?\`D/mw}r>S)6c5FG)r{1&F\pdRP`N`@qv=^X@6n#DH8G~.>v^rL/EE;iy=etl|7R=%U/N9=q^u[1XM.8r[g0
::8]yXTq__J1fxH9bn9y.Z)pr\`WYavPa.#R8\RGy;leZTuF*-En=B/[$\=FY&{c}yfV)+{/;~vU+8ASC;69X5Pgw|htJmy-VA#tM<`wvg6J)k#iY\hCFBT8#Jy=^rhjI(=z
::&p[+VW)fP8r.v35R>=%C2R*}KoPc{)LSj(L_%{p[&U$xt?R1KfwnG<\.;r6piHw;`E,KN-tHWS>zI%c-~}jiVSJM0ExQ9wpD;ho+<leB%K]CxZg@IR5|DSV.BhK7uXoBy~
::Hf%)p6iaf=mlmJL}\q30&iO+}3\]*!48}p44<U$CI?b7eRW9!n-=;/WGQ^*WN/O)A^9jfhm_Z9_@Nmk6]ABc%iIhSJ>X%+\(@r*]jEQK+/~buTaLUgHeb53+N2la2D=l++
::L)w,g|^^4Qyo+S}!Z^k=m\}%k2gpssh6>gJX8l}2NJfmJSPQ;)P2YmM-zRO?MLtn4m?4b70cfL}YJ@)<r+zs{@\[QQC{mf$g`!,<NM=NrV=p1^=oN}Y/S)O1WQTe>Xq,Gq
::!3$-YwIo(5|3y6?.BmC/-@n1TU_;cos}tk|OFV7PeOs74OTlTe=O;BFQ*\?S2/oR3noG5SUQC1g88Ve&XFtam?Q+sma*>$Y&`b<AJTYwh_?me,L>}r|q6MN<T[_-2[?Y]z
::pc8nLo/nryQ9=Z$=CxpBDW(CpywrPhv!{ahlo\X#LNqhzl_Q-M-IZnz]Sl$)Vr&oP(Mg?~Mvf!`T}3ZtDPL4N%g|)-Yo(KU/xUl23/L&-QugT3BWccc\{*hE&@U!}+DO^4
::5,[1a_DZg*9i\6hFEemI~v,~(M.,Eh%K=@5H]Hb;.k=^XU=^Um;5/.&_Z-}Ka\d[)\h{2R~RuL;l?$tC1On?zdoazb`Kng@4EhUonQj40=d0|M6_rCGf4c)7H%$d`6iqTe
::k$z|_Aus2J6Nk~Au_i+!~}%1}E4s7YeG=DJKFc%<;qP04=M$4W&!RVq0kjcy=m9.g-t*cUs=eE\.\<j9N)py8ER]k-B/pbIRH-rw~7wH*y`X@(mpC`U5y<<_(_MTnh@.g$
::i~qrv!;T@o0xBYwG<DTy&*^4V_1+mkwo1&t]<a)$i)O6DqrzQyT@hlI$|_ry9VtmMmR1,)buaEJ-]+@rP}Jk+u*YhvVUEq,el];P>,aJEM1/s`GpSUJA/aH6u]Kc6Z~(SX
::YThF7Z`NKGTP9(`#v4#`KRU|3Zp7%en}Z2Y74<|LMIcmA)4(3%]jRn+@Bq-vmk6^5S;MF1P=1{A<Z-)Aa?b6C+fJok[_f++`lZ<}I-]O(r*z??d2/CTTkTVg)r5Qgp)=XL
::0Jh;qej1=jvpR4s_]?ZEjFqB0J^|myJj@6WZNvUZSYm2=5[G>r!7zz/\4RA%ri3XR%dkkgfwZ%wLoy_ir5V=+N}0f@xE@o&4w!apE7AO}Uo?fh93IsWC<8L{ZqafVn.0o#
::ZA8GUcS315<L7S6hfCSX`Q^.b*/j.1-QLFvWF[nz?)ttxG_WgYI/oG+zZz></t1LIRx}!,!hEhg\q$%S>FbR^1YZe][4rKXj+zm|J&{EzY8tB#Y~UzmoEYOp!6?y#(ktK$
::96@oM9/-0=qA*R_R[zP?kb.z(6?AXJ]icFzg@R\OC`rg)|PHwdH3hc}aL?>]}h#?G]w!M~sjqt;/e+6_#)Dn4D_RE_sQw1F|CKClXh>I{6DM>^;@H-`lwzZl,|Yy[{de]|
::_h9RQO3Jo`!p]M|{9rO6P9HPHF7_1m>9MH77RH/YBYRp$p4vP?wH>CKQ&sW#V+[TQVJ]AFS2/z$G$9?*%JNCvtcB2p}+L(Z])o*#$%IC0;d)OC(ZjR;zUBR6l?wWy@zqRL
::$mE!QCW2*]%37i3$^~(,$u`v;;a}C`a;6gN=G0N`T2]]s|7xX0k{[AzbLQx2aHzl}e!d3QO_;s#uKz.;1$~7JHcX`u2@LxD%)Nh{V*5NG7%1JZ`<7^O{77<l#UJApYY{Lv
::uLIbDfth4vf[vUG;ADn#@q\nD[wo@vZI-$`_j4V2K_uK&y%Z$On;T1(aTqTl=W@Dx6+^kfrag2Ij#`2!.3$q;8ZH+~.y`lc8JK+Sr(7(L&qZqO5NAR/Gw=dfKapgVObWW4
::%T#kn)<;s{-q}c^w,FD\V\mi]eqZ&)2=Rz~S7u3v;L7VKm3d$le/Q;GFLS9W~Fr$jM(a>[|W[E\m!;}+SCetoxLh_|rn>?5nhK9Bn2!DNy5}Ju8g2OUB.kagd;-?p|MSC}
::J_tj<!ZB&=[V-bUEEoaj_}%LA5]L%C#~BMa~`!8qUnyGF]iPyc<x|ewnp?ikSJQ<,@rt6@_T/u/<,d^yHM@PE%f!q.jRSR/2oI+@/^IE(MVZ4h}Gxz1N9#1hfd%Ab}w&l?
::OMptdViP\t>(<Az\/aH{t>(?G).B-NYugWCQ(xe5m`WK~4PmhXk5F&1ve%FKj5K_A-3VCMl9>+M+E,0Stjrw<QPylBEP;L.Mo@=dDt6X7=PshsN]<%oM)@yH7Yz2yBJ}T9
::QoSP9!3)to%1SnV1vO/s}MGzFgS%%G!^hP)$xE=I`}_?A]DBSV>n[<kvr;0aT}aFLO&[LNxe9?J&P\x[(v=G7_lT#kooOsIflMZN`~3a#L{bDs~KUuJbD0j?kFF@2X62<6
::;M?wiHf.R{*%{~Ne6U,|}z1gt($45cnnX!7pyeH?#[!a+;{&?YnVDnME(GUj\$AN4L6Wqk0jVkE<E(b<CE6^>*xRlfUNHK{%D[S_j]]Xo=@Zz+.+#KN%.KH&]S\e_BA7|\
::k=s1/#8V#ND\E3aS<t2NdqW$1J#H`%^VGyZy]jV`%[8<j,;w0J}=OT2R+,\Wc`*sqOGHlBj~E^%DGtrBlh!!j];?#a7_Z00p|KvBGv)U>P.}3.\BLEbLp2%w]?6GG@gg>z
::B;`%DeQQ*QS~+Bs/pIceO,ZmVY@BHeFSz<k?TDl,r!*4<!z+T}5y(?Z_6q\a3VKNe-m]<(.Z];qK%c9RB(nz?e*)+G}O_W%\{IYUqs7iruN|5IK@x{rKH3!),{wWF]rMd)
::V{U`tmk+mQ=HJ4XrEr*V6;Lv3P/4]Sz;#[Do1#\fQ2IETeqvr|HZv+4MA?RmoRv[z[W8;X{ET5?xS%87?(0mz@3Q9;]!9-49,mPvZz!gHRB`1*pQv,w5wVD1{{Q|&c6;pG
::_INbT,7e[O;Lt[@|Z/@vPk&4>ccE+cN#UrJHI(Q%r$DIw{r9mv~9_F^\Pb@-=}dY\>aN*x%L|1Pq~ug,nxS{J_hhkb@+yrFq-mK=39?d81A}P}EcLEX/T?xUjQ_F#=%c5G
::DwjF`HUCigTx3YLj]X66]P@pU=94[Xi82_xYj{#p[8O9K6HTxbm1NdGHUo69E&w!<Hzd?=0NV_OLCxV-wozOk6dCOk}jBY|/ZPGZ}V[W)G*>d!?5[WmDIl|{jYjN/EXj(K
::D4G_voO5RX32Os7uvxbfI#*&HZ(5Wyh(p/uJ,M%*O7O}?C8gi&L>M%I{.9O8b3zd/1bD\)r?VSPvq48kz$?W5>A0i0|v0(}BWO>.<+1.\@tqZ*LsMg3SO^hfn*k}DDXoDk
::6/7aE!v[5t#sc*dG&a^BB+vBPif4NYi\^7r&aHHmZNpvdaxn$utC/DpZ,r@fM13_[(;pgIZ0rrg$6$Zs>}6*M`pjg/^XYgH39a>9+#;G-%l5(oDPI4,|Du+oP6KF-f>{yC
::D9!^DDrdv?XyyLwPaLONX1N5^9GGL@gOxwJsZ1[E_Cf;AhBkRh-4g%M4b!\UP`4D;$FSz%0^9@P_US!E9bj<G1TM3A]_qo,&%vYr_&KT0DgUetz*nUNo$Hqu_xce$}#~jU
::1qBOz+_ym,jb~eRHswGg;F4Ryc#RCu=r=zd3;qp/`*p5mL*m;!*tuw*O]Yp`;??p=ip,mwv^pp1fQ@hctATWSr`PJV73ldxm2}+GBSV-L?Y*QVGdLz(j%XY?i87RUWp.dn
::!s&o2uHug|=&MkO_^gPaOz=Jfmzc<XHZw?i+{cn8([iSvzr&A}1hi`WbQ|pid\K#;ha`mJdp&$zoru)A0))Nm7OFHf=CX{`&w),_Iur*g\#q\k\i\(Oe;>EVDtZPFk}~f4
::lv^WiSIle1FIQTXB0BK25rQPb!^^)YJqd/P5Rl#TY11GXm7^VAdBB0bS8ZBD+.C$GRO`=oHW_$e8*jYHD!qk0`WK0+E)6;&^-%J)Y~[Nbb^a1-$~!(Tm!R>)JY5n<Ppp>o
::_rIrkkYAzMFk`i9*2/C.Z>+9N+N00!t}#tO>o),jPlRs)I~[0be(b}Q$/mBZU5T;oP~|eU9O,w>k86pAl^uK71BcQYAYZ34g}9601ZAtOpji>JsS|NqWDe@5t[[R=dE5#[
::Z6.hjrQiki]TA&tcfn8|Kh2*sbjLI5xi|FDWSn3W7+bm%iVGoT{q3dF}ETN,z6Zz8+hekSX|_p,bITQ+jEoSCBrM?a<[Vv,HedUvz0Ha)fs59V}lo)#[]LlUFlO8!<\z@o
::poO<@xa&;;i_Kxu]*h3UW7KQ#2c1e!YU~NvtwVFu=2,)\S\6Wi8M&AZS3gHc5|Rabs=$/b-i~6=Y0=@V%2r~Fy]E7nu}m&&40q}IG\~@B_9vu#7zaoT=z#&<mawS{v/uMP
::R3bGflh~yP>Ndu8*O_<Bk3>Pouls\?p$ghVy9u}Z\eS?!8,w|fA!B]NjV=+t3vO9k.9)\p(X./ahUA8#@rloVYO)s]/<Vr>unJViPv=KrAU\1]SkxsRDocQ/%AFi$CmaHi
::x,+b{SVR`}F71x=^ypf&g{@}w}R<Hk20S^-3wB0R5p1|GuwNKFMuq[8_P~(wrBe{\,0S,ZcJ|Nx*CI}9g*44/l$^.,KD5[1<mviug]pF&MtO=`eA6QnT}Yi1PO*x6xVFB/
::R$^J`AM,(1Xy--]Rj}L2q.~4%+=eg-ggU-]&xkvOD?ot66_xEBx,`ZzN\OW5ScGTcJ~Yd+~M|Ih`MA}%vH*U`v`y`3o}](Qv5B|d2%WwR_4?tq?&SKU8FWoQM2ZGREEb#Y
::-qsfk`a98DYlrJ(MmOJ|O?7&EaUl#tF()%q;&S8}F1E/d5U#fGlV`}uT8[|<op&`ks5k{S+x+8\8El*+gUu)w<{_.>CER<u}V=(Zf-27BSevWok~jj5Tj<x!!c&6kcRS!+
::8\Fqb_P(fJn=ujTy8#^;}(CqU,^h|W}H>x{[u9t+7O5u2Y*C;tugVxYS[x;4]LG&B!rHi!uMuX~w7`[b$sW}I2c5wa?P1CaC<w^X0x5!}shDumXAr3`[e*.g%Dy2>-jst@
::X~G&_\m,~h922vb<;,F7[#*x_ZS0c<dMI{?F!A6s+^WRN<[vjL/8~+z^4$A#j7o4ws[ie,wa-@fkAqz@,4-w%m91<nCaJD@+pdd&l41{K/$Q2P_7mTkj!}*xVar&loxX/(
::O{v=>%Nh^bO~Qd`6G`g>nn,{=p1I#S_Z3?WN)/yve7BT6w@`Jnp}jP~p7w]De^gKJEgH.grwXt]B4A0|TY`Bb$bo6eSMQF=1@K|x\y3_2[,e#qYkRNE$A;#c?W8e!Sj]V7
::E@s-kk2/kd66c<H(6jiIN<6z]o)R.<?fk&!}UiKRZdb9T-XEG~y;lz0+jF0buiM>O+XFN_<F@%#1mgvJSkd<kuXjXk`*>,8VAFXmj(l4HeD;Hh_}Kl&&X+c[WUisQrV~Z]
::#bJDc<G))Fiw$=ql!Fnzr2DVbW}*FRv%OC<AngaY^1GTB(vTR=szINt/wcZqK(dHgR7pcI;Yg3A-&/jnm/fuJTCF@,D[aQE5,81R&3{d*px^5],)MaB9H3hJt*[UfL]@;y
::2C\n,Sm4]OnOO}[R)F0@<U)g>wn#v/P|>SAHkk{`k{s+bvXTaA2O/gMpo8t53H~ybOMCh9cBfKRPp|y@>wUQV^C5_3ZBiXo#[Gq6Uwo[t4;U*Qg0?jb^T.&L{g45tM!0x%
::rIYP)C%z=xJF9O2r#)<*>&*IOvR!mI5*&&dw{hCrD6sVzC7U%~S(1y>pM29Q3HU}XpX@shH%UDvL&As7s8&SF#.n#%gi<SIpg|;<SC+Y`B^9lXv9@d%pb8VUB7)HxMja8$
::Vfu,<`1$?u~i?Hu;h-Lxs{|Ih&Jx!B1H<&]L,\T;-8T-Txol=RQ6I3X^6\VXSPr#93z@{Q[AppEsn9_9wLo<#oqz!^?[X~?r7IKg&{tBU]%F$UZfnLw)I>#haG`nBBMCvh
::%J{gNEj1]~*U1P?fi1#kJrx=m/Ru[^4EgUuYZ=~H,`Fp$)lF<EPKp?6<`cMk(&_(s[>!l<l16OuaD2LJgbm9;!<]uMtp*5%V=5Q*P1-)ro@tiUTS2V1Av@>O_**ip2Y~i_
::ct&clJ*g+vSNUqq&_pMXLO./<oQ5x7@;A)CP..@KQb,,z|J4idU6rP=E}SL)s>T=d,O*w%smD361+V?~?MDx2[UWrMi8tUDr|_,)lM~`bz/5D/N&q{}w~vS`bf$kZI}sgX
::vL|}nkwEN{^H8ws5aaF%E@TQ0-5eDqW@y1fG~O|*]1J|DICL#x|4rhh.DHq[[8viXnWHI4{#TBb*~.5[-#=sp&C=m7bmQAxK@J;KuInF1\=G3D}pZ+gS|uiWt=[tp^mnM(
::59O6hV5_TG;/H8pp&xUuL4$R=o{Lg~~LC!t6,+c6j+73LPJ_qO<p%.OF0p{RZL@[fd[UFjk>nJ]yw[?0K6S?CGwvaSvT0s%=NYi)Yujhx}}fkv2vUFa!c2wxPwnMO*VA1&
::S3m4`A%M<)fAW+-%TZa3ZDjtAK&GoDYP,~buV(LVZrps0(d@p.j-nJ+t@B\U_Z+WlSbigd^Ll5=~_vuqjL^gYqvQLrZ|XA]f!T&6&F9eZod12{?%}g^_!Js48;0yipGOgG
::um0@)DvD%@5?.Q*S5&!YJTM^l8j53\/pB-Y=u/O4;7~7KaS7Y+93$5YomrTw1+2C1Eq/1{>_A;z<OLjZu9F})Ppz%_y9p15U;w0\M1n3T<2i6kg!5d)_nbJJ@S=~YcrS`?
::>1c!$I;Z%$B1rIv6`x#df7&[lJ<eEZs@fSY>TXExS@gK<3~SVlK8Ag]fH!OTQryl-v_#}xu08}n0U1ujfaY,irQ(Eik+-s%]asfDV)NM45wQpBg[0wd1?gSG4Z[;UOzp)a
::pR8@m/ew=lj>Bu];FPyx%jZb!2YdrQM%#W#(K~L,yhrYbk&W3TOF}?3OTK{j[~YuhArIo`Z|*5t/W~gWRB&Sx!-HiI1gp73izCQ,LGJ~?vbqBI-RP4Bl^3M~hH^v8}}-Hw
::r(RaO^xQI{o^u@F6@7o9NaK!fN.P$tmg0/_K(@O{b01Zio%[n2)O(%c#YvRslyBkH^uA{C2H,/8^_-4B.OJ?U|[+kU+r0T`6\kc)KnUe&`>csD5o{xm!76m{p],|?Ds<.R
::yxDP$P5m<BMa~K|\Z(FqJDxES%cw;mNu`uK>g0kRraw7*jG$/3fEa1&xpQY_sJ@<8nW]ca5V0$@pHmA#fmlmV2(G!ww8x_%dF)e&(%qv;0;FuEcEw^{,pYuH,cEF-jc|[9
::jw{%|^<sT|[HH!R8of7rBCp,PX,O9!Xr19!wJJn[Q@kd[!*gvOxkh8cUF5Q>)3=(_Hq[]^>V*vRz|?]INKEf2PXCAB.p~O092)9q5|Ld~4Am{?]2A[q#G7Vl~7B#X@%}!A
::>_hox=`!+g&Up/e^OrtYn;hnl5;+6UxVm_u^Oer62P9{5w*tKB7mwOgr.+|Uf/\9lWK)hy>pX$(Un59l@JuNnOaym3hX6{-kXR`nKF2)sDrvvvmB*mFh<B1gO]rEv][P6]
::yFS[Da!_Ek#?q8`.CfEuQg(`Q/>THh`|HL%hFalVYN{-v2751;G+lZEd3w$-&Ywi1asyobj;Wt~i6aH~<sD8`YZ\ntB/[qh_RVnBszTFry*OCPOAZ^l|uF/#L_bU;5(zu_
::!1<F`!VD*F$f)Bjb0L$n,Epglrh#y2gSr~SVm$k/Pnj3xn,hP6Okyr^2hvdezOLiB)o%WJ=0Zkx-O!VS3[GkXFr%,HY9G.5s![WF~Ydxii%]mFz5FOgqt@.7ayJY<$qctT
::o5jpdbBAF]lw|,Zqpq`d%7bK1b~*#gRa3asOz~46](0Ty5^]cZGn9`W]R,`lvS@J?h{9k=o`?WAkM_6;N@*q+nmGVJAF&wAAl$HotbiP#OAw,2+VVQB|1Bf>&ZA=Jx(ddE
::.~X;Rz{?<X@f5NYcr80+~c*X.!HLd/!.H(}00[.V+}VL*Y1PMF`c-.xSIW5KBO!hp6dW3+F,W_.<z)M&%[^bL9rT6;}7;4e$Q-NsbyXlCqnf2DfunpKc@{y*AXN}!7x<b/
::2>+Zih5Ru]H4GDJe_4!wS$S|[A@LIaQr9jsWuI{k9b5wTF[#PNk^RB]|;1rw}!T_ZO@}h7rS7l.MJ^RwBl4oFPd?9_vlxxvT)kOGzS!dnr[?#DRV+9k)2N)~CwsTeT/o[{
::*}bN{SaUyWRHNc/3!J/UUy$W,pwrP@+lC/h3ilV=sREKuk1z>-V#AqXrL!Ntf7]M-1_8t7B+S8uhJ[U\eyfZa7?2BnWYN4&__A9^cJwm|yXR[k52Ic\VQ1.vLD7KnxBb2<
::t1CL-]xtRwlY`.b3Nh$i1X)(=b4dfF63DGd<i+vzDtvO$?2mTlPZckFZKt/%.GkLsOcXevFQDWEv%f6KV|LK}mbzmxus&;QxBc21c[G@.JFiX=IUb8Hm7u6@tt=rD!W_.^
::4p&X#B5XDKQ5`/e/NUn@S~$9G)e0(f;,K(REKx.r3I+0]v8A,$XW||M58YA#uA;^9`TQ(@F)DI*]g(B07+E@jh<Q]q;TgI1Wis/z?CTa*;1ZR@NPE$tfd}`_mrI]tj%Sq,
::oG<zcbvFMUuE{8T[acl4dE8Z1C,WW;,tbo4k}={SPLtQ%S+Vg0&(FBFEp3!U7#pSIij&dRn!Uvo08Dng)tqdbwFA9oiv3$g_Vq_l^Xv-S-OmcpO^~L(N)?\)aq#x%F86p`
::ylDf)Ff1/dOS_u$Ia%lC/;Lm7_p@b^m3kSla^}V8vC&qz`n,}NX9?ko1^^]#2Y^z[f[HO-p-YLSuiK!e~MfWe;G9Y#eN35Z1z&.=d+^(_T2=i|^%bJtI^uu@Gmx*.#YzGY
::iRMKBVTPB^&~?@?X5wdYn-N3?`pIruFsDr}BJ2d0;rnU6k*QF0M`t\N`hokzs-7S%%3%$]/\t$k\.vfV4K;]v3Sckh$}x~[~>fU1eR.i!=~c]aVScP!s?@*}>9u+^}Bw}V
::9T?Yfq[mLZGqgn#l>=Lj4~p)RzMk25]dk+LOuQI<s97Bpo%|HKRQlTG~3Pax.DjiDhTfj#Km~~$W@W5XP@cuqK=B%0@3exN0)j+BrbJZSPdkN~KNGF6&/Bg~.`Kpt=0i$K
::twzxuM]LCjT%&[FdjbBU~A1=aj%OVv@<j7N)$+&2}2mMnk+we0o?x>{C\4*XO?(<ty`7e(JBB`La7FXB~|5_EJI~j6>i5App*.K!S4/LxF!@q\uN!*mqa3w{u4u}&y?5du
::(&]d]f(7m|2.`>-;iWr,auNnL<39+Z2x{\7bf,nf]g[a$isM>nNso0QhmZSYZ\a7`Tjcj<dl*_c9}CVD*m!@,RqHo]j/2K@$&VN{9b5&|RwmRjyGwI[Z^}/[3MxXXABs{&
::z>&A&^u^IWUr\TY~b]*[0@eMc1v+N6jc^Yx{O.ISfH1?x)B9]t!o[F|bKw`hBl6S*eebx|FJ[g8|^huH)1cx9n}xMBR/KRfr2n)H&-vU([>GR(8&ie1$m]}~PqBU+.3|3Q
::@^hrH\$^!d$zvNF~&NR#9q!QNxD+#Z<*bylMrE%EpQJ~+$?md)gr+V]]GbN|T78g.AxmN<C&/u7Seo]m}jIHP),6VPie]@7i$9I]s=Mh*>\S^Y\KzZ/+gJ7?8tYYeJGeuV
::UFmd!v4lT(I4?k*K>NC>2.y-j=C_nYWK1kBZubel`}KRF%l8OCV^GYz=K4g-tVH[yNYY~X&Edr5gHT$.%JhKEHp4c8d#Sq$HOG$DfW|A&dOW;%E2;;pk%XK6dp[Ue\AlmZ
::/,OiIsJRe!b+Y(,4ZTqa#[)S<Q]sOFK_g~aH8CDK/=b*j)nYITlhbnX$2/vZQYzg2Au-q<t`RdP(RjEE?UF]4$Q%;<A(rLQcLfq1Xd-DLndA<ZYYx=PV[U1>iSR3`w9A6@
::8%,@f9pT`gP4\m_6Y4*gK.sX%CRT=3!v}a(G,f-x~uOrGgoBpSizS=@4D$@\wn/W+r[F2VBlt>Ri^gwnx(uJ!P[mGqM<.XTi;y\]*[5\2=_@?G<=lT5VP&l28I7td}m<-!
::@1u?MWeR_\LEs(X]_$M#>vTN.58.<$+$|y~gqJXr%3$9C,]eNiXlGo;Pn#ke~M5Y]nuOe@;Ji\ul0,^p`4E+Yyj*\}KYFluCj{JBt1>%JH`.C<LfcI^pUgoA]pd@cCUQb}
::3N7TOQHqSM&)fX~Xp,ASymZkeOBT1mMp=uL;|A9`.?6SxPoLw_8W\.^Yo;T9pf&y-5J=Tc.y_FSEP%}ZJ@7W*yN@l,&Km]?&14PTmv>}paa/0ySOI/QI`;UAR180[>)NQ<
::;drj4rJ7]CfgZCSX%b*a^ZI?,hKbZnC!t,wcuLSBN%tF#GpA[f~#ns7hjI=\LX^M#++[5{_kXWf)G\Mcq<t1F$EVR4M?mZrIP1pCtg%Lcj|__&+at/~}ydvH%pO(6s=tj>
::{f5qYU/l_M@){iqfjzrb]c+]u~f>f315Iz,(fmkl~aFm5`G#J,gR,2(^RtFzRFAuI8Jjdg1+r9hvM`utblEoT/g`gb>|.Yb62Ld,;h2uO,&05SLUY;*qJb9?,RO8Fb4Gcb
::n>yW<HwQ>_(|CNr${}0`fvcW~x=UB|uzuJ5n/BmBZ/P|rA%^bYiUSk*~!/r}`6oDS;*[fl<bgZ-3L)8~(Ka]@@kGZ}7`7b~(GmYh`KEiUHn|[/s\y?jO]F3ZG-_rC<fg}m
::k4#Sf~m#)N,5![K,,q_le_w\u&X<eo;VR)-xHY{R%l2tE,{*z*)]1>Pe..L#J\0t6~lz`y^/w*JR)60@KP__LB^CJ<;`@eoGbO;@1cR[1_u9^;CAmHe*j#97%u5.iz!Yrt
::Tx+9~9oY5R-B#yVww#h%y0Gibd01y}_/E<#ObToaKZLjSi_DH7$M%0wTBuS;4d%Db<}y(gHQnz)D=rF;E#VYxU{<Pad~p$ZR~]ieRfSXt1!0rCb68q_B-Ur0o$DRO7icGO
::YNx0c!k7^hC$VP1+L))*_+`(oO4Mbzm5.8t^6O6ElSn{QI7cAX@n0?,7|kIkP@Wm#5b?Tn0PO*7J={PHaBpzJcW#{58bB_ZRFhu}!9p,SAF#v;9R`M=8sMDgZ2An@.bb*C
::`&hu+V?3s$6~H#(#KVSQHetW%sp[g+Ioo@KpoVc)|u^Vp]upNqK!~,Wv>-UaxPz4[brR^,}@3cCE|rDN>g6$|IT9Pm=gV5=~\od&R*6c]p|lf7Y[P\;QryJUsWXNvkUyfo
::55^$8[z95Zduy3yJsho/Pa1=Xx&v~bk08y+w<|yz$@Vp-uy{A2N~6,|.yhsy7bTdFLMR4)PBy|4{aKFAh{t?F;_=rZv|#8L/VO~y4Hquu]v<+8[/5L1?=6)R.{1!CHgY}_
::{Jo<K*<e_t$13/NQ(D2=+P]G6pmF0v>.i`DfB8zE,_z/OzvCyCsa=xG=l$dY2TVm3xB6Kk]3c\Q-E,1OFwB`7E*=bc)22ecm=]ak[Q/eW`\UcFKxKfdvVTB|jSus^2t4^5
::~RHargoGQF~||!4a}[*}jLwP1;dFYS\Q%eX\7/Kw%#nAtE<ji<[h_GN))IG;iUF7-)0H(*`!(_.]>\gXZ&(h=|lWp3)ec90$J7>~aS@zP%T#K#*@=$&?\MVSHwa)voAyYX
::lEh^-2F;nPbw<d`h)`.al&ALOr!2p4`i6eA5cyQk?`wM+aBh%*I9J^B?#$GMmJEy`3}@o_A{?6=Z5AJ-3FV_OL(!8tETzf=}5Y.L~GA_iUfz+M#%3%MAXYz&tExZIMY<J(
::wh?)5hGYa3$>9)Jm[`3E,vhuik,S8kKxouxx9S^s^34$X/<7Lx^KXNcn`=O%}K9yRQHd*5dpB>c$3hiJdY2Sb1TmBvP3b$uMqf$8_H?}N-tk~-f1QG`Bq^<,hEdFkkv&om
::>RX4R+fP2KQ@2]]fM2tGU24yoHPeM6.N%(&EuZ(s_DE]z25v&RKt/Mj%_\rd_RxbVas+sJopcyRVN0f&Ac&(bFG<1`L3%#mLc?},sQ&O-reE-{L.590J4m%p;sQ>-?ob!x
::4ui.>/Q*;--BTA3%x/;7f($XuhS]t?e%KCei195ENZ>%eWH)c2P7ZEqA{e8>g,|lCUfvxJn]abq4#8q*a-K7T}(z5Jy!vtQZ5mf.ka0`^&ULDo7JAHrK`J$\a@]^/(-wo.
::7B\DzQp]]aT$(fZ7Bfq,!n[{+1APP300F1_^g4~Sz)~O93n@Xt$XP;oRl._e^58}VU(l`YqTd$h*/4A9ma!G#YsnJemi_!<G/rg~dxKSS&eNqCb8pYt-0<pbb`YGdbM$*~
::;uOr)(`VP5RikL=(8-wt$ZMix79fY%oiUqUQ00f`B%L@6\6,Ko8dwe[o|v8yhq>A95`QVCGG?nLv6i$NTK5OAdrC(&V06\]HC(29F~Qb)?tUlVg2xnI(E,sy9jaj`{s92[
::IOGglurOV6vfR8pydn?B2|6BQyd9EeR+<bo9[F0{n7I3AP`/]B}0A.hMA}_X|<t8]w&7Waf@?PwsXL>aG1%7~L,<A=t^~o~2Izs%~W=BAg![,A>c@Tr@IpEB$7Nr_V\4!d
::MuU[}LClKnrFyO$|k7T@i!=UD7SO`yp$2j6N;g}4-p2+j3{=2&*D}tvP4d`*@<yMWdP@S=7HfJC5@WTW6?l/Qw,QNjt>Idw8eDGxPv8/hf-{0noy`tr5eEaHQoy!LTsnOm
::52|AP2={C];OV*%nob<M#0dZvZj?L>KO=deMd(54DC<Z7/8H$+Thz@wfT?)bi..N,ezg@ey;@#ln*!2&xnLDk}6wc!>Zc9Hai+]uGS$nz(27.ZqWEoI/*6wtf/!jDS{TO-
::Wiw$Y)L^KQ3b9oI`IlUq+w1WC{q&HY~aPSVkd;I/^nj+4!S~cJhS@21W9\dsxhy;^-K4IuK9?stY{R{B[}Q2Wqy4o@6XzqL0v5cV>~s1&Rl4<#y4l/u0\=yGbkxXxtyOA8
::}j29RpW%aNt^1*3_hsM(R6Y9WsXjmF|<(tWAd?YuH?OiCnU~CbG!X9ei6V=bcI[y)`Z9#b^5{Af_-1_FIPe,gy]?To&Urqz+)+lXEM)qG4G5o0z@7wz#g%8}KDj~!/d-kS
::XKI2+F|dunB-\7}^>jwFlc<^q0LF~Ol3<j~nGfda..I2mMkH?2mtqV>noO2AmVXarI|.|3-P.i[_yi^f9W@~H|{opVq@TS\v;QqD2UV#Q^_>ryv7<xsPn2v\|xJnt$-Goq
::d5ZzL@^db7v2bQUw8^~8<R*@BPEwcxMBbj&(11O?Wisg<t;,I*lR0[KT4~eb,d1njT1^v2X$)0magX-\y@{n3cSEBkw]+bz/QO7/I0&k@.q)wN[N<f={_Pdu|v=Y?e)#9t
::s]BpZ`fb%i>$b^*l*Syc6XKmz*7o$leaBy*$ex#uhzTY&rs]E}?LFJy]1i;eDG<K5O=|OIC4[AMhrt-X%Dha\_R7;qq<6w0$~uLBJb&2Gk^ivlC5;c!O@+794N*RV}p*Nd
::b^UJX9<Z.)ht./vxdd%iuMIb(aoUAuwq37=u{+j!\D|H^rVP$A!n^4@-rXIRzI3$N7X5p/D_sK?Rle%$`@fM4k(lpK*}]mrU_5)?~nDkh*WoyqD7QAxYw}|NTI,}RFUUwI
::`I*!_@<qRIP11hZkY!F(y+*2!3X\X{(lRkDP#P-4}E>wu58X.OYy)DmxU\V5Rske==I{^/tLV3#!9sv<kb!FFs@\CXFN[Y37|!OFX4&ou)o<p9A<5+ks`2a;q|=-h3&c2v
::>P8A9Q_)u$kFNFqKD)L]C5=@gG<xMX^D/nMiM<\Piw@dV)?4$/p%QKUyFgO1DW31yaMy-D.vszCCS[?;2dO#(oluiV^ApG6SH$YX],^2y8J/{i.Vq!/nM[WR\fu_L4&$av
::_lRD0|jl!mxxf!dC<#rZQsr<Av9l%fh\;m>(cqU{s,3A1]qza$5nt72oELgP-`5^IH\`Cs*IkSz.t[I6S+i3mReqiB5zao]5x,nCd-OMC?(),8kPx/^4BIw2Gg#+%\b*g<
::`[r)ZIu{&r$sR/,4R1O3GEvQIFapLZ??.Y9Yo95mnDGp@OEN~__n(rK20|Pk3$r4t@5JEi.0}}xF9Az@|zr$-do\`Kzw~4rnd@8ewN@b9<6MQ;<qvDG8@p=-nBsX<1gy2]
::NL1\*}waT}GQ</v_hG|z]3oF%LA9+D]\iFlpk3e5-8Z`Rz/9Q}2$.x}NQ]!F%]YZ-#C@P85Pi*e1W60FxRrw##|0>Q+2|Tmtqi6C@dodn,/k^9GQ,<1)S*ynw7ma.|wp72
::f\0j}yUA\9Mfuzn6u|<0GNJN|3>KS?%DgcS3,0X*N8SOm{<#R-rLo9,4T)f|+G+P*1$jf$lh4j9qhWgOJB6l`Y/j{i;18ua#}e-!n~g28L=vfr?g%(b@m5t&Li8Tlt\rYE
::)<FHrH,u8BstK`<tFQ&.tq6a8CgW>Q&==H~B](I4dECOy0,zLjn8)nA\w*(bs__V-UuIt-yS@@iV~4?rV`\%R@eoYj7W;q(jkBYw|Fwlyzwrk`e)sZnL+>*p}/mc6}Y+Kg
::?!nCr4Y^ue!pwx*rf!Z}fK[70u$,ph#?4ht\EnxiMJHG@<YO\4rJ73lDQ7z!u9$qet5\;sj{|2Ivr`{]yS9LHLu$zCFD\N]SdWFP-[ail|/rjmjlBU9hg]KA8R3bsAA<!-
::*RapTJkCY@/dT9TQFRy7SMvTZ^TDi\yg0fRo@F`&0yI4Gw5\NezS2++\jz^xWj8Yb?=Q~8hOsg01TbpKNoMGcLDdD/UCNdtu!h53^2#+RyV*1][Y<bO{1THx#$U<V-3+u\
::Z)?;,`0OEM}tcNKG<S6nWCS\&B`2W]K1E03lr~\9a4eimz-l(+u$0LP[7G??IFebG(UN~n`Jt?ErUhO#$io{RFd\PB9Vjmn9z)](6WC$Pl,HnA;lM4M*\~+#vkqS1RovSh
::pXR<Kx+Bakztu8%]Ed44dbc!A[P!t\pkbj#hCr<R+D-Dp1Q(b[4$|,myNFaA(xB_8~u\{]{/2`/S(@S6P40}%+h8Pi4]_{Y`lc[Cx=O4\6V31C_P6`0Lpf3!1zDxsu_cjn
::;NtNS]pc[x|eUvh%Ye5LP0xZl`ZUAhbV]q]>-|J@p2RnHy61Np8C-viCvq-/[45C,`j7yq{uh_vD0$6vh*p@><Esv4WT(}$!}MLyPa5P|PONLvu]_xmiXyRB1m_m<PHje3
::tNSsX;OfzoMM@=mP-I@T9BJY&/u4(51!nDI*Zdt#YE#1^l<y0IX(>ft9hH),Dry/43H[h^*sRD*$wz?5%-mpNc^&KX5z6#de~%=L0Z[O.Sj8e{h!{tGN)?.!3-&D{[[D@2
::%gq)hC\i]]@&,v/hqlFr}FmA7]E=<<7hPrfio`\<w[Dsy,$Ib2brspwUV;Dz0ZT0f1VPDe*]BZ`N6j}TDS4LR}}1&yhO7owx.;0`SQY8i#l-,3)$Owhg+1JityEg2Y@l-P
::!N8aEmn{ngg)T10=S/4/U?,Tr\35[;GG#ZE$ccB%SXz6_+WR;T^BrLEhvt9ym4N_BthD@KF0DJr(IVE/-]Rtha}#*q06EsN7;Gl1Dg=]HE53M<kN$Ve+[<$-w$xPHtwTHy
::7DLok^&-;7L=ZOm7n9=kfwY~ffQFtMk1pBd~4a!rO\O{PA9wGZquig<G(^KlOeX}pQ\(w-S<Ms$EfsCRC-l1+z;zNi$<]3v1j^Jefa7ffxS6U?<z.tHTioglVbTPTNa6z8
::h^-m[(?5FfGU\~91Tgyn)`9Cmq+XV$*f/fOEZ;X5M46&.4n)1#rWKTL2*BCM+kC=+%8YL)z@jN-Cbd\3S8S(LO~7w0;5ST//!svLdnr!v6n>s,[U?S>ir,tyPNUuRBY?_e
::6M&?eq37dNQ9-7$f>1wqV5jY2e0A}irQ6qo]z2%X^9<96E>c&v~/,&[C6/1&UncrZc!l5,F_vR.}(O>PT@GE]Pz;q4THX<Vc_Zx<}=2$wzit5~$4kQd?UCe@\p;G|on8$z
::g{WW~4ljZ<L#$IasZa4ku;a5KME_vbJjcxF)v}6qnP#[sn6o;x#zW3/k@gL&XM170Ok,ipss*dEI&JSKaz}8pfp%-batvjj5%T8h[#<<<x3,D/=jEU<L-<-4^c;NPZlM(T
::t}4bVc@Q6$xAa$&PK_WPaccS7{l=op[N9rvEJqf@`7XcD9u9{mu+d;DPdlhntvA_WwQK|bXP@l[ggCurH=gDJ(DST+H[YX_)sT8;}CSVMPIuvjO?@Pl0d$Q`<h&jY>IykP
::wW.GZ^J+[5Trc>p?[,Ppk%WxFqrU5DPFz>i^hJ{#a@(McKuTrd,laK)(@<#uW/U$X5{I()?fe45;o,0s|oaOZQ37T,2D%K$VtUw/\IkiJE5d?h(fRi3^p2_N\;y)26/J.2
::cD<^AN5e//rFRC@F-OnFA|pgQ0_&NyS+R4o?giC8Cz~Fw[p2!au/o#&d%e3U{a7uT(*5H6CNcb?0<cCVjufvMgv,d<#RQ/r?x\SO~F^7wYf|yf7bR%y9Z\(+Jg$U\{epy?
::Cq{/UG,He_#(/97}aTD^fNk@MPFKF\DL4V$H<5=.=X&6y<nE2CKLAVPIJQ9D,7_2ww`,NH7T4OT;vAD#Y>r}]TNE>OAWuQ6+p-\J(5[*29h$1Sz[nkWonmqqqg}c-8UJh[
::|}9e^@5!&yBl^@,@/6]rS^Geg!gFA-[T<1EQHq6qui#CbeH2I2{!QB(ULgT{t@vE^85.2l]_3mwt`]W5wr]lF5-cm,!^qgN@LiSAr1n8z,LcI+m}fbF[R!*;X5@Pm;W.9L
::b1Vc8b?-;?.*AeOkGy6Y4u8IFm}zkMadsh~+wIL}6;@JlfaUO-KVUAos`aZ/-~jxg^|a@54<lse-!tn;6?)L{t(W^;/%BN_!@qp_K*slf5!FR;ZzT%8w&gci|2?Tmlw1%#
::HGQk[YB4o(x4q#pu]rtBifEbF~jONQ!bPD_on-/]0utR,Pd3%Aqb&1&Oe~nbt&d$~{UQ(vd@~E]N{YMFCUP}KS6Q3_7OTJ6Q;DxcOO}mCrwu[/._QqQx`JlTZ>s.}~7y6W
::ip[Qy%n+#Q/O9;_[E~/(^.eRr]6lFlDlpw$l2;HMwfYs9QN?7RDh`b|$bE?7Y8jb)E6f$cE&nGH7]q|6\}Cg+yAQd5%W`T*ViAZ]j^g[*>rtKHOZ)C/dqy2(kyZBc8wSY)
:://puZ@~%O)McR2.jjDJ^hhU[n#BrV6f]7zQL=XzZz)SOjcI;+hJ#*%8^K,Q95Jbg?uyO4~/(K=bnBEbl.Sr\gVN4@-=d8G[Y0I9DS=ls8|rmBL1@@UN~y-E8KT]rm&,a-?
::Q(jD)ird*}j^F&4v8D`LKi=W~Or)}zT/5Yd}&z;xBnBQD{)%5.gff]yL!|NBe@eK#O9XjZ)m=H{/qk)@l8o`2!?!jOcj_8T5D!Luc{MbVr|&etDs*@zoNvQrLSWED]MYMT
::Hn(@Lmi!L29X.6Rct<om48-8%#AcE\`Li_CNh/4<R48+/|djS,ejEF7&4^MLO70iPc//.&xFHpZ}jn2VWLzsqm[=k=LWV9a+wM^wnDeW55($}Q^zvXs2t<TN#T1LG4UEY8
::8Kh75(}2.nj7rd1fN8ZH5qF%Zl=W0z!W~tGg}.cYwdXR\4%aJpOOoMeqFHsL+<AE(M>yN*@X4Zo2b57y?R@dG#E1W(u-VN>aA424Z2?7M;9,s<R_$!Xb1^D5b~3|&L}6(3
::\$oNVy<Rbgh*xM%bfuW)a@\q/u7qz0Ja$QLDp+3cApdP$\hq>WxP?P(s)7j.9pHQW$f2[F9tN2cCPLjWP%A}IPkk>h2Vcx}+(SeVIMG&*]NfZy6s.Ar29dVc~Q$Z>kf/{n
::]3-,a32|1Fv6PkVS$}iV3S6r=;D7]j^CLtvHhPPJ/<L<3,BdN2[q72a;\yBG)O~Lx#;8M2Yy;P&H88>(}?M]U0Yl!&=0<[=Te\WDO!0lCQ7j8p{cv(-e9p9U||>g`JWU.A
::z.GnZ{YUr#ucExo#~beF`abg!<5;rNYnbl{G3k8SiUG6?U]rH*{-F2R`4~pA+PDBYn=fc@,`<ZichgDNJjbOqEBQ\p8gJ!*S3(%mN/<~TZ`[JN7e~zRhjA\B6b)T?#3nQF
::uhS}[*3QBa7r^,eGM<\W(qV6pb87z{[1feVr86tBZS@*Hg0GQLAsX%g*|aI5F2VbZ8T~uKSAuWFssje\1^{nnI~31NV\g/OGudLR.p&RyLI*Wp4h}z4a@c7zKk/)&6l\R/
::7ItI-y{C4iEWy\{[8Z{[r*j@`vP[(Q5,0l`M1pX4-80z(Ny+JK0.bTW?pFiRh{mR&[TXy=+HT*D3h;|fFP]!bWe65EO!aWxg3Fl,ZuM-;c$ibHbF*a-btkeH!mYQ(3P%)A
::a_%aywY(2,.1&?8J|}!@>%3Zy1KeJT~MLakBEE&@Zj}f4WB/BFSE<A/)-c@pd]o{@C\v{!vxDorB<xBU$V)!k<vWb*$.*p!Wt&\h{v7wiDQeZTJ42q/X4ilILDg<M~0TMM
::%C0#-7bB[b8e!UqLbywu}G[z5R4xwI@7jIDO*_#tH4-K>3rCika]QvfC(qV89}XEgIvv|#_NvK<@x$K^=%&%O!SbtXZS^YaT#=|P84~-*A8nGr;K)&B.X=/Ti\`3_6jNyT
::xr2hOv/DOu5=Z%2b)@Mq8H,g*`bR?R60doa}il<u9FpZX<tp5ha*\6V`8b\jSv6=|W]{ZI}D/1DR,[[2x04SB3I%9)YM0*K%_88;u8Hrl|gBb(ge@|kfTNci}F6s>BJ9p+
::[v.<vfgw7\cmuAF]9hqcT&|pUJm{1O1N4>q(IQ@1mP9OYt$,<yTSh6NR4M%|ZdR8pRcl+l8p5wV_M%QORor|)L/j|&#3G{^/R}Me&!6(1B)7zCQsZ}X]M,J1=5>Vj$pZ=F
::,*,U1y|]|}17Jg,`b1Pnn62;Vus_ZLtGB4`_lN_h26Cn1Hzr$s7]$u^|LncPh*X\e3xMOmUsV9&GW!x/@gw^r7$8adbeSsF[~Q9)MvV/*#ocb8=J3F&c0=QA,.?xi,\`I!
::LATipN%c[mDzjW(2[7J<?+90zm6NqWFVVB3L\8#Kr-<&|LpO$vsR@{wPW^(XRH~nu6TOfSWIvCquF$DRSX#(![FX3,3zR{/BMC+bU=2\uQdB(eRq}2/}uZ/4EiQFop7[q{
::xj^zZo&u%?yifix=yTyT`I/8LEYM2G_5DTt0I&6LQA,SfOK&_X[|Q-Zv/L`TG2|Huc1atP]#&`z\{})mx3@Z]aR&8C5&T&PwE&0!<09@jlF)hj)\*gVPc+dYN66Z^%A/`S
::0v.DyD=TWNs*ehq#\9&3b9}rosk/)[&+EI#|9`D_[=?LL{spLk3M#J3}VZFa{vDpYqxZ,l\<WT?psGn8za3F^ArvWsd8\0orv]3`;5vT*)e=;ZbYZ(qETXqj|K$0DJ}-zv
::_]C&rSj^mE?l{%fZ*O!N@/vSB=)EDb!~ESQ9K(Ho#qvW]npq$/Et&(HI9C?=f/a%<wplJ0j69ZzZBP!C4@A?)l26ExgfqUfG~6/+Vn)^hb_gxiz;N+nf%>@Rf3OZn~*v4/
::L?a<CuYm(2(_XY_D7`KFrm]r(l?,J.f3\qpyOx@&lVQnLPCVnjiA2X,I#,R}l|aC~UaI[kk/rSWT>[l)Y|LO,}uSOWCB&jv!#2,Cr\p;usS;/Nf{`sSQ[)zz8N|PbV](c-
::K`X?{ZH+J!g7,n!~R`CG=pEQ6|Yc`;wmq51wa(m.$_86~X7qg`T0{Lv>a.00ZP/T_oZd\pFztZQD=xQt}PRAjIl|+>XaC7b)bEV)[@TojCe9y*T/6H_rqb5vpj!CQ5b;vF
::AmDD`4Pr3DfyY|squhU#BSiv;4lQBgR?CQ0BDI(%fJ(ibH@e_I`Hb<bzE_y)v8Oogo>mx{x6aTU$PZrl|%[|h$S#ab)k&=.hw_T3>zmYk,V78E-a(GK<I<M/$]YaaZ`!n*
::Q1+F%a5jQ;mcczMv&w.yp!qN2RX)5^}t0&I^UF!7,(i&KtB`JrRmcTlzs6FQ_0-p((Rvvs`;bqs<K%}.jw>nz3Gq&`G<dONb!D#OaTHOuRdCj1y\)Z4$*u.nIN3KlWRK.U
::2(Q`{)cYBgm]Y/w@%$YRmi90b2Z&WYv%AjOma@(f,O(FTSosJZ*Lfw@k7)(P**TDm9AQPMCqcR9!WwGhk2P2Yeej[Ra*AO8W-y-Xx6\rkEwxK5%RsA@-0BR?usNalZd/o=
::B#~UB^aJDJY8|0CUwu4,|%6+a([Wt,YFznMyI]CC4uF@Xs7-%65|W+zv!$/\hA[TntA5kfN*^_O0mSWFU5`{@]5,kf><@,T`;ck<K7I$xq8U+Y*HZxH6@_arxO$iE#}F)_
::|F5SC&NnX#kptj?/H2XnEFDwS5;kkN$|j$BM2R#.d?gDZe+07WU`a7YeS=QmjN(O=x%=>UYt[*T1RLm`,PGJA$i`ee7k#LeXA?{~WVb)`bcI1_O)4Df@o3ua5M8PLA}T+r
::yilqX<mC}v~;WDAEvWky^TT?Nk$Z^3DHxX.h{jEIy#34wR\aC^4y%btcX$a`WH`>\J&ncC&FuYPa(5?~8.iMU4(Py3Ay_k}8osQ.hulqMUXISsKzx.,Pl30k8EDH%|@w_,
::GzKKu4o!1WpM6)k^@%tE=H(yEYYfHNrB`TqfU*L@Tx[@6XWgF&|U[@0+2v0?$bsp}MYx6Y*n9eYMj2m3_-6)UI%Jp)x`a[J2Z9V`~PA,J%%*64J0A-i3Sj-WY4glDP-Zjr
::<NX1f9pRP0;jgML(|0@s}263~r`AKqqR2B7`0/9`p-Ieqr[f-|xx[8\z|K2;-Q*%gTDmab~3_$5V{8`NP=J!+9^(Yq^D5mxa,_ZaS`ORb1I\LUv{\qRT{Q^J{~?J-SRLWq
::e$wd4mwa\&CL<gNKP!@1m;Gd/Fo~zg+6An<+4]j4q.a.^dk=7uI@O@sxF2klHeTLf^%d4!WI_WbZD]Np0/WAqc=F2LH6zuL%5t-yhQeDG;f&;BGWDDLJQU}~CN#LgZEbm[
::_$em{p\zd1neJ)P^8uZu;z+GDS0B@6T7>.xR-B[7]@Cjp(t6XE4NSOY}7E2@V)Af{,)2m)+W@Vz~i[F7><ot335KH%YIDYV1b3>twO^>2%MUx|1]{Gx2JYZ*HZ%#a?q?3`
::cYPXN)R0H@W;tzkw;Jqu|#yCpx_3CjowO9fb]HhuP=BRr\2xGpF;izsVHm;KB*q/`KQ#pLKWgdwsiTclYAQ[.x_s`eYjnR(D1+I9b4WZZefV{<u(JtKoI]-E@-{s|S)xC)
::dV%m&VSkV!Z0WvMhA8(\=.q-VGes*t]WZrnsn8w{G|@f^u-?44r_WA!PNBuD2W?ATm9PqAh~hW=|&L6*Gq/&H<3@a%ru_=2zhkpIM0cDA+#9=8p{]y7eCKRx&K~i6*C*]F
::o?!}`B__z\-6]l@DsG0!j;@W_%#y^ct,FV(4)GA6@r_%4v_rmyd&vT|3(sHmG/HVV8Q9(&zd5HaQlaW$CM6i@@SZW~sb_<}VG{jta6Ea5^1k0IYx{C=LU?qC]e!i??Ea?q
::j\#tP[DcS92kdHpEJ`/$I<RC<PC\_lp]lha(b@awa7D,0q-1DBt}Z+wJRu]HA/1MJg)%vA6(zK~uogncZYB?IJ8-nU!,Av#W~-4_6z|6->N)(jBU{aQ<{4<{f&GpIq2)B$
::=)|`B_A,uE|dg*2Y,_.;i&h*8D1}QtLwk#DeXvS$6MwD++,jz=eRBt0<3mW3B_(u1p!LmAyMs(>r(#kn\yiPpXW(5g/HO68AT06yEzSOq*)F+I!LT{vAFf|c,VLaT2GIbr
::yR*TD%MhnLoyV<kR?GM?#VtS-cbT*lSX8YBq\G{SN2_2ROS}fG[N?sa!Vd9I0bPIqLn/A8FB_4OR#7B%!ATt8l!ErB4I|2%I|Et5,h#Fr)Jp9jbGw>^]($v`CLup,h15o8
::%I=JQ=B}U~Vya9yD.X0?3|t1G$\8z76_Md.o0fY(RWv}#-AV<);bLA+Ag(+S$Cws|QJ[>9\_R(C?$eR6eUSRF@{/T`3Eq.-T%+fY>2wSpkNxlF@WAB+F|eEyi<~p{{WcJv
::TsZyw0VYCO@(X4y;9<5<7j9yTi`h$/mr+]eJ*=3\L58)u\D;LmAM#%k}Z[Dr$[*z`I+{O\NFs?88vV?HJLpNBW0@z2n?6PS54f7>ZjT7`8w5NPkS$*Ic~L8ple?O%vUCx@
::aye%ox8+/!Nh5M[fUSh(K;y95dTy1{2Q.0CH(g@Xo?r!8aqFlYgMN`+(;CIkowYrD5N3Rc5$JZoe^ok2\t9yDk1bDJ|^9[>z1NmQ+@N~z9ktdUq@?/dt2\}G3FQ<vdRn8@
::nRCy3@(7GQ/-<&5O/EX5=1%_63\0pIgn-Ky4K*Ay|u`-h\\v]~^eeSUm|eq6dQL(&}{@?DTwp|a<2xXYASdHQTg2^Ff{K!I2=*<f1O];R{7)%Z~q.}~,`pWH@Q_QswCCI*
::/j}x*}HEuS6yvB-uPS,{X86NbvNZ1od}8.UoE??9,]UrR?-Q6TdDr7SkbwC54~k_^-%e$H\MFStl;#M+X|U%,b,DrR]~Ae&#Z#pGRo}rbVB>.)Mr1buP/(yoTj=Yx8E9gH
::qHd#$zPMp\ylhYORZK2NRyS!vl}C>*m*9nq@<h8+d=D/c<dK#Yr1$%rT^^O@h-E@O{hQsYg`f@*z=~3]C4)V4h}g{_1woiU88_`Yo_(79;e;a{rV@z?_-4wHN9cZ#Eg5?u
::KVRA9BNwz9o#l{W<]F={UUB0>5>M4yip~L#@.f4^1H=j,7@km@Z/V]wOP98zH-=(\Rk,/g{FtcT%?Y\dn@_!ukeI(@@/>PA?;c$5qL3;D1]H1aXr}!$Q$!0L||o}^$9?.C
::o?HqLC(JHOb-nf%G;=XYMNdz]3W#;^Z?5ILk;G%Cf-W=jwv$_+D{olw<nuMLG~/O|)F{%={ol#J8^*VOnUi+P~_V*Omq,IcK_-1A]R)SOhL6zRtGb#_mC`V-XJm*$M#L(b
::AqTr~hG}Vh\wiq(QNpL^HKdNx##S8VU`h6N#I^6JNhz?l2IJtANQi8}|vNw2`Q=S]L`-~V$A&ttj8y_aS>0HF+(@(0tGQ65!+%Z2r?ww86u_}_+AF4.=!YlMJqj!EABL7d
::6~>Q$#bz6S|HN-C<<U[+<\%GUFa*O0E~K7>2pjD=E@psMOd&$EG0n;\(Z}HSvxF4M7c)90g.;/M-8zG~]&3`P&wze`W(}fC>@6-Dw<yiO`oBZ|+b.]w^rsjC/KY3M%He;{
::ASj^tTlk}H]shyilI$6!5}K_Z5tPIwr6<!96EqGpQqU^l<57}DKXD0l*77b$sK($kOA.{{V-5%}Rh!l0BNWs{T[?`pz7G\-|GkuL5lF*fVL,&nA=;!>7+s#\|@u|w$C(yt
::SS7y/6@FRS=n>-8hs2cwB~1uswpc6ARzpK_5bz^M}08|y_WT8e.3uuxr)wa//UtF/i@21y_SSoVa&vrOX/`M^^MYmKJgAL,$dc&LAh;&y(pQ6Y-3xl{qs!67JP/j|\KH`J
::{pEM;T[mL[!B||L?ev?TeE?-%5pc8^T4|cn+K$h6mRW5A%M0j[c)\edb]Flac3v|s3[5*R=dZ%ZCuSJ;|#]1CyOOL6@|)F6bbk%9kp(Jj=Tk^Pi9o<f{EvBj57prOqJ{{?
::+lMWMH{*Si<P>s/SCv^k@~[xFz2U{MZcWa2Re>?FfQ-E^&;m[HfU3YGHr[=`O=Wo1/EYd-AK9_M(@1O(hT]QM6G)1CjzuLc;OLd>eRvC3(4g4aDd0tTY@0(Ym\d/zYFUGG
::8lLGM%hTn!A;F~I)ff,R~oHd(5{Li48Q|,I;L<@COiYz;d#NpZ~]89U%EA>TX|Q^+,wSjA81BfAea4xg,,J2o+92Jo{pa~LSS7+z=d*C@[w{&=2Th)?dwe.7R|^QI4*^z#
::!\%P+j4wAn-{B28S`K!p`|idfl=Flm#^hbo3xB2_@&GT_I-iPLch]+Iqpa9-EeCfO[_p+8VJ7.2P{N.\xOD}f1r^|,c&`+z[e-L,V4*$)#L4#s09mma1=j~Gh~Lo^8>r|Z
::YMFRO+%jq1nv9k)#\61jO%FO]Ozwt,Rk8Ew?@oYK]@locg68^-eoeI$$#Y]KLzh0UQN^%8OWjcW+p@Y1Yh](Zf7zw^!4$*Ogc01,Qn7zhnvHU/lnIWKnNZ$MJBh@y;)|}p
::)x2v##*TH.NLtB$|Gi3GJ^en~@={;$mp!(<aU(4WQ9FWJW][`0tE)M)uphCGL3\ot0B`KLmH~wmbKkU~E[a,z_fS4D<%Z\^p<1nEAo!y`{U[977KyZ\6OJBYuJ`zC/*ZQN
::]g!,\!W35@&2gp%ouClvvh=F&>#i-Z`Br{*{xthf^tQyRM#M[RK5wnf\p49fi)XtpVm5e.n7+;x}sOkUnurWmLt^#VV->x88|f6gGh=bJ\itKF@<AExN5yaM}tPo[?8r|6
::-5X,p/=eQ7f#,k)tK$stQl\/=xVn}3*LcVbY;H/}]Np@1EMOSwE/>sK,r*%.JlR$!>)FF{IZ)V/$ylhu\<1[ufLY*Cd3Dc,~rVp$,Gw<)L_RPa}vr+X(}|_YHXB`[\82iG
::BWP1n&}ZbLwzv9]b+[8R.8Z1f[DxlpS~,Pk/%8WHG?w*z()-a5GMqm;_f4b+6[>nQy$2qA&$v}ySN=IR@o7&1v9($])Dz&O|^Ae9A?RzC#`ghpDVw\]RSSI3b20L)q.cg=
::#gC{|[n[=0~itKdI`%Qpee/PfH@_cUDf0-YMlD0h7q437?[+L-~/p^5yx-gg{A2/hobP4zS={fHup2>tjQolcmy?&+cO+qTK*CEpiH9~_|ogVHb9=bgdQdzHvgFmjW{X)z
::/owatfXgV4AmE)efV_XJ*yR5DctXc&DT]ySXv#.oamMUKSSuyS.1|1Z/6bq{pvT,-e@s}?Ju+jRLWi`z8q&B#Br]>;5Nt>glfR7B}=t0VM\<kb[BG)Xk<.CZmqh*Q&?HmD
::v$H\vv{sG1-#Pg^C#z7qCCka+*Q&tlr&5lkQL3hWW*|rSz4a\zbN=Y3F)cn{sT4PdUm+SXe8%aXg\5s7_7&[-8/<[m#q=`_!oE=UDeKXg@T,Z97BSSd9hdeN1#7ty,O22/
::CoPU%=.qhx\2@rWF$a;IRx^~uw[s{[b#4+kT^|?WBc|;@,FT!z1fhul]XStCbxMb-jk,Sf;WjnlysUK@>\dn}l7b|CnC$IG}/majM&|;4pAY\U!44)!dJ&c\>\JHV[OPbx
::4QKrVL.L/)b<]Xyp@5-&sGp`CH^}WY$[EhNgT_{(ac<I$%ZCu$`AVX($*;H@!m<ZQ&84n($f#hBf=cF^5*^nI-Sl#%uIzUuE4z5O_;/[;gpC-w/n<M=WUy;o-f/o68VKN{
::0SLFSBK^uQA!z9CA2T&qAo{Oz(1hI^Ur|jK`s%4*iN?di@N[V87n2=Brk/u!Dluh6N~}Ce`,V(Z2Ru!4IA31~/rsB;>l5tG.aX4ZC\<Zfjr2/)K1$GP(rB/d[vwa>->y$9
::3)d3A^x`?tSPR=/bxI,5voSCo?5I44pi-w$CBx;z2MD7<i~)bAilQq+2/)t,d!?jSk\(_i~@8zqbq|`rFlz[z^7_+#nwYDYZqxN4*<I$=o>5K1vQ-ut_S*NLV]mf1G^0VP
::jWC_5[4n.Sm6n&jGG$y^dWbOO~<G/d_pp-|k/[_(AtgceCXG(B!x})oQ10R?7D+H~BrFCTZ%`cOGN[CFmbztz_(Q%&dh{_4CBD8z=scl}6^9Bd6I$3S?Q-SED43GVI#d<C
::KKwYVxQ3`8J=GEQ~\Xjx+\R}=M,w{jGJ_EmtE<jm\V_+A&)SWGI5;?<|FT1>f&=H2!g)cpt$Ufu*)S!`a{|Q.{lrb]RhSj@vm%IJ]762zl}WwVN-1XHQJi~)V+<2q#ERFz
::-8iM.2&~LhRg/^_p3Yw),7.&)^6N%RfrvJlCvJNFrbYv[kJXjde-KGf4-1jVNJopP/r[d!=^ZiO,}ACzgV/J]gE4n;K3^`I`ZOJ5G#5mHFKRufRo\|_TngJ(Tz@7sv=YiH
::d%dt]bzYfK`)hjhVqUC\ygvV$,6@fP0pQSAJ)<|&x+i?mHg-\+LI\k%C5I#R^,;VpPGs<7~zG78W+kV@Hq~dxy4v_ZAA<|x3Bbxs{yB%u9Br-{rQ(S|^M%N9zJ8gv]p_J=
::rg]a)pd5^2CmR!LYRiBzIDWNEgD[!K1lRBmYysdzT<pF|^WVFs]$IN^.%Py*srlJ;S}Z*#a_RF3^o5GaU(2XuL$]z@2WFK3gcVC2[-f@;\zs{a-ZZnIwX830AJ~O^@*q.<
::m)PDrSal}lCbrLsy!2#/,m3C6\\CxOeTiEbJ0Ba^Q0f%O+FB1<,cwnOA]W3yGxyr(;M,urwemYgAY5\qQ`}/WpM!WonR3Z([K.xi9dFJSI(A/h_41_vI/=Q(jYAr}sT`of
::v;w?.^9nUJ=LotOqUxS#I<1N.baDE0#HJA-<$6UYpfCosUa<n,1@k+kxm3{BxSi}EC;Q+v`nR(IyybgB>R_3,o.D*s?XloQZbXCD8mWUVg)of77h;3?@s<VO8@,iOdiaF/
::N4mb^.sWiq+cjWm^YE5/hB3,+(l7aO6>nl-Vfs+QNzl-mHT,P)0,La.(S&pLECW9>{Is;e-A3$_?NWi]@`*=sS;K3Z=l_6UO4\IrbBB=t!W2~93Kt~<WqX$V1w%51%G,Kf
::@vtnnZ(Fu2Xj[%kzFI2kUDAgwFH2)\GAo)JTvXg{r!^]=]M(j.b}5f^[cHPSc5\,KGuvGO?4zZKM*JfBs.1}T-&4J_z%zKvfIWc!xiEq.`z@6sDqZ)dpworTB884UEV-I>
::\9<f/,>FCtM!jT|,YTN}U<|#b,o3bp8=vb!N)ChfbM^<bpg1O1^HG*,TpV.WMyzgXsK1-k(%oe0hhxmTVk!$yf9h-k(jbge9m^YBjT?S^E,PW,O4Ool-BYsD/1_]%{ory`
::5{%%W@uEIAj@A;t&(Rx+6FTy|F~Hg1AImV]];5YR8pLE5#5O$0T5=3M3?zR<s4MoaU|&vC\P\!8T]?`#|XBV1m%vJ%NayP+-!}LXD(]%.E?SR\Q[{kg-mQ60/}x7BW3g*3
::TdU=X9#J^m`1(buzN-SNJIIr&ij!=g#a[kcpq_wz=MF7,s7@C`^g-|U,V!7ww7xDSgcU{FC+b;E31Fef7S`qI,cA`DYGT%F#E&ipzTy-y1~%+UNdr;/-0CU0S/77~%zzpR
::`&\}cgt_y%Iw1H.C=3DwR^\|Xo!tXL(]MOvbe%.&U0GfXR3o,!|+$S*2+NiTd*oHbX^dQEJ,4{YQK#aM@fq&sBIP}x84v8kXO.LzP9J<Zv6tXJ@j&(978`k*25-ym5$X9a
::*VEW..}vH^KS[GB$.&aiW?|5To&4WNHzo`3+Bp},WXum1r{zf]-#cR}fR?])vQFYH^ksNIz?W2|~[/c8Z##y`LTLPULBz)[NI3[MBVm~F3X12wZ&+gBZQ4tVqee;CL5ob/
::09C53)uFoi+I>;Cwfqb/,7u-O%6`Sv}A_VhyL2`iEL!CO%Ky5lZZRcIH!`%~62tU*UIk>ML|R~<Qi`LTakv;ph[fVRQN&14+Gmv1t{*S%FJa#j!zII<&}AVn-UJ#&t{^C_
::aX8*gz7/x+FTFZ(#6lB#EupU)I}`6_-I@$G1C325wTc5G(`4%CN#o)D~LG,_N~\.P,(-w.!hV%3Jg!q,tL$IU|J3_G{vhME]~\Y3j4nS#>;YEz@U~]gVBB}VM|\9h}KLzO
::o,_M*M>%lY.X[D1\~+{9g->@F3d5>o+d%0[&P\&Xgye(lZNpLPC@z*=$sb?iFW*Z;D@N/UEps_t~#H^4AZ<-;PT^]4EcDRqAD2=OaDo}\NoA`E%h{,U$>D)M9l7u^l3@)g
::[r5nFJ9^_/2O9!?1StoJ|-%G_6xnX\jtALW*#flurvmTsiSm3v&IAi]1</reHGnsfTDX-Qa2*HI%/ND0#I6R{gsgdwXYkE^0_F)*x7I6K-%6ENw&-NYke|Y9\?!4tsQv&)
::^BP),pgUI!Le;Q;LD!#_L0-~p|&diL02-[cWbag#jlJ/lBQ95P;@2/pSLOCH,CU*fz3z&QY1|dB]o0~9zT>.z%fOcupkVS,1vC9)z!Qm@rNR)DBa[4AQql^8@DsVg/N|4N
::TI\vb?o-IHcSnw\E@kmRvs[#<dVm|hUq%z%ArIwsv+./UiLHQVyRd+VE|3?Ec)45{FRxi5KM>t_gbF=;9}I*qgJ7!&pCCMX0wq[Qcv^rdbr8v5Sd~;A7m)ga%(mCqxt\f8
::;Er*FJaI`huLEgSwUj3H[yQd#tpLB@f{>[s<F(>0&`dp<xE424,PV?QZQo(m()!M}+TFsOu@>&eB)#K#11tRwLE!2NSjmAOo.eq!4a5^%V}!CcvyxA&rOHI&LjW-KD.MMB
::\35D)SY{?<XKW$FQx%A&AXMHrl5%zCff{RK|WcYFF>#.n-3R-1_G+YH3^vS#-|]XCV,A~azuQ,gEKD*qMV7RcdKMh\<?F>j9|<UM!x#F4%R7fZ&8sm;LH@a`d/AB\75j`6
::FbgBSmB/qGZ[#Y1#DmNkP)?u]?~u8D%jfZBJhxd(`!_m2~~RzS@7kX#_9-D,[J~QWG9.)@Qz5z~IADQG]|c0`/r>L>2jK2;%WFuYwY/<[7Q%oS68=r%O>++7}jP@C*oHy_
::2e-.95lR%zCFE7o{Vw|Huh.TOa>r@{Y;,yLNcMq}o+K)TLA<2`J`V?I3m.iPe?0BK6vp~-%sU4*dr+sTU}iBot!unKNJNDvw#z]IeyqI&okgHoJ?kxaL/&m<<8c%*FImRO
::$E9Fruwl|j`EB15g*o$]}7z*&MP!0\Rnd$^q$+f}qT+}o5-QF0<()UT\x_K8_~\QL0c,+J;DE3,U{4fQoqm[i|X(yn3Yqs0geV;qE$(R`Xn`E%H{r`$T.FYtHREvgIUdKG
::KIZWnGkjhS7}!ie5eTrhtt*1qGl$@}VdN`Ev[U]n&i!fYZWDgtVMx-H/5FWV<#?pNROr?wH\6%aX9TO~K+ibWtlbZ-r;I8W@hgSi-.o*RuwYyjy\y^\$Q\Z&9QZ(A0A=@q
::6b![}^<1>]P}X|jNL/Q5zEJO**=MG\i&*8$NIT#L$g\53P-h%BhaGDz21Y~mhcXg5?&gnKFF#M@[T?ia2nLV}\sMNy.$B=PSW2eK`+T@D!)ub]DEYu#IX8aa*zO._aXmfg
::AVU8]U9U??YSe))(B/nD#zFrYs4u,,9(7FU&+zX2SND1Qq,FH[u&Z~nWlG,oc7=e$c9sq{,Mg\A(BWE^$F}yyfsI@g\BeWMZ^>2\I^~gJ\mW3\rHcdk`,Hv@7\)Q9Qr$=l
::3)%Mj_W0VK}Wbj?MZTm)(0Wz_vXB9+P;q)T}^Tc/K}la]iuwZ/b7)$}T8YNmGGjbXG,^?0x*tBB]2b]Dcw%2n/-SREbY*}ddvs4+?l%+j;CQt>*O(tkN&R)]lq5UfnB?r;
::O*G8;hF0|9mu`]=KvtGZ*F81a2T&ve&$lfy`J)~L>%V^y;PPM_R3@k2G$~WGm`%o&?p%wo6zpjt,G|F_tLn,xz)+qGPFaPMp{P+CHAhp.QNxE8n>HcO?gFrmiqgoIu&?.!
::Ad_Jd+2zVQ.7Bwy1>3k<u!4f\e?V.SEJJobQyJntRk7X&/sye@pWg6cZ([P62isDJ&J=PUcofN!VG41w<t2uh%Z(|8pzQ~bvnO3BwIZ!=P_CLzTWfpwZw6,EQw*$W@,z!E
::y<jK6_=#0?kXir8sVorK4&f;}Z4+,DO%3#35bRPD/|vI5cBMBTn.O7V5A}&4X65?oM*370mJh+*jwqWU3^0D7}V;oZ6w^xQlmL/L_Z)\)sQ2nGKA5F{=yPCq/qd,Z*<R5[
::J4Tr|01|,NWB0&!r20.WsBtP91#\Tw[br4Aigkus4IU&?uAAhfFNNmE{G;i{VgeX%h2ViwA2`u2Xy`)4,bt7g3CO@$2WRdmP^fu!$Jgj4INMG-};qKvli$hh3XRu;hgrNG
::qD#}E{u|bSh^R|PCFXJr8MB!e_yA?.[9yLSOw0;>Yi5Dv)_^nT<2czGWb0Jw\DUC<EgR+.3,>e&v9$o&Oz0n)J;H)GSdaPB<&/dEOW7NZZ-[z+$OvjITyTj0|ak\[(UJ`2
::Khe/ee!uNAo3RQK.E[*1dmkqhM|/7qa)D0B$i7BZ(X)THYdcO#\e\,/}@L,H[X@vlvBwcT$CW]rC\I>/#MA+|Ff`?mf@(xf&n@,p?fS{yAY#UjynKP]E~fL/LwON5^vGlr
::iS56yL}wQ+kl]&e7Sf*+wVO/,EuwB(3-h~<n`a~zs_)3/Rhp2wTqG?!c\-SQ$an*Xmy}Ce4z8/cr#T;{jzC$\LOF.PI,omRko.iv<~UH(G8G%\UY#?t(sh(I3_aRShI*Ag
::87QtJpr4FcoZ;%vF!KdtRb&cU\u}vTA&E~nst&o(n2~z_A>M)23lp?.k^t}E@,%d$Iv=0c<2B~T3#99B]Ddv[Vj\t-Q@e-ghx0cJq1TXt5[4)?BaK3%6gIFQ(QvU(x!,m^
::Xy`#z/>qI*&]lwPxI=$h=,oq0}bm();Hs<`4lG)f4u/%576]SP*>qu#uGD]dX]I[+,@2edv]y}!?F+xR5Y`/9/eq,9sLqq{0W.GjMBWq{7B]eG@FF#M-6X-_Oc3/K%HZ|%
::`\lOr]y2z&9SwsqU8|>S[C*CA1~El<C4-f5GtIvd5r7]lmfkOE2-mdSX/uY%RU*ZqL|eFoeK{apE|0Ns}7*cVG01bpTWbu{rmVq&+\3r\#i5RRAq3IQ)pD}*HoETCd/ejA
::)}/}]R5=_Nt`M|.~0u6GA?V/luP~&BsOJitEwx8Y.daP4BfpH37hQy?cK)no%cqyd?2g0=>CsM/y>IK3{Ls};NZzFb;vMXxW=B)8=-hAoZn/)G94yqB58dzoVkwxbN#>*1
::Cy.SzuB_k<Eg)U&Kv&_Zf|<ziY~T0\}i$|2OEb@J)A7i5nkN_8G8?o\JAAzNOA!&SZRu7Y{b{|[9HE(YfTKCCPMP7RtEJFB3u+[8&buEgN(vn^?wKsBD2?^SZftKsetD*^
::}KFA2{g+xyiK^}ly-@(`OCdQy?SM}[pH/[bB-o<oiHxIar?rkAgrB{jHquF8C`Y)xGAHuV])eEb[C$x@Z-M95/i}t_f<7<[h6G-B\L1aSl0(dQ03Rn,GShYL{GtbN<WWHi
::TKe-HN!bZ)s4!p@rRajIIh`0%j4n`v[*hO4Ku{b]CHz+8qlr)nZZduQdb*zhVLKhcwJy9u?Yb{>`>/m!~]1zLzumUM^?qcW;{\bB<AQ(!FpCCvC&V_+!rU~y}dxTeM3E1?
::U_rqwFZR*8Hk)<]T#1TainGEKmo<OT2AHijVdb*5?_9dNYvCJ&iFrNEHV~DdwQ1N=BvYrW^SPUoP47G7p/ZW)On}sm=NLl0IJH7K82*WLZzvfkHrq#3@os7Q7fiiLTM`}7
::LS9<U67d})DEwb*3GTls~s!NN@ydzTEXGG$[gM/NbR7#|cd=(Fh)Y1t]m6/K{$zW%bI^(n=0X}#r,=_d*{nA|cDk5lj<WZYHD3hZouan4i_/gSEY+)aCgxp^d%K)^l2LBM
::Xl<bGe0gIWzwjXsk23m9?MzxP+R1]?~}(@be|e4u/_tF+Y2l!sl`ZQY]$/i5ti)W2in_F*#rNN~M|/5a}M@p{_N;!iA6g[~z^X^bV/GilN^I.bFoN!/@&N5(I[!dPWLw/]
::A?qHK}V1$\GAX4_e#Nd&Acg}V%g%$PpD)\sZ+~aVt[A)jsBU.x)rcA-75STA5|}.T<oo7Xnv.1[]PtF._qMfH*gUNz5,ty5*q~/IE_xBVaM(/bw*]i4k+8bB,d%.!8iN6@
::3s>7KoL_rYapuzcHTHpsio9&abGC4}0~h`P5Dxf`}zVlH+M#{=xTmlGf]2%l>)>sw?PRPv/TrhnnfyTo=p2]JVT@ng@UhvQ]VH@jJ_-mU0lS?#T;gcA+c]G`[Xc]9WhnH&
::X#mnezO4/T=7KyyNlnQ~^|vui]VNzt_8}lcI(Mk3XXhx]j_%MD;CJ\WX%kV^PXX+g+zH_&#,zj~i^7^CS3B(ul&S|Mq5f[J!+U&*XX^UMd-b%wjB+GJUX=x?u-7-HJeE\A
::.!@aGRbq@t#t,o[r(@SKGT/>/f,U`x1G\60x*uMx!oP(Z(B<bRpQ~7NuA/gHdeOMzOI&|ze=x%I|w[$hhERCpsY5&@b]`s3xzQOdxbr4X0fX>Rlv~4c8\1KZVI_VRs/@tK
::i%WP0LJz07_H]Si1KX#2_Mk;mkPJw\7^.SW0a{u3~YoT8X^&MEacmPc+?PuksS8#2ZKxE2]fQy!;G==D!g1Mvv;`q`yTI4iqninn-iFx7KPlu7y,ph;Sq*P8MFrAk2c[v7
::HXC+/Yi9p3/_VR[x8XLtzjN/}0CF53z-Uq8m]=IL8g3<aDF~g1#M.Q^49E7+a*p|i,`x_CNcX)V#8oSm=NJ=koy(%HccmNzWK%%=t9,1|VMjBAs?DBl4[tEu6gxic(fmO]
::vdGy)y4?JXAIk<o[|`8%}D#w+5kKC/M|*|>nv5f}U09!d5}r)IhcO4@+R09SPNN7s]al.~XD{@Db/?[R+|4zo;08_v9]IMS`&O3|4IB4v.PcHlWYr^a~cpA#zkRXh?cE,g
::tH;1(qoc]wvLrtf};^TSRqhRHXSZD-4d%4)BLMB?<4,.+YQ,iYbAW%09/P+DBZ6eHH*{YuR]$L6j!r0!;<P@0H0m3sq(|T8|~POv[pkX]G>sX-@P,d[d`!+=ww$S_P);$v
::LPd<WZq/~I.fXnl2n!%X^_D&![oJCmj@*,5DoeXl10T(OmV&Zbj-I`*UEk=G.&@XvsYj@*?ZF<tdq`!(e+,=ot>gHL>3iDo?cSfZ)zGkm4W7CR;k3w`xPJxO0#6|zxz7bv
::nJv^[66h$x)/)}_K.+r@97f*}m;[-)<%]2k\Mve.s5mEtTS?d`ckUQf5papqZtYOwVdk.1vs*C!qZ~h9{<iX1lgMRNXcurs2(`bDkg~Ei&cof,gRtW0%gD}-h&0=q$w|vg
::E<SBOoapMWFU}OsznT>ZWbG[K{p4<>B@s6obC7~[&(S]5DekxM^,ud/S8|.xPX?VS+Na?fP>80\c<&K^NL?h{$&}nnBOG5*}ha3`<;/iD#p>4[$lZ<$ym!&4#2af_ZCCF!
::_VM(h|Lw7NHMFn#i*GJ+/}W[mdO{U=6V4+%!e/z<#cUR\VO33W6;6)W!C{r7q|7?S<)`meo#4l+U{/4+T0xXXEDIvM/8<mQv<Bu~waEK}WAoFIas%_<fIIQM}?)V[UEI9E
::#a||\qmI0;B+m7n,0M<C~<`_cic<NEePa$\-U?;oLCxE1lCnx#*qs4b(\0Gpg@P})BIyjB=pNh^+qqk#j.Teb>Hf%M(*sM.il2,JH1+z.p6qdgMp~W1;<=x<J5?]/ln\l3
::?B?^I@fNB/+{w|1TWZ2Vcf}q=U>u^&8(BI>]^%wZ<l*0f7IW^cEp)<3ocT5Nyr#aHjTbw-9O+Odr^7?mZ1@g2jB2YlmY%5+E2Mzl}cL]ZbD`^__BQoK~@%}CbmZ*Ty04?k
::]n(fsS8^kBlpim8K8_A<!#uypMF8=-7!iS&(C2Rw/dq3Ym|K#(usgG8`ns!YsA<h#|uiGT5U}YCZzt\ei4B-Pobh{\mR5X>O271t=#fk,wBx]J(7o,V|gI~s#\S{B~4Tb>
::~}-!b69p|e55Y<H<<Ld}@zYc![)B;>7\zvRIx_@%8CHjyI7tv!CzkvuD&I6M3O6Beqk;a?+P}#7T480faD#O/_eb@|[?w9N#_;Yys\*sgSdU&JT2zUxn\|Qj|<k%NsCcn\
::xERl*AQoih]Ee#I(V)bZ-a<T~ySC|aB#07Y@;5EGQI0S<pE@E.&bdIKaus7L.jw{s&V56YX1Ud5#..C8C/9eP?r-SJJ>V|F_TDOrM_j<=KDSH!6Ixh{LXg-|vKr4S|v*,(
::a+FQ]OzPpFG_se\m~xaB2&gV,Qq2K+_qsdGLZ3tK/Z#0x&=cf`@0hXG5X$JmG*!W3aF.x)QRe/`1sMHXdcfeu,p!b\M`i29]/5wzRp(}_Xiw$K!o}cV`T3;}Fd94hk9ZeA
::t?0vyu)T\xsH3aofd$C`%U27@9vJvi^ubCbz_`7JKp3L2wzhDZwrky5lbY?LOw*$qV_]PkAjvecu2Qie#B[lP0@o<,i`-ifB6;a]!x+J349j[(ca@%!8%h{A34CQJnkD+b
::^mKSp26`Iu,{4&xSsEGiv6`b-NG}DRS0`C-IcATNKLwH?M1W!|z_AYvoVuaC#D[\;SF&+0xk+N_N+TaJBu{oL=yF7%BKd-OsvJB2,@BXl#$<[Y!Hn~cli0cQk?\c2W=W>k
::=pOAB[q=$TGjiROt}IW8wBfjqPE;$}i;|\yZ|O~_E@*m*sZ,3s$rDiD86#XC.MG?COSC0%!5K8x#hbeK8m}?d2D$B&Cuf%+Z-8oxt8_pt}`kCeM@LL4ETWBLF]<rsAl)Ei
::{>{rrKL[{?YY=;ce]cd,5[zOB)8rjrY6m[%%~Ls%RN?WeNP4D\9*Twi0w.nfvAP&Kk1)h^|@K/zCJ.~xn}V#[*i#.!rc4arIL}6Fo5MVs\})Tz.XN|y?tQo~XjZvytTLqJ
::`MS%C]1GRBN,!=5J^;JnlB3L>hi]]F&3\MW<~`puGimQI3INM+h|`Gu+?84r;Ag42HNgC}3Zi#A$^.@AEIElrY;9oR)wl[D]cDq]5I=FgI`0r;s5EGf(Fb#.qeO/_S1aVY
::pyP*E_7r5KbaJFN$&qF7\%I^,*4}uGyxs~by#m?LS0jOWmK7~{`~2k/E,jEFCB`|dZ_K[pb-l6P/bi03?y9(OR[6e[lc/I!w>g_w$+*j@EZ%CoJC^QL|NwP@6^1{/2~njn
::#E!2O=u]I^]Z[`NyYoh33Kjlj{LxPM1jf55D{$\KJ!uZ^G4?\wIr%vWmvzK__mKXWsg9L=[vC&ntYmcR`A.cg5d=AyLwMP+MIBGTt}X!k5>Us*8\&c`@OE.{!FOKxObft9
::Guo&1FF4(Y>=|UF3PTX{yOC,{p!YWfl7%p2iV=fWDqz*aOvJ3AO^OK,W*=q3Y5h8wUuMKJte[;foT-5qa(8fPvD=wUO\I{0)OD.\+/=8Epi}K!n2/^he&&z5JQW5@R8U8d
::T/vaVSg$!uw(lE/ud3w#K2w)+.KscK<xSXv$l_}QF^?x\4.wV)g%+]s|j@yo,mE(]u9]UEL=))U0%wvg&73W-X4dPk,x(mU#!zf*NXZi*~ewKvTYxEA(qEE^5|+TI75ils
::B+u$m*%{2|#/LR79e)R]d3HP}7Q,/`+(@tJ^Nq[QICmx5RcLpfp(g`j;FjTysH6xi)c>\3skxTq$b!0[Z~.A7gotqFN6[??=Z$/aP$<*(jlsz<Q3rS+^/o5Q[!F8F.z4%/
::POG*w#wT0=ffqd9hJWfR=Y+OE</`\b/ZDF*<s8u+<gvHFe7!aKVa#c.pB2Q1L=)C~nWEQ;l2rAH=7m<Qd=(K\OvjB&;HBu7*Ii2_a$l#K1lN_YWsm(,hXg4BStT(UqswG@
::X@AP{^joIW]gw=#2#F/g2LfN6Q(i5R>fzM.OzADu\}@T69Tl5BQA<9r5[0UPbUT`o,ZuP*(>(OqLj6*vM*)X4ZyH<EXOgcWaUit\/*RsLy[FGqDD3?Q~h~#uRDjd>pO`fN
::3=Q%eI4^/3hf&W-zQl{||Wm{/(ww+vtuzPI6Kd~_pKF)K/[+aTV!IuRE%M0p*gE+4<~l~L|@Z97{&f~%rp^Q@7zBcXbQg}^([B^s3|M2)~vZDb6vz^JyY|[F@iC~ScK+Aa
::5}ZkIxyAhQX5-^\%V)7e~2Awa/`Ds;peiHPw.[.1dfwb~f/F~p)gdlV5DG1*ZU-^%6lu-u|Gl/5{C(RQ_Jbu$Jz+mRr&Q7`wgp$l4aF`j[Vsp#OJMB2$<~Vyd*jze*cmS0
::F%5\DZR{.CK_v6p\|]8>l*PG^c+A<R7e8#KQML4i>x19P~4[_=.l(AfuQ+#V=2aY80$Vf4DRt}QN(zZ9ZpL31{(uA`~Yi)Vh@t{+tM_@y^V?#l@iAwq2uH^v&V(<LR2_N/
::tzk<]q$<ThY{HV.h<.-wpBw2a[HmKW>ULh?vkgVqH.\pzyLCY2m{.a/xsO6W}iA{f53*]vu49*&,iGBlX3AG=O6o5xzoR[4%7+*%&AHSaPG!C8<l]\M{QS&K^jo>.%NjY=
::Phr)bWbQCt6H={dIZtgHMq0,}OK&Od]%S!`R/)YHU(28{7QVt^w[7yu$^1|\0m$-S$~JV8H#w*gdo@_LwrSpDw4`esd)^xqEJ<ajkh\58;~acJ)WmxcX<NRk}kidz<z[W^
::++qB<]4TC]b@ip4/)P?d>/FyG)!U`#lF9q5+X/{S,Fn+K2E}*7VM-7!M))GR@|{IHL8,(PC~2PzO~?mljm=KGjM`Lr]y]Q?uEY4-ZxX#+@qc~Py)B[=y3<5[Bp$d|^~uhX
::_[*j{ZNAlpn`!d32\rc^KNcfN0~ofw6+&?.71g0xgz\@VZ)eD90K_;l$A|fgdKv4n4YBL;PaiL}+27L-oq!GX6MK<3EYsBe|%T<MO_<k9yKj-g;_m}!7)&ig}~xoIu[VrN
::`o_/.8(Q$p/78\)DiMbC1n)]+;.Od-n;zYh&A><G^/H/kdcHq/_8KM84S8n<$={;tD@34=*OaG&-#|2Vor9TIi1~l,!{;Y|kC,9hC\t-_R,BLtHAi/JgIwJtJeZZz)IO/8
::?CElUAvQp~pFE/hV=;(V~U9qE@u^kDGX^F]2fpC(3,3%Pq]FLl2N>fK|q_r)oru%!qP(<d6FaJ_}b{70WOw=OGgl&T`lnBO)+XsR<bVRQNDj!~8<c!5zeve@rZ`()s<{*s
::^,I.TB3?TM2H(#VFLIl;AvgG/0Z`rZOaf6)`DH`4qqVLA(cyn*5\{-s<B80)7mI~7!%KV_fl@HC})(6c_tOCthK67~m=-H!zQ[[GYAu}*UjZ|(>5!m&`#Gy7bNrh;OfZBR
::eMza;*PYpji@FC|x`gULakf,SuNJ}a8a>J3HxlOo]jJ~`R$@)v}V/G`<PS4zXz*r6/Cr{bz`6_*kBPXNeaN2x{rmlmKV,yw#[[kNMNS=g;Ab4}PUAu5q_rcLa#.x+[93P^
::]\}M<tP&940].VFhaJZW*sj2CB!E!kT7,_K]uP\$|zUsUeuv.$p_o5`-h8>kK#H_c<6bA_ROY.kYykWDpjgbgKFqIn~G.WNmZAMl[r>vTWt\nxT%5,ZT!rWO4ZCQRxEukh
::>(Q4Q{m{$/z~qxqrj0`vCls[L~-im8s766VHN?~26adpsN}KuVls3S9DR4#R+Wc3F4eIIt_$(15,(=%5*-<wjFpnX~!=kBj2tYSjCvyxwA?#Do/j,bo)Hs{N}P{-ru[5@,
::FnvEA!ejWa2o9^81Wk*^/BA7^l8}hA0O6qm;v5_0mC`(L@)+!bLc86dKu!?RHQU)k6F5y1k$e{6*nyYxS{,{Mf3zKZp_=wQb^c8{K\omIRM%kn5`3j,pZScqrY7?R;x,\$
::kbRt*Y(60Z6\&a%2O\/a2*ef#{O;or4#l&/p_lZQZ3uCo)H%/F^rq|Roe[c{`5B{/&<YB|g];yTT)L&2v/RJ@IncxZyFG6?T,4xs!sv5{|PPvR,UpD@INbr2c&`dx-R8p*
::*}pPC\76ZN/~@JY*l.CpQ7j\LOMCx6yX;biI?&kj_&1!W1db;qr;3z!ZVelipNe4lw|b`]NBB>Vj`%wVWai41?)5p!#B,T,z0L]u={~#3@&AR{q#]w@~G?\]VBG\G[6BDG
::z%$oR;ievEpZ;FmX%v23]1jH%(?}[pY{BWjrv\]~wh|U[&v<Ry*;9I5?!baC-rx&u4E1uT.Y|MHgNEAQ`m!Q%K=2~];[4}\[;+g[FM{wnbQlV<7ri-1Lsd]EIYUv_#?p|)
::aK*Vu9Y>U(aK]!RJ%$/.1Mv+>pqH$u.?~cp(7QAaH{^qnop)skh$WEEhMJLEch?^bC.T)OEhCPD3J,)NIa^?[VsY265buu18*5i3*JvzkQiA&{]B2Gi?Y8>|axLM$EjcWV
::ShA=f4XE`IeDn`_-fI%w.,L+\5c\8,B?mv-}ZrGN=zmn?w2F{-#J=,`XW&k+|mX1?beQJ*@!RlhN46PwTef7zIJTjw$WQmh?##w5J{Qa6GXEf$BRAE,)D<%~<wLEm,3Wl4
::yvYZ[*>MAbVXDO~~M}g;awXu1)G#Oz!A$lz2^W9ripVy?\b_(lsLiC)V+M\q;!p@qxX3KHKl<D3.2@F&H$/Z]Miv,r?q26.B[,Zu!gCG1}Q@y`BfnbVy^QQj`d}.^Daw|e
::V+m3(Gwg2Ug|H01;x*!|0|Op]uC]SH=xF0[P=PYo~wz3ZKMi[.!X`J8VLDy4!pwd}]d5cqG+=(=x>iq5t`vZhgC8+35w0*aurZ3pTXY!&xnYvw_90G_s^}Z)G-[u95vHwD
::qbqMb,kE!wt,5j<umP0?>C>=~w%OxHEr]|e|9mK#~+o%uz@/Zjhw3C>?9EfNk}Hl99W$|aOH~)$^a{A=Vq[F;aU~NNKR<%q(9Vp\0tXX03T/eyc{L0(i<uE-Z]Ymlc$W#F
::A*H,,P?XKC]{Z0=#0]|rXa!Cn6fI$)xDW6C=s+qhK52NvvCLzWBb66g`vC5)*sY(5ghBem,sTh^-G0M~o*Dpnl&{Dz4dbTCZ<c@d\gfQinDmO>|yK6Q%V6NMkxy`A3DB\V
::EcT_]mc#^1DlUg|Kq&B^x<$*!0T!zo,m2;B<GlsT\\+\}qG$T3`gPd@j/?m>lNk$HN>#B63+M^D{V#I>MRUy?bRXK+~8Y9wEzS4x53a$Y\|We+J@4sav/1\7+uSD|7DbwF
::s2a,?R)vH2Bzu~17Nk#5Ulhbo=yNSsx2zVpE?z]vw?v}qp9npAD<#SBHfTc4CwfV;e3+\2gkG!;!#XN9FaJ3mMQ0LgQWaz@9Dt}GI/2pu?U^*SC^Y/1JWTe#3lsWcv$$bs
::U6ywR;rpl*=bKAB>z2/isdv68cp+u3j7qLp]<)Xn,a*!Xo>&Bsz<;J#AVg}it;|)nrIWp?*l`w~)HR3JoJwZXI+X0vQYg,w1v[n\`DiPYE6-8zf>GVD&EyD!Bw\&cH9|Rp
::/ioQ32TY%e713Hl*Cjt~SiB^]X,/|;=KcJ2e(c>Wt,e/LSySy=5&.=2UTABheV-;OW~H>j23qsi5E5O2-G]|z(MlP2B[K1~@FxyxVSZM#?KKZ^C5BRgGtsydp+(AvFBY[<
::0Lx|+D|<uhd@QHLqj#DRG<p%=.Q%CbjYcx^ILxwhA*(cBFZ4]?c8TB.)%C0*!$#Q7_]]OdQ1AOz/RhW!ZQVR=9sooQ0PH0m(~9pmGGn6c^io4_!?AezX+ycJr{c%*FiyIE
::aBjqk*^Jp,sZb}Xa-O3#,Ya#IN<Ii#^_k?v_Sh;5.anONFI-d/Z]9+T|(fc.kbFo4})}~C3/=,1B]WJc<y\}dH~TNTrJC&WW[3xu>CDbk9M?H?LYd{8\SwrC=~gBt\N/A=
::.d;G^=I<8K~*}qR_O]|^?<.^iR#!%V3rdP!K<cBv)GB7UA[x5#,_m)M_YA-eEMHVH3=eD0)fhva^>+/u6Rcxd22HW$o`dWV_arlg<E90qrGg&Lb+2{-{IlVa0=cv1q34``
::OQD|q*B7~E?fpc`pG~6Qx(P4Ybsv<7e2-n)|nRCD?2eO]7sn\^/0e)TYt9yjF/Pg.=%U=ZPyaARiV?@c3md-=Q1+`TXSA/XK2IYG{~S4)EQ>!W)GS?2+`1Y*A;ZyEX5`rQ
::[Dh[R5$oanMV~7U%ZXSqTCs^2a6Ap;VnmP{L-c8DIFE}ubqq5jDcvViH^.BdlVk(ow|KyS\[B]\D4gYyP=5|mM$e-X69s?&pp+K<P)pd4S%GhG)&*O`q1!Hwx7pqBnt@WI
::~=T|+]ju/r060uq%v~ZF\NRq1iJ&(gNtfKW)sJJV@USdlQaFFg1uiW]fbQ4fIY-0W)a?,12RB6DpyPH6eYGjR|u=K1iO+eK}-pNoP`@-UG`@YK?up)2OyW8e%t53j=_KEZ
::;BOO!AU%4wpctz`n5\2\dV&Q$+W6(I7)EQmE+@zJdfn=,o`(VHJeKx|GmbGPn[x{EgJ,5QSbX-);qZw}LHt@q4Pb/8KY&ZaP$*a2N[AN?9R2h|PZYKAIcn|qx,{DcG;&E|
::T7&PohU,.dNBgd}mlrc0+Zm)bKs1dfpLjsVS`uZIZ5dT=}pb6{|WdNAm`aUA.W,ABuIfwaBZA\U6_]hj5&>pAFK*V*}h7(>z*+UmIRC@L>#I#vDyr;S+3|Ds.z&\fS#$Az
::Vu^pI/IzV?Iv(9Vgd^{NJ=Z\f{]RCgweas-Srk%[`vH`x0$@cQRE4\pzEn+zE);$_I!Lf=+N%WJcTEG4W$#iX1OUi2_Jx)7OxeWmG11B,xwTU]]u}Ey<|omTv}yzptpwq5
::}T_eD$G}/J^$([iw@P1$y#F&X%=s/?u6g*u$s2\Q94&S@u)5.kXq*4(,30<3)$Ml3??RwzKZ!liKQ&xO!\A$3QN[q@rXf`*B{`a+)EEe*gcNEl]/f$?ij;\{_`>mL.NRp8
::,PA)t{Z,aY>kIQJf13|2fEl{rPn+cN6f+sNk7U_+|[9pM*<dgPfhx[2ZggDP;Gn8S1>FG6?-{|EC;%/!yUdTrQ6?f=KEATG)8?);#9k<6Cn*>TI@*U!j/=U*]t00T$o13B
::W*OdYIvdBW<;1B|P{0V%nN3!$T=bUZ[NK@;[pK<kzbGI2B76WzI87knS=}Ex_D4[o`kj^X%R0,q,VZv_kY\/fscc]M%jewdPp,{g5`2==nhn22CVc~qgM1juF}Rwu?_>bD
::l,0p}y6k[$>tRQZ/tv/,oJ2H5|L`In~KI[k{-M-$8)`Z*,!1C@.`?m}/#&MdDzOA@fW1{Ds<03^A6!d.T>7R%-Q+0KeV,EF/IH-|1-axd#eU~NM$nYWC;S`RxzAxX%v+]>
::<R;xK]6rvjnLdwVA1$vC{!X/<P/rR?nACaMalku;X,>m!)+gFg~q+WAx<1txA-|tqg?MK<(6jcq_//RO}u3sQfuu>cdhD)dk|;~RMD#FJRjWWz]?_kGuWp?]up>FYG=e$y
::zT=-{=5p&a\j5Ah|KlXRxd_$yN,3-k.{8w~cRlhYIkmJFsLfQ{H^DKd1](\[)=/!J,<{3Q#CCc8F$Q~nq$k*=RsVm=.XcHkF]=L`c4D8a;nE\MT\RM+-kb5myp]<>%so>Q
::d|]6I%QwbyXi2T#3*0#&i{tK-DRJol^Jg#}2%8<RfU_4v0AyQ%EF0uM^hNNUFSCn5~RL5S5\S@!t.EG`?arRtU>@dWMT1]]QH6WJ{i37O`(^sS\]H$yh*hzfCswYiM[OIv
::N|)@BUtX.XbmUrv_NE\0|Sl#@n{KvmrTx-\Vpz7kM5jEW\ifn;oz%uW#W9;`w_b5B&^GXXz.Rd;oa^%rFo)3tbR;m[xg7OS}$2HaY&E`$Kp[._Hx#QTH$q\(b]c836T.V,
::O-ln1m#{+@tq~C|6>2L9nlg*ymE}G/__IGlYl&bSlp^t$)#v>chzMw-48,\X%$IRuyy$YAm[.,NdIRe=plqX)OMJbkR$)Pgb]zss#r|+8`r2i8F0xc^w9+/oslRCd5iO%4
::ER;Wa+~[O=AVyZVc\^~]VjH`Z{hCDmQ3HI3Eogz>-}ST4A1,Ns%A&)A][wC3n9D%)_!=Y-KckE)Z74Jv5*p>{fr,}[l!~(aZ=n`_a(L*^Q77%&++dTY&Vn\%gHhP2Q@7oq
::|x(<A\RIuv5?e@DQ](ih15H0HvBK_|2V`q]+^!XjPS9yzbylm#`7*ITj<+vt4FBj!J10$&D=l;<TQAwKM#zX}p&s<&V*ef?E,eMBR&G\L7!E~]W<CDNyj9gtcg|C2\jSQ,
::D?0YE$TCB4hA_w/dss0t$)O(^rzfPh?j-j=O-)x{1_F*H$qM-e^1V(q]V8JXkJjT\>9J=+UM78BFCRiw8|!2s]wDc4OYX8G,C4y)T+78~X@1A_rk@)u6>V10kDC_.<TV4e
::A%wZ*UTO)D_=|un9`J7{^HRDKz`kuy?usq7I8870,.E+&+gP^*iIfQI6O`\==)}WeZmG=w;4-EJ^CP}Ky=-Q]UA|&wZ(g(YN2+,G*=,aD>~$vLe6A}JYlc3&)66qg]1]&R
::;@,Bf@Ni8C}f?`m;DO^Lj_@9wOk/oVs$oZ[hVZ`TT1/3@2L5fhY6vI,MbSW|\tVq1cL<hJc8#2I%Q*y9>7+({|uUuWPUea^G5Q1zU.yKqFheLt^}$S|YdxiXQyZKL+$VjH
::av&Gsc~<Q\<HKr-u1b<Q|cbcJG&Gm@6|U6./AkpB8R0SAcJpWm%iDD,Ks$rCw5V|m<D7t#4d_2OlYu%rb#CB.J@xG}Ys>y80./y-Te%?}3O\P+>N?B@/$`~EO$8tuN5nCz
::<t{g%sfGebn_q$}_I{rv[J8kEn?BF#Z|w;[{+\R,%o>3k\44!|kNy4XzH3n}Qsi&1N;2FY*H|N~zdOSYa[os*U>b.D38hM^O<kD^0AH#-<Y4.3kH.m]T)sc)Ns5#h}5!oR
::4RJK.SBgQboolJH?Bks-HVja0]a+>9Y/jgC%2p&,UgKQJv-!]DySU-+\(j&2j7&sv>~6s4ERv^8#5SBz[AIXaiZz#E#IKT2;O-E{1xlde+\kI\rRC@k!uF!.7_-E;J[!v4
::Pw*,Byew~oMvL{gMz*0tdZV7XamkQwz=|QC]g%}vmNnkRRRgLN5v+cPkK?S[g,HOd_p#qF8qccjjV{%662h@4EZE^M{Bd`7iNcaA37Pkp~?FK674}N+d\^WKZzX~T18|Tt
::[r|\S%uvO6p3wfs8VH`Hhc0ir,Hl$=l},[!P_&Yh2t3U{A*&N@a2rMNlX(2GxvvmyT?4g}U|\e}0cH%EF>AfKX;=xme{.zWZsV4a#|p\,{*Jz\/b?Fp$0F}*&Ac8Gcn-Y3
::1B/Oc{K8YM`bF9^X;Y%D,PjAzc^,B|p7yJ=(SR^2C}]%z9V[n28gq8^TN;z/9cJ%_$(#M;hVP<@|QI]Y)UWV][j(0<gP-xd<WRDBfo;nxcMBn!FGv5pL$RyR%3v#g@YacC
::NQf;N9wj$ud>FS%t\Y|2D-D2<6d++\CB?A{x{d[&CK$0IE{Gt2.KwuhY,mFTr$EHl6.`XCd~0q9@@$]8E5&T+PkY`0]-1/7V&UpR{z.D1aZieE2(rbv*t,XDS]#m$*u|?M
::9qw&Evsw8{7cLsT{Z{G}qQ9-i6V<ncT{d2~7f&#Y$6d|/svM\*;PifbNAPFx;TrT$9<7>c<c?hy,4iN;1i<i6e2IZz-3*~A&QzGq|)C=.yo0U(-FT)>}8f6DKcl/uzGw7N
::%C,PJ^\,No9e(%Ebts7w<EIv630/lk~(d]aJ5,GKft)$4p%~DQA`#zrMRvdyjoal?CB%YG)J=NnLl/g((G}Zsa.$Gk\8whiN=7w/<JLb&a8eiv>H9Q7Nm*<51^$U$1Fds7
::00}R(x\*kn3ytJ$huRQy`imQj[1VWZM3Rue*TEW(*uaXnq;grZjj)k5pG$?J2RD*\s]?r$9nuhp\^;{TcfxSK!K!qUYT*nC)!6<,R]=DXTb3O|rv?k78a](nwEyQ1yt/P1
::l+hmsoBVJixS|?&OKD4<&=16!}U$puv(0SAIL~CSZKGkg(S|a!6BOv#9@C|AYhIqK<]$ZdgqvtbH8Ne${-Z.INzA@fq~>!Ke+n55anR!~Digi-`JSuz#_JrT!u4jLR+$>=
::`[-MQltv8U7Vpxs[Q#Q.#1K^jRL}WR\K%=k1[HE[y]n(wkw{se)m?DTuTN1#!91fp~oNmig=R%p;bqYq9_!N~(xuB^=rkA]/%]y&4TlPfvHrU#5j{^@xZQWK%pMmEd10|f
::8yasZdn>sCS8}Y[*_vZmGU#Dk\SeRw44rA#qUzRA0uQ[|d~cAhoE[yDO;_Y#s.-]YPzN)s!]MR}!*%^2mIF?lD,Yh%MGjWlQoN.Qt[J=QE0`p*rA4H_V6$Keyd3kZ]dUug
::2qDQZznZBKlXPm+f|~)fqyxu#&v[irT>m]3vqqs}&Tv5St{XYyZS.IJ>~l`Pf9@yIZT}p>@#t7%]w^%ER_-+K]_[q1u?F8pC=Y#[N[*ScZM%vQ{ObI#dU_<<54@|5U9W.W
::CVOWrY.VrH/2G14XJOU?+s(a5;GlICVO-EvSKf_.hCNiM%3z%WAb>kMX/Ijb#U9taO0A^CbPJb__ANo)aiuuz#pU@+HRqq,Z\R^+[]_CSpZd1JM},!+O&Z!z!1y2|OlAw`
::#_|v;%!<p~7r_C4FDok|IMm)_jsA/,lQ^N_zotU^pQAd0.DrG/mQ2!r|Wpg?r]yurze2nRpWfo50pWY3JV;Ktc;A@_}j#u_WB|%JiR(r>Ou>MoQYI(~)0bf\y4|wXC(W3u
::#O%gZ/IP05r9yiG]EKq(+FzU~z_+0phyRqqGN_ppdY(b}#M`h|wM@n_?#-2xIX+[NA`LZr6#4KQ=P+B9trpO7^.})^SKOEmWu&LT$Qkv($,{[!Yoa82xA]9y;P#DAQ[!y6
::lbW|us!w_hb+G/%C4sO*3x@V~RoGqF][9om37X^Yd@Ko|}5*<Zaab=_qSVk}}!/$q/(o]7?#N`z)36HO^8|ur@wlf|!kaf|o>[bK)P=~MAor|%nL4p}O#F=)7-Q}0WX=8A
::Qnc(JfF|/)k[]CDGEhT9f$R8R7gk<m^!zO/L<lD)JLF<cUwPqEGFT>+9`gLx&_.CxSe(\Zf(+M%G;oW9qR2NAqE,zOK,GXZg|JR=Lh(G@Y@pr6G+$|c\h?}*\={hhO`ui2
::Z1{}ew\x}/>{5#vPY5GFc9YpJpr3;Ftj/dT>OBtqBinebfF)*>At/rlPTZ`K1F8ue%A<FTq8+#.Hje*Wj|}|kN-~*(uuu%y95Xa\i$[R!%x%#We5wo2/~WK>/L3s\r770i
::^,/3?vgp=GvltZT/l3v4q!OR(Si?O(m(1hkSUuhs+pCiY&dSIIhG%I$_wJv|xHH-;X}3FXK0$y%vE|@[_cKl(pP*Kh=heeb8TFms5&r-10Y!CNZ?to`aUWU2CPsRM*C?1,
::k.yS.pUI{[,.oa-bzwqBAI)28g$E!lfpU0%@RyCmq[(vYE5[.!eTxY-ZhYsc)]v9\}mYzUt^3X-Z]Nd1e-g(dCX5f_dQ[9.Ve4*l\;B]I@ux4oA@UG,fAVGW6}s|2~Far-
::Lj8J5S1VZ[zL^CoT5(|IY~z<|qLTC[PLmy%9)\UwdM!~0Yq)<?kU$}&U3$[4sJ^Kn_lnK{c`1CN1#E+H#x3r)8y%^Yld-d5R[b2Vrcq|/_0^Jx$VBdjy.$}Efpt}+6Lrei
::BY^KM%xuc@W,o=;46{hkO!#ME)&$hu+fP6ZHc.s0sWjSIg67t;0~?5[!?^@<yZcohL!<<]/=P/d-N/[**a#pR_`S3v/M9-9G~3XQ_4}~!R4l(kkM[n*uE(G.-n>z(8Vi<#
::?X,Ek%Ix;UYCD{NLQ<C]/76}9PzUOq[E2R,C}T(mexx<50N-$26$p{|h;86XkrV7XCy{H&>D]xHrsGbq|!JAx5K.fU4.mmka^~3+71,ebd6;)[HeB*PPp34T}[*(cs9h<q
::gjvK*2YtW}RMwT>1Tk,Xjq,ij[7Gq1ix)~0kU;57i;S-6LB=DB(M8966u4,WGI3a)7<eF`)SUki]OmwPNDv39)1A4^F}u|uJ*%,/.6|I\r*~$bbD;An+3RQ*NCzjkT&IjP
::}qy<Kx$=OR2lioIZ2F9Vl|=i[2rW<z2!Ogh))I/`zu&1KRUlZ3WgfgOpM9&XiHux\@OKks\$8ZHNA[*Ylj.G|[ka7+pUy[8dxK$vx|-}-VqH9x15.2jCCDpCmQ$#~HaD{n
::Hb=~TgQ<wrWt*l;Ju=qR`lmT$53(Oij#<V/c]!7}s[tO61yTAn$WjCNV_D\[\2?Nk69*!e/Mxi5rR=$mWi~NM>rZGa4`n[e&w&j}[x7n8Hz!-X^PjpYeei;?+qNT@Z]O;%
::!hj1`b\9X7_ZCHz4Fyw+SCcS\w}#_ku[&80FS~jPJK/#x]k7d#DzxE/F691bQSl&gPO(g][MJppL]NO]~u`hXcz!fSSzV5,C]2r}ZN.D_LG=Bm!21q*nP;T~F9MTlEM[]c
::vC^WB}L)UB}tRv>-8amd^5eaoT1Zsf&@;)Qz$V=%h3.]O8hEt@4bGb?1*;;d9&hL\Z#8X&YD^VQBo}^6*hbFDzyyzbiEU\$/?ul%JSF{jH2dbAB&\?s/`r?MTO%Q3=/!CV
::o__D{sRYSQ|2!,yl6L#T(MYPfufz8mpzIk|Pu=x]PLq+0*?Be&_`sehB,?QHeJjF5519.-!My~[pSRT_uKGw`N5lc)<jrv.-nN]f{+-S0d%Z3[2J|[S&c&,TPZEx\eDK-Z
::c3]Wo9fhl%;{~`Nrn7(MYW#/zCg36M*gTyg_YXDp`1g!jv2^SIfwr*O]5Ee{Yos54B({,_8B%K5i%Q&L~u.J\A6tc;LS=YgIc~]0/}ZJ5PVU}x`k;6eF(HP3R!daP6\5r/
::1(8hkQ0)r#B~F<7;g9RYW9v1.Xgl/tneu6uFLvHKbvI4`X~[p0R&k#,kyK*hvL8p4/wHx0h,!81BuH3w0cLsn5^A`$yDm[f~F]Nx9e&qz[I+L?M$s(xk$-eBXdS+QV.o5i
::3SqU7\F#b]3@,ujZ}Fg;b6zBEm@7n&(8qG>/f,W0t_t*\]QnCZq%9(daw+5s.il+?dj0B2),<XNOxYK4!CI1tj7<6kPAFJcTPSWD|JUaR2zQ?[5/v6YZ.7c#\F}~_S[qzA
::eA&$!FT|&T8fTMN^jGW-^c(fuR}[Aw7^`X5JE[hyioAznOqt+I?qc{35/[Km.f]h|s9@Lw/st|k@lrD0^{32p^/DM,YD5z&+eh{5m2_!#4i(aptgE}#/bqViBoL^*Ed3!}
::;r>l#hFT*<PeEP%sJ)8J6wY.91X@7><~,.sN~\LRKI)!g2}wfM>g-w/#$50,;|wN+|J/&w/08kq^e83}XS[_c<1nwnvYmR4}LSq?YS{Z[i0>>Q1,.ZTD%XqYF*pLj0jHi4
::\fRQQ9=u962zj?fh~d2{~N(X++gGtdqf55Snz!Q{glA@]-A$iP<`NERc~IpB@#QTnL.pMBt\}lqDWn\kM?UQ|cI<3YV+-l-O}w}&y<N;pJIMQ^1[PC{7buLq2tcTiP!$U0
::ax$TJwFz*W/{rUxUkHr++1ZdxSz4P`[4_!C~~1n7KbpLS^\4u1>*-<6hWwT~^g||Qd2]|H&sS~8P%6r&xskS;+W`<m5*RiW-=JaEi}y*cylruF1wlDMYBSGOH6Q&7J^3jR
::Ah,Mp%zq=hNW&IHEPp<&+wwt2hThs4]Qrpd+^+#I]<n*gtB@gjD[1)wEsZu08,oX@03Sz\WyE^j+-2w,.MMK$l)GKLSH`rsPz,?3,Ia,M3+clg1ROjIgjhLeKD|d{+TG.m
::^-9qe>ag2a22u1/XIN3&Yy`S^(Ii8rq~K(vu3oOtgNXFXa#%J*e1*7+{y]&34B]M7j_m(n$@P3mvW;V3d<R3YC?G!w#EImm|&EAVub>B_O^~i>,PK;83aOqTy?hUX)w=o|
::!t[C=FFhiDChno;$ammL.Kyb%^Zl9`HBE2)BW-1&1,NmfCFpTB%pI0K!b7L%I%,T1K!R,>KI`V`ou\,P#ZEt`b&0-7/%p5>TUy&Y?C)Z+YX@}!/f36-9RfEd_[3!XzMgfA
::C5w,ma0Riy6-l#IE;Y,MlO6o>[(Xa$_3**(<hBa\[E[z3eBa(UQoFl)8\0[CmTAc~mm#4.mTOH5gt5Sx.,efs_{i+G,?WQd4,xA)-0N]KVd<`2.!L/JKr{EmQ,HgZJic&T
::XSCycPV<+h=Qg66LuuG7Y3]07vmTuBoSm<fW88azP;DfJUj3Q(U+s8P<LI9Q6$t;gz_u{GVkj}6cJ!=u<r?}Ysxr|odAkO7#b6V#z#`XDhTDDEqmZP3&wNagax`VG]Y08?
::S^]kWPMKc(`@A.W`dw}F`<j!,UEmDCp&TW5**~Q[RVnsmIh726D]o7BY5=4*W<6K3-HRGW17P%^XXm7=U!])@#c,.J,@xuV_d$ou!snJqI+Qq%qK=mB\p\)VvR3*QGbAQv
::RT273@QBFj6LVs|D7!Z@$X3#axG;?K@x8W!2AQWvnKyrEx!QgtwhW~MUz.Do,>UbX+rCTL\HA7YgZI{QtY}8d;{oMn95b;*GrR@jj&mtWartC#Ft1MNPQ~N%~naC$I5Qb#
::WdxTBI(,*qMBcef*PB#C\d$ZZ;Q$_+0tGF?!T`t)+1=ejgU@$&Q%8cZk2h3MmK&I0D17r()bMSq[~p~z1B\||Jjd`?[y,&$r0>pXI%I#Pdi~7m75BRU3GXUr%XZ1KTcW|K
::[zSjwE3X%[P+hz/<]hT#Xcv=m|_D,LM\;o7f&g-u/]}I>qG%7,k[aK#`j/[JgRRc@v\F&E5<}ju5e;M*vza99j4HaUy=}|H]pOR0M+W$/x3T!<Dcgb{^}_`9M@$k?/Zt,I
::b*^St7TEf~O5h9Z<5}+]^sNKRT[#^8nh`ax0l%WnI,l;rXXEhCM\OiuQ4O%xiPZT;z#Ed]$$7i6Z+v=y|7*sy_^?RZ@(1SOvY0*G>+riK_s9+G?tU?yYLk-L*HbAPVKX5q
::F|>#xaIQ`=pG,p-QR!Mdxy)r+Ft`(8jwae>tC));?Ls\d8j/\q?Out16{%U7\AIfdkefwpgDYXLq3+@IU2x7wvBW&L=bt4>/h%,5&Oe`1|[{(nGjZ]#X_;tPEcM%o?QdvC
::g$S!94tF(7,9yc(Ju;aUb|h;Ze7|&#Xi,P`+ZL!|%=5T-XJq?C`Ip(x?m^2<I5_{~2([GF}[S{bxitY-00[#I,,aF{gnihTtpmO_H(ed]YVtGt)}Ap\ww>^k@B~>H0\sgV
::}Y97P_Cn5|-H#V&YrKw?(kK_x._+U?_dmM,#ZT4hCu\q{2K+WuHgnZQs7o$YYPD=UIj.n`*~7FBG3N4%8WbHg_ILNfKrjNoA.vjvRa~PC+5OPkl`]?F-;}uSl6*,uW%xI&
::|\8M>+SB=yfPc|{la.sBaF3cw^ENw)<;p0`<x4;x&gOgPW1,@F{LQRKsT*;&b#@800]sE-nT>q3}~8AmdZv<9Gi@0(`}e_%oPkT-E3Di-wOWz9d4sdN;m5HO*3DF(0s\]o
::v589~[1I_xs_*dSud#vE;BI?glh-Y=a`@^Dm/]I)WW,EMmaYE!O[QGNJz>#Dmx4Kr5^m8[V\5Ug,2n?-<u%;638JuK!mw.w*0&`yJK7K]91fotB@Z4bc,\CXGUB?sa/6Fc
::PlDY2E2\fBa!*?C`G?y?ALR6j))4;/?jQ)^l4Cr2K(7q^LsiExMI9B>~Ij5a&;cN}M5`pC?<Gw8ezJsKDm(hiGX47V$%vycNlFs#VL.C~Q*M$X`Xp@t``GM~t~;DSi8bWr
::Z2E_9}sj#%9^_XAxIs/uz+6RR/(>z]qBMfHpMU9Xm7Ux6X05]=j[BN-[)/x|mc5y;^@~QbiJ@7n*23mM&6w|%wo8L@yR|6(_owE+!Han.TZu4]SA($\<a1]v*spLj%UW.X
::y`E=eU7EY%g!h{|nR<_Ane<wkN\c8*jDfd8w^\C5nNo-&QL&yV0$qELJ4r6!gh*z$+hT)X4XCg0$)H;}zZ~G)v22bd3x>dQ1bDsfMGFtqK2@+DtM$/?zLrF6R2r@=C6oC$
::_<<Z#Rf)uc!3Cxn0S)=_.Y._vf1/~<BLn~;6K-nhm=9@[E2{hN]_qz9GN/I/{WZt@M,`r{}e;4K+@oi6Lw/=7aSq;-eyCkqUU\a0j_v-e2xl0<~3n*`uqI+x8%R9k}\G/g
::yz5Z@TFk`v%F}eR]*Y;3G0j/jCi*LU$x/O*8jA=c[p8;cBp\b~?wgC?SV\`]7Ga<)bJGOnpX;*4;]M}hNO.Eh)|*4f@AHD9_7h08b*o[lPmFC$RAs?s(_GxR,ev][ltc+Z
::(#[RWXEZ%U%j@)E`P9S,YeS>5uBzj_Y#RbR=k*9x&,f=KN4-NH,+Q[42x}Ve7n%OI}=I}Wpk>xk$tJE5pD\]#sA6H;*O1-iM{)-%V0EW@@]xt2t3Xk<t{z$]>t~{8`_D>L
::xSYR5W/*z=1/v<0w|tWHvk!ehI}O%YZ<G6X72]3ZWURKye$*RA`]Rp/g$fC/x)zRG{c,#6?JyE!6YOvEYr|M0ox08u=`k^%fp=zY5K+~Gh9eZh5L\q?8Nx|T\5p%hgRBMC
::L1(lJ6,$cL.[u7yY=7W%4F/YGEaOSh&h@z9e7M-8a&Y_6j#K9GNPco0\6u3K%cC~1ks1}khStLweuT,9TQLC$qRJ?IBHl2)_Go&oY3\Gef@j?AKAb[z#*J)e,\IneEFn=r
::3[wo[wnOgIvb!J;SN6,YE[ul4;aA6zxPB-2B?%R*}I12un&H9vi4(OTaZV~N8@,{zm5?rRTQRrXciwg7*DkqOfg9&u9vmmu.k{#ud^xh-y0kDKA@r&1h&WoS5;bS+.{Q6r
::U3!h\cRPm7xL6r`e0+hI+s>S=BGSI*A6{6Yh_&7b#)J\jG#4@PWOFL=|g?xdzp5Qi,^^i5XrU~C*;9O#qW?@YftlLE>j]`}c7aH`B$-<cBzl&(\,9}C[~T^-i3o@^|dq{Y
::`ZSj@gjeu72rhqGC/6v%]7t5veOMlzb8!q_TwmftNbHA[$os{l@KXhcd2cQ1,/0gwz}ectn8D3vk*@wc>&C7roQ|u@`CZna2OuC6XnNF%cR|2y5d${*SS/r2=mo_#qxe,J
::tpNx=QT}oimN!8#eLP8n;mC/fP_^c_5q8sTaC5`tSR%_aVx\=@aH+?m2khj<E/00?8zl]&`e%r)Y-&E3ZgTypL?m&G9,2E?Ma7q-GRhNGniYV-elD3F2m*1wiNi=.{=WzE
::h`3sC^kjWsxea&5!ii.ou8(kGHRw??8FWue-%FGo+Lq;>|]T\COHl~FHQd.!\/mn+Rh;f3aA\NHZa#B.KHnac@8}e^}Z%rK#@-B=5^wCHG16A&?&KbenlN_93]96^8!\br
::y!Wn*<o5LYTCu%7qdb>/6KL}R8t>aLt1>YK,pc7+-,tae5>Yz9_<t\Ef6l_]pKW2D!(]<t*<,MS[R*ultXCyq_ifs2pN.ho|2#Hu<gRb[NKn@}tPc@sg&eeg7R8YAh{OA_
::t\{Pu\sjGx6ceg/{4f[-(Vem~N7b11&P!dE{yP>effOYX?>!qIn)xW2*AGeRSS+)gQ82\MMc$Vaib@?7~@9H`z;2-3t*a3jg,r+@P8$9\{-~A.Nr?Id2mgQZDSBGH{<HgZ
::gbJ(@<D0/V%jpK(qMX~0Ab!50[xo3O/t9YgaT.A@zFKMPRq2s\|B(36\`},4+>+]\9(Q~c8H>ytN=kl4D*l#,}S}QxN(o5{>b0NBqdT]r}~+A=TTxp@qUKb\PzX(Xvk{Qf
::]EFU}/Kr>D+HZ(H_\BX}HCMhkG^7ot*CukGL9_dR`C(^H|y*W#4fx~DKgHVfKs)Wk#gHQ)|@pvfNSY}VuDNY44XbPBR}<#ZV~xS=?\)3BE,cccbx/N3_\6ol(h[+]vH+^+
::,<He6cGp&&R]s}D$WDSnvq0M0[i]l6<!,*)5YfHSMxly*kW.Byxoay,,c0r[%A[o@2MIxN,^#[RYqGEZDr7xDbA{&@},\OpEe{FB>=H}\m{3(zGw^BYGg!#Yt%6,=$pNf?
::ZBd0cB?z;l]kCi6H*Gb96pic;[MU%G\H~{ZOC3IPHrg@O.JpjCUS\\11sv1(,AoJ^aQhgp8\ghx~!#~qsCQ-B1T5}[sU/MX?ARv5CVP1R2jwgfN+i;=&y56svKvox$M,?j
::<uG+<#KzK.nKZDM/BZ)(bVkBgrgq]BG/.7FX{wB$g}2mxPZ7B^&@b6\5YBb|IKUz%Ow%uxs+I}dn=9aEJ^r)0}B)]_~GZ=of0~ijsi=i\S3}y8+s1T\7-p`&T_qVfK7MDD
::RD.U;{|wS2NIC!}f@399+Eq7tza^D}i,YF.WiEV6g?\Rwp;Rm1@F/u~FoV!%@}uh\5KgHGBwj+!+LBc-x{ZeYjegsaniHC|.NkT4s?,9Asw{d;7QS$!t5s_<IbogW!-hFE
::SiRHJ]R>h($Qj)v/_$\QV$&@={-{9.<G4h;Lt]WY=vCL,H.f21u?!M*vy]Ymo+;4)(RdIcYu}_4\C3DaR|eR{\sgfq!w,RTaZ~WZNDzSUzT8Z2?Xf{HQ&M%nDF7NcZ/[*=
::nq3iWVn!F07X2Tl(N`*r(C$)LE&]5(e^}6XFSP1x^qR.|3D\mo~[?+B&x$%!W]a22d+Q]++]?QF4TyXwIwTq;N3I%GiT>E@+?4#@Ee8|-j7fU,vzIWP(}dnqSwJv~.oik!
::J6Nm$O_RdX%pMEDqT[uUSjIr~)(xM5q}(>_me*U]HY<A|%C;|Qs}7F7IeX>\6-,dGSLAP)]<HLJ/xJq,$dv;u74G^@M&hDfVcSj3B*O<y~r?p-/;R5;qH^gdm^g%R7/AYM
::KNQp(c5S]e(1F2BzhM)68G&mQN`FGIBwcL?t=]}o%.4`z,&opa]Phl~`oEM]I,9w]Nt+fP\sBt^=!C(s0[,,AK=AqrM(Ms$wCjv@g_MX?9J1YgX9UBY)ClCZh1TqzGGA*H
::|\@OFc~kTlt_A#-j(D%u9S9^C7U]Cja8\20r<x[f|k+is9hN~mQZ^fE89}^`+3_Sa;\\Q~6ePu87ipKbRA4rM8[icR?pFI?Beb+qO_AvSqH~@IORA|,P0lJ$rtPsPkX)V#
::91/Gz/lae]\#$w?@D=CfXY^}(mFqEw,b=%-TN6+;SJ#zkQb}ie.@[w%A0Ua9IAfAY-Qq@)`g4CS|d]K-uaprR!qeSpD`)miWgW,jFHHAv?q`;|1w9!z9MMAmOjGtGS@(fn
::>AO0%qhR(O|m|lv?xMeU]E_c]ZfHfl,1iQ*n/4K5Tgt7S/r4yHnfxtKC+[XSq&O}Wp=%<3.it^b}2=d0D!L4-T4=x1dt8KYr]txnVM]MwtyZ9xYrnX-a1)U;$YC7~P>yCs
::vx9(Iq8|!#?(xCXA\m(ASrL`h\8pfb,i>fP1#^-M<#yTQqy35l=Y/lh&f}Rr>Um..YicltSR?UMYqju*KO<1)5)WM52D`[,d4t\en?.f]@Fi.pi3#ep}p2j~jn-J<Cv*+)
::>Qu?,14mt04BQ<^ku,U,yg%HhX=Z=72(=zp)M=@x#@N$\KJ[!YDPCKYT_S,H`?{w)C?s@F%\m_{{v\*y?T$_Q{DvuhKRn=i41Z+jZ^~(M;N`LT38zl|OQ!sQa9EtV%qu|O
::W{\DHYBI#coA9>R/.jv%=sOr~u4~glQf\3MD6Xt;5k\gzL1ESMNfq_9XgF8{[*e/}]*H$[1TK}XD~fkH$+BusAQrjesplE7[p2JjXqRc8EJ&(~%6ZTPk81{FAZcZj`|2[,
::]0JTN?SM,>ba5tT1Va)V@Kn^;O}0OOa,*yKC)CkQZns)87ejjiZ#$RfIBFAQ~9+*(l[~GJ?9KxKsMS*Q=!HFD7/]|*ASq?io|]_zf9rJQ.wp*D^)~l]$h`R/1Jfk,&\&2q
::;^RX2t}D*}JS`TJ)D[HB#*%x#?`@E|`pnXACa{_+nndcB/Lm*pB6B0BNt3{86nj2n|u4MvHvHxD74hwL7OzQ&fm@$aZmjF4W2]<MUE,\LyX_WKRO#I+1;#9Pr!Kq|O(bcR
::Hq&vwn(YSu0Tsy2WmXC(|]p4l*{SXuVIAwej}4giN6u\NRc~%Bs![;4TnbfP[x#^7Sx#b(>,CG(?BzBOcPbKFGZ=(VMl[{v(Pz$z\u^QMOB(][5,Kn3QlK|vb=!G0g?#G~
::{Yl9ukk#?J4!G>X*,PyK(28<~tL|a&Y%ykl(dKmR\P>jIh6AZuKlF)==HX~0H\Pr_$)F}q[HUVW3pUsd%hm6?0maB3*JbHT<z|9*aA}dr/ih>Ko_1ecG.2`Yda=XJj/{hQ
::{RjfA|NsQm(I&m@&ojCBa(.lH6KR#6>_s`Bk%D*Y&NNQBuE\2VCxZ_Q5[P_2k[XMqg]jZ#6)W7`-9nT,O3K`jH*izG51Dl<4Cn7+$&f}#]<z&;gLs~VN!)7k25UJP<Q;&L
::P]\;5=epBz5F5s{0X^0]K!]lV+I;(Lr!V+(D\B]R-F^mIUf=#xyv~B16_!!1cng|+.45~ZHvu%?\lEKp<N=~ZxO5=YLfkXYA[I^HzlNT7rwMZss,1Q_cp^-$IVfw.}ixe0
::E_^YfOb;kEd}bO;,u<^ub4sD/(*85#kOn^>PewnsgtN4#=9Hi;fJ-.exm)\(?9Zh7uu9}Ii,zWs?G`nEP\s_kn?]~sk/Q5-tf$Y3`h#Qv#?oOJ!Hpp,jxpgwsR#<phLl(;
::|5uC{B%=uzb=k65Q|eIIJ`Ui.`RSUKyocM#`dhHU0j3D#%DdF/G;+sc<jvK}GHvk4Dp+]Q.u*Jd\Pm`_<DT(%_P|!y2x<%3LZs>gq./Hb^$^1jCk.0B0m%$\W8=-x802T*
::kxw^l-$|lA5O6jD.=Ix]Yx,^CvgkE#-s#x[G@U_L75mvM]/PkKlOy<BOeji%EnV2*5yEs-RX]5uX!Z-uzvy-K(6qRab}<@S|]0L#dz@aH4%e#Dk`x3Px#+fbJ}0a5#e,./
::NuWj(.|q8#S<xe(ft|D@Fab^Cvzg(5FU?MA?Uyj]6%pf<^k/DpyYj^@DxPJcI|EkE5/<(v/R,LX!xk@(.xNM]*cHVzcU-LeBo&*iU$ca-nmj^&w6LjCn/?awc8Z*e?dS#3
::/_5I2h_W|z^r~36R?3[(0h9n4THK*bju@=8kxbwX{PGJua/zw?5n<?$4UFN8z[`rOm<1Y_1(dKiu]efb.<ygrGn$UHtZ^y9V1Qcjr>AKW0bdp2ylIPJ9Z|VZ0@m|%]P=8H
::*g4&3[&e-q(vKQyj3U2;Ac2@)Bd7a(h63*sINoNrQn)\]!43qeeP$$MA)e;M+4\7-oe3#ikIN^n;c7lL|ABL3IT4H[#sn0Mw<YLm9]cp,P3kQdGL!2B!vkW^4oZB9Z9M*m
::`^\JuwqDfaeQb;#}4jGNG9^`vEHg;l*iTfwqsNO~AJ([<0ovUGY@Vc>U+wq~K`)M4,<ZovD|}nS=s4gs4$BHxx3ChKQ!PF[/APBQZrN9_&q!Ho;+m$G/tPdzKW3?21X[`[
::]G[9MZMP{-t`1KZgcHJqzRH$G`Ex6Bx6f!*Qc;i^\9c]DHg<WIE.<8p]K^F^J.A+x./dT9Wm?*z$67zQFP4zX?i[......d,k.pI<G&,ix9H~7W6y)W@j6m>=H@Q-sU@24
::W.)Ox-v>`;%,b6X,}2/>HpDatQ}g;S,=6py;5Y,CbX+sbQN`3<]+D|.am/es[XuZ{pTvwdW8U$5g,\~&*pV$cQB91b%^0)S,k{xOjB+|L+u,C-!rzRyP^;B-(.JW=PE^Uf
::<YaPRfvgxTkyT-Vtjkb\<%TZdwl&T$=ELXs\Q5_=L]7a/.GPv.%97NoFtZ?o~*|/XN1`HEJGsj#$/0f!CV0($~/Cu#DZy9)/DKR6GM\0S?Kg#fI%U/<*2IiGQXG;#D~&R)
::yANym9]TIwzhvR$nJ,y[A]Xp,`3kRAPmfP4lB1)x=}l2R#`0#g!O@ZHL|bL=xN@P&-<ThVL%YZ*|DT8pK?.qZ-.bhS}$h`p~>GkZE7TZ[(7tZpzsk;ds)0;Hnuu,$`6}+t
::leU#6,SX0m*O^UU~_`>jZ]h=HUqS}4}Y8E;}DoYOK\ds]Zo8O+wZrPFYw[jEoKeC(,V}I7K~C/_?W+nD~hJD2F=U2)g-N,gm,4gst4\qDF)0ng=S+CO%?iex9pLVqdxBN8
::l&^Od19==|z3b?B\_q?B.,*YEaQ}z@t1Jvi~fc|#aNO8@zjWCsCe|V,^h~0dh$`I}gK([de{LGNGq?og0*qLtXw@.MS1vdB]jdcSB\.}o,_eqv71wEO[hrz&/vu))X-`I%
::V]H%aPZ`hPb*B\I*Im^&#%x%g+lL{<uub\aOXBkp/22D8vq5VPeB,lg>TnMKMkdn?53v2C]xsZz5tAYIo\5~C{nG9@-nbpP3>8y17a;!q*F3zTxDq#w<X^,Bkn45PLaqWR
::a*vRlI?HQ*+5>plSMY);xXmv|3FYyYP-D`1<tD>p)*Ld_(XVFY#oDaG8h).lwaYZxi~<$*OvjS0uy]Z<&&hWU2xI`$*\qs^su/l\Z7#rO}.e.s+dI^ds{pT|IEPYq+|fdF
::&[,xuTj#Bi%0}9$0Y1nB`WI-fYQHd(-1o<<r;;V%aL8yFcx`cYyUtl/aR!}-!IfF7UU4#7(UE|3}jmAK9#mfaU@*6,a9W*a3v*3mh2Sbz$&f)g&+$tM8Yk.tAfYzA#u*&!
::F`Y)`]D-H\S5Fb~0%]K#]~2eirJ_r\4BY>l#74S[3ziKIazXfGs#q2[jqgw{hM(\%r(7rGUMmG1h<%T([LN5cX]HrK-^8A@`Ex4ni\4<_tvD5g/B#yV*M4rI&1Lm-GYy>E
::fpU=#2=Kj#;aW%<%B(OYQ|Mg>&eNWr+,mtr~xdkL>4CN89dny-`1a5&mk?mm91zJ{4_Zv9w*SV(H#-H%8oeqUiktQ[-P[.(Z(ZPJUq$3+Q,0}~xQg3sD1ny3i21?>aMbXM
::eI0$\Se&/1DzCz_IXxv[z&y\/,xee`F8X@{O?v3P*$K%e#4a[eUbj]RGN5#b\2MIjAq%c^y}OHQCu``r?~;sFc>#nr!3lbY%kSZ\)dn`PT9)*q]MIlc$@$v$+<fp-ID>Tr
::P3^qA(P6Rnhe7qLx^YX`Ln@@{%3BM8XHdq{1(aHeUW^aOS_s4uaS1NnciCcTt<{qd\y[TvvX%Mshe4!x3#D,N*@r*!]P.<(0#)i.g\$\z!sI~e,y=<zeUT!7KhrY1KTTe]
::Ep/^}N?zs]qmq[HYaPC8~Ksu)5Te<Ow<a#1T0ShJK&EM[b?>W&.bY~qWI7A5!hcBf#gnVt!nDfRvs=(,`U+p=@.%1ub}#,a7M>dm9<*PTLn*.8,>R0pRN^8W^}28{$+0KW
::;E+.*6Ql*VffdIV,`;yYH]Abil{~Wod?$/!^y_(jvG|R_7]>l+wpm/~`xythM`l/O1yr89])Klx7Df5~X<L5Sxq?rN5I$J.txFCL54_(sBO`AoAJPmY%Gu.<^eB6m{S*d7
::XA4?1;)]qY`9#z+eI!kR!E8x=)H/a1|4T%@%*->PFua<dGj~t=p%.Riw(yFc30Rh3]XF;uth;TMa3C@~C8H[Fk~d5hxrTTGTHs#PoLugSj_MN7oneeTt74gufUqr(18yZk
::}K`Rrnh7$=_r{#c{ne7q3N7!IpP<iJCo|0>gOjT2Df_?9zs-q`7$C#-c>iLigqXy%3~]`&/JnAFJ$\9-kqkEv@5%?B}qyf1*)R0&klZ?FS[-VNtcP-$%L[X!-5}I|/,-J.
::0`xL9+eRbYK!HH8%a\}q7QVg$I`[j!r2n8m?TYAg6$qrMWg|jZQAKZMP96/8UWXOsSC[-OPK.F_Q{6JsHa_;]L<*{g|!6]5RToE{KJ0FWGeAcEuDsd,O|(2ea!&5G!@l2R
::PQ?frM)tX+j*y205He`<9__p7JNjp`Ic@m7H2nRHE`yW`u#0G^[S]Z_cx[12goW\_$TQtWiyc|j##<$yTN]EqH$[.>J~35)]R+eWch|y-XSmVeDL]HSIby|47eQ1|@cnB<
::d3B8@/i+-E-bfvWsiUL~_ZeYry|Zgdzh}1TK]_d2?p6~}n<jdQUpoQ#J2emSKi/\7h.I%%GEk|uHZcji/[;WFj{*IbHyV{%=%[B}d0T^sTrD=PS8X8*wHx}rlZ{CEFv,t4
::81xJ=a#_*Cpl@$.0&t\aTGPXLIpp~hh$?lyXI!26$Iq@-`FKds5-Xti~;N?[3}^Z?$aj]@\]t%VOuPb5dY3fSkCw?YH~dp$BQvC$c+*_M*Cm.Wsv*&`bd7Y-rR1#S?DxtG
::b}0Ir`Nc#Dop955EN5^-+ScT1xD^\idq&*PY]+W04~!@`Q];1N=sM\952hEeW<@xo0#3;]R-d|rK`I>/G+G&ZH^KlUC<]P9?u]hSztT$M?u?\3[fTs6l`OAj|13De5y^{,
::TWs0ZPP\G&%6)7=B)*E(wz^(aT&W+mZL_5Qa[nQP;r~WbZo*oycwQ8D`Pi8e.z,m0^roE3.P&S(iaq/BgzdEYA!g^[|tIOBs^S9_ozqko*h*CptC-Jq[;O{uOwW)W\adk0
::e/Kt.aBN3toc}aoIo\o.@2>m2\-to{DKRR[N)%ds?FfO5Xi6f]teod??al]?;(rK@?5l,iBt-2w,{v{C-Tig8GxQffZM.Y&1>`\(rPgqWg(m%7mGB4^Pa_bOEaUCUk\|`p
::!#=B}1.t*k/4/zQ=DY}X[)lOn4wf3Cf_Xdx[K*7tj_z0\5Qntv9j|H@zQ{YP.tc9\#]P$K3?j<Esb|2kO9w}z#Y`TkfX,dYIXPL!,A;s]q)(nt-qy-zNyP;U]QbeuY=#/,
::)c7T7q@;Rh<W3Mp{,5Tc$ona~qPO.yr]}a#-ie+RJth(R$^~*)THQM~U2!=F,vHULxus~F}K9/7UX3l(/W!G]Sg$gpnYwvv@.MprKi6oQV9IJ1q<Cx{WbNaqc0&8fxR+Vr
::>v/Q6}id}\yf#lkiALq/9wzio0T+$H3OW!m/4!g?7b\Vp7(,3q.3jhfjaL-rN9*vc/Wo6jFR/HJ73xW(cbU6[yn3L[SK<Rxdt`V`Ml2pUKe{0N2wcG6KSy>}x(c1M@3rA4
::!Nn)pPg?ej%Lp1;m6h>&gWE&`acRf9c=[`x(Ti]n0AV|XiFN\Ld5*iv[YLLH`\gbUU/vhRfp\9>9JcE!PU1Xan&$0]AWPnOCiYbIMoxMw9RPn2cL-,~Wei?jE$=SaSlaO8
::AnndCecm<)5++xzq!&)Bt$qcE]o6|I1`zUKBXfpJJIY![1Z7t\Y*&8vxW))(%syWRm=KA4{~b%V.}Kafe$43l!#H;z4%os9tb{U@irw+M?Q^j]S$&E_/#s5RQ2?Zbi+UEI
::<3enLnLaIkk\[~2vhu.f])Scj&sX*a$i\F^Eg#1xK]_$T_wnQxXQ,Rr?<bb&O{O1~LvL6|aJL<Ps$>t6y(SF-^ruq_~iV06B<yt0=u}kQVzn7Y$]-.aWPVOe]);kisL(\-
::KFQ*4/2,f9<%D>_8@*Vgj~4Goi~qoFFaZ60Ir!?$k3PtOuea<jPbaRRKcx*]g&n!~%vJg9Tsv.]y/]sNdxV~<K[jO`!9^$yC~kan;~X>2d*vTIj#^GX%X;}iQh|LhYFsd6
::?F$o|lr]$a!qd7@uOTfX-aa6]hFqoo&YGL3)Fb3`ofNM$-4!)/${es(hIUKApW85A_z]#yBr;#$~(;$`a`US=&^_~K8Xr~b45U#i;^%S;^;U#`|rPt~K*Fz)h,W[s4!]#N
::3!4V(Zg}w]i^(_U}skkH8}+r|O9)8YMMOpcCD/}$8%r%]#FR%*w6nOTLgLXEPm\.o[FHA9id(M`]EK4.zd-*i>Rq&dbUlEGfHX78YN?LkQD^|oIcP3/ZyISC2Gmh00^oTi
::+K3f4%4&f%2h8nTC!=/u!rjWnr4i[z/AW|4xEeM==5.es`2xn`a}N/{T640@$W^R$?.gv&Xi.`@vg[{pt\fW-46[ibix`C6F=ruP/rsN=c5Gd`}~cr-=`X6?ia4!FZ]|AN
::N}cFBh0(Jf|kZ@ZCOe==zB{rAjf4pn+lvVEehy?Lm`tDcnWowO}My]2T.h5I^eI|?%g>$Tn{0r6|GlO{!huO]}!~;6{FoNr2tW;}-y!%zq6OQpR\>_wo1WSuxV<Q+@4mt3
::r.3vh,qxx|9nZ;jg>,iX{5HhpZy|Eu5}S{3H,RMsc`J*pRgS,n#o0.zyDH2;D*4-F2QBp{&G4(HH/9tvx}w8Ea8iF?&cj]!-Ddjn$/&x<*<C_1>XX5Bh#@\yX_Pm<ye9V9
::$WG}<}NMi0j&S5oAo4LF6Lzi9?T&W-6iUL-O#$./*y^6vo-,QMrU2?hXY}*]~d<*^5TH)rAt\U9e&}QYg|+~M3/qLO,]ry>{Bm\qf7I7c28iz(FAltZBEGP%69zHAz_Xp0
::EgY;8C`9rW6%e%1FMRgE`./KDYn_#HA10={TZ/Z2C9dq>0@?~TK;Bpu;r`{^;f;1Gx[;&sLJtJAQ!nOya$Go=C0[G?&C?P$[OdUEBHr]N,Xna|>hj%!&G4FyZoU*\pEG9F
::@|&|ogVN*8+~V$N]Mq!FL_xzIsJ;o}[0aa@9?DPVUOU9Us6278V0wKa(C1Rtst;e#V;!m?>+<1myCa`r+A<>q##oY~517uk-(,5-M12!a$yYN2SlQ(v2=F(h,k!Z^zs*3F
::.8u1b.-<[<M]q8C5ar^EqHV;bSq4vW8si4n7$FH?{O^E!Uv-vZ>,~JxcBR<GRxivBuaaF[5L\%S~*p[j$LTc8vZCNXf\-_%Ib|GoBZzm>Kb5mJy<*3V3c{gnWTqxXP4SxA
::^(Dy=*SV8I=uu@+Q(#hD&+<@U6&g.FO5~YYd3to1MP~<yRtx?gO7DRR~Pyhd4TJ75QQ*ORn8Smg+uqf4YpCm4sfvM>KgXd=})#``)Q?5KmP7=89S\|MB2hb%,>8?AZLNwP
::V\tU_1%a{8H07y[$1twREn8jvqHSCJA{@lMdN.3\Zj%=aFI6H4=7D1;}}ngkM\%nzKj<v`wzY%[,CwGLj}8JdKni{,f,p2}y{)nW^=;yuLo0|w3},#!\m>|aT=m3;gJZV}
::I3phTIS=@FM3n;l*fO[uKg>`;$t^H6?eBMV7N?=vb#riO8Ef#9C_xzO.c=2&V~Tw4Jl<7R@&yc{$PYTol9(t3A#97xQ|@I{b<qL?XPdBvn,lEAV6d$)lq/v&yGYxS2NW{V
::Mc5|NHH^GowuWT{(f]5q)nC*r<z5TyMIxZANFTf#LqQADNx1\TUAsZ7Skd~`pdeN/&`gJg;a`m%?TG-,vw2pS<q=7dI)YLadpiP51G%qDY<OUQmrBu~~UacdO3Hx%sh[s!
::<TI%Ilc`hq%L/<DU=S>_<z;v{xO;s<u]@85*~mIxu``=>1U\ihi%(rBkPZqGdyX+g=v0M#.j5Yc+|Y7Nb%VqeFHWJcIthsgu*OV|EVSV}]|[.~f%6r=wf+oRTpm+jW.@{2
::|ex[h|&yg9u+r-u[X5>-4$R\}y(y|ykI6r\XhZ%~6kDFAG.L,Q)~ooP`x=oTwa^;UiuW-8RpvXSut(T2s{7JMaf/q`V^JA]1C]7<9\M[A~Tb.~\J1WjE]ENMnt5.N@w+Kq
::W/]jFCO[c|?YFd;j/n1?!N+f7DIOdTG&Z\>3wVv1|zb21-nv1Hh;(0G@M#=;s31}c5IrI3^])gt=CA5vYtO^9H2^*Z-R&?lEfu9q3s5EHZC~n\t|\h]`w{!.FiSXILH(8A
::|m7cQK%WS2tG#H6+VVYP=J0l6#J1BH.?E2Ny9lX7{K;u=|S*_ZRLpz9ho*RLB^kiAfE|d*y]Jj?8oAE1rO0GJ/`#%`i@M5pQRvlUiU64&o!2IS}k=Km]|8g5tXWt~?~[#Y
::kJ#s&q)/^2~#ol1rTUe??G]]nutg^FC0p/Ir672J5cgR*\.^Hm>GTSl@$tE>APHN2e^b?#}2kW/J+6}RXnb^rvNa%FY>@T3<R^GF/&%1t+l!]AsX~[==6v1~ErUttL-c=g
::<q*y/9%PEk*QSJpL^Bt.=5&LRMUt3-^v0o1FUd]l]pd<7lR#7FTMq+Hz.Vg,1/>tBtLTZkXgVF*NCl>o*]nPY3#v|yVY/S|D7$[(@s?s[<Y,I/53gUk\{[.VKtf=c#x,nc
::M5b\GYW*c[<2WR[ERahk1,LD`_zfc\S8ZaZa-Pg.g&VdB8*i9P|9w\.ue2>_?r,)OAyzvLhO&0[DJ.L49jzE(x-|6Pcgc.I;Wkg&~>pSDQuiP1QCmQ8wUVhKt<Rn*wyI]{
::3QWPrqL.1(-0|#NXwg?;^G0F|<*|1nlV((|oAb#64@o#Jx^2wauhevows7jZ?)U!o`0Ev`pI@<[fnz+\+1kinnf4[!L+];XUGSj.UF!?%9mz9sUj%U/;m#{Gugv@w=Gc%%
::J/kYX?MZVhjJQueu/yB@`%aBh+G#DFZ$8IMprmeb4%\|@X`HsM+}&2CQ4<!dZda_To-\]ZTIm]Kx>VVH_Ie?N%a[I0s]FO)lXvbGjMHQ-qDZ`tI&\\b4]eyKQ{<%.vw2JX
::@=Pw><VihZ#wVu52W|[lHp$aCT56`W(GHP}Txnnng1Mu+R9%hL8\29M@GLpKW\YXMU6OAx}j&X>?Gm;3d!B0_kCYyEy{X6Pn/|OMy\87FN>\Dc^rrp6PgvYC2;*rr#OGx#
::,N7xt\T5BvRkQMmj1R4H~iUFh>^-==!pc@\U+]TR5!,juh<=npjI,D@`Tg<Y),N{BA/6`*TL?;W^`$&uJh^0,RL<_u]5=cI=[3Se<Daf~hS,&c1zI2hmcdE(s0b4}B*Blu
::4_C=VON7}tc5>5C98~@0G-@063/;]VaoBSfm\t[9r`zk<kq5.V]wW6si$(XAQoN5%FwttqIKsj^W9+Eo5ky<rYb\J/Ja0u^?w$MsjHV1$F&At8Qmp|]l^IfbO*19@>nwE*
::p[Q,PBK@SxhE[nKw*5^ZAY7221-i~Ore]B?Km3PVGLLl1f@ieFX1Zan3+13mR7AgFwS%{#$Sx!a}^f!R+o[E$G7_JF-`YjpG$g~SSh!5};3rrx>[PZcJXHX}VYt~%pdekn
::?o}hFJo,6|gyXKpmtkp[g$@-,YuA16~e(dGe_cmDHap[3Ic6C7&#)`O3I,oZ)yv]El-W;s>U/qT1hY8JO<IBU>.5nD1h>SVJc6sR1TKA)2Ni&pFFK|n+BX3Kt%3`|/!,gg
::)ZjD/Unj6nk|q\(ng-@!8A0M%#XieZ+/MHV?2tajaqjHF>/tZ[znl%Fj}3Za@,RX_<1$Nwee(+U}UOiul_NWL3zk%hcbQv6G--UwefgON8h13{/RwI.4/S^?q~P@*7XYt1
::Da-W`N)a}nwFoctvAE>.tv`mS3|`KVd<BV)nq,z[_SfLn&XG|n@m1^EU^j.lox{?hA[m<#<HR@4/V}VD>h!v~=b9VejYgZ1SEqh*SfW`LkTx<DZkP_,xT()8?s=Lw?yZjc
::Ws<;gprN{rh6##WkjX$+[WSy35iWPpu3\`v8)(>?A]vlzWKy.~{H=I2NFU=C.$IN}Nz~>V)nMd_Mvdy@;yO!~^aH9Omk$pxMCg(bUUGo$$W]_p8p6.?42ArtY@/yNh|u\E
::y|tLsooDAIv[;sG>zaL0NevAGZ,7x^qp6Ar1fm,_UB[$|qO8p`4Qu%hB$d]D6alAVo&FuoFko%WhlJ;yE>rhufv)vdKp!^yK&Jw.VF)OO=jH0+S9hq.s/_um#r)xYwaIE|
::^I$^,Dq7Oo(ID})l,QD2sWjHmu0?wdZ>{nbFEk<B12VyqZA8f(V.cqXTGT_,Ki)G_2V4cl9knm&j&@[qA[52(-q3)8qj(xrS.iU-3U2-)I2S^ON/<8A767d\(Mg+@JxR)}
::L;@0ni*>3bU?I3$p#gF~MK{H9V8(t1i.7h2%rbEyF`F=p;.%;18n%mwI.>2&3/I7<\d37_XAd_{i*bw>TcI6b-IV]CjTR{G9|#zU5[{IL-jaOof=<[Wrc[N=l0P^_m-Piu
::W=aUi6(R5u1p1M$I{KWTO1s8t^^*9ha)1XYqVvMugO8!MoW^N#6q<^GcK76ev0.9qQv%A8|FiX`*/x6<ecp*&rc#[%Z\\uF6zYfypETg$|E0/00C2[1Z[zt%tkyLyUzlLA
::XO-ie+P1Vu}pbC8+>r-udxj&TvpEk<uSsAVq<UC+s+FN?L>z1w$x!aO7ZUM9~q9GKlVqRV2-&eR2&c6<L0l@[X%v;0\8Zs1s4Jh;y5*_5nP;@!#j;VadJA+T_a]IOcTT;v
::$>0Bf>!ypR0R1Rg!Op]GF80eX4/L-2V1KX/0D8#2KI~qtN!T<k93j*KLLza5|F+9%kt7gD-dhR3U,g;{eGpm{37-1OSRlT9Hwc>#oQwMz3K%Z9)5oXqQ|Lbz]5!63_fQ=H
::h911nU/\M&t`wUFP<$szW%VP;<qCS[xY@3|brXk4|sbQ>}[5w=cY&0&9V@pNUxHm{b[MJq3n!&&K5GW#%oDf.[?C0w7&ME0eU{hC[nkqCQ`&37#?%V0_#z%s(15~6hV%l/
::jQx\h1S;Qm1][%/(f!)a!{5f<SY-gt.{Rf,$#d;op>vEC_Q{L@(=3jqAgG{v\Np`e+rt.`O(f64%O`lNbl^YvE|N4V[/iS#GDra@%epaxU<L*s^Qz<Yk(gZxMl6(bBs6Jw
::9lHUjl0yNv,mJL/Oj(I!D}UNn&bS*?1KR=\pWU>Cv<{SPykH;c1*]ZsLqJH*dx{o^wwxeE@8-Cmb+z=s`L/g^oy~;)R\|]zlHoM=h0.4j>K=7T{n{qA(SHIucDSI_X|}ow
::AAL(8KG,}G%aC}Eqwn6.o7YKM=Zg)Vy,!3^,d0CvJhF<%KY[ExDb>~24[O;PB9!/}1W}qe|-T|;d3Z@3n]Q#<x<h(^+PU!4`DYc/-<,L/1}-iV|<,d5r_EMy0B0E9uS{|M
::Ld-NSPu]AGTWeiz/*_o(7.?U(6%U8y-+rbt+>T^0F+5ZxB@4#nUiV{GncY%4_P7zg(sfRk8)W+0M8{WpX-M,T}{Pj{o1G]&vLW,;.Sb_mZRgi!#k-TijROt,(Lv2wis/)P
::eu?]j%Y9YHpFXRwhPQ&;85X`EZUU86\(w;3ij#w`6knJ]pgY~3e~#L{l73dN?U[>Q920HKZSd_Bhg7v?_?sN(~aXX7D/-%rRilhsk@~,4A1i7?]kGZ-AF9c\2ogl]!;-\-
::.5<3h?hQ@<8JPtd/o\0V`XVTS8`I0NZgHpW,Z{HoI2P]gb!JVb$V7f`Tj3+R$^5{RuF9&_@zbY0s2F!+9l&&jFa0hBp/])y%o*y`=5z2wf,KXp*r_qUK#9Q]2h<%4CK}SW
::g&Ta9vk?.YkhKYmM/,{LZ_]eb`RP<fN8znq@b=[|g}8cUWB_&ldMdeHQ$TNy?px%*3}SB^|iK9ChW?)/U/}lq2x-N^GG?GF}M1A1n9x`E>jQqTw813!QurU&BiI/&P]MCt
::M`k)kU_pz/o,=S,gLUa-+NE,[.CXR.c<@kh7mxDK1?PJJ)9`[[S;CzmR2<A*NGNc([qS<H~wraUiBg=\q9fB0yorFuYu6&~k^th=z_/<LivrkC9WX_*8vKx4)WbzN$sTO*
::\~(rmxJeO@jezt[Mdpf;Bwfx2C8z+|cjTxv6g[D]~Um\[~&7^*CX[/[_=jPew+`,&+l}]@kkBZ#O[b7_r*I-J#A,;#FPd>&^%2AGDf/AhY[jVkl%)0`^g_d;/B$KPH?bSv
::`OC][A%y$+%O;1%t-_74@7qEh/-!6Ox,u/}J3i9<DvR2t|%K7UhN4w0Dgg2c{-/M#/!0+$c9SF!hwfYSk[\!\_]V3d^X#;ru3E$<L\<8X-xQ>sKby#@#zHRr%t#_.~RB1k
::#f\!qza&xA6>*I4wg+rWqv##LZwk=%{U?q(#xlG+0r&xG^^z>}@FFj^e^%&JU|7le}]?x_#EzY1&5wMTGxvU4|H4tH&g)7No0&aX-=d5=BR$Jq0234S%;T${V8zU0ZL^9j
::6l8xxQMU7ER&Nv$}S1XV~4K77}Vpv=>W@-y%m<=-?1;Be32lFP~~$6HBa9i6a9BG2>!g5;lFW^w@Q0v!j3.icUBmsfB@m?S_[e\CBsUah%M[KJ/z,V0Id{B]i!uy,u`,ay
::t[e5?3X*!}CuLE98,uC/_25>?=K[$;r-V4E1OCE+Ki#?YapY@t\~(=8FRlBz(cT}%FlFBW0)2KrlQ_rOLSd3p@z~Dmv^.Ccr<l!<+n^CVz@2[v=hR0k6Naxls1_#FWpPD_
::l[S9NfBHy1-#\bCSYU/eZNPp9QSb*T8NV1[fR>lNt$9}sl10q)>mJa.\rk_5kh`opz1STKe,?*W}dp_*kRtsfOyH$fu&}b*5z-\mwSU5{xBHL*Xo!YBxsb-[SCOUci`S58
::AGiGW4&41\QI<}sZDETB}wa[I@TmrK,x`}fnV5Eb.K;P<-|(~7{lFNCRhTxL],3eN*!Bt/NK*Pz*>;;R`iVsoa/R9Qx=Z6+=[!OG<[U)4R9fd_$4H0`_]3Z/AXf}nenaBm
::;T>K%P>mbmni~|8V[efXlM5=885psIe`ig-vM1Kr-k#=pcS`,o7`j?#U<nxj|zf#gz8jQlX#uK6OH6{Bz-sDY3O]MZ,TV))Jv8%2V=pJhB(?eqIX{D]Q>VDggY[u+`WuAj
::=]&j>nu`mXvdG1+~+0)6fVcy#D`ir.y{`eT+D>LceL^rfKwiYfws0!R3ZpW@1ep*Yf)@2<8M$@9.k6TV}Z!kU}l3iBdF|_`\.TgYt[Kxf/t(/wI`nJ]A2{b#l8{?pr*$ph
::@[;r_t27$@&|e\]T-MeV#qWx!Jd[=1|+WzGFUY^Hq~8Lb*~X~^l)AgX=Ku,LR1Itf^}i[FP]uIL81{wUlM.X9w)iG*U!ts.hJPl]C^[F#IPP>1$OCZw&&?GGJWSZ0Haar0
::5sfge5J(}gSxeGlsh(OT29iw?Wf)MBws{r}kv/iJ,1Tc]A=NdENY}vsaP#IS1ejeD@I`d7Kzx49e;h]=vp4S/jT{3>8KsRDXcwI3!EX]`Ip\xCb<l{bt{.jPeo[#{p.Lz]
::rQ~1Q/tBBU{mB3e?uyUjjtk7hq5PG+7nAJGC?Va7#unqFC9O9P\P}F2[voJ_csD8@5}<I53Np96>0@X|>Zanzk?H8~APwQKN/k;WxOr8(`{8/bAZ1Z#`5@P64X/+Ka1=@V
::N?Wk=.3-{w>\Gle%qW{UoJ24C7X}A5Lnq?}e)xs0(<Whf9W9K!(i4s}CxCfYf`<w12t?h}kHs\S/WP6P<aauJ5{c6IX~p43yy}ha1sBnoE-t6<y[u\TM(k1SUI@B7&sT$7
::H,Cw]-a/~+kbZ?L]~7x4J*fY-H8t+Rga\C\<<3Zd)KAbxjaVH~Q1;W1n~$sB7*WF-bK!2%IqI-((;MSqeB_feY[&aF5XKXQAYXB?z[gK=Kz4lkZXK[q{zjJ/JSO<xX^^wp
::`Y9q%_p*/2l;G4z(IpKzm_]k6Z@luW&!o|x58NR#^n{,d-8)f+}m-Cf>BD`($PLCGjG3uvc,IgNi@{%e3Oao3_MH4sq8f?S@c50jq#-EZaF$BY;QtU9L0iyY_@tLQ9Qweo
::Z6TEM2;p|,EHucK%$d5L`%krV}cV+#RoTArBe(W\$8y8Ma)xzQL!a$\.JZ/`UI3.tOCXPmaB=3B=z~yzv8@jilb0\BJhg!XJFy!|}DWliyp~0tCn-hyQ6l0`f7]2uLdeF}
::j9KA9h#<8}(drx/0p&>V|UTaOifKAG`pTF@-Q+7<`Ep_fA9p>L|O9PF/X@L*^9%o7?i{a|d7W56sh!.*l/vIgAla?eQh[R7PD_?2L1c~%&Kuf&P6MkfV6IU%5FPx#1,!vP
::V_p{FP$mA%?MG}s(9y!#MF#nx6s>lZ`9iG]J{AiyfXsT)O%c4A,f1~)]FT5cGA}C@0l&v?8j2NR?q*%OpP.stmmlY%#cGeYZ6x?|Mpb/R89ZGMH7@IyBd3]h/ng,Z[A81Q
::D2}#J%KI+?`{[&CX0o}vJ\~mnUp$-0}<P_4uYNvvWAWe|^$0X,/(JTUmvXq8Ix68eiv9gDI#U6},Wl2l#{|*Os29qOp#aR-cEAG0J=<JmArCVB?t(|{n+CW8H6#_%U33~e
::`N%/k#Ayck}&sqijn6d<{PN+=(F?mJ;x#o3;{GkwGo?^RujSP&RVUXIGk6-sVXd|F27,c{i*P!XDuR/)atCA<<N[>#O(F1-=O+1|>qhb>V\{EvG7.FXW\+VFCn1jB-iN2@
::JNg\E_b4#B2GP^<=*Do!mjUyO4xJIi+%`LML^Eq8^h~!gVg;EanuRvoMC+_Fj?fchM,t?DCwi\0)by6sHJtXcPLFyK<aw^jRj3Msw&30J+tHUv$n]CcKwzWjNiC9ARD86~
::WTO}(uS?(|bWYl;.~V5[2F0)2HZucC>`ReGA)HB0%H+jaC=(r+3xNPZW`4sukigOG;,twxXUvHq9eS@pk;A&ciHG5hqF-pHl#@vxQ!%OP/+[yX+fn&<DAU3@u;HN_p4Z$P
::K(#K|pP|wpP=k*.i66E$vr(FTW?}@$,\.5>d=A0}L~%<yjfRkny%F?ZWbsL/4;&Jz-D!wOqD{A}1FN\;JO~YuxJiV)VjP_B.==ib8JWa?pkDfbE;;cSf4{`#R?VZTugR2t
::LuraV&ZYsq8OxkHjPO%$|In&^Wh~EZ-UAz%*ep50zC*,YO<P6(v!_dcT6]p9MpM2FTH?*]*pk41V8(rr$fn+bbK&~v;u{M.9zZkc!df[}9-Jb\yqTg4iq#eQn=Ij;s*GYO
::$6Goj/CES8Y0G8c6f5O+^v#g8{WhtBBr.UMv`U4aztc4iJ|rs1J~b{*~MFBrz{t)r)O@]C=iqx*]Cui)KL8[*\v?X7MjM2;o%@,[v|XA/A}XV1NPZ)jgvo3/b@_oNw^c#I
::bSob7H0;+D*e210A)eU*!yYj=^&X6Fw68mA$V)eRPc-M{o+P/*FKRyJs|m0R)6*)y~lBy<a%J#oC)(v2iMRsHA%MmXppQIFh|xd~.7Tn!C%&wdx3HM8uOfv5`atc?@y4l]
::2Cmt_|`p&8&T@%y`)5MB9Y1cP_x3vOAVosi~`[;09Xix>Yf&0Z[M0_MF}%Yk-Pzh+UorD1;pH;UamKyy]qTFh0^%Jzkath+XCqjCL@3#4?5Dn0/^!Fz@GxlU|9vk?zsDs>
::-zsR[Os96#q8&MdB+)/LAm+\zNKUGoa9WBe&/er&IjQ8P~1OZ^tML`Og}%b<l&TNQIj}8a[zB+Ob)<\/ATC}$9yByIia[{F&>B@/&E8`xxU0J;ZwCe9SW(W8$91T+H=Vc;
::>95!?T}O08%Pjl|Uyd-3f(.NaK)Q!b]-gupjQF18/%?Z&ng^_@Wx@/PK7VmtgQ!cT=|KR!DT#@,v,{+{>lsx2U$y@37g\85@ehD{oL2]he=1-IxOJ~>oP&jnk8PB3m[A,d
::w;Uia?KWADyW}[V]w3CJZ[xrr&m+NYO27zlL`aDUkxd+E5AF,}QeYQFA%|z9lMx9+$~*?aoM/h$=_dfV2s/tp0w(2WoxVA!}jpU+%spe@EC^y6-l0E?sT<B!K-c?BpBkAn
::v^)j_9prmm0>~hgu_\90Cfi[Bh3;`7dwOdGd/r;45/q$d~8Oyd+T;,~[/HaNEWREQi+k#ubyWZ$nj,?WAD2Ig,mCamD~;2|zz6.;uPfs8$wQKuRnoeIjRS*Oc7#-_Oy{;V
::&n^~vO[wg%\pr!(gTm^Ez)luDlfP.S;Lh<r}WEMhdul_D;8)+r[[SFEKV;,da\&=*UtgHde?ey1xRn?z<i%A);1u*_[[O*~_9;y2s=L+9Tn_4M^vt}%kb}*|%+[ZTlzN;X
::We1DWPe<iny,pnb^;Z^1(*sX10aUun%KaJU08A7,0$D]qg}HI$rEhxel^BJz~T+le@W^8j=f{sz;F@$Z}clN5*|z;o4]U@=eCea&76WDY%cI\S~KV3a_ps(KLU0-FEB<za
::[=a_q@nTM;nOOJ&(IpY#?V+;|H}8o28nLr1(M$p@4vO\/r<Q{>;J5fIsHAiKtDCGmu)o=ZxWP2383!lx$BmF7U=D.)ehU&{|Zk0rpF6n8x!#H98K/C(vy~\_>Akdd~zBGG
::)Mhf(9q\nB/0(2M|2)TZ0+Y2wuCul=h\@p[%*~9/SKm6z}.Uni(4k$Z0LlR#vN8?]BzuL&,-IjD6?T|ke/{1,?I9BzKlW_Qc_GT?\fm$6U?<C,kpm5Y3Rfo(L1bnsEDVb}
::c9<+jbG)NDeAd~1/pN[|8em\|E;UIajqELu4>_#(bxU#0sz+u^0B8fuGv2LHWv!vxgNuY#R]$[=3oR9;4X%/OlwQ]0wXTWU]tTD~g.!~Rd(GjB~-}9<S*>FX>A+miH17aJ
::<ryfb06@GxgCB{~6YWET5,_&q&\KM2nOf[As?Nm`lj/w%z$@>#oz-8P,>)M8ex|fE6C_{!=J@/Jo~hxF=uS5C/U$oux|u4|uvtVFBshlT=GWi|iCy]45`+m8B.$+^v{q.B
::XEpSj\JwEfnIqQcv7/B?IRWD$d!E^C1,H#y!<hQ[j)7<vi^Yzatwn)zRd<3\;j8#8/>MbMER#hlxw2cI#&gP=c0L{-f{$1Y~{<Ar2P9J#!z]242ZfPNP>RmPavDlwIqjlW
::iBWM?(DFHII&Q_h3#]G%9rPem!0e)p>AY=TM!QQ0~\t.,\yggiWm15h9loraJBd(xK/Sv`{HPX~BpH>(~sR!M6&!T`;V-+JKUk>Lx9)qw%u1wi$CqDi\?MJsK!v*$CoTca
::T!Evltld]-Gk/n\?%x\y1eY4UkY?/JPMT|EM!`*Cr1+k)rP.PhT#(ITZA=/xQ0qbr{RYRq6KjVRUDL./^v*7B$Ox2]?@cGn{,@+p++uO%C)ZQvQjl.c|_Ql@^d,5{ccU.B
::907/qW/%bl-,oTw/XOmS\gjOJmo{Mf]$]Rr5HUgrN}WRIZYHE|U3m*Sk=}[@W01c8B5FBRr.{J[jjFzIV<P*+fWdj#C|~NP,;5^35_#Xq,#%90oyZA0vlr>2,=64lm5vs(
::AS`_U8We-,(%d=dx&zp+K<]y#^I?m&y^JQ{9(D,&p`7ngf-4aPOEALGXcF[uIOu]gAj#,e>8Cj3O{en[#+=o+=Vk\Jc{}q/4{@rnwklbF-g#%&g$SrhX$8XG{K{.9M^w`|
::k_{a7A8]v~.Gb[$|`fl-Q@yR/3xP$OD&$!HV^O7UP/SqJbjacm\<ZZr4MJ`6[#M?Nr.vzQGtt-N6R<4TU1Bgg+)I!m4?Sl@9(VbKf`uF0.3[eS0W7T/[BF|M%l2oP_sGE<
::e-0GK5EQ[wYlJy|%7!~PH~g$QJJEbOX99*+d$c\p*9(]7K-hfuoLPv|(d6v]{07@}_%LNw4%_8vPfx)I0|sX)T>13M~.{pu&yD}sQfq]r=M;bv|uT^c(DMp~I8FNKIx+Y{
::SC6*H*~%bm7-[;R<5az8@3l=,K,m*8`~S@I,2NrerR>@BLY)7Q!`qs1kUtxae7W*lYj?}I9O9O&_yB%}-`c@`abXPq!eKQR)c9-E5ve{Q4uOaJ<cT0Lk2AWi<-q_pyt#1N
::$[?O^R@L(6Ja!zIE8k?7V2QCc-[@enHnHf7-dp!lYRC<,=*FE}l(bW#p=V_Pj$FRFU]L&/=sviELL3F@_A2h]},v(gw3H5]ftnO=?|{qDuh^cINFr}zFDwehDkT2)[Cj=o
::oo^h9@suG|HjMpP<Ss(j!8rr!(eW-r8Ly|CfVWfiFF~9&x]G>Z^QtF/Bit;m6s1@gV|rXHAkDxI{K>^XzTyVl)4@[KU/6cH3[^]bEwH{{Oj#2t{#FC_K(B]cZ%9GNP8^/I
::vj.Sm(K$7Gb!55Cb>!*1oH9A%kNB4RKG0HaW/6GrHM<S#slKRnO(IaiQk/#0purRa+^8}aa.^PH,nRFeO|Iqh`pWB0^BW(X~v3vd)m5Qx+bc%J/j#f+[Ed<]M}|Z-z2Xc|
::(YcPXnqR9rS6kF|^%g-k>4R07pZ[%}k`MtFM+,PuM~\5;*Q28uhM+X3VnV!vG()zCZb6W]9=!]8>B3II>%]R=i}]G]nN\kDPAFtd[m]9Ml+HYee.uCp81=%x?fTB9p$6o6
::-1aGk@yI?a0fQ4}wKa2{2nfj5;xlTHlxBVorBS$hPfE;4sB`ezKWL$QxQvh%t]iyumjI}qjW6C,U-u240fEGeBC@O+95=<zkOI3nA)7xiU\]vc2#wb2jvfV|JZ;Q.Bx9@;
::npWd34_=kC;wQl|IZ&Ss_&qbd/L$x`NjpVErede}m5D0BSp#u@9XmLpQ1i@[!G^d3?wts<m)m(BW|fJlMQcBV>EDADeY7E<WIMl?KY>?jTRJ#V+R&n6,Bt;IhDR/N6!`Yk
::+z;wNhckYZwDK%gL.d8qK(^%qVwhWE+K2.F3[w#WVE{nK#7cu6!LHZCk9xLJ91O\>h=8xYZKqvXHnFKd~rv?k!G4(hOgL5Pr6MhQBMn&sLYK(G#DyE#pcLjbp*PS&Ul0-d
::X5Du}K3x87%t&X9MeHd{JH0C;Sl+zxlQ1UnIuuF$3rdJ-LTxlUomtI93yS?{Yf$NwS)X4ekh7Y?B-Q6;r@E,!06B}!\r9ui$4P6F#,lbMwFKj|mrJE)O4//4oV&mizBe=y
::=k*,,$qJ{esh~*_8~L!JV+k`a<t!yAT#NP#Z`d.UNZ@M$4wzHoA(S.A[;>_ggO%62*AzQ~BOPW\Wd\7lF^alXx_w]Sbyd[dznM~k3=Fkqfzj9aVNT%6nwT0|)]S)mT{M`K
::TQyCR~3y>)PS^^P,!t/Z+A}YjU\9Pk3y>ZD|%_G50weh<[XsVj@iZtbg+IqRBy|*4^.</}W`M/R7QHx3kM?k\TDn79Zg8W)#Ll[QL>YU0=jB!6v6OusrI(zk!\P(~&T{*5
::YxR=tL^TL#wOgAH!<pY;bJ~$.\kJ-GMZcu;pJ9aiL;t@6n@ez{Go-a^u_qs*I.|~~{HW6QX9P1kef?k@@!C)pwZZvYTHQ806~ZMpFb9Tie()BlL)>W0VYmoLn]%(>iwlU_
::qZj=zbZ5&!SjRC;KnRW$AiJP3O@oSidMM\LcN/W{e_A+;;{0vk8q[_D<;Nu_JAf;a*{XU8Z$<Ny;yW6*pRY3dk)$[6[Bf2bgi}?|5HS2B+Tg@S1d*c.jn0N-NAHU=6;A8\
::_c>GCy5;>@.GMS1zS3ch#$OW@n+,p%$~DTt[!N}/Ip`LK|HPgst&9dgP0$3!<Jsj.e|5<-~S!p>f/vAJQA5jX0qa-`nC`j2BM5rw<)rk{K7#<6f~61O%NvkaQa{LCQX}?X
::{&C%Fx)MVmKmf2`%2@9,=8(U.xN_/?w1Qoadz{-RA`91c)eUdMQ)ML<0LpgH*3RX4\=\!vGCWKVz;Is+UXFQb!@}_d{lKG>l+>3(]!#T>L~a+5kwimaT^4F#|2kHv_UMj=
::eB]=abmB{%R{jlJa%#OpezP#4pUQ\ZQ1HSykNy~z{mQDgU%FIK$T,@eJD1_Zb!]owtvc55v}myV52b1oAp!I8zA5_OvIyYel)g3;{jDsfZJMh*^+T@)5[Od{;=I`sXZXfs
::1w0!pi_2)-]&r;/~[O+3m@_@vv]}SS^cL|}<ufZ1[h.{pL9`+AE[#g&SvSvRaqRqd(}g5(rD#^bkTudb|0WB!OFu4y<JJ\=2hk1lK0hLL/E!U[T?Z([;5Tm?MTnrAl5!]e
::GVp{@K$?q|!>eyfcn=hdOt2eX;8+Gc@=3Z!%{p@mK)p!j3jDkwy81\oZIp3xXn=&U/N<KzwT=Fy18c`3Ak=N=Lp|+^ryH(-@Zk}*2(i!Yn6{Ar8^1c<uGQek6+c@sx}bGe
::~\=Kd$zVkCvQ@`6fajmz)c<Sa6b@9HA%mw;GJv#v@_5Z@~V65<-=@MQ=UQ*dL^HLxR?QzXEy}!BAo5lru/8I]Fabp_RN9K,@2rt%llcot]Q`_Yt+?FX]#`!HL<_a_,~vC(
::rZkd3E*d4fOBf<Qt,(Gh0e2N`2*s0F8S{,OBHgO@k<T?_h.1>0Gcc3G|}W}E#+?j-s2{xQe(m%&|NtadEB?4JM;D7x!4^8PInyXQA*?jB5TjiX^DUC)H=4!Uf77Rh}%xZ)
::V8ZYw~uR~.#|8s/OmM\a?@-T)eezX6b@eKp7jlo+TtQ}a,M=rQ5c[Usy{eVs>fGO/VOfBk~;t]z/jLp.pm{uPxSHIB9;Q^@TlEs|nU\}mcyT@4qRT5.bm8JUS)~8z;Oe3G
::Dc*Y&@|Bs98QAyCQ_,Lg6g45i2WeVWd*wa}pR3)/rB#@o~Cp]5f_R@hWoWuFI85O|l\n6Jv`{V?$thu}.i=taVAb8nx,,^!m\nh](.f{R!WrpW}h;5rZ*VXV}\Qmpg_m5_
::^iz1qasG-9rS{\=*BHs-{Vo*vNdh]}Uu&KI(Il7<M&jjhR*V>r|[K(H\hCw(2\[0I9K.kn7dmPdpPNDH]3@y.)WLNZGTK!WVHxG/*8Lneg=<p1SeN]njlzB2*&r{Y?;P)A
::oRCxmUICK2-kuHf~xOo6Ub$WFHj{aeHFLa4D%g%An-b;tdD2L_@ty<vuB##4Z%T&+7#[mfgeC(coZCG^)D8*CGD}>ri_w4`t`vPY&Sfr.S,<`(^(RV7>m=H4@KRa(r`)Ew
::1$k;94q(>bBXx{-+R>aM-Ox2,nR-(RPiEb-c.NK1Ia,Q)?t8BG(@.aL$)>)<O(!XmgB\if{Oj/{2R`GFKGozJjJ!2,$/?9H`3w|(D$h\{c@};q`B7iZMn+j-q~1-|*H,,,
::~~goburqKUu?]LCQT|qf[U)Z5|$9l-u~l/bcH]l~.=UbM@4|y9CQ<&m~Ue~XC;YX\([A5t>wyXz7%ATiGJol-;@4%ZxY1f7o+QsL`W\HK^(/ByLiP^/KA/X7rXej8/v(.b
::;RJpx\V/<!Av!PJNVk7!?PSs2juyV9BUby|h44&==C+u!KBzX$+.SfAU-biL\0%2MA_e,&TZc6Fx_o^[bk^gxkz4&2)IPw#32NkhSbkY&WaTAr*d;zH^@q^hK4a#/E6uH?
::7,{3_T.NnF}kKnR+AYr~KKOJ;p?+i!F%y%R)SswQEItVj6TPAsUV}3RQ3;-s$2>[pXs[St/,Lyws%;_Y2[r6#I#*w*z{Z/uCF(%\8n&P&=g^19(EK;EUWm9OtS[Hd3>#s7
::G<45~)lMaJfvK#-qS^5>AUmVGBP2g<c,WBBQtw|=m#9lDTzWCJ[Xu5wl$k^$vpzt\jeIE_]&F;yX*E8o(Eq%^J@fPxLP/q_i(ap\f2&3$|e?%|$\ry/[4p_,0v7n/qF.(3
::g5\s<HXg/;~7j9DH@4xB.w$R\k623pIPfCqrDGQoX37\h/q_jYz/_\A^jsf|R^MaQ{C&g,,\TE&/u-e}sW?OEL$L;Y7r3zul_9cy=5-+Mk&RZhA[p9.dTG5~p<LfwGR_{v
::prw_2]+#C%nB|qL5b@K.%8JlToMlw0jN8}`,G~aIlAo)60}rP}rn$2Sc\P_iAN%Ydc/L6_}(*b>wH2QL2PPq~\*[|nTkt>#ZEF>O9$Y*EG\^_ReQYedNj0b8jpd.q2H`tB
::{T74Fq-1lcjw&h$`Bn2|&B`jyMQLn?rxM^Iwf>~bCnl}O}zA&3yvKG!iZR(;hh0$InO{*_N7M(/2xS_D!\H;RcnhcP^Y)gnNAm]-W27NiN17zit)rmy3>\+0[H&E(nMkV)
::31/I/((y(g!`]TT/zr<*n8d$aj_OL3BcGyy1_rejg?2!wr!_LF&wtzz6VrNaFmM7`=pL5~XRb>Ql(JGGy*RAin$viY3>7?EZB2Ny^O[VWixU,m}/7B]?S^f{<+JFEcfmTJ
::ki2p8ebR=}WA!&p(Mn<pvjFxfnfX}_8Qf`c`0-MD#QkgXVdoL1TWuFY+8nj3\=>8SFd,5U$$]j$gWSbQ$5b!,dY<IMxg*7a{.Ar{+tVw.4K8;BE|%Bj%$_ypcWe@TG7HWN
::WEA-F<SCs/*fG<;[2EVCPq\;ao]*0Ep7e$fJ[c}}^D*{K=h=\(_{70jk/6[hYK%T/BMuq/iH#g2P?a.w`MFAN+V}z-EnUF{v}VS7$B#N[Zc(*{__Pu/[).x>5#;3~3RDsB
::[lDM8a0yHM`Y3V=}OXeM?V*Ag`Vr>R2)!0\}HU[Iy0E84#90lk.05(8}#[zD^_yQKRb0PfHq!wI*}<;4U1FdUpGO_gz}%#jNf*_{KC}$Y75P~3x2VVfJ#e>KR#rsM5gJRk
::.~;-B4D8})6RcTf(h{[.Jj19+-OLBy(p7FBmXAvtQv*_vfBmgm#M5r4=*mO3?5dELJ#D)CZ[t;,J9V0InAM23JJHOr@p`84d==5`H?Afcm79pH^f=`>W5QN~-yA*Kc>qL5
::{t6+!<O4jv4-49`,^N8U/dxK#]Dq\3@)jHzQ*`oE&G`&$6eTd_9lgIg|uI7Z\l@JEV<E1yl!(VPRKaQiq|ilnK~]d}h<~H$($Y,,ZRbE`5xXLz}*VNYA]pF7~u+_Z7d+bI
::_8oGBHm`#+k1IgQ%J`dei@l@P?V^v?.={!_-acp3bzcKU40tB#qkg+u_A2-)/KC#W4a={i<@D~Z5`~Fumi|aE.u-MB)m$O[?QyC<?O?!T\*xzS|WgifsDwn=4|\m^T/Y1Q
::=`-Zc)DtYC[IjIXHiX-q[hjf{;f^T?_Bj=rF<v.(?3BaWZSDW{>1`2#X30@@~5i@@3m?L<EF12`&nrS;|f<+oKUpo=tp])Bw@RS8[%|/AqE4]D1|lq)sO3tF&INOL%3ya5
::C7GuxL2#Azl6q[brRm0i&#yZ[.<D016YJ5\4cf^WH)5g`$]IlPFZcet/1NHjW+S[wf}s|^RU;eOBJ!/w!7W.o40X^1b|#Q_18/oL_0705j\3Kcp3GRR8@~5!T/HUbyZzYD
::8TMOtrN/fO2g|W8^`2bkb=x?j]sAt^x,&w#4J1erWo}Jx&C(lTG6{c%3&g|9qWGBqPsd.*}192-tU\p2.>E^Im_g6fTz\u)JTwWh,|Xwi01A!a5]`{yVxH7p-I&;GpM[vQ
::2*8P{2~KVLz3BDQPuz=8wYh)-*#Ci&R7{z?tGuivVn^ESH!2<(7g&Q7x8I];GaVy!%2As3_]qV]A^+P1u|X=@V,e?6A,^9Dx&<x\<00|n}mYvp`lZfesw6;&ssOS\l4mc-
::M!rsVYOvEGKfh11~h_?)?^dQl{D<B5(Fqk*~luZynnR;QVDU_9Lbv];5%>nX~qPVquL[;gY<Qgb|pr-D?viRl_kk{h{\CP]OGOs.iGW;oXH(j.].oH^jm0;#uUv_!Ak8@b
::ti[R@N1~c>vBHjr2tBd,o`RII-^$sfSQye5TlvWY]lo/-N!cf`u-Qx.`@\Ly>K)w_FhRM2l@TS3n,JfzeUv6CzIETbusRuGQ3|C`?`(tPLaF@9K/8%?Z)BD3J`@e_RKfe&
::>6Q#}^#hfCNU_v{S+pX{R1!z+p};ww}G_z8F.vQ<|zw{#>yO1_7Vpm}eD=pCf53jhW/{<#BHN1r)B/po_w3qW3AUp5i/.?U2D,K&SK@gg7.{Q_*Z@0P,qVLx9o-DqEX3$g
::N7tRK07]f]`GQf!a+/Pd+2[&B;wb!O6lp{6srf=,m8i>Ul[p}0g.F99fUtgOYqo1{+FVA9<kbyJahNR=#FS{KWUln^3xX;e^$0t}}UF|y3EjJLha5~R(I78@@j/ya$zgAr
::gF9xFR2;=Op/4e>_FqX|QR{gS,FM^Kp^ooXcGUl^1VEw^sjqg[{Yw1NKOk5fP\<c<X;hR/H]go9QutsqeG4?+)Nv&fBjBAy@(Bh!6N(^{^~x[L;0v+zC?b$98$af3XPIYZ
::T)aLD-P[rT\)<}<288cm&#UB]O<GTV{?OD&[prv$3j?QiA6L%y>WQZ89&,Yi743ZFLWX6Ht9m=j*|I#c^C@^GAi?ADs<O\K5,tbaCB+Qof{Wqu|K`zo_=D%(Wp7yK;)?y6
::XOE6Cv.mZ>hq54g6!}oU1+pE)43q^8A~hW3;EHDq?l$493F(!Vy{%${H|ER5c_1?/a>]]771Y&,;-lTh<^;ZB@siNU;/`A-My[aX}1\f*ZQ0r-T!k*%oCeNXi<9DGFe`/a
::Z?`L3$3O0UNwD7uOxC&z|dQ9i_e%LVyaXMvwb[t\~oS-q\>[{p^e{krr8WjZD{K%Tdkt{gKev&itIK*7MPM.T)ei=lS,J@DUgd3ui!oYkE9`=8$WfA/9X%vT5]iRs68}XU
::R3Bg9`[e^JNazCOv,GPkEPX)Q~Fd.dRl`Td]798aPR8r7F!e|c^ZQ)0k!fZjsg/I~{w`+A^35HY^D6#aP$6vJ0\cMo\O$qSVIL)sOd6ix%zw]34A?j^,m(!$8bPBU1Ld08
::THCZ]1r=^ff)w-r\.V1ZVrWSl2&K8~W(9G_a.jt>_hddqkL2[%\[q]_r3iXzqKiG4S\mh#p\J4rf7|m7e\/T5-&[7@_UN^Pa2s$VS^5JY!oe$*OZ2+`Z%S!>6@7#6dAw!N
::}S&lKtvB{^mSwvA\HmnZ]Xi~g#gl/=*A{H_B,.hOR{UW*}>_).s6ib1`r=*,[,y)7Vyu^0wDVK&`gnC0bCG7yELE7OWR9u%MnY*_ia@{z48Vl7YO`(o74D`dhFTuS%L<p@
::psx{]\i,N<i_X+Z9GxqCSWhcSIJ>021ZK[v9OdM`n4Y>y_Yx%*1(-qfTRK<<,a^daQ#+HT2_SM>)?U\w$5G?9t>YQp#U5H|wJ/F$M{(&cuQv8AV|isl&(w+%P_-B_!^*~.
::}&N66uHBy9!1Vp!EVfSUZIg`Zi03$|;?u7ih6bp;cw/q7@I\<\+)~%afWIuvczrVgRLSrTyxIJ]3B0w|4AoVXL+[,Ya1[)Z*`(NV^twL9N-MrM52ld|Qqr+r//TX*O_5Bu
::w<,A~Mk|`BQF?53UjR>Ckrszd(xhq#POfpUo73YH[_#<yCs=d!uj1{aM>P@l9h/Xh<3oek8#R3q9Zyq{X?2YSvwvGE$u%Nz.z}I3)jhl%Q^xTIl(vFV^RI_qqb8y]eh`G{
::A$m_)gXmZ-{)EU[~,4Y=(7bc!lcMA\1au04l+;])[J_k><E@\BvO_{6deo?@=RqH(tS)m|~(W$tZge%$erV*_dKQD~NSYxhZ`I/?q<J=~BxK&%!@gursLbY#(K2+~6{&v;
::/V@}Z>iHkV.RlzgC58LE&U>6BCjHhp-M+lp8aB(7_rIG~Kp%mEan6yQ8<^w*i)_b#eU8iL+z,f,1,TX}FTg\k/p/F@`[b~wd|&yZPzTmcpY(lUF^;O{1o0,FSf`9kR0?fi
::5i&/^wW7c~_9NU.`$p~OiLOSTXWm[v4gWbOIbRbK=2`@oY})_/}^w-D+zItH0*x`W2y;.4e#1RwA!Q9VD)I_ZWs`Z4PA>r>}!bhw{MG!avE|78dN_=oV,\%;.INQiq@sSq
::V_4LB6~z}H.|37OSSZx)s&0RoA}d}WKF|`~Au^}]mdi9~PXpY(GE&X7;-u%HJEMESk>-Idq)EU}0v\MmHK5-%SGwI(l`AV4TR}8wN]7k#SL!Wt;@X2b5o_)V%-f4>S!bxs
::zG3$z3e;1u39W`W1NX!!P&awP*dP]_FKiNJ\JG1bq<D[qjJ.kc#b;Z`+qQD3LP3=%Rl#jCwr{O-aGN\+2hgDY+%-j_jr%LL2FOrng4{2*AyeR1uQtJwMDxy-MI1@RObk1T
::sUZinmTONcag}|/;%-BP6E]VzFP]yXW(yP[Kqo%aW{>?]h[W+B%Q.T=jId>}Fnk{\Pof;/mWg6MfeM1F@8F!2NbBz?#qO<&wujiv_L}5NILq?L!2;dfth}9N)7D0IOx/3%
::bh=fUz?+$ny^$qw3B&]ziM2)UYcLg+1kd.s`]N.m&fLk,0%p;oH(ZdRL^iBd=n,7]uNLzl[6cQ1%NY+l=-mNnNLj5=>3KgdA1Cag&Po45(2V!k/9jm$V4Jn.MI/lyuH)YH
::HA%|4r[Pe877ZjIi/zt91Nm-f*>M|c+wG]OBxr.x|aEo9R]iW!CA]>hx\*phCjuZ,MwK<=)YEkPS4F!@;]BhCT@ZA+_^I_&v#8.`3a68wpTGF+?VbuC42o+u!AOl2J(~Lv
::T_1z^VHsB,@9NS)7Hs+Z$xmCjpenxH7_!Yei\o5xah#7=#LHa8ZESwJt}U~UmFW=t%\\~0DyLf7by*s%C7Hy)Z!Y/=>di,R2w&;]?Xd/It-NJN59cnFwdzZ3|j~(f(#gF~
::s1b^!A-3mOo_]J,=.&\eno+ffe{eq0~iRkUKkrBi{g|DRQy?Mk9hmE$g)tv!\%Pk8g^`5-&u(fz]#1m?)KB*?!|<$lGi3=Sn.VmP\Id)\?3\lKz)!sp?=;Xl<pX@QaFmUM
::uBpK,^O24[Z*}TJW)DgG{+G5MPsm=m1rE[$SiFlV=*IKP)kZ*,#Q^0xDsxa4FgJ$?iRA6\T[h(tCvBAVgaN6)/no(Yz),I/N.ILR}v3x}LqSc8;JAhQV(6(<f51_y7isp\
::|)c.#kakBnD|/OJ$0Iu<-Y{Bmmr]DPN<\InR%wBQyMk\?{{?7pi|X~DbK${/RWmJ|IUNX#IW;4@a3$U&ycS;N<2Q[z&3D;XG~a72`!g};0P@Y,PTE6Dhk]msh\QB*nSgn;
::WFJj$NYU5c54Xy+iOe+[I^I<.+Au7X,`-mk48BNI!jW?7+(A@ZPlbL]B-`EybV,qfH4@o\\<l[vc(au?4,E}~Z{7OJ#]q^/S&E=~_=>-DC\0ep9!r<%YPTI@Zyi%@&tC.K
::D$J=3G^{|*4;_NaLM8$4_5h{Y8WiV/^0Iilh-zd=<I!SKxFH.PnBx@NVdgjZVv5H-(`in2ADNeV@kgpp`oW<T43p|3wfwdPI>6%7BzR`(k[WB&vKQ!d($SNzMyjCnpwi=D
::TL-_8gYzamdHG{@r${5GPH[`RiO`+eSHEbLPI2+Wk_iNI/(eYE=*hPa4y&WK]MEGONrJ#P=X|K$(w`Y-Oz9Ecg<t>+Yy22l#Cx&o(?{tATNt_]`!HJBVlj9ga*x>4iTLE3
::{~MT!sjs*KNs%_b@,PdxxM[yEZpFo1%pM#ds#W7r_<PMCMUMjHx<#S\_XVT^,He=y)<&7/u\Uk9Ims[k|vn&42jo)HLi9p]J)QE-EV?_\6W]Lp1rNnnC5/cgVE23wKEfl/
::,r4g+TLyS4[//gOYtWm[=eJiDs1;F[+2DO!aj8.II7G`M*s`B)7a~F1&5y4ucvQ2&+V82or^=MyG!O6-Z)i/W<TN@uA@/h;=6?@&k$8IP.z;t+s~\$KvfS<EggoC6EJPOu
::T2B!^fdXBB?gF.)8A#==$0bpX*dze`NUlZ/2nBzvfkc,NE-1E(+p=#2}qwS4b#Px;}=LJ/O%VGXRW~o}.Uqk<bSo%?8O-__35Dd6ysx`5%jJ.\#iHuwr^mzN{y\A*/]S*=
::$S9v?i%s_)1#+-Oe{VI1,&<yU{KN9$vjtqzpoPs~s}~-iGn4Fum`WFev]a7zx+MNEmElKw#3;\ej}TBPcK^Jv-|I,hIAy**;IzBLPddeAsAYIoJ}<<K3R~E6=b5FS;lwMR
::dgO]m#g}~=[*|=1|i_/$k=<a,?prT4,ueB$m}Q4bLGPEk!r00<R{6m2IAa?;\i>y?^zJ-,55Q{2,qI{K~;PBqpr*9H!>VEKj{X~S@$,*\q0,^O#<_]B^Li7F+,bIQr|m<l
::9=^@|N{wul5*?>Np\**#Kj{kkWb0%_Hxh}h|\/RZE!/6>gcS1J_zlrWNHa.X;|0VH\kBTb#khae=Gyvj2e+KP|R8.JOq%sHv<wJVx&(uGC6e)I8)+t;GaI(OT!pc1WuEI$
::9lN->p\6Sq)RSZ~,gBW)4y(yCHZ5xTttH_V!D|U=IQ3gqZO)2v1_rS+CfVoW[~5Z~7!VQSmKsDl!;A~_{#gcZ$U+Mt*1#&{HU0?[%%.+!{r|*l`+]tyo>{bG#[/<(6)w8a
::,vTdx*@qeF7h3EkhXZ<%%$76*JFN22XqVrU{M2<!@r5Ks).[*R!Sp%}-Ax^gvMDh?p`1{]7-6V4j/&Ehh=gaGGz2;5GsSeajH+`&lWq[.X;cdj,/HC4QR[x;!f@~~sjLlg
::$cCl(+o#<m|m}@APj9;(DPR=G9x5)SleFaQ6~*OSJ9S@E^@X>,Vfp6c/,U0qj$~%Pl%.2K0{mQ4?r4svD-x4pU(7w0rTWFjA%-jU7LY8OF`CYOXfD3Gq_Z\&ot@j?Z{m|x
::=J$Ye%FVNaL<so`,6r5u*6C|Os*ZyHc-$GaRh)qZJ(1-$(\Sk#2bYxF(Szvnax{9j6!3WPcIJj6e,M-;@8#t?=>%[f??\UT<@vucCP`C5#)Vp;keU[Xk[r)Y0^v{an)!P*
::PZtDgj)#{rxL!<f#Mr;Kflh=xBB4c>hysLB4W?_@&hJ?82`<=&yYy_$]<(DDGqS@q]|3dX~}ZOC2[m-MAQn)gWcDOYcQAGU~xxjP/UovTVU7e1Lm)7VUXfjp!}g)p!at$l
::clvV#AE38S;_=+v*%%Vso_gn0a$y!jW}UMQq;{v(#AK%nT#iYoo~+[#lQ6rG9u3R\f*vn!>$(W1?59c${gdM)8kL%`r[rJ^{Rc@jg#;zXz@^KCOthU)RJFn[g|LD]Ki@Z@
::~([(}|>!%bS-zrd$k0v*<Cf&Xl)VBoUY*N-j@p#j9]i<#}rn5OyV=GKj}D}w7F?Q|m,upuW~HG58cZ_zQyR;9%V6s|75%)A=(5dMU}wi+,XPD@c\WspLI[/K4g>R\tLt}V
::}?Fm{PEip,REHnCi0>l{+#w^=fO+Cj.SmFZIJ^0jc@\~j8E^d\yd*_JE<bM*YoexIMm{T9=XcGHAQJ1k4;3F{,<^//vSJq#~,\6T{9=xiUWG=%gT$7nbgVdde@Zzxw,sBD
::41sY/QJAJ_%P+0hVAz`;6..<mdF!lC8`l}=wqQXj[[a,R~LCD7J~.T3({3oma<Zh39V[CHy,9[j9i.d*9=LQEj4;7ZLN^5t=!_vm^=Xn_LgF?`ng/yb+\}emG~!XJJcjC2
::Cd9W,Ov^]MIBC)!iHY%.?Zv5kk?x|i}eKu1{AAt`d%VHgo_2_qh|9L1c6w_,x[_?Yn^a[I.#qe}aWikJcB!f\&6c|6vmz-/M!6QL6Hk[h%1o$R6ZnGf)St)TNsbPBDd@E9
::[hE\{nR(nfBvtz(MViociicltD[pVz}%Dd4Uw79WL5zQt7~1!n))Ql\Hi\nR=M+?^mFh4z<e{PQ+BldQ-OvKQDMH-N=n/mGnX#I{m\,wnSW28&e0yzpL{WsVsfyGTwsJY3
::33j8pnK1(l2~qW>(&vu2|77P{0A]vqYq&CK-tLF-KJ)HsrPug1r!pXhky(QL*-~`l]y}a\124#.w!m|JNzhZI9i~Z{37+B^;,Mp~>Eu4aKOBt$fu,l_[``6yfqnuS||`GH
::gm@Q/}K^,d`sFRK3/)fk^ewK(bAw)Q!To7|M96\lsVG%^p=.6s$)w8ae\L2y4xg=!An6d(\PE&NH+OKt)U@c5*Y=`k\NCpRDqbNCh531xUE#kBgz3C/w+)IFI-EdXuq}/T
::D.{<-#fdcs!Q(nJht#zi<QCDOE/G1-&G6)TibD>3+at8*Egy6QVe>^94.?XZEnT_JxBHQ%-TsvQ&IKyiBgeVLexbIDH&9jEegPRusFLz|`y)tO-<Yf|[;d&Z{BzU.-sjjE
::l-1egS+B7sp2t(!6({38VH|n|pWaSUXps|U,f_2WO(hZ#4gjw=`MX)j&bq.6b^&2n3+-O)|ERBn2Y@HKo?5MbN@,XrKgO=J.veZQ0]86Xt.;VR*k3V)=Y#&fJ}PayTdE.-
::MT1X{o]a,]1?Io5FV!2;CB%CSNslu97AmzK40\,;DiBl3+C@NnBka\3(d<EUd21IDS+^-Jxh_{5(~P4I2%/x2lVK*[7oYp/e)eMJ_MRL*FQ[1^cH~v_~v_tCPW]!I;cM&f
::3~q?q.{6]2%R?&(`={@$m,e,*QzFrqrm9dJHc|eL3$bJAKl|xvOdJ&76g!{e[YEK+iUJ/s#)vpG)1,P^]Uxv#vtSA\mi`BePVk@5]t4n{H(8,2|]yA#$?%]Iw*woc@~~q=
::1&Ea^e!;a~sbz7HKDqj9-]Gb8ZXHQ6@*6S12CE*Bb=ExFR=3<.vFuofipN}4?du|XI|\=FiHF/MxD?EV#dH%UMmuOt(TYqH7T8n|8b=4g!~+xWK&S&k`-c#G(Hs+-UkayT
::u`%,7H_s!5#t@35CxU@@kP|78N^fn,hodJL4ibh~f>/iN8FO/.{2;$3h,&+7A=bB}X8XpkSNParlh$tkSJXrZ!u7>UsBe<Dhdok_O}A+v(HA#iTR.r]i/&.9E7~?XF%tcd
::KqyLHIhF)$o&/Z=!2^iHM+p-F2+@cxGBBb~d-;lZ[K6E9BawY%O?.d]hIl`E=q\~0_Q^ChqHKSWLy}cBA`Y~;mzVb/Ii2)/br21SzL=ec\ny}Z(Zl4Km{Y^EIZbVULaHE$
::[]63c/%0*L_[Ofq=kOIKw\JO}gP.bHWJd)R%d^J=3`g6@bh5GyJazJgM?r-VmZPQ6RZ?hy&t1[J->CFo,&Y^2y?,Hk%M_@gt;X[Sdh\Se1.~N![N#F|(G#1cSZ#2hHqGb3
::z~(Zk)u2-^6M*-u]/8/~xVh|^By^~8`kXB*A{6-&db@\ba5G3mIw;*jG?q/NpPBjeN{w*E}s5/uUQPM512%$j_(iDE(DiWKk)UP0.`>9)@qNm4bLhDgLiy<arzX!M/~iCr
::V9|jO]lE{Yls$L)e,+L/`D$o`zf@07DKwbC%~7rd7XUxcBKY]OPX{3LZcuvz=US~f^ck0DULbvwSWodZeD~p?JS|2n_,[aVLYC]bD_r0Lk8{iKK1K,/5k2fAw+=F)3%_D`
::=c10k<b<RjQcVsna6W9+9^-X7fVKgo^MuvTG;{G{]#Xr\$mMjEx4>5s\Xk4a8YmG3r/dFQVa7e{Q&K5MH041kOT!7$=.<\yZsVZ<cM}gmD=t[]@$PB^_g)<L]d~[uNpBnq
::rj-MXl2k}I)moXbiX^9Lj/gRhJmy;Q(_Rtf,MU/Z,^}yI9y/^!pQBn!_snEoCehaHpTohNd*uj9UAbh7eAf;p7x#mQ5shE){|3U|,+31isl5/8D$ix|}H0%46<pRU+q->a
::2+D@NyhNN8FL,U!2LkY<KT*9!DVWl>{/-^Q)Nd_R93),woS9b@BZul&Lk$P^^=tI,CM{TRGhcfDpTMMGS!xCrnOLYP3Z&5RE)N>/6QWCc0Y}C`*9s#MM#(#|oOCXE#dR]1
::RM*j\T\.,QBVl-=p`FT}TT@,vHJm&7^2GN?W/dZqCq\kl/h?aWRY6Uk@zydlgRVW;9>JE1vZ.TIKM\720o^zwf{Y6p$B=%16YMyq$UA=w@%FBF_k4tsog[D]!W)x\Pttt\
::l,Cnvd)jbP@(@O|~WqM,E+MY^COjV6xlR8O+>Za$!-er74lX()E$Gp8cet4pmc`q`PaGo/Od?QH}?&MM}>#uR|#;\(p)BH9oE1FI|a*qkBsq&^u4Wr.;E=XO|(\aD?_{%Y
::aE-Eoomk@w6VgOF{W*lKpGxDL;?hqQKnZ+Nl7nD^$}vW1rY]]12$]nD8l<j1}z`(~N]|Q?Yu]ohjgc.ZMR&Q,-O_!<Yf=LY!C0XHk-+j)pGVyF<8-c[BQr;]3(GjV7)P}m
::{;f!%KR?1n~I7!Mw}2V_2XG%DC]Q0-Td\RXV^,gdwT%Gy2~yIp-R-wNuYNT4B<]`3ayzz1e4PVkA#>39KZl[>*98N$[[,mKeD|lG}9Pwq3/kFa}A$*r2Wd0z0)QC^qa72E
::g%i[t_wR%_a%iyNWxR1M7uwb=DZ1.GWj=Q><5(kw%WM(~H]9[zQRiMkTTbo)eDJrMq@=xH!@pdkQWMQ*JMiiWa4%rT#c0v_XTl]^2_%g+<V(7xl~HRc-S(_v.JcR+h+AA~
::D[-e,.by?ANFT*vpBna?]z92&Ty7yj%F@)Eta<SK|/<}I\LUNqyG@85Zy]?94+pJDL&~!SY2&)=G3t3D*_]&F[\+Z-,,gEfNq@3(B50*={.GItIb]S%SO^qU};ew|dDPQ*
::=D\;HT7fp^@uZbVSETS=8hnG]i)hilwRea$0vtJV?[g($;!XHhon,~`M~Zod%Mfhr?v;j~cSzSK71?a+p5(~4kfRZH}jqu[g;oH^~\\XN=`fUh79..[,*su3hp&{ALR2q$
::_6&n$ZcgICvRN;@;jZkgse6w#JRNHS/j36AL;<E*xRgcfNT\vtWJmAw1r|ytZUo/Wf/EoB}uD*k3?&%26mEMe%&DyH=GEzfkM27,\=rfVR|H-j1-wkI{Dep+^X6Vb}l]3L
::*O*8vK||.-r/rSFg(3+.6jj]OcK_L0WTW[EwgoVdNT;s~Wxj>Puf+xs~2A.,~n]{6}~]5EpT1jQYh1.dj}w&_MQeQ.[o^qlAy7PtRnx--=tuM+9T6aYg!cQls{F,_]-n%]
::a-C?Oi\4E3^(L3!FU{FjF7>735)bwVV3H7/|CLjR,CHug`H/QPyHy7Sh|!#yg},WpydJi9h6LVd++sC7k!~Th//>sm2z3/x1,kA2N2SMZhs~GI0mcWUzu4*Ebv]59Yb<$|
::I{i-`w)c(_FTaN%U3`v8Q@)E%vtKOv?JAb~[;]~8K~^~if1WIk?4&_)<M_!lne$Z%StHZzQ2~UFDW};_KT)qS|[bb*2Uu20<m~x`\DU^3?#)m66i}lSV\F%IXS11_1feu#
::8?W1TT7e$FGw*p0++oUfjKd?HR)+2ve=!Ds4\P06[Vj3,{_Ha8gn!|bz_P^7nb3gmUV*f<Qo!tgV2cVj~0n!M_NI$CX~gBYZ608kC`s{\#/Z,3`xY]251dpH~1ajHx]WtM
::5;l`5v;$YqTbp*}hZ%fw^7-b}JT(x1q=ky}PX,kV=`8o.={P2\i2~@||^o}9)nOuv\426O5U]>(,Vvv(tF|]jo!F6{Ra.T>qjS=Ov#TepM2aW-%NC}aCc?>67a|SGDjdSR
::~=?8UyURm`K9HS@*w-}w9?x_fp=y;j\%M9(Vxo5]bQCD~)Od4{3EpQK|;Emqn!MoUrmgTbc&PD`59HO)J5y6X|n5.e);J^0^t0zmI)x%3sO?*f@P>|(gGZS5R}UD(?F;8W
::~qc,A.@-Lt1i40|EoD[PjgqF[4qYY!2U]}`;A?oriwlhUGR^o7K!M`(*?6#yv5}#YI]{CsXf}ZbE)2ch>b@z`VD~NS{LyqNs150LMJ%|J`Sgg^1Q,o5HJwA^4(jCRu)c_j
::az)*}k$^;oHgs_S}/uCMWs.VQs[MKZJBq2deHW3[?cR#Lsa!dYoUJ.$Q#[oI80n&AiK>G&)6T78xi8SAAp-@I1-^3clfHFo7ihot~=HtoU|q(H{<Yu<T<ip{LGb+6ao]gb
::&|(PZ`$[oW\l4_<}Duj%_,a{N2A[|)yCL3LC@f3~vp=rK4..Kukyn^)(Off2Yf-sRTR8^v(oy/>zefBs|+7)0VRna;%23TI<<vpT(Gw{\!zm\<vK*eBU{UI;RIs6\?z1rh
::C#[`fh8}M!Oz{pIIo2Lrn/,oSOG%;-w~aW<uc+aGy&eGpR.eJ^0^3+-cco$_sQZ_d7shXhKOyE&[V&)H30@sro~(YWd||\<2)4rRir~(*!i#D-o!;!>AMAc?&16aNH)Qj-
::8zs-XgDM-x.OFpZ1hijE#%c%t(?l;VypN6vWQ2&W())C-Ca?g{*FHlZ}-oivXQq]szYz/UBA~R1!5QS#%wDjTU\<3&c3y7%`#Sr\]7.w?r!W4L~QINZgz!#_kv7EJ@[ipO
::35Nv]Y!(siEmC,\}!0.d^E%2@TV=<1{4n`>)g2U{^U?8escs&$O6}`^FV|Mb1*QwffIT,PV5i(H#4PT|Z65(~+h(g=??v0{E3@,;^%>C+hby@{g~{;?\2eewAn?y|2BKOI
::sandz!d-4`pKKzfdn#a3G*`bUrt;04Q86AqMi6U#j7rg$EB&xZ_vlrr6P`0;g(s#d)R<<9)IJUf}L*uMWp7zzy!t1s9Nc)qqU6m8etNsHU2L+DiR*$[?=xgzb|i{Ub>u]$
::T5*PZcy#*]JY>=4T=U@7y7$WzlSGnC(=hPwj4/8BtwUs$@H\V$3~e^J+$*2Y|}[fw\?8zbj9TIdKkDpO>tH|z!d^5e;]DGjPsN;SO.Pq=+.,0Ogfk;KbHF<675%@t8#|3?
::te]+Q~*yt0+H;TmJCb/(z2?jz_=*crHH`b-bdL%pB6[\AH4<BI*[t/*`)mmN|2k.X}D!>VoC;%lWm0bU]RuQDf?RE2t3b%@3`LC=,$$(Ib@P`\Y[L1Et(1(CJbdNvMqh{]
::pWHk_%F](j1@J1hqSWi\6bF_^Fytd~otUGu6K`Na<#S5IF)UU,lH\-qk1gx!B9gk[>Ys9Yj[6S<9%~MF9@V7,zS0M?\|&Z;`Eq<djg<!nbH<nzeGA=SB,m/#~YK4W;q2Z;
::2m\2Z%z0/TsrDMw3&G#r4,K*r<#Z>)?c^wT5W!;TsnakQ\97MRqHG<$9lwfX^uK5hV#8Iov=.r<U!0.QN!I+N#--78_&kQ;g?D6#A0J^)nxF1[uE{pb4(1>y.=o]|;,j.#
::A;E2,Zv5=qS3a]mG,Xv}gNL(!\GH2\?p@IIdU~qkz1fdi*$vNksoD~h\PvHWi(JwI.]iGd-\J1,({xp4Sbd(Bi1Rdl^bn?KpN*Y=4?z*gYbh)~a5y`PKN`vDH#ba$1+d>d
::2|!l|/h;2E8z|>Y!K{`lSZe7%=KD?@ujqo-83v7ylA(;t#[<VE^~/)[F&^@/A+&arHpIb$wfm53M>3S-yxpQ&}4vt&)Zxf!a`R]P=ST_n|7hmrd2%oTg|*;-9&s|7X[{)U
::+Kw5[juIqq~3}Ip~NOR]48ITB40RQ9Ohciz3&7xtTx%g$KD[X!iZ;O(V%8vry48Z#-=}{6wF6BjQ^fx%xc#js9.*)Z5Wjg=q{!rca(Jm+im#m;qhN\L8.m9/}T[Oa+})hi
::Mvr&nyK]W|UmYG,_XCS;ga-c1ICeo#=E~\asEhXZ#^Q4n|2<&?Az#U1@N+<xV2=acX1EJw&[I]&KRnwm79PAsBAL$FIq!z8G#Eeh@^eswVj3FQT&2P>jiK/m9wDNh{]hMD
::r{{euH0MLfX($k|)tPDI|3Bu~7OL25\rDgiLNY*_WzT+I9<AO-|pzv?qzHz8O-z_kaq#}UZpj&CO\T~7=!}d^>/FE_MRVq>Juf2aZ<Gf%Q>!-CMzMdugrzAYZ~$QN9Z}Y2
::79mq<C)D<gtQ7tH?%+j#r$SF{4W#=E|q8H,Lu{ODQ2ir]5|R0;#SJ|k@%n`n5N30!OYEEKvT=-~#PzP1}7wq.B(y@T`AHHWatH1x/L?&XN++;*-?`^FI$M$/!fv/w{0Zd1
::GmfQ!&I/?xL1qqrx+u2J+Sa]L7k}9\m~-LO,\=8M#{*@Aw[w1BL%jRUNRHAH/$iH~9)BuO$XAwAA(Z;lu>GILIE@kk2ADf{1L${84|Xn!1;ZD0{eyD&-URm;?U;QM}{m_%
::MjyT=qE#5B&l4|j+.b/&=Sn5`R(ZZTyXS#y&h_varMQ;m)6`N+9#ul2+v}\2f.#sj!5W}1|B<op]nJLRl2.j*i]l^zj_8H=(`i*aPM^V7gq8,*w`PWVC1uU89A>`k\y<N{
::iCE##A?;/_mle,,,pc|1yWIhC!H|DoRoT(SmZzQB?CLxJPfSh{W}dmBb6Sgu}zz\-2j[%2a$6IC<yv7v5EmKl~4Dq/`e7zBL@v*eH0qC`yr1;KD,pBCBGR#=($!iAVK-le
::s_phq;\jIJ3L&oad.8p0h79=EEORN--06izWh_RkOH&g64g$T4rwOmQ9KD>++WiFUPK58r%-{9Bt~z~9C]9P\WSC3ZYS#l~Oj<?y[<|[-T8}b&c\%jKnO;C+d][NDKwS}X
::0nWYB`>[tm=Stn?s=wtT>d{r6@jPN~xFf)j1$Ztg<L\|;v@QGM=p@Gz$_)FsBF.dg|mtRvM2aa]a?kD;`[K&\0;,n<dA%61!XqOU(rvnLSG9Ra(+yo(pNgC!|R}cJ#/O3%
::ui_7=DqL?wSYPh+Jn@&m{Xb?u4oIInckVV&/lz.U?$Ba)g.88S_gDmX}z+g*]`k0F-`%FsXjkePH[?zJ,O\zbQ\E&KtUGtjgAnnl;BVHdw?)5B*!>nDbiG5\uY2Qju2(2!
::J@y7!0;)J*|kamalg/Punwwa)Ed@`J>r*@<i@KBcM*]?8{E^)exNsH9{/X}Q_R(LI}U>#kSNx;l]#e+gaB)ymehT3s.Z^hLd,p,47Js}p01*s(V$.?PYf0V*9mJ!;j%yD&
::HGyc=D=ojK~o/QVFL^KTRvoj2a\m)\+]A-n{Jn~uo3#kc<rTe5H(dn@a3vY=5JIg|nAkRbSG,Jp*38l`G;hFT\P`^\+V8YpV?](H_)A7O?YI&EWa}&;Ym3_-~\}3fYB)L]
::(QWEi0my3U/z1/oMKU@}zo|8\0>D<<}nlkB/%z!&+Bk<i(xn!-I*f%Z5$-ag/Vi4LI9\tW$C&q_y]5{Q/yW?)i=i2ak-?vEsC`_bzh}q#^DfVIyXQ$fJ@j9#w]g/Ghx6V*
::TX>$&\o5uUYDkz@^Sbn0gTpEs(_gI5TO2|LhXl|q9\;6`QJ,R?nuA$G,BTs5F1;{mshk1Cu0[2Z$YWfY`0I!^|QR~dW47[UB+B2(vM`eu2uk#Op|X6}l=f8-dR@x8Bog)K
::lR\t]7?gloQ1e9vO|Q-N2-kCk.,CI\h`;khB*2Szj;3q\1o*-kgtgS8N>0Uon5vs}CqRBHo*IqNwA`^_A*6AWiJ}]qCX;]hP,!88q*IiANTJmG5u@qTyh0f,%N14ym`bg.
::!jxT,Oo21>`iwO+<Te;f(]TN61,n_z27@1xA!4w?E^$*\v`IlKvN`t#VFi%<tc0+_m;l6TrdA$;(&$P23<#df6>+xt-3#*`bWKWb#y>[wXW}p82=ymbDpIdyY[Jb<mPvXa
::73OWKtp3;kc{~gqb_>!mc(Jo5B1A8JmUk4+fK5^60rgt&wxz|5}BUi##rSR<RO/Z\6i8sCc[/MMqsJu+>oEWax@,HiW/Dl>HqXjsljl2QH#GeyXmn^F$$<&3?Y.fK-ZwOA
::Fw)$4M)T~V/D{CFV@l%^v4S#1%~qFc1!Z]shgoaOTW-j2y$/7;>~`rCy3r^NSDDaRoN!aY\AX9m]Pp37xnU\52QHH*yr|29I/4dh~oxg/Bh.[{-Goq_A-s0WKiy<E-;k5p
::N*gWI1P8Jd+V%8ThsWZ4g^5f{E(w57Xv6,]{3w(Jnb2u=WHh?^2C)_uIUO.;{5!^k/5;8uu9p+3}W+o^^ECL\60QhhaB[*oqV=*PG7&fBK#)UIo?(Kol]^Zg^np|i[F7F[
::sGQ4}2)aszpo%`^2)<;WFlv}Sqo%oTlO)j*|t<&7jV)GtIp|,7Yq|%OW0Y1*l=#m6}6XceTwjnlMq>=}nCZ]KU76\pP%LJOhs\Py|6ayFbJff5n/18j?.s^BuEDp.I-l,f
::iK%``JReq}G\@hC6+FjkCGD37E7Zi8MBXrCX5NpEW/vz2<|.xqU(KHjRN&pq))yx$`Yf%e;Y*A.H`n;&=&7|D,;oLNWnGi`)BIbwgD1DkSM<VSL*%rmR}4Ri.X|dR)!&/C
::|~xtpR6]US<`{Z7mQS`ZTD}%-o3$f;KUpatvpAHp.~yH$>ML|jyt#rYIJ3;9T4m?kd-[5Eg^08Qp?].y7DM]/,bz%2$?!+^N2v6gV%~GNowy1BFj>r;1r+ySEYlf^cI6km
::t^wXM7kdEJCf9Axo6cD[Sxmo>X?+S+L=qEgM?kGs-D0BUc<^Ma;<-@;J9|kFmNTR9AR_PE(jaemt]R?.Lq-RwlyE7DR\?J@-#b^pSyv,QY9Pk\6g{?Rc(E)bx$%W33=c2@
::txre&1FJ}mNx4+?M5lD&&$?O]?B}iv__q8]tD$o[mFh4<}Dn6ccAH7JLYNy|?E$uWy(k*ZG+1V`F^FrNkQMh%]cvlK~ILwIX7&6ZYst!hu<hD*)~ak_N`oR-T2?k-qL@LP
::2j?Ky4Sh^vY7/=U/a#|1k,x=j|<2~7!A_prDDk4{VXZya|f^NaC`IwKzf((dauvv4S5F-m7Ol(HB&c9J`JV!_X`Jk]Pgb$?NN[vPSJev#Q^Jjd)-\#CMo[d<r]mx`LHb{p
::XD`*skt}pz.=>rvwA*.s.gSdAQail;<j/X\AepBUT`(KT]-=<hSqDA/fB!jz%e<3p{;-#^oyJbE\qH3i^%jC+pe]M-3!<@OjCABONO24,,Srz9E?_O@oVfm1M#oq>YKovb
::,*^h%SEXp8Wb~JPg6A3d>U{dpG5ARQ@m.&W[pUatM,NxMg.]No|8#p[S3)p>g)DkOIIpch*g/]/<_s#aSD<(ZOsj0}mfyb_G;G3M{w6XCj/hfpap{Zw8sF|S^;U^mR&rRD
::jQ)K@2MR(~i*<^d}\hxpTO;+[HGCch^+>,mwbKB<=P*4;QFKl@g;;v+^;pnsI_e.z]V.As+P&19ZqQKaT;Y[\HtMnsS+^>?.5zQYN/Qu-uKD<mZd\KM.}t>w8axh!i%MQQ
::#vtY>#0mIchx/4&Q$SNR_<<hO,hInY-S%~uh64U*KFOTJKC&v%[iY=3x0lGQPrtjRL*?GZ\h=xa/YnoHj@^`dO+-p1zo93ap7]U{S[w{,0^x=Hw1|Td2ZMVy%6+f_>^/C2
::U6QE_|f<b0!;FuY1GbuJ[0d-bMw<enUxHX%7j/sncZ.2FNlJ}P$cf4}11nrGr5bbK)8<S43G#KvAi3LUkXg|$~.E{E}>t6>bT6sn@ud^5<D}SMqgzLuPp$(xpEM*uhuRB{
::}E3T1pb0EUdAMf,ENK&\l11CtzmE()+_?_!f6z=8&`aR]]7nz=6AY]QwI2.FPspOVdcB1$fM!|%taTLwT]tdHZ]ufuJ%HeRGKHC7`72IljvP{H0+||$U8_q+WoX,Kun.wL
::<bST{Sz-!S\3Wnbj^@G&wA3l1BOS()IBo9a;y-%#OT2g,/YNnB^<v(V,en-_nI)&-nKTvnrn[T1-\8Hwxf?9~W<oWys~iE{y.bx]7.~LZZ{s(FOfYiGgDnV?V9*M8&]+N{
::T(ZQR`bI=ruT)LHkn#_lg_rZkqj3;`o^&yB]su/?4p`#g)KqU-P[dB4_a1wdZRNCP6(Zo+m8ZVg6,$5aa_{4-rlRFJGY*U>GEx+Lz]~l*FD[%8S<?[Y)(L[Ts?[*dy3BjC
::SweN&ycG?94,xzKD6C4ktRRn$lv+![0Ws3FaJqeH@wh#4YG8@Qct6GuFGM7zj_f^><CLc}jVKFv#cwraeo~>-10C|mGBTDl(yh3=D4&CC,|W>YE\@f9w<jyjpC.JY=XgFH
::=@U/6rz``N*%X;z?sWIc`;qQy=d(qhdZ[<e;B^<s%1I?c-SJu%*H/8=JeV.Iv_M*ZPB3)7`dv3iE!9~6%-isj6Hh8Tf,I{8YMYocG7Rk;8ft&we#;&WewMM[V5z\%raf8[
::vXGH=b-0G&EuPZ&c#uJ~|ULVA!VSo~*f@;x^aNnf|4k\6wqy7S4cqq&`fD=a[H]sFN#c^Rg;6f7dRqqu2ryL\Sm94>s3a14=Dri|j_Z<^SQ#vstq(tO3Wqpw|DrbI6kQ^,
::jT.Q5|jQE@0%,HC[8JJt*vi%|<cl]MW)9v\/#AeTwd&|J5y{`[Qqb~`?_6Vrm{Vw;r1]g{$2-lB^29j$>^qmZ?]UOf(-Z`cf+LKL/[4qt].#)+2}nz71klZFd[8<B*\L{`
::ZdM%k~D3gQ?*A7g+\=-kHRtd#[eh6le`>_Q<.H+R.q<[Nw.%pv/*};WzDh#X~Abhz.n}E{iCep)#_j;!dC@FOBr,yr#S}#Sd5(%hi8T&o}r=z([K&Dv}pOK%MyM?OPmb|.
::vJ=<;)wFbvP$)Lt-zU+g1R}~/>qlCJh-Z4G<xxx}lFFD75=NjN4e?7S1>c\xYcwjKsyaA*PMEpOu\b5&q/I5/T@xlg-GVgv68pkD_N|Bz#y0.ysqxz~3a)yWtKCclzH8;8
::NKB9{&W%/b-#iG+?>sMY,N#lEve{%27,1klEyu0Z@/{Mi/#A9CWyCT&D]hELjpan9jQNK/2HV>KkswY!B~s3~.6+8vH`u6}[N/TtN+Sf[t`Vo\9?5`7lmt?E&*aajjAO8o
::H*E@}9}85s-wB+_D[hx|RF%$mpwW2+T;v^0@NY<BYw,\lvR_vtlWuV<cs}j}K[f%UO!(!?hLyE8K{L6fv_6v;$1`djg#~_#{{#c,{Di4E\4*a7.lD21Jev|8fkzuo`HHc1
::TkM,H}TM)AJ!p#Xx@rio~u#j+9Qfka!ec?A(stE8iX<S(_]8@u&/rRgb8TWmhnVaNr)a3|1b~mE!Q1^d\6<Bh`B&Jj59\^{S&)@}%vly7G/mN]#D]czhyuUar2/sI6Efal
::ezRCf``|p8D{+3eNT@Wnh~RN5w%[ij7.E(<Or/,${7&W\MW*e`|3W{}UhbGa};O[&Cc@,C}SA^{Ya4x(n[j/(|BP)}@2(D!FuiX[.{.^M^G;c*es7a\.},#k9aRP0-g6dw
::+<DC~HIiSQ9o@Xc$8_JVFCzl,9iD\\J;@nH=MD^Ac_;GNQ]}Q8^w3=n-TXtoDpjKR-p/i/J;z,VJUu-/4K>ReYLa*og6s.RA{OVH[PO,`^0ba-3vY8<NAs7TYeAWLP(l}~
::tF6#c`Z0g^K{#|R[#QRJ%NY_quH7&Gn;1yO_vh.pGms{i5)CxHSq=2t_~4(2V,a^N]>[;z]u=4jh,zZ{mCiByDxlw-2qIq4zmv]^++E%]LI+(Jb2/4*Ij=WWf`Fv(EWwYl
::\(NP6~bvk^ZhskGH/t^g-fUF)*IUPewCE3nO|gVuN;[x+^$6xF465<Xo67R$K*aW~;sN,{sBBPq[u.H@04d91~0)PHepziD/->DjEDl+@SP|po.8;eX/zU5BrrisGU*liD
::%/9X-FA%j_EF~E>3c^v6LYDth1u#pTIEXi$nZP=~9|tvXlZ5cOVj?DNbCDcKXt%M](!o?FoI\[[a/<.[,+J{d*~=D877nN}.H?)A7_sV+ofD2Ujz{ko1<Mh,b?65$Oe=P?
::]\k9Ei+>7ZCus=}CZXqWNv(?FY|~Im\7Sp[RIOU)Y6J=ox3@e;7M(2o[q3VFmC$9yLQW`&W(gsPGAvLt>uU(EkGxi/lu{?uln_cRk>*o\oSs]qC#<-.-_FdBbn*4tAP4$/
::-JHxTqB|SrDMg@|@iFtbO+OG~27w/E}%%$@4(OPtwcLTSCJKIw8-Uu5,#|fY{v9SSlh!HGo`O0KzHf`UfiPpIe_wqa|Z7P$1Gc|d55B|d@Py[Am2yf?Ep+TtdcIzN]=m7K
::o3eYUD1Wm]?7K!A2;X0U%{=;p]P*tt>CQrLebC+S$={_BT{>I,4qrR.7eT<u\sno~bl4wc@M_+T!p]So7PL%l>4Q$&n`|}U8iJ-CM&Xj;hmC_1`^%=5bSw%\k;i)7o(h$b
::m`C@#}y}0X$`<GU$OZA(FTL0C)zH\e}dx#!PPt{ha!uT?x3Ujhcv/Qi`ceHJ!lEJ\Xhx{HTg$6hL=Fw.H8<9aB!}HX5Kn%x8]*VTml$q{D4<6Ki+DL)4&[*Zn]#CXDD(d}
::+ye<RR,c1/_=@{T;imcQ)JX\-9X[^tg)HP<C#3fxpHU28$5IJ]v0M;>KW=UR>8@Vd0)s?!s*#Bt,)|&{r8c+h4t%!JGRd3`+qf,wt[@YcI(l~Pg~itIbh@oI[r1#qC62=e
::?g\kb{%M&y0?J9(E)8k3[<AUX.j/=y/%alawSbNd9}C*cr1%A\!`APo%.Q*ey{1h>};c5BkAN6mExJB/N(T~a6\-@ACV]G<Z[{,7gCTrvy}tpRo9;RwQ6PW<CXr61G5!]_
::YSXAZ=dvVK;Wt!]{cT`MLKI`%o7#].)SU1r}BPGpL&m-{t*NG^6E!|>IP$a0*)2`=]mOc6O\#?nO5Q*BFen}$PJI(/7FYsh=seDg*WGmxd1*lnJmFVX\#Ajq#Qj=6S&xyX
::YNDApY6&cSVfD#ltLA8;m9=np^W}VycrC0fW#sY$X@7rqXs}irD?>80?8v%W\mr@HbG/JMy!,UaWqr_Ufls!r\G73-{>#5hEc_$q@tkv>nTd7OU6w+VWpk-a0+6{T/fX<g
::,5HxBT4wU0IQX92`!;#_5e-}m~c69Uv_j<=h!^9oC==.,*NWs#eJ?]rBQJ0<Fdp+G>-rZ9/[<yt)sB?2sq3S>cy)kV%JM3Y6rnD@Ld^xL7$)^vVT`0GFnl9_+sMi~i`XAx
::gvKQmiZwzPOlMW<[VueE%ATF\H06KOS<sk(YdQsTx6rEBU})n!il(X5Wgc2QrW(<@dGN>{pS2.a.\x`c2S!@k0o*M4L+]?r\+)XQ~16-UsLnn<2ZZIFrC=4Ax-6Pg,.QVN
::-O/J9nA1<`$-r@usToPR$>b0l&\1sU=N!sb!IUOh(1TEJQ=)RztBd_tzh;T<K68*^=XR,/~=Q`h[UK>z*Dn.Sf5V^40O#)fq#u/Is$L5I4>sFGQ+{6kXB@y6*q]fs[>OlA
::jIH;6ZZbrznJ_IQP]7_WsaQhwy=k~(;xLY/?s5a0NH`vb3}lMcTB+8>6C-)Do212Vk)X=w/^O%Yup@W_(g%6YP(m0^Z<PRKbgFgdwDf~[=~c~Cfe_zZur&&Xz3>cNjZbqZ
::Rw6v[y{iP}/{>vD7_G*G/pg{MfYsxPPU3I9]CgC\c=`#tXXJ\XWDAPgVh|nU]#]y\9|lD+F}OZHJ=,wA|;4qL+*4}RlVo,ZS-HrmS{-0GDR*TbN7eWItMfucJP?/@(tBPp
::kF~QEU@Q/C[F1QRY!M!cq%@wgq>&DnY}z_6-/Qg<o&o7L.C=~$*_.}IoEcy!EXAfL/0S#ajU6t[^`di7\s.q~yJ]_@L8YPFi[3}r\H#1*Jn@~vpEGsQhSi~8;bZkPz|tPc
::|gmE2Y0uYKK\6#\+#}1HKorO;aNbX~//ls-}&F~j17h=zqhV~61pX7-MEv\uhe~JHot5mvq1mR[_5oZ`{t?/e%DE3-w}>h\Wk9i$+J\!H_T\,(F,qiKk$G}8Wxjb;%d%(s
::!/tYT$avJoWfn.)7%=E\Kc?uFEM_UP[wdXO))-|-U]~F[RUeJ&)2C3`(mbY^?O2KwYauHRI0x}APh6tp,@=OY%+Dmc4GAyCarQ@bsB{\BQgm&0%dkPlWAk`j.OpzU5[Ihh
::;Ec}5(*-9z*]dN/~a{}74mj!Y]+@kCxYs4#GZGA[/-llw3Jt\ee{Vv=n_[mlj9[jKGx$\6]m(MfDA72VP#2~TQTDGIh@f[n0*39\/fnd^;eZb1N6%4~o]Sd4FI|?6Qf)<\
::KP57+2bT/j*HDvA^@U?_M^X-wJ@EVClzq}L-^*T@hz{Q}klrlf9-PxBp>iOgbj[hw(8AQ<OM&-G+ygjhZF;z!8uASTD|+rGpxdeHj@wyEiuL!~KDkScF~!tg*e>/3~mLG.
::H|P3rpefxMcFc;G1Z&`_o0U%}0]lpZ_=8ksY`\Xy-mEVE_Zn8HB^iS~5J*))<zopTpiM(qB#7Ah8{$Q_/(ez\3?Cg2IsiCPa]l5nZ$thXZi4#1Ma0+VS8$|SMKZy3WL\1i
::cUqYibaUXjJhz)Vfa|{th/,AswS3HNK|jpS(_gyu6<Zl)H}#@J;6V=kw*Vfv707;\-Ja4?`6L))AChYC!;0*~;1uqoS2w|`)Mb4X*hP6<}57!xpgZU?RykrBY>+?+=5vs_
::%XL`NQk5=eJ~o&][7z4ZM&-CwwbBY;K5&({m>&oAR,`EMCHihTi$td\=zIDfI^>P2MF,3[*,SB_09@u(%gG@hCW!Cy?#_P?R}Ta[4pU{0a[j&63[+!~r4&6}QJ<O;t/eV|
::EQjq,PSm76r[[}%X$z=c3^XZRYb+]-<xr|\^Rs`UmYj~jT8oL9B4#?E;ah5h>cS<c4mnq[k*&$8w[soNzzqDmxrqNmfip>al)@K_xde^+0o2ly>Qo^y@WVdE|40@mZ)Dx(
::a@J4/}KnAO7AwbeKR~a9gsKY6{_T8UKdR]B3V%.]lV|xqUR#G^HktnJ-8H3]Rf,/qMvv6[>oZ8IAzmym11y,(VxH{8lY}62?f{D()G)-<8ht,pedjSdGY8S$[B;,<+UX.F
::Gj;mYj-lj!{0Z{i!V`!8,;mg@>Iew`[fb1r2xQcZNyb=p__6|c4Lw7xNxhcJEnxBc/650cUIuW77%\{q=8j9G=fc4!1jX`~+w6^SWY&Sys^jA\.79Ms5Jl}fioX(8Nk2Mm
::ykCr1OMeKvC~jkv3^AqUzpo-C<Ie;\`5N6C%\kJ01M+JdV*N1svrzS-YG4SEP2T=`WD;Le%f/C-x2ltq4111>Q[jN/;@g|.w\BL/J/bb_v&AL?bV{B`YxrJ@%n+wfi2kel
::<W9_}C9|g8wk9_95x=Dr&o9QR.f&VUkzm`=lv!#Z&@7$ct3AKYcXt@vP0B,cB8rD)R=f;G4G]0m@mn!427w(KvgM\vjlEAn^JiG{H9>SK`)+(qoZC>u]({wT6(xO6RY0%p
::b,>gpBn2]V;ji@uHO][K-wX|9dbB5W$Bf$KR%+Ssrcr;M/e<O%zocOQVN&=Ura7i<k}g8l289N&k3ka+88)@!|)lWumR2mkui0}L!}O~Q<iNf~/j|5_|(5=]hriJ1s]iQt
::cqg+}3CX$cQ`9V?QqP9frq}Zai~]-Cd8]$pjwh8IgW>.6_dn$}D+Y{\v?BY!<,-R&FfDKxZc/*T\V,9F8]L)Tz\v8vvJ+aS\u=!j-/IDrB@Em`3VF`eI_@=LLO$Q(|#yiD
::/(OA\]]@y!2yvv|jRT%j.6AkD8|#Kwe{utWQGV(_f8gf5$+Qx)7|}6L+Cd?SPC9N7Md8~C_vhy<YBZJgAlyk.iVJ+-ZRRNq(\TSNIXY!cwLpPBnT#wF~nG2pK)Q*iOO/J=
::UDSzSzzq\b]tge{^LLi`[@H50*m-S)3.sg|]6kQ%&^+z{g2u^I)/E?lq}K=fgimCP=drOd&)X(K^c>*V$}kl/n3IgS(bT~%R4r%W8hxRceH)d<6Le<w)_0+bO~*@<,!7D5
::0p4ntc<^cgNs]c2q%B_L=L%5*$JL-^Ilqo=2TF<?jj!}^2LNN;!Hz_1Z2He?U;)R$?G9f4P8u-\}JIB&N3o0<O+9.I2/8_Es-gs;8]};QIMIp!Nys9-%$y6YwnIz#e7y$l
::TmD!TTU@m[iHbEPlZx4|!En(0b^l(q_|5dEbe+;c$<rF1gXZH6pQ{C]zVfs0EA,j4l3ejb.NN`NT0=%u>eh%89B$6JwVPrkMvnTMi%!ca4OG/6)K#m<]F_K%Z?$2zx-EKx
::Exrx&dsZ+UpI`rGz-=tiQJBb@q14pZ~yka>.rLSP=xD&0{a|?LDbs31d~?ePB^{NN!+ex92?)p4lE.c0,h7HlY4CaXm!Fa=t*VHatfGVi@\1DZ8=ed-~Va6X7qHzO\ObG0
::yTWzAK~5DVaPf-Q2B(29czG]m<^Al06p[ubi,U,XwztT}!u>fHcqrj4rhe2UF=>U%;YD)}*MMKgO@6;$k;;L3<$Y-$+_4jJV$l8was/%u7&3]}kx)kKVW5s~+3BA-,9k!y
::!(5v#CL^a,<XkKmK5a&{-O7D|vI)lzn|.G4)Q31(cknZ4k!#@7rYmZ=+Py7|r8c@K)TYa,^;%kNdLK&2vkP<u06t9#`p79ziNqsa6^/P+[Lu(V3drI(*~$4~G|!;I0-O7\
::6?^,Zrw=Q||ny%9y%_yr/iG=I?=\=A*T6#n)|dLQ!&r(B\u4o;oLxlSXur#4$+8;b=>Y<KM0QR+!Nv5uUu~7^Q,*@y?V(SWU`cylsJ]]|L`wEHy+k\w;N.I+2{Bb&M%NiA
::aLrt2@,y<K)N}?EF.CMpRf&3|<P0X3aNXthVQiGB>S}k(2K2+>7/31%i1rr**O[{2PRJDN{1.upO>\d9|gtA3$2u^*]5oy<(d.Pbk?`_Ty!DRTpgQYhP.p0UmQ2z133m\M
::B.q6*dr8C|g%vC$Jy|p6ec<L>B~nZ2LxXG2~-i9(NxzSBn7Ow10gXE$6-zZanzEue$&kr=qe7seK$_UZi!L@I.aOFBhx^S1`A}JJLy.+!F=@ckNn7bm_IB9{mFfKN`;qgh
::B|JM!5%*=e.JQb=jl8kq=^TTFtf3lJR(g.-+dB<iwzr1D~O|aGs{l~dSjH%zO/XE_q1?pwCk]ijQ%a0;?roU|y7!gI4i{yep~}x6Ep0~cGEHjkP2tt4dhzdXJ+gRFKnUoc
::(GYw0*NzrdS_WLkaUCjK$%;pF~lGgpN-_x$L-|RHf(@[|u7f`P5739#o*R<QDmF*js,}Bj#|Y#Oy}tc3YGn+M]Fd!/jL}WU2xUoj!2,eD1?{`Iy|c04<ZHAXCm{pZP-Cmx
::NkvL>-XMR,@T>v8tt[}lYOPA.=9XmmnanXt(?R]NzJVwWo_^OB;4sf)@Ax&zsf6PC}KgL00?2Abn_d#kU4NR[[HjVOyO9s{o=;}z#m?pI<Sd0NJT^l(F&N<^gG3V~mdW9L
::4bTqW2P%^[_P*XUy-MzO<UJOO>D6x8yorDoE4504M#p8~4!7iV5U3_`x{<R<M/}6QI3wS$KbY#2h,Y|d?iCL3vKzlY*QA&#;4`5D?KL<.r0Dm7A@G?YBFA*ocrw%CM+NE1
::Cc<myn.HQ+l$[lNWjhqE>!6nuw!]2vYW6fPN/$t]m8L`_MCU!Tb>`Z&/YZi}c;mKim}X#w}^D(mW-Y.d4\4S5]6epsGiK5!K&iorL|2w7M=B[o[Ilk]7CV0qJE#q,LL-tk
::jk2Tb#uR+Le@~-PikF|W1)$2/4[yXl6SpblxLX=^5czYkK9paWex`47{I0gS2;_0VdlB0`NUy{_WyNs~5}ju7r?OIPN1%G6W>J|yg%s\`q}Vs(rQ{qW%0JFl}No7pjvK7J
::M?~DYG$IuWG=5L;[icUo\oFgeD;&Q#)ax_a@kyHXK*zYm0JSO&GdsoECI0FMk(l,sSZ@NE?E`v$)Q4_9&KJA\gW=XZWPPj/(|Gw`;6*7k0L[o6XQ/QGCSnG&kYs(SwAR{3
::QVDKnjC2#F(t!?L)1+1gBGl-G)MZ3h_CO%8zYH|g,Rymr~.S|n/EX70{q0=}/X`v1dmdr0`liV%Cm&eBfaz!JvG+@D1!7[n!$nMt6AU(,e6&HktyJAG(.D9d#w5*peuuK&
::LUa`a2j*;oM,;?h%uG].{Ua!=(+gw1oOQm.V[q7\m3Jod&F[8U-GH20Z3!{OjtJJw[\t}D{IYC7h0kc3_#yQp|Wu[4/8ROf8,aJr&jt%Y,%6u|!XJ(XK/G45kD1kV,zq0i
::x{=DDH]{rAiVDo|iD(U`P>iZPnZ({cO?K+mphTv&p\ezn_OTp`{;c<)%mRaL2Elk!53#znDUW.)bXU~~E@M$=hWPrF#V+q=b5GH%Kw0A|hdA<$*o*q?dHjaL2Z\FK4Ph|L
::~8)A#![7vH]ogt5yGx+@K,tZhlkap2s{8kv-oL)M{@(8C|W@>-E$*;`.lI}W|*Dj32T\34[&&ukX@(uPI3-AS#6U|T6#Q>BVT$WDjd23^4Ef+7-eG^aMZ0]oNJ4fAl1!?&
::GO\=}3WAnX\PjzcI[z{2hLfYaD|A`4M,j]Qo)r{7RgMW5?mI3@adld!eM-(c26I\|!N5f(e_GDd,j@+!kw7DfZ{yAXxMc)k|YM~R{aB;$n%kJjDW*{o$iiKUTxgn9J<9o>
::|J~04+94ckdHwY|D\J8RFNj5IT;@3Y#>WP^1*lOs5LNG\J)g/mq0j0%4>hw?Z#ApHaYV#[O(o.5<=n^sJ8Yj0Q-uneuNkR,E>I^p~|6(/uVg<ERz@fXz13R^zrO+M~I%w[
::jpH7^%VpT7+-(K7z&^uI3q6S{C?fq?4AzaJgYk$/Do7Ca+7*4&WdsACC1PC])*/e%YDtc9SN{M*{]m/86{@n^78lT?@W{#.ZA/uQusiPry@CA?Q7oPY\i,XU[}iVGlUEUJ
::x|W`)3o)|cs}^mm}5CRHr,QDA;(;&mRa?NVV1B,;jc.6.z#5Cq7m|qEZ)$FX^F;SPX.BG73zFH|WqtLo$T-r\zPGX)Obi}7JrM<SLVt_pYGIIL#d$[uX~#n}KY3u)C;?kj
::R47mkGHK>X*{BZ$(J3kuGT.3+bacO>Q2ZuvJ+e<#.;BB`4/U</)<zGbO}s3^6F/U6tG|z<S$j_#dC%cPEUr?4.(iGtOU-`+)YjF7~A7%ouSjPeL9TxaQ(()p\9.0o2}h?i
::tpba8k4II$AwP1$cdd0x@q]=t(wGvw[R_[q(qpojFR5bA!cu5A!Uxn^$]t<nJ%jxldzVc+^NyKp0Fzh9-/fEk/C/wqBpP_c<-uUG+-{Eee?vP,8&jVZ*,ZW?D+76Rzdgx6
::61WGfBhQZ+V7C8cWH|~791o[Q~}ZCoNq=9g,AO[7DYPOphsH9FNO6,=`8d@RoM|Py<IC1(H@{(FJ5yp1k4OM#MForI6H62KN8Hc!/I6w.^ThrB-/#DWu5GRL666]Z(z^[R
::|[NVsDr&8xV{.M?s)yO4*eb,D2fIup^l[X.I{/WPmP~Hsk^ZA5tW7~2^=@RD|Kp3?D@f},iGd\-;M[-b|,oN[h29@D)AuXeyi1=g^vJzq{VXqJ~@=A#U,Xx^nmx9y)kcrU
::(12K8||GkllVHVJP16_EcV@Dqf-7N8jEm!1Zh;|ZX<t5N}iJT)anE\6tf/7Z)z<roi4@mGaXor;D@M,QZa{u$j}<)aBo;wJ?.Q6nk*\/T@xmB`l!Shc?0f*]jW/n@H~b#x
::A$)I!FHvNjtE2!c|-@dp[6{>1&\-EdLA1*xeMJlkj-T6/c37?_SN;^_*B4f~3L/ii`(_sama(G(SHV#{!u^Ve9E|d/c-EdS/qEU6=/jM_8+4gEDCJ7,]KHT3Rn)l_}!Nvn
::Un}S@`sIb]-XwF6%2*tdlGezwBh]k\WY=nBECL8-q1nf@M^tCZF5mMLP2\YP)d4m48}d4DC37i9g<YB3R)aIHr[P,=R)FbiRmE3whtqmMUKkqw|RcyII9$&wv${8t=&MgH
::l_x>3dP+/y%xmkS-_1{S**gpo<3wvonA7AcL5sJxQP8!t^>xch@qJ31m%t,0E8YT4jafHuct,;_,f~~5$3_K$Ih?m-rIW82h>A7DMTU-pA(WG){+*ViCz+pr+<W{^.xmuq
::v[eHBaOS`c6up^P&83_0WU+{TAY=F7gL94J4MB3pX[Eb@Q%]9BGZ.RB1\5`8Hkxw0a;_Q.fVlD`3t|4eTfPki$`*H(p0NGLS6T\hu6e<J3tXn>Ln7oUze^)9z$8Y8zL,@e
::V@2hbb3nTEPTp@W\@{&-8un9^rb00,Bon~zV_iqeH4-El~Vu$ay`XKmE0X]#>OZc-{j8L^49tN10i*?-h=pP;Z&v;f/6&G|Xs)ETeX->iEr{eA$i7SfroLaV3qiuf@?T[#
::8UNNy_cYCZ9|M1qNO>.](|BUsA9UgKz`/p/eH^(TQU\MM!NGkk*^O8(cc~U6.4;a\8RO$Gs\;Li[1nVq{lc2@/6nG-e8K2sUi1Jv/xP4IJm/u;d|MEJU5!<wpa)4L%55qs
::K*~\jD7+_,8.pg`kBXcPHy$qJHk]o-^,vw|J/+Zb5folmUg\ikwS,#t@athr27C4jse5D.%q(#VqWD6MEg8a]$dbN#<2$|qx9gI`&zo2Ulin,S&PscO(@LtekxhHt@#/Pr
::tk\1HvI18PK09tcH#$mu@VoW!zP+@[{2CB&F+c,[{Gp)dtQQKgwj-}}EuL{@441bdmE)E\I8Ir6zAJUNi}sX0gNF9[{^45f`yUdGwAH@6VVJpdRh$Ve#6Z-6GVX*XZWR&r
::E?=+trKfG,B}SEiF\Om\N*|M4PtF#wkbR5kKdu`lk9umf_6W_N%b(liB}ti(Yr]sc_xG)8irUM+F9T]TclY5?I){7bW@LtfakrxMAFev-?z+7IJyawl@AP*N{iJo/kuwl*
::,~,l\-)lm/d~4V1owYnsje>~5W_48Fv*olc.zfbbGaT2{O6fSo.eNZ_[|=pexyDKPGn|k?G4VO?XE#ZC&l1|h*ad#le(WMp(>z.~TJz-\3[Bu~Mw8nTIZXo;/o[!IPrbhs
::]W;`JLK7tS1[JHlba?)z~S&qxy}BwE<U#,pMW1}f*/td]=kp(?#8.DRZcLb;[=Y1(bv_km%[FC%>cU,N3YJIFRbJ1nt=ZN8<Y.?zj\K9QB*EQpD#Wd5un*Kb9UlTM>E5I)
::LUr-B_6!dYq<Yj9u0e(~Y,725,=CVqcXz}9&J|}Lu1e#^Kv+CW1B]pgTq??v|cK4;J5D0_y>rejz{&(tZ0[DAjQ,V@[{nGt\<;DV$xnW~!?%PxSQX4fv[rX7v)3@fW}q4K
::N8.2$QkA}z]^2sr$YP.!g=SKK,;Xn{$77D;gQniq^)+o/@fZPmDyCD%{mv\aU8kcvl<($_f!FU)[ch]79g|2ct{|{z!3GTP{Rp1wmg,BycTV[6f&a+;Qg[ixJ2;7?;tv%J
::HPuQ\xO-pyoO~]/q{Z[RSjhiz_y}vX8_NM7tKX!DB!C0B/V9KSjkY`h!l,V|/+9qE!wS>qfa*pMV&)BVexxd!Mb[D|xK#KP.TFTzXE<xe%>G<p*R1*s^0tKN4qWi;p|Bit
::e*-HN%P<JM%ixxekV]?C#R=H>S<fF=&l-[Cj3ojLG,)pFb3;U{Jz05f>7]~0\Lfz=EYxC=gk82(h3FqB|f%m{v,IJ!*L;/OK8+.}BlQgb~\e*P0H9k(%Wyx2^/W2&pi7!y
::C|5vzR*B%joNQz>k*<nzfrKqN|-#tgY_~plLMIQ9Vl`SeFuV!)/$qg{I]!6^IvV4ZqcPHqf]/9IiyoRHO2n6j\(h!e}S2!xD,VU~N.xEH].IEvBzG(I{d;rhIKulcd|=n{
::3A6Vsa8ln-}?daFXD}!LnhP^<YyJlA!`Hbv6CJ\@/@v?}}9RMD4F/w}oLX2ChJ{G9BrQ]c4IUw`Svo#w@g#O9;I(E`9$gBY]6>-6DoB!VX=.1\3P%SM*mpO_LZb37}ias}
::Vx86.UEJ1!]Br5$UJVWX3m.f[Ytkag&=YvDYE{Z=x\g]uQe/IssYm&9_nko8XVd%xTxx>6}7w^ZNFp;M8;c;cD0$;}v@N&KJLfnPA]v~cK+K!_e!u#@5QR=eG{9G/G!.x}
::\)0#Mi`1*fVpyQuZ3x)n*a*S+y]3EuMxnT4W>Nu4~/i?6`Xo/UAPs$1->a|!$tUV0&8s7[PRD/j*G=<\p>={=0$+4E0#1qYOapm~0Tnp<{%=rGkSI|>cWphjMw&YE]hti%
::C/qQTRU9O8#tmJf;)_~H>$AY&nX|Y@i{tOG!@U>T?Z+ePp/6n#On/Km\DMz-di_@GSmwe7C+[*@$-?kB)!(zVon{3GY,rZxwIlie5b1F&Y<}v0w?lTE*-Xhi-`{L1Y.4[Z
::8JW$#0T^!/a;MIP26Krr]l0w]$M\yU,wz}0rd6+}lwP3OhQ}<?}.<ZUr1g-*B!O4;B?ba}Ix)`m#mGm0b6ogx(Fb<]95V~u)Lq~lio3;jrng;Rk%z\Z7`B;Rc_O1Gab[FW
::43a_Yt0Nbk#CTfNy_<l~Qa}o4IC_iKc+4xwZO5vG_v0+.gferesMS[BU^\0B57[,t1}]$C?pOrAy1)o.k_\3Yi=^Ubi&qc@dr0#,&0JV?P,r)IS|oS{q^3S!^L+wy]E7Rr
::1olvVN{E}cfd|z,2=$*.]f_9);.rhZ2r*3r0*PE~pVJfEyDrSBC1~F~p[wEcv@/NCuv$2^9\&WUG}SKXA[U;vB|#~%{K;[|i`.>.f/FWAl.CN&$D`NPVtw*$CN_A,FA\+@
::MQ-^r{JDyo63?eOx8)#A*vjszm#;3_G|N\,~HeK`VFB|zi6uEQ_[/a@yghqj7#>\Wf<l+>f]OR6>]KHpQmo;`i<dHLbJzle>${qg3H?EksLg&6i?NO=&9VfvaI=y3wmTy;
::SmXjE_x@VEyrQ(n&(B=5d&_y;jyFC1gXi;(=8Mx#$`hk/Sjh{*V[+8>=^}s0bn33[2tCnYWj^d)eN)O>(emmRJ5T18_)K%&[\Qzwszqi%LQBO,EFud^#<8z`_S-O$8a6c{
::fiEcRzk@!/CsZsnvm~E87LR;d]9W&8LJn\KS#7o5di6{D{Tj<ZQmtLld#i`Iw*7G+cpI}t3AaAd$?{XAizRD}lH)HFN(t2AQ-<@m<2YJae4x<8Ny.S(!<&@`N?%w]mL(R4
::=W-r+u31_Go6W>geFA*^M(\94c8A<_4wIa#~Cwrl{Z4CSeRJ0FB^7U/X0sgnWB1k$a,!wlBoN=,2]\3YpD4MPAR!SjE2susZ`{h73M/GEgH!nk]UCSqP,D-Em,$l$MI$;u
::MIw#wW@82t;G~kH]aXrq+4rjn*,ZU{0S&[k&@DX4/AfFfjjTX}[K/>{joLq6JN%v_[tmS8AFci\I31+FD&.oZVLU($&vI3MJJhWerdB55.%}9SW5%l5O&}s\m(Ng_sWN3H
::\`N}=(G$,D*4Onl=;i02ni@^fsJ=B-;AjwlbtiB_m/|ZSguIbC,Ko&F_*g?leVB^&bQ9-!Vae}a@w22%q;VxUn`f,Ua-+T!Ar5f#.[EUO/v#3AGRKId-,cI)LFD)[cM)GJ
::C/a!.wM^3{aFe;duG/^0baJO=Y`I{CP5(K4=cs^.y`BF}J<;(l+FLp^N!`IohRy|%k6Vj.xd>~U7%RGAYGgLYvU8XsI2((<Y>~H3)7{7da~-0M}p0)<z=cy/s&.|jmf2q#
::28Y|L6Z/eEVj1]|k#R|*IMQjy5|jy4`LKG(!0NMPCD`!_2uH7xG^v5C5j$Rj5,Ho4Bt)<f%6a6]{4T(I#BV`nL4O[\PCJ6H9,9@FWW(GhE0K1aNBx7ergjCb70QyqNX=Mc
::=GU4ie3~)bqGf>l;^arn<a*oID0,3kB3M@ZVz}<X$OaIFSqP}o@U2}]ox6d/Z%.+zf{o5$EQ+vM7UE5^uv|9#Oa;Tq;Ye?mmH4Ch9oT#2,0MP]%WTqH7M)5tvE8T{PXZ_F
::6$-&[.k.vF6J&Qu)ymbp_.>z!W+,HOphuh|\3!h-%052F{7zMpdNNdz|o5@Beuus/n=Cp__Fi@[.ryXFq#GSiB;/J[O3)sWaqUr2uYcs^41bACuWzs$K<(p&Q}JZoTP$19
::KCtmCU2@8X3|ugm/-&TK>}^8@a]Qn6<ie\HQxCrfHM+Eok,?-9nG5ELa#hs>D,baJ}JV*^Jj?4rq0piK8U!^Gt}$7A_N+Aymq+P`Pbbn3(y$yy4\<ct{S6an%300^H2LSw
::NthozsVOe%$=GqZr.|&((tcuXU*aRlZ!E}I<38`mEV1Nu-JUVhRw}hz0nA\pXX*|^E={u}8*zt]o>m3bP17heP.nqZ+ch+k1g;TuhCS=U6A2iIF})$t226hGCm4jFvmf;w
::Q+z.)vXZi==AFV}k~2b0mdH.{,2@If@nAOClq1F%jin1.2Fbgr%Q8Xvv9Y?[i,Dz&t$MX>]|_jk^J&,(inZoT?|bhy]\hgqHyk&sCW;`FATE+{*s.Rfcdav7R-q*OK>n1/
::2*gpn_@T^5K%y/fkryk%cMf1YNgqq.z]TNNU?;4iC&yxJ-7Y?b8Xst>3)1os\#KNvg&D`6N@\.!xFIIUwH;*%Rs~oiz7D-(A&J>(W{q<D*]a[qGQ*RNvgS~N8Ao_mZl77F
::@|r%~xps0&C!!_W0qBth.[@YpX]ssR<;qIXzrskTE,xYA[q%_$P#o*q8\<lO!YFZ4e>c-<g+N+A]%cn7dikw\#nx`rdA6OI{RU!OH3=VE$(rb1#*ysDC>&/z{TOEuAZtie
::M{]ta=L&kQ&8Gm2_<C1~.ol/S)i0&zg53&F.*t/Il6~iZ@GPakT36io~%?DY>[e=/t=b]geFlcmuOFXYaPXf.G*2^*WP%(PIRJ/i<7!]dt`v\srvqA.}8zA}-pWl=b/WgV
::u5CF;QS|wWX%?a~\}f^[=jx*^@Qlg_*js~irWAm-21zltQ7{k}6q{L8/2kPKBohGgbQ=dKJvC<Gqb(&14^D@(F+3sm\S|wvvK;mMuPZqV7}z4\Yx]FuE1Ih;VCYu|6!s+V
::U{P1nS~ok.M*<U?M0$+B4{LA)?X|\4^;?^|%#QvaAJ=]GY0@YL30bTHY/T.7%&qOH^WZ1%yvFj8^p(;8;xKC.7Jb?C]P*qLlQncLNaL{1iHbD$`JH_wC.j>;L,wQ9x{)p}
::)?+VI<ZL#r|y@TeG*tnp$NTx6)l\|;,5nl2H{/c_zZ1*cx9]g+sBo,KDQ9u,MODxB#C*p]xP/8v-*/)[[@H7#n}6gup2~}esM}}3XDK5[,;Tt#23/JuX[FJ7bbVeB*X{J;
::\zz.QPQK*&5*zXMCRO|vLA3n#0Ajki,V$Rm%pfDaUi|OaY9nYRiMmTZf_GL<JA^=r-!|;v/rs9Uq_Yb\2b8`}oa@LUDl\zu~@2M@}*ZIvT;~RSAiF_>ouiG_!|[kZ2eKzi
::@ql[rW#C&-*pD&t06p7qr8HF_BVu>fiv>0B)=8cWKF<oQ%voR|v72eM!bhHA3;XeEt}c{,7jM|Lz$81ez~-nmG(oLBKa.J**I.;hi/,8cHw^linsf$Q,^_]Xa37HNvEJUx
::\oJfG;twGykfAo@7hA_o47HWe!kjx/$iv)InOV4>5|t{_r`T=wl8mkuDk$.?;sdN{hxmQGc/%cYD-(aL]5E=+.EzY,FHaVLAsY[bP=mkEtqwjr|b!h3*q<!qf+[S#&JfA#
::8|NHzGg]k0a?k;D?iQH]F\`$0{\U>rg*(1/j=IRWD~Yyb]S,DC<3R%d{#$=FSx6GVP#vnXc!capXHnfbyZHEF76mggic{K6b5\9@62*T\^pcK%6^v5l)@+;\s?7+0+jQo6
::?Ws)P];Qa09r6[;xba-/4?U1X6EErmge^4K+KPt>m=16vo}+*[Wik9N8UI0^NtiH6p@}mS]rs,$[P>T#LtXpdzJuFCKO=%G%E>0Ff(|3?jvH$%-O9D97\X@Uz*xg8(4W.L
::RnV)R7j|0Mx8[>m5h*{+UX1!4v}H_N{^fofP=NIeus\l4{MQl^\km3s(d\{)?/D4*|7N)iN%_%sSqXR*Kb]iI(mwGU,L-c!+*Jf|CA]p>%6l[L(R.|BoS0O}]51|\q6>M}
::G;2@7jd3U_yY]m-l~LPNCn\p^a}2~TkT8+L%m1q44[D?sgKN9@}TbcaI9O9z.5iSL#R+NL{Y)kx4Q/m9Z$*d\HZp9@J6sd+x08Er1AN&RoJ9D=2pS#Q%z-}H;HnUZcMCud
::^pV/UUTh,Ecz[bCezpialIg,\wOB$2JX>YNK4vCAKrI`El$F-ulf)M~%M]/u4<S*nHVDuR-=m0}vl;OGh4bdF&gkZ+Kp_da;|~N#7q@,6^/2R!qP#gCZ2&+r~Nh.`?b&#p
::hz]ClZ_O?ie&Bd`C41mk};gmglmwcW4(JYWs?9-]SVs;Q@wg#GWrLlEC*5A)e\+K$%{`5!-~X<jY#oTsY-~8Ft$KKiFGk0?$&jtrIqrt$/lx-!%ZVc7c]<.(u}_R+o$nRZ
::!wdE2WEl]rA,M_2u,$`1A\}sY&)Di*9Sc$A$Xo4d@4sO|&Xn+e^`nf5s5DL;%6=HmZa$]DvTM`ELQ>(&,qkrZk6x7uxB_(FSW<QBy[MJ6$psG*|+aA`dR-lKJU5tHBRBzF
::^xfy}7FEu~}OGtQvEf?zUbZ+;B?hbz+?_mL4mr(/i5\Ui~8}NBTE!^Y|g6nY=eG*UGOTihC{rXr?|>&3$?1Pht;[EK,y2LOcgG7-Tw=<wzAW#GP+T~2TS/U_d~j_mPnRxx
::J^WjiT_|PrcH&_z~nB.IlE]||hU8ouPPqsUEm;/AV6]LK)jGWc+\dR-vzH+7cq%[81hGqa@j1~i9?p,T=0cYUrV9hA*EUzKq~a00-;@rA{abZvmU2FK3P`w\f?7{}Z|W|R
::Z[?=VGuNmbB4|N~l3%+$0>!eVR)lTkdUiM1m0FgeJ4Tj|UG$!A8r]TyiJh_AV)D~dwWS{X~!BD7f}0!u)o}_ghRN3_DYxbN(C+Mzm#WEC=[6d60^K2ASFwe>^-UnTF3OVW
::uZ4(=]Y1U{p]=m}JtI8RPcbh+>yB>N)<P%;s~@g,*V+*(u]J]\hD$zN_.kzc7m/jHSYdy(r)9kv/]x5BkPAsc$g*MzLJ(}U6coj!(1a@RR>)!XE1D9v[hoiwr/=d.B=zO8
::K7}[,@{TD>{K3*DL#04d*]I!4HAN$F#kipQPQi28-]h{D{floKUNbQnOw(rRA.\k#^lWmWh[!TlJb?[j7z#~c(ItUC+6p_%(3pO)hk0OePmAZ5/Rf_ny5I/fK`8/5]LPoW
::Sbt4,.*o#&0^3IPW{YDP)W}]1;R*gWQ@x4+{CFBQSZu(*gvp6jT0mUu/%&tWVHW=8a<i+q?NWL2yr*b*@SZoY1&xntSp`pN|pL4hj*q!wz;?LI<uvb>+g|bYh@Ufz@@AXj
::z6TN9},[q2jLtb~K,cD9JPcbc`|6rM\9iPm%@+XuDEr]r]+[UHdMTr-d{E\bG(>uH3qv/J/{k<z&jQM(ZZ!I5&*CRID\{`A4ToFc8/kNh<lcV@v<KqVjxEfWB^p-O;\7>+
::)@Sq5!6YgO`eV|)[)<3E\~!;(`J/wTy&O5)#YBJDbNlWrIyEV0>y[{}YY89$XVh_H}w&i,b2TzKJz;9.<pYgG8Ku4;H<]jlrrkhg>Z8uZ~Kb$pM3^TWqXnvYf#9r-N~GUx
::]m1b9d$;TPpBUrPAfEVaMpq,8E6!Eo,E<D1DT`R=E7<Te)v~\Z,<q4SCyrJylWAQ|4<*3D,&Q(qnTi^2k{)V<bm7hw<j2@bOfq3C5Pi=;[+Q]Ik4u/7?p*8qV,wWKi,{}s
::jv8Gu*T>D`E=<a0!OH=JcuOo2tU(_ldM>b(q(L0Uv0bym=W8NHo7$R}bs(4tR7azY@cd4rg]A+fRhzkm#t$Y#`yi(f[2i8Vp++eg+qTs{tpMQ[jmi,NV5Ygv|Z/sJTk{0%
::36,euIpBTdho#;@8\\3[ZR[PV7.@)~(qyqc2R[Cuwb&8mw1M?ydN`MZx4{@]m\#wv033kCHg<sVqu6zdee+vXF1Bg,+P4[94%oJroUKVDMhW<BZ29ZW0GbvIVm2{3VO$#6
::RuJgNrFsL$tw/[Dtl7;]h}6x_`8qO}S*@O]D|g\kK*q)A5Bi,Y|E,h7IuIA&r5/z*{a*=ShkI7F}kmjr(!)$<lHT~i%Rjb%Pw@Q+VY8;q&N{T\!4ZTY2&[7h@}a~c^S`{a
::h(P;DAw_z6{eRZ-DW2}v.PyO3+$PsH7U^F^n#Y,*x*Aj0j$qSuj_,+n~>70FR^>xsFOE%M[aC[`TzEYg<Pw_[2gs+YR@V#`nj>Q%,O,KmX0R2Fu3XbL*,,ZiTY17s/Ci{5
::G=J|!=uf\ew@Px*R1k2\rBu!7UO~jisPD,&^H4^2~CkG[JvSAJ_HQJ,.gMs++{t988!b]Xh5ZMRxS<RdF0N)fp.oM]o?T.*RAHIdE!.G*|J5brA*-<=8M[sDa|=Y3quz)@
::*5!HM=%}BwxUnVq=(C)cP%[a/HZMELo%eO*VZm89dWX<JORI#*3wj#~wc%Yi@502~CS~t~+wG[(<FBn<)9@DrC,j|WQpylgn5tjkzKbVmUX-U}5<wC,c-T[ftxO1r-KX+~
::m-&@kLemX-M`;%EJOF0kwu>@ukq|5X4.pLuOzcnr>6pe9TF|f[Em&{=N8zp1[v5?2@T{8\Q_`[te82e3Vq;LS+%1gNX(.A$Qx4/G7JP*fQ(tufB]mY8;%I14dT$v</g`!K
::Pqz|>yMBBms%0MMl!u0\cx`C]tqp4Gt{/R8UJGcZD0wR&~Q7lPEL^=-\+dH3R?L?o;CyLE9&2TSPY~zaxBZ&Chd<2$Zbz0^t>-+yf8r9dRNSZo5K5[a6g<~H?y/[QtjK>9
::C!@5ybqFi=G//Hcj}iDNpjdp6^$^YS=McJ6!<,8f|@f_,2Pc|e5ee[XgFM1,GP=ath*9czVDn|)qzeoahEj4R#,S|cd;t7J@.K>]g1h0bk\F>2>-e\*dSC}I,<@kaP|nJ=
::OaGD#$z&_7GZIF(H?`WdqZrc@-J%E-?.,|&!GqV+gj,b1R`9LYmM`mu6lSLm7W]C2W[/M7^qT8lM(]1+>YyoL@K[=-o,p@%6I?p=nq{}yPestb[!XmkkQOqQts1nIcba3l
::>>av8~p(|%*W=IIE@~XS3ykCBZ!FSG^l\nHpH%u)7a`WaKdC+J+|RE},mSr0Q3z9y`0x_#HJ]=~X-T,J;hZe&O%b)?X?[n~WQQzUs}9-3I}9FLX(QlP]1mq+I[Yt/9jCt_
::IA]8%sP&w(<\[a/6;AX)g6K6?/^Gn&ZL|dDgL!TO6XK]q;05fzAq\3o|>O50D(_nJJI23o]bu7jJE{Oy;iG2%[#l8{o]N.ZCO$KD_!sjQ4ig}a}ma]4%5_{Cc?dCpqy{<-
::]z1b&<`mb<2vR=9/jZ4g`xp&s7HzlAo,c^O*<dUc/tDy\>@G3oA,+Miyz\30iO@PrC1)|[PQ&5#&5zt?Srj96kj@hK(_TDb`iz%,34VggK=+d_K,#^Q-@hTP6JR_/W%wk~
::RTAKY\CngzX/@Q_2E#6e!I$8I\nw3ZDr29dJL5_hW\VqFz5r]_~FAW1.nMwr,7)\`Ag]wQA,fRM_i{YuG!psF`5E7OI0,,e7G*la4oFKC5Y3w+WP0UJgUpO4~FJ@-`\Jc|
::}Ct*W@/#XPI=FBm}sQc|LaixNs>C->V87p)E(YZaA[4S;^^{!6rrKWmNAY4O385EOrOBsiD2(|@0PYdq1?K{OXu*6?JwDng=VM,t#*{L;Ypx<,oihB[B.M=~C@HR`)}g8M
::89|D/StYmEgPI.{w|rmk^vjoL15^/R&R[Uv8P[$xJ*9\@h^EHQ,JSV4KWjsJ}fCy`;vv2(06C5eO,+4;ztAQynoi5ATE#[~--y<E(CgJ3KK/O}lu|vv9!#$Qx-sGZoP$rm
::G6$j~u8xm2Bj77)&_]+5M/hgEO}b&d.K)[q7%&VjS4l3c.V;)FlR6\$Wxt1Esh\P&Z0oha>bU`kpI89H*[dUr!7~]b*CHgAvv\hSs6`?jcVZC%iz<r*8zFUY<8A$w[~Aq*
::,g!tjN#_Q@2+bKZI_R/;hHfieA[7pfl59SEvRgLFw1<8)nq[S@36>cCwomJ!S4Un<j;#74COE%e]BF_qs6XJ(PxD@avWG[xJyvo?Mv<eC_c!BG,HvfBZ)_,Ej#N~MGV7wD
::XMdUx??tOhE9]K}Z^RcEJ{3n|!]w\#LQ<6/`m)is.LUX9o;hB_*\{w<L5u>UP$WSk~7CFn!B3bo{gaALd6Ra)g0lZ[S/)3(c3PMMFC{z<Yaz%`LqA|-0KW8*j^ZzPdQJ$F
::WTjVrBKQHLahYp>fAMoJZ3oVV,0Wb6tx57E{]U~{^/x&<x&#aCnqn/WeWWArD`afV8]t80NoMb{l<p|>9Pv&[+b%44fWWE{)nwG!2_}CT2&E-S?=DT~u!Ahr&O-1WllOU(
::u#YWw{I87~KEcFMoH?r!C<2um%<dDg/q-c^V]&g3IyOMg+q4Pd]f\Us^,RGqlsiBkF._{(Dy]a!;]|B2rjN~?zie5u;W7vP!.Yjw98Xwkef00v}{M&N4qIE0Fp9Sfv}xiU
::B3r))b*QDy8E6rcfrjO&RnTr<<;2ISo#16QFNgcvr!0o_4L?MSn2h++8dv>_\GL*V0}O<aF_|e6OpR^ITaNd?p},g9D3[||zLfWe%I2DNI>]yRcE#mDb~}Y=X,dcT_Po=K
::tZyLrl0@SdI`2qfaMlA#zZhvpZ<XyQ4nTUknJpQ63K$T[6wg%cRj5MR3`C_-lm+|_$Q9P7?\7^$8K&Oy`_m|SO+%B#=L>RUk=jlZB^yy[|r5qK....y+..a^B,pSb}I+o^
::,P,=mdqI1Aq|Z{ij9Dq)U#j.l[>6a#9$U6(,F/&N6-|)`HzmqI;k>A#|(CQ[)+?_dW0^mi|w*d0[Pq@,]_<fH.#y\3*-#Rbd&>]puj5!O!C%{0Z[5`3\/p`txivy6F\x*A
::/THV)gAuM=D2$xWdOw&],gLQ1b@;nQf<R)G8(.EG=;e3CpL>h<7yp9y)FI@8A{Bp}tK[nYy3p81vyInbeEh|X%{!`%Qx43#|{NI!pAQw1)|NkZDK.>n,G,L1W.7aXMZN(|
::A\;[NU``@rMuf039SH/E@bzlguqFiM)FuIObAFlN6WBMm?n<gQYf=k|-52<T(;R$pq2((Rq2zi~5Sxkba<TSUTv!{k>hd,fpS2xjZ8j8AN|@7,|h/fJkChHMxY)V3$?-{w
::D^C&jIv?pa9?1%RocZu,aC1;h*uNVV5zk3eC$*zneNy7`GyJ/oH|hxuWnbualBY\%fOXhHM^4-!jn2.JJ2zu!6;c*-c]XjeHTro(6+EI*OK8N|vsMn,s4yoU)~yVVB8se+
::H1O3pFfsH%BW&L@W~oVN?T)U.|xMOXACg-@CieSuw4laNKsq3lB0?,+OCYf~?N^c8-V^Yd*?E0qT<Z*d|#T|p;T/mm14VO?NLrif)~o8W*-H_15tF2)CC)VC`{PK!U#Re{
::p!?ff\+d#VfK,#GE5)ou2}^#nNK>MJQELMT0zY`\^_5<KI\tL5`>0vF]0%fj\W\&y`&<2E>FBmlvq9IdG~[W(\cQ@M~U#2}4>B2ClpehwZeUVBkid<IQJ07Hy*M&vS!ikS
::-ns@2q\zY^Bd%U_SDKYc4=s_6sq$%eO[f-C|6+$,|sPmBFh2.W(0RpvKvjh}!N)se!P7?EDSs3A,bsmC/JM}S[cUvS1K&/B+u<?BeU%~nG*zq7tn8i+6_!$!-<cmTF(Zo6
::CGCZ>.<*bkVN%,~I\=`@+TL`BMYg[[g=j+jx5_0]<FCL0Gjz8e=T+dQ07hcolsJ%iXoz=E[+^5i9LZ`*gpm.9cgqk^G8Z[;Jjy9-@KB/t.&_6h5u_)(*-h/l0nK`/dnv8F
::Lyvmh#%-/SkZrG+!bQmmK,YHg{|LHW`H_6IRD!xI5MK?O^.xirqW|<X|pRQad*gz}6*<r+[xTT2msyrRT]_}z&1eK%H4fTKja-y?rh5~$x)GVG\*I\)d%,}jXqUkVoFoBF
::0c7_B%W4NULa!$N#jf|is@@=p`PZ&~tHI\;e]uM(Y.0U^4q{}+V&a|<pW&~ZM[_L%gW5<9>yZzs;ep<{!I);nyQsL`_C,is8OSy0G*g?1<mm$aN!unzzmicOvwJLrW=ovt
::imJlJmveO=pSI~B/bPPSReUbEg8GxCr/dpt6t,)*jMk3hV@e6opvJY6|M)OVfn%z&U+bt{lM%$]i25tiqqb0u3_wsIO%$U?7iotsRBk&gWFlNe~vwHzG&ndxEu.)LR!1Zu
::ge2Dw|4G,o{uAgZ#;bWq_@)$Y@n!H~FIol]O[oORnunc)IsIheO~%z6vzE^[o?hDuw2lML1cTSsq<_#9/*57.R82fnETb-[&G,VpNYx2d\I9#OKrc@z}@Xfu=VLBX2`<^T
::41%KdxT`)&Bkoz$+uZ)[)6XLly?|Mco/;a0?CZf$7z8J?ZD~_=qH,qZr+(1=a^xp7~KKY{]*YSOnf3/{4[3Ijp)ue>RBw|#2j@DttZ~h<A944lI%t<`P.fthFejk^/9\t+
::E(FWSS.*8p#!SLK]nk6<cov`aj>$G|VVp+84k.{pu)O%}Ayf_{*YgGKaZ@\X/vE^zDK=]c_2z;raK%;!a~*tt,0k>N448o/shy5%r$xeWiLkf#FOaB?{p.r@w*V/84qiWR
::RY;-!seR}/WzJBrdI/D[g&+HjQ&15H^}n^fvh`8_g|J&-x/s7-x0IU6;1Ya9-xq,Q^CA]nQ{FB(00A([,CSx\KF>p~IH8R<ia8DI.fPN_!94+h9{Dg1QG3cxC5G=tWS][t
::7tT15]{2.aA+5w0`o^9s9(}AaF~G>)/wR|ymNor[3Y[{um9S7XCK(ZRt-{d|`*v<-2C7V(DNaK!Pmoq5iSe/<C4p2Q&Cg(99alDZsGSB0}g59\zBJ}NGyQ!d(P!pH5[YFy
::F\?A(^ln-q[4E]iL9bj+Chb^(9fE5-_Xacb.hIFQ{aqvD+91{^=Cgy2mk_Ui;EwNLynwpd]QUAG}MGo.K6i5l5>uakQD.27@3axS@JWHhBkCli\u20,5+LBXB?TG]TK7RO
::~?y_4?[^~?cz`(vj_gIa*#][2HS|`x4t%c3$Vn.2wzS+Kb?7PaIB0-,BaWwuD9<xia|Q}5Islpc2btJ4~=1JZ+7X[SPz~mj]$qpPmB<9poZd@{{&Pwu6?32(R96+>Vfa;p
::wgdXTC=w,,qA4\c}Gy?/$PUN-4L&C,Hw>ZTaTW^M~{Z=+SXsb@tr8c2ZS!=/8D3+H<k9Dx8?aIl0r4W*./.*j;b}D=hh,6bq-<\Su9xn.~un{&A?wNftB%[$OEfLc%SqlJ
::}?PpBKaesH}*!O]oDZF|8nh|?wf](UteSG@xb*JIW#yLp0eWf2K@*ee(M_3I/r|9=Jl<F|T=IZMZkYf51i^>tF&@+N{mMWs4PcJP3\)(P[;b1zwGz;Igs-lij?FL#9&T6R
::1=a[.#f?x5WZa_!HK!SWZ-}8d{.y}78|1ZVnbaYC@Xc}sU/e\p~UG;hKuDEH&ba{-VsyfB~/aSS9sy{9Q>p}Z3lp&?P;q<jVP?-Z+nu7@o]`Qw96}MyKyalRosy}(p[bp@
::A+R$f#~Gu&i3yH.AXV7iEZUGiiAbTM;z,(0gU]PIT=z)j6;dWfERNRgKh7+;6h+[Z7\Mb$_mF`9nULVHpg%K7qoDG-3yua4~+lw[/O~nKx~H<baofK9wYY{(=H9([sn2g%
::3FCi7+nh5x><KkOmj1E^(63`t>YK>OdGI;4dz}FCE8,]x9Pty)dAe(-kVT4;U?K3|CE9?+Kb/(Z)k9jE$EY^1JhKg@JtkdB16lt3oA?&L+Tl*|rZE_(f<ORJ]JcHk8tG(0
::,UVp&u6d5[rL\`F}c;iiu+kt8oq#)FEq@i{@k/8j<bnZ]VL)/6Irxh3\k?(mf$Gf|eA2K0hHfcYh@T}?\x-O.K%5b4dPZ5gfB6;|2[a14oYZr=9{Xc48R++].-vdV|e2E.
::R]wa.tFo6n7(2`ip{[~58^0r*)~IAp$P|;yZ0!c(g-=fW$K;r`AGQ2ELi*l/!u5Y2mc5x?ogNu.>iqq,/3gpUqGpMdRC!{c!cvYM|Bj~yX|R>+!Jt`Rv~_gQ9dkG0K0=(T
::aHaB}byGNRRK-Eb&rzy1.cE][$yyTNc8scXu~$&yayt9#\{;(aSWHKp/7<u6n[y8tU/[NQgZ$?tMRjLt\&EHRwT!A=}3CNCC%+Oh5kvXwjBHbvxP1<5+06N7)0bCg[85vE
::v$X3Tg-7$E9BbFC2IS?Yl|g8NK5Lhi^YHL#i{7<Mo|3seREfA+=2Ek>uC*?3GuZu?@&sm=;kkx`-1|n*4/89SPLpix0Ss!k)$)0hOVk9[A?,.yj0|tPlm%ymitY{1fzKxh
::i3887WW\x^KKa?!B/B\W@;`,lN6bFFc9}T~qn&v\y.62S9XdsCLnNLnGxNSsgjwUch]wD`?#PfMT}e_]UgtJw18Lj=$ZY^1J}Ni;{S|g`pLr6}j9S+Wlmp`0$!E?_ZkU=<
::Ki(Bp`}u{#smvu}wT[$^i32$\!_Qv?AK22>bJIS^_%=ySU,j;oU5<NQybN9o((~0f18M!jD*!LfFf0Gu!G=nSp%v1>xm1ytw5y1CLP.jNNt(fkB;w(iE>N0y/]l%*dQQDU
::_9j<J~W0.V{h2t~L%AS(8hzd,SP~UgU]y)ri5Dl|1;&W]?WBt2[PF)SR;BFYulQ&n@i@Vy!^46Ad{g9ZW2Lu#,M$Ob],58b5gDeC,7w$+T>xB9(<9r1F,9EW,d\S{ImBUj
::#h*%;,0Aa;6d|_1%v`h}z5]0/rGPg?cZtS.vh[mYG3K\b`Ka{{lT^*k`<n]l&r)F]`fJ})MLw|QSnlxVqj~TUy}d$|-,R9>S3T@cu3Pk+p(JH/;wtG]Z\-Xj<1G2V*kb%v
::Kuo}Kad~XTD{Eq;5\%Y[7dGXn}!\}>b*CBP-(_KSbeEq_aIE,$~.Rr-Ans&TM%wr_&HaPZ5~I.a=g4pN!eHTP^71#5Tf_9tvs[AyMS)>f?2k5;>6w>2xG~B)CO}?O{6q~&
::]dyFYLV}Og;v4sEJ+.W+-h@ME1m9a#>Jj{H93\{P*r}ani;fub}Q}dYRi0{|$yp@]qOkRpXO6xoyOtq!XJXDS5<?#+i5[EGs&bC;y)-x;T%pfSBr3VjA7z=Q6`zzWOoBZQ
::)*;ic/}j2lj~rb53(qCME6w*=SietH`Ii[73O_eCNp#*XeQ/xWHIP(XEXMC;D;Ym.jzX2-`,tpz%@{a`+I%xn0x/~~=Sq>&0g9)q\c^YiktZZ#|*{1`IEESPocDjKH;@Wx
::#L)k@`YCR=1;./Br-p>SwtPo,B@CLjc92E57TW&_^i&}}\`q$7kVvaY)>g@-FIb++dfZE<WU@Kq37$g(0S#P;nHuRRX~$9z07NyV$P$xa[~l|3;K`VN7{OkUEusfusoxX,
::~de~HU,kPsQ6ASGNK2OpCb\w@#bYY@s]/oFFK,CQ?|L!|EY2ucRQ||(=(R!F0rvVcB&+EVdQE@@(|6yxf6dmkax1tC,1~jq4K7<I{DpK+eHS[s{/I7NGu^RBEXYH/aa[9S
::F{Yy0I)F}1Sso0)t;@R~nkjD(A,B);--suqM0kdS&q>COiCBX&zN*q}WA>_!ar(0qn%B<{k|/r|h6vJc!nFzXp60.}7Yx&0(Yl97\Zfo.BzQZo}FO=pQMM%g&Tp;1;(o~{
::#N]q6&8s?8n9&zeP9s->E,y~^>|scK4#A61Wo\J7Pz~fGhLS86+DQdns9/d9+ZT9>r|&qyG[]+*TZqcI(-IjZucS#*5S&6k)C0lIfTq[cl,]2j%`.5;Nbz~1+iDOt\g+lH
::eOHGoR?(3u2BAAs[owne{cljd/p7JP[@-4y+sap<Fv!,)K[k1jd2H~^!=8}a{82pViexE*vbr{(yJW_x6PD*;]*hoct+r**W/HxY7R^[]k|F3fdR1VDl<ep~Z?Q!hW~m[g
::mL?Thp=JsuHWo+_6X-O1V1/qWjeD~2zQvOqQ0r[%M[YrktN!wDc`B}soWtf3w}M&wq`p9U-$CCd$!|sA1Ch/qWNaGm#r}KvJscw<Pt(]hzrnTvFqIPLvH#0S`,tC+a,-jW
::X9AB7nGMM+IaDOWdO35I-sPhYBt_$|7v~J_,O_!Zg06>NYr%P,lT)\-<Gzz9>4P&XV92+pKU-O#%@MPbNCL3b){&P)imdGo6v$U$Lo?]GcS<Ihc7iCLI\8i\`z#VrnC6g}
::f!#cNhQQL*h#+Qc#d!3Vw\#6,9D(SYn|bn(+jnienEAmcD]p>;9cGD3gcA({$X[YNI6$YkAD}&rRL<PpRtR(epU]w-@2~3Yu;2/!|X*n-[9PU%Hi(?2s/lEf]Mkq)\lxQc
::dqP?SZlKbMQ)HkBO3=0.)Aje1rwz^3\=QSov;Qg/y]a+cpw5h^1s^*m!XvXa#W3^Bx)^AqIY*4D[{=Z07<e^*h|_fhl<m=CR*cmmX1Fpq`^X}7@=}j}[y_+)cq+kChLxvb
::AWwys7m#Zoix^&g8CZjpTycH@X2@>/tow(wz<afIVP5[a>B/m\n7+*CkGTk6/W12wlZ,[bf]}3<%jp/].1e<)qZWjeP?%E3|XB{2Wj0;ixY`kT7pl0?/my29|skb!o$&KJ
::6\Sy3xWait^T0\EqD7P0uM]rXtO4^f`cwm6q>mbfRh4Os$K7IWJ2kg`|qdGg}/bWGqyr0&=TNPFXd`q\6biL*_se;,4iu/atyl%gYa3$5Uck^/+iimZkn-oygRH^pLQSBS
::.J|JWmb$kJF}&]A$F]*vj7kKkDbCZS1n8~/jren^(=-E6$FgVI.\EEQKB[.b.wENDg~6eh,iE~>)nTU@P+oD<xwSWw=(6|]5z?qh`,nAOCX)<eD;}NVDA?EKB{Lt[!XK6V
::`3Y9{S&kfLW?e3~]F#E36|%W#O@$Mdewb9h]?W&aLEbqavN)I}Rs(\kV@W81SJ5b[m9rU`#i3}d%w#a^f^R{?sXD?@#0|)dY]Fu#I;Uyfw_nrD+fPX`8YD<N!u!6}@O&/3
::b8.2g1{oHGDX0taeBE)X0Vg7m`WT}%Up{#P<9nZ=wM?]LH>{B%IrBV[6%5$@|A7fmGn7yv*Q~o-zLV`~dc%;U*0|_mpy@#XDcfL<NF>/o7n&>=b_o`s@6(c;X-#YN.gY{x
::txb6+(b+#pKk+o9?e4$|(k]{[;}T3;TsLge^`L6}<5{~n1ei#qfqv<c|kUxucL\[C@{)nUD4<dFhQHUZYoh,\0t,n!d\OC3SRQ$4DHH~=}tF8rr5M,|Bq?o7IAtYek,OR#
::~5)w@oku;)]8Tj8Y)r(^h,FU4<kGZ\MT\SO_\Wr-Q.+M|dn%A/Xo]c!)CRm$-\dq+?IIVUzl{eL)#-2zh`AsRM$bl8lkCB]34rk(L6)l,$j<w<fq[5vN~iJN=mTfw!n7l^
::1WNm(2WFyTK65(wQZ5-kXJ`mO,^3[7<q*j{-<mxA!]X5,bNSMG{YQ>Xy#XPIvrCErV92j-\BJOtr&w|yFE]sd^G3d/(tXD7%sL9&N+(r><cjsWf5(.r$<w^.Sk%z(e91/B
::i~E~/`Iln[1Zeyv#zwK{B7`/k{muAjM3A\XAE=bX^CmUpqfXWyhd8B7<NrIPS?6~,<+$ox$_pGOU^#Er)67$+1LaNY1kPhn~G$j]YH^*}J?hGS!8Ix<NmQGqJgq##d,]^p
::?J|Gn=Xre%|@Na\0w7JH+2!sA0m#F(/7Yo5M1IlCs,Z<a/NTFC9D%^Q4Qqw<sg+lhDBG^a,k^rN}~YEW?&F$sk27k-2r=2P4Lxmx1|m^{)UG{$q!h(Y<!yWxM_Yk4-&K6j
::#~C&aFsQGXyjLSU,eEd`[ZJO0N)cIt_7R,ovxKa=q$HN_{7~N(j,iY,(8rC%k__i;ixXf9H}sW+~9Jc/!m2NtpZ_5DRm~Z9hp]zx;8fIP`~3RF<x~6<Y;IEdr~hKE&[iB[
::|*Tk+Z;&fb409cVZgh{hZA>yh7*c5$jy;S>Mlj*?;o;@>}#tY+Q[np~DoBi2=TJu|@Pv},-U5/P8*NT=V`BPTm#4]EJq,(YE*dnd1TxN(^;F<bxQNYFXQ<#qcF4T|q#R>g
::UkzzK]szIM>zFf3lertp0acKI1hPif;rINP0zuFfuvF6l5=*5{qAsdnzci10y~w0qsL4gbnY*^sb=;lu#6VEo8.b`9.>k%B$=V\U8ZPVT=J^{yaYarkrZ<1MB{z@D2Kp^w
::8Oe-4W2WDDrCAf^;6ol^%Q/qQbS9u0`$k7k,!ZoaVBpCZEYR=1M|)z$(-?<nLw&`%dK`a<U5Ri01,3o-_`JedNsH]uSIY,ZsTZS_sPO38!Cce;q<R>81xkd3lapy9Mem7j
::B7<)%URDdk3.lpl,~A#DQJNM<UlWPU45,.bq&N[&-Cq]*cVPSJ_4K+6oRBRp*wM_JpfV;MRT^kfh!mzxE[m)P,Y9)_?|AbmB(ODb$u(V#xw`V$4sIN-#q$$r6[VlF(s1|!
::kacX0XjmI)pUS|-riX$a&\G*&L(bOR5psSZi=*_t-,*hq-BFjuT3}?aAa_P/@?*/*=K)KEz8>]p|N/bD8rc).%+Z8wy_c7>._-rxn&he]8-]#YO1e*be8[@gy=O1wl(l+k
::@XU(t}yhq_V}epoY8=8E79>e2uTVl-c<3;CM$7>GuRb9GME=&(2#+y6_)eUbF-$yvDS|1pF^_|.*Ru{mW^jPW*<tF$$PUcsip7W?FTveEI_Cz!-#KGgHX1vCw#b${WBP-S
::lbA_=RrN$)^@Sw4<xvvDO(jg4{@`_QpAFLrTuZ}cD13<iglP/\.lwb{4P>7bFc>F)*.j-%%Co6Egmt(Z%QSPs?S!YloO5(oDvf?L[aOq6@K.18S2vsxQK3/Kx3svFRyr$L
::|\w1xqrXuRxcW@*89y(RWJR<cii<CDL<&}]}w+-79#0J.(4#XADM,R*1Sgd=R;D&b`NI}tP|wQ;T(u%)0[w;QA0{v4t*,N3*t=A`EYKz%cYPJ>dpPvT%A{fvrWAX7fu9?r
::fc2Zj}YhI84VQJMt,5@J\?e`fT!$zW2$UbTU3w<~pqmkDbK[x^vvLjb*+qs]YdVgKL7p}^e\hD`7cJcRX3g&m6qv{#ju|)B=XLWa19@k6EDaI;TyE;3;vdWiwYlFkYE2*}
::k%dR[RdD>Q,%nd0MI<B%k@}@N\{EqB`@uA8)F0T2w2v;l#Zr@8HY/tfr={I[l0Ld!WVaDxYZj-T[wg<%gDS!=$s&tQ*u0P/+Ecoj5^c-mKNA<qB+B$.RjM#-~ZndEGs*]k
::IvyC@NKL!+wx)l3J1d>eDxjIdVR2eybU+Jjakz6bQ?Od$Lte5fMFIW+/+C6vh`@KLL&NLWbk-+%Np$tpD_}Pxv@JI7$?(r?PzcWICSiNasaRTKH/rVR*0*Ia27{N$aj]t;
::#TrFYNB`|^xIej2G)WP*F*}`y8mNjzzntE~l6m]%;$E;GK9B_8INmf5H`RMb_/P5JLXPGbnGP5w4-^J~RLn1>o_r#\]{F4gv_X\09Y}&FVhMnun,NMVASVG>4OM;>noTS\
::|=Nf7[W~9+Jnb\aka)KaQYjaA&zz!L1>g<rsBQ4j|r+7$LeQ&cNl.sMx<ISsJhPIZRJRV8ES2{R2mMf/@A.f!VkQody5ejQCVMB`,NCt<FK{Wb(o{B2d%+14K7[8u,pZ<e
::D\_N1m{M~Qc<Ay2?~&Yt=$lCrD7zv?}CVMp`R&XZ2b`~C*\?C<%zMpj<(N\?%^_PQWsTVlE%yqHF-x|+3cvkkSf!1#p?kwS8qv*FapOTS#a/;@-DMqLEeVS(.[!LVO,HR0
::=UYVW?Jj2`W]y9N26rdx0cD|nQn?DEe[Nb0g1P>hvuzU0{|~&doZOG$o+t;2f1SOoqP&P0e/{$+NjzxE@.C(iZ<1-ennBf(Ns4?99nz5)JT(L/&[sM5*brVI653235t;~5
::u2H\T}`aFTEyT}y,H`9UD5%gB$D0+)2,m@gNP5ef98%_$l_?jP<o-iyJ9sL4El[X\PxaX;YJKdp/q6t;h5V3UNwf7oZW*lKuR@c.(]zBFL_8g38avB9W/$>omh5-u!)t*b
::u_{Oj-5[B&JD,\-ItM-v>dQ2bS6=40xq2`nvX*CsQ8tTedvcv3hKV2!=()7v7c3Bf?Oa/mkvxp7RO#p^=0<LZ0M$BlzcoWK)*QM\5+Al{D8w+x3[,Cv2*U;0QXjlq(G5j8
::9o/&OYG+1#.mP}D+F_V`-43#YUW161!R70H(8Ttm~*!?mF3Ak~E[UOv7dVB<erU#*$B1`_|0f4]|XB>+s^#NO&l)EeE[7IQHlk6VKB=w&BN@dN_^fu>r4FSw\a5*XF=(r8
::6hu|suQeV[8!&Z4[umovKZTaC@MdhLPoLc%EyUjdBlJf7?O!-3VwmiHGv6%x?,\fO-qf?aEt3@\LI1VNkiS2t`Av@-3jwy!Uo_D7HKRlI1^$]lE%jp).c|lL*/A@),XUK*
::XD4hQ4pm+XJ)(8/|hcGM_;i8[Y7F%f3%Oznh@aw9bCWue1%f1hTm%`WLMDyK81SsWNxqE{S=)vHQ_k1kk)6=1V/4@4`h/hbNz3_q7gZaHh*~]d!O>5!\w`i)C5-GGhTm<m
::nW/I_cvyf[<+p-^nM-Ekr)qOb[Oc*\3{$@CVG(i&}a79K1~5\6*n0ac$6Dw>HK0nrLqYIOxyo/9@+Xy1G*0&<|.Xf](eJdAaqKG#p@C?s3Y#tv@l/7vyLcX~=K+R_39Nq\
::jr!K5JKt{VH^K*_15=NCD_MB#>mKrRjtb~d~%g3{Y89N`zBT)YI=0N0(902_d=.)_80omM\%4/#FCpx5o&cvexVZTSk&7+`eE#3OJlX`A2KJ?&/%L\q~;t%0H,z^=CtzId
::M&@?tM!dbXPkY~1)ZFT?t)e+qCU#rtaf0U$3~W}n;`]4|9!;c+|fyf46\$\5qB1v2m5N*nwlh{gh`7f?~6F/YI^s?D1B;s=10=6D/~C@)E%g=&mD|5$>B=-5K~PuQP8WY;
::.qjIa3kBOMOh6Y;<f%n+oAwsy`lJg8R*f]vM&<0/}<_F&v7oHLrq**00z1[65n~%TQJ%B/Jk]ckIx4TE[d7MVzpPcNu~YWINv$|ru\L\mOo@yWS<sQD~25JsU!yHIN\tI,
::9*.)iqp<I),`5+$!siY?gud@,kw*8+,0bL>AYVyw@rKkn$dSDt,/886lK%gD$zYWH,Y8LqM%C0[~oYV}Zsp{ZiYHGkj9&-B+oD@q)\W#^ZcYu!3jS%YY~m@Ls7\6}qTGC\
::-G5)YLk(JZMmAZBXL3;kC79q*+5g}He\Q]F,;?[Vy]8V_R/T%yN1,E!-<<BkTyi%Dmfk~j_]Ya&0eEb^dDWomDe$v`x-IN1MB;vbtYo,!Q(kQ!8<euB%5(`Phxkx-Qf/!^
::)oKQ\/}a=!*bX7\PMD&dil6[oGdemKz7yt,H8-qskMwUWkUd,9DlnXVF.KX?j|07<RfpmNQv%mVcoDND[\8-6}4WTE<{$d8Ng|=b2[yoGx)O/dyB-%Rw]I[pib$-[n.S$i
::9h2CjS`^D^lZod/[N)RK&*6TwEn\\yPXBrW*li,69mZ]G<Lu%s*?>Er?!3KGW]&mzGz)n<TFt<Zs4myI-d@(w6U/;{|}yu-pf|e0N,#lQZ^R(L9-W]QeVze.eR5v+s!;9.
::X$,Hb)d{>,U@`)8S]jN6aFONs$\h/Aw<3_}og&o){ljHXiE}E!9zWQAmLSe#+_[R2Jfll81,(^$=EE>{n{9nO5z26CntTFr;JHLm[G\I}V23IAPsI5L5^3_rlpMe{Ck7AR
::/c~0B3yL>y4\ccp*F%h)>~ugc8Xj+WA9xFh1P|LVt8B9G;MMA+;z__ApkC?ZcGmYLLPU$=7{/+iJ!RP>U(#F}W@0G%[%;OkP*!c4UZ)i5Z6nw=j22i4[cMVB%O?{21Aou#
::(Pi/P9,HF*6AXJMvN`B<^mWO3j~&t#vCNkQ3=q08s|3KILHH5W5/v7kGGFe|Szl}/]KR1gIA7KV(j~&MD.c1Bj$Q_;m\s[MFX$QARF3S=Z+;|SRQ[rwKiY=<>?W,-gpv8E
::L%a`x>bV]A$<gv6Q3UL@M;raJ]C6.xgbh)%wet7PkLE,b`m-z@2F_`~v75EeqJq+(S52~;<R*W;$}>jee#o6BQK`fW3lE1>2K.v&`SKWP7m0t+IL%ufCpQGoGnRVc%D}k4
::%Qt]c3v+JMC5xP<M(/k<{nj\Q(1Gt+]F{b9H_3=v9+Ph3l2k+KJ3JU1DrMdX.{/%{[/,w#BNWJ*G;l2m;bXMVncL;]N;2nr7;G{XpUG+Nv6k@Ur2zTPEWJCvI4kYy06r&l
::y>Icxwj8)uCFkT@o!LmSK.Ur373Jdj)xeYq@;SdA52Jq$+;\W9Mk~^*dv$0$3O&tBfBvQ9L$9=g`xW<@*ZD^]!t@X/6mpMV[fL(gmaa3mSJc#eE)U02FFVjbF%8_},\l&S
::.2p-BqPSCe~)7gDyF(uBiFAhA3~>63XxFYV;vk1^86nzr5e#9<^nh?Qc-\d;8($Z\}@j`axg3s(ae^a%_%Kuj&e3uJ[ioE;~pS)`EWd(^w`+`/)AsH9.BX$f<B``m8j>?c
::!z,&^NM-mL379NRr*%Lav60?70ci`UOtR%$.g0_a{Up,@yzci=)6O^>1R@&@Ys7)oRSyG&-r`?#Dhu#,V%ut#fI4al%KJ6|s?FfrPg9e$40!bgMt&PQDt7Q*G7E$&SkP+%
::3V0e}WDFDP2?GWt6luTWxAFmJ5@f*[X=PYjn{N]tNvxmXjwx%=>X.4axLgL`0mf|,Iw[(xX0TTdak{.x6%0n;{KMZCo4e~IKM3ekOC-2HCws7s$OsUS[),(Cca9Ka7t.=c
::XgljZbP^qveaiC26I&E?rG<R=,K@_Yz{3rY4DZ\Y;\$!N?Qenfkv()-IiMct1C9SZaICjY9VO|T)M{Xq{(D)M!hRm/yn|\xduen|k`k1BC2cr5IOZi}O{$2A\s4N^t-Uuw
::BPyTfZANuC,=Eo#-PTB<i}J,\gmq+Ck\nxo*C_(l\E4#r%vj]k9CVkCaG?[WdNI\L2*wG%|@q(1|3r_kf35Wz$5,PRb[d{rf/7?-7Fmvwo@V?b*TQ!PV;~C#J~!TX{y?NA
::8{zub/-=m|Y6j6iUmRtt~0vLP!\3`MspU8GQih+IS1WNAf<[g{=7hpXQssZ1-r+iSU~K@{RFZ|+i.JW8%7=5LIf%l&,t&%%iRc.RZi0n0G3_Z1%FG0do&CxtREC5uE5mL5
::=v}/T\RLbQq.W}8.or|p<49xrv~XACI\Ih2(Mq#D.Z?4}&AOA1;[M7/B~<$uDvn1kIi;@AH6qIvy+M~\wGBxg9k`YmwjXGNc\k7(jNe+U+6F+5qU(5Cq@?px)AWIpOMw~o
::t&SA}N5i#y7$WmZ!+d}dWP%3Y&GXPHK!UXOeW1YlZZY8osr,*Z[vTOw+Ibx~?.Zg*$u$U%ZG=lv@!ULb+t*QvZ+#]aS_!xlh6GQyWTD7Akq$EP9_2.`=+K<s7m8Yw\P)X8
::z|nsh+NSM&BRj_-A9k&~nJ!<M1Tn^/=)m~>>)\Va.|Yx`?;)]<YWpb_!B!{]Uap+;Kg~j0xi,*|[$o9KO#6rL]?S]@3,41_t,}]}}f>J^t2IS![Q.`)\9Ab.!ygMhJoS51
::QLSUJG|1u;nwTT)Ic8in&XT&x(lA*~?!%8C/kTJQ~XX4tD]5Ne=\bv.P%^C5(oZ<u*Qm}<kCs/.drM`/?x}El1MA?uLdM6^lgBo<;tG4i!kD\Z\c}|TV@t&Lb?cvEN{Qxd
::xY9@~E+X5eI`RK5GSd0J^S6eYqfU\LKw,Dk@,*yV/bfGHL^irJ?5[LQOH))t=OK?dU7u6=`on!#cce]w=))r9j0v(wAz\V(Bsk{9%*UcSI2^;&1U*Aw3gkVC^4-R]r|TF?
::h3+*Kp;l1*ndeRO_&lGe&A$065^B9u0k!j;6>3{no}O$>u%s{6Wh,{D}qC;9Qy!.i?=dY9ry,&+f9[-*<P=3J4t7K`&VeX0$/GS+BEqX\%JTMz9d4r3#]|z!WItz43KyY&
::C\9dn&_*f%+|uR+z]iD$*Tf+4]IUrLSNHd*{~sDc2_4QyFhAd}K5mz4<9IpG1{b.G<*#/2lk8lpb6A-k.e%.UUM$Y3@g1s+%oqY9*=[%|,ufeeX*XdxgP8G=FpJ^66E1F\
::V]`[?_$gI!7w@4qpBxxC<!b<RH,\eS9t2350(o+R<b,tDV1_d0FnDQs49|k(W%t3[X$xLgWhYWWocDa^m9w%]f,?2oqk0bT2@)fAbU)}ZCwv|7n?Pl`)``*duR[5EiBWug
::OTr)8+~12UnJ<#D7<`$Bk>*KnWiQtS6=x9gqsXZ\X?v(gUtX{g^[k\Or~v$(*h(v{aSL+yyCjkCyi]97=0l^TAlA<p{co;BBA9-^df!1{p9K-e||HEW7F(@}&BWM]8)=+H
::*ME13{1/-2[52+IU^^F[/u%%C}xu,mb}#9{zTfE{jz&NFWu}%%xyeh/M\tHe;poP[9-oj]EtdDHjW.LT$(>PKXsKd=r\A_si3dz2dp`;&u6FL=F2[Bcyv$bIT(;*h`u$,{
::~gQ()r-4<uT5$!VGgV9yQY(C91kcS(OWbY#P.ZT,R[+698%[.B8qr9S#ZoZoU/7Ghu7Dk8v\=9C<*kNYknt7nKNUn~c-am)<9nI#qIq66H)jGf/=V8w?;yp@O^j&s%3J/R
::]#uFaEhjP\m4o5|U=+Q&#%MEER8Mf}2(})WkTUe?P0F|xXM=MWd`p}LC@Fwr9jQ2G4y)1ynXATZgPk[N//5fxvpBcv]<p\AwrX*(w_Jd+AgFTT!}(sR{u^C;1F;d-aw81T
::*Pj}oMESmJ(l@ZK[r,B?)c`)Fw1,gosL$_wv\@m,hb<|0ygbog\Sy(s0O((_6Eq&x~^-e?couJti[r3zm7MB6q.#8%tK.qr#Z-0)T\/Lbj_B[g^1|E[>i&g$^iNlG+bzBY
::3&bDZDv>S0>fnj[H,Jth4eV<2xfr,Yu6Of7aBtPZ&zCE6L4&8L~1{wKD8|#+c(V(0YOIrhE2c.JqN$46Z=a\b{E]-8+8g#jYh6]03zFIR5xqfV2~9accFjF?pvV/Hi!zRi
::4a|@8m3s8xHv8,{ZQz`7|c?r<!p($^V,ON!v(jrpGi@4SC~BR67GLr\|csd1LC4[.j(OWnHZQ@uD`!MTu~B|UaP(q?u3`)<Gyg;p}?*k_E@2GuYSuNNUy}2WRBVXJoA*IZ
::J35=cXZS+v\bS`Sao<#mNQ+zY^C8{wVOk\5i)M|vMgry2,R,B+\+%$JmihB%@_7<p;!z}A)xHX3{NvnB?=(Wuv^FY}E4NP5]]]%os-R;y.)+y^O[0HOMP63=Btr#EvhBCS
::E<+9vrrUj^e;ld#luqHqsMx1jx.`(cE&J+|gdFoE.t_uX7LM~O)*)dQ^ZuC}\.`|2szb1v0.u=_1^)-0wumMPr7h<E#=Y44UM=5&5wL^6aoH&w@A+!SF\@)R7AkMrJ}kL~
::=nUbNw+y.^{w0tyy\T]?_~!=,5p){o[FItz}+}n2,NVGg\p7?#nAh#XAogWr{fO,zgb$/--Up(+02g{Cdc{P?<8wD_XZ<X6Syb?Jv_}j\c&$SncfyQA%M3yi(et#~gxfmP
::].lR[xQ`X;1k8&fwryI,l0UxbK.L}a5uO^S~ND(dXYXyAaSRrW^_h1F6^t5[U1Z+G|WW#a`W>hl1s[y?dR}wI@/t<!mjao.Ws|;X}R+fOpw_IJ&}$pRhw?7m[~QYu;p*0A
::QTGcv5WXn45<D5k3jm>+\M>@}>1\7*JVrJI@v*;P[plPfZMZfQPx}sn.d-*zQh68|+p0n<u{O]lK3u#z?`QJS}5FqOMl@o6t!\SZS_EGJbHyh1(BfBrtH+tsq}+DT#@iD4
::r&@0UNKjp}=l5#XmKI^_F[LKIX{80ObcZ[3#q/o3T3tjS$*,TD3vfDE#/ke@F=;T1ZAFZR>2/F)}]53KOgE(7}>4>(mRVm&;01=Dyli@O6Tw)tz!mGP8H<+5oaTF{)P3H9
::mU0.9W7ZyR#pnq0#M$D!v*neb?I}0q8|Q#4tsa!aeKEdPErNwQMBf[]HU\X44@~Km6/?a,-E/Wg%q;MI&AMjO2E^I=|QS*])I]|6QAFb3<~`*RdO+JdbQBS?JAcw=GX9\I
::E?XYrK&D)[?uQP?qfPnh6v44>.|eEg@pkF0o`Mh{-gr%Jk9++w%U>b1mJacmJWk10jXz.jnD&+WRRh`{qg>W_fB%#h9om^%3yD;|}V([TN)8&%Th75YK&j#7<coX5hQ)2D
::w-v{E3^OJWWbP-dn&p]-&ve=A\@gD*&$=usDGp]hCb<oD<-!yoU35|J,3N2x-KT[m4`oyhQ^4Wgf&+n]W-$ikR$Rr,5ck?!59GCLzh*#]VP]+7G`kQR.`N-W{>.&tuzA<V
::D1XY@KsGo6yImh%Arm9o86anQ.t[K{lj9VW9<i%,-ts!Dp!OTX%_2I<_OA\PP+8m/6Vrx6.EA7OAL~xRROc<?;Ft{M/B<p3j>bNn?D3(SeEo.@NNj@D4wY<6}5;;f$L#k7
::BM%Jj&3Z*O_H#ijB!R<J0/!H/B$BkC3~ISwNeB?eVDlq~E@!P\;nv(0^j_sSW;nlxmIV>^gY>[Y6qoV9j{zC+0]({11NhdKFVmViJZN##r)wIS,nST?2D=D]ZTu|j((gj1
::KMiaX4Dc]s~6KY7??=VK[oWetCbKweKL2qkam)?nz%+s~B,p0dzl2pqO?v)f)1}(o+WSX/]7wX^/ST5i(pjgRj?;CAY~>,;~]n|0IH=]r<@]LOH!U-&lpPrl<dXWhQh6Om
::f)4pU^oDVn6v{li{%P>-^l\(UvbQda~Ovgx=CIuII[%$EGl5l9\NL&B%UEBw]W+bC{SXgw*<rY%R9^B}-]dlp6GZt67|C(]uAF.<;}Z`$,[JqJ;%!(OQ^<hz*_K2g\+AmK
::L-Qf646A<6f`fzcm0zAgNz&K5B>ir;^]/}biY~z2@8ZY?*\|)I{dIs{E8o}6vi_I4ru^f|U4i_FRj)vl;Kh,F}j[8pRw]_g\bvZKBE|^@{[_z?uGW&3c|~\YiHN9-!m4C_
::T@EPU8n0eVNP?7{nmR|`i,5D5(Z]>Q[+c\;9/]Qm*xZj0$S_hs!1B9dk0Wz?sry`PGK6O7mSN`2NS,Q=41F$(Y=bZYYUvbTdmnRmfgYL)oa+QG6LNgXdMeX;P]Mm9px3PE
::)xQhlbN=Im[mRFpqHd4o+IG]irJ3iua?`KUwrQ=O&S*wve>y!F*fiXjx]@)=b^T2UC_-(Xl/<n8]pJeb(;qDDUgs{3X%0OlVOl{y)Bn#F$=}$$n84`6eP<RdjI&5H0+mK~
::&I>(CpOBl-LiIN6ym=X(wQ/>zk7^H;%NP!4<f_$ec.^OZX!EU.&T3v.;[c0.}a5(Y<rAI%[tBE0),Q~E0dAUW%Q/+5aF<Fn2SgOgA^r)qNbhFJq,SDZS`^|-/PQ-^*&GbJ
::RwW&8k6Dojj{Yj(~a+$l;D[21i,>,)FF`n4pi@k!\Zu!l@OMrzb7v+t#kbok]VwG77L1q-8wHW.fCR8zNC`oPwI^tBU@x;<V>@qW\*eko][qAKdD|6PuCXI?U`|x<jUz9n
::>x[DffF]?iB$+@ZChda~$3XQ.8UC,uQq0~M;%^\Q,JgcC72)[7}gE$;5-J)aW2q4ef;*W2_E@0g}eJ--Q,/uS9sc|_Ms+X!u5B%s3r33%l_%K{,UW(s@io{&[,^_^0.=]L
::8%}o.psu7MSI1-=7]_mwv={lqtiI!p8~L..?N7o^_/Y3xL@JGboc?O[H8)SxK4\!DNe,P$g?%=*_Ihw-1-cH#@(*i[z?2Mfx(VfNF<c[0ikv\/EyN?=s]8jg!|QnUySM~A
::T1Sa-6uOv=!CT^Ud3r2V,-T]<aSWR^*IxSqi{hv~p&l19p<MVj&YYPR&#_yGks}FYABzrb`J!8DZoo0]#|Qvnm/.zha~N0-?Y2-FXthZwh.LXQGxuNJp&<hGYa-!3<kQb?
::.HI*~mPjw>ZVa\vPGX,URPeP}9GuD?k(^U(JD)18J3iE<qQxB7+/+0LqTIF\mNG=1lB|>s;?>~.EVn95xr*!mXb$#A]Ic!Vm>sRnP7(wrtD)y8p4)oG<ua&oV#EM;+~A+v
::#-EpGs#@fLp47p?E}^3sxG#[Y1S#]FvqCf@A<g&`0V}[68wp*/?oKqx2[^B>qRZ<X~9b[jaL}9rLF_YA<gYBHDJJ]@}}5Zs0~9JA!l)R\{X(!<u\FEQySg-}!h)&yKtiWc
::8obuYZWk>hyJ4p9y_SZA/(3?Z6Ui0AMOyG/anLQ8J^;Aa@eURYejLX`AGInFshY{@Jndc!N{Bq|w`m.\x3UcYr%3x`Eh4&xj0Ky7sr7qHQXE6{!>.~|!\5BpChX3``I[=o
::?G]F#}FW\/lf!mvh=SzI#OkrZx6Q0rA}PEmC$7dv|32M@*IU1pMF?9!PRNT/5U18p_}rW9HI%g4m;u?3dUW2d&x[[PL<&M0)D*mpMuOCDg$5`.r/NbZl=up*~>s;0sJ^+w
::hgCXs,mK_DDnu]X*RCL>a!e)?qp`ct3uyvqfmvMmz}XB+qYU8/sKH^UJkdhtlE^EX3i#Vn`;Qa3=4lL/oUk1xb,Z0Ijyc#/F(\3b1Uq$OgtFT#Y`&z\&Q(+7<HQ_k%&~wB
::*V`nvhV!,]\qqmtna[PV;u+|oxhsB/q(2*v4^._?7ospvICVGarP1|df$=DYFylaggx,S3(TGgImZYJq|A=mdY!PNWH-XhuFzgaq])tzTW\.u7|k0^Fx{wY].7!SBajU`n
::?-;XT|=BBN#C|WwJZ0XzPV=u?gca(PMhdkqF._^U3GM]+IdR.ynBTVsFmE_r^Wqs/r~&Zl&t@-*>w^5v8zZ+7@=@}!G0TCG};5Jh$dk~B`d?iK,1OeW63dxh|saHTeR2Ma
::K~l5Kr4WjHhu@BirO2lztL?uc5h>A,I;]F^y]X)cQcJ(?*tqoh\8fc&Lz7El2ggG1S[C0vi!?qZ7Ab_F9A1}4o^d_1=9F(=T]Vp9ZkD$|QH{DjW5gXE)khkLy*9Y]1}(&H
::CeBwg_RusB_]5ua+zTo]`.H^fny\2M}c1(&B;Qfr2or5Iw;fLRYN}XfTOahQ]aVjsU&#8{*|^G^n>&g]5=%8iqONt(i`Kg\)DDM_gc*DqTR~0w8,d<?n,%YhIYGLn}g_6L
::kwESXmw[a+/(kv=Z8Z]9`ge`J!/3&J+R5iy@=O4b$,^k;lB&t/|&@F</GPaYrZZkH}I]Kn?^fh*(RA|nm8EhVw*X$887{a<aQq%41eu&)zz{{G|BXPPF[ZG&}V=;\swV|M
::1;8?]zo[.n&<j7pLs[GKLC+}6x?jK;u*72m-NwoH|O_Qrn?vs+S?j}F,|02e&|V96FU~6[u(zF0}na~Y<-_~)d/6.>o%63E?)s6jNtNffeCA{x1{@{]sHlENTghR?P&-$4
::-pOq=KPvMVvo@(6%Iz%n>G3w?w[>Z&|@\9W9|0{dMNbq|&Z?#!b8_x1qa%ZPiX}r/VX,ma%-O,=2S$In?sGJ(q#qy]3WRIXYO,#h+Rfv&h@VOlYe<wV[CzQ]gfr^any;o;
::/Kmw_Kn]w8lPqD)sXxP}_aN?cCh6c$<m7F~KfCK8ma|b{AJGHN~+9X+OZ5cuo|K<]6D]R^ig#rd.8yCp%Tn2<RTn8K5o*0Ur{ibG7tDSUxseo=9orvYz{N33gvkRMqHmsr
::WXf&7GlzN[ry.A{tAYOU[R]cV1rY\,5\omUF$&;OMnW@MX-CT9r5_;IE6%RPy%q`edrwn91#*h(9vF?g|nx!V0Z,^PB@3)-$*{&DX~\GL7S<OERQC.^TF5qi8U}mE6EOe5
::L_bfVo6)Ep.A+Cu/0WTYl_AlH,x1aw>@&%$si!/L+;(hUZu;o1t{%%A/YF8`Ws$++0E1U>m0*fh{^*Gf%1eZD3\c5;zrGA]0hz0lh={@TIk<0F!xRJ$>.E+~?5]ydwfFa%
::8-/2i^55yJZ%bbS?ehPJ7hvVXXZE/7=Vzy|yUc/edA/1>/%#w@qNds_+;WJRITpGZ/wI>H}w)M;xhhPxU2!Fc^$<k{/dy\>9&i;i_ap,q-QazNRF(Jv[.$oeouidhMYg}l
::*E2}mi_K>3*|.}|i11\}|JDgN3h55`N,0hN;DE%=6;\99whMOX-qH,iP~sI}nl)rs$YL7wTE2KyUratZ=S0J>a_N$K4IGiT@yRJl5m/0w!S{HuM*jZ3KRUXnT0vV%U]X.B
::y.2kKJhLH]4|4*C{DXU}*~aKR<x0LwgR0?Mix|w-9}cvyEFu/Z/nrSS]z^}V_O8qnT##V!ypb$EM@`-9I]!V5uA0=]l_D*qG>#YdE/ciF&tElD~MYB{TNH@5c){`#!X{$h
::C05>o2~QrMqugo~b>$-<s,dfGB}n}3l_\3X0P[.V-2@5Rd25o$X?v!?#|EPx\Jw=vtzv!bu?D_e8YfP+#DRM12gyL=&3G{37+t,+@ItD%VK&j0?ATTtQrr0m3m4|L!<m}F
::2g.AD!eqk+qV~|XW_Nse1ISj~gk11q/X6-gu4_A\z,1qc9n\UM0SwDI5G;+^vY?+ptQ+Dd3K+hbq-Qst8GgDCnLj`*GI{[Dc=0PJ=[ha.[vc5*s*5dtgV)QFzszoe?N6&n
::Gh+3RLR-v7,Dw@/EGhj.5j3$zxH)#jr?R\k9S%6[_gtiK?&$xwUjRm<w%FyGO0/BQQJ75D$iMFQ;@wCo,t{Gb%TTw1hR=oNzCd/*#^3N@S~M7KIuR-;hF2n.Of^rnt=-^[
::|hCh<@,q1HBS9!P]$109/a5cl+G@fDPhlGl,x?L=WIEJK<<AA28SF(!PhZLg))No/N9~WQpG$DTVunR=;Uey\Uf.84I+<*M8m+dCdU}3lJ]<m~Bx9}p/xyo?*m*q/e,T|M
::_vfhak@{TZhT(kTKiPm@`|#|/evLX2N?K_BCw;<`[,*4gm0nTb,FA#G*2s([lDfeEo/}d-{Id#p<sM[|5<sn>&P.*Q>nF$uxcjtcZ%((fMm40aMD|!C)ljigro]f.YIY1E
::V6j}nB0e3i3~/a@&4m*GH;GJG0yRY4Q)exeatEC!LvVW*V7s_LffO3VA-A`BmZ1QlnOBDiT4Q{+,896w%rZe<Cj,&qV9kKFMgWbb]S1+CP}`tSfXaI3i%\nFuC$q.X&M$C
::H+,Wclf?,v,]f+0o;8#7TpGO=\b[vMF9|S.yi@z8Ynhm+l@S/X5pcIi1\~|l_PJf6_wfoE<LhOvk;yBU_?#3$Xj|T+CnzhCU2~g4Pge_wKML#-5*E]%5uT4jLz_Hq]9ZhP
::,_*wGY<P2\Y#9v]KY~H&/B4=AXJ*yfYgZgrEysDrjP;D.Lu0|fnX02DK@|]mH3W~~<,wKGdcj,v+J`5if~PACE\BnNr1))xUYH|%njHJ*%3m$n&zNev^S>$|dl-8-cgUbe
::3F|AD3v}4UI(+>?VbnpR5w@\AN<m;?2+)ei.?Sw_E^kDdfTH,<!uN8IM)@?]Y{%7S*.6V.9Q.O!E]X!UYtV![d@zS\d${0dE<BJhfM68Z.5MeGpc3&aXIoaV$0|E4dqLT5
::th8u5%Y3ko|1CU^0&sbQze|LB8PBc&vjC*Wv3C54jyUpYv]6dfQ2m0|->3746\-Z=eY/E54c7r7o)j~Z`Xz-X{-r7ZE^QVFlk]z1zvJVyrbKzB4k]z<&~na5M0{en})j>Q
::hFZN8pnEx+4,Y5#f^u(1.Bw6w\H\_z.s\{FDCy4YnHQi)j7rR=BBV59U/?#~?TL6->u-iylOUAw8_?G3(2c3+([s>=~+~+6+k(*wgW\d9&0mCl<~VAzA_g7fdK3j~sS/J1
::l2.3E?k5(,8hk#%boQgwEXCGPm`{@^%06fmvL}%gw2&dg?9Vtu4SbU0=%C)H1NZu;AfI{~%d5n^?%(bbzo40u*{laIk=53f}Z(aPtl^K#}T<g8*!cGL8BjA,%&q]=HdL>V
::VFE+WB2|a`/%T5],]{2&.ECxgzkJcxU^Uy4j%EhM`+FD3&l}.*Q!dTM{lZbs\(G/W,I8{5K8y|W3im16_46F[|LcVN2G>%!6PvxM=_Olz{I#WfxY?E9KV1BpY(RaHE~`nG
::dzlMP40gGBF$<e{d+o+Z<B6gRAAix\VIJ@N2>uew`2rWvQ^7INORc#n5\Rn;-PRDGh-(b*#$fNo2#vh%uM_p[x7poUb{Sg0Ch)\L=+~o+;323W%/-dpc[RX=Q2XgB3LJ4P
::SrTPga[xi$+n)AwHf.M?+AIf$4.{pdFl1^/GU40qd$oyWq,c==kfQjXP6jSomTgiNp}4bA<^omn.Y|;4?!lC-%~tLG0uOrGv^oEp<?50tw&er.0jc%rY+W6fXwDHR#{Ilk
::1IU^S.x#C7Ttavx3@8`g\[TA/Q_x1+QG?62;~\J?XtK*<wFJ@ydZ0}?143el68$Uj+]2Z7EV(6`i.KTx>Wo@njVH4IyusZoI2nHP)<]RRaOwGHlJ!mDYW(G0\zPxY_V*6w
::e$eu*<$}w+toE#y0_{`v4\&0aRzLg{bL~lO?NHoa>dR<?%}(#q!x#b<25otxWX/L~Ia$LSH)OJnZa0-9E3Z@tRel-z!xM\onghuX+^`GotaY{#Z97p%AA72}vo6E0^aEm{
::AfQ9gCi%?K);#p=G_8x`I+p|%qtc(y(n=rFgKtAM-*DRUZbua@87Fbh+_XQ|9<TauA9LxiFn_;j,@-0pijRT-j^#c=l\83^a@\O9D_Ju|,GidueHIW_F{_1UN5q4Z?|u`1
::=R-K~Nk#0Wb*w@[|li5J~2f_ff!&+D$}$s5-%TTS)Ho[l$0<D;e/16nrwp<)|,A;=s]16I|f2fY.p9;SEqtpfeubIBVom)2R0*$x4tDV7))L^YC+yz_={kw2[ps2mIQQ#]
::AyQ^[sO;lS/E&JRy_NrOS%71K*T/*LuV6KD\75@2K8,/|ecOVLtX}mUu+QrbMA0ZK{o{8PF!y^Al9g?FNHF|NP;2!39aU(V^F#!qN6{B-<XA!txLSrj/[5L6;9?~\1f|88
::/,4Ki=u.^P>,SO9vo1rzwMR=q=`oa\OAZac+4eEO/)&x!wj_qkZ$Z^d)M8k{QO+cs*VBub->A&HyOBp43;jPH9gK=k]W-c3LnY3QAF-ClR.\E,@Hw_]?6[+cC;uJ/j[!nY
::rj(1xPiM%gbd8hnD+y+Cg?(G]4hP}YPKz]CFm0;iHd6Rx&/iBkFI>iHg,\iMQbX8},YbQJz9q9qh|2]jS4k]*b!OLdv183%oyc?%/&xkWcJAiI/edODgDVVK#R(SXxjtat
::{`_-Fb^GQ<^;BCU#bTD[tlGEF-\V|pbL=AmzMB!niJD37X$pe>>RN4DCWbH,%;%H@!U(Le-B<<i1UEH@<j$lEX3;|UW+S=4@J%xX6NJ}lY9s}G<KzQD^E#B]@PJHMKMTc^
::~AGkkGl,RIXnh_sOoYdzn18(OO6(P/0/m-U3YmYzNmIz=*Bga=bW.i!kM0iz#{e!eKDz&{7@RKr<h&C#zL(E&nt\Y%#/L;Q[->}x{trV$M36qM1Z0U5Fa~9t)(o\3*K=X5
::d,>/i[-4\s~e{4H-ToO!%I7|#(i[$yo(`2M-,nItc]c46hyH^F!Q\DVOx|%neK=Ug8K[am(3QLtBa[!l(?hzUXh3F1<O`I\gR}4N&1L^|[xAm/eJb!bK~C,Wtd7o1<JV]E
::Gr)j@Dh2/@|^TXF2msz!`pdlBe0VY`6NyeP2zr/spboAAti]WJgp*kL0?p^z27OF,lgc;3)`T1&1B1;?xRn6m$)m?%mPWs`}M)?iL};}%;pz#~`*KNI3Q^ro2!$*+Ni[Z<
::Jm*~rl[^N|a#;g_|Lao?fgcoDVhqpAsKQkDSTl*)s$0^VTfFnTT|oN}`L`oB(IH6&7ko9!^S^+nDQa(ki0)Tumnut2V)q-Fb>}$kJzZjO9!][2Iy@I^WQ^yALQX*g^v>pc
::3M@ab$v($rdiqEgc;1i$$PUgzL35i8oKGC^jU1rXei(c~=YXl~[-jV,7h_fd5{Mtk,rSBW&/B<PX&#2,fZmT<wYm,e#R2vS^dAUCCl8ZBS\3)}5`WiZrb7(8A3I90/^x@~
::Ep;0|^@IJa?wtB*s%3Bi=!er.mm~O36#&5K;]JkMv^_{.<-[egIR.pDhy^tIdO()FUYeq9ny&lyr?^Cy}pSHzP-$,N>BTRLqc0!6_V3OuS{?=UHuw(}p>m&n(1WA&Lrpj7
::}0}6XgtRL~#uOxUX5][p-OSrnBWA#L&pDyYcdhi!MHPG]5]SBob5*E=EnXF&J{TZr`.s{/;H4<%hAX(ClEbo~T20q_en0kOQdJ!1<#G@DZ~@,%j|z2ZSg_QFiSS{1+cHO&
::.`T<j;U@CPJEz!a{Diu*PNmo=,nKL7}B/iN>sl_KmRnhU5>7*|0bY9oXu6QR9WN8\7IK2}`ko?,dw,i{mi=BH^GGiJD>.!07ei@(}PJ~SS.$=+RC`f[^l^5hY9M]rpXF`s
::6+jn{541l$O|}Nk*s{}5+g3fl#X8q._+pD*FNBYsQ,v,$2EA2EMnUjk;U,F1W[\/uUXkFO,8?]J9i}30p&TDkI;y4/U[$mip]`FO9tLU-HkNNgjwEhAsS;8(hD*7Rmi.2U
::(ihgf4gA\G6|_H%m[B3^5=BVuZDT!nf3Sp4=h20ILPN9`[M#zFF$Xd~V#*4;33g&K=Z2[QzQO%\UN#UH!KLmzALNU6`2t@yTZ25aaXasCi=!|k&]#^8q[4nk,<0;Jq@ap4
::j[`%{2gsSDM-zFMq5Y0@gq}wqHL`OcF$D1u6oI$cLgVq#*3-JLdws@7Y<f()`zjz~@~mmHE%>4CLudh4!w<b@O>VtGCDznXyoNkN{(US$[\M@Womg#S/<wN-H$gxQRn.qg
::I!6gOpuq_S{*Ak~&kYEq$}jP/0R/WJilw&9-nkKa&G>@b~k-k[3]D!]z>W]Mw*[,Q}Y(C!?D!eGrPzfi9KBAvJNMxP,k4^klf(@-m->OS-plCJ}HmpnV9-$1$C\ieIO}k=
::{0p@)Mesn-Uq1}Kkh3fk#xuPHnN5NtpBQRMefpuKmtvB(5p}|kuH}T.()bG*^Kgdv{.v|)}~w>??,4x44jm*HzCAud10[QK{,j\e.,C?_zN]#o##a&92R@.a02V)%)|N~j
::5u4q8`M<n_+MT!fV]$C2C,.u]HM_soz-1p(u7TwlHE>EE@g(WQ.j(91Ny4O;ZQxjUg5X35]p_Or*&vq{Sb-@f]64}$;Id!@4@>xaBiCN@j2vfU7o_;u/w6>SwiU_W|]/Aj
::~g>5Jpzs^PP9-}x?{=XY*?kUYn;ee%Nj6Mz_}CgQm4fxHWAo{{/t,Xzse]U1I9(r~N^z>>N1!1xmG/+4m[+z2/VA(Y5FeYvVRa%loIQ`Ly3ECA/=.p>L<$q$\c/X8ONM0k
::={Y2.uZU#EvcI$u{k6l]Y2l=f{./i7_B=],-A_*fM.cDmic-AZy\vTD>f+?U@qRc$(6+}@Gptv#WtEJ#KJYuF#;9Ms8Pa4hZ6GW/6di}>ff-YS{tCu#]huD8/p+zGj@B&%
::u&9&dkx=0_M{IqxE}?Ser5(Uy[Z(GX)6;]i]aghxu%NACsf,_M/|b7DegQAu]8K^vR)H;Vn%vg\uhF5|4EdHC5f\}t&q/5QL[YB@kUM8|vX25!$6_4##Zxc5O<zqUU7~#Z
::<f~P.E6V75@|js>{0WA0WicG3?6PuoVV(Xua6TdlQh!p>9Y~1eWm7nP(-_wA;If1=9Pl9Ru,sU~!uJrbpTW|O[h|MW=c\lygcS5NZVVw^a<iH/4PT*h^9sMCUUP0.4wKhB
::vl@?fyyW@AFtR\1,<dTX`0DI`05e;uquKYJ_Q#j8`k?,2mW!FUkZF5P0Fqe9G8r8>,Uu7PlGIzh*/=J^->B6oD+A*hcpi,]ggJjwOh~YiaZ)Hm9?eJWPo6#_Ay@;uV^]aa
::SPpJScB_#R?@t8GC_>\P(k)9PSpl+xu~EM8\t-A{*o}%+>G8,y.=mC,g].Gz,.ai4.<z;F369.Q,vLPp&t`rFl{!Zx;n<[m75^l8!sjZH,~(p1\Y_6}$5/t0]<>wjFB?cB
::NLc]].^]THW>?_Y(f1{Cz,T(\qUwQ)IK]VC|oTQ;;j+(gSDDV+v)5aY(\CDETD>zrDRC5M].sR73yT3yAfi1a`b_}bA6mB&CNfFA)/P7T~A69+ba/vff4{}MM77k[QRNv8
::;&Sqh(2Jr#?|bITkxv(1K7[T+5cXrPw_.z^4FwVdn3W%gM\)7T`s_.PuN@+.KN/TE^LWOi@tpsJ\Hw.AE(e?]._L6Bv40/I;H!Ut_vsaVy?d<KiA%SpD!h2XX&;$cKtc06
::zaNhYaqxz?cvrR0;s.cE)patjGH[n#98[wV9lpO-Z]l%SZ.Tc+r<Vm|Sss,;d]DH@`D*`Ml`SkTHdv}W?\|Co.op@V(!jKL~<,T_y\IXj]c0B/.DlKBu#(ktW%2G(eh<R?
::aYfICYpgcs&BrhW6]}0$w5-Ed?tyhvCj2}[T+\K6FpY@IZeE/`@98vA$Wwhi5N4!+Ee]ODv^bY3]&npfwhs;R0c!IG<xo0U[a5N0y/4\e,_%ENa{yui`J+Gk+$QGYfR*jV
::3&_REM!w5E]-W_D}H?vu@&<N/5p\=Z,DVfU-W0%$Qd%hX!25yN,Kd]o3$\Toovdq]jxC7`Zu}g}qgv-geed?V+mj(f,geR|NIhs$.=7D|qc#Mh@X/O/Dyg*B+G3AKp{JiU
::&ZF$l*=X`0KZ=!T/lZlm[Kg9p]7PPJwav`g4>@~7D9*R=FNi`PfD8Ldk3baW#gIcwUzmCjx^=gRMPa+\uxOj!P0VME0VfjaSgGLj|yhcLga3pnyDe}QPo+W+.8EK?AG=)k
::*_=%Hg^zJ#6CTB,DFhxaoSkHvbj=8tTN+8R1(g(nUDqcKM6H^*?sl-8=-avA>G9,[w]=30g>`MU#ed#$=zP1kzxS7J7dJ=(n}RY8VW;lwq/UtS(e3Rc{1D~demy7Mv2Os`
::.TO-KZ)f.>!|4DjW(@!~J]kMro8s1%rMdxwD)&2q4D)I5e7d<d3d)j00m6#lW<~NDNkKOyy9@fX\ls9ut%1hbKHvQ*Q=ktZfJ<1TtpZ}/a?Pe{F!)a4Ugn?\Rlj%2a7qK&
::ogQNIc-OS4tjS=euZv6jNF7_jZUp48hQk.H=YN\9_E>81ToV_0e9^M|k$Z}Qc%dK55.,PNeV+hZ]))KfkNG]!wuG1qu+2QX)L~eHqQhPqE3fo=/AGK!a|r9~2rUUouvN*\
::-fh*p|(;&dbY5sm6,E!C<r_AhlwyJLPIe6NHNw0<wIthNh>1J|{RZ*I(AXcIRM15-k5){1g%WF_PrL8@DE;l6LEqgqnJ9*9cjO!\7o*+u;#xIp]0vS{\;<r;4-MV[+EA~#
::I2~s$AhaU0JBN0GNk1`%;B><A&r7A5!FTtuc+&]*W<%mZ|1DkI=aJDR??EBL%NEi_nH,+MgE`_Me[`8ryBtVKh4gUC(}IX9?E~kIkJ0uGn{A?mG=|[s`1&p(p0jofao/~{
::/f%$Cw7joGEm.=/pTI>~K[i~^}IQNW*s%XS2RZ}Q)Ho|^Ez5J?!y;b0q8+SG[%(sCE?2Wf5Ld~K_HjV4hrQI*<HMGc7(*]~W.Q`d-)lT0E+tYk{G{Zd;B7Xd9StXr`=ll`
::uY*[#&qw=5$&ux5Pxk-yPIRd)(\@?j/hjDM!E\25j$q\Iq*%6Jul4EelW0Gli/\7nw+de%&`$$JIgA*fPIQDSN~7L@B?t69Kj]1Kl\|0;G$Jj,oni`A0bzuF7byES$~x1N
::=,pbWsW`P=20vC&0Dhro!`5|jt(=Kjc?!?FgK\|zDYM~U~XD@SbZ4%;*y4h<FZe.Mn)!Km\lT%?}B%klqVPD|xN?\%*3S`*6!sd$tB%OVd\&%x#pcxW2fst\C5mtgv?ob0
::sLH6e7?<7`mz\*B8]o{O>Z5Hu%YCA1/dwV_j_%n`.i@&e?saYM+#hw[ex~_1%Jl<Emvs]#l9$TWb8;0I\~pz0#;#0hc81`yZ_dCry_L5YG|)Cz+IiGNV-wLlc3S},W<jF%
::eDEju(CMZ>m<4w{]zD80|5aY>c98g!+-|yK/Y+/]OP)59AnDLt>Ag[<%!s\Jj!}d7\NpE`iwNr!MSN9EDJl~aL*i0(ICUOh,x,*@FX=?ym85`*KXoX,EzDk4R!N.b5<*6g
::Hs+[?$3t}7Xl/R{Fb@r90XXGMk9Y6O&I-5aMa2.Wpq?o9l16,BNVRIHZ@[Zf1F[C`gPhny-`&cM2g~r\E=zi?tkV&+/coFTm2w?5LR4%\WIeNlkM99=D`&uplu[0D;T&jV
::[gG1s4&Eut2NFdj{7a6sil$N.ghQaRHs3t9P5)i)#s)}|@}LfMZ50l@w,0i`2]~!n?vyYhKm*zxL]NaNnha\OnN/i\-zO#KE_\B<.=Pr\/SgwvRL$-IUh?Q!{wv#oEm[4c
::<%6Xo6@Bt6Nlg\!wvhJM*C)hel-N[z3Ckh<(vu,Uux{H$thV@;AaT^M9D1qI~xd%?do0`Nf(Xi[924^t6|Jo}n*X~JwwY;^QPs\E1!h(Og8EsISijJc{A]BJ]0kg,B]hPM
::Revgiu&^gAK@Rjjx4!M&|BIuZ/e~4\>9$53zTI8lcd-n42\%dZ%4;z%b.(Y\+iCAp*Fzg2rd50T->>E@9<BKs94tvI<&QY/Fn]r41X_4K;Um#`}s7M5^@q|jWMFA(o*c|2
::+IrAJ}\%R]&/;Mp<Y$MiiT/8Eb#NEOHIS<TeRFNfN3@qf0KM#&`193of\heSwihv%UDznJ=v[n<djFR{FzG%GN~s3\!hYeC]$0(H(f@,qRrVsWp|(g$`#4tqgML1H(3rOB
::5(snQ]Itr*d37a./yZoKC}|u|;p;bN},c}K,8-4-qPOSGP971c1P0_0EJ[eU!;4{_BK,k=0=zPvXGP|A,h3P$OIEU{QS;.&PCbH>`+;&Dq+A&b_+{VeMKpeC|KR,?9aD#.
::86R^K3tKVyxc>&Yr!CWZsrl^L56/a#Hcz}QW>aX6BLbCSS\y%fgBR1d+pbhRE.@^#8L6>C9SX=5s5CXI~XEfMA+v@^\9Z/c#vf~6Ur\CLfR^%eMu%9;]zxMe)?+jI~RqGk
::@Km=H9A{@H1|Qkw~yu[X.!$n[=sV`o8c@k#pf,1?JpsH%F\Rp}U9$K[O|Uq~.rJ<aF>YXH+T7LmC5]v~Xs;QbFkVTQ]TgLA?3TEMpRS>OXz$b)]=qF0FpX3(=B%O<H-JJc
::rqZ~G4*]}P\??yhu\T,tb]0/alzH+yaop7&sP}$%mX261Bk7or}}P-,U}_iBfOw7T@`ygry)~9yUmC.VjOS9Q]FQd0#rJ1EsqUm||&#X}^N]V}C]Tyyb6R|q;*PKw=M8!+
::3kS=,-GztQlm$?Z)XZ]OP=4hWX1]`wW{R%dK]R`NXp<i1>S.(O,OW]d)C)D-r+|;.Y(t(QDrs)ly]7^OuO;iE]7HC)Q-;2|;OsmzD@0I7.9(YS#;a-}9h1+d*4l-Egqgm(
::_D12*@wd{lX]T|kQjur[Sd~Mm$4AQhB@{V*1PmBv4JYI@>p-/il]pV&y*6wU[JMTRc8tQiI4U(`y{SL_1JoWrq~z$O}HWV.IU#[1AJXs%@`Jylf5AAyjwY-VO27hVt2ttf
::MS83,2MvQL?I3!?}v!&Ve2){6$,$4}}tvzRiG3F4eaAIR$N\UAaa(^s6!LTRa;#~;[y^4ZHb)L^1`LlY@|s$-_-A6/3c7l%3}M#X}8|&#3lEdZov#N0/`feBT_2M]c\RUt
::vwGQCNNd2W<tU~\k4aV~m20S1@/4.r)Vm4LlLCQN\M!~L}1E&<BUummnq;M`>;$v~/0@#8o5Nz`SnR0`))^{`Z8#DU/5*saC.fl`%?[An\[$cx<40#-\pL*NBa#|$\#LWT
::>/bwxq+_A1(_NVjnE5AAVKp|u@vke8!\hu}_lZaF<5jAEkW|d$7y.+y\3SR{CaT{|RAq87E6|_4b`nWB`KZKJ^;7|+h=Kcb{rWAq_An9=_cc`nIegLoFH+W5XS|b\)Hq,C
::fY7(vDMQ?Qnd.S=>&7TzAu2]K,q,3.hYwKpI?>BIo&tYD}v#%)?6;5z<|Qx;@5a)u)L3Y5.77Sd8]{c(.Uc)V_lP66~9EBhI8{g=Qud.j[Syh)!|U~oQ5RwA$<RQsfy6!Y
::2+DW46,65G)[/?$fy[Q74k7#[SDk`!5^xQl}_+x$^]r$QB]=~zolX7Ym>v+SJ]~>=[,Ov]zff7%p_WPThXE+=[SOU4;_k7Yrt_QT}Ur$iB&O_H{b.I_tKjQTfsN&!$)(j5
::RB;18f2(w7l\hTPD,*tUGdrI(_8tjj<_/Z1rc,D8K^g-NcLS73)7*U`MJ-.CxA.&rb*aH55+^^k{-U87&aC6[9,7_s;&F^{/&uECOycS/9-9jD8SY^H?U[6C\y*B?9iAQl
::u8@C,a8{v^%63{)cTfe@!xrVV.22agc(Y!3Vw-JKe_F/kYOmLF0O<J?kG^P2&!v(T%/WETIP`-iQMQ>qqp5,g@iiHH~K#I.3v5./{/n_(Y|WMQ{rWs5,]$]kyHaL~$^/F4
::E(/YfaVR9vua8,bwVrd1<6u_J(ApwTroRB%7U@yPQ5/^Cy)/76,Y{nrK|8F#P_`\5VeU!GH[|RCq?{<6!_|_dpii2UsKl857M)!_o|K[!WCq3{p9!_W|vqji~UYF&_x5gZ
::Q[,bvr8CnPub$\lQpV#J6WevYJ+lRcV~pkgS4Hp9VpAVFAolcC}V\M&~x[OKa*niJAnnL{932>5s@UpK)|R|p~Pq4q*V3YK-yC|Ln8#c\#WSzC/ZXX\^|1TLdJs|6<S0Ul
::VA2u_+]VMlw7~[&d7*-ct7[v_WRTjlfHnBW2@,~B}-#.~5If!(Bfh1YbXMQ&[7uta#d^3)p{jjCb{{mC.Uu)Zl#BB7qj}b]SG(4WHU68^_<B&897rb~Xj=qvpU*I\fN[0A
::%v<B\9g/I&-9(7.w$XL^x?JhwX0/m$`%cuzq.hV$<iBjNHRPtG}-8Ph,}8irKQX%gM@2GoE%-Lc<}uK*sk>tX!m5A~S$FpRv?w7,nb$\Jt9s]T<ir9g?,26IX*8gCwC,s^
::JHUW>G.L&2?F1}n%P8inRRh#BBE{*iGI8YqjRVz+!j~i5qEPzqXF23vlP0T3p-|W;8MY$\cijI+Tvk&&r,m_m6442PA;^vvWZyxK9+O|EEq8VwA`k5,euwLuu=rcN,N_4z
::{S+*aI*f$[_5CET]|*>cenRMgP/5-~;d]$sC`7`tzDOIQF#wO]!8|JR.-+b}T^{30_|mtdq9BQc?eNT^zSzDEF?Nt8?k@&j7j3KPr)(NMTB$zNVs8~dexX.OMhh%WVo5pe
::sy2y4?r*e8fE=-7A5!Z$EQq2;rAd4|v?BnFx`BNUyNu)(\]nAAN!\~k)[DL5Zs(\Y`YrBM@hhoEh}wd<RP=-_nw~&Mg,c+X<))ZttLDaAmX0k?8o0DYT8g_w@~[J;!pRE@
::%tU,jL{4Zz7~xJm~cD]/Cwj<ybcFm&%L0,z)q(b09LVUDJwsJSEZ0Ba(zwYWp\!U&(^&(hrx=n*Ps^4NeYBfmse]MtwelT15vj\D\&byjp&0#Z4Gf1fuX6r3Tj&A|+HAMb
::HN9BQcFA@xeA;^g^+aww{najCi#hAGK3g||e<SWw>[cZ$<)cLd3j^qp,3&{X;WEiLJ->YO6n&GtcuD+2jXb[<4w%E04u!Y2p7EpKR_t?pII0iOYVg%^&EtOxC+9n=N{FMm
::6USo=Z~kCvT?VE$W&rj_(r3=`Pt%|C-Brgt0EH6w9_*Xu0~so<X;yNz$rTn%IDD-5KZzvU7.Zw8#j</]Sg|}8gz\{O}[%>sJbt=z[\Cuv,/V-VrWl)S_j4f&pYDYAn/ccH
::%$8td!/+0U-m}jpsC7uw|EfHWs4Z<MZ(&\[\Qu~)g?m=t92Izl!UWA*29]z]zT}019K5BtUjvy//v;K3(%fIXi2[W(Qb6Z2n,}PaJMwMpP=882{v$]oM}#9,8oG%<b6;6@
::s|dnTp3Y$8W92DakQV.A;46@h{4@W]lk9O*dGtBNR|q^7a(E{(2w(|G(Cy5n4n3Z{CHHv^.Ue5G/RMIo8r0Lm;o+Ont4OM]0Y*}=f>~C<M/q7cP\<pG6]A8VpjA*k?woi!
::.3o^RG~IBj(1ge}Vm~]pLQ0rKG@H`+\3.Q-NUVV&/1tm[$Y3ra28GFi4!*e%)#f5u0^\]G#T)[)AP6b\6C8G69vG[;Mynn(&\R8,C4Szrf~9UOopo;|t3>T3`&%~/scU04
::Skg%MW-K{x}BRR6!!kQRH]/\3+,LmS7pdYG?I@?3;RPrQPL]Vfe|IomL3iwJ?r777;u3Q0ps!xnLH$pdHd6mA^gPIM&*zi@#J9e,0ylZ}h+](<+n?ltBT!BLv_D=q?~zli
::V_EM.)pG})S8FCIw[3C=$si|(E{)B4Avi3XM@><}SOaQg8h?iwnj@%\Q^T_oJ_#Rb/(~!3qy&>@0hwq%sW]zk>o@*}tWNs-z4%M`{QNcJ3}Qi(+z4k(vlOs7s\tliBS3g%
::HznI};2?aNgdz8dJS*spce3Z23n7LvD~Z9.jhCfCkAoO}4Fn=T|7^FcoT,!U?)s/3z/1EJ+o!0j{^qH]XONK5UiA-F`fo.!`S0$-4tnnL6XYy=Xv57zUkl$tbM)1OKdO&8
::#(,rJ31i2Gi\d)O;TLfi}6-G&[3E`VFpbgbxD=jmq<pKO,5M\y9Se\h9Rj>VbI%N[s=vuYbdY?(B~M]g?V%fhmWiu5?M|J\dr@`-3]y*\6kZ9NvPw`biuS[eahli%!HO%{
::xNq%/TyDOXI^C(*Evg(0#)EEU2E%22qb$pT3lh~gQ^/0wzov_gxRk,^KaE6I9f`TOM+*bo*292%-pkB)7;I2}<KpsCoS={{VIdF%+4D!B^LOU@;ziL]a#o<L$7YGOn9%mN
::s5en~=|;O/*rQezr.nA,K3-bXVrj;D~@}S&$IX%iWkSu7G_e`b@3$s6+N7\tj`AnvqlzyG[)hj*u@q2$$j~YDG\yVJBt/lD|6n(,KyQXS}e[BdBS#MzH<j@XFgF{3~9VZJ
::fz{&\_qA)`&r9Z,szHCZrM1QhW!vUq7S;Eh<[]!WiU`M2Jq-_FfI},C,/4uPlDhPJ}<MGHet(!(<GjvfuBCr\Gv{i4$jWs;3EZ}/oSHZBx(kD#=U[kl<Iii{2J>!DWqq!D
::zWDTlt.`k|+s^-_|-Gi@*RGLb))aR53t;O$-/P?pj(W3iC-2Jdf?}gb-]r)VexB%Vl&stRN5}\)wl&VX)5@~YntBr<0SX%GhHBVvVSci1eO;R_i4ndxecU}]{iTye-4E.a
::O;4LLq?9XQE\@1wis(ByQ5JaY;^IhM&xxm<ivRAmKX52n~cHE(U_0/`~A48o@?^&c3sg2@Vz)&N1D#Le6ASYl;,?Uz{dhyihZ^Wrs8W9jm)A;ZaR^`I-YEF/~*O3sg;hr}
::h|lRk=1wSTh,qec@4jYVy}<h@wk&FRcn@-Zz)@K6T!hx$sUu@oT$=<0LJmCu\D<aPr4yhD[I6g.KTK!=\OXgM#72MY46cEtVF!N~F&%rY&7[O1!ihqG6^JUih_9Up4t&l-
::TmBk4r={x9~@BSG\(MM1d7Ah@{oamzt&KPPpO|OlZ|>~MI%iyuyJSqAlT#`;!6{}*Gm)/}y*N!7zj-TwAp\j-nM+K4^%od+q<g^bWLj1ApobnDh=#K-H[|k&WsK[n&[vji
::(8_I#~d;b2$PaXJww<vwr`pgW,lR/I!uzws8V;mNyk@KPeLqRNnOZirm76VH?dfmW*>K%S6@(NBxJ~p^8elTC?P#y6m9Dq\li0=;nV3qBDq~Qf/ef\ug6I&(#.VRbZS&|u
::gUCtE_jgGswP(c3m*m)L=X6=V9ZW1}Bz5(P&8;l_V+%]isSZ(ortz0wBwXxqhPVYr\G<-O[=D`|wqfI{0R?_!F3E>TyO2])KOksff?sc;\)5I`,0a4g2BIk-)l^(/w8Jd&
::srqHpk\>Q9VDJoF~_lA_%U{nD*VyN_kXZQ)/Ge9tAZ_2e{%~j(t0T9zq8FeI;h{B)8#30)aTqwKs)2hTK008X0(0awCPW_GQVM<8iXc*\*L7TlIkc+dNNLMC44xlpg?[3!
::WeM7fG@f6M#c$I.@yy`Q=[#F3`[0pj|kL|Vg31rtCXo[?$oF7lCwa5#9Y?z-o29\{kXMHv*O}9`DFdwB4YO{wTvf>M%8?Qo[;h6enz}FqrSn{TCE.U8[otW*d}i8|Z3AY3
::W=%8zAu(#G_/f*-ki)Q9%M(Jsk;gK/O$pcroHuSf!WRG;uwFX7pd)?(^V.d/qu#yl&1kZr=c9=KFx@-H=}/gr?eItmU\p7{N,$bNcIA>rjsM*JH5XTA^2F+Lpt@}4,IT6!
::3Mdt}K|la~a8kcUxl?R<oy{Ul[wZC0Rq[<i0OK*}LM3mNPz6~%HYhic[-W?[Z5h|=3)!7{eD`tslgm;pOyo/UIR>C~;zvbEa;KVmA%3xek-3xtVT9BAQWdJu[;R!2(o_f2
::A40Y/^Ed}<VYznPUw#$+41Oy_+kMAcf=i84XAl)w+nL!dzm]3=Rd4Yg~[O_0W,cR/_8iJ2?o\.3h=@oA9[~4z$Fb2wp$${SxEiuxBioz>6Zl+s]M&O2{Ei$\SFt!henO?y
::K^QsaiPXd[=Im,{RsYP^\jWsXoMS(bo#R^xW=NtXx\5alu8Gd&8c)NdjPW&fGr6+N9`m~~,kVR}_Zj7yb(rc93KveiOsJCBZ8~1Jx,mfpA=oPV(;0\dMDpnb$pEr47*SGZ
::1?u@*hM;-He2Ia,{h~Z;MZ\-$A8M&o0,CCuw?r2JKqICee(W$i1fwmv@GwcwjW0HzdRD(?Zi5;u#u4S(vp,(]/&3P)p@5~7n`l\j_@;?BVI7BPwg2iqLXz+qSbzM!kBq_{
::QM4U^2iMSX;<]5f~Sb70fwPm~p5)F\#EJUfxSg]k0q~A%g1m0A5*@}P{A@gvVhdX@#[5R=Z7<{_/6bahMB\\!gWpK`rCD0HLJA6aWO\YdATJ_gyA{5|scAOi;4oM^7k\]4
::#U}<C.2,
:batfile:>

::
:HWID_KMS38_Files: