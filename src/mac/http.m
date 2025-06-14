#include "../http.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreFoundation/CoreFoundation.h>
#include <stdlib.h>

// Simple download state - no complex async patterns
typedef struct {
    NSURLSessionDownloadTask* task;
    NSURLSession* session;
    bool is_cancelled;
    bool is_complete;
    bool download_success;
    NSError* download_error;
    DownloadProgressCallback progress_cb;
    DownloadCompleteCallback complete_cb;
    void* userdata;
    NSTimer* progress_timer;
} SimpleDownloadState;

DownloadHandle* http_download_start(const char* url, const char* destination,
                                   DownloadProgressCallback progress_cb,
                                   DownloadCompleteCallback complete_cb,
                                   void* userdata) {
    @autoreleasepool {
        DownloadHandle* handle = malloc(sizeof(DownloadHandle));
        handle->is_cancelled = false;
        handle->is_complete = false;
        
        SimpleDownloadState* state = malloc(sizeof(SimpleDownloadState));
        state->is_cancelled = false;
        state->is_complete = false;
        state->download_success = false;
        state->download_error = nil;
        state->task = nil;
        state->session = nil;
        state->progress_cb = progress_cb;
        state->complete_cb = complete_cb;
        state->userdata = userdata;
        state->progress_timer = nil;
        
        handle->internal_data = state;
        
        NSString *urlString = [NSString stringWithUTF8String:url];
        NSString *destPath = [NSString stringWithUTF8String:destination];
        NSURL *downloadURL = [NSURL URLWithString:urlString];
        
        if (!downloadURL) {
            if (complete_cb) {
                complete_cb(false, "Invalid URL", userdata);
            }
            free(state);
            free(handle);
            return NULL;
        }
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        [config setTimeoutIntervalForRequest:30.0];
        [config setTimeoutIntervalForResource:300.0];
        state->session = [NSURLSession sessionWithConfiguration:config];
        [state->session retain];
        
        state->task = [state->session downloadTaskWithURL:downloadURL
                                         completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error) {
                state->download_error = error;
                [state->download_error retain];
                state->download_success = false;
            } else if (location) {
                // Move file to destination
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *moveError = nil;
                [fileManager removeItemAtPath:destPath error:nil]; // Remove existing
                BOOL moved = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:destPath] error:&moveError];
                if (moved) {
                    state->download_success = true;
                } else {
                    state->download_error = moveError;
                    [state->download_error retain];
                    state->download_success = false;
                }
            }
            state->is_complete = true;
            handle->is_complete = true;
            
            // Stop progress timer
            if (state->progress_timer) {
                [state->progress_timer invalidate];
                state->progress_timer = nil;
            }
            
            // Call user completion callback if provided
            if (state->complete_cb) {
                const char* errorStr = NULL;
                if (state->download_error) {
                    errorStr = [[state->download_error localizedDescription] UTF8String];
                }
                state->complete_cb(state->download_success, errorStr, state->userdata);
            }
        }];
        
        [state->task resume];
        
        // Start progress timer if callback provided
        if (state->progress_cb) {
            state->progress_timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                     repeats:YES
                                                                       block:^(NSTimer *timer) {
                if (state->is_complete || state->is_cancelled) {
                    [timer invalidate];
                    return;
                }
                
                float progress = 0.0f;
                if (state->task.countOfBytesExpectedToReceive > 0) {
                    progress = (float)state->task.countOfBytesReceived / (float)state->task.countOfBytesExpectedToReceive;
                }
                
                state->progress_cb(progress, state->userdata);
            }];
        }
        
        return handle;
    }
}

float http_download_get_progress(DownloadHandle* handle) {
    if (!handle || !handle->internal_data) return 0.0f;
    
    SimpleDownloadState* state = (SimpleDownloadState*)handle->internal_data;
    if (!state->task) return 0.0f;
    
    if (state->task.countOfBytesExpectedToReceive > 0) {
        return (float)state->task.countOfBytesReceived / (float)state->task.countOfBytesExpectedToReceive;
    }
    return 0.0f;
}

bool http_download_is_complete(DownloadHandle* handle) {
    return handle ? handle->is_complete : true;
}

bool http_download_is_cancelled(DownloadHandle* handle) {
    return handle ? handle->is_cancelled : true;
}

bool http_download_was_successful(DownloadHandle* handle) {
    if (!handle || !handle->internal_data) return false;
    
    SimpleDownloadState* state = (SimpleDownloadState*)handle->internal_data;
    return state->download_success;
}

const char* http_download_get_error(DownloadHandle* handle) {
    if (!handle || !handle->internal_data) return "Invalid handle";
    
    SimpleDownloadState* state = (SimpleDownloadState*)handle->internal_data;
    if (state->download_error) {
        return [[state->download_error localizedDescription] UTF8String];
    }
    return NULL;
}

int http_download_wait(DownloadHandle* handle) {
    if (!handle) return 2;
    
    @autoreleasepool {
        while (!http_download_is_complete(handle) && !http_download_is_cancelled(handle)) {
            // For GUI apps, pump NSApp events. For CLI apps, just pump CFRunLoop
            if ([NSApp isRunning]) {
                // GUI app - pump NSApp events more frequently for responsiveness
                NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:0.01]; // 10ms timeout
                NSEvent *event;
                while ((event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                                   untilDate:timeout
                                                      inMode:NSDefaultRunLoopMode
                                                     dequeue:YES])) {
                    [NSApp sendEvent:event];
                    // Check if download was cancelled after each event
                    if (http_download_is_cancelled(handle)) {
                        break;
                    }
                }
            } else {
                // CLI app - pump CFRunLoop
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, true);
            }
            
            usleep(10000); // 10ms delay instead of 100ms
        }
        
        // Return result
        if (http_download_is_cancelled(handle)) {
            return 1; // Cancelled
        } else if (http_download_was_successful(handle)) {
            return 0; // Success
        } else {
            return 2; // Error
        }
    }
}

void http_download_cancel(DownloadHandle* handle) {
    if (handle && handle->internal_data) {
        SimpleDownloadState* state = (SimpleDownloadState*)handle->internal_data;
        
        state->is_cancelled = true;
        handle->is_cancelled = true;
        
        if (state->task) {
            [state->task cancel];
        }
    }
}

void http_download_cleanup(DownloadHandle* handle) {
    if (handle) {
        if (handle->internal_data) {
            SimpleDownloadState* state = (SimpleDownloadState*)handle->internal_data;
            
            // Stop progress timer
            if (state->progress_timer) {
                [state->progress_timer invalidate];
                state->progress_timer = nil;
            }
            
            if (state->session) {
                [state->session invalidateAndCancel];
                [state->session release];
                state->session = nil;
            }
            
            if (state->download_error) {
                [state->download_error release];
                state->download_error = nil;
            }
            
            free(state);
        }
        free(handle);
    }
}