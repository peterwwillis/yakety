# Deployment and Distribution Analysis

## Overview

Yakety is a cross-platform voice-to-text application that supports macOS and Windows. The application is distributed as native binaries with different packaging approaches for each platform.

## Packaging and Distribution Approach

### Build System
- **Build Tool**: CMake 3.20+ with platform-specific presets
- **Generators**: 
  - Ninja (primary, fast builds)
  - Visual Studio 2022 (Windows debugging)
- **Build Configurations**: Release and Debug presets
- **Multi-platform**: Single CMakeLists.txt with platform-specific logic

### Distribution Formats

#### macOS
- **App Bundle**: `Yakety.app` (GUI application)
- **CLI Distribution**: `yakety-cli-macos.zip` containing:
  - `yakety-cli` executable
  - `recorder` utility
  - `transcribe` utility
  - `models/` directory with AI models
  - `menubar.png` icon
- **App Distribution**: `Yakety-macos.dmg` and `Yakety-macos.zip`
  - DMG with Applications symlink for drag-and-drop installation
  - Automatic code signing with ad-hoc signatures
  - Bundle includes all resources (icons, models, frameworks)

#### Windows
- **GUI Application**: `Yakety.exe` (WIN32 application, no console)
- **CLI Distribution**: `yakety-cli-windows.zip` containing:
  - `yakety-cli.exe`
  - `recorder.exe`
  - `transcribe.exe`
  - `models/` directory
  - `menubar.png`
- **App Distribution**: `Yakety-windows.zip`
  - Portable ZIP archive with all necessary files
  - Self-contained directory structure

### Build Artifacts Structure
```
build/bin/
├── yakety-cli(.exe)          # Command line interface
├── Yakety(.app/.exe)         # GUI application
├── recorder(.exe)            # Audio recording utility
├── transcribe(.exe)          # Transcription utility
├── models/
│   └── ggml-base-q8_0.bin   # Whisper AI model (~110MB)
└── menubar.png              # Tray icon
```

## Installation Requirements

### Development Prerequisites

#### macOS
- **OS**: macOS 14.0+ (Sonoma or later)
- **Deployment Target**: macOS 14.0+ (Sonoma)
- **Architecture**: ARM64 (Apple Silicon) only
- **Tools**: Xcode Command Line Tools, CMake 3.20+, Ninja
- **Package Managers**: Homebrew recommended
- **Swift**: System Swift compiler (`/usr/bin/swiftc`)

#### Windows
- **OS**: Windows 10+
- **Tools**: 
  - Visual Studio 2019+ with C++ development tools
  - CMake 3.20+
  - Ninja (optional but recommended)
- **Optional**: Vulkan SDK for GPU acceleration
- **WSL**: Supported for remote development scenarios

#### Cross-Platform
- **CMake**: Version 3.20 or higher
- **Git**: For cloning whisper.cpp dependency
- **Internet**: Required for downloading AI models during build

### Runtime Dependencies

#### macOS Frameworks
- **Core**: ApplicationServices, AppKit, CoreFoundation, Foundation
- **Audio**: CoreAudio, AudioToolbox, AVFoundation
- **System**: ServiceManagement
- **Performance**: Accelerate
- **GPU**: Metal, MetalKit, MetalPerformanceShaders (optional)

#### Windows Libraries
- **System**: winmm, ole32, user32, shell32, gdi32
- **GPU**: Vulkan SDK (optional, for GPU acceleration)

#### Embedded Dependencies
- **Whisper.cpp**: Automatically built from source
- **AI Model**: `ggml-base-q8_0.bin` (~110MB) downloaded during build
- **GGML Libraries**: Multiple architecture-specific libraries

## Platform-Specific Deployment Considerations

### macOS Deployment

#### Code Signing
- **Default**: Ad-hoc signatures for local development
- **Script**: `sign-app.sh` for manual signing
- **Automatic**: Post-build signing integrated in CMake
- **Quarantine**: Automatically removed via `xattr -cr`

#### Bundle Structure
- **Info.plist**: Complete bundle metadata
- **Bundle ID**: `com.yakety.app`
- **Resources**: Icons, models, and frameworks embedded
- **Launch**: LSUIElement=true (no dock icon, menu bar only)
- **Permissions**: NSMicrophoneUsageDescription for mic access

#### Distribution
- **DMG Creation**: Uses `hdiutil` with Applications symlink
- **Compression**: DMG + ZIP for additional compression
- **Installation**: Drag-and-drop to Applications folder

### Windows Deployment

#### Executable Configuration
- **Resource Files**: `yakety.rc` with icon and version info
- **Subsystem**: WIN32 for GUI (no console window)
- **Runtime**: Uses Release runtime library even for Debug builds
- **Vulkan**: Optional GPU acceleration if SDK available

#### Distribution
- **Portable**: No installer required, self-contained ZIP
- **Structure**: Flat directory with all dependencies
- **Execution**: Can run from any location
- **Elevation**: May require administrator privileges for global hotkeys

### Cross-Platform Features

#### Asset Generation
- **Icons**: Automatic generation from SVG master
- **Formats**: PNG, ICNS (macOS), ICO (Windows)
- **Tools**: rsvg-convert, ImageMagick, iconutil
- **Sizes**: Multiple resolutions including Retina support

#### Model Management
- **Download**: Automatic during build process
- **Storage**: Embedded in app bundle (macOS) or alongside executable (Windows)
- **Model**: Whisper base-q8_0 (multilingual, quantized)
- **Fallback**: Build fails if model unavailable

## Automated Distribution

### Build Commands
```bash
# Configure
cmake --preset release

# Build
cmake --build --preset release

# Package (platform-specific)
cmake --build --preset release --target package

# Upload to server
cmake --build --preset release --target upload
```

### Package Targets
- `package-cli-<platform>`: CLI tools distribution
- `package-app-<platform>`: GUI application distribution
- `package-<platform>`: Combined package creation
- `package`: Universal target (detects platform)
- `upload`: Automatic upload to distribution server

### Remote Development Support

#### WSL Integration
- **SSH Setup**: Automated WSL SSH configuration
- **Port Forwarding**: Windows to WSL networking
- **Build Pipeline**: Remote build execution from macOS
- **File Sync**: rsync-based source synchronization

#### Development Workflow
1. **Local Development**: Edit on macOS with Claude Code
2. **Sync Changes**: rsync to Windows WSL environment
3. **Remote Build**: SSH execution of Windows build
4. **Testing**: Remote execution and log analysis
5. **Distribution**: Platform-specific packaging

## Security Considerations

### Code Signing
- **macOS**: Ad-hoc signing for development, requires proper certificates for distribution
- **Windows**: No code signing implemented (potential security warnings)
- **Recommendation**: Implement proper code signing for public distribution

### Permissions
- **macOS**: Requires microphone and accessibility permissions
- **Windows**: May require administrator privileges
- **Network**: SSH-based remote development requires secure key management

### Distribution Security
- **Upload**: Uses SSH/SCP for secure file transfer
- **Server**: Files uploaded to `badlogic@slayer.marioslab.io`
- **Access**: Requires SSH key authentication

## Deployment Challenges and Solutions

### Model Distribution
- **Challenge**: 110MB AI model increases distribution size
- **Solution**: Automatic download during build, embedded in final package
- **Alternative**: Could implement on-demand download for users

### Cross-Platform Compatibility
- **Challenge**: Different system requirements and APIs
- **Solution**: Platform-specific CMake logic and conditional compilation
- **Testing**: Remote development setup enables cross-platform validation

### Dependency Management
- **Challenge**: Complex whisper.cpp build requirements
- **Solution**: Automated external project build with platform detection
- **Optimization**: Caching of built libraries to avoid rebuilds

## Future Distribution Considerations

### Recommended Improvements
1. **Code Signing**: Implement proper certificates for both platforms
2. **Installers**: Consider MSI (Windows) and PKG (macOS) installers
3. **Auto-Updates**: Implement update mechanism for deployed applications
4. **Model Optimization**: Consider smaller models or on-demand download
5. **CI/CD**: Automated building and distribution pipeline
6. **Notarization**: macOS notarization for Gatekeeper compatibility

### Scalability
- **Build Farm**: Current remote development could scale to CI/CD
- **Multiple Architectures**: Could support Intel macOS, ARM Windows
- **Distribution Network**: CDN for faster model downloads
- **Package Managers**: Homebrew (macOS), Chocolatey (Windows) support