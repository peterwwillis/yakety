#ifndef WINDOWS_OVERLAY_H
#define WINDOWS_OVERLAY_H

// Windows-specific overlay functions
void overlay_show_recording(void);
void overlay_show_processing(void);
void overlay_show_result(const char* text);
void overlay_hide(void);

#endif // WINDOWS_OVERLAY_H