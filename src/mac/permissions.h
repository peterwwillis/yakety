#ifndef MAC_PERMISSIONS_H
#define MAC_PERMISSIONS_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Permission types
typedef enum {
    PERMISSION_ACCESSIBILITY = 0,
    PERMISSION_MICROPHONE
} PermissionType;

// Check and wait for a specific permission
// Returns true if permission was granted, false if user chose to quit
// - permission: The type of permission to check
bool check_and_wait_for_permission(PermissionType permission);

// Direct permission check functions (no UI)
bool check_accessibility_permission(void);
bool check_input_monitoring_permission(void);
bool check_microphone_permission(void);

// Permission request functions (triggers system dialogs/settings)
void request_accessibility_permission(void);
void request_input_monitoring_permission(void);
void request_microphone_permission(void);

#ifdef __cplusplus
}
#endif

#endif // MAC_PERMISSIONS_H