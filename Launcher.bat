@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

:: Read configuration from config.ini
set "auto-restart=false"
set "multi-instance=false"
set "vanilla=false"
set "priority=normal"

for /f "tokens=1,2 delims== " %%A in ('findstr /i "restart-after-update=" "config.ini"') do (
    if /i "%%A"=="restart-after-update" set "auto-restart=%%B"
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

:: Auto-inject BetterDiscord if needed
set "CORE_FILE=%APP_DIR%\modules\discord_desktop_core-1\discord_desktop_core\index.js"
set "PATCHED_CORE_FILE=%cd%\injection.txt"
set "MUST_RESTART=false"

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
    if /i "%auto-restart%"=="true" (
        set "MUST_RESTART=true"
        echo This seems to be your first launch after a new update. Discord will update and then restart automatically to complete BetterDiscord injection. Do not reopen Discord manually during this process.
    ) else (
        echo This seems to be your first launch after a new update. Restard Discord manually after updating to complete BetterDiscord injection.
    )
    pause
)


:: Manage multi-instancing if enabled
if /i "%multi-instance%"=="true" (
    set "instance_count=0"

    :: Workaround to count running discord instances by substracting processes search results
    for /f %%a in ('wmic process where name^="discord.exe" 2^>nul ^| find "dis" /c') do set "dis_count=%%a"
    for /f %%b in ('wmic process where name^="discord.exe" 2^>nul ^| find "discord" /c') do set "discord_count=%%b"
    set /a "instance_count=!dis_count! - !discord_count!"
    
    set /a "next_instance=!instance_count! + 1"
    set "DISCORD_USER_DATA_DIR=%cd%\data\profile-!next_instance!"
) else (
    set "DISCORD_USER_DATA_DIR=%cd%\data\profile-1"
)

:: Make all profiles share the same BetterDiscord installation via symlink
set "LINK=%DISCORD_USER_DATA_DIR%\BetterDiscord\data\betterdiscord.asar"
set "TARGET=..\..\..\..\betterdiscord.asar"

dir "%LINK%" 2>nul | find "<SYMLINK>" >nul
if %errorlevel%==0 goto :launch_app

if exist "%LINK%" del "%LINK%"
mklink "%LINK%" "%TARGET%"

:: Creating symlink will fail without administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c mklink \"%LINK%\" \"%TARGET%\"' -Verb RunAs"
)

:launch_app
:: Build optional arguments and launch Discord
set "ARGS="
if /i "%vanilla%"=="true" set "ARGS=%ARGS% --vanilla"
if /i "%multi-instance%"=="true" set "ARGS=%ARGS% --multi-instance"
start "" /B /%priority% "%DISCORD_EXE%" %ARGS% >nul 2>&1

:: Restart Discord if needed for injection
if /i "!MUST_RESTART!"=="true" (
    :check_instances
        for /f %%a in ('wmic process where name^="discord.exe" ^| find "dis" /c') do (
            set "process_count=%%a"
        )

        if !process_count! GEQ 6 goto :restart_script

        timeout /t 1 /nobreak >nul
        goto :check_instances

    :restart_script
        timeout /t 2 /nobreak >nul
        taskkill /IM "Discord.exe" /F >nul 2>&1
        timeout /t 1 /nobreak >nul
        powershell -WindowStyle Hidden -Command "Start-Process -FilePath '%~dp0Launcher.bat' -WindowStyle Hidden"
        exit /b
)