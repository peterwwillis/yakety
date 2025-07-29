#ifndef DIALOG_H
#define DIALOG_H

#include <stdbool.h>
#include <stddef.h>
#include "keylogger.h"

void dialog_error(const char *title, const char *message);
void dialog_info(const char *title, const char *message);
bool dialog_confirm(const char *title, const char *message);
bool dialog_keycombination_capture(const char *title, const char *message, KeyCombination *result);

// Model and language selection dialog - returns true if user made selections, false if cancelled
// selected_model will contain the chosen model path if return value is true (empty string means bundled model)
// selected_language will contain the chosen language code if return value is true
// download_url will contain the download URL if a model needs to be downloaded (empty string if no download needed)
bool dialog_models_and_language(const char *title, char *selected_model, size_t model_buffer_size,
                                char *selected_language, size_t language_buffer_size,
                                char *download_url, size_t url_buffer_size);

// Model download dialog - returns 0 for success, 1 for cancelled, 2 for error
// model_name: display name for the model being downloaded
// download_url: URL to download from
// file_path: local path where file should be saved
int dialog_model_download(const char *model_name, const char *download_url, const char *file_path);

#endif// DIALOG_H