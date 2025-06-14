# Yakety Architecture Documentation

This document provides a comprehensive overview of the Yakety application's architecture, including its directory structure, key modules, component interactions, and platform abstraction approach.

## Overview

Yakety is a cross-platform voice-to-text application that uses push-to-talk functionality to record audio, transcribe it using the Whisper.cpp library, and paste the resulting text into the active application. The application is built using C-style C++ with platform-specific native APIs for optimal performance and integration.

## Directory Structure

```
yakety/
├── src/                        # Source code
│   ├── *.{c,h,cpp}            # Core business logic (platform-agnostic)
│   ├── mac/                   # macOS-specific implementations
│   │   ├── *.{m,h}           # Objective-C implementations
│   │   └── dialogs/          # SwiftUI dialog implementations
│   │       └── *.swift       # SwiftUI components
│   ├── windows/               # Windows-specific implementations
│   │   ├── *.{c,h}           # C implementations
│   │   ├── dialogs/          # Windows dialog implementations
│   │   └── yakety.rc         # Windows resources
│   └── tests/                 # Test programs
├── cmake/                     # CMake helper modules
├── assets/                    # Application assets (icons, etc.)
├── whisper.cpp/              # Whisper.cpp submodule
├── build/                    # Build output directory
└── docs/                     # Documentation
```

## Architecture Layers

### 1. Application Layer
- **Entry Point**: `src/main.c` - Contains the main application logic and initialization
- **App Framework**: `src/app.h` - Provides platform-agnostic application lifecycle management
- **Build Configuration**: Multi-target CMake setup supporting CLI and GUI variants

### 2. Core Business Logic (Platform-Agnostic)
Located in `src/*.{c,h,cpp}`, these modules handle the core functionality:

#### Audio Processing
- **Module**: `src/audio.{c,h}`
- **Responsibility**: Audio recording and management using miniaudio
- **Features**: Real-time audio capture, sample rate conversion, buffer management

#### Transcription Engine
- **Module**: `src/transcription.{cpp,h}`
- **Responsibility**: Whisper.cpp integration for speech-to-text conversion
- **Features**: Model loading, audio processing, text cleanup, language support
- **Note**: Uses C++ for Whisper.cpp compatibility but maintains C-style interface

#### Model Management
- **Module**: `src/models.{c,h}` + `src/model_definitions.h`
- **Responsibility**: Whisper model discovery, loading, and management
- **Features**: Bundled model support, downloadable model system, automatic fallbacks

#### Keyboard Monitoring
- **Module**: `src/keylogger.{h}` (platform implementations vary)
- **Responsibility**: Global hotkey detection and management
- **Features**: Customizable key combinations, permission handling, press/release events

#### Menu System
- **Module**: `src/menu.{c,h}`
- **Responsibility**: System tray/menu bar integration
- **Features**: Dynamic menu creation, platform-specific implementations

#### Configuration Management
- **Module**: `src/preferences.{c,h}`
- **Responsibility**: Application settings persistence
- **Features**: Cross-platform config file management, preference validation

### 3. Platform Abstraction Layer
Each platform implements the same interfaces defined in the core headers:

#### macOS Implementation (`src/mac/`)
- **Language**: Objective-C for system integration, C for core logic
- **UI Framework**: SwiftUI for modern dialog interfaces
- **Key Files**:
  - `app.m` - NSApplication lifecycle management
  - `dialog.m` - Dialog coordination between Objective-C and SwiftUI
  - `dialogs/*.swift` - SwiftUI dialog implementations
  - `keylogger.c` - macOS accessibility API integration
  - `menu.m` - NSStatusBar menu implementation

#### Windows Implementation (`src/windows/`)
- **Language**: C with Win32 APIs
- **UI Framework**: Native Win32 dialogs
- **Key Files**:
  - `app.c` - Windows message loop and lifecycle
  - `dialog.c` - Win32 dialog implementations
  - `keylogger.c` - Windows low-level keyboard hooks
  - `menu.c` - System tray implementation

#### Cross-Platform Utilities (`src/utils.h`)
- **Async Operations**: Thread management and background task execution
- **File System**: Cross-platform file operations and path handling
- **Threading**: Mutex operations and atomic access
- **Platform Integration**: Launch-at-login, accessibility settings

### 4. User Interface Layer

#### Dialog System
- **Unified Interface**: `src/dialog.h` defines common dialog functions
- **Platform-Specific Implementation**: 
  - macOS: SwiftUI-based modern dialogs with native look and feel
  - Windows: Win32 native dialogs
- **Dialog Types**:
  - Model selection and download
  - Hotkey configuration
  - Permission requests
  - Error/info messages

#### System Integration
- **Overlay System**: Real-time status display during recording/processing
- **Clipboard Integration**: Automated text pasting into active applications
- **System Tray**: Background operation with menu access

## Component Interactions

### Startup Flow
1. **App Initialization** (`main.c` → `app.h`)
   - Platform detection and app framework setup
   - Preference loading and validation
   - Component initialization in dependency order

2. **Model Loading** (`models.c`)
   - Bundled model discovery
   - Downloaded model validation
   - Fallback mechanisms for missing models
   - Dialog presentation for model selection if needed

3. **System Integration Setup**
   - Menu system creation (tray apps only)
   - Keyboard monitor initialization
   - Permission handling (macOS accessibility)
   - Audio system initialization

### Runtime Operation Flow
1. **Hotkey Detection** (Platform-specific keylogger)
2. **Audio Recording** (`audio.c` with miniaudio)
3. **Transcription Processing** (`transcription.cpp` with Whisper.cpp)
4. **Text Processing** (Cleanup and formatting)
5. **Clipboard Operations** (Platform-specific clipboard + paste)

### Dialog System Architecture
```
dialog.h (Common Interface)
    ├── mac/dialog.m (Coordinator)
    │   └── mac/dialogs/*.swift (SwiftUI Implementation)
    └── windows/dialog.c (Win32 Implementation)
```

## Platform Abstraction Approach

### Design Philosophy
- **C-Style C++**: Core logic written in C with C++ only where required (Whisper.cpp integration)
- **Platform-Specific UI**: Native look and feel using platform frameworks
- **Unified Interfaces**: Common header definitions with platform-specific implementations
- **Minimal Dependencies**: Prefer platform APIs over third-party libraries

### Build System
- **CMake Configuration**: Multi-preset system supporting different build types
- **Platform Libraries**: Static `platform` library containing all platform-specific code
- **Multi-Target**: Separate CLI and GUI executables from same codebase
- **Code Signing**: Automated signing and packaging for distribution

### Threading Model
- **Main Thread**: UI operations and event handling
- **Background Threads**: Audio processing, transcription, model operations
- **Thread Safety**: Mutex-based synchronization and atomic operations
- **Responsive UI**: Non-blocking async operations with callback mechanisms

## Key Design Decisions

### Language Choices
- **Core Logic**: C for simplicity, performance, and cross-platform compatibility
- **macOS UI**: SwiftUI for modern native dialogs, Objective-C for system integration
- **Windows UI**: Win32 APIs for lightweight native integration
- **Whisper Integration**: C++ wrapper maintaining C interface

### Model Management Strategy
- **Bundled Model**: Base model included for immediate functionality
- **Downloadable Models**: On-demand model acquisition for advanced features
- **Unified Loading**: Single `models_load()` function handles all model scenarios
- **Graceful Fallbacks**: Progressive fallback from custom → bundled → error dialogs

### Platform Integration
- **System Tray**: Background operation without window management
- **Global Hotkeys**: System-wide keyboard monitoring with permission handling
- **Accessibility**: Proper integration with platform accessibility systems
- **Launch Integration**: System startup integration with user control

## Testing Strategy

The application includes focused test programs for critical components:
- `test_model_dialog.c` - Model selection dialog testing
- `test_keycombination_dialog.c` - Hotkey configuration testing  
- `test_download_dialog.c` - Model download dialog testing

## Distribution Architecture

### Build Variants
- **CLI Tools**: `yakety-cli`, `recorder`, `transcribe` - Command-line utilities
- **GUI Applications**: `yakety-app` (Yakety.exe/Yakety.app) - System tray applications
- **Platform Packages**: Automated DMG (macOS) and ZIP (Windows) creation

### Deployment Strategy
- **Self-Contained**: All dependencies bundled including Whisper models
- **Code Signing**: Proper platform certification for security
- **Automated Distribution**: Build and upload pipeline for releases

This architecture provides a robust, maintainable, and platform-appropriate foundation for the Yakety voice-to-text application while maintaining performance and native integration on each supported platform.