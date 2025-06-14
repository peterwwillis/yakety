#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "../app.h"
#include "../dialog.h"

void test_ready(void) {
    printf("About to show dialog...\n");
    
    // Use a small test file download for demonstration
    const char *model_name = "Test Model";
    const char *download_url = "https://httpbin.org/bytes/1024"; // Downloads 1KB of random data
    const char *file_path = "/tmp/test_download.bin";
    
    printf("Model: %s\n", model_name);
    printf("URL: %s\n", download_url);
    printf("Saving to: %s\n", file_path);
    printf("\n");
    
    int result = dialog_model_download(model_name, download_url, file_path);
    
    printf("\nDialog function returned: %d\n", result);
    
    switch (result) {
        case 0:
            printf("Download completed successfully!\n");
            // Check if file exists
            if (access(file_path, F_OK) == 0) {
                printf("Downloaded file exists at: %s\n", file_path);
                // Clean up test file
                unlink(file_path);
                printf("Test file cleaned up.\n");
            } else {
                printf("Warning: Downloaded file not found at expected location.\n");
            }
            break;
        case 1:
            printf("Download was cancelled by user.\n");
            break;
        case 2:
            printf("Download failed with an error.\n");
            break;
        default:
            printf("Unknown return code: %d\n", result);
            break;
    }
    
    app_cleanup();
    exit(0);
}

int main() {
    printf("Testing SwiftUI Download Dialog...\n");
    
    // Initialize the platform app (handles Cocoa setup on macOS)
    if (app_init("Download Dialog Test", "1.0", false, test_ready) != 0) {
        printf("Failed to initialize app\n");
        return 1;
    }
    
    // Start the app run loop - this will call test_ready when ready
    app_run();
    return 0;
}