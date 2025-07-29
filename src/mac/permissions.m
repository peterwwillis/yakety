#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <AVFoundation/AVFoundation.h>
#include "permissions.h"
#include "../app.h"
#include "../logging.h"

// Permission display names
static const char* permission_names[] = {
    "Accessibility",
    "Input Monitoring",
    "Microphone"
};

// Check if Accessibility permission is granted
bool check_accessibility_permission(void) {
    Boolean trusted = AXIsProcessTrusted();
    log_info("Accessibility permission: %s", trusted ? "GRANTED" : "NOT GRANTED");
    return trusted;
}

// Check if Microphone permission is granted
bool check_microphone_permission(void) {
    @autoreleasepool {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];

        switch (status) {
            case AVAuthorizationStatusAuthorized:
                log_info("Microphone permission: GRANTED");
                return true;

            case AVAuthorizationStatusDenied:
                log_info("Microphone permission: DENIED");
                return false;
            case AVAuthorizationStatusRestricted:
                log_info("Microphone permission: RESTRICTED");
                return false;
            case AVAuthorizationStatusNotDetermined:
                log_info("Microphone permission: NOT DETERMINED");
                return false;
            default:
                log_info("Microphone permission: UNKNOWN");
                return false;
        }
    }
}

// Request Accessibility permission
void request_accessibility_permission(void) {
    @autoreleasepool {
        NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
        AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
        log_info("Triggered Accessibility permission request");
    }
}

// Request Microphone permission
void request_microphone_permission(void) {
    @autoreleasepool {
        log_info("Requesting microphone permission...");

        // Ensure we're on the main thread for UI operations
        if (![NSThread isMainThread]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                         completionHandler:^(BOOL granted) {
                    log_info("Microphone permission request completed: %s", granted ? "GRANTED" : "DENIED");
                }];
            });
        } else {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                     completionHandler:^(BOOL granted) {
                log_info("Microphone permission request completed: %s", granted ? "GRANTED" : "DENIED");
            }];
        }
    }
}

// Open System Preferences to the appropriate permission pane
static void open_permission_settings(PermissionType permission) {
    @autoreleasepool {
        NSURL *url = nil;

        switch (permission) {
            case PERMISSION_ACCESSIBILITY:
                url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
                break;
            case PERMISSION_MICROPHONE:
                url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"];
                break;
        }

        if (url) {
            [[NSWorkspace sharedWorkspace] openURL:url];
            log_info("Opened System Preferences for %s permission", permission_names[permission]);
        }
    }
}

// Show permission dialog and wait for user response
static int show_permission_dialog(PermissionType permission) {
    @autoreleasepool {
        const char *permission_name = permission_names[permission];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"%s Permission Required", permission_name]];

        NSString *infoText = [NSString stringWithFormat:
            @"Yakety needs %s permission to function properly.\n\n"
            @"1. Click 'Open System Settings' to grant permission\n"
            @"2. Find Yakety in the list and toggle it ON\n"
            @"3. Click 'I've Granted Permission' to continue\n"
            @"4. Or click 'Quit' to exit", permission_name];

        [alert setInformativeText:infoText];
        [alert addButtonWithTitle:@"I've Granted Permission"];
        [alert addButtonWithTitle:@"Open System Settings"];
        [alert addButtonWithTitle:@"Quit"];

        NSModalResponse response = [alert runModal];

        if (response == NSAlertFirstButtonReturn) {
            return 0; // User says they granted permission
        } else if (response == NSAlertSecondButtonReturn) {
            return 1; // Open settings
        } else {
            return 2; // Quit
        }
    }
}

// Show waiting dialog after opening settings
static bool show_wait_dialog(PermissionType permission) {
    @autoreleasepool {
        const char *permission_name = permission_names[permission];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"Waiting for %s Permission", permission_name]];
        [alert setInformativeText:[NSString stringWithFormat:
            @"Please enable %s permission for Yakety in System Settings, then click Continue.",
            permission_name]];
        [alert addButtonWithTitle:@"Continue"];
        [alert addButtonWithTitle:@"Quit"];

        return [alert runModal] == NSAlertFirstButtonReturn;
    }
}

// Main unified permission checking function
bool check_and_wait_for_permission(PermissionType permission) {
    const char *permission_name = permission_names[permission];

    // Get the appropriate check and request functions
    bool (*check_func)(void) = NULL;
    void (*request_func)(void) = NULL;

    switch (permission) {
        case PERMISSION_ACCESSIBILITY:
            check_func = check_accessibility_permission;
            request_func = request_accessibility_permission;
            break;
        case PERMISSION_MICROPHONE:
            check_func = check_microphone_permission;
            request_func = request_microphone_permission;
            break;
    }

    // First check if permission is already granted
    if (check_func && check_func()) {
        return true;
    }

    // For CLI apps, just log and return false
    if (app_is_console()) {
        log_error("Please grant %s permission to Yakety in:", permission_name);
        log_error("System Settings → Privacy & Security → %s", permission_name);

        // Note about permission inheritance for CLI
        if (permission == PERMISSION_ACCESSIBILITY) {
            log_error("");
            log_error("Note: If running from a terminal app (VS Code, iTerm, etc.),");
            log_error("that app also needs %s permission due to macOS inheritance.", permission_name);
        }

        return false;
    }

    request_func();
    app_sleep_responsive(1000);

    while (true) {
        // Check again in case user granted permission
        if (check_func()) {
            return true;
        }

        // Show permission dialog
        int response = show_permission_dialog(permission);

        if (response == 0) {
            // User says they granted permission - check and retry if needed
            app_sleep_responsive(500); // Give system time to update
            if (check_func()) {
                return true;
            }
            // Permission not actually granted, loop back to dialog
            continue;

        } else if (response == 1) {
            // Open System Settings
            open_permission_settings(permission);

            // Now only show wait dialog in a loop until permission granted or user quits
            while (true) {
                if (show_wait_dialog(permission)) {
                    app_sleep_responsive(500); // Give system time to update
                    if (check_func()) {
                        return true;
                    }
                    // Permission not granted yet, show wait dialog again
                    continue;
                } else {
                    // User chose to quit
                    return false;
                }
            }

        } else {
            // User chose to quit
            return false;
        }
    }
}