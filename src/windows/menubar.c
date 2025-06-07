#include <windows.h>
#include <shellapi.h>
#include <stdio.h>

#define WM_TRAYICON (WM_USER + 1)
#define ID_TRAY_ABOUT 1001
#define ID_TRAY_QUIT 1002

static HWND g_hidden_window = NULL;
static NOTIFYICONDATAW g_tray_icon = {0};
static HMENU g_tray_menu = NULL;

// Window procedure for hidden window
LRESULT CALLBACK tray_window_proc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_TRAYICON:
            if (lParam == WM_RBUTTONUP) {
                // Show context menu
                POINT pt;
                GetCursorPos(&pt);
                
                SetForegroundWindow(hwnd);  // Required for menu to disappear when clicking away
                
                TrackPopupMenu(g_tray_menu, TPM_RIGHTBUTTON, 
                             pt.x, pt.y, 0, hwnd, NULL);
                
                PostMessage(hwnd, WM_NULL, 0, 0);  // Force menu to disappear
            }
            break;
            
        case WM_COMMAND:
            switch (LOWORD(wParam)) {
                case ID_TRAY_ABOUT:
                    MessageBoxW(hwnd, 
                              L"Yakety\n\nHold Right Ctrl to record and transcribe speech.\n\nCross-platform speech-to-text using Whisper.", 
                              L"About Yakety", 
                              MB_OK | MB_ICONINFORMATION);
                    break;
                    
                case ID_TRAY_QUIT:
                    PostQuitMessage(0);
                    break;
            }
            break;
            
        case WM_DESTROY:
            // Remove tray icon
            Shell_NotifyIconW(NIM_DELETE, &g_tray_icon);
            PostQuitMessage(0);
            break;
            
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    
    return 0;
}

int menubar_init(void) {
    // Register window class for hidden window
    WNDCLASSEXW wc = {0};
    wc.cbSize = sizeof(WNDCLASSEXW);
    wc.lpfnWndProc = tray_window_proc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = L"YaketyTrayWindow";
    
    if (!RegisterClassExW(&wc)) {
        return -1;
    }
    
    // Create hidden window
    g_hidden_window = CreateWindowExW(
        0,
        L"YaketyTrayWindow",
        L"Yakety",
        0,
        0, 0, 0, 0,
        NULL, NULL,
        GetModuleHandle(NULL),
        NULL
    );
    
    if (!g_hidden_window) {
        return -1;
    }
    
    // Create tray menu
    g_tray_menu = CreatePopupMenu();
    AppendMenuW(g_tray_menu, MF_STRING, ID_TRAY_ABOUT, L"About Yakety");
    AppendMenuW(g_tray_menu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(g_tray_menu, MF_STRING, ID_TRAY_QUIT, L"Quit Yakety");
    
    // Create tray icon
    g_tray_icon.cbSize = sizeof(NOTIFYICONDATAW);
    g_tray_icon.hWnd = g_hidden_window;
    g_tray_icon.uID = 1;
    g_tray_icon.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    g_tray_icon.uCallbackMessage = WM_TRAYICON;
    
    // Load default application icon
    g_tray_icon.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    
    wcscpy_s(g_tray_icon.szTip, 128, L"Yakety - Right Ctrl to record");
    
    // Add to system tray
    if (!Shell_NotifyIconW(NIM_ADD, &g_tray_icon)) {
        DestroyWindow(g_hidden_window);
        return -1;
    }
    
    return 0;
}

void menubar_cleanup(void) {
    if (g_tray_menu) {
        DestroyMenu(g_tray_menu);
        g_tray_menu = NULL;
    }
    
    if (g_hidden_window) {
        DestroyWindow(g_hidden_window);
        g_hidden_window = NULL;
    }
}