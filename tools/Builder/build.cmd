@echo off
rem Helper script for those who want to run Builder from cmd.exe
rem Example run from cmd.exe:
rem build "default.ps1" "BuildHelloWord" "4.0" 

if '%1'=='/?' goto help
if '%1'=='-help' goto help
if '%1'=='-h' goto help

powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0\Builder.ps1' %*; if ($BuildEnv.BuildSuccess -eq $false) { exit 1 } else { exit 0 }"
exit /B %errorlevel%

:help
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0\Builder.ps1' -Help"
