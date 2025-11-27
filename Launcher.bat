@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

:: Read configuration from config.ini
set "autoinject=false"
set "multi-instance=false"
set "vanilla=false"
set "priority=normal"

for /f "tokens=1,2 delims== " %%A in ('findstr /i "autoinject-after-update=" "config.ini"') do (
    if /i "%%A"=="autoinject-after-update" set "autoinject=%%B"
)
for /f "tokens=1,2 delims== " %%A in ('findstr /i "multiple-instances=" "config.ini"') do (
    if /i "%%A"=="multiple-instances" set "multi-instance=%%B"
)
for /f "tokens=1,2 delims== " %%A in ('findstr /i "vanilla=" "config.ini"') do (
    if /i "%%A"=="vanilla" set "vanilla=%%B"
)
for /f "tokens=1,2 delims== " %%A in ('findstr /i "priority=" "config.ini"') do (
    if /i "%%A"=="priority" set "priority=%%B"
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
    set "CORE_FILE=%APP_DIR%\modules\discord_desktop_core-1\discord_desktop_core\index.js"
    set "PATCHED_CORE_FILE=%cd%\injection.txt"
    
    if exist "!CORE_FILE!" (
        set "line_count=0"
        for /f "delims=" %%a in ('type "!CORE_FILE!" ^| findstr /r /v "^$"') do set /a "line_count+=1"
        
        :: Restore patched core file from backup if it only contanins one line (indicating a failed injection)
        if !line_count! LEQ 1 (
            if exist "!PATCHED_CORE_FILE!" (
                copy /y "!PATCHED_CORE_FILE!" "!CORE_FILE!" >nul
            ) 
        )
    ) else (
        echo This seems to be your first launch. Restart Discord after it updates to complete BetterDiscord injection.
        pause
    )
)

:: Manage multi-instancing if enabled
if /i "%multi-instance%"=="true" (
    set "instance_count=0"

    :: Workaround to count running discord instances by substracting processes search results
    for /f %%a in ('wmic process where name^="discord.exe" ^| find "dis" /c') do set "dis_count=%%a"
    for /f %%b in ('wmic process where name^="discord.exe" ^| find "discord" /c') do set "discord_count=%%b"
    set /a "instance_count=!dis_count! - !discord_count!"
    
    set /a "next_instance=!instance_count! + 1"
    set "DISCORD_USER_DATA_DIR=%cd%\data\profile-!next_instance!"
) else (
    set "DISCORD_USER_DATA_DIR=%cd%\data\profile-1"
)

:: Build optional arguments and launch Discord
set "ARGS="
if /i "%vanilla%"=="true" set "ARGS=--vanilla"
if /i "%multi-instance%"=="true" set "ARGS=%ARGS% --multi-instance"
start "" /B /%PRIORITY% "%DISCORD_EXE%" %ARGS%
