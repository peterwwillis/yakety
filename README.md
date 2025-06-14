# Yakety

Universal voice-to-text input for any application via hotkey-based recording. Hold a hotkey to record, release to transcribe with AI, and auto-paste the text anywhere.

## Quick Start

```bash
# Build and run
cmake --preset release && cmake --build --preset release
./build/bin/yakety-cli --help
```

## What is Yakety?

Yakety transforms speech to text for any application through a simple workflow:
1. **Hold** your configured hotkey to record
2. **Release** to transcribe using OpenAI Whisper
3. **Text automatically pastes** into your active application

Works as a background system tray/menubar app with zero friction voice input.

## Features

- **Universal Compatibility**: Works with any text-accepting application
- **AI-Powered**: OpenAI Whisper for accurate speech recognition
- **Cross-Platform**: Native macOS (SwiftUI/Objective-C) and Windows (Win32) implementations
- **GPU Accelerated**: Metal (macOS) and Vulkan (Windows) acceleration with CPU fallbacks
- **Smart Model Management**: Custom models with automatic fallback
- **Background Operation**: System tray integration with configurable hotkeys

## Requirements

**macOS**: 14.0+ (Sonoma), Apple Silicon preferred  
**Windows**: Windows 10+, Visual Studio 2019+  
**Build**: CMake 3.20+, 2GB disk space, internet connection

## Build Instructions

### macOS
```bash
# Prerequisites
xcode-select --install
brew install librsvg imagemagick  # Optional: for icon generation

# Build
git clone <repo-url> yakety && cd yakety
cmake --preset release
cmake --build --preset release

# Run
./build/bin/yakety-cli --help
./build/bin/Yakety.app/Contents/MacOS/Yakety  # GUI app
```

### Windows (WSL Development)
```bash
# Sync from macOS (if doing remote development)
rsync -av --exclude='build/' --exclude='whisper.cpp/' \
  . badlogic@192.168.1.21:/mnt/c/workspaces/yakety/

# Build via SSH
ssh badlogic@192.168.1.21 "cd /mnt/c/workspaces/yakety && \
  /mnt/c/Windows/System32/cmd.exe /c 'cd c:\\workspaces\\yakety && \
  c:\\workspaces\\winvs.bat && cmake --preset release && \
  cmake --build --preset release'"
```

## Project Structure

```
yakety/
├── src/                    # Source code
│   ├── *.{c,h,cpp}        # Platform-agnostic business logic
│   ├── mac/               # macOS implementations (Objective-C/SwiftUI)
│   ├── windows/           # Windows implementations (Win32 C)
│   └── tests/             # Test programs
├── whisper.cpp/           # AI transcription engine (auto-cloned)
├── assets/                # Icons and resources
├── cmake/                 # Build system configuration
├── CMakePresets.json      # Build presets (release, debug, vs-debug)
└── docs/                  # Documentation
```

## Available Build Targets

**Applications**:
- `yakety-cli` - Command-line interface
- `yakety-app` (Yakety.app/Yakety.exe) - GUI system tray application
- `recorder` - Standalone audio recording utility
- `transcribe` - Batch transcription tool

**Packages**:
```bash
cmake --build --preset release --target package      # All packages
cmake --build --preset release --target package-app-macos  # macOS DMG
cmake --build --preset release --target package-cli-windows # Windows CLI ZIP
```

## Build Presets

- `release` - Optimized production build (Ninja)
- `debug` - Debug build with symbols (Ninja)
- `vs-debug` - Visual Studio debugging (Windows only)

## Development

### Code Style
- **C-style C++**: Use C++ features only for whisper.cpp integration
- **File extensions**: `.c` for pure C, `.cpp` for C++ features, `.m/.swift` for macOS
- **Naming**: snake_case with module prefixes (`audio_*`, `models_*`)
- **Formatting**: clang-format with 4-space indentation, 120-char lines

### Architecture Principles
- **Platform abstraction**: Common business logic in `src/`, platform-specific in `src/mac/` and `src/windows/`
- **Module boundaries**: Clear APIs with singleton pattern for system resources
- **Thread safety**: Mutex-based protection with atomic operations

### Testing
Manual testing only. Test programs available for dialog functionality:
```bash
./build/bin/test-model-dialog          # Model selection (macOS)
./build/bin/test-keycombination-dialog # Hotkey configuration (macOS)
./build/bin/test-download-dialog       # Model download (macOS)
```

### Development Tools
- Always use `rg` instead of `grep` for searching
- clang-format for code formatting
- CMake with compile_commands.json for IDE integration
- VS Code with LLDB debugging support

## Dependencies

**Core**: whisper.cpp (auto-built), miniaudio, ggml  
**macOS**: System frameworks (Cocoa, Metal, AVFoundation)  
**Windows**: Win32 APIs, optional Vulkan SDK  
**AI Model**: ggml-base-q8_0.bin (~110MB, auto-downloaded)

## Distribution

**macOS**: App bundles (.app) and DMG installers with code signing  
**Windows**: Portable ZIP archives with self-contained executables  
**Both**: Include 110MB Whisper model and all dependencies

## Remote Development

Full WSL-based workflow for cross-platform development from macOS. See `wsl/REMOTE_DEVELOPMENT.md` for complete setup instructions.

## Contributing

1. Follow C-style C++ conventions
2. Use appropriate build preset for your platform
3. Test manually (automated testing not available)
4. Ensure code compiles on both macOS and Windows

## License

[Add license information]