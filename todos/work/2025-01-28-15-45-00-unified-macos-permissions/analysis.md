# Analysis: Unified macOS Permissions System

## Current State

### Permission Handling is Scattered:
1. **main.c**:
   - `handle_keylogger_permissions()` (lines 85-124) - handles keylogger permission failures
   - `setup_keylogger()` (lines 126-155) - loops until permissions granted
   - Uses platform-specific #ifdef __APPLE__ blocks

2. **dialog.h**:
   - Declares 4 macOS-specific permission dialog functions (lines 28-33)
   - These are in the generic dialog interface but are platform-specific

3. **src/mac/dialog.m**:
   - Implements 4 separate dialog functions (lines 39-112):
     - `dialog_accessibility_permission()`
     - `dialog_wait_for_permission()`
     - `dialog_input_monitoring_permission()`
     - `dialog_wait_for_input_monitoring()`
   - These pairs are almost identical, just different text

4. **src/mac/keylogger.c**:
   - Checks permissions in `keylogger_init()` but just returns -1 on failure
   - Doesn't handle the UI flow for requesting permissions

5. **src/mac/audio_permission.m**:
   - Has its own permission handling for microphone
   - Doesn't follow same pattern as keyboard permissions

## Problems:
1. Business logic (main.c) knows about platform-specific permission handling
2. Duplicate code for similar permission dialogs
3. No unified approach - each permission type handled differently
4. Platform-specific code in generic interfaces

## Proposed Solution:

### New src/mac/permissions.h/.m:
```c
typedef bool (*PermissionCheckFunc)(void);
typedef void (*PermissionRequestFunc)(void);

bool check_and_wait_for_permission(
    PermissionCheckFunc check_func,
    PermissionRequestFunc request_func,
    const char *permission_name
);
```

This single function will:
1. Check if permission is already granted (using check_func)
2. If not, call request_func to trigger system permission request
3. Show dialog with permission_name asking user to grant permission
4. Wait for user to grant permission or quit
5. Return true if permission granted, false if user quit

### Benefits:
1. All permission logic in platform-specific code
2. Single reusable function for all permission types
3. No platform-specific code in main.c
4. Cleaner keylogger_init that just returns success/failure
5. Consistent handling for all permissions