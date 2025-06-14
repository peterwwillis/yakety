# Yakety Files Catalog

<!-- Generated: 2025-06-14 21:06:13 UTC -->

## Overview

Yakety is a cross-platform speech-to-text application built with C/C++/Swift using CMake. The codebase is organized around platform-specific implementations (macOS/Windows) with shared business logic, leveraging whisper.cpp for AI transcription. The architecture separates core audio processing, UI dialogs, system integration, and transcription into distinct modules with clear interfaces.

The build system uses CMake with custom modules for icon generation, whisper.cpp integration, and platform setup. Platform-specific code isolates system APIs while business logic remains portable across Mac and Windows targets. SwiftUI dialogs on macOS provide modern UI components while maintaining C API compatibility.

## Core Source Files

**Main Application Logic:**
- `/src/main.c` - Entry point with app lifecycle, keyboard handling, and transcription workflow (lines 217-251: key press/release handlers, 254-283: initialization sequence)
- `/src/app.h` - Cross-platform app framework with entry point macros and async execution API (lines 6-43: platform-specific entry points)
- `/src/transcription.cpp` - Whisper.cpp integration for speech-to-text processing
- `/src/transcription.h` - Transcription API interface

**Audio Processing:**
- `/src/audio.c` - Audio recording using miniaudio library for cross-platform capture
- `/src/audio.h` - Audio recorder interface and configuration
- `/src/miniaudio.h` - Third-party audio library (embedded header-only)

**Business Logic:**
- `/src/models.c` - Model management, loading, and download coordination
- `/src/models.h` - Model interface and configuration
- `/src/model_definitions.h` - Centralized model definitions with download URLs (lines 15-30: downloadable models, 35-41: bundled model)
- `/src/menu.c` - System tray/menu bar integration
- `/src/menu.h` - Menu interface and callbacks
- `/src/preferences.c` - Configuration persistence and user settings
- `/src/preferences.h` - Preferences API with get/set operations (lines 14-30: core API)

## Platform Implementation

**macOS (Objective-C/Swift):**
- `/src/mac/app.m` - Cocoa application lifecycle and event handling
- `/src/mac/clipboard.m` - Pasteboard integration for text insertion
- `/src/mac/dialog.m` - Native dialog coordination with SwiftUI components
- `/src/mac/keylogger.c` - Carbon Event Manager for global hotkey capture
- `/src/mac/logging.m` - Console and file logging with NSLog integration
- `/src/mac/menu.m` - Status bar menu with NSStatusItem
- `/src/mac/overlay.m` - HUD overlay for recording/transcribing status
- `/src/mac/utils.m` - System utilities and permission handling
- `/src/mac/dispatch.m` - Grand Central Dispatch async operations
- `/src/mac/http.m` - NSURLSession HTTP client for model downloads
- `/src/mac/Info.plist` - macOS bundle configuration and permissions

**macOS SwiftUI Dialogs:**
- `/src/mac/dialogs/dialog_utils.swift` - Shared SwiftUI utilities and helpers
- `/src/mac/dialogs/download_dialog.swift` - Model download progress interface
- `/src/mac/dialogs/hotkey_dialog.swift` - Keyboard shortcut configuration
- `/src/mac/dialogs/models_dialog.swift` - Model selection and management

**Windows Implementation:**
- `/src/windows/app.c` - Win32 application and message loop
- `/src/windows/clipboard.c` - Clipboard API for text operations
- `/src/windows/dialog.c` - MessageBox and native Windows dialogs
- `/src/windows/dialog_keycapture.c` - Keyboard input capture for hotkey setup
- `/src/windows/keylogger.c` - Low-level keyboard hooks (SetWindowsHookEx)
- `/src/windows/logging.c` - OutputDebugString and file logging
- `/src/windows/menu.c` - System tray implementation with Shell_NotifyIcon
- `/src/windows/overlay.c` - Layered window overlay for status display
- `/src/windows/utils.c` - Windows system utilities and registry operations
- `/src/windows/yakety.rc` - Windows resource definitions

**Platform Headers:**
- `/src/clipboard.h` - Cross-platform clipboard interface
- `/src/dialog.h` - Cross-platform dialog API
- `/src/http.h` - HTTP client interface
- `/src/keylogger.h` - Keyboard monitoring interface with KeyCombination struct
- `/src/logging.h` - Logging system interface
- `/src/overlay.h` - Status overlay interface
- `/src/utils.h` - Utility functions and async work definitions
- `/src/mac/dispatch.h` - macOS-specific async dispatch

## Build System

**CMake Configuration:**
- `/CMakeLists.txt` - Main build configuration with platform detection, library linking, and executable targets (lines 46-85: platform library setup, 252-261: whisper.cpp integration)
- `/CMakePresets.json` - Build preset configurations for different platforms
- `/cmake/BuildWhisper.cmake` - Whisper.cpp submodule build integration
- `/cmake/GenerateIcons.cmake` - Icon generation from SVG source
- `/cmake/PlatformSetup.cmake` - Platform-specific library discovery and framework linking (lines 4-42: macOS frameworks, 44-50: Windows libraries)

**Build Output:**
- `/build-debug/` - Debug build artifacts and CMake cache
- `/build/` - Release build directory
- `/build-debug/compile_commands.json` - Compilation database for language servers

## Configuration

**Assets and Resources:**
- `/assets/yakety.svg` - Source vector logo
- `/assets/yakety.icns` - macOS application icon
- `/assets/yakety.ico` - Windows application icon
- `/assets/generated/` - Generated icon sizes and menubar assets

**Scripts and Utilities:**
- `/sign-app.sh` - macOS code signing automation
- `/script.md` - Development notes and commands
- `/ideas.md` - Feature ideas and development roadmap

**External Dependencies:**
- `/whisper.cpp/` - Git submodule for AI transcription (complete whisper.cpp project)
- `/website/` - Project website with Docker deployment configuration

**Development Environment:**
- `/wsl/wsl-development.md` - WSL development setup guide
- `/wsl/setup-wsl-ssh.sh` - WSL SSH configuration script
- `/wsl/start-wsl-ssh.bat` - Windows batch file for WSL SSH startup

**Test Programs:**
- `/src/tests/test_model_dialog.c` - Model dialog testing (macOS only)
- `/src/tests/test_keycombination_dialog.c` - Hotkey dialog testing
- `/src/tests/test_download_dialog.c` - Download dialog testing

## Reference

**File Organization Patterns:**
- Platform code segregated in `/src/mac/` and `/src/windows/` directories
- Shared headers in `/src/` root with platform-specific implementations
- SwiftUI dialogs isolated in `/src/mac/dialogs/` with C bridging
- CMake modules in `/cmake/` for build system organization
- Generated assets in `/assets/generated/` to avoid version control

**Naming Conventions:**
- C files use lowercase with underscores: `audio_recorder.c`
- Headers match implementation files: `audio.c` → `audio.h`
- Platform directories: `mac/`, `windows/`
- CMake modules: `PascalCase.cmake`
- Swift files: `snake_case.swift`

**Dependency Relationships:**
- All executables depend on `platform` static library (CMakeLists.txt:118)
- Platform library links platform-specific frameworks/libraries
- Whisper.cpp integration through find_library discovery (CMakeLists.txt:224-228)
- Business logic files (`BUSINESS_SOURCES`) shared across targets (CMakeLists.txt:106-111)
- SwiftUI dialogs accessed through C bridge functions in `dialog.m`