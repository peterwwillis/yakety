#ifndef DIALOG_COMMON_H
#define DIALOG_COMMON_H

#include "../../dialog.h"
#include "../../preferences.h"
#import <Cocoa/Cocoa.h>

// Common dialog appearance constants
#define DIALOG_BG_COLOR [NSColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0]
#define DIALOG_TEXT_COLOR [NSColor whiteColor]
#define DIALOG_SECONDARY_TEXT_COLOR [NSColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:1.0]
#define DIALOG_TERTIARY_TEXT_COLOR [NSColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1.0]
#define DIALOG_CARD_BG_COLOR [NSColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0]
#define DIALOG_CARD_BORDER_COLOR [NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]

// Common dialog utility functions
void dialog_setup_window_appearance(NSWindow *window);
NSTextField *dialog_create_title_label(NSString *title, NSRect frame);
NSTextField *dialog_create_section_label(NSString *title, NSRect frame);
NSTextField *dialog_create_description_label(NSString *text, NSRect frame);
NSView *dialog_create_card_view(NSRect frame);
NSButton *dialog_create_button(NSString *title, NSRect frame, NSColor *color);

#endif // DIALOG_COMMON_H