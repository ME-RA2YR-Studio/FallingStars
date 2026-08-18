@echo off
setlocal enabledelayedexpansion

set "CONFIG=%~1"
if "%CONFIG%"=="" set "CONFIG=Debug"

set "SLN=%~dp0..\FallingStars.sln"

rem Prefer the bundled vswhere.exe next to this script (Phobos-style), then
rem fall back to the copies shipped inside Visual Studio Installer.
set "VSWHERE=%~dp0vswhere.exe"
if not exist "%VSWHERE%" set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
	echo [FallingStars] vswhere.exe not found. Install VS 2022 or place vswhere.exe in scripts\.
	exit /b 1
)

rem Locate the latest Visual Studio 2022 installation root.
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSROOT=%%i"

if not defined VSROOT (
	echo [FallingStars] Visual Studio 2022 not found.
	echo [FallingStars] Install VS 2022 with the "Desktop development with C++" workload
	echo [FallingStars]   MSVC v143 build tools + Windows 10/11 SDK.
	exit /b 1
)

rem Initialize the VC build environment for an x86 (Win32) target.
rem Idempotent: safe to call even inside an existing Developer Command Prompt.
if exist "%VSROOT%\Common7\Tools\VsDevCmd.bat" (
	call "%VSROOT%\Common7\Tools\VsDevCmd.bat" -arch=x86 -no_logo >nul 2>&1
)

rem Resolve MSBuild: prefer the one just placed on PATH by VsDevCmd,
rem otherwise fall back to an explicit vswhere lookup.
where msbuild >nul 2>&1
if !ERRORLEVEL!==0 (
	set "MSBUILD=msbuild"
) else (
	for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -find MSBuild\Current\Bin\MSBuild.exe`) do set "MSBUILD=%%i"
)

if not defined MSBUILD (
	echo [FallingStars] MSBuild not found. Repair the Visual Studio installation.
	exit /b 1
)

shift
"%MSBUILD%" "%SLN%" /m /p:Configuration=%CONFIG% /p:Platform=Win32 %*
if errorlevel 1 exit /b %errorlevel%

echo [FallingStars] Build succeeded: %~dp0..\%CONFIG%\FallingStars.dll
exit /b 0
