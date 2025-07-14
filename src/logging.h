#ifndef LOGGING_H
#define LOGGING_H

#ifdef __cplusplus
extern "C" {
#endif

// Initialize logging system
void log_init(void);

// Cleanup logging system
void log_cleanup(void);

// Logging functions
void log_info(const char *format, ...);
void log_error(const char *format, ...);
void log_debug(const char *format, ...);

#ifdef __cplusplus
}
#endif

#endif// LOGGING_H