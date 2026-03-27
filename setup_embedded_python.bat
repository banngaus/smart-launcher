@echo off
chcp 65001 >nul
echo ══════════════════════════════════════════
echo   SmartLauncher — Embedded Python Setup
echo ══════════════════════════════════════════
echo.

set PYTHON_VERSION=3.12.7
set PYTHON_DIR=windows\python
set TEMP_DIR=_setup_temp

echo [1/7] Создаём временную папку...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

echo [2/7] Скачиваем Python Embedded %PYTHON_VERSION%...
curl -L -o "%TEMP_DIR%\python-embed.zip" ^
  "https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"

if not exist "%TEMP_DIR%\python-embed.zip" (
    echo ❌ Ошибка скачивания Python!
    pause
    exit /b 1
)

echo [3/7] Распаковываем Python...
if exist "%PYTHON_DIR%" rmdir /s /q "%PYTHON_DIR%"
mkdir "%PYTHON_DIR%"
tar -xf "%TEMP_DIR%\python-embed.zip" -C "%PYTHON_DIR%"

echo [4/7] Настраиваем Python для pip...
:: Находим файл ._pth и раскомментируем import site
for %%f in (%PYTHON_DIR%\python*._pth) do (
    echo python312.zip> "%%f"
    echo .>> "%%f"
    echo import site>> "%%f"
    echo    Обновлён: %%f
)

echo [5/7] Устанавливаем pip...
curl -L -o "%TEMP_DIR%\get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
"%PYTHON_DIR%\python.exe" "%TEMP_DIR%\get-pip.py" --no-warn-script-location --quiet

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Ошибка установки pip!
    pause
    exit /b 1
)

echo [6/7] Устанавливаем зависимости Python...
"%PYTHON_DIR%\python.exe" -m pip install ^
    Pillow ^
    psutil ^
    --no-warn-script-location --quiet --no-cache-dir

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Ошибка установки зависимостей!
    pause
    exit /b 1
)

echo    Проверяем Pillow...
"%PYTHON_DIR%\python.exe" -c "from PIL import Image; print('   ✅ Pillow', Image.__version__)"
echo    Проверяем psutil...
"%PYTHON_DIR%\python.exe" -c "import psutil; print('   ✅ psutil', psutil.__version__)"

echo [7/7] Скачиваем FFmpeg...
curl -L -o "%TEMP_DIR%\ffmpeg.zip" ^
  "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"

if exist "%TEMP_DIR%\ffmpeg.zip" (
    mkdir "%TEMP_DIR%\ffmpeg_extract"
    tar -xf "%TEMP_DIR%\ffmpeg.zip" -C "%TEMP_DIR%\ffmpeg_extract"

    :: Ищем и копируем ffmpeg.exe и ffprobe.exe
    for /r "%TEMP_DIR%\ffmpeg_extract" %%f in (ffmpeg.exe) do (
        copy "%%f" "%PYTHON_DIR%\ffmpeg.exe" >nul
        echo    ✅ ffmpeg.exe скопирован
    )
    for /r "%TEMP_DIR%\ffmpeg_extract" %%f in (ffprobe.exe) do (
        copy "%%f" "%PYTHON_DIR%\ffprobe.exe" >nul
        echo    ✅ ffprobe.exe скопирован
    )
) else (
    echo ⚠️  FFmpeg не скачан, конвертация аудио/видео не будет работать
)

echo.
echo Очистка временных файлов...
rmdir /s /q "%TEMP_DIR%"

echo.
echo ══════════════════════════════════════════
echo   ✅ Готово! Embedded Python настроен
echo ══════════════════════════════════════════
echo.
echo   Python: %PYTHON_DIR%\python.exe

:: Проверяем размер папки
for /f "tokens=3" %%a in ('dir "%PYTHON_DIR%" /s /-c ^| findstr "File(s)"') do set SIZE=%%a
echo   Размер: ~%SIZE% bytes
echo.
echo   Теперь можно собирать: flutter build windows
echo ══════════════════════════════════════════
pause