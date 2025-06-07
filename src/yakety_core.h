#ifndef YAKETY_CORE_H
#define YAKETY_CORE_H

#include <stdbool.h>
#include "audio.h"

// Core Yakety functionality shared between CLI and GUI apps
typedef struct {
    AudioRecorder* recorder;
    bool whisper_initialized;
    bool is_recording;
    bool was_recording;
    double recording_start_time;
} YaketyCore;

// Callback functions for platform-specific operations
typedef struct {
    void (*on_recording_start)(void);
    void (*on_recording_stop)(void);
    void (*on_transcription_start)(void);
    void (*on_transcription_complete)(const char* text);
    void (*on_transcription_error)(const char* error);
    void (*on_transcription_empty)(void);
} YaketyCallbacks;

// Core functions
YaketyCore* yakety_core_init(void);
void yakety_core_cleanup(YaketyCore* core);

// Recording control
void yakety_core_start_recording(YaketyCore* core, YaketyCallbacks* callbacks);
void yakety_core_stop_recording(YaketyCore* core, YaketyCallbacks* callbacks);

// Main update function - call this in your main loop
void yakety_core_update(YaketyCore* core, bool key_pressed, YaketyCallbacks* callbacks);

// Process completed recording
void yakety_core_process_recording(YaketyCore* core, YaketyCallbacks* callbacks);

// Get current time in seconds
double yakety_get_time(void);

#endif // YAKETY_CORE_H