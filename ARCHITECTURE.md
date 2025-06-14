# Yakety Architecture

Technical architecture documentation for the cross-platform voice-to-text application.

## Overview

Yakety is a sophisticated voice-to-text application using a **C-style C++** architecture with platform-specific native integrations. The system combines AI transcription (Whisper), real-time audio processing, and system-level integration to provide seamless voice input across applications.

## Architectural Principles

### Design Philosophy
- **C-style C++**: Core logic in C, C++ only for whisper.cpp integration
- **Platform-native UI**: SwiftUI (macOS), Win32 (Windows) for native look and feel
- **Minimal dependencies**: Prefer platform APIs over third-party libraries
- **Modular design**: Clear separation between business logic and platform code

### Language Strategy
- **Core Logic**: C99 for simplicity, performance, and cross-platform compatibility
- **macOS**: Objective-C for system integration, SwiftUI for modern dialogs
- **Windows**: Pure Win32 C for lightweight native integration
- **AI Integration**: C++ wrapper maintaining C-style interface

## Directory Structure

```
src/
├── *.{c,h}                # Cross-platform business logic
├── transcription.cpp      # C++ integration with whisper.cpp
├── mac/                   # macOS platform layer
│   ├── *.m               # Objective-C implementations
│   ├── dialogs/*.swift   # SwiftUI dialog implementations
│   └── Info.plist        # App bundle configuration
├── windows/              # Windows platform layer
│   ├── *.c               # Win32 API implementations
│   └── yakety.rc         # Windows resources
└── tests/                # Component test programs
```

## Component Architecture

### 1. Application Layer
- **Entry Point**: `main.c` - Unified CLI/GUI application logic
- **App Framework**: `app.h` - Platform-agnostic lifecycle management
- **Build System**: Multi-target CMake with platform-specific linking

### 2. Core Business Logic (Platform-Agnostic)

#### Audio Processing (`audio.{c,h}`)
- **Responsibility**: Real-time audio capture using miniaudio
- **Features**: 16kHz mono recording optimized for Whisper, buffer management
- **Threading**: Background audio processing with callback mechanisms

#### Transcription Engine (`transcription.{cpp,h}`)
- **Responsibility**: Whisper.cpp integration for speech-to-text
- **Design**: C++ implementation with C-style interface
- **Features**: Model loading, GPU acceleration, text cleanup, language support

#### Model Management (`models.{c,h}`)
- **Responsibility**: Whisper model discovery, loading, and management
- **Strategy**: Bundled model → custom models → downloadable models → fallback
- **API**: Single `models_load()` function handles all scenarios

#### Keyboard Monitoring (`keylogger.h`)
- **Responsibility**: Global hotkey detection across platforms
- **Features**: Customizable key combinations, permission handling
- **Implementation**: Platform-specific (Accessibility API on macOS, hooks on Windows)

#### System Integration
- **Menu System** (`menu.{c,h}`): System tray/menu bar integration
- **Configuration** (`preferences.{c,h}`): Cross-platform settings persistence
- **Clipboard** (`clipboard.h`): Automated text insertion

### 3. Platform Abstraction Layer

#### macOS Implementation (`src/mac/`)
```
mac/
├── app.m                 # NSApplication lifecycle
├── dialog.m              # SwiftUI dialog coordination
├── dialogs/              # SwiftUI dialog components
│   ├── SwiftUIModelsDialog.swift
│   └── swiftui_bridge.{h,mm}
├── keylogger.c           # Accessibility API integration
├── menu.m                # NSStatusBar implementation
└── *.m                   # Other platform implementations
```

#### Windows Implementation (`src/windows/`)
```
windows/
├── app.c                 # Windows message loop
├── dialog.c              # Win32 dialog implementations
├── keylogger.c           # Low-level keyboard hooks
├── menu.c                # System tray implementation
└── yakety.rc             # Resource definitions
```

### 4. User Interface Architecture

#### Dialog System
```
dialog.h (Common Interface)
├── mac/dialog.m (SwiftUI Coordinator)
│   └── dialogs/*.swift (SwiftUI Components)
└── windows/dialog.c (Win32 Implementation)
```

**Dialog Types**:
- Model selection and download with progress
- Hotkey configuration with live capture
- Permission requests and error handling

#### System Integration
- **Overlay System**: Real-time status during recording/processing
- **Background Operation**: System tray with minimal UI footprint
- **Native Integration**: Platform-appropriate permissions and accessibility

## Runtime Flow

### Application Startup
1. **Platform Detection** → App framework initialization
2. **Preference Loading** → Configuration validation and migration
3. **Model Loading** → Bundled → custom → downloadable → dialog
4. **System Integration** → Menu, keyboard monitor, permissions
5. **Background Operation** → Event loop with hotkey monitoring

### Voice Input Workflow
1. **Hotkey Detection** (Platform keylogger) → Audio recording start
2. **Audio Capture** (miniaudio) → 16kHz mono buffer collection
3. **Transcription** (whisper.cpp) → AI processing with GPU acceleration
4. **Text Processing** → Cleanup, formatting, language detection
5. **System Integration** → Clipboard paste to active application

### Threading Model
- **Main Thread**: UI operations, event handling, system integration
- **Audio Thread**: Real-time audio capture and buffer management
- **Transcription Thread**: Background AI processing
- **Thread Safety**: Mutex synchronization, atomic state management

## Build System Architecture

### CMake Configuration
- **Multi-preset**: release, debug, vs-debug configurations
- **External Projects**: Automatic whisper.cpp clone and build
- **Asset Pipeline**: SVG → multi-resolution PNG/ICO/ICNS conversion
- **Platform Libraries**: Static linking with conditional GPU acceleration

### Build Targets
```
Primary Executables:
├── yakety-cli            # Command-line interface
├── yakety-app            # GUI application (platform-specific name)
├── recorder              # Standalone audio utility
└── transcribe            # Batch transcription tool

Distribution Packages:
├── package-cli-<platform>   # CLI tools bundle
├── package-app-<platform>   # GUI application installer
└── upload                   # Automated distribution
```

### Dependency Management
- **whisper.cpp**: Auto-cloned, configured, and built
- **AI Models**: Auto-downloaded during build (~110MB)
- **Platform Dependencies**: Framework discovery and linking
- **Asset Generation**: Automated icon and resource processing

## Advanced Features

### GPU Acceleration
- **macOS**: Metal acceleration with CoreML fallback
- **Windows**: Vulkan acceleration with CPU fallback
- **Configuration**: Automatic detection, runtime switching

### Cross-Platform Development
- **Remote Development**: WSL-based Windows development from macOS
- **File Synchronization**: rsync-based source sync
- **Build Automation**: SSH-based remote build execution

### Model Architecture
- **Bundled Model**: Base multilingual model for immediate functionality
- **Custom Models**: User-provided model support with validation
- **Download System**: On-demand model acquisition with progress
- **Graceful Fallbacks**: Progressive fallback chain with user dialogs

## Security Considerations

### Permissions and Access
- **macOS**: Microphone + accessibility permissions required
- **Windows**: Administrator privileges for global hotkeys
- **Code Signing**: Ad-hoc (development), proper certificates needed (distribution)

### Data Handling
- **Audio**: Never stored, processed in memory only
- **Configuration**: Local file storage with secure defaults
- **Network**: Model downloads only, no telemetry or data transmission

## Testing Strategy

### Current Approach
- **Manual Testing**: Dialog functionality and cross-platform verification
- **Component Tests**: Individual UI component validation (macOS only)
- **Integration Tests**: End-to-end workflow testing

### Test Programs
```bash
test-model-dialog              # Model selection UI
test-keycombination-dialog     # Hotkey capture functionality  
test-download-dialog           # Model download with progress
```

## Distribution Architecture

### Package Structure
**macOS**: App bundles with embedded resources and frameworks  
**Windows**: Portable executables with dependency bundling  
**Both**: Self-contained distributions including AI models

### Code Signing and Security
- **macOS**: Ad-hoc signing, quarantine removal, bundle notarization ready
- **Windows**: Resource files with version info, code signing TODO

## Future Architecture Considerations

### Scalability
- **Multi-model Support**: Runtime model switching
- **Plugin Architecture**: Custom transcription backends
- **Cloud Integration**: Optional cloud-based transcription

### Performance
- **Model Optimization**: Quantized models, streaming transcription
- **Memory Management**: Buffer optimization, model caching
- **GPU Utilization**: Advanced Metal/Vulkan compute pipeline

### Platform Expansion
- **Linux Support**: X11/Wayland integration
- **Mobile**: iOS/Android voice input extensions
- **Cloud**: Server-side transcription service

This architecture provides a robust foundation for cross-platform voice input while maintaining performance, security, and native platform integration.