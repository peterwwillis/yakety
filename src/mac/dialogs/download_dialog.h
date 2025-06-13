#ifndef DOWNLOAD_DIALOG_H
#define DOWNLOAD_DIALOG_H

#include "dialog_common.h"

// Download dialog function - returns 0 for success, 1 for cancelled, 2 for error
int download_dialog_show(const char *model_name, const char *download_url, const char *file_path);

#endif // DOWNLOAD_DIALOG_H