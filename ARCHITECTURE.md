# Yakety Architecture

## Overview

Yakety uses a clean modular architecture that separates platform-specific code from business logic. The architecture consists of:

1. **Module Headers** (`src/*.h`) - Define platform-agnostic interfaces
2. **Platform Implementations** (`src/mac/*.m`, `src/windows/*.c`) - Platform-specific implementations
3. **Business Logic** (`src/audio.c`, `src/transcription.cpp`) - Platform-agnostic application code
4. **Unified Main** (`src/main.c`) - Single entry point for both CLI and tray apps

## Modules

### Core Platform Modules

- **`logging`** - Console/GUI logging abstraction
- **`clipboard`** - Copy and paste operations
- **`overlay`** - On-screen text overlay
- **`dialog`** - Message boxes and alerts
- **`menu`** - System tray/menubar management (singleton pattern)
- **`keylogger`** - Keyboard event monitoring (singleton pattern)
- **`app`** - Application lifecycle management with atomic state
- **`utils`** - Platform utilities (time, sleep, paths, atomic operations)

### Business Logic Modules

- **`audio`** - Audio recording using miniaudio
- **`transcription`** - Speech-to-text using Whisper

## Build System

The CMake build system creates:

1. **`platform`** - Static library containing all platform implementations
2. **`yakety-cli`** - CLI executable (links to platform library)
3. **`yakety-app`** - GUI/tray executable (links to platform library, defines YAKETY_TRAY_APP)

## Key Design Principles

1. **No Platform Code in Business Logic** - All platform operations go through module interfaces
2. **Single Source Truth** - One `main.c` for both app types using `APP_ENTRY_POINT` macro
3. **Clean Interfaces** - Well-defined module APIs with no platform leakage
4. **Singleton Patterns** - Global state managed through clean singleton APIs (menu, keylogger)
5. **Thread Safety** - Atomic operations for cross-thread state management
6. **Robust Error Handling** - Proper error propagation and cleanup on failure
7. **Platform-Agnostic Entry Points** - `APP_ENTRY_POINT` handles all platform variations automatically

## Adding New Platforms

To add a new platform (e.g., Linux):

1. Create `src/linux/` directory
2. Implement all module interfaces for the platform
3. Update CMakeLists.txt to include the new platform sources
4. No changes needed to business logic or main.c

## Entry Point Architecture

The `APP_ENTRY_POINT` macro in `app.h` provides a clean abstraction for platform-specific entry points:

```c
// In main.c - simple, clean entry point
int app_main(int argc, char** argv, bool is_console) {
    // Main application logic here
}

APP_ENTRY_POINT  // Expands to platform-specific main/WinMain
```

**Platform Expansions:**
- **Windows Tray**: `WinMain()` → `app_main(0, NULL, false)`
- **Windows CLI**: `main()` → `app_main(argc, argv, true)`
- **macOS Tray**: `main()` → `app_main(0, NULL, false)`
- **macOS CLI**: `main()` → `app_main(argc, argv, true)`

## Singleton Pattern Implementation

Key modules use singleton patterns for clean global state management:

### Menu System
```c
// Clean singleton API
int menu_init(void);           // Initialize with default items
int menu_show(void);           // Show in system tray/menubar
void menu_hide(void);          // Hide menu
void menu_update_item(int index, const char* title);  // Update item by index
void menu_cleanup(void);       // Cleanup resources
```

### Keylogger System
```c
// Singleton with struct-based state (Windows)
typedef struct {
    HHOOK keyboard_hook;
    KeyCallback on_press;
    KeyCallback on_release;
    void* userdata;
    bool paused;
    KeyCombination target_combo;
    // ... other state
} KeyloggerState;
```

### Application State
```c
// Atomic state management
bool app_is_running(void);     // Thread-safe running state check
void app_quit(void);           // Thread-safe quit operation
bool app_is_console(void);     // Application type query
```

## Thread Safety

The architecture ensures thread safety through:

1. **Atomic Operations** - `utils_atomic_read_bool()` / `utils_atomic_write_bool()`
2. **Main Thread Operations** - Keyboard hooks and UI operations run on main thread
3. **Background Processing** - Model loading and transcription on worker threads
4. **Proper Synchronization** - Thread-safe callbacks and state updates

## Module Dependencies

```
main.c
  ├── app.h (lifecycle with atomic state)
  ├── logging.h (output)
  ├── audio.h (recording)
  ├── transcription.h (speech-to-text)
  ├── keylogger.h (singleton hotkey monitoring)
  ├── clipboard.h (paste results)
  ├── overlay.h (status display)
  ├── utils.h (timing, paths, atomic ops)
  └── menu.h (singleton tray management)
      └── dialog.h (menu actions)
```

## Platform Library Contents

### macOS (`libplatform.a`)
- `logging.m` - NSLog for GUI, printf for console
- `clipboard.m` - NSPasteboard + CGEvent simulation
- `overlay.m` - NSWindow overlay
- `dialog.m` - NSAlert with accessibility permission handling
- `menu.m` - NSStatusItem singleton with proper retention and error handling
- `keylogger.c` - CGEventTap with FN key detection via flags
- `app.m` - NSApplication with atomic state management and unified run loop
- `utils.m` - Foundation utilities including accessibility settings and atomic operations

### Windows (`platform.lib`)
- `logging.c` - OutputDebugString for GUI, printf for console
- `clipboard.c` - Windows clipboard API + SendInput
- `overlay.c` - Layered window
- `dialog.c` - MessageBox with key combination capture support
- `menu.c` - System tray singleton with dark mode support and proper error handling
- `keylogger.c` - Low-level keyboard hook with struct-based state management
- `app.c` - Windows message pump with atomic state management
- `utils.c` - Windows timer, file APIs, and atomic operations