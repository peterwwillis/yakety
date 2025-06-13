#ifndef MODELS_DIALOG_H
#define MODELS_DIALOG_H

#include "dialog_common.h"

// Models dialog function
bool models_dialog_show(const char *title, char *selected_model, size_t model_buffer_size, 
                        char *selected_language, size_t language_buffer_size,
                        char *download_url, size_t url_buffer_size);

#endif // MODELS_DIALOG_H