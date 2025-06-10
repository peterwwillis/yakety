#ifndef APP_H
#define APP_H

#include <stdbool.h>

// Entry point macro
#ifdef _WIN32
    #ifdef YAKETY_TRAY_APP
        // Forward declarations for Windows types (only if not already included)
        #ifndef _WINDOWS_
            typedef void* HINSTANCE;
            typedef void* LPSTR;
            #define WINAPI __stdcall
        #endif
        #define APP_MAIN WinMain
    #else
        #define APP_MAIN main
    #endif
#else
    #define APP_MAIN main
#endif

typedef void (*AppReadyCallback)(void);

// Initialize the application
int app_init(const char* name, const char* version, bool is_console, AppReadyCallback on_ready);

// Cleanup the application
void app_cleanup(void);

// Run the application main loop
void app_run(void);

// Quit the application
void app_quit(void);

// Check if the app is running in console mode
bool app_is_console(void);

#endif // APP_H