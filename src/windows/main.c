#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <stdbool.h>
#include <string.h>
#include "../yakety_core.h"
#include "../platform.h"
#include "../overlay.h"

// Global variables
static bool g_running = true;
static YaketyCore* g_core = NULL;

// Function prototypes
int keylogger_init(void);
void keylogger_cleanup(void);
bool keylogger_is_fn_pressed(void);

// Console control handler for graceful shutdown
BOOL WINAPI console_handler(DWORD signal) {
    if (signal == CTRL_C_EVENT || signal == CTRL_BREAK_EVENT) {
        platform_console_print("\nShutting down...\n");
        g_running = false;
        return TRUE;
    }
    return FALSE;
}

void cleanup() {
    if (g_core) {
        yakety_core_cleanup(g_core);
        g_core = NULL;
    }
    keylogger_cleanup();
    overlay_cleanup();
}

// Callback implementations
void on_recording_start(void) {
    platform_console_print("Recording started...\n");
    overlay_show("Recording");
}

void on_recording_stop(void) {
    // Nothing to do here for console version
}

void on_transcription_start(void) {
    platform_console_print("Processing audio...\n");
    overlay_show("Transcribing");
}

void on_transcription_complete(const char* text) {
    char msg[1100];
    snprintf(msg, sizeof(msg), "Transcription: %s\n", text);
    platform_console_print(msg);
    
    platform_copy_to_clipboard(text);
    platform_paste_text();
    overlay_hide();
}

void on_transcription_error(const char* error) {
    char msg[256];
    snprintf(msg, sizeof(msg), "Transcription error: %s\n", error);
    platform_console_print(msg);
    overlay_hide();
}

void on_transcription_empty(void) {
    platform_console_print("No transcription result\n");
    overlay_hide();
}

int main(int argc, char* argv[]) {
    // Initialize console
    platform_console_init();
    
    platform_console_print("Yakety - Hold Right Ctrl key to record and transcribe speech\n");
    platform_console_print("Note: Using Right Ctrl instead of FN key on Windows\n");
    
    // Set up console control handler
    SetConsoleCtrlHandler(console_handler, TRUE);
    
    // Initialize platform
    if (platform_init() != 0) {
        fprintf(stderr, "Failed to initialize platform\n");
        return 1;
    }
    
    // Initialize overlay
    overlay_init();
    
    // Initialize core
    platform_console_print("Loading Whisper model...\n");
    g_core = yakety_core_init();
    if (!g_core) {
        fprintf(stderr, "Failed to initialize Yakety core\n");
        fprintf(stderr, "Please ensure the model file is in the correct location.\n");
        cleanup();
        return 1;
    }
    platform_console_print("Whisper model loaded successfully\n");
    
    // Initialize keylogger
    if (keylogger_init() != 0) {
        fprintf(stderr, "Failed to initialize keyboard monitoring\n");
        fprintf(stderr, "Make sure to run as administrator on Windows\n");
        cleanup();
        return 1;
    }
    
    platform_console_print("Ready! Hold Right Ctrl to record.\n");
    
    // Set up callbacks
    YaketyCallbacks callbacks = {
        .on_recording_start = on_recording_start,
        .on_recording_stop = on_recording_stop,
        .on_transcription_start = on_transcription_start,
        .on_transcription_complete = on_transcription_complete,
        .on_transcription_error = on_transcription_error,
        .on_transcription_empty = on_transcription_empty
    };
    
    // Main loop
    MSG msg;
    while (g_running) {
        // Process Windows messages
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) {
                g_running = false;
                break;
            }
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        
        bool is_key_pressed = keylogger_is_fn_pressed();
        yakety_core_update(g_core, is_key_pressed, &callbacks);
        
        Sleep(10);  // Small delay to prevent high CPU usage
    }
    
    cleanup();
    platform_console_print("Goodbye!\n");
    return 0;
}