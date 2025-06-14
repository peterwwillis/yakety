# Build System Documentation

<!-- Generated: 2025-06-14 22:22:00 UTC -->

## Overview

Yakety uses a CMake-based build system with automatic dependency management and cross-platform support. The system centers around `/Users/badlogic/workspaces/yakety/CMakeLists.txt` (lines 1-535) and specialized CMake modules in the `cmake/` directory.

**Key Build Configuration Files:**
- `CMakeLists.txt` - Main build configuration with 5 executables and platform-specific targets
- `CMakePresets.json` - Build presets for release, debug, and Visual Studio configurations  
- `cmake/BuildWhisper.cmake` - Automatic whisper.cpp cloning, building, and model downloading
- `cmake/PlatformSetup.cmake` - Platform-specific framework and library detection
- `cmake/GenerateIcons.cmake` - SVG-to-icon generation pipeline

## Build Workflows

### Quick Start Commands

**Standard Release Build:**
```bash
cmake --preset release          # Configure with Ninja generator
cmake --build --preset release  # Build optimized executables
```

**Debug Build with Full Symbols:**
```bash
cmake --preset debug           # Configure debug build
cmake --build --preset debug  # Build with debug info
```

**Visual Studio Debug (Windows only):**
```bash
cmake --preset vs-debug       # Configure VS project
cmake --build --preset vs-debug --config Debug
```

### Common Build Tasks

**Clean and Rebuild:**
```bash
rm -rf build/ build-debug/     # Remove build directories
cmake --preset release && cmake --build --preset release
```

**Generate Distribution Packages:**
```bash
cmake --build build --target package    # Platform-specific packages
cmake --build build --target upload     # Upload to server (requires scp/rsync)
```

**Build Test Executables (macOS only):**
```bash
cmake --build build --target test-model-dialog
cmake --build build --target test-keycombination-dialog
cmake --build build --target test-download-dialog
```

### Build Targets Reference

**Main Executables** (lines 114-206):
- `yakety-cli` - Command-line tool with console output
- `yakety-app` - GUI app (macOS bundle, Windows GUI executable)
- `recorder` - Audio recording utility
- `transcribe` - Standalone transcription tool

**Platform Library** (lines 46-85):
- `platform` - Static library with OS-specific implementations
- Sources: `src/mac/` (macOS), `src/windows/` (Windows)
- Links: Platform frameworks (macOS), system libraries (Windows)

**Distribution Targets** (lines 358-471):
- `package-cli-macos` / `package-cli-windows` - CLI tools zip
- `package-app-macos` / `package-app-windows` - GUI app packages  
- `package` - Combined platform packages
- `upload` - Upload packages to server

## Platform Setup

### macOS Requirements

**Dependencies** (`cmake/PlatformSetup.cmake` lines 4-43):
```bash
# Required frameworks automatically detected:
# ApplicationServices, AppKit, CoreFoundation, Foundation
# ServiceManagement, CoreAudio, AudioToolbox, AVFoundation
# Accelerate (for performance)

# Optional GPU acceleration:
# Metal, MetalKit, MetalPerformanceShaders
```

**Build Configuration** (`CMakeLists.txt` lines 18-23):
- ARM64 only (Apple Silicon): `CMAKE_OSX_ARCHITECTURES=arm64`
- Minimum macOS 14.0: `CMAKE_OSX_DEPLOYMENT_TARGET=14.0`
- Swift 6 compatibility with incremental compilation disabled

**Code Signing** (`cmake/PlatformSetup.cmake` lines 85-94):
```bash
# Automatic ad-hoc signing post-build:
codesign --force --deep --sign - "$<TARGET_BUNDLE_DIR>"
xattr -cr "$<TARGET_BUNDLE_DIR>"  # Remove quarantine
```

### Windows Requirements  

**System Libraries** (`cmake/PlatformSetup.cmake` lines 44-62):
```cmake
# Required: winmm ole32 user32 shell32 gdi32
# Optional Vulkan GPU acceleration (requires VULKAN_SDK env var)
```

**Visual Studio Compatibility** (`CMakeLists.txt` lines 301-308):
- Debug builds use Release runtime library (/MD) to match whisper.cpp
- Iterator debug level disabled for compatibility

**Vulkan Detection** (`cmake/BuildWhisper.cmake` lines 52-55):
```cmake
if(DEFINED ENV{VULKAN_SDK})
    # Enables GPU acceleration in whisper.cpp
    set(WHISPER_CMAKE_ARGS -DGGML_VULKAN=ON)
endif()
```

### Linux Support

**Package Requirements** (`cmake/PlatformSetup.cmake` lines 63-82):
```bash
# Threading: libpthread
# Audio: libasound2-dev (ALSA), libpulse-dev (PulseAudio)  
# Basic: libdl, libm
```

## Reference

### whisper.cpp Integration

**Automatic Setup** (`cmake/BuildWhisper.cmake` lines 4-101):
1. Clone from https://github.com/ggerganov/whisper.cpp.git if missing
2. Configure with platform-specific optimizations (Metal/Vulkan/Native)
3. Build Release configuration with static libraries
4. Link core libraries: whisper, ggml, ggml-cpu, ggml-base

**Model Download** (`cmake/BuildWhisper.cmake` lines 104-131):
- Downloads ggml-base-q8_0.bin (110MB multilingual model)  
- Source: https://huggingface.co/ggerganov/whisper.cpp/resolve/main/
- Timeout: 300 seconds, stored in `whisper.cpp/models/`

**Library Linking** (`CMakeLists.txt` lines 214-261):
```cmake
# Platform-specific GPU acceleration libraries:
# macOS: ggml-metal, ggml-blas (optional)
# Windows: ggml-vulkan (if Vulkan SDK present)
# Include paths: whisper/, whisper/include/, whisper/ggml/include/
```

### Icon Generation Pipeline

**SVG Master Icon** (`cmake/GenerateIcons.cmake` lines 24-133):
- Source: `assets/yakety.svg` (vectorized master)
- Tool requirements: rsvg-convert (librsvg), ImageMagick
- Generated sizes: 16x16 through 1024x1024, plus @2x retina variants

**Platform Icons:**
- macOS: .icns bundle via iconutil (`assets/yakety.icns`)
- Windows: Multi-resolution .ico (`assets/yakety.ico`)  
- Menubar: Template icons (black versions for menu bar display)

### Compiler Configuration

**C/C++ Standards** (`CMakeLists.txt` lines 5-9):
- C99 standard required
- C++11 standard required  
- Swift 6 (macOS only)

**Warning Flags** (`CMakeLists.txt` lines 309-340):
```cmake
# Non-Windows: -Wall -Wextra -Werror
# Exceptions: -Wno-error=unused-parameter -Wno-error=unused-function
# Debug: -g -O0 -fno-omit-frame-pointer
```

### Troubleshooting

**Common Build Issues:**

1. **Missing whisper.cpp**: Automatic clone requires git and internet access
2. **Swift compiler not found**: Install Xcode Command Line Tools (macOS)
3. **Vulkan not detected**: Install Vulkan SDK and set VULKAN_SDK environment variable
4. **Icon generation failed**: Install librsvg and ImageMagick packages
5. **Code signing failed**: Run `./sign-app.sh` manually after build

**Build Artifact Locations:**
- Debug build: `build-debug/bin/`
- Release build: `build/bin/`  
- VS Debug: `build-vs/bin/Debug/`
- Distribution packages: `build/*.zip`, `build/*.dmg`

**Library Path Detection** (`CMakeLists.txt` lines 215-250):
```cmake
# Whisper libraries auto-detected in:
# Windows VS: whisper.cpp/build/src/Release/
# Other: whisper.cpp/build/src/
```