#include "../dialog.h"
#include "../http.h"
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import <IOKit/hidsystem/IOHIDLib.h>


void dialog_error(const char *title, const char *message) {
    @autoreleasepool {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithUTF8String:title]];
        [alert setInformativeText:[NSString stringWithUTF8String:message]];
        [alert setAlertStyle:NSAlertStyleCritical];
        [alert runModal];
    }
}

void dialog_info(const char *title, const char *message) {
    @autoreleasepool {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithUTF8String:title]];
        [alert setInformativeText:[NSString stringWithUTF8String:message]];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert runModal];
    }
}

bool dialog_confirm(const char *title, const char *message) {
    @autoreleasepool {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithUTF8String:title]];
        [alert setInformativeText:[NSString stringWithUTF8String:message]];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        return [alert runModal] == NSAlertFirstButtonReturn;
    }
}

// Permission dialogs are now handled by src/mac/permissions.m

// Note: dialog_keycombination_capture, dialog_models_and_language, and dialog_model_download
// are now implemented directly in Swift using @_cdecl and will be linked automatically

