#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#include "../platform.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void platform_copy_to_clipboard(const char* text) {
    @autoreleasepool {
        NSString* string = [NSString stringWithUTF8String:text];
        NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:string forType:NSPasteboardTypeString];
    }
}

void platform_paste_text(void) {
    @autoreleasepool {
        // Simulate Cmd+V
        CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
        
        CGEventRef cmdDown = CGEventCreateKeyboardEvent(source, kVK_Command, true);
        CGEventRef vDown = CGEventCreateKeyboardEvent(source, kVK_ANSI_V, true);
        CGEventRef vUp = CGEventCreateKeyboardEvent(source, kVK_ANSI_V, false);
        CGEventRef cmdUp = CGEventCreateKeyboardEvent(source, kVK_Command, false);
        
        CGEventSetFlags(vDown, kCGEventFlagMaskCommand);
        CGEventSetFlags(vUp, kCGEventFlagMaskCommand);
        
        CGEventPost(kCGHIDEventTap, cmdDown);
        CGEventPost(kCGHIDEventTap, vDown);
        CGEventPost(kCGHIDEventTap, vUp);
        CGEventPost(kCGHIDEventTap, cmdUp);
        
        CFRelease(cmdDown);
        CFRelease(vDown);
        CFRelease(vUp);
        CFRelease(cmdUp);
        CFRelease(source);
    }
}

void platform_show_error(const char* title, const char* message) {
    @autoreleasepool {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithUTF8String:title]];
        [alert setInformativeText:[NSString stringWithUTF8String:message]];
        [alert setAlertStyle:NSAlertStyleCritical];
        [alert runModal];
    }
}

void platform_show_info(const char* title, const char* message) {
    @autoreleasepool {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithUTF8String:title]];
        [alert setInformativeText:[NSString stringWithUTF8String:message]];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert runModal];
    }
}

int platform_init(void) {
    // macOS permission checks are handled in audio_permissions.m
    return 0;
}

const char* platform_find_model_path(void) {
    static char model_path[PATH_MAX] = {0};
    
    @autoreleasepool {
        // First check current directory
        if (access("ggml-base.en.bin", F_OK) == 0) {
            return "ggml-base.en.bin";
        }
        
        // Check in app bundle Resources
        NSBundle* bundle = [NSBundle mainBundle];
        NSString* resourcePath = [bundle pathForResource:@"ggml-base.en" ofType:@"bin"];
        if (resourcePath) {
            strncpy(model_path, [resourcePath UTF8String], PATH_MAX - 1);
            return model_path;
        }
        
        // Check in executable directory
        NSString* execPath = [bundle executablePath];
        NSString* execDir = [execPath stringByDeletingLastPathComponent];
        NSString* modelInExecDir = [execDir stringByAppendingPathComponent:@"ggml-base.en.bin"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:modelInExecDir]) {
            strncpy(model_path, [modelInExecDir UTF8String], PATH_MAX - 1);
            return model_path;
        }
        
        // Check in build directory
        NSString* buildPath = [[execDir stringByDeletingLastPathComponent] 
                               stringByAppendingPathComponent:@"ggml-base.en.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:buildPath]) {
            strncpy(model_path, [buildPath UTF8String], PATH_MAX - 1);
            return model_path;
        }
    }
    
    return NULL;
}

void platform_console_print(const char* message) {
    printf("%s", message);
    fflush(stdout);
}

bool platform_console_init(void) {
    // macOS console doesn't need special initialization
    return true;
}