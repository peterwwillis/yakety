#include "../utils.h"
#include "../logging.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

// High-resolution timer frequency
static LARGE_INTEGER g_frequency = {0};
static bool g_timer_initialized = false;

// Initialize high-resolution timer
static void init_timer(void) {
    if (!g_timer_initialized) {
        QueryPerformanceFrequency(&g_frequency);
        g_timer_initialized = true;
    }
}

double utils_get_time(void) {
    init_timer();
    
    LARGE_INTEGER counter;
    QueryPerformanceCounter(&counter);
    
    // Return time in seconds as a double
    return (double)counter.QuadPart / (double)g_frequency.QuadPart;
}

void utils_sleep_ms(int milliseconds) {
    Sleep(milliseconds);
}

const char* utils_get_model_path(void) {
    static char model_path[MAX_PATH] = {0};
    
    log_info("🔍 Searching for Whisper model...\n");
    
    // Check current directory first
    log_info("  Checking current directory: ggml-base.en.bin\n");
    if (GetFileAttributesA("ggml-base.en.bin") != INVALID_FILE_ATTRIBUTES) {
        log_info("  ✅ Found in current directory\n");
        return "ggml-base.en.bin";
    }
    
    // Get the executable directory
    if (GetModuleFileNameA(NULL, model_path, MAX_PATH) == 0) {
        log_error("  ❌ Failed to get executable path\n");
        return NULL;
    }
    
    // Find the last backslash to get directory
    char* last_slash = strrchr(model_path, '\\');
    if (last_slash) {
        *last_slash = '\0';
    }
    
    log_info("  Executable directory: %s\n", model_path);
    
    // Check models subdirectory in executable directory
    char test_path[MAX_PATH];
    snprintf(test_path, MAX_PATH, "%s\\models\\ggml-base.en.bin", model_path);
    log_info("  Checking: %s\n", test_path);
    
    if (GetFileAttributesA(test_path) != INVALID_FILE_ATTRIBUTES) {
        log_info("  ✅ Found in executable directory\\models\n");
        strcpy(model_path, test_path);  // Return full path with filename
        return model_path;
    }
    
    // Check directly in executable directory
    snprintf(test_path, MAX_PATH, "%s\\ggml-base.en.bin", model_path);
    log_info("  Checking: %s\n", test_path);
    
    if (GetFileAttributesA(test_path) != INVALID_FILE_ATTRIBUTES) {
        log_info("  ✅ Found in executable directory\n");
        strcpy(model_path, test_path);  // Return full path with filename
        return model_path;
    }
    
    // Try parent directory (for development builds)
    snprintf(test_path, MAX_PATH, "%s\\..\\ggml-base.en.bin", model_path);
    log_info("  Checking: %s\n", test_path);
    
    if (GetFileAttributesA(test_path) != INVALID_FILE_ATTRIBUTES) {
        // Normalize the path
        char full_path[MAX_PATH];
        if (GetFullPathNameA(test_path, MAX_PATH, full_path, NULL)) {
            // Remove the filename part to get just the directory
            last_slash = strrchr(full_path, '\\');
            if (last_slash) {
                *last_slash = '\0';
            }
            log_info("  ✅ Found in parent directory: %s\n", full_path);
            strcpy(model_path, full_path);
            return model_path;
        }
    }
    
    // Try whisper.cpp subdirectory
    snprintf(test_path, MAX_PATH, "%s\\whisper.cpp\\models\\ggml-base.en.bin", model_path);
    log_info("  Checking: %s\n", test_path);
    
    if (GetFileAttributesA(test_path) != INVALID_FILE_ATTRIBUTES) {
        log_info("  ✅ Found in whisper.cpp\\models\n");
        strcpy(model_path, test_path);  // Return full path with filename
        return model_path;
    }
    
    // Check whisper.cpp/models relative to current directory
    log_info("  Checking: whisper.cpp\\models\\ggml-base.en.bin\n");
    if (GetFileAttributesA("whisper.cpp\\models\\ggml-base.en.bin") != INVALID_FILE_ATTRIBUTES) {
        log_info("  ✅ Found in whisper.cpp\\models\n");
        return "whisper.cpp\\models";
    }
    
    log_error("  ❌ Model not found in any location!\n");
    return NULL;