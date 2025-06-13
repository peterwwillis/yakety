#include "download_dialog.h"
#include "../../app.h"
#include "../../http.h"
#import <objc/runtime.h>

// Context for progress callbacks
typedef struct {
    NSProgressIndicator *progressBar;
    NSTextField *statusLabel;
} DownloadDialogContext;

// Progress callback
static void download_progress_callback(float progress, void *userdata) {
    DownloadDialogContext *ctx = (DownloadDialogContext *) userdata;

    dispatch_async(dispatch_get_main_queue(), ^{
      [ctx->progressBar setDoubleValue:progress];
      [ctx->statusLabel setStringValue:[NSString stringWithFormat:@"%.0f%% complete", progress * 100]];
    });
}

// Completion callback
static void download_complete_callback(bool success, const char *error, void *userdata) {
    DownloadDialogContext *ctx = (DownloadDialogContext *) userdata;

    dispatch_async(dispatch_get_main_queue(), ^{
      if (success) {
          [ctx->statusLabel setStringValue:@"Download completed!"];
      } else {
          NSString *errorMsg = error ? [NSString stringWithUTF8String:error] : @"Unknown error";
          [ctx->statusLabel setStringValue:[NSString stringWithFormat:@"Failed: %@", errorMsg]];
      }
    });
}

// Cancel button action
@interface NSButton (DownloadCancel)
- (void)cancelDownloadClicked:(id)sender;
@end

@implementation NSButton (DownloadCancel)
- (void)cancelDownloadClicked:(id)sender {
    NSValue *handleValue = objc_getAssociatedObject(sender, "downloadHandle");
    NSTextField *statusLabel = objc_getAssociatedObject(sender, "statusLabel");

    if (handleValue) {
        DownloadHandle *handle = (DownloadHandle *) [handleValue pointerValue];
        [statusLabel setStringValue:@"Cancelling..."];
        http_download_cancel(handle);
    }
}
@end

int download_dialog_show(const char *model_name, const char *download_url, const char *file_path) {
    @autoreleasepool {
        // Create download progress dialog - reduced height
        NSRect progressFrame = NSMakeRect(0, 0, 500, 180);
        NSWindow *progressWindow =
            [[NSWindow alloc] initWithContentRect:progressFrame
                                        styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                          backing:NSBackingStoreBuffered
                                            defer:NO];
        [progressWindow setTitle:@"Downloading Model"];
        [progressWindow center];

        dialog_setup_window_appearance(progressWindow);
        NSView *progressContentView = [progressWindow contentView];

        // App icon in top-left corner
        NSImageView *iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(20, 130, 32, 32)];
        NSImage *appIcon = [NSApp applicationIconImage];
        if (appIcon) {
            [iconView setImage:appIcon];
            [progressContentView addSubview:iconView];
        }

        // Title
        NSTextField *titleLabel = dialog_create_title_label([NSString stringWithFormat:@"Downloading %s", model_name],
                                                            NSMakeRect(60, 130, 420, 25));
        [titleLabel setFont:[NSFont boldSystemFontOfSize:18]];
        [progressContentView addSubview:titleLabel];

        // URL info
        NSTextField *urlLabel = dialog_create_description_label([NSString stringWithFormat:@"From: %s", download_url],
                                                                NSMakeRect(20, 105, 460, 18));
        [progressContentView addSubview:urlLabel];

        // Progress bar
        NSProgressIndicator *progressBar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 75, 460, 20)];
        [progressBar setStyle:NSProgressIndicatorStyleBar];
        [progressBar setIndeterminate:NO];
        [progressBar setMinValue:0.0];
        [progressBar setMaxValue:1.0];
        [progressBar setDoubleValue:0.0];
        [progressBar setUsesThreadedAnimation:YES];
        [progressContentView addSubview:progressBar];

        // Status label
        NSTextField *statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 50, 460, 20)];
        [statusLabel setStringValue:@"Preparing download..."];
        [statusLabel setBordered:NO];
        [statusLabel setEditable:NO];
        [statusLabel setSelectable:NO];
        [statusLabel setBackgroundColor:[NSColor clearColor]];
        [statusLabel setTextColor:DIALOG_SECONDARY_TEXT_COLOR];
        [statusLabel setFont:[NSFont systemFontOfSize:12]];
        [progressContentView addSubview:statusLabel];

        // Context for callbacks - heap allocated to survive function return
        DownloadDialogContext *ctx = malloc(sizeof(DownloadDialogContext));
        ctx->progressBar = progressBar;
        ctx->statusLabel = statusLabel;

        // Cancel button
        NSButton *cancelButton =
            dialog_create_button(@"Cancel", NSMakeRect(200, 30, 100, 35), [NSColor systemRedColor]);
        [cancelButton setTarget:cancelButton];
        [cancelButton setAction:@selector(cancelDownloadClicked:)];
        [progressContentView addSubview:cancelButton];

        // Show window
        [NSApp activateIgnoringOtherApps:YES];
        [progressWindow makeKeyAndOrderFront:nil];

        // Create directory if it doesn't exist
        NSString *filePath = [NSString stringWithUTF8String:file_path];
        NSString *dirPath = [filePath stringByDeletingLastPathComponent];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];

        // Start download with callbacks
        [statusLabel setStringValue:@"Starting download..."];
        DownloadHandle *downloadHandle =
            http_download_start(download_url, file_path, download_progress_callback, download_complete_callback, ctx);

        if (!downloadHandle) {
            [progressWindow close];
            free(ctx);
            return 2; // Error starting download
        }

        // Associate download handle with cancel button
        objc_setAssociatedObject(cancelButton, "downloadHandle", [NSValue valueWithPointer:downloadHandle],
                                 OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(cancelButton, "statusLabel", statusLabel, OBJC_ASSOCIATION_ASSIGN);

        // Let http_download_wait handle all the event pumping!
        int result = http_download_wait(downloadHandle);

        // Cleanup
        http_download_cleanup(downloadHandle);
        [progressWindow close];

        // Free the heap-allocated context
        free(ctx);

        return result;
    }
}