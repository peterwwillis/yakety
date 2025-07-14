#include "dialog_framework.h"
#include "dialog_components.h"
#include "dialog_utils.h"
#include "logging.h"
#include <stdlib.h>
#include <string.h>
#include <wininet.h>

#pragma comment(lib, "wininet.lib")

// Download dialog state
typedef struct {
    BaseDialog* dialog;
    DialogComponent* header;
    DialogComponent* progress_bar;
    DialogComponent* cancel_button;
    
    char* model_name;
    char* download_url;
    char* file_path;
    int result;
    
    // Download state
    HANDLE download_thread;
    bool download_active;
    bool download_cancelled;
    float progress;
    char status_text[256];
} DownloadDialogState;

// Thread data for download
typedef struct {
    DownloadDialogState* dialog_state;
    char* url;
    char* file_path;
} DownloadThreadData;

// Forward declarations
static void on_dialog_event(BaseDialog* dialog, int event_type, void* data);
static void on_dialog_close(BaseDialog* dialog, int result);
static void on_cancel_button_click(DialogComponent* button, int button_id);
static void setup_download_dialog_layout(DownloadDialogState* state);
static DWORD WINAPI download_thread_proc(LPVOID param);
static void update_progress(DownloadDialogState* state, float progress, const char* status);
static void cleanup_download_dialog_state(DownloadDialogState* state);

int dialog_model_download_new(const char* model_name, const char* download_url, const char* file_path) {
    if (!dialog_framework_init()) {
        log_error("Failed to initialize dialog framework");
        return 2;
    }

    DownloadDialogState* state = (DownloadDialogState*)calloc(1, sizeof(DownloadDialogState));
    if (!state) {
        log_error("Failed to allocate download dialog state");
        return 2;
    }

    // Store download parameters
    state->model_name = _strdup(model_name);
    state->download_url = _strdup(download_url);
    state->file_path = _strdup(file_path);
    state->result = 2; // Default to error

    // Create title with model name
    char title[256];
    snprintf(title, sizeof(title), "Downloading %s", model_name);

    // Create dialog configuration
    DialogConfig config = {
        .title = title,
        .width = 400,
        .height = 200,
        .modal = true,
        .resizable = false,
        .parent = NULL,
        .event_callback = on_dialog_event,
        .close_callback = on_dialog_close,
        .user_data = state
    };

    // Create base dialog
    state->dialog = dialog_create(&config);
    if (!state->dialog) {
        log_error("Failed to create download dialog");
        cleanup_download_dialog_state(state);
        return 2;
    }

    // Setup dialog layout
    setup_download_dialog_layout(state);

    // Start download
    DownloadThreadData* thread_data = (DownloadThreadData*)malloc(sizeof(DownloadThreadData));
    if (thread_data) {
        thread_data->dialog_state = state;
        thread_data->url = _strdup(download_url);
        thread_data->file_path = _strdup(file_path);
        
        state->download_active = true;
        state->download_thread = CreateThread(NULL, 0, download_thread_proc, thread_data, 0, NULL);
    }

    // Show modal dialog
    int result = dialog_show_modal(state->dialog);
    int final_result = state->result;

    // Wait for download thread to complete
    if (state->download_thread) {
        state->download_cancelled = true;
        WaitForSingleObject(state->download_thread, 5000); // 5 second timeout
        CloseHandle(state->download_thread);
    }

    // Cleanup
    cleanup_download_dialog_state(state);
    log_info("Download dialog completed with result: %d", final_result);
    
    return final_result;
}

static void setup_download_dialog_layout(DownloadDialogState* state) {
    BaseDialog* dialog = state->dialog;
    float dpi = dialog->dpi_scale;
    int padding = dialog_scale_dpi(DIALOG_PADDING, dpi);
    int header_height = dialog_scale_dpi(DIALOG_HEADER_HEIGHT, dpi);
    int button_height = dialog_scale_dpi(DIALOG_BUTTON_HEIGHT, dpi);
    
    // Header component
    RECT header_rect = {
        0,
        dialog_scale_dpi(DIALOG_TITLE_BAR_HEIGHT, dpi),
        dialog->width,
        dialog_scale_dpi(DIALOG_TITLE_BAR_HEIGHT, dpi) + header_height
    };
    
    char header_title[256];
    snprintf(header_title, sizeof(header_title), "Downloading %s", 
             state->model_name ? state->model_name : "Model");
    state->header = header_component_create(dialog, header_title, &header_rect);

    // Progress bar component
    int progress_y = header_rect.bottom + padding;
    RECT progress_rect = {
        padding,
        progress_y,
        dialog->width - padding,
        progress_y + dialog_scale_dpi(50, dpi) // Height for progress bar + status text
    };
    state->progress_bar = progress_component_create(dialog, &progress_rect);
    progress_component_set_status(state->progress_bar, "Starting download...");

    // Cancel button at bottom
    int button_y = dialog->height - padding - button_height;
    int button_width = dialog_scale_dpi(80, dpi);
    
    RECT cancel_rect = {
        dialog->width - padding - button_width,
        button_y,
        dialog->width - padding,
        button_y + button_height
    };
    state->cancel_button = button_component_create(dialog, "Cancel", DIALOG_RESULT_CANCEL, 
                                                  &cancel_rect, false, on_cancel_button_click);
}

static DWORD WINAPI download_thread_proc(LPVOID param) {
    DownloadThreadData* thread_data = (DownloadThreadData*)param;
    DownloadDialogState* state = thread_data->dialog_state;
    
    log_info("Starting download: %s -> %s", thread_data->url, thread_data->file_path);

    // Create directory if it doesn't exist
    char* last_slash = strrchr(thread_data->file_path, '\\');
    if (last_slash) {
        *last_slash = '\0';
        CreateDirectoryA(thread_data->file_path, NULL);
        *last_slash = '\\';
    }

    // Initialize WinINet
    HINTERNET hInternet = InternetOpenA("Yakety/1.0", INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);
    if (!hInternet) {
        update_progress(state, 0.0f, "Failed to initialize download");
        state->result = 2;
        goto cleanup;
    }

    // Open URL
    HINTERNET hUrl = InternetOpenUrlA(hInternet, thread_data->url, NULL, 0, INTERNET_FLAG_RELOAD, 0);
    if (!hUrl) {
        update_progress(state, 0.0f, "Failed to open download URL");
        state->result = 2;
        goto cleanup;
    }

    // Get content length
    DWORD content_length = 0;
    DWORD buffer_size = sizeof(content_length);
    HttpQueryInfoA(hUrl, HTTP_QUERY_CONTENT_LENGTH | HTTP_QUERY_FLAG_NUMBER, 
                   &content_length, &buffer_size, NULL);

    // Open output file
    HANDLE hFile = CreateFileA(thread_data->file_path, GENERIC_WRITE, 0, NULL, 
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        update_progress(state, 0.0f, "Failed to create output file");
        state->result = 2;
        goto cleanup;
    }

    // Download data
    BYTE buffer[8192];
    DWORD bytes_read;
    DWORD total_bytes = 0;
    
    while (!state->download_cancelled && 
           InternetReadFile(hUrl, buffer, sizeof(buffer), &bytes_read) && 
           bytes_read > 0) {
        
        DWORD bytes_written;
        if (!WriteFile(hFile, buffer, bytes_read, &bytes_written, NULL)) {
            update_progress(state, 0.0f, "Failed to write to file");
            state->result = 2;
            break;
        }
        
        total_bytes += bytes_read;
        
        // Update progress
        float progress = content_length > 0 ? (float)total_bytes / content_length : 0.0f;
        char status[256];
        
        if (content_length > 0) {
            int percentage = (int)(progress * 100);
            snprintf(status, sizeof(status), "Downloaded %d%%", percentage);
        } else {
            snprintf(status, sizeof(status), "Downloaded %lu bytes", total_bytes);
        }
        
        update_progress(state, progress, status);
        
        // Small delay to prevent UI spam
        Sleep(50);
    }

    CloseHandle(hFile);

    if (state->download_cancelled) {
        // Delete partial file
        DeleteFileA(thread_data->file_path);
        update_progress(state, 0.0f, "Download cancelled");
        state->result = 1;
    } else if (total_bytes > 0) {
        update_progress(state, 1.0f, "Download complete");
        state->result = 0;
        
        // Disable cancel button
        dialog_component_set_enabled(state->cancel_button, false);
        
        // Auto-close after a brief delay
        Sleep(1000);
        PostMessage(state->dialog->hwnd, WM_CLOSE, 0, 0);
    } else {
        update_progress(state, 0.0f, "Download failed");
        state->result = 2;
    }

cleanup:
    if (hUrl) InternetCloseHandle(hUrl);
    if (hInternet) InternetCloseHandle(hInternet);
    
    // Cleanup thread data
    free(thread_data->url);
    free(thread_data->file_path);
    free(thread_data);
    
    state->download_active = false;
    return 0;
}

static void update_progress(DownloadDialogState* state, float progress, const char* status) {
    if (!state || !state->progress_bar) return;

    // Update progress bar
    progress_component_set_progress(state->progress_bar, progress);
    progress_component_set_status(state->progress_bar, status);
    
    // Store status for logging
    strncpy_s(state->status_text, sizeof(state->status_text), status, _TRUNCATE);
    state->progress = progress;
}

static void on_dialog_event(BaseDialog* dialog, int event_type, void* data) {
    DownloadDialogState* state = (DownloadDialogState*)dialog->user_data;
    if (!state) return;

    switch (event_type) {
    case DIALOG_EVENT_PAINT: {
        HDC hdc = (HDC)data;
        
        // Paint background and header
        char title[256];
        snprintf(title, sizeof(title), "Downloading %s", 
                 state->model_name ? state->model_name : "Model");
        dialog_paint_background(dialog, hdc, title);
        
        // Paint all components
        if (state->header) dialog_component_paint(state->header, hdc);
        if (state->progress_bar) dialog_component_paint(state->progress_bar, hdc);
        if (state->cancel_button) dialog_component_paint(state->cancel_button, hdc);
        break;
    }
    
    case DIALOG_EVENT_DPI_CHANGED:
        // Re-layout components for new DPI
        setup_download_dialog_layout(state);
        break;
    }
}

static void on_dialog_close(BaseDialog* dialog, int result) {
    DownloadDialogState* state = (DownloadDialogState*)dialog->user_data;
    if (!state) return;

    state->download_cancelled = true;
    dialog_destroy(dialog);
}

static void on_cancel_button_click(DialogComponent* button, int button_id) {
    DownloadDialogState* state = (DownloadDialogState*)button->dialog->user_data;
    if (!state) return;

    state->download_cancelled = true;
    state->result = 1; // Cancelled
    
    // Close dialog
    PostMessage(button->dialog->hwnd, WM_CLOSE, button_id, 0);
}

static void cleanup_download_dialog_state(DownloadDialogState* state) {
    if (!state) return;

    // Cleanup components
    if (state->header) dialog_component_destroy(state->header);
    if (state->progress_bar) dialog_component_destroy(state->progress_bar);
    if (state->cancel_button) dialog_component_destroy(state->cancel_button);

    // Cleanup strings
    free(state->model_name);
    free(state->download_url);
    free(state->file_path);

    free(state);
}