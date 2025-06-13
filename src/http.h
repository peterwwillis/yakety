#ifndef HTTP_H
#define HTTP_H

#include <stddef.h>
#include <stdbool.h>

// Download progress callback
typedef void (*DownloadProgressCallback)(float progress, void* userdata);

// Download completion callback
typedef void (*DownloadCompleteCallback)(bool success, const char* error, void* userdata);

// Download handle for cancellation
typedef struct {
    bool is_cancelled;
    bool is_complete;
    void* internal_data;
} DownloadHandle;

// Start a download (callbacks can be NULL for polling mode)
DownloadHandle* http_download_start(const char* url, const char* destination,
                                   DownloadProgressCallback progress_cb,
                                   DownloadCompleteCallback complete_cb,
                                   void* userdata);

// Polling functions for simple usage without callbacks
float http_download_get_progress(DownloadHandle* handle);
bool http_download_is_complete(DownloadHandle* handle);
bool http_download_is_cancelled(DownloadHandle* handle);
bool http_download_was_successful(DownloadHandle* handle);
const char* http_download_get_error(DownloadHandle* handle);

// Wait for download to complete while pumping UI events
// Returns: 0 = success, 1 = cancelled, 2 = error
int http_download_wait(DownloadHandle* handle);

// Cancel an ongoing download
void http_download_cancel(DownloadHandle* handle);

// Cleanup download handle
void http_download_cleanup(DownloadHandle* handle);

#endif // HTTP_H