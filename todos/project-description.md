# Project: Yakety
A cross-platform speech-to-text application that provides instant voice transcription through global keyboard shortcuts. Press and hold a hotkey to record your voice, and Yakety automatically transcribes and pastes the text into your active application. All processing happens locally for complete privacy.

## Features
- Real-time voice recording via global hotkeys (FN on macOS, Right Ctrl on Windows)
- Local transcription using Whisper AI models (no cloud dependency)
- Automatic text insertion into any application
- System tray/menu bar integration with visual recording overlay
- Model management system with embedded base.en model
- Cross-platform support for macOS and Windows

## Tech Stack
- Languages: C (primary), C++, Objective-C, Swift
- AI: Whisper.cpp for speech recognition
- Audio: MiniAudio for cross-platform recording
- Build: CMake 3.20+ with Ninja/Visual Studio/Xcode
- UI: SwiftUI (macOS), Win32 API (Windows)

## Structure
- `src/` - Core application code
- `src/mac/` - macOS platform layer (Obj-C/Swift)
- `src/windows/` - Windows platform layer
- `src/tests/` - UI component tests
- `cmake/` - Build system modules
- `assets/` - Icons and resources
- `whisper.cpp/` - Speech recognition engine

## Architecture
Platform abstraction layer pattern with cross-platform core and platform-specific implementations. Main workflow: Hotkey → Audio Recording → Transcription → Clipboard. Components include tray menu, dialogs, preferences, and model management.

## Commands
- Build: `./run.sh` (release) or `./run.sh debug` (debug build)
- Build & Run: `./run.sh run`
- Clean Build: `./run.sh clean`
- Package: `./run.sh package` (includes notarization)
- Upload: `./run.sh upload` (includes notarization & packaging)
- Check Permissions: `./permissions.sh`
- Clear Permissions: `./permissions.sh clear`

## Testing
Create UI tests in `src/tests/test_<component>.c` following the app framework pattern. Add to CMakeLists.txt and build as standalone executables. No unit testing framework currently integrated.

## Editor
- Open folder: code