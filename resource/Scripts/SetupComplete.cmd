@echo off
set SCRIPTDIR=%~dp0
powershell.exe -ExecutionPolicy Unrestricted -NonInteractive -NoProfile -NoLogo -Command "& { . %SCRIPTDIR%\SetupComplete.ps1 }"
