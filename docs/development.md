# Development Guide

This document outlines the development conventions, environment setup, and workflows for the Yakety project.

## Code Style and Conventions

### C-Style C++ Philosophy

Yakety follows a **C-style C++** approach as specified in CLAUDE.md:

- Write C++ code but with C-style conventions
- Prefer C-style casts, function declarations, and naming conventions  
- Use C++ features (std::vector, extern "C") only when required for whisper.cpp integration
- Keep the core application logic in C-style for simplicity and readability

### File Extensions and Usage

- `.c` - Pure C files for core application logic
- `.cpp` - Files that need C++ features (primarily for whisper.cpp integration)
- `.h` - C/C++ header files
- `.m` - Objective-C files (macOS platform layer)
- `.mm` - Objective-C++ files (rare, only when mixing ObjC with C++)
- `.swift` - SwiftUI dialogs and modern macOS UI components

### Naming Conventions

**Files and Directories:**
- Use lowercase with underscores: `audio.c`, `model_definitions.h`
- Test files: `test_*.c` (e.g., `test_model_dialog.c`)
- Platform-specific files in subdirectories: `src/mac/`, `src/windows/`

**Functions and Variables:**
- Use snake_case: `audio_recorder_init()`, `preferences_get_string()`
- Prefix functions with module name: `audio_*`, `preferences_*`, `models_*`
- Boolean functions use `is_` or `has_` prefix: `audio_recorder_is_recording()`

**API Design:**
- Singleton pattern for system-level modules (audio, preferences, models)
- Single point of entry functions: `models_load()` handles everything
- Clear error handling with return codes (0 = success, -1 = failure for operations)

### Code Formatting

Automated formatting is configured via `.clang-format`:

```yaml
BasedOnStyle: LLVM
IndentWidth: 4
UseTab: Never
ColumnLimit: 120
AllowShortIfStatementsOnASingleLine: false
AllowShortLoopsOnASingleLine: false
AllowShortFunctionsOnASingleLine: Empty
BreakBeforeBraces: Attach
SpaceAfterCStyleCast: true
```

**Key Points:**
- 4-space indentation, no tabs
- 120 character line limit
- Spaces after C-style casts
- Braces on same line (Attach style)
- Format on save enabled in VS Code

### Header Guards and Includes

**Header Guards:**
```c
#ifndef AUDIO_H
#define AUDIO_H
// content
#endif // AUDIO_H
```

**Include Order:**
1. System headers (`<stdio.h>`, `<stdlib.h>`)
2. Third-party headers (`whisper.h`)
3. Project headers (`"audio.h"`, `"logging.h"`)

**C++ Integration:**
```cpp
extern "C" {
#include "transcription.h"
#include "logging.h"
}
#include <vector>
#include "whisper.h"
```

## Development Environment Setup

### Build System

**CMake Presets:**
- `cmake --preset release` - Release build with Ninja (default development)
- `cmake --preset debug` - Debug build with Ninja  
- `cmake --preset vs-debug` - Visual Studio build (Windows debugging only)

**Key Features:**
- C99 standard for C code
- C++11 standard for C++ code
- Export compile commands for IntelliSense
- Platform-specific architecture targeting (ARM64 for Apple Silicon)

### Platform-Specific Setup

**macOS:**
- Minimum deployment target: macOS 14.0
- Architecture: ARM64 only (Apple Silicon)
- Frameworks: Cocoa, SwiftUI, AVFoundation, Metal
- Swift compiler: `/usr/bin/swiftc`

**Windows:**
- WSL2 support for cross-platform development
- Visual Studio 2022 toolchain
- Vulkan acceleration support

### Dependencies

**Core Dependencies:**
- whisper.cpp (AI transcription)
- miniaudio (audio recording)
- ggml (machine learning backend)

**Platform Libraries:**
- macOS: System frameworks (dynamically linked)
- Windows: Static linking preferred for distribution

### IDE Configuration

**VS Code Settings (`.vscode/settings.json`):**
```json
{
    "cmake.debugConfig": {
        "MIMode": "lldb"
    },
    "editor.formatOnSave": true
}
```

**Key Features:**
- LLDB debugger for macOS
- Automatic code formatting on save
- CMake integration

## Git Workflow

### Branch Structure

**Simple Git Flow:**
- `main` - Primary development branch
- Feature branches: Short-lived, merged back to main
- Direct commits to main for small fixes

**Recent Commit Examples:**
```
Replace Objective-C dialogs with SwiftUI implementations
Fix critical segmentation fault in download dialog and unify model loading
Implement proper mutex-based thread safety for transcription model
```

### Commit Message Style

**Format:**
- Use present tense, imperative mood
- Start with action verb (Fix, Add, Replace, Implement)
- Be specific about what changed
- Reference the component/area affected

**Good Examples:**
- "Fix critical segmentation fault in download dialog"
- "Implement proper mutex-based thread safety for transcription model"
- "Replace Objective-C dialogs with SwiftUI implementations"

### Cross-Platform Development

**Remote Development Workflow:**
- Edit code on macOS (fast, native tools)
- Sync to Windows via rsync
- Build and test on Windows via SSH
- Documented in `wsl/REMOTE_DEVELOPMENT.md`

**Sync Command:**
```bash
rsync -av --exclude='build/' --exclude='build-debug/' --exclude='whisper.cpp/' --exclude='website/' --exclude='.git/' --exclude='.vscode/' --exclude='.claude/' . badlogic@192.168.1.21:/mnt/c/workspaces/yakety/
```

## File Organization Principles  

### Source Directory Structure

```
src/
├── *.c, *.h          # Cross-platform business logic
├── transcription.cpp  # C++ integration with whisper.cpp
├── mac/              # macOS platform layer
│   ├── *.m           # Objective-C implementations
│   ├── *.swift       # SwiftUI dialogs
│   └── Info.plist    # App bundle configuration
├── windows/          # Windows platform layer
│   ├── *.c           # Win32 API implementations
│   └── yakety.rc     # Windows resources
└── tests/            # Test programs
    └── test_*.c      # Individual component tests
```

### Build Output Organization

```
build/
└── bin/              # All executables and resources
    ├── yakety-cli    # Command-line version
    ├── yakety-app    # GUI application
    ├── models/       # AI models
    └── *.png         # UI resources
```

### Key Architectural Principles

**Platform Abstraction:**
- Platform-specific code isolated in `src/mac/` and `src/windows/`
- Common business logic in root `src/` directory
- Platform library provides unified API

**Module Boundaries:**
- Each subsystem has dedicated .c/.h file pair
- Clear, minimal public APIs
- Singleton pattern for system resources

**Resource Management:**
- Models and assets embedded in app bundles
- Development builds copy resources to output directory
- Distribution packages include all dependencies

## Build Targets and Packaging

### Available Targets

**Core Executables:**
- `yakety-cli` - Command-line interface
- `yakety-app` - GUI application (tray app)
- `recorder` - Audio recording utility  
- `transcribe` - Batch transcription tool

**Test Programs:**
- `test-model-dialog` (macOS)
- `test-keycombination-dialog` (macOS)
- `test-download-dialog` (macOS)

**Distribution Packages:**
- `package-cli-macos` - CLI tools bundle
- `package-app-macos` - macOS DMG with app bundle
- `package-cli-windows` - Windows CLI tools
- `package-app-windows` - Windows application bundle

### Development Commands

**Basic Build:**
```bash
cmake --preset release
cmake --build --preset release
```

**Clean Rebuild:**
```bash
rm -rf build/
cmake --preset release
cmake --build --preset release
```

**Package for Distribution:**
```bash
cmake --build --preset release --target package
```

## Testing and Quality Assurance

### Testing Strategy

**Manual Testing:**
- Individual component tests for dialogs and UI
- Cross-platform functionality verification
- Performance testing with different audio inputs

**Important Note from CLAUDE.md:**
> YOU, CLAUDE, CAN NOT TEST THE PROGRAMS, ASK THE USER TO TEST AND REPORT RESULTS

### Quality Tools

**Static Analysis:**
- clang-format for consistent code formatting
- Compiler warnings as errors (`-Werror`)
- Platform-specific warning flags

**Debug Configuration:**
- Debug symbols enabled
- Frame pointers preserved
- Address/undefined sanitizers available (disabled due to Swift compatibility)

### Code Review Practices

**Pre-commit Checklist:**
- Code compiles on target platforms
- Follows naming and style conventions
- Public APIs are documented
- Error handling is comprehensive
- No memory leaks in C code

## Important Development Reminders

From CLAUDE.md project instructions:

1. **Always use `rg` (ripgrep) instead of `grep`** for searching
2. **Cannot test programs** - always ask users to test and report results
3. **C-style C++** - maintain C-style conventions even in C++ files
4. **Cross-platform build presets** - use appropriate preset for target platform
5. **WSL development workflow** - follow documented sync and build procedures

This development guide should be updated as the project evolves and new conventions are established.