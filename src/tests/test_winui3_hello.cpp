#include <windows.h>
#include <stdio.h>
#include <iostream>

// Basic WinRT includes that should be in Windows SDK
#include <winrt/base.h>
#include <winrt/Windows.Foundation.h>

using namespace winrt;
using namespace Windows::Foundation;

// Simple WinRT Hello World test to verify we can build and link against WinRT
// This test initializes WinRT and creates a basic message

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int)
{
    printf("Starting WinRT test application...\n");
    
    try {
        // Initialize WinRT
        init_apartment(apartment_type::single_threaded);
        
        printf("WinRT initialized successfully!\n");
        
        // Test basic WinRT functionality
        auto uri = Uri(L"https://github.com/badlogic/yakety");
        printf("Created WinRT URI: %ws\n", uri.ToString().c_str());
        
        // Create a simple window using Win32 API to verify basic functionality
        HWND hwnd = CreateWindow(
            L"STATIC",
            L"Yakety WinRT Test - Success!",
            WS_OVERLAPPEDWINDOW | WS_VISIBLE,
            CW_USEDEFAULT, CW_USEDEFAULT, 400, 200,
            nullptr, nullptr, GetModuleHandle(nullptr), nullptr
        );
        
        if (hwnd) {
            printf("Win32 window created successfully!\n");
            MessageBox(hwnd, L"WinRT and Win32 integration test successful!\n\nThis confirms:\n✓ WinRT headers are available\n✓ C++20 compilation works\n✓ windowsapp.lib linking works", L"Yakety WinRT Test", MB_OK | MB_ICONINFORMATION);
            DestroyWindow(hwnd);
        }
        
        printf("WinRT test completed successfully!\n");
        
    } catch (...) {
        printf("WinRT test failed with exception\n");
        return 1;
    }
    
    return 0;
}