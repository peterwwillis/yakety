#include "../keylogger.h"
#include "../logging.h"
#include <windows.h>
#include <stdbool.h>
#include <string.h>

// Global variables
static HHOOK g_keyboard_hook = NULL;
static KeyCallback g_on_press = NULL;
static KeyCallback g_on_release = NULL;
static void* g_userdata = NULL;
static bool g_paused = false;

// Key combination tracking
static KeyCombination g_target_combo = {{0}, 0}; // Will be initialized properly
static bool g_combo_pressed = false;
static KeyInfo g_pressed_keys[4] = {{0}, {0}, {0}, {0}};
static int g_pressed_count = 0;

// Check if two key infos match
static bool key_info_matches(const KeyInfo* a, const KeyInfo* b) {
    return a->code == b->code && a->flags == b->flags;
}

// Check if a key is currently in our pressed list
static bool is_key_pressed(DWORD scanCode, DWORD flags) {
    uint32_t extended = (flags & LLKHF_EXTENDED) ? 1 : 0;
    for (int i = 0; i < g_pressed_count; i++) {
        if (g_pressed_keys[i].code == scanCode && g_pressed_keys[i].flags == extended) {
            return true;
        }
    }
    return false;
}

// Add a key to pressed list
static void add_pressed_key(DWORD scanCode, DWORD flags) {
    if (g_pressed_count < 4 && !is_key_pressed(scanCode, flags)) {
        g_pressed_keys[g_pressed_count].code = scanCode;
        g_pressed_keys[g_pressed_count].flags = (flags & LLKHF_EXTENDED) ? 1 : 0;
        g_pressed_count++;
    }
}

// Remove a key from pressed list
static void remove_pressed_key(DWORD scanCode, DWORD flags) {
    uint32_t extended = (flags & LLKHF_EXTENDED) ? 1 : 0;
    for (int i = 0; i < g_pressed_count; i++) {
        if (g_pressed_keys[i].code == scanCode && g_pressed_keys[i].flags == extended) {
            // Shift remaining keys
            for (int j = i; j < g_pressed_count - 1; j++) {
                g_pressed_keys[j] = g_pressed_keys[j + 1];
            }
            g_pressed_count--;
            break;
        }
    }
}

// Check if current pressed keys match the target combination
static bool check_combination_match(void) {
    // Must have exact number of keys
    if (g_pressed_count != g_target_combo.count) {
        return false;
    }
    
    // Check if all target keys are pressed
    for (int i = 0; i < g_target_combo.count; i++) {
        bool found = false;
        for (int j = 0; j < g_pressed_count; j++) {
            if (key_info_matches(&g_target_combo.keys[i], &g_pressed_keys[j])) {
                found = true;
                break;
            }
        }
        if (!found) {
            return false;
        }
    }
    
    return true;
}

// Low-level keyboard hook procedure
LRESULT CALLBACK keyboard_proc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0 && !g_paused) {
        KBDLLHOOKSTRUCT* kbdStruct = (KBDLLHOOKSTRUCT*)lParam;
        bool keyDown = (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN);
        bool keyUp = (wParam == WM_KEYUP || wParam == WM_SYSKEYUP);
        
        if (keyDown) {
            // Add key to pressed list
            add_pressed_key(kbdStruct->scanCode, kbdStruct->flags);
            
            // Check if combination is now complete
            if (check_combination_match() && !g_combo_pressed) {
                g_combo_pressed = true;
                if (g_on_press) {
                    g_on_press(g_userdata);
                }
            }
        } else if (keyUp) {
            // Check if we're releasing a key from our combination
            bool was_combo_key = false;
            if (g_combo_pressed) {
                uint32_t extended = (kbdStruct->flags & LLKHF_EXTENDED) ? 1 : 0;
                for (int i = 0; i < g_target_combo.count; i++) {
                    if (g_target_combo.keys[i].code == kbdStruct->scanCode && 
                        g_target_combo.keys[i].flags == extended) {
                        was_combo_key = true;
                        break;
                    }
                }
            }
            
            // Remove key from pressed list
            remove_pressed_key(kbdStruct->scanCode, kbdStruct->flags);
            
            // If we released a combo key, trigger release
            if (was_combo_key && g_combo_pressed) {
                g_combo_pressed = false;
                if (g_on_release) {
                    g_on_release(g_userdata);
                }
            }
        }
    }
    
    // Pass the event to the next hook
    return CallNextHookEx(g_keyboard_hook, nCode, wParam, lParam);
}

int keylogger_init(KeyCallback on_press, KeyCallback on_release, void* userdata) {
    // Store callbacks
    g_on_press = on_press;
    g_on_release = on_release;
    g_userdata = userdata;
    
    // Install low-level keyboard hook
    g_keyboard_hook = SetWindowsHookEx(WH_KEYBOARD_LL, keyboard_proc, GetModuleHandle(NULL), 0);
    
    if (!g_keyboard_hook) {
        DWORD error = GetLastError();
        log_error("Failed to install keyboard hook. Error: %lu", error);
        return -1;
    }
    
    log_info("Keylogger initialized successfully");
    return 0;
}

void keylogger_cleanup(void) {
    if (g_keyboard_hook) {
        UnhookWindowsHookEx(g_keyboard_hook);
        g_keyboard_hook = NULL;
    }
    
    g_on_press = NULL;
    g_on_release = NULL;
    g_userdata = NULL;
    g_combo_pressed = false;
    g_pressed_count = 0;
    
    log_info("Keylogger cleaned up");
}

void keylogger_pause(void) {
    g_paused = true;
    log_info("Keylogger paused");
}

void keylogger_resume(void) {
    g_paused = false;
    log_info("Keylogger resumed");
}

void keylogger_set_combination(const KeyCombination* combo) {
    if (combo) {
        g_target_combo = *combo;
        g_combo_pressed = false;
        g_pressed_count = 0;
        
        // Log the combination for debugging
        log_info("Keylogger combination set with %d keys:", combo->count);
        for (int i = 0; i < combo->count; i++) {
            log_info("  Key %d: scancode=0x%02X, extended=%d", 
                     i + 1, combo->keys[i].code, combo->keys[i].flags);
        }
    }
}

KeyCombination keylogger_get_fn_combination(void) {
    // Windows doesn't have FN key like macOS, return Right Ctrl as default
    // Right Ctrl: scancode 0x1D with extended flag
    KeyCombination ctrl_combo = {
        .keys = {{0x1D, 1}},  // Right Ctrl
        .count = 1
    };
    return ctrl_combo;
}