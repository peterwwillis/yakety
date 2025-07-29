#include "../utils.h"
#include "../logging.h"
#include "../preferences.h"
#include "dispatch.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>
#include <pthread.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>

double utils_get_time(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec * 1e-6;
}

double utils_now(void) {
    static double start_time = -1.0;

    if (start_time < 0) {
        start_time = utils_get_time();
    }

    return utils_get_time() - start_time;
}

void utils_sleep_ms(int milliseconds) {
    usleep(milliseconds * 1000);
}

const char *utils_get_model_path(void) {
    static char model_path[PATH_MAX] = {0};

    // Check if we have a model path from preferences
    const char *config_model = preferences_get_string("model");
    if (config_model && strlen(config_model) > 0) {
        if (access(config_model, F_OK) == 0) {
            strncpy(model_path, config_model, PATH_MAX - 1);
            return model_path;
        }
    }

    @autoreleasepool {
        // First check current directory
        if (access("ggml-base-q8_0.bin", F_OK) == 0) {
            return "ggml-base-q8_0.bin";
        }

        // Check in app bundle Resources
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *bundlePath = [bundle bundlePath];

        // Check Resources/models/ggml-base-q8_0.bin (where CMake puts it)
        NSString *resourceModelPath = [bundle pathForResource:@"models/ggml-base-q8_0" ofType:@"bin"];
        if (resourceModelPath) {
            strncpy(model_path, [resourceModelPath UTF8String], PATH_MAX - 1);
            return model_path;
        }

        // Check Resources/ggml-base-q8_0.bin
        NSString *resourcePath = [bundle pathForResource:@"ggml-base-q8_0" ofType:@"bin"];
        if (resourcePath) {
            strncpy(model_path, [resourcePath UTF8String], PATH_MAX - 1);
            return model_path;
        }

        // Check in executable directory
        NSString *execPath = [bundle executablePath];
        NSString *execDir = [execPath stringByDeletingLastPathComponent];

        // Check models subdirectory in executable directory
        NSString *modelsDir = [execDir stringByAppendingPathComponent:@"models"];
        NSString *modelInModelsDir = [modelsDir stringByAppendingPathComponent:@"ggml-base-q8_0.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:modelInModelsDir]) {
            strncpy(model_path, [modelInModelsDir UTF8String], PATH_MAX - 1);
            return model_path;
        }

        // Check directly in executable directory
        NSString *modelInExecDir = [execDir stringByAppendingPathComponent:@"ggml-base-q8_0.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:modelInExecDir]) {
            strncpy(model_path, [modelInExecDir UTF8String], PATH_MAX - 1);
            return model_path;
        }

        // Check in build directory (parent of executable directory)
        NSString *buildPath =
            [[execDir stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ggml-base-q8_0.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:buildPath]) {
            strncpy(model_path, [buildPath UTF8String], PATH_MAX - 1);
            return model_path;
        }

        // Check whisper.cpp/models directory relative to current directory
        NSString *whisperModelsPath = @"whisper.cpp/models/ggml-base-q8_0.bin";
        if ([[NSFileManager defaultManager] fileExistsAtPath:whisperModelsPath]) {
            strncpy(model_path, [whisperModelsPath UTF8String], PATH_MAX - 1);
            return model_path;
        }

        // Check relative to executable's parent parent (for build/bin structure)
        NSString *projectRoot = [[execDir stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        NSString *whisperModelsFromRoot =
            [projectRoot stringByAppendingPathComponent:@"whisper.cpp/models/ggml-base-q8_0.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:whisperModelsFromRoot]) {
            strncpy(model_path, [whisperModelsFromRoot UTF8String], PATH_MAX - 1);
            return model_path;
        }
    }

    return NULL;
}

const char *utils_get_vad_model_path(void) {
    static char vad_model_path[PATH_MAX] = {0};
    
    @autoreleasepool {
        // First check current directory
        if (access("silero-v5.1.2-ggml.bin", F_OK) == 0) {
            return "silero-v5.1.2-ggml.bin";
        }

        // Check in app bundle Resources
        NSBundle *bundle = [NSBundle mainBundle];
        
        // Check Resources/models/silero-v5.1.2-ggml.bin (where CMake puts it)
        NSString *resourceModelPath = [bundle pathForResource:@"models/silero-v5.1.2-ggml" ofType:@"bin"];
        if (resourceModelPath) {
            strncpy(vad_model_path, [resourceModelPath UTF8String], PATH_MAX - 1);
            return vad_model_path;
        }

        // Check Resources/silero-v5.1.2-ggml.bin
        NSString *resourcePath = [bundle pathForResource:@"silero-v5.1.2-ggml" ofType:@"bin"];
        if (resourcePath) {
            strncpy(vad_model_path, [resourcePath UTF8String], PATH_MAX - 1);
            return vad_model_path;
        }

        // Check in executable directory
        NSString *execPath = [bundle executablePath];
        NSString *execDir = [execPath stringByDeletingLastPathComponent];

        // Check models subdirectory in executable directory
        NSString *modelsDir = [execDir stringByAppendingPathComponent:@"models"];
        NSString *modelInModelsDir = [modelsDir stringByAppendingPathComponent:@"silero-v5.1.2-ggml.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:modelInModelsDir]) {
            strncpy(vad_model_path, [modelInModelsDir UTF8String], PATH_MAX - 1);
            return vad_model_path;
        }

        // Check directly in executable directory
        NSString *modelInExecDir = [execDir stringByAppendingPathComponent:@"silero-v5.1.2-ggml.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:modelInExecDir]) {
            strncpy(vad_model_path, [modelInExecDir UTF8String], PATH_MAX - 1);
            return vad_model_path;
        }

        // Check whisper.cpp/models directory relative to current directory
        NSString *whisperModelsPath = @"whisper.cpp/models/for-tests-silero-v5.1.2-ggml.bin";
        if ([[NSFileManager defaultManager] fileExistsAtPath:whisperModelsPath]) {
            strncpy(vad_model_path, [whisperModelsPath UTF8String], PATH_MAX - 1);
            return vad_model_path;
        }

        // Check relative to executable's parent parent (for build/bin structure)
        NSString *projectRoot = [[execDir stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        NSString *whisperModelsFromRoot =
            [projectRoot stringByAppendingPathComponent:@"whisper.cpp/models/for-tests-silero-v5.1.2-ggml.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:whisperModelsFromRoot]) {
            strncpy(vad_model_path, [whisperModelsFromRoot UTF8String], PATH_MAX - 1);
            return vad_model_path;
        }
    }

    return NULL;
}

// Permission settings opening is now handled by src/mac/permissions.m

bool utils_is_launch_at_login_enabled(void) {
    @autoreleasepool {
        // Use SMAppService for macOS 13.0+, fall back to older method for earlier versions
        if (@available(macOS 13.0, *)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
            NSError *error = nil;
            SMAppService *service = [SMAppService mainAppService];
            SMAppServiceStatus status = [service status];
            return status == SMAppServiceStatusEnabled;
#pragma clang diagnostic pop
        } else {
            // For older macOS versions, check LaunchAgents
            NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
            NSString *launchAgentPath =
                [NSString stringWithFormat:@"%@/Library/LaunchAgents/%@.plist", NSHomeDirectory(), bundleID];
            return [[NSFileManager defaultManager] fileExistsAtPath:launchAgentPath];
        }
    }
}

bool utils_set_launch_at_login(bool enabled) {
    @autoreleasepool {
        // Use SMAppService for macOS 13.0+, fall back to older method for earlier versions
        if (@available(macOS 13.0, *)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
            NSError *error = nil;
            SMAppService *service = [SMAppService mainAppService];

            if (enabled) {
                if ([service registerAndReturnError:&error]) {
                    log_info("Successfully enabled launch at login\n");
                    return true;
                } else {
                    log_error("Failed to enable launch at login: %s\n", [[error localizedDescription] UTF8String]);
                    return false;
                }
            } else {
                if ([service unregisterAndReturnError:&error]) {
                    log_info("Successfully disabled launch at login\n");
                    return true;
                } else {
                    log_error("Failed to disable launch at login: %s\n", [[error localizedDescription] UTF8String]);
                    return false;
                }
            }
#pragma clang diagnostic pop
        } else {
            // For older macOS versions, use LaunchAgents
            NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
            NSString *appPath = [[NSBundle mainBundle] bundlePath];
            NSString *launchAgentPath =
                [NSString stringWithFormat:@"%@/Library/LaunchAgents/%@.plist", NSHomeDirectory(), bundleID];

            if (enabled) {
                // Create LaunchAgent plist
                NSDictionary *plist = @{
                    @"Label" : bundleID,
                    @"ProgramArguments" : @[ appPath ],
                    @"RunAtLoad" : @YES,
                    @"LSUIElement" : @YES
                };

                // Create LaunchAgents directory if needed
                NSString *launchAgentsDir = [launchAgentPath stringByDeletingLastPathComponent];
                [[NSFileManager defaultManager] createDirectoryAtPath:launchAgentsDir
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:nil];

                // Write plist
                return [plist writeToFile:launchAgentPath atomically:YES];
            } else {
                // Remove LaunchAgent plist
                NSError *error = nil;
                return [[NSFileManager defaultManager] removeItemAtPath:launchAgentPath error:&error];
            }
        }
    }
}

// Async work implementation
#include <pthread.h>

typedef struct {
    async_work_fn work;
    void *arg;
    async_callback_fn callback;
} AsyncWorkData;

static void *async_work_thread(void *data) {
    AsyncWorkData *work_data = (AsyncWorkData *) data;
    void *result = work_data->work(work_data->arg);

    // Schedule callback on main thread
    app_dispatch_main(^{
      work_data->callback(result);
      free(work_data);
    });

    return NULL;
}

void utils_execute_async(async_work_fn work, void *arg, async_callback_fn callback) {
    AsyncWorkData *work_data = malloc(sizeof(AsyncWorkData));
    work_data->work = work;
    work_data->arg = arg;
    work_data->callback = callback;

    pthread_t thread;
    pthread_create(&thread, NULL, async_work_thread, work_data);
    pthread_detach(thread);
}

// Delay execution implementation
typedef struct {
    delay_callback_fn callback;
    void *arg;
} DelayCallbackData;

void utils_execute_main_thread(int delay_ms, delay_callback_fn callback, void *arg) {
    DelayCallbackData *data = malloc(sizeof(DelayCallbackData));
    data->callback = callback;
    data->arg = arg;

    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, delay_ms * NSEC_PER_MSEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
      data->callback(data->arg);
      free(data);
    });
}

// Platform abstraction implementations
static char g_config_dir_buffer[PATH_MAX] = {0};

const char *utils_get_config_dir(void) {
    @autoreleasepool {
        NSString *home = NSHomeDirectory();
        NSString *configDir = [home stringByAppendingPathComponent:@".yakety"];
        strncpy(g_config_dir_buffer, [configDir UTF8String], PATH_MAX - 1);
        g_config_dir_buffer[PATH_MAX - 1] = '\0';
        return g_config_dir_buffer;
    }
}

bool utils_ensure_dir_exists(const char *path) {
    struct stat st;
    if (stat(path, &st) == 0) {
        return S_ISDIR(st.st_mode);
    }

    // Create directory with 0755 permissions
    return mkdir(path, 0755) == 0;
}

FILE *utils_fopen_read(const char *path) {
    return fopen(path, "r");
}

FILE *utils_fopen_read_binary(const char *path) {
    return fopen(path, "rb");
}

FILE *utils_fopen_write(const char *path) {
    return fopen(path, "w");
}

FILE *utils_fopen_write_binary(const char *path) {
    return fopen(path, "wb");
}

FILE *utils_fopen_append(const char *path) {
    return fopen(path, "a");
}

char *utils_strdup(const char *str) {
    return strdup(str);
}

int utils_stricmp(const char *s1, const char *s2) {
    return strcasecmp(s1, s2);
}

// Atomic operations for thread-safe access
bool utils_atomic_read_bool(bool *ptr) {
    // Use GCC builtin atomic load
    return __atomic_load_n(ptr, __ATOMIC_SEQ_CST);
}

void utils_atomic_write_bool(bool *ptr, bool value) {
    // Use GCC builtin atomic store
    __atomic_store_n(ptr, value, __ATOMIC_SEQ_CST);
}

int utils_atomic_read_int(int *ptr) {
    // Use GCC builtin atomic load
    return __atomic_load_n(ptr, __ATOMIC_SEQ_CST);
}

void utils_atomic_write_int(int *ptr, int value) {
    // Use GCC builtin atomic store
    __atomic_store_n(ptr, value, __ATOMIC_SEQ_CST);
}

// Mutex implementation using pthread
struct utils_mutex {
    pthread_mutex_t mutex;
};

utils_mutex_t* utils_mutex_create(void) {
    utils_mutex_t* m = malloc(sizeof(utils_mutex_t));
    if (!m) return NULL;
    
    // Create recursive mutex attributes
    pthread_mutexattr_t attr;
    if (pthread_mutexattr_init(&attr) != 0) {
        free(m);
        return NULL;
    }
    
    if (pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE) != 0) {
        pthread_mutexattr_destroy(&attr);
        free(m);
        return NULL;
    }
    
    if (pthread_mutex_init(&m->mutex, &attr) != 0) {
        pthread_mutexattr_destroy(&attr);
        free(m);
        return NULL;
    }
    
    pthread_mutexattr_destroy(&attr);
    return m;
}

void utils_mutex_destroy(utils_mutex_t* mutex) {
    if (mutex) {
        pthread_mutex_destroy(&mutex->mutex);
        free(mutex);
    }
}

void utils_mutex_lock(utils_mutex_t* mutex) {
    if (mutex) {
        pthread_mutex_lock(&mutex->mutex);
    }
}

void utils_mutex_unlock(utils_mutex_t* mutex) {
    if (mutex) {
        pthread_mutex_unlock(&mutex->mutex);
    }
}

void* utils_thread_id(void) {
    return (void*)pthread_self();
}
