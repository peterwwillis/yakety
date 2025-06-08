#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#include "../app.h"
#include "../overlay.h"

static AppConfig g_config = {0};
static volatile bool g_running = true;
bool g_is_console = false;  // Global for logging module

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    
    // Switch to accessory mode after launch for tray apps
    if (!g_config.is_console) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    }
    
    // The app is now ready - call the callback if provided
    if (g_config.on_ready) {
        g_config.on_ready();
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return NO;  // Keep running in the background
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    (void)sender;
    g_running = false;
    return NSTerminateNow;
}

@end

static AppDelegate* g_app_delegate = nil;

int app_init(const AppConfig* config) {
    g_config = *config;
    g_is_console = config->is_console;

    // Initialize NSApplication
    [NSApplication sharedApplication];

    if (config->is_console) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    } else {
        // For tray apps, start as regular to ensure UI works properly
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        
        g_app_delegate = [[AppDelegate alloc] init];
        [NSApp setDelegate:g_app_delegate];
    }

    return 0;
}

void app_cleanup(void) {
    g_app_delegate = nil;
}

void app_run(void) {
    if (g_config.is_console) {
        // For console apps, just pump the run loop
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, false);
    } else {
        // For tray apps, run the full NSApplication run loop
        [NSApp run];
    }
}

void app_quit(void) {
    g_running = false;

    if (!g_config.is_console) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSApp terminate:nil];
        });
    }
}