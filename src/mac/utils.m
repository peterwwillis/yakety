#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include "../utils.h"
#include "../logging.h"
#include <sys/time.h>
#include <unistd.h>
#include <string.h>

double utils_get_time(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec * 1e-6;
}

void utils_sleep_ms(int milliseconds) {
    usleep(milliseconds * 1000);
}

const char* utils_get_model_path(void) {
    static char model_path[PATH_MAX] = {0};
    
    log_info("🔍 Searching for Whisper model...\n");
    
    @autoreleasepool {
        // First check current directory
        log_info("  Checking current directory: ggml-base.en.bin\n");
        if (access("ggml-base.en.bin", F_OK) == 0) {
            log_info("  ✅ Found in current directory\n");
            return "ggml-base.en.bin";
        }
        
        // Check in app bundle Resources
        NSBundle* bundle = [NSBundle mainBundle];
        NSString* bundlePath = [bundle bundlePath];
        log_info("  Bundle path: %s\n", [bundlePath UTF8String]);
        
        // Check Resources/models/ggml-base.en.bin (where CMake puts it)
        NSString* resourceModelPath = [bundle pathForResource:@"models/ggml-base.en" ofType:@"bin"];
        if (resourceModelPath) {
            log_info("  ✅ Found in bundle Resources/models: %s\n", [resourceModelPath UTF8String]);
            strncpy(model_path, [resourceModelPath UTF8String], PATH_MAX - 1);
            return model_path;
        }
        
        // Check Resources/ggml-base.en.bin
        NSString* resourcePath = [bundle pathForResource:@"ggml-base.en" ofType:@"bin"];
        if (resourcePath) {
            log_info("  ✅ Found in bundle Resources: %s\n", [resourcePath UTF8String]);
            strncpy(model_path, [resourcePath UTF8String], PATH_MAX - 1);
            return model_path;
        }
        
        // Check in executable directory
        NSString* execPath = [bundle executablePath];
        NSString* execDir = [execPath stringByDeletingLastPathComponent];
        log_info("  Executable directory: %s\n", [execDir UTF8String]);
        
        // Check models subdirectory in executable directory
        NSString* modelsDir = [execDir stringByAppendingPathComponent:@"models"];
        NSString* modelInModelsDir = [modelsDir stringByAppendingPathComponent:@"ggml-base.en.bin"];
        log_info("  Checking: %s\n", [modelInModelsDir UTF8String]);
        if ([[NSFileManager defaultManager] fileExistsAtPath:modelInModelsDir]) {
            log_info("  ✅ Found in executable directory/models\n");
            strncpy(model_path, [modelInModelsDir UTF8String], PATH_MAX - 1);
            return model_path;
        }
        
        // Check directly in executable directory
        NSString* modelInExecDir = [execDir stringByAppendingPathComponent:@"ggml-base.en.bin"];
        log_info("  Checking: %s\n", [modelInExecDir UTF8String]);
        if ([[NSFileManager defaultManager] fileExistsAtPath:modelInExecDir]) {
            log_info("  ✅ Found in executable directory\n");
            strncpy(model_path, [modelInExecDir UTF8String], PATH_MAX - 1);
            return model_path;
        }
        
        // Check in build directory (parent of executable directory)
        NSString* buildPath = [[execDir stringByDeletingLastPathComponent] 
                               stringByAppendingPathComponent:@"ggml-base.en.bin"];
        log_info("  Checking: %s\n", [buildPath UTF8String]);
        if ([[NSFileManager defaultManager] fileExistsAtPath:buildPath]) {
            log_info("  ✅ Found in build directory\n");
            strncpy(model_path, [buildPath UTF8String], PATH_MAX - 1);
            return model_path;
        }
        
        // Check whisper.cpp/models directory relative to current directory
        NSString* whisperModelsPath = @"whisper.cpp/models/ggml-base.en.bin";
        log_info("  Checking: %s\n", [whisperModelsPath UTF8String]);
        if ([[NSFileManager defaultManager] fileExistsAtPath:whisperModelsPath]) {
            log_info("  ✅ Found in whisper.cpp/models\n");
            strncpy(model_path, [whisperModelsPath UTF8String], PATH_MAX - 1);
            return model_path;
        }
        
        // Check relative to executable's parent parent (for build/bin structure)
        NSString* projectRoot = [[execDir stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        NSString* whisperModelsFromRoot = [projectRoot stringByAppendingPathComponent:@"whisper.cpp/models/ggml-base.en.bin"];
        log_info("  Checking: %s\n", [whisperModelsFromRoot UTF8String]);
        if ([[NSFileManager defaultManager] fileExistsAtPath:whisperModelsFromRoot]) {
            log_info("  ✅ Found relative to project root\n");
            strncpy(model_path, [whisperModelsFromRoot UTF8String], PATH_MAX - 1);
            return model_path;
        }
    }
    
    log_error("  ❌ Model not found in any location!\n");
    return NULL;
}

void utils_open_accessibility_settings(void) {
    @autoreleasepool {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]];
    }
}

void* utils_get_app_icon(void) {
    @autoreleasepool {
        log_info("🎨 Loading app icon...\n");
        
        // First try to get the standard application icon
        NSImage* icon = [NSImage imageNamed:NSImageNameApplicationIcon];
        if (icon) {
            log_info("  ✅ Loaded icon using NSImageNameApplicationIcon\n");
            [icon retain];
            return (void*)icon;
        }
        
        // Get bundle info for debugging
        NSBundle* bundle = [NSBundle mainBundle];
        log_info("  Bundle path: %s\n", [[bundle bundlePath] UTF8String]);
        log_info("  Resource path: %s\n", [[bundle resourcePath] UTF8String]);
        
        // Try multiple approaches to find the icon
        // 1. Use CFBundleIconFile from Info.plist
        NSString* iconName = [bundle objectForInfoDictionaryKey:@"CFBundleIconFile"];
        log_info("  CFBundleIconFile from Info.plist: %s\n", iconName ? [iconName UTF8String] : "nil");
        
        if (iconName) {
            // Try loading by name
            icon = [NSImage imageNamed:iconName];
            if (icon) {
                log_info("  ✅ Loaded icon using imageNamed:%s\n", [iconName UTF8String]);
                [icon retain];
            return (void*)icon;
            }
            
            // Try with .icns extension
            NSString* iconPath = [bundle pathForResource:iconName ofType:@"icns"];
            log_info("  Trying pathForResource:%s ofType:icns -> %s\n", 
                    [iconName UTF8String], iconPath ? [iconPath UTF8String] : "nil");
            if (iconPath) {
                icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
                if (icon) {
                    log_info("  ✅ Loaded icon from path: %s\n", [iconPath UTF8String]);
                    [icon retain];
            return (void*)icon;
                }
            }
        }
        
        // 2. Try direct path to yakety.icns
        NSString* directPath = [bundle pathForResource:@"yakety" ofType:@"icns"];
        log_info("  Trying pathForResource:yakety ofType:icns -> %s\n", 
                directPath ? [directPath UTF8String] : "nil");
        if (directPath) {
            icon = [[NSImage alloc] initWithContentsOfFile:directPath];
            if (icon) {
                log_info("  ✅ Loaded icon from direct path: %s\n", [directPath UTF8String]);
                [icon retain];
            return (void*)icon;
            }
        }
        
        // 3. Try loading from Resources directory
        NSString* resourcePath = [[bundle resourcePath] stringByAppendingPathComponent:@"yakety.icns"];
        log_info("  Trying Resources/yakety.icns -> %s\n", [resourcePath UTF8String]);
        
        // Check if file exists
        NSFileManager* fm = [NSFileManager defaultManager];
        BOOL exists = [fm fileExistsAtPath:resourcePath];
        log_info("  File exists: %s\n", exists ? "YES" : "NO");
        
        if (exists) {
            icon = [[NSImage alloc] initWithContentsOfFile:resourcePath];
            if (icon) {
                log_info("  ✅ Loaded icon from Resources directory\n");
                [icon retain];
            return (void*)icon;
            } else {
                log_error("  ❌ File exists but failed to load as NSImage\n");
            }
        }
        
        // 4. Last resort - check all resources for .icns files
        NSArray* icnsFiles = [bundle pathsForResourcesOfType:@"icns" inDirectory:nil];
        log_info("  Found %lu .icns files in bundle\n", (unsigned long)[icnsFiles count]);
        for (NSString* path in icnsFiles) {
            log_info("    - %s\n", [path UTF8String]);
        }
        
        log_error("  ❌ Failed to load app icon from any source!\n");
        return NULL;
    }
}