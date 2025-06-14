<!-- Generated: 2025-06-14 23:07:15 UTC -->

# Testing

Yakety uses native C test programs to verify dialog system functionality on macOS. Tests focus on SwiftUI dialog implementations and user interaction flows.

**Test Location** - All test source files in `src/tests/`, executables built to `build-debug/bin/` or `build/bin/`

**Test Framework** - Custom test programs using platform dialog APIs, no external test frameworks

## Test Types

### Dialog System Tests

**Model Selection Dialog** (`src/tests/test_model_dialog.c`)
- Tests model/language selection UI via `dialog_models_and_language()` 
- Verifies SwiftUI implementation in `src/mac/dialogs/models_dialog.swift`
- Displays available models, language options, download URLs
- Expected outputs: selected model path, language code, download URL

**Key Combination Capture** (`src/tests/test_keycombination_dialog.c`)  
- Tests hotkey capture dialog via `dialog_keycombination_capture()`
- Validates SwiftUI implementation in `src/mac/dialogs/hotkey_dialog.swift`
- Captures modifier keys and key combinations for user configuration
- Expected outputs: key combination structure with codes and flags

**Download Progress Dialog** (`src/tests/test_download_dialog.c`)
- Tests model download UI via `dialog_model_download()`
- Uses SwiftUI implementation in `src/mac/dialogs/download_dialog.swift`
- Downloads test file from httpbin.org to verify progress tracking
- Expected outputs: download completion status (0=success, 1=cancelled, 2=error)

### Platform Integration Tests

**App Lifecycle** - All test programs initialize platform app via `app_init()` in `src/app.h`
- Tests Cocoa setup on macOS with proper Swift integration
- Validates event loop and dialog presentation

**Framework Linking** - CMake configuration links required frameworks:
```cmake
# From CMakeLists.txt:515-516, 525-526
target_link_libraries(test-keycombination-dialog "-framework Cocoa" "-framework SwiftUI")
target_link_libraries(test-download-dialog "-framework Cocoa" "-framework SwiftUI")
```

## Running Tests

### Build Test Programs
```bash
# Debug build with test programs
cmake --preset debug && cmake --build build-debug

# Release build  
cmake --preset release && cmake --build build
```

**Test Executables** - Located in `build-debug/bin/` or `build/bin/`:
- `test-model-dialog`
- `test-keycombination-dialog` 
- `test-download-dialog`

### Execute Tests
```bash
# Run from build directory
./build-debug/bin/test-model-dialog
./build-debug/bin/test-keycombination-dialog  
./build-debug/bin/test-download-dialog
```

**Expected Behavior** - Each test presents modal dialog, waits for user interaction, prints results to console

**Manual Verification** - Tests require user interaction:
- Model dialog: Select model and language, verify console output matches selection
- Hotkey dialog: Press key combination, verify captured keys display correctly
- Download dialog: Observe progress bar, verify file creation at `/tmp/test_download.bin`

### Test Output Analysis

**Model Dialog Results** (`test_model_dialog.c:14-22`):
```c
if (dialog_models_and_language(...)) {
    printf("User selected model: %s\n", selected_model);
    printf("User selected language: %s\n", selected_language); 
    printf("Download URL: %s\n", download_url);
}
```

**Key Combination Results** (`test_keycombination_dialog.c:32-38`):
```c
for (int i = 0; i < MAX_KEYS_IN_COMBINATION && result.keys[i].code != 0; i++) {
    printf("  Key %d: code=%u, flags=0x%x\n", i + 1, result.keys[i].code, result.keys[i].flags);
}
```

**Download Results** (`test_download_dialog.c:25-47`):
```c
switch (result) {
    case 0: printf("Download completed successfully!\n"); break;
    case 1: printf("Download was cancelled by user.\n"); break;
    case 2: printf("Download failed with an error.\n"); break;
}
```

## Reference

### Test File Organization

**Source Structure**:
```
src/tests/
├── test_model_dialog.c          # Model selection dialog test
├── test_keycombination_dialog.c # Hotkey capture dialog test  
└── test_download_dialog.c       # Download progress dialog test
```

**Dialog Implementations**:
```
src/mac/dialogs/
├── models_dialog.swift    # Model selection SwiftUI view
├── hotkey_dialog.swift    # Key combination capture SwiftUI view
└── download_dialog.swift  # Download progress SwiftUI view
```

### Build System Test Targets

**CMake Test Configuration** (`CMakeLists.txt:502-532`):
- Test programs only built on Apple platforms (`if(APPLE)`)
- Links platform library providing dialog functions
- Links Cocoa and SwiftUI frameworks for native UI
- Outputs to `${CMAKE_BINARY_DIR}/bin` directory

**Target Dependencies**:
```cmake
target_link_libraries(test-model-dialog platform)
target_link_libraries(test-keycombination-dialog platform "-framework SwiftUI") 
target_link_libraries(test-download-dialog platform "-framework SwiftUI")
```

### Common Test Issues

**Missing Frameworks** - SwiftUI framework required for newer dialog tests, older model dialog uses Cocoa only

**App Initialization** - All tests must call `app_init()` before presenting dialogs

**Keylogger Conflicts** - Key combination test initializes dummy keylogger to avoid conflicts with main app keylogger