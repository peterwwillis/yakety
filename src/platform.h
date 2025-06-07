#ifndef PLATFORM_H
#define PLATFORM_H

#include <stdbool.h>

// Platform-specific functionality abstraction

// Clipboard operations
void platform_copy_to_clipboard(const char* text);
void platform_paste_text(void);

// UI operations
void platform_show_error(const char* title, const char* message);
void platform_show_info(const char* title, const char* message);

// Platform initialization (permissions, etc.)
int platform_init(void);

// Model path resolution
const char* platform_find_model_path(void);

// Console-specific functions
void platform_console_print(const char* message);
bool platform_console_init(void);

#endif // PLATFORM_H