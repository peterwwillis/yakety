# Yakety - Project Overview

## Project Name and Purpose

**Yakety** is a cross-platform voice-to-text input application that enables users to perform speech transcription for any application through a simple hotkey-based workflow. The core functionality is: hold a hotkey to record audio, release the hotkey to automatically transcribe the speech using AI, and paste the resulting text into the currently active application.

## Main Functionality

### Core Features
- **Universal Voice Input**: Works with any application that accepts text input
- **Hotkey-Driven Recording**: Press and hold a configurable hotkey to record, release to transcribe
- **Automatic Text Insertion**: Transcribed text is automatically pasted into the active application
- **System Tray Integration**: Runs as a background system tray/menubar application
- **Cross-Platform Support**: Native implementations for macOS and Windows

### Key Workflows
1. **Voice-to-Text**: Hold hotkey → Record audio → Release → AI transcription → Auto-paste text
2. **Configuration**: System tray menu provides access to hotkey settings, model selection, and preferences
3. **Model Management**: Supports custom Whisper models with automatic fallback to bundled models
4. **Permission Handling**: Automated microphone and accessibility permission requests

## Key Technologies and Dependencies

### Core Technologies
- **Programming Languages**: C-style C++ with platform-specific implementations in Objective-C (macOS) and C (Windows)
- **Build System**: CMake with advanced preset-based configuration using Ninja generator
- **AI Engine**: OpenAI Whisper (whisper.cpp) for speech-to-text transcription
- **Audio Processing**: miniaudio library for cross-platform audio recording (16kHz mono, optimized for Whisper)

### Platform-Specific Technologies

#### macOS
- **UI Frameworks**: Cocoa, SwiftUI (for modern dialogs)
- **System Integration**: NSStatusItem (menu bar), CGEventTap (keyboard monitoring), NSPasteboard (clipboard)
- **GPU Acceleration**: Metal acceleration with CoreML fallback
- **Architecture**: Apple Silicon (ARM64) optimized builds

#### Windows  
- **System Integration**: System tray, low-level keyboard hooks, Windows clipboard API
- **GPU Acceleration**: Vulkan acceleration with CPU fallback
- **Build Environment**: Visual Studio 2019+ with WSL development support

### Dependencies
- **whisper.cpp**: OpenAI Whisper implementation in C++ with GPU acceleration support
- **ggml**: Machine learning tensor library (part of whisper.cpp)
- **miniaudio**: Cross-platform audio I/O library
- **Platform Libraries**: Foundation/Cocoa (macOS), Win32 API (Windows)

## Target Platforms

### Supported Platforms
- **macOS**: 14.0+ (Sonoma and later)
  - Native Apple Silicon (ARM64) builds
  - Intel x86_64 support available
  - Xcode Command Line Tools required for development

- **Windows**: Windows 10+ 
  - x86_64 architecture
  - Visual Studio 2019+ for development
  - WSL integration for remote development from macOS

### Build Requirements
- **Cross-Platform**: CMake 3.20+, Ninja build system
- **macOS**: Xcode Command Line Tools, Metal support
- **Windows**: Visual Studio 2019+, Windows SDK, optional Vulkan SDK

## Architecture Highlights

### Modular Design
- **Platform Abstraction**: Clean separation between platform-specific code (`src/mac/`, `src/windows/`) and business logic
- **Module-Based Architecture**: Well-defined interfaces for logging, clipboard, overlay, dialog, menu, keylogger, and app lifecycle
- **Single Entry Point**: Unified `main.c` for both CLI and GUI applications using `APP_ENTRY_POINT` macro

### Advanced Features
- **GPU Acceleration**: Automatic Metal (macOS) and Vulkan (Windows) acceleration with CPU fallbacks
- **Thread Safety**: Mutex-based protection for transcription context and atomic operations for app state
- **Blocking Async Pattern**: Revolutionary approach combining synchronous code simplicity with UI responsiveness through event pumping
- **Configuration Management**: INI-based settings with platform-appropriate storage locations
- **Remote Development**: WSL-based infrastructure for cross-platform development

### Distribution
- **macOS**: App bundles (.app) and DMG installers with code signing
- **Windows**: Standalone executables with ZIP distribution packages
- **CLI Tools**: Additional command-line utilities (`yakety-cli`, `recorder`, `transcribe`) for advanced usage

## Project Structure

```
yakety/
├── src/                    # Source code
│   ├── *.{c,h}            # Platform-agnostic business logic
│   ├── mac/               # macOS-specific implementations  
│   └── windows/           # Windows-specific implementations
├── whisper.cpp/           # AI transcription engine (submodule)
├── assets/                # Icons and resources
├── cmake/                 # Build system configuration
├── docs/                  # Documentation
└── wsl/                   # Remote development infrastructure
```

This architecture enables Yakety to provide a seamless voice-to-text experience across platforms while maintaining clean, maintainable code through its modular design and sophisticated build system.