<!-- Generated: 2025-06-14 22:35:00 UTC -->

# Project Overview

Yakety is a cross-platform speech-to-text application that enables instant voice transcription through global keyboard shortcuts. Users can press and hold a configurable hotkey (FN key on macOS, Right Ctrl on Windows) to record audio, which is then transcribed locally using OpenAI's Whisper models and automatically pasted into the currently active application. The application operates both as a background tray/menu bar service and command-line tool, providing seamless voice-to-text functionality without requiring cloud services or internet connectivity.

Built with performance and privacy in mind, Yakety performs all transcription processing locally on the user's device using optimized Whisper.cpp implementations with platform-specific hardware acceleration (Metal on macOS, Vulkan on Windows). The application provides an intuitive model management system that automatically downloads and manages different Whisper model variants, from lightweight tiny models (~40MB) to high-accuracy large models (~800MB), allowing users to balance speed versus transcription quality based on their hardware capabilities and use cases.

The architecture separates platform-specific implementations from core business logic, enabling consistent functionality across macOS and Windows while leveraging native system APIs for audio capture, clipboard operations, keyboard monitoring, and user interface components. This design approach ensures optimal performance and native user experience on each supported platform.

## Key Files

### Main Entry Points
- **`src/main.c`** (lines 329-388): Primary application entry point containing `app_main()` function that handles initialization sequence, model loading, keylogger setup, and main event loop
- **`src/app.h`** (lines 6-43): Cross-platform entry point macros that handle different build configurations (console vs tray app, Windows vs macOS)

### Core Configuration
- **`CMakeLists.txt`** (lines 1-535): Primary build configuration defining platform-specific source files, whisper.cpp integration, executable targets, and packaging rules
- **`src/mac/Info.plist`** (lines 1-34): macOS app bundle configuration with permissions (NSMicrophoneUsageDescription on line 28), bundle identifier, and system requirements
- **`src/preferences.c`** (lines 1-40): Configuration management system storing user settings, model paths, and hotkey combinations in platform-specific config directories

## Technology Stack

### Core Language and Build System
- **C99/C++11**: Primary implementation languages (CMakeLists.txt lines 6-9)
- **Swift 6**: Modern UI dialogs on macOS (CMakeLists.txt lines 55-57: `hotkey_dialog.swift`, `models_dialog.swift`, `download_dialog.swift`)
- **CMake 3.20+**: Cross-platform build system with custom modules (`cmake/BuildWhisper.cmake`, `cmake/PlatformSetup.cmake`)

### Audio and Transcription
- **Whisper.cpp**: Local speech recognition engine (CMakeLists.txt lines 28-261, integrated as external project)
- **miniaudio**: Cross-platform audio capture library (`src/audio.c` lines 1-3, `src/miniaudio.h`)
- **Hardware Acceleration**: Metal (macOS) and Vulkan (Windows) for GPU-accelerated inference (CMakeLists.txt lines 232-250)

### Platform Integration Examples
```c
// Cross-platform audio recording (src/audio.c lines 38-50)
void data_callback(ma_device *pDevice, void *pOutput, const void *pInput, ma_uint32 frameCount) {
    AudioRecorder *recorder = (AudioRecorder *) pDevice->pUserData;
    const float *input = (const float *) pInput;
    size_t samples = frameCount * WHISPER_CHANNELS; // 16kHz mono
}

// Platform-specific implementations directory structure
src/mac/          # macOS: Objective-C + Swift implementations
src/windows/      # Windows: Win32 C implementations
```

### Model Management
- **Whisper Model Variants**: From tiny (40MB) to large-v3-turbo (800MB) defined in `src/model_definitions.h` lines 15-30
- **Automatic Downloads**: HuggingFace integration for model acquisition via `src/models.c` unified loading system

## Platform Support

### macOS Requirements
- **Minimum Version**: macOS 14.0 (Sonoma) for Swift 6 compatibility (CMakeLists.txt line 22)
- **Architecture**: Apple Silicon (arm64) only (CMakeLists.txt line 20)
- **Permissions**: Microphone access and Accessibility permissions required (`src/mac/Info.plist` line 28, `src/main.c` lines 78-117)
- **Bundle Resources**: App icon, menubar icons, and Whisper models embedded in .app bundle (CMakeLists.txt lines 159-183)

### Windows Requirements  
- **Build Tools**: Visual Studio or Ninja generator support (CMakeLists.txt lines 215-222)
- **GPU Acceleration**: Optional Vulkan support for enhanced performance (CMakeLists.txt lines 241-249)
- **Distribution**: Portable executable with resource files (`src/windows/yakety.rc`)

### Build Targets and Outputs
```cmake
# Executable variants (CMakeLists.txt lines 113-196)
yakety-cli      # Command-line interface
yakety-app      # GUI tray application  
recorder        # Audio capture utility
transcribe      # Batch transcription tool

# Distribution packages (CMakeLists.txt lines 359-471)
package-macos   # DMG and ZIP for macOS
package-windows # ZIP distribution for Windows
```

### Development and Testing
- **Test Programs**: Dialog testing utilities for macOS (CMakeLists.txt lines 502-532)
- **Debug Configuration**: Comprehensive logging system with timing metrics (`src/logging.h`, `src/main.c` lines 255-283)
- **Code Signing**: Integrated macOS code signing pipeline (CMakeLists.txt line 186)