@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

:: Search app\app-* folder
set "APP_DIR="
for /f "delims=" %%I in ('dir "app\app-*" /b /ad /o:-d 2^>nul') do (
    set "APP_DIR=app\%%I"
    goto :found_app
)

echo Discord version not found in app\ folder
pause
exit /b 1

:found_app
set "DISCORD_EXE=%APP_DIR%\Discord.exe"

if not exist "%DISCORD_EXE%" (
    echo Could not find "%DISCORD_EXE%"
    pause
    exit /b 1
)

:: Force electron data path to root\data
set "DISCORD_USER_DATA_DIR=%cd%\data"

start "" "%DISCORD_EXE%" --vanilla