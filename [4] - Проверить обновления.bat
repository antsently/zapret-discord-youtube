@echo off
setlocal EnableDelayedExpansion

:: Установить кодировку консоли для русских символов
chcp 65001 > nul

:: Основные настройки
set "CURRENT_VERSION=1.6.1"
set "GITHUB_URL=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/version.txt"
set "RELEASE_URL=https://github.com/Flowseal/zapret-discord-youtube/releases"
set "VERSION_FILE=version.txt"
set "SKIP_VERSION=null"
set "FILE_EXISTS=1"

for /f "delims=" %%A in ('powershell -command "[datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss')"') do set CURRENT_TIMESTAMP=%%A

:: Проверка существования файла версии
if not exist %VERSION_FILE% (
    set "FILE_EXISTS=0"
    echo time: %CURRENT_TIMESTAMP%> %VERSION_FILE%
    echo ver: %CURRENT_VERSION%>> %VERSION_FILE%
)

for /f "tokens=1,* delims=: " %%A in (%VERSION_FILE%) do (
    if "%%A"=="time" set "LAST_CHECK=%%B"
    if "%%A"=="ver" set "INSTALLED_VERSION=%%B"
    if "%%A"=="skip" set "SKIP_VERSION=%%B"
)

:: Проверка интервала между обновлениями
if "%~1"=="soft" (
    for /f "tokens=1-6 delims=-: " %%A in ("%CURRENT_TIMESTAMP%") do (
        set "CURRENT_MONTH=%%B"
        set "CURRENT_DAY=%%C"
        set "CURRENT_HOUR=%%D"
    )
    for /f "tokens=1-6 delims=-: " %%A in ("%LAST_CHECK%") do (
        set "LAST_MONTH=%%B"
        set "LAST_DAY=%%C"
        set "LAST_HOUR=%%D"
    )

    set /a "time_diff_in_minutes = (CURRENT_MONTH - LAST_MONTH) * 43200 + (CURRENT_DAY - LAST_DAY) * 1440 + (CURRENT_HOUR - LAST_HOUR) * 60"

    if !time_diff_in_minutes! LEQ 360 if !FILE_EXISTS!==1 (
        echo Пропускается проверка обновлений, так как прошло менее 6 часов.
        goto :EOF
    )
)

:: Получение новой версии
set "NEW_VERSION="
for /f "delims=" %%A in ('powershell -command "(Invoke-WebRequest -Uri %GITHUB_URL% -Headers @{\"Cache-Control\"=\"no-cache\"} -TimeoutSec 5).Content" 2^>nul') do set "NEW_VERSION=%%A"
if not defined NEW_VERSION (
    echo Ошибка при чтении новой версии.
    goto :EOF
)

:: Обновление файла версии
echo time: %CURRENT_TIMESTAMP%> %VERSION_FILE%
echo ver: %INSTALLED_VERSION%>> %VERSION_FILE%
echo skip: %SKIP_VERSION%>> %VERSION_FILE%

:: Сравнение версий
if "%NEW_VERSION%"=="%INSTALLED_VERSION%" (
    echo Вы используете последнюю версию: %NEW_VERSION%.
    goto :EOF
) else (
    if "%NEW_VERSION%"=="%SKIP_VERSION%" (
        echo Новая версия %NEW_VERSION% пропущена пользователем.
        goto :EOF
    ) else (
        echo Обнаружена новая версия: %NEW_VERSION%.
        echo Посетите %RELEASE_URL%, чтобы скачать новую версию.
    )
)

:: Диалог с пользователем
set /p "CHOICE=Пропустить это обновление? (y/n, default: n): " || set "CHOICE=n"
set "CHOICE=!CHOICE:~0,1!"
if /i "!CHOICE!"=="y" (
    echo skip: %NEW_VERSION%>> %VERSION_FILE%
    echo Update %NEW_VERSION% skipped.
) else (
    start %RELEASE_URL%
)

endlocal
