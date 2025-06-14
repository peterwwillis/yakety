<!-- Generated: 2025-06-14 22:35:00 UTC -->

# Yakety

Cross-platform speech-to-text application for instant voice transcription through global keyboard shortcuts. Press and hold FN (macOS) or Right Ctrl (Windows) to record, transcription is processed locally using Whisper models and automatically pasted.

## Quick Start

```bash
# Build and run
cmake --preset release && cmake --build --preset release
./build/bin/yakety-cli

# Or build GUI app bundle
cmake --build build --target yakety-app
```

## Core Files

- **Entry Point**: `src/main.c` - Application lifecycle and transcription workflow
- **Platform Layer**: `src/mac/`, `src/windows/` - OS-specific implementations
- **Build Config**: `CMakeLists.txt` - CMake with whisper.cpp integration
- **Audio**: `src/audio.c` - MiniAudio-based recording (16kHz mono)
- **Transcription**: `src/transcription.cpp` - Whisper.cpp integration
- **Models**: `src/models.c` - Model loading with fallback system

## Documentation

- **[Project Overview](docs/project-overview.md)** - Architecture, technology stack, platform requirements
- **[Architecture](docs/architecture.md)** - Component organization, data flow, platform abstraction
- **[Build System](docs/build-system.md)** - CMake configuration, dependencies, platform setup
- **[Development](docs/development.md)** - Code style, patterns, workflows, common issues
- **[Testing](docs/testing.md)** - Test programs, SwiftUI dialog verification
- **[Deployment](docs/deployment.md)** - Packaging, distribution, server deployment
- **[Files Catalog](docs/files.md)** - Complete file reference with dependencies
- **[Windows development on macOS through WSL](wsl/wsl-development.md)** - Modify code on macOS, rsync, compile and run on Windows through WSL.

## Requirements

- **macOS**: 14.0+, Apple Silicon, accessibility permissions
- **Windows**: Visual Studio or Ninja, optional Vulkan SDK
- **Dependencies**: CMake 3.20+, whisper.cpp (auto-downloaded)

## Distribution

```bash
cmake --build build --target package     # Platform packages
cmake --build build --target upload      # Upload to server
```

Outputs: CLI tools, app bundles (DMG/ZIP), all with embedded Whisper models and resources.
