@echo off
set "CONFIG=%~1"
if "%CONFIG%"=="" set "CONFIG=Debug"
call "%~dp0run_msbuild.bat" %CONFIG% /t:Clean %*
