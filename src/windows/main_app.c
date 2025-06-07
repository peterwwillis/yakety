#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "../yakety_core.h"
#include "../platform.h"
#include "../menubar.h"
#include "../overlay.h"

// Function prototypes
int keylogger_init(void);
void keylogger_cleanup(void);
bool keylogger_is_fn_pressed(void);

// Global variables
static bool g_running = true;
static YaketyCore* g_core = NULL;

void cleanup() {
    if (g_core) {
        yakety_core_cleanup(g_core);
        g_core = NULL;
    }
    keylogger_cleanup();
    menubar_cleanup();
    overlay_cleanup();
}

// Callback implementations
void on_recording_start(void) {
    overlay_show("Recording");
}

void on_recording_stop(void) {
    // Nothing to do here for GUI version
}

void on_transcription_start(void) {
    overlay_show("Transcribing");
}

void on_transcription_complete(const char* text) {
    platform_copy_to_clipboard(text);
    platform_paste_text();
    overlay_hide();
}

void on_transcription_error(const char* error) {
    // Could show error in system tray notification
    overlay_hide();
}

void on_transcription_empty(void) {
    overlay_hide();
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // Hide console window for GUI app
    FreeConsole();
    
    // Initialize platform
    if (platform_init() != 0) {
        MessageBoxW(NULL, L"Failed to initialize platform", L"Error", MB_OK | MB_ICONERROR);
        return 1;
    }
    
    // Initialize system tray
    if (menubar_init() != 0) {
        MessageBoxW(NULL, L"Failed to create system tray icon", L"Error", MB_OK | MB_ICONERROR);
        return 1;
    }
    
    // Initialize overlay
    overlay_init();
    
    // Initialize core
    g_core = yakety_core_init();
    if (!g_core) {
        MessageBoxW(NULL, L"Failed to initialize Yakety\nPlease ensure the model file is in the correct location.", L"Error", MB_OK | MB_ICONERROR);
        cleanup();
        return 1;
    }
    
    // Initialize keylogger
    if (keylogger_init() != 0) {
        MessageBoxW(NULL, 
                 L"Failed to initialize keyboard monitoring.\nMake sure to run as administrator.", 
                 L"Error", MB_OK | MB_ICONERROR);
        cleanup();
        return 1;
    }
    
    // Set up callbacks
    YaketyCallbacks callbacks = {
        .on_recording_start = on_recording_start,
        .on_recording_stop = on_recording_stop,
        .on_transcription_start = on_transcription_start,
        .on_transcription_complete = on_transcription_complete,
        .on_transcription_error = on_transcription_error,
        .on_transcription_empty = on_transcription_empty
    };
    
    // Main message loop
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
        
        // Check key state and update core
        bool is_key_pressed = keylogger_is_fn_pressed();
        yakety_core_update(g_core, is_key_pressed, &callbacks);
        
        Sleep(10);  // Small delay to prevent high CPU usage
    }
    
    cleanup();
    return 0;
}