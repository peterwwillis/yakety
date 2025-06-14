# Development Guide

<!-- Generated: 2025-06-14 21:06:36 UTC -->

This document outlines the development conventions, environment setup, and workflows for the Yakety project.

## Overview

Yakety is a cross-platform voice-to-text application built with a **C-style C++** philosophy, emphasizing simplicity, readability, and platform abstraction. The architecture combines pure C for core logic, C++ for whisper.cpp integration, Objective-C for macOS platform layer, and SwiftUI for modern dialog interfaces.

### Core Principles

- **C-style C++**: Write C++ code with C-style conventions, minimize modern C++ features
- **Platform abstraction**: Clean separation between platform-specific and business logic
- **Singleton patterns**: System-level modules use singleton pattern for simplicity
- **Resource management**: Explicit cleanup with proper error handling
- **Thread safety**: Mutex protection for shared resources

## Code Style and Conventions

### File Extensions and Usage

- **`.c`** - Pure C files for core application logic (`main.c`, `preferences.c`, `models.c`)
- **`.cpp`** - Files needing C++ features, primarily whisper.cpp integration (`transcription.cpp`)
- **`.h`** - C/C++ header files with platform-independent interfaces
- **`.m`** - Objective-C files for macOS platform implementation (`src/mac/*.m`)
- **`.mm`** - Objective-C++ files (rare, only for mixing ObjC with C++)
- **`.swift`** - SwiftUI dialogs and modern macOS UI (`src/mac/dialogs/*.swift`)

### Naming Conventions

**Files and Directories:**
```
src/main.c              # Lowercase with underscores
src/model_definitions.h # Header files follow same pattern
src/tests/test_*.c      # Test files prefixed with test_
src/mac/                # Platform-specific subdirectories
src/windows/
```

**Functions and Variables:**
```c
// Module-prefixed functions (from src/preferences.c:280)
void preferences_set_string(const char *key, const char *value);
bool preferences_get_bool(const char *key, bool default_value);

// Boolean functions use is_/has_ prefix (from src/audio.h:36)
bool audio_recorder_is_recording(void);

// Initialization/cleanup pairs (from src/models.c:24)
int models_load(void);     // Returns 0 on success, -1 on failure
void models_cleanup(void);
```

**Constants and Macros:**
```c
// From src/main.c:25-26
#define PERMISSION_RETRY_DELAY_MS 500
#define MIN_RECORDING_DURATION 0.1

// From src/preferences.c:8-10
#define MAX_LINE_LENGTH 1024
#define MAX_KEY_LENGTH 128
```

### API Design Patterns

**Singleton Pattern:**
```c
// From src/preferences.c:23-24
static Preferences *g_preferences = NULL;
static utils_mutex_t *g_preferences_mutex = NULL;

// Thread-safe initialization
static void ensure_preferences_mutex(void) {
    if (g_preferences_mutex == NULL) {
        g_preferences_mutex = utils_mutex_create();
    }
}
```

**Error Handling:**
```c
// From src/models.c:24 - Single point of entry with fallback
int models_load(void) {
    // Try loading, handle failures, provide fallback
    if (result != 0) {
        overlay_show_error("Failed to load model, falling back to base model");
        // Remove corrupted file, try base model
        preferences_set_string("model", "");
        model_path = utils_get_model_path();
        result = transcription_init(model_path);
    }
    return result;
}
```

**Resource Management:**
```c
// From src/main.c:316-327 - Cleanup in proper order
static void cleanup_all(void) {
    keylogger_cleanup();
    if (!app_is_console()) {
        menu_cleanup();
    }
    audio_recorder_cleanup();
    transcription_cleanup();
    overlay_cleanup();
    app_cleanup();
    preferences_cleanup();
    log_cleanup();
}
```

## Common Patterns

### Platform Abstraction

**Entry Point Abstraction (src/app.h:6-43):**
```c
#ifdef _WIN32
#ifdef YAKETY_TRAY_APP
#define APP_ENTRY_POINT \
    int WINAPI WinMain(HINSTANCE hInstance, ...) { \
        return app_main(0, NULL, false); \
    }
#else
#define APP_ENTRY_POINT \
    int main(int argc, char **argv) { \
        return app_main(argc, argv, true); \
    }
#endif
#else
// macOS variants
#endif
```

**Platform-Specific Implementation (CMakeLists.txt:49-85):**
```cmake
if(APPLE)
    target_sources(platform PRIVATE
        src/mac/logging.m
        src/mac/clipboard.m
        src/mac/overlay.m
        # ... more macOS files
    )
elseif(WIN32)
    target_sources(platform PRIVATE
        src/windows/logging.c
        src/windows/clipboard.c
        # ... more Windows files
    )
endif()
```

### Memory Management

**String Handling:**
```c
// From src/preferences.c:67-81 - Safe string copying
strncpy(entry->value, value, MAX_VALUE_LENGTH - 1);
entry->value[MAX_VALUE_LENGTH - 1] = '\0';

// From src/mac/utils.m:142 - Platform string duplication
char *utils_strdup(const char *str);
```

**Buffer Management:**
```c
// From src/main.c:177-214 - Audio buffer lifecycle
float *samples = audio_recorder_get_samples(&sample_count);
if (samples && sample_count > 0) {
    char *text = transcription_process(samples, sample_count, 16000);
    if (text) {
        clipboard_copy(text);
        free(text);  // Caller responsible for freeing
    }
    free(samples);  // Always free the buffer
}
```

### Thread Safety

**Mutex Protection:**
```c
// From src/preferences.c:32-37, 104-110
static void ensure_preferences_mutex(void) {
    if (g_preferences_mutex == NULL) {
        g_preferences_mutex = utils_mutex_create();
    }
}

utils_mutex_lock(g_preferences_mutex);
// Critical section
utils_mutex_unlock(g_preferences_mutex);
```

**Atomic Operations:**
```c
// From src/utils.h:42-46
bool utils_atomic_read_bool(bool *ptr);
void utils_atomic_write_bool(bool *ptr, bool value);
int utils_atomic_read_int(int *ptr);
void utils_atomic_write_int(int *ptr, int value);
```

### Callback Patterns

**Event Callbacks:**
```c
// From src/keylogger.h:8, src/main.c:217-251
typedef void (*KeyCallback)(void *userdata);

static void on_key_press(void *userdata) {
    AppState *state = (AppState *) userdata;
    if (!state->recording) {
        state->recording = true;
        audio_recorder_start();
    }
}
```

**Async Work:**
```c
// From src/utils.h:18-29
typedef void *(*async_work_fn)(void *arg);
typedef void (*async_callback_fn)(void *result);

void utils_execute_async(async_work_fn work, void *arg, async_callback_fn callback);
```

### Error Handling

**Logging Integration:**
```c
// From src/mac/logging.m:67-80
static void log_to_file(const char *level, const char *format, va_list args) {
    pthread_mutex_lock(&g_log_mutex);
    // Write timestamp and level
    time_t now = time(NULL);
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", localtime(&now));
    fprintf(g_log_file, "[%s] %s: ", time_str, level);
    vfprintf(g_log_file, format, args);
    pthread_mutex_unlock(&g_log_mutex);
}
```

**Progressive Fallback:**
```c
// From src/models.c:44-89 - Model loading with fallback
if (result != 0) {
    // First failure - try fallback
    overlay_show_error("Failed to load model, falling back to base model");
    remove(failed_model);  // Remove corrupted file
    preferences_set_string("model", "");
    model_path = utils_get_model_path();
    result = transcription_init(model_path);
    
    if (result != 0) {
        // Final failure
        overlay_show_error("Model not found");
        return -1;
    }
}
```

## Build System

### CMake Structure

**Multi-target Build (CMakeLists.txt:114-196):**
```cmake
# CLI executable
add_executable(yakety-cli
    src/main.c
    ${BUSINESS_SOURCES}
)

# GUI/Tray app
if(APPLE)
    add_executable(yakety-app MACOSX_BUNDLE
        src/main.c
        ${BUSINESS_SOURCES}
    )
elseif(WIN32)
    add_executable(yakety-app WIN32
        src/main.c
        ${BUSINESS_SOURCES}
    )
endif()
```

**Platform Library (CMakeLists.txt:46-85):**
```cmake
add_library(platform STATIC)
if(APPLE)
    target_sources(platform PRIVATE
        src/mac/logging.m
        src/mac/clipboard.m
        # SwiftUI dialogs
        src/mac/dialogs/dialog_utils.swift
        src/mac/dialogs/hotkey_dialog.swift
    )
elseif(WIN32)
    target_sources(platform PRIVATE
        src/windows/logging.c
        src/windows/clipboard.c
    )
endif()
```

### Compiler Configuration

**Warning Flags (CMakeLists.txt:310-340):**
```cmake
set(WARNING_FLAGS
    -Wall
    -Wextra
    -Werror
    -Wno-error=unused-parameter
    -Wno-error=unused-function
)

# Apply to C/C++ only, not Swift
foreach(target yakety-cli yakety-app)
    target_compile_options(${target} PRIVATE 
        $<$<COMPILE_LANGUAGE:C>:${WARNING_FLAGS}>
        $<$<COMPILE_LANGUAGE:CXX>:${WARNING_FLAGS}>
    )
endforeach()
```

**Swift Configuration (CMakeLists.txt:90-103):**
```cmake
# Disable incremental compilation warnings
set(CMAKE_Swift_FLAGS_DEBUG "-Onone -g -disable-incremental-imports")
set(CMAKE_Swift_FLAGS_RELEASE "${CMAKE_Swift_FLAGS_RELEASE} -disable-incremental-imports")

# Generated header paths for Xcode
if(APPLE AND CMAKE_GENERATOR STREQUAL "Xcode")
    target_include_directories(platform PRIVATE 
        "$<$<CONFIG:Debug>:${CMAKE_BINARY_DIR}/platform.build/Debug/DerivedSources>"
    )
endif()
```

## Development Workflows

### Adding New Features

1. **Create interface in header file** (`src/feature.h`)
2. **Implement platform-specific code** (`src/mac/feature.m`, `src/windows/feature.c`)
3. **Add to CMakeLists.txt** platform library sources
4. **Update cleanup chain** in `cleanup_all()` function

### SwiftUI Dialog Integration

**Dialog State Protocol (src/mac/dialogs/dialog_utils.swift:8-13):**
```swift
protocol ModalDialogState: ObservableObject {
    associatedtype ResultType
    var isCompleted: Bool { get set }
    var result: ResultType { get }
    func reset()
}
```

**Modal Dialog Runner (src/mac/dialogs/dialog_utils.swift:17-67):**
```swift
func runModalDialog<T: View, StateType: ModalDialogState>(
    content: T,
    state: StateType,
    windowSize: NSSize = NSSize(width: 400, height: 200)
) -> StateType.ResultType {
    // Create window, run modal loop compatible with CFRunLoop
    while !state.isCompleted {
        if let event = NSApp.nextEvent(...) {
            NSApp.sendEvent(event)
        }
    }
    return state.result
}
```

### Testing

**Unit Tests (CMakeLists.txt:502-532):**
```cmake
if(APPLE)
    add_executable(test-model-dialog src/tests/test_model_dialog.c)
    target_link_libraries(test-model-dialog platform)
    target_link_libraries(test-model-dialog "-framework Cocoa")
endif()
```

**Test Pattern:**
```c
// From src/tests/test_model_dialog.c
#include "../dialog.h"
#include "../preferences.h"

int main() {
    preferences_init();
    
    // Test dialog functionality
    int result = dialog_model_selection();
    
    preferences_cleanup();
    return result;
}
```

## File Organization

### Source Tree Structure
```
src/
├── main.c              # Entry point, app lifecycle
├── app.h               # Platform-agnostic app interface
├── preferences.c       # Config management (cross-platform)
├── models.c            # Model loading (cross-platform)
├── audio.c             # Audio recording (cross-platform)
├── transcription.cpp   # Whisper integration (C++)
├── model_definitions.h # Model metadata (header-only)
├── mac/                # macOS platform layer
│   ├── app.m           # NSApplication integration
│   ├── utils.m         # macOS utilities
│   ├── logging.m       # File logging
│   └── dialogs/        # SwiftUI dialogs
│       ├── dialog_utils.swift
│       └── models_dialog.swift
├── windows/            # Windows platform layer
│   ├── app.c           # Windows app lifecycle
│   ├── utils.c         # Windows utilities
│   └── logging.c       # Windows logging
└── tests/              # Unit tests
    └── test_*.c        # Test executables
```

### Header Dependencies
```c
// Core headers (minimal dependencies)
#include "app.h"        // App lifecycle
#include "logging.h"    // Logging functions
#include "utils.h"      // Platform utilities

// Business logic headers
#include "preferences.h" // Config management
#include "models.h"      // Model loading
#include "audio.h"       // Audio recording
#include "transcription.h" // Whisper integration

// Platform-specific (only in platform layer)
#include "dialog.h"     // UI dialogs
#include "clipboard.h"  // Clipboard operations
#include "keylogger.h"  // Keyboard monitoring
```

### Build Output Structure
```
build/bin/
├── yakety-cli          # CLI executable
├── Yakety.app/         # macOS app bundle
├── models/             # Whisper model files
│   └── ggml-base-q8_0.bin
├── menubar.png         # Tray icon
├── recorder            # Audio recording tool
└── transcribe          # Audio transcription tool
```

## Common Issues and Solutions

### Memory Leaks
- **Always pair malloc/free** - Check `audio_recorder_get_samples()` usage
- **Objective-C autorelease** - Use `@autoreleasepool` in tight loops
- **SwiftUI retain cycles** - Use `@StateObject` properly in dialogs

### Thread Safety
- **Preferences access** - Always use mutex in `preferences_*` functions
- **Audio buffer** - Single-threaded access, no concurrent recording
- **Transcription context** - Protected by `ctx_mutex` in `transcription.cpp:18`

### Platform Compatibility
- **File paths** - Use `utils_get_config_dir()` and proper separators
- **String comparison** - Use `utils_stricmp()` for case-insensitive
- **Atomic operations** - Use `utils_atomic_*` functions for thread-safe variables

### Build Issues
- **Swift incremental compilation** - Disable with `-disable-incremental-imports`
- **Windows runtime library** - Use `/MD` to match whisper.cpp
- **Metal framework** - Link only on macOS with Metal support detection

### Resource Paths
- **Model location** - `utils_get_model_path()` handles all search locations
- **Bundle resources** - Use `NSBundle pathForResource` on macOS
- **Executable directory** - Check relative to executable for CLI tools

This guide provides the essential patterns and conventions for developing and maintaining Yakety. Focus on following the established patterns for consistency and maintainability.