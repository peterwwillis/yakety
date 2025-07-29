# Unified macOS Permissions System
**Status:** InProgress
**Agent PID:** 54909

## Original Todo
Clean up permission handling by creating a unified macOS permission system. Move all permission logic from main.c and dialog.h into platform-specific code. Create src/mac/permissions.h/.m with a single check_and_wait_for_permission function that handles all permission types.

## Description
Create a unified permission handling system for macOS that consolidates all scattered permission logic into a single, reusable module. Currently, permission handling is fragmented across multiple files with duplicate dialog code and platform-specific logic in the business layer.

The new system will:
1. Create `src/mac/permissions.h/.m` with a single `check_and_wait_for_permission(permission)` function.

2. Handle all three permission types uniformly:
   - Accessibility (for CGEventTap)
   - Input Monitoring (for keyboard access)
   - Microphone (for audio recording)

3. Provide consistent behavior:
   - For GUI apps: Show dialogs guiding users through the permission process
   - For CLI apps: Log instructions and exit cleanly
   - Handle retry logic when users grant permissions

4. Clean up the codebase by:
   - Removing 4 nearly-duplicate dialog functions from dialog.h/dialog.m
   - Moving all permission logic out of main.c's handle_keylogger_permissions()
   - Simplifying keylogger_init() to just check permissions and return success/failure
   - Making the business logic (main.c) platform-agnostic

## Implementation Plan
- [x] Create src/mac/permissions.h with function pointer typedefs and check_and_wait_for_permission declaration
- [x] Create src/mac/permissions.m implementing all permission checks, requests, and dialog logic
- [x] Update CMakeLists.txt to include permissions.m and remove audio_permission.m and input_monitoring.m
- [x] Update src/mac/keylogger.c to use new permission system in keylogger_init
- [x] Update src/audio.c to use new permission system instead of audio_permission.h
- [x] Remove src/mac/audio_permission.h, src/mac/audio_permission.m, src/audio_permission.h
- [x] Remove src/mac/input_monitoring.h and src/mac/input_monitoring.m
- [x] Remove permission dialogs from src/mac/dialog.m (dialog_accessibility_permission, dialog_wait_for_permission, dialog_input_monitoring_permission, dialog_wait_for_input_monitoring)
- [x] Remove permission dialog declarations from src/dialog.h
- [x] Update main.c to remove Apple specific permissions code
- [x] Remove utils_open_accessibility_settings and utils_open_input_monitoring_settings from utils.h and utils_mac.mm
- [x] Test all three permission types work correctly in both GUI and CLI modes
- [x] Fix accessibility permission check in src/mac/permissions.m - the check is failing even when permission is granted in TCC database