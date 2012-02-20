@echo off

:: Windows 2000/XP/2003 Auditing and Forensics script v 1.1
::
:: This "simple" script will generate an audit report of the Microsoft
:: Windows system it is run in. All the audit files will be deposited in
:: either %TEMP%\Audit-rep or in a subdirectory 'Audit-rep' in which
:: the script is run.
::
:: Please notice that this script is enhanced if you download some binary
:: tools that provide additional information that cannot be retrieved
:: with Microsoft's tools. The appropriate tools are listed in each
:: place together with their download location.
:: 
:: IF you receive this script together with the above mentioned tools
:: be careful and verify that the tools come from their proper location.	
:: 
:: Microsoft, MS, Windows, Windows 95, Windows 98, Windows Millennium, 
:: Windows 2000, and Win32 are registered trademarks and Visual C++ and 
:: Windows NT are trademarks of the Microsoft Corporation.
:: 
:: IMPORTANT NOTES:
:: It is noteworthy to mention that if you want to run this script in a 
:: Windows 2003 Server, you must configure FPort tool to run in Windows XP 
:: compatibility mode for the utility to successfully run. This is achieved
:: by right clicking over FPort, selecting the Compatibility tab, and 
:: selecting Run this program in compatibility mode for Windows XP.
::
:: ------------------------------------------------------------------------------
::
:: This script is (c) 2005 Javier Fernandez-Sanguino
:: 
::    This program is free software; you can redistribute it and/or modify
::    it under the terms of the GNU General Public License as published by
::    the Free Software Foundation; either version 2 of the License, or
::    (at your option) any later version.
::
::    This program is distributed in the hope that it will be useful,
::    but WITHOUT ANY WARRANTY; without even the implied warranty of
::    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
::    GNU General Public License for more details.
::
::    You should have received a copy of the GNU General Public License
::    along with this program; if not, write to the Free Software
::    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
::   
:: You can also find a copy of the GNU General Public License at
:: http://www.gnu.org/licenses/licenses.html#TOCLGPL

:: ------------------------------------------------------------------------------
:: Changelog:
::
:: 07/2011:
:: Updated several links pointing to third party tools
:: Fixed fport command line and added information for running in Windows Server 2003
:: Collect event log - 2 days
:: More  process/sockets information
:: Added Service configuration info
:: Collect more info with DumpSec
:: More Hotfixes info in XP/2003/7 - wmic qfe list (discarded)
::
:: 13/09/2011
:: Collect policy information with  "secedit".
:: Win XP does not work [http://support.microsoft.com/kb/889532]
::
:: ------------------------------------------------------------------------------

:: TODO: cd to %TEMP% before proceeding? 
:: TODO: Filesystem checks could also check cacls
:: TODO: Additional tools like
:: -- ASSOC? (msinfo32 includes it?)
:: -- GPRESULT : Group Policy
:: -- IPSEC \\name SHOW
:: -- Windows 2003 has additional clis that could be of use:
:: See, for example Nltest: www.microsoft.com/Resources/Documentation/ windowsserv/2003/all/techref/en-us/nltest.asp

:: Command references:
:: Windows 2000: Start -> Help -> Index -> Command reference
:: Windows XP:
:: http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/ntcmds.mspx
:: Windows 2003:
:: http://www.microsoft.com/resources/documentation/WindowsServ/2003/standard/
:: proddocs/en-us/Default.asp?url=/resources/documentation/WindowsServ/2003/
:: standard/proddocs/en-us/ntcmds.asp

:: ------------ BEGIN Configuration variables (customise per system) ------------ 

:: Directory used for reports and for temporary files
:: TODO, could use a directory at %USERPROFILE%/Desktop (or Escritorio in Spanish locale)
:: TODO Or %APPDATA%
IF EXIST %TEMP% (set REPDIR=%TEMP%\Audit-rep) ELSE set REPDIR=Audit-rep
:: Location of report files
set REPORT=%REPDIR%.\report.txt
:: Additional path for binaries
ADDPATH=
IF EXIST c (set ADDPATH=c:\forensics\)

IF EXIST "%windir%" GOTO :Endwindir
       SET windir="c:\Windows"
       ECHO WARN: windir variable does not exist. Configured to "c:\windows"
:Endwindir


:: Additional tools can be downloaded from:
:: Microsoft
:: MS Windows NT 4.0 Resource Kit Support Tools
:: http://www.microsoft.com/technet/archive/winntas/downloads/nt4sp4rk.mspx
:: MS Windows 2000 Support Tools
:: http://www.microsoft.com/windows2000/techinfo/reskit/default.asp
:: MS Windows 2003 Support Tools
:: http://www.microsoft.com/windowsserver2003/techinfo/reskit/tools/default.mspx

:: Export full registry?
SET EXPORTREG=yes

:: Review users through the registry
SET USERREG=no

:: ------------ END Configuration variables (customise per system) ------------ 

:: Check if we have an additional location for binaries
IF NOT EXIST "%ADDPATH%" GOTO :Noaddpath
SET PATH=%PATH%;%ADDPATH%
ECHO Adding %ADDPATH% to PATH to use available forensic binaries
GOTO:Endaddpath
:Noaddpath
ECHO.
ECHO WARN: %ADDPATH% does not exist. 
ECHO WARN: Create it and place there additional forensic binaries (psinfo, fport..)
ECHO WARN: You might want to also install the Windows Resource Kit Support Tools
ECHO.
:Endaddpath


:: TODO, should check that %TEMP% exists...
IF EXIST "%REPDIR%" GOTO :Endcreate
mkdir "%REPDIR%"
if ERRORLEVEL == 0 GOTO:EndCreate
ECHO ERR: Cannot create temporary directory! Aborting!
GOTO:EOF
:Endcreate

:: Check if there is a previous report there
IF EXIST "%REPORT%" ECHO WARN: Overwriting old report...

:: BEGIN AUDIT
TITLE Auditing system

@echo Determine where are we running first
hostname  >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO ERR: 'Hostname' is not available in this system  >>%REPORT%
@echo -------------------------------------------
@echo Extract information from the system 
systeminfo >>%REPDIR%.\systeminfo.txt 2>nul
if ERRORLEVEL == 9009 ECHO ERR: 'Systeminfo' is not available in this system  >>%REPORT%
@echo -------------------------------------------
@echo Find date and time
ECHO System date and time: >>%REPORT%
ECHO. >>%REPORT%
date /t >>%REPORT%
time /t >>%REPORT%
@echo -------------------------------------------
@echo Extract IP address
ECHO IP Addresses: >>%REPORT%
ECHO. >>%REPORT%
ipconfig /all >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO ERR: 'Ipconfig' is not available in this system  >>%REPORT%
@echo -------------------------------------------
@echo Extract MAC table
ECHO MAC address table: >>%REPORT%
ECHO. >>%REPORT%
arp -a >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO ERR: 'Arp' is not available in this system  >>%REPORT%
@echo -------------------------------------------

@echo System environment
ECHO Current variables: >>%REPORT%
ECHO. >>%REPORT%
set >>%REPORT% 
if ERRORLEVEL == 9009 ECHO ERR: 'Set' is not available in this system  >>%REPORT%
ECHO. >>%REPORT%
ECHO Current environment: >>%REPORT%
ECHO. >>%REPORT%
env >>%REPORT% 
if ERRORLEVEL == 9009 ECHO ERR: 'Env' is not available in this system  >>%REPORT%
ECHO. >>%REPORT%
@echo -------------------------------------------

@echo Extract additional system information
:: Record the system information, including the hotfixes applied.
:: Download from: http://www.sysinternals.com/ntw2k/freeware/psinfo.shtml
ECHO Process information: >>%REPORT%
ECHO. >>%REPORT%
psinfo >>%REPORT%  2>nul
if ERRORLEVEL == 9009 ECHO WARN: 'Psinfo' is not available in this system, download from http://www.sysinternals.com/ntw2k/freeware/psinfo.shtml  >>%REPORT%

:: TODO check if it exists
:: IF NOT EXIST %PROGRAMFILES%\Microsoft Shared\MSInfo\MSInfo32.exe ....
@echo Generating msinfo (this might take a while)...
ECHO Generating Msinfo report .... >>%REPORT%
ECHO. >>%REPORT%
:: start /wait msinfo32.exe /report %REPDIR%.\report-msinfo.wri /categories +SystemSummary+Resources+Components+
start /wait msinfo32.exe /report %REPDIR%.\report-msinfo.wri /categories +all 
if ERRORLEVEL == 9009 ECHO ERROR: 'Start' is not available in this system  >>%REPORT%
ECHO .... done >>%REPORT%
@echo -------------------------------------------

@echo System uptime
:: Record the uptime of the system.
:: Download from: http://www.sysinternals.com/ntw2k/freeware/psuptime.shtml
ECHO System uptime: .... >>%REPORT%
ECHO. >>%REPORT%
psuptime >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO WARN: 'Psuptime' is not available in this system, download from http://www.sysinternals.com/ntw2k/freeware/psuptime.shtml  >>%REPORT%

:Localusers
@echo -------------------------------------------
@echo Local users (this might take a while)...

:: TODO: Consider using sid2user from http://www.chem.msu.su/~rudnyi/NT/sid.zip

if NOT %USERREG%==yes GOTO:EndRegUser

:: Record users in the system through the registry
:: TODO: This is quite cumbersome, there should be an easier way...
REGEDIT /E "%REPDIR%.\Users.dat" "HKEY_USERS"
:: Display header
ECHO Configured users in this system: >>%REPORT%
ECHO. >>%REPORT%

:: Summarize all users gathered from registry
FOR /F "tokens=2 delims=\" %%a IN ('TYPE "%REPDIR%.\Users.dat" ^| FIND "[HKEY_USERS" ^| FIND /V "_Classes"') DO FOR /F "tokens=1 delims=]" %%A IN ('ECHO.%%a ^| FIND "]"') DO CALL ECHO %%A >>%REPORT%

:EndRegUser
:: Remove temporary file
IF EXIST "%REPDIR%.\Users.dat" DEL "%REPDIR%.\Users.dat"

:: TODO: This could be done, but that information is already available in the tree output of the disks
:: ECHO Users with a profile in this system: >>%REPORT%
:: ECHO. >>%REPORT%

@echo done
@echo -------------------------------------------
@echo Local connected users
:: Record users connected locally and remotely.
:: Download from: http://www.sysinternals.com/ntw2k/freeware/psloggedon.shtml
:: Logged on users
ECHO. >>%REPORT%
ECHO Users connected to this system: (psloggedon) >>%REPORT%
ECHO. >>%REPORT%
psloggedon >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO WARN: 'Psloggedon' is not available in this system, download from http://www.sysinternals.com/ntw2k/freeware/psloggedon.shtml  >>%REPORT%
@echo -------------------------------------------

:: Event log - last two days
@echo Events of last two days
ECHO Extract events of last two days (psloglist) >>%REPORT%
ECHO.  >>%REPORT%
psloglist -d 2  >> %REPDIR%.\psloglist-two-days.out-eventlog.txt
if ERRORLEVEL == 9009 ECHO WARN: 'Psloglist' is not available in this system >>%REPORT%
@echo -------------------------------------------

@echo Succesful/failed logins
:: To record the successful and failed logins to the system.
:: Download from: http://www.foundstone.com/resources/proddesc/ntlast.htm
ECHO Successful failed logins: (ntlast) >>%REPORT%
ECHO. >>%REPORT%
ntlast /r >>%REPORT% 2>nul
if ERRORLEVEL == 9009 GOTO:Nontlast
ntlast /f >>%REPORT%
ntlast /r /f >>%REPORT%
GOTO:Endlogins
:Nontlast
ECHO ERROR: Auditing is off or 'Ntlast' is not available in this system, download from  http://www.foundstone.com/resources/proddesc/ntlast.htm  >>%REPORT%
:Endlogins
@echo -------------------------------------------

@echo System information (Netbios)
ECHO System netbios information: >>%REPORT%
ECHO. >>%REPORT%
ECHO Shared drives >>%REPORT%
net use >>%REPORT% 2>nul
if ERRORLEVEL == 9009 GOTO:Nonetuse
net file >>%REPORT%
net share >>%REPORT%

ECHO Net view >>%REPORT%
ECHO. >>%REPORT%
net view >>%REPORT%
ECHO. >>%REPORT%

ECHO Net user >>%REPORT%
net user >>%REPORT%
ECHO. >>%REPORT%

ECHO Net accounts >>%REPORT%
net accounts >>%REPORT%
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO Groups (net localgroup) >>%REPORT%
net localgroup >>%REPORT%
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO Started services (net start) >>%REPORT%
net start >>%REPORT%
ECHO. >>%REPORT%

GOTO:Dumpsec

:Nonetuse
ECHO ERROR: 'Net' is not available in this system  >>%REPORT%
ECHO. >>%REPORT%

:Dumpsec

@echo System information (using Dumpsec)
ECHO. >>%REPORT%
ECHO Dumpsec (shares) >>%REPORT%
DumpSec.exe /computer= /rpt=shares /saveas=fixed /outfile=%REPDIR%.\shares.txt
if ERRORLEVEL == 9009 GOTO:Nodumpsec
type %REPDIR%.\shares.txt >>%REPORT%
del %REPDIR%.\shares.txt
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO Dumpsec (users) >>%REPORT%
DumpSec.exe /computer= /rpt=userscol /saveas=fixed /outfile=%REPDIR%.\users-dumpsec.txt /showosid
type %REPDIR%.\users-dumpsec.txt >>%REPORT%
del %REPDIR%.\users-dumpsec.txt
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO Dumpsec (policy) >>%REPORT%
DumpSec.exe /computer= /rpt=policy /saveas=fixed /outfile=%REPDIR%.\policy.txt /showaudit
type %REPDIR%.\policy.txt >>%REPORT%
del %REPDIR%.\policy.txt
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO Dumpsec (groups) >>%REPORT%
DumpSec.exe /computer= /rpt=Groupscol /saveas=fixed /outfile=%REPDIR%.\groups-dumpsec.txt
type %REPDIR%.\groups-dumpsec.txt >>%REPORT%
del %REPDIR%.\groups-dumpsec.txt
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO Dumpsec (rights) >>%REPORT%
DumpSec.exe /computer= /rpt=rights /saveas=fixed /outfile=%REPDIR%.\rights.txt
type %REPDIR%.\rights.txt >>%REPORT%
del %REPDIR%.\rights.txt
ECHO. >>%REPORT%

GOTO:Endnetbios

:Nodumpsec
ECHO ERROR: 'Dumpsec' is not available in this system  >>%REPORT%

:Endnetbios
@echo -------------------------------------------
@echo Remote Netbios name cache
ECHO System netbios name cache: >>%REPORT%
ECHO. >>%REPORT%
nbtstat -n >>%REPORT%  2>nul
if ERRORLEVEL == 9009 GOTO:Nonbtstat
nbtstat -c >>%REPORT%
nbtstat -s >>%REPORT%
GOTO:Endnbtstat
:Nonbtstat
ECHO ERROR: Nbtstat is not available in this system  >>%REPORT%
:Endnbtstat
@echo -------------------------------------------

@echo Processes
ECHO Process listing: (tasklist) >>%REPORT%
ECHO. >>%REPORT%
tasklist >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO WARN: Tasklist is not available in this system  >>%REPORT%
:: Download from http://www.sysinternals.com/ntw2k/freeware/pslist.shtml
pslist >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO WARN: Pslist is not available in this system, download from http://www.sysinternals.com/ntw2k/freeware/pslist.shtml >>%REPORT%
@echo Active processes
:: Display active processes
:: Download from: http://www.microsoft.com/windows2000/techinfo/reskit/tools/existing/pulist-o.asp
pulist >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO WARN: Pulist is not available in this system, download from http://www.microsoft.com/windows2000/techinfo/reskit/tools/existing/pulist-o.asp  >>%REPORT%
:: Download from http://www.sysinternals.com/ntw2k/freeware/psservice.shtml

ECHO Services - Status: (psservice) >>%REPORT%
ECHO. >>%REPORT%
psservice >>%REPORT% 2>nul
ECHO. >>%REPORT%
ECHO Services - Configuration: (psservice) >>%REPORT%
ECHO. >>%REPORT%
psservice config >>%REPORT% 2>nul
ECHO. >>%REPORT%

if ERRORLEVEL == 9009 ECHO WARN: Pssservice is not available in this system, download from http://www.sysinternals.com/ntw2k/freeware/psservice.shtml  >>%REPORT%
@echo -------------------------------------------

@echo Loaded DLLs
:: Record all the DLLs that are currently loaded, including
:: where they are loaded and their version numbers.
:: To identify unusual DLLs, open files and Trojans.
:: Download from: http://www.sysinternals.com/ntw2k/freeware/listdlls.shtml
ECHO Loaded dlls: (listdlls) >>%REPORT%
ECHO. >>%REPORT%
listdlls >>%REPORT%  2>nul
if ERRORLEVEL == 9009 ECHO WARN: 'Listdlls' is not available in this system, download from http://www.sysinternals.com/ntw2k/freeware/listdlls.shtml  >>%REPORT%
@echo -------------------------------------------


@echo Listening services
ECHO. >>%REPORT%
ECHO Listening services and connections: (netstat -ano) >>%REPORT%
netstat -ano >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO WARN: 'Netstat' is not available in this system  >>%REPORT%
ECHO. >>%REPORT%

:OpenPorts
@echo Open ports
:: Record opening ports.
:: To identify opening ports and their applications.
:: Note: When running on a Windows 2003 Server you must configure FPort to
:: run in Windows XP compatibility mode for the utility to successfully
:: run. This is achieved by Right Clicking over FPort, selecting the
:: Compatibility tab, and Selecting Run this program in compatibility mode
:: for: Windows XP.
::
:: Download from: http://www.mcafee.com/us/downloads/free-tools/fport.aspx
:: It may need administrative rights. ie: runas /user:Administrador fport
::
:: Another alternatives are:
:: netstat -aon - show all, show pid, and show ip/port number.

ECHO. >>%REPORT%
ECHO List of open ports (fport): >>%REPORT%
fport >>%REPORT% 2>nul
if ERRORLEVEL == 9009 GOTO:Nofport
ECHO. >>%REPORT%
GOTO:Endport
:: Alternative:
::runas /user:Administrador fport >>%REPORT% 2>nul

:Nofport
ECHO WARN: 'Fport' is not available in this system, download from http://www.foundstone.com/resources/intrusion_detection.htm >>%REPORT%
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO List of all ports/process mapping (cports): >>%REPORT%
ECHO. >>%REPORT%
ECHO Process Name      Process ID      Protocol        Local Port      Local Port Name Local Address   Remote Port     Remote Port Name        Remote Address  Remote Host Name        State   Process Path    Product Name    File Description        File Version    Company Process Created On      User Name       Process Services        Process Attributes      Added On        Module Filename Remote IP Country       Window Title >> %REPORT%        
cports.exe /stab "" /DisplayUdpPorts 1 /DisplayUdpPorts 1 /DisplayClosedPorts 1 /DisplayListening 1 /DisplayEstablished 1 /DisplayNoState 1 /DisplayNoRemoteIP 1 /ResolveAddresses 0 /sort 1  >> %REPORT%
if ERRORLEVEL == 9009 GOTO:Nocport
ECHO. >>%REPORT%
GOTO:Endport

:Nocport
ECHO WARN: 'cport' is not available in this system >>%REPORT%
ECHO. >>%REPORT%

:: Last option - Try with a custom script
:: This is based on the script available at http://www.multingles.net/docs/escucha.htm

@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

if exist %REPDIR%.\ports.tmp del %REPDIR%.\ports.tmp >nul
tasklist > %REPDIR%.\tasks.tmp 2>nul
if ERRORLEVEL == 9009 GOTO:Notasklist
:: TODO could use pslist if available (Tasklist is not available in XP home edition)

:: TCP ports
echo Reviewing TCP ports
for /F "usebackq tokens=2,3,4,5,6,7 delims=: " %%g in (`netstat -nao^|find "LISTENING"`) do (
set sz1=%%h: 0
for /f "tokens=1,2 delims=:" %%s in ("!sz1:~,6!") do set sz1=%%t%%s
for /F "usebackq skip=4 tokens=1,2" %%m in (%REPDIR%.\tasks.tmp) do if %%l == %%n (
set sz3=%%n: 0
for /f "tokens=1,2 delims=:" %%s in ("!sz3:~,6!") do set sz3=%%t%%s
set sz2=%%m: =
for /f "tokens=1,2 delims=:" %%s in ("!sz2:~,16!") do set sz2=%%s%%t
set sz4=%%g: 0
for /f "tokens=1,2 delims=:" %%s in ("!sz4!") do set sz4=%%s
if !sz4! == 0.0.0.0 set sz4=any
if !sz4! == 127.0.0.1 set sz4=loop
echo !sz1! TCP !sz2!!sz3!   [ !sz4! ] >>%REPDIR%\ports.tmp
)
)

:: UDP ports
echo Reviewing UDP ports
for /F "usebackq tokens=2,3,4,5,6 delims=: " %%g in (`netstat -nao^|find "*:*"`) do (
set sz1=%%h: 0
for /f "tokens=1,2 delims=:" %%s in ("!sz1:~,6!") do set sz1=%%t%%s
for /F "usebackq skip=4 tokens=1,2" %%m in (%REPDIR%.\tasks.tmp) do if %%k == %%n (
set sz3=%%n: 0
for /f "tokens=1,2 delims=:" %%s in ("!sz3:~,6!") do set sz3=%%t%%s
set sz2=%%m: =
for /f "tokens=1,2 delims=:" %%s in ("!sz2:~,16!") do set sz2=%%s%%t
set sz4=%%g: 0
for /f "tokens=1,2 delims=:" %%s in ("!sz4!") do set sz4=%%s
if !sz4! == 0.0.0.0 set sz4=any
if !sz4! == 127.0.0.1 set sz4=loop
echo !sz1! UDP !sz2!!sz3!   [ !sz4! ] >>%REPDIR%.\ports.tmp
)
)

echo. >>%REPORT%
echo Listening ports in the system >>%REPORT%
echo. >>%REPORT%
echo Port Program PID Address IP >>%REPORT%
echo ------ ------------ ------------ >>%REPORT%
set iant=
for /F "tokens=1* delims=" %%i in ('SORT %REPDIR%.\ports.tmp') do if %%i NEQ !iant! (echo %%i >>%REPORT%) & set iant=%%i
echo.>>%REPORT%

IF EXIST %REPDIR%.\ports.tmp del %REPDIR%.\ports.tmp >nul
IF EXIST %REPDIR%.\tasks.tmp del %REPDIR%.\tasks.tmp >nul
GOTO:Endport

:Notasklist
ECHO ERR: Cannot generate listing of sockets per process as 'Tasklist' is not available >>%REPORT%

ENDLOCAL
:Endport
@echo -------------------------------------------

::  more info about process/sockets
ECHO. >>%REPORT% 
ECHO Obtain information of sockets and processes
ECHO --------------------------------------------
ECHO. >>%REPORT%
ECHO Information of sockets and processes: >>%REPORT%
ECHO. >>%REPORT% 
tcpvcon -a -n >>%REPORT%
ECHO. >>%REPORT%
ECHO --------------------------------------------


@echo -------------------------------------------
ECHO. >>%REPORT% 
ECHO Listening RPC services: (rpcinfo) >>%REPORT%
ECHO. >>%REPORT%
:: Rpcinfo is provided both by Windows Services for Unix and by third-party vendors
:: See http://support.microsoft.com/?id=313621
rpcinfo -p >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO WARN: 'Rpcinfo' is not available in this system  >>%REPORT%
@echo -------------------------------------------


@echo Extracting routing table
ECHO Routing table: (netstat)>>%REPORT%
ECHO. >>%REPORT%
netstat -nr >>%REPORT%
@echo -------------------------------------------

:: TODO: more information could probably be gathered with the 'show'
:: commands of netsh (at least in WinXP)

:: See http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/netsh.mspx
:: and http://www.microsoft.com/technet/prodtechnol/windowsserver2003/library/ServerHelp/28e2f559-bfa6-4f3a-857c-ffd045f8de79.mspx
@echo Extracting firewall configuration
ECHO. >>%REPORT%
ECHO Extracting firewall configuration: (netsh) >>%REPORT%
ECHO. >>%REPORT%
netsh firewall show config >>%REPORT% 2>nul
if ERRORLEVEL == 9009 GOTO:Nonetsh
GOTO:Endnetsh

:: Could be further divided as:

:: Current profile
::ECHO Firewall current profile: >>%REPORT%
::netsh firewall show currentprofile >>%REPORT% 2>nul
::ECHO Firewall  icmpsettings: >>%REPORT%
::netsh firewall show  icmpsetting >>%REPORT% 2>nul
::ECHO Firewall  logging: >>%REPORT%
::netsh firewall show  logging >>%REPORT% 2>nul
::....

:Nonetsh
ECHO WARN: 'Net sh' is not available in this system  >>%REPORT%
:Endnetsh
@echo -------------------------------------------


:FileInfo
@echo Retrieving file information (this might take a while)
:: TODO: Could also check cacls
SET DISKS=
FOR /D %%H IN (C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO CALL :Checkdisk "%%H"
GOTO:Endtree

:Checkdisk
:: TODO: Consider using /f (huge files as a result, however)
dir "%~1:\" >nul 2>nul
IF %ERRORLEVEL% GTR 0 GOTO:Nocheckdisk
echo Extracting info from %~1:\
tree "%~1:\" /a  >"%REPDIR%.\tree-%~1.txt" 2>nul
:Nocheckdisk
GOTO:EOF
:Endtree

@echo -------------------------------------------
@echo Current policies
ECHO. >>%REPORT%
ECHO Current security policies: (auditpol) >>%REPORT%
ECHO. >>%REPORT%
auditpol >>%REPORT% 2>nul
if ERRORLEVEL == 9009 ECHO WARN: 'Auditpol' is not available in this system  >>%REPORT%
@echo -------------------------------------------

@echo -------------------------------------------
@echo Group policies - computer
ECHO. >>%REPORT%
ECHO Group policies - computer: (gpresult) >>%REPORT%
ECHO. >>%REPORT%
gpresult /scope computer /z >>%REPORT% 2>nul
if ERRORLEVEL == 9009 GOTO:Nogpresult
@echo -------------------------------------------

@echo -------------------------------------------
@echo Group policies - user
ECHO. >>%REPORT%
ECHO Group policies - user: (gpresult) >>%REPORT%
ECHO. >>%REPORT%
gpresult /scope user /z >>%REPORT% 2>nul
if ERRORLEVEL == 9009 GOTO:Nogpresult

GOTO Endgpresult
:Nogpresult
ECHO WARN: 'Gpresult' is not available in this system, download from http://www.microsoft.com/windows2000/techinfo/reskit/tools/existing/gpresult-o.asp  >>%REPORT%
:Endgpresult
@echo -------------------------------------------

@echo -------------------------------------------
@echo Lsa control set
ECHO. >>%REPORT%
ECHO Extracting lsa control set: (reg query) >>%REPORT%
ECHO. >>%REPORT%
reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa  /s >>%REPORT%
@echo -------------------------------------------

@echo -------------------------------------------
@echo File associations
ECHO. >>%REPORT%
ECHO Extracting file associations: >>%REPORT%
ECHO. >>%REPORT%
ftype >>%REPORT% 2>nul
if ERRORLEVEL == 9009 GOTO :Noftype
ECHO WARN: 'Ftype' is not available in this system, ussing assoc >>%REPORT%
assoc >>%REPORT% 2>nul
if ERRORLEVEL == 9009 GOTO ECHO WARN: 'Assoc' is not available in this system >>%REPORT%
:Noftype
@echo -------------------------------------------



@echo -------------------------------------------
@echo Startup services
ECHO. >>%REPORT%
ECHO Extracting services started at startup >>%REPORT%
ECHO. >>%REPORT%
ECHO "Run:" >>%REPORT%
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run /s >>%REPORT% 2>nul
ECHO. >>%REPORT%
ECHO "RunOnce:" >>%REPORT%
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce /s >>%REPORT% 2>nul
ECHO. >>%REPORT%
ECHO "RunServices:" >>%REPORT%
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunServices /s >>%REPORT% 2>nul
ECHO. >>%REPORT%
ECHO "RunServicesOnce:" >>%REPORT%
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce /s >>%REPORT% 2>nul
ECHO. >>%REPORT%
@echo -------------------------------------------

:: @echo MRU files
:: reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ >>%REPORT%
:: @echo -------------------------------------------

:: TODO Hfixes are described also on uninstalled software
:: @echo Uninstalled
:: reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall >>%REPORT%
:: @echo -------------------------------------------

:: Check existing security policy with the one provided in the archive (secpolicy.inf)
IF NOT EXIST secpolicy.inf GOTO :Nopolicy
ECHO Checking security policy ....
ECHO Checking security policy: >>%REPORT%
ECHO. >>%REPORT%
secedit /analyze /cfg secpolicy.inf /db %REPDIR%\secpolcheck.sdb /log %REPDIR%\secpolcheck.log
if ERRORLEVEL == 9009 GOTO:Nopolicy


ECHO. >>%REPORT%
ECHO --- Policy info: secedit --- >>%REPORT%
::copy %windir%\security\Database\secedit.sdb %REPDIR%\secedit.sdb
secedit /export  /cfg %REPDIR%\cfg-secedit.txt /log %REPDIR%\log-export-secedit.txt
secedit /export  /mergedpolicy /cfg %REPDIR%\cfg-merged-secedit.txt /log %REPDIR%\log-export-merged-secedit.txt
secedit /analyze /db %REPDIR%\new-secedit.sdb /cfg %REPDIR%\cfg-secedit.txt /log %REPDIR%\log-analyze-secedit.txt^M
secedit /analyze /db %REPDIR%\new-secedit-merged.sdb /cfg %REPDIR%\cfg-merged-secedit.txt /log %REPDIR%\log-analyze-merged-secedit.txt
secedit /analyze /db %REPDIR%\new-secedit-hisec.sdb /cfg %windir%\security\templates\hisecws.inf /log %REPDIR%\log-analyze-hisec.txt
ECHO. >>%REPORT%

GOTO:Endpolicy

:Nopolicy
ECHO WARN: 'Secpolicy' is not available in this system >>%REPORT%

:Endpolicy

:: Check hotfixes

SETLOCAL
:: Gather info from the registry
REGEDIT /E "%REPDIR%.\Hotfixes.dat" "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Hotfix"
:: TODO: Check ERRORLEVEL


:: Display header of hotfixes
ECHO Gathering Hotfixes installed on this PC ....
ECHO. >>%REPORT%
ECHO Hotfixes installed on this PC: >>%REPORT%
ECHO. >>%REPORT%

:: Summarize all hotfixes gathered from registry
FOR /F "tokens=7 delims=\" %%a IN ('TYPE "%REPDIR%.\Hotfixes.dat" ^| FIND "[HKEY_"') DO FOR /F "tokens=1 delims=]" %%A IN ('ECHO.%%a ^| FIND "]"') DO CALL :Summarize "%%A"

:: Remove temporary file
IF EXIST "%REPDIR%.\Hotfixes.dat" DEL "%REPDIR%.\Hotfixes.dat"

:: Done
ENDLOCAL
GOTO:Endhf

:Summarize
SETLOCAL

:: Gather more details from the registry
:: TODO: Does not work in Windows 2003 (Registry location changed?)
REGEDIT /E "%REPDIR%.\Hotfixes.dat" "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Hotfix\%~1"
:: Retrieve the hotfix description from the temporary file we just created
FOR /F "tokens=1* delims==" %%a IN ('TYPE "%REPDIR%.\Hotfixes.dat" ^| FIND /I "Fix Description"') DO SET Description=%%~b
:: Escape brackets in the description, otherwise the ECHO command will fail
IF DEFINED Description SET Description=%Description:(=^^^(%
IF DEFINED Description SET Description=%Description:)=^^^)%
:: The whitespace in the following line is a tab
ECHO.%Hotfix%	%Description%  >>%REPORT%
ENDLOCAL
GOTO:EOF

:Endhf

@echo -------------------------------------------
:: Extract information using wmic
:: TODO: Information could be extracted to an external file 
@echo Extracting information using wmic
ECHO. >>%REPORT%
@echo Extracting Hotfixes with: wmic qfe lsit
ECHO. >>%REPORT%
wmic qfe list >> %REPORT%
if ERRORLEVEL == 9009 GOTO:Nowmic

ECHO. >>%REPORT%
ECHO Users (wmic useraccount) >>%REPORT%
wmic useraccount >>%REPORT%
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO Shares (wmic share) >>%REPORT%
wmic share get caption,name,path
ECHO. >>%REPORT%

ECHO. >>%REPORT%
ECHO Installed software (wmic product) >>%REPORT%
wmic product get name,version
ECHO. >>%REPORT%

GOTO:Endwmic

:Nowmic
ECHO ERROR: 'Net' is not available in this system  >>%REPORT%

:Endwmic
ECHO. >>%REPORT%


@echo -------------------------------------------
:: Export Registry
:: TODO: Consider outputing only a fraction of it
if NOT %EXPORTREG%==yes GOTO:EndExport
@echo Exporting Full Registry (reg export)
ECHO. >>%REPORT%
ECHO Exporting registry: (reg export) >>%REPORT%
reg export HKLM %REPDIR%.\registry-hlkm.reg

:: If you only want to export information of installed software
:: reg export HKLM\SOFTWARE\ %REPDIR%.\registry-sw.reg
:: If you want t export user information
:: reg export HKU %REPDIR%.\registry-users.reg
ECHO "Registry exported to %REPDIR%.\registry-hlkm.reg" >>%REPORT%
ECHO. >>%REPORT%
::EndExport

:: Check archive signatures
:: TODO: test for windows, can the registry file be changed?
:: TODO: Removed for the moment since it is not a CLI program
:: IF EXIST %SYSTEMROOT%\system32\sigverif.exe sigverif /defscan
:: TODO

@echo -------------------------------------------
echo.
echo "Finished audit please review %REPDIR%"
echo.
@echo -------------------------------------------
pause


:: Restore the title 
IF DEFINED %CMDCMDLINE% (TITLE %CMDCMDLINE%) ELSE TITLE cmd.exe
