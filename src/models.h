#ifndef MODELS_H
#define MODELS_H

#include <stdbool.h>

// Model loading - ONE FUNCTION FOR EVERYTHING
int models_load(void);

// Model path utilities
const char *models_get_current_path(void);
bool models_file_exists(const char *path);

#endif // MODELS_H