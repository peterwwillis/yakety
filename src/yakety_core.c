#include "yakety_core.h"
#include "transcription.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <sys/time.h>
#endif

// Minimum recording duration in seconds
#define MIN_RECORDING_DURATION 0.1

double yakety_get_time(void) {
#ifdef _WIN32
    LARGE_INTEGER frequency, counter;
    QueryPerformanceFrequency(&frequency);
    QueryPerformanceCounter(&counter);
    return (double)counter.QuadPart / (double)frequency.QuadPart;
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec * 1e-6;
#endif
}

YaketyCore* yakety_core_init(void) {
    YaketyCore* core = (YaketyCore*)calloc(1, sizeof(YaketyCore));
    if (!core) {
        return NULL;
    }
    
    // Initialize audio recorder
    core->recorder = audio_recorder_create(&WHISPER_AUDIO_CONFIG);
    if (!core->recorder) {
        free(core);
        return NULL;
    }
    
    // Initialize Whisper model
    if (yakety_whisper_init() < 0) {
        audio_recorder_destroy(core->recorder);
        free(core);
        return NULL;
    }
    
    core->whisper_initialized = true;
    core->is_recording = false;
    core->was_recording = false;
    core->recording_start_time = 0.0;
    
    return core;
}

void yakety_core_cleanup(YaketyCore* core) {
    if (!core) return;
    
    if (core->recorder) {
        audio_recorder_destroy(core->recorder);
    }
    
    if (core->whisper_initialized) {
        yakety_whisper_cleanup();
    }
    
    free(core);
}

void yakety_core_start_recording(YaketyCore* core, YaketyCallbacks* callbacks) {
    if (!core || core->is_recording) return;
    
    audio_recorder_start_buffer(core->recorder);
    core->is_recording = true;
    core->recording_start_time = yakety_get_time();
    
    if (callbacks && callbacks->on_recording_start) {
        callbacks->on_recording_start();
    }
}

void yakety_core_stop_recording(YaketyCore* core, YaketyCallbacks* callbacks) {
    if (!core || !core->is_recording) return;
    
    audio_recorder_stop(core->recorder);
    core->is_recording = false;
    
    if (callbacks && callbacks->on_recording_stop) {
        callbacks->on_recording_stop();
    }
}

void yakety_core_update(YaketyCore* core, bool key_pressed, YaketyCallbacks* callbacks) {
    if (!core) return;
    
    // Handle recording state changes
    if (key_pressed && !core->is_recording) {
        // Start recording
        yakety_core_start_recording(core, callbacks);
    } else if (!key_pressed && core->is_recording) {
        // Stop recording
        yakety_core_stop_recording(core, callbacks);
        
        // Check if recording was long enough
        double recording_duration = yakety_get_time() - core->recording_start_time;
        if (recording_duration > MIN_RECORDING_DURATION) {
            yakety_core_process_recording(core, callbacks);
        }
    }
    
    // Update was_recording state
    core->was_recording = core->is_recording;
}

void yakety_core_process_recording(YaketyCore* core, YaketyCallbacks* callbacks) {
    if (!core || !core->recorder) return;
    
    // Get recorded audio
    size_t audio_size = 0;
    const float* audio_data = audio_recorder_get_data(core->recorder, &audio_size);
    
    if (!audio_data || audio_size == 0) {
        if (callbacks && callbacks->on_transcription_empty) {
            callbacks->on_transcription_empty();
        }
        return;
    }
    
    int sample_count = (int)audio_size;
    
    // Notify transcription start
    if (callbacks && callbacks->on_transcription_start) {
        callbacks->on_transcription_start();
    }
    
    // Transcribe audio
    char* text = whisper_transcribe(audio_data, sample_count, WHISPER_SAMPLE_RATE);
    
    if (text && strlen(text) > 0) {
        if (callbacks && callbacks->on_transcription_complete) {
            callbacks->on_transcription_complete(text);
        }
        free(text);
    } else {
        if (callbacks && callbacks->on_transcription_empty) {
            callbacks->on_transcription_empty();
        }
    }
    
    // Buffer is automatically cleared on next start
}