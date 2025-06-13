#ifndef HOTKEY_DIALOG_H
#define HOTKEY_DIALOG_H

#include "dialog_common.h"
#include "../../keylogger.h"

// Hotkey dialog function
bool hotkey_dialog_show(const char *title, const char *message, KeyCombination *result);

#endif // HOTKEY_DIALOG_H