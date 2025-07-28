#ifndef AUDIO_PERMISSION_H
#define AUDIO_PERMISSION_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Check and request microphone permission
// Returns true if permission is granted, false otherwise
bool check_and_request_microphone_permission(void);

#ifdef __cplusplus
}
#endif

#endif // AUDIO_PERMISSION_H