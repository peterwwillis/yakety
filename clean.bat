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

:: Note: Not cleaning generated assets - these should be kept
:: To clean everything including assets, use deep-clean.bat

:: Remove the entire whisper.cpp clone
if exist "whisper.cpp" (
    echo   Removing whisper.cpp\
    rmdir /s /q whisper.cpp
)

echo.
echo Clean complete!