# Testing and Code Quality Documentation

## Overview

This document provides an overview of the testing setup, code quality tools, and testing processes for the Yakety voice-to-text application.

## Testing Framework and Setup

### Test Framework
- **No formal testing framework**: The project uses custom C test files with simple assertions
- **Test approach**: Manual testing with dialog-based interaction tests
- **Testing style**: Integration tests that verify UI components and functionality

### Test Files Location
- **Main test directory**: `/src/tests/`
- **Test executables**: Built to `/build/bin/` or `/build-debug/bin/`

### Available Test Programs

#### 1. Dialog Tests (macOS only)
The project includes three main dialog test programs:

**Model Dialog Test** (`test-model-dialog`)
- **Source**: `src/tests/test_model_dialog.c`
- **Purpose**: Tests the models and language selection dialog
- **Features**: 
  - Tests SwiftUI dialog integration
  - Validates model selection functionality
  - Tests language preference handling

**Key Combination Dialog Test** (`test-keycombination-dialog`)
- **Source**: `src/tests/test_keycombination_dialog.c`
- **Purpose**: Tests hotkey capture functionality
- **Features**:
  - Tests key combination capture
  - Validates keylogger integration
  - Tests dialog interaction with system-level key events

**Download Dialog Test** (`test-download-dialog`)
- **Source**: `src/tests/test_download_dialog.c`
- **Purpose**: Tests model download functionality
- **Features**:
  - Tests HTTP download integration
  - Validates progress reporting
  - Tests file system operations

#### 2. Test Characteristics
- **Platform**: macOS only (uses Cocoa frameworks)
- **Dependencies**: Links against platform library and system frameworks
- **Execution**: Requires GUI environment and user interaction
- **Validation**: Manual verification of dialog behavior

## Test Organization

### Build Integration
Tests are integrated into the CMake build system:

```cmake
# Test programs (lines 502-532 in CMakeLists.txt)
if(APPLE)
    add_executable(test-model-dialog src/tests/test_model_dialog.c)
    target_link_libraries(test-model-dialog platform)
    target_link_libraries(test-model-dialog "-framework Cocoa")
    
    add_executable(test-keycombination-dialog src/tests/test_keycombination_dialog.c)
    target_link_libraries(test-keycombination-dialog platform)
    target_link_libraries(test-keycombination-dialog "-framework Cocoa" "-framework SwiftUI")
    
    add_executable(test-download-dialog src/tests/test_download_dialog.c)
    target_link_libraries(test-download-dialog platform)  
    target_link_libraries(test-download-dialog "-framework Cocoa" "-framework SwiftUI")
endif()
```

### Test Structure
Each test follows a similar pattern:
1. **Initialization**: Set up app environment and platform-specific requirements
2. **Dialog Invocation**: Call the specific dialog function to test
3. **Result Validation**: Check return values and side effects
4. **Cleanup**: Properly clean up resources and exit

## How to Run Tests

### Prerequisites
- **Platform**: macOS with Xcode Command Line Tools
- **Build**: Project must be built first
- **Permissions**: May require accessibility permissions for keylogger tests

### Build Tests
```bash
# Configure and build debug version (includes tests)
cmake --preset debug
cmake --build --preset debug

# Or build release version
cmake --preset release  
cmake --build --preset release
```

### Execute Tests
```bash
# Run individual test programs
./build/bin/test-model-dialog
./build/bin/test-keycombination-dialog
./build/bin/test-download-dialog

# Or from debug build
./build-debug/bin/test-model-dialog
./build-debug/bin/test-keycombination-dialog
./build-debug/bin/test-download-dialog
```

### Test Execution Notes
- Tests require user interaction with GUI dialogs
- Results are validated through console output and manual verification
- Some tests may require specific system permissions (microphone, accessibility)
- Tests should be run in a GUI environment (not headless)

## Code Quality Tools and Processes

### Code Formatting

#### Clang-Format Configuration
- **Configuration file**: `.clang-format`
- **Base style**: LLVM with customizations
- **Settings**:
  - Indent width: 4 spaces
  - Column limit: 120 characters
  - No tabs (spaces only)
  - Attach braces style
  - Space after C-style casts

#### Format Rules
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
AlignConsecutiveDeclarations: false
AlignConsecutiveAssignments: false
```

### Compiler Warnings and Flags

#### Development Flags (Non-Windows)
```cmake
# Warning flags applied to C/C++ targets
-Wall
-Wextra
-Werror
-Wno-error=unused-parameter
-Wno-error=unused-function
```

#### Debug-Specific Flags
```cmake
# Debug configuration
-g
-O0
-fno-omit-frame-pointer
# Note: Sanitizers disabled due to Swift compatibility issues
```

### Code Quality Standards

#### C-Style C++ Approach
- **Philosophy**: Use C++ but with C-style conventions
- **File extensions**: `.cpp` for C++ features needed by whisper.cpp, `.c` for pure C
- **Naming**: C-style function and variable naming
- **Memory management**: Prefer manual memory management over RAII

#### Platform-Specific Code
- **macOS**: Objective-C (.m) and Swift (.swift) for platform integration
- **Windows**: Pure C implementation for platform features
- **Cross-platform**: Core logic in C for maximum portability

### Website Quality Tools

#### Frontend Development
- **TypeScript**: Type checking with `tsc --noEmit`
- **Prettier**: Code formatting with `prettier --write .`
- **ESBuild**: Build system with type checking
- **Tailwind CSS**: Utility-first CSS framework

#### Website Scripts
```json
{
  "typecheck": "tsc --noEmit",
  "format": "prettier --write .",
  "build": "npm run clean && npm run build:css && node esbuild.mjs"
}
```

## CI/CD Configuration

### Current State
- **No CI/CD pipeline**: The project lacks automated continuous integration
- **Manual testing**: All testing is currently manual
- **No automated quality checks**: No automated linting, testing, or formatting validation

### Build Configuration
- **CMake presets**: Multiple build configurations (release, debug, vs-debug)
- **Cross-platform**: Support for macOS and Windows builds
- **Package targets**: Automated packaging for distribution

### Future Recommendations
1. **GitHub Actions**: Set up automated builds and tests
2. **Automated formatting**: Enforce clang-format on pull requests
3. **Static analysis**: Add tools like cppcheck or clang-static-analyzer
4. **Unit testing**: Add proper unit testing framework (e.g., Unity, Catch2)

## Testing Strategies and Gaps

### Current Testing Coverage
- **UI Integration**: Dialog functionality testing
- **Manual testing**: User interaction validation
- **Platform integration**: macOS-specific features tested

### Testing Gaps
1. **Unit tests**: No isolated unit tests for core functionality
2. **Cross-platform**: No Windows-specific tests
3. **Automated testing**: No CI/CD pipeline for automated testing
4. **Audio processing**: No tests for transcription functionality
5. **Performance testing**: No benchmarks or performance validation
6. **Error handling**: Limited error condition testing

### Recommended Improvements
1. **Add unit testing framework**: Implement Catch2 or similar for C++
2. **Automated test execution**: Set up CI/CD pipeline
3. **Cross-platform testing**: Add Windows test implementations
4. **Audio pipeline testing**: Add tests for whisper.cpp integration
5. **Mock dependencies**: Add mocking for external dependencies
6. **Performance benchmarks**: Add performance regression testing

## Dependencies and Integration

### External Dependencies
- **whisper.cpp**: AI model integration (has its own test suite)
- **Platform frameworks**: Cocoa, SwiftUI for macOS
- **CMake**: Build system with preset configurations

### Integration Testing
- **whisper.cpp tests**: Located in `whisper.cpp/tests/` directory
- **Language model testing**: Available through whisper.cpp test suite
- **Audio processing**: Tested through whisper.cpp integration

### Test Data
- **Models**: Uses test models from whisper.cpp (`for-tests-*.bin`)
- **Audio samples**: Uses sample audio files for integration testing
- **Mock data**: Minimal mock data for dialog testing

## Summary

The Yakety project currently employs a manual testing approach focused on GUI integration testing. While it includes code formatting standards and compiler warnings, it lacks automated testing infrastructure and comprehensive unit tests. The testing strategy is primarily focused on validating user-facing functionality through interactive dialog tests on macOS.

Key areas for improvement include adding automated testing, cross-platform test coverage, and implementing a proper CI/CD pipeline for continuous quality assurance.