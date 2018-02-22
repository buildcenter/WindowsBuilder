@echo off
rem Starts the build process from console.
rem Run from cmd.exe:
rem     build /?

rem no need to use forward slashes because we're in windows!

rem shifting will modify the batch file dir variable, so we need to assign first.
set SCRIPTDIR=%~dp0

rem help
rem build /?|/help|-h|--help [help_topic]
if '%1'=='/?' goto cmd_help
if '%1'=='/help' goto cmd_help
if '%1'=='-h' goto cmd_help
if '%1'=='--help' goto cmd_help

rem configure
rem build configure
if '%1'=='configure' goto cmd_configure

rem mount
rem build mount
rem build mount [configuration] [?|<number>]
if '%1'=='mount' goto cmd_mount

rem dismount
rem build dismount [undo]
if '%1'=='dismount' goto cmd_dismount

rem driver
rem build driver dump
if '%1'=='driver' goto cmd_driver

rem defaults to build [configuration-name]
goto cmd_build


:cmd_configure
rem build configure
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Configure' }; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%


:cmd_mount
rem build mount
rem build mount <path> [?|<number>]
set SUBCOMMAND=%1
shift
set REF_IMG_PATH=%1
if '%REF_IMG_PATH%'=='' goto mount_interactive
shift
set IMGINDEX=%1
if '%IMGINDEX%'=='?' goto mount_list_available
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Mount'; ReferenceImagePath = '%REF_IMG_PATH%'; ImageIndex = '%IMGINDEX%' }; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%

:mount_list_available
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Mount'; ReferenceImagePath = '%REF_IMG_PATH%'; ListAvailable = $true }; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%

:mount_interactive
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Mount' }; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%


:cmd_dismount
rem build dismount [undo]
set SUBCOMMAND=%1
shift
if '%1'=='undo' goto dismount_undo
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Dismount'; }; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%

:dismount_undo
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Dismount'; Undo = $true }; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%


:cmd_driver
rem build driver dump
set SUBCOMMAND=%1
shift
if '%1'=='dump' goto driver_dump
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Driver'; }; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%

:driver_dump
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Driver'; DumpDriver = $true }; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%


:cmd_build
rem build [configuration-name]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Build'; Configuration = '%1' }"
exit /B %errorlevel%


:cmd_help
rem build /?|/help|-h|--help [help_topic]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPTDIR%\tools\Builder\Builder.ps1' '%SCRIPTDIR%\tools\WindowsBuilder\WindowsBuilder.ps1' -properties @{ Subcommand = 'Help'; HelpTopic = '%2' }"
exit /B %errorlevel%
