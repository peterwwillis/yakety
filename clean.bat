@echo off
echo Cleaning all build artifacts...

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

:: Remove the entire whisper.cpp clone
if exist "whisper.cpp" (
    echo   Removing whisper.cpp\
    rmdir /s /q whisper.cpp
)

echo.
echo Clean complete!