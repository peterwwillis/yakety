@echo off
echo Cleaning Yakety build artifacts...

:: Clean yakety build directory
if exist "build" (
    echo   Removing build\
    rmdir /s /q build
)

:: Clean Windows cross-compilation build
if exist "build-windows" (
    echo   Removing build-windows\
    rmdir /s /q build-windows
)

:: Clean generated icons
if exist "assets\generated" (
    echo   Removing assets\generated\
    rmdir /s /q assets\generated
)

if exist "assets\yakety.icns" (
    echo   Removing assets\yakety.icns
    del /f /q assets\yakety.icns
)

if exist "assets\yakety.iconset" (
    echo   Removing assets\yakety.iconset\
    rmdir /s /q assets\yakety.iconset
)

:: Check for command line arguments
if "%1"=="--all" goto :clean_whisper
if "%1"=="--whisper" goto :clean_whisper
goto :done

:clean_whisper
echo Cleaning whisper.cpp...

if exist "whisper.cpp\build" (
    echo   Removing whisper.cpp\build\
    rmdir /s /q whisper.cpp\build
)

if exist "whisper.cpp\build-windows" (
    echo   Removing whisper.cpp\build-windows\
    rmdir /s /q whisper.cpp\build-windows
)

:: Optional: remove models too
if "%1"=="--all" (
    echo.
    set /p response="WARNING: Do you want to remove downloaded models too? (y/N): "
    if /i "%response%"=="y" (
        if exist "whisper.cpp\models" (
            echo   Removing whisper.cpp\models\
            rmdir /s /q whisper.cpp\models
        )
    )
)

:done
:: Clean CMake cache files
echo Cleaning CMake cache files...
for /r %%i in (CMakeCache.txt) do if exist "%%i" del /f /q "%%i"
for /d /r %%i in (CMakeFiles) do if exist "%%i" rmdir /s /q "%%i"

:: Clean ninja files
for /r %%i in (.ninja_deps .ninja_log build.ninja) do if exist "%%i" del /f /q "%%i"

echo.
echo Clean complete!
echo.
echo Usage:
echo   clean.bat           - Clean yakety build files only
echo   clean.bat --whisper - Clean yakety and whisper.cpp build files
echo   clean.bat --all     - Clean everything (will ask about models)