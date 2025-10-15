@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

:: Read configuration from config.ini
set "vanilla=false"
set "autoinject=false"
for /f "tokens=1,2 delims== " %%A in ('findstr /i "vanilla=" "config.ini"') do (
    if /i "%%A"=="vanilla" set "vanilla=%%B"
)
for /f "tokens=1,2 delims== " %%A in ('findstr /i "autoinject-after-update=" "config.ini"') do (
    if /i "%%A"=="autoinject-after-update" set "autoinject=%%B"
)

:: Search for app\app-* folder
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

:: Auto-inject BetterDiscord if enabled
if /i "%autoinject%"=="true" (
    echo Checking BetterDiscord injection...

    set "CORE_FILE=%APP_DIR%\modules\discord_desktop_core-1\discord_desktop_core\index.js"
    set "INJECT_LINE=require(\"..\\..\\..\\..\\..\\betterdiscord.asar\");"

    if exist "%CORE_FILE%" (
        for /f "usebackq delims=" %%L in ("%CORE_FILE%") do (
            set "firstline=%%L"
            goto :check_first
        )
        :check_first
        if not defined firstline (
            echo index.js is empty. Injecting line.
            (echo %INJECT_LINE%) > "%CORE_FILE%"
        ) else (
            echo First line: !firstline!
            echo Checking if injection is already present...
            echo !firstline! | find /i "%INJECT_LINE%" >nul
            if errorlevel 1 (
                echo Injecting BetterDiscord line at the top...
                set "TMP_FILE=%TEMP%\index_tmp_%RANDOM%.js"
                (
                    echo %INJECT_LINE%
                    type "%CORE_FILE%"
                ) > "%TMP_FILE%"
                move /y "%TMP_FILE%" "%CORE_FILE%" >nul
                echo Injection completed.
            ) else (
                echo Injection already present. Skipping.
            )
        )
    ) else (
        echo Could not find "%CORE_FILE%"
    )
)

:: Force Electron data path to root\data
set "DISCORD_USER_DATA_DIR=%cd%\data"

:: Build optional arguments
set "ARGS="
if /i "%vanilla%"=="true" set "ARGS=--vanilla"

:: Launch Discord
echo Starting: "%DISCORD_EXE%" %ARGS%
start "" "%DISCORD_EXE%" %ARGS%
