# Build System Documentation

This document provides a comprehensive overview of Yakety's build system, dependencies, and compilation setup.

## Build System Overview

Yakety uses **CMake 3.20+** as its primary build system with the following key characteristics:

- **Multi-platform support**: macOS, Windows (WSL), and Linux
- **External dependency management**: Automatic fetching and building of whisper.cpp
- **Multi-language support**: C, C++, Swift (on macOS), and Objective-C
- **Multiple build configurations**: Debug, Release, and Visual Studio debug modes
- **Cross-platform packaging**: Automated distribution package creation

### Project Structure

```
yakety/
├── CMakeLists.txt              # Main build configuration
├── CMakePresets.json           # Build presets for different configurations
├── cmake/                      # CMake helper modules
│   ├── BuildWhisper.cmake      # External whisper.cpp build management
│   ├── PlatformSetup.cmake     # Platform-specific configuration
│   └── GenerateIcons.cmake     # Icon generation from SVG
├── src/                        # Source code
│   ├── mac/                    # macOS-specific implementations
│   ├── windows/                # Windows-specific implementations
│   └── tests/                  # Test programs
├── assets/                     # Application assets
│   ├── yakety.svg              # Master SVG icon
│   ├── generated/             # Auto-generated icons
│   ├── yakety.icns            # macOS app icon
│   └── yakety.ico             # Windows app icon
└── whisper.cpp/               # External dependency (auto-cloned)
```

## Available Build Presets

### Normal Development

**Release Preset**
```bash
cmake --preset release
cmake --build --preset release
```
- Uses Ninja generator for fast builds
- Optimized for performance
- Output: `build/bin/`

**Debug Preset**  
```bash
cmake --preset debug
cmake --build --preset debug
```
- Uses Ninja generator
- Debug symbols and no optimization
- Output: `build-debug/bin/`

### Windows Visual Studio Debugging

**Visual Studio Debug Preset** (Windows only)
```bash
cmake --preset vs-debug
cmake --build --preset vs-debug
```
- Uses Visual Studio 2022 generator
- Provides full Visual Studio debugging support
- Required when debugging with Visual Studio IDE
- Output: `build-vs/bin/`

## Dependencies and Management

### Core Dependencies

#### External Dependencies
1. **whisper.cpp** (Required)
   - **Source**: https://github.com/ggerganov/whisper.cpp.git
   - **Management**: Automatically cloned and built via `BuildWhisper.cmake`
   - **Purpose**: Speech-to-text transcription engine
   - **Build**: Static libraries with GPU acceleration support

2. **Whisper Model** (Required)
   - **File**: `ggml-base-q8_0.bin` (~75MB)  
   - **Source**: https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q8_0.bin
   - **Management**: Automatically downloaded during build
   - **Purpose**: Default multilingual transcription model

#### Platform-Specific Dependencies

**macOS**
- **Frameworks**: ApplicationServices, AppKit, CoreFoundation, CoreAudio, AudioToolbox, AVFoundation, Accelerate, Foundation, ServiceManagement
- **GPU Acceleration**: Metal, MetalKit, MetalPerformanceShaders (optional)
- **Swift Compiler**: `/usr/bin/swiftc`
- **Tools**: `rsvg-convert` (for SVG icon generation), `iconutil`, ImageMagick

**Windows**
- **Libraries**: winmm, ole32, user32, shell32, gdi32
- **GPU Acceleration**: Vulkan SDK (optional, detected via `VULKAN_SDK` environment variable)
- **Build Environment**: Visual Studio 2022 with C++ build tools

**Linux**
- **Libraries**: Threads, dl, m
- **Audio**: ALSA (optional), PulseAudio (optional)

### Language and Compiler Requirements

- **C Standard**: C99
- **C++ Standard**: C++11  
- **Swift**: System Swift compiler (macOS only)
- **Minimum CMake Version**: 3.20

### Asset Generation Dependencies

**Icon Generation** (Optional but recommended)
- **SVG Processing**: `rsvg-convert` (from librsvg)
- **Image Processing**: ImageMagick (`magick` or `convert`)
- **macOS Icons**: `iconutil` (bundled with macOS)

## Platform-Specific Build Instructions

### macOS

#### Prerequisites
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install icon generation tools (optional)
brew install librsvg imagemagick
```

#### Build Process
```bash
# Clone and navigate to repository
git clone <repository-url> yakety
cd yakety

# Configure and build (Release)
cmake --preset release
cmake --build --preset release

# Or configure and build (Debug)
cmake --preset debug
cmake --build --preset debug
```

#### macOS-Specific Features
- **App Bundle**: Creates `Yakety.app` with proper Info.plist
- **Code Signing**: Automatic ad-hoc signing for local use
- **Asset Bundling**: Icons and models embedded in app bundle
- **Metal Acceleration**: GPU acceleration via Metal frameworks

### Windows (WSL Development)

#### Prerequisites
```bash
# In WSL, install build tools
sudo apt update
sudo apt install build-essential cmake ninja-build

# Set up SSH for remote development (optional)
./wsl/setup-wsl-ssh.sh
```

#### Remote Development Setup
For development from macOS via SSH:

1. **Start WSL SSH forwarding** (as Administrator):
   ```batch
   .\wsl\start-wsl-ssh.bat
   ```

2. **Sync and build from macOS**:
   ```bash
   # Sync source files (excludes build artifacts)
   rsync -av --exclude='build/' --exclude='build-debug/' --exclude='whisper.cpp/' \
     --exclude='website/' --exclude='.git/' --exclude='.vscode/' --exclude='.claude/' \
     . badlogic@192.168.1.21:/mnt/c/workspaces/yakety/

   # Build via SSH
   ssh badlogic@192.168.1.21 "cd /mnt/c/workspaces/yakety && \
     /mnt/c/Windows/System32/cmd.exe /c 'cd c:\\workspaces\\yakety && \
     c:\\workspaces\\winvs.bat && cmake --preset release'"
   
   ssh badlogic@192.168.1.21 "cd /mnt/c/workspaces/yakety && \
     /mnt/c/Windows/System32/cmd.exe /c 'cd c:\\workspaces\\yakety && \
     c:\\workspaces\\winvs.bat && cmake --build --preset release'"
   ```

#### Windows-Specific Features
- **Windows GUI App**: Creates `Yakety.exe` (GUI) and `yakety-cli.exe` (console)
- **Resource Files**: Windows icons and version information
- **Vulkan Acceleration**: Optional GPU acceleration via Vulkan SDK

### Linux

#### Prerequisites
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install build-essential cmake ninja-build \
  libasound2-dev libpulse-dev librsvg2-bin imagemagick

# Fedora/RHEL
sudo dnf install gcc gcc-c++ cmake ninja-build \
  alsa-lib-devel pulseaudio-libs-devel librsvg2-tools ImageMagick
```

#### Build Process
```bash
cmake --preset release
cmake --build --preset release
```

## Build Targets and Executables

### Primary Targets

1. **yakety-cli**
   - Console application for command-line usage
   - Platform: All (yakety-cli, yakety-cli.exe)

2. **yakety-app** 
   - GUI application with system tray functionality
   - Platform-specific names:
     - macOS: `Yakety.app` (app bundle)
     - Windows: `Yakety.exe` (GUI executable)
     - Linux: `yakety-app`

3. **recorder**
   - Standalone audio recording utility
   - Platform: All

4. **transcribe**
   - Standalone transcription utility  
   - Platform: All

### Test Programs (macOS only)

- **test-model-dialog**: Model selection dialog test
- **test-keycombination-dialog**: Hotkey capture dialog test  
- **test-download-dialog**: Download progress dialog test

### Distribution Targets

#### Package Creation
```bash
# Create all packages for current platform
cmake --build --preset release --target package

# Platform-specific packages
cmake --build --preset release --target package-cli-macos    # CLI tools
cmake --build --preset release --target package-app-macos    # App bundle DMG
cmake --build --preset release --target package-cli-windows  # CLI tools
cmake --build --preset release --target package-app-windows  # App installer
```

#### Upload to Server
```bash
# Upload all distribution packages
cmake --build --preset release --target upload
```

## Configuration Options

### Whisper.cpp Configuration

The build system automatically configures whisper.cpp with these options:
- `BUILD_SHARED_LIBS=OFF`: Static linking
- `WHISPER_BUILD_TESTS=OFF`: Skip tests
- `WHISPER_BUILD_EXAMPLES=OFF`: Skip examples  
- `WHISPER_BUILD_SERVER=OFF`: Skip server
- `GGML_METAL=ON`: Metal acceleration (macOS)
- `GGML_VULKAN=ON`: Vulkan acceleration (Windows, if SDK present)
- `GGML_NATIVE=ON`: Native CPU optimizations (Windows)

### Compiler Flags

**Debug Builds (Non-Windows)**:
- `-Wall -Wextra -Werror`: Strict warnings
- `-Wno-error=unused-parameter -Wno-error=unused-function`: Allow unused parameters
- `-g -O0 -fno-omit-frame-pointer`: Debug symbols and no optimization

**Windows Builds**:
- `/MD`: Use release runtime library (even in debug)
- `_ITERATOR_DEBUG_LEVEL=0`: Disable iterator debugging in debug builds

### Swift Compiler Configuration (macOS)

- **Debug**: `-Onone -g -disable-incremental-imports`
- **Release**: Standard optimizations with `-disable-incremental-imports`

## Build Process Details

### Automatic Dependency Resolution

1. **whisper.cpp**: Cloned from GitHub if not present
2. **Whisper Model**: Downloaded from HuggingFace if missing
3. **Icons**: Generated from SVG master if tools available
4. **Platform Libraries**: Discovered and linked automatically

### Asset Processing

- **Icon Generation**: SVG → PNG at multiple resolutions → .icns/.ico
- **Model Packaging**: Whisper models copied to output directories
- **Resource Bundling**: Assets embedded in platform-appropriate formats

### Cross-Platform Considerations

- **Path Handling**: Consistent forward slashes in CMake, platform-specific at runtime  
- **Library Naming**: Platform-specific extensions (.a, .lib, .so)
- **Executable Names**: Platform-appropriate extensions and bundle formats
- **Code Signing**: Automatic ad-hoc signing on macOS

## Troubleshooting

### Common Issues

**whisper.cpp Build Failures**:
- Ensure adequate disk space (>2GB for full build)
- Check internet connectivity for GitHub clone
- Verify compiler toolchain installation

**Icon Generation Failures**:
- Install `librsvg2-bin` and `imagemagick`
- Check SVG master file exists at `assets/yakety.svg`

**Swift Compilation Issues (macOS)**:
- Verify Xcode Command Line Tools installed
- Check Swift compiler path: `/usr/bin/swiftc`

**Windows Build Issues**:
- Ensure Visual Studio 2022 build tools installed
- Set up proper MSVC environment with `winvs.bat`
- Check Vulkan SDK installation if using GPU acceleration

### Build Verification

```bash
# Check build outputs
ls -la build/bin/

# Verify whisper.cpp integration
ldd build/bin/yakety-cli  # Linux
otool -L build/bin/yakety-cli  # macOS

# Test basic functionality
./build/bin/yakety-cli --help
```

## Development Workflow

### Recommended Development Cycle

1. **Edit Source**: Make changes to source files
2. **Generate Assets** (if needed): Icons will regenerate automatically
3. **Build**: `cmake --build --preset release`
4. **Test**: Run executables from `build/bin/`
5. **Package** (if releasing): `cmake --build --preset release --target package`

### Cross-Platform Development

For Windows development from macOS:
1. Edit locally on macOS for fast native tools
2. Use rsync to sync changes to Windows via SSH
3. Build remotely via SSH commands
4. Test Windows-specific functionality remotely

This build system provides a robust, cross-platform foundation that handles complex dependency management while maintaining developer productivity across different operating systems and development environments.