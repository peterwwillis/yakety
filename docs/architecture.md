# Yakety Architecture

<!-- Generated: 2025-06-14 21:06:06 UTC -->

## Overview

Yakety is a cross-platform voice-to-text application built with a modular architecture using C/C++ for performance-critical components and platform-specific APIs for system integration. The application follows a singleton pattern for core components with clear separation between business logic and platform-specific implementations.

The system operates as both a CLI tool and tray application, using a unified entry point that adapts based on build configuration. Core functionality centers around real-time audio capture, Whisper-powered speech recognition, and seamless clipboard integration for instant text pasting.

## Component Map

### Core Application Layer
- **Main Entry Point**: `src/main.c` (lines 329-390) - Unified entry for CLI/tray modes
- **Application Framework**: `src/app.h` - Platform abstraction for app lifecycle
- **Business Logic**: Audio capture → Transcription → Clipboard integration

### Platform Abstraction Layer
- **macOS Implementation**: `src/mac/` - Objective-C/Swift platform code
- **Windows Implementation**: `src/windows/` - Win32 API platform code
- **Platform Library**: Built as static library via CMake (lines 46-85 in `CMakeLists.txt`)

### Audio Processing Pipeline
- **Audio Capture**: `src/audio.c` - MiniAudio-based recorder (16kHz mono)
- **Speech Recognition**: `src/transcription.cpp` - Whisper.cpp integration
- **Model Management**: `src/models.c` - Handles model loading with fallback

### System Integration
- **Keyboard Monitoring**: `src/keylogger.h` - Hotkey detection (FN/Right Ctrl)
- **Clipboard Operations**: `src/clipboard.h` - Copy/paste functionality
- **System Menu**: `src/menu.h` - Tray menu management
- **Visual Feedback**: `src/overlay.h` - Recording/transcription overlays

## Key Files

### Core Headers
- **`src/app.h`** (lines 6-43): Cross-platform entry point macros, handles Windows GUI vs console mode
- **`src/audio.h`** (lines 7-37): Audio recorder singleton API with fixed Whisper configuration (16kHz mono)
- **`src/transcription.h`** (lines 8-15): Whisper.cpp wrapper with language configuration
- **`src/keylogger.h`** (lines 17-20): Key combination structure supporting up to 4 keys for complex hotkeys

### Platform Implementations
- **`src/mac/keylogger.c`** (lines 16-54): macOS accessibility API integration with CGEvent filtering
- **`src/mac/app.m`**: Cocoa application lifecycle and menu bar integration
- **`src/mac/dialogs/`**: SwiftUI dialog implementations for model selection and settings
- **`src/windows/keylogger.c`**: Win32 low-level keyboard hook implementation

### Business Logic
- **`src/audio.c`** (lines 14-32): AudioRecorder struct with dynamic buffer management and file output
- **`src/transcription.cpp`** (lines 17-26): Thread-safe Whisper context with mutex protection
- **`src/models.c`** (lines 24-88): Model loading with automatic fallback to base model on failure
- **`src/preferences.c`**: JSON-based configuration with key combination serialization

## Data Flow

### Recording Flow
1. **Hotkey Detection**: `src/mac/keylogger.c:75-80` - Key press triggers `on_key_press()`
2. **Audio Start**: `src/main.c:224-229` - Calls `audio_recorder_start()` with overlay feedback
3. **Buffer Capture**: `src/audio.c:38-80` - MiniAudio callback writes to dynamic buffer
4. **Audio Stop**: `src/main.c:233-250` - Key release triggers `on_key_release()` with duration check

### Transcription Flow
1. **Sample Extraction**: `src/main.c:177-181` - `audio_recorder_get_samples()` returns float array
2. **Whisper Processing**: `src/main.c:187-189` - `transcription_process()` handles speech-to-text
3. **Text Cleanup**: `src/transcription.cpp` - Filters output and adds trailing space for pasting
4. **Clipboard Integration**: `src/main.c:195-197` - `clipboard_copy()` + `clipboard_paste()`

### Platform Integration
- **macOS**: Uses Cocoa for menu bar, SwiftUI for dialogs, Accessibility API for keyboard monitoring
- **Windows**: Win32 system tray, native dialogs, low-level keyboard hooks
- **Whisper.cpp**: Integrated as external dependency with Flash Attention and GPU acceleration

### Model Management
- **Initialization**: `src/models.c:24-41` calls `utils_get_model_path()` → `transcription_init()`
- **Fallback Strategy**: `src/models.c:43-89` removes corrupted models, falls back to bundled base model
- **Path Resolution**: Checks preferences → bundled resources → download fallback

### Event Loop
- **CLI Mode**: `src/main.c:383` - Blocking `app_run()` with signal handlers
- **Tray Mode**: Platform-specific message loops in `src/mac/app.m` and `src/windows/app.c`
- **Threading**: Audio callback on separate thread, transcription on main thread with mutex protection

### Build System
- **CMake Configuration**: `CMakeLists.txt:1-535` handles cross-platform builds, Whisper.cpp integration
- **Platform Detection**: Lines 18-23 set macOS deployment target and architecture
- **Resource Bundling**: Lines 159-183 embed icons and models in app bundles
- **Code Signing**: macOS app bundles use automatic signing for distribution