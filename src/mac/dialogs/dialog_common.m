#include "dialog_common.h"

void dialog_setup_window_appearance(NSWindow *window) {
    // Set modern dark appearance
    if (@available(macOS 10.14, *)) {
        [window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
    }
    
    // Setup content view
    NSView *contentView = [window contentView];
    [contentView setWantsLayer:YES];
    [contentView.layer setBackgroundColor:[DIALOG_BG_COLOR CGColor]];
}

NSTextField *dialog_create_title_label(NSString *title, NSRect frame) {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:title];
    [label setBordered:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setTextColor:DIALOG_TEXT_COLOR];
    [label setFont:[NSFont boldSystemFontOfSize:26]];
    return label;
}

NSTextField *dialog_create_section_label(NSString *title, NSRect frame) {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:title];
    [label setBordered:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setTextColor:DIALOG_TEXT_COLOR];
    [label setFont:[NSFont boldSystemFontOfSize:18]];
    return label;
}

NSTextField *dialog_create_description_label(NSString *text, NSRect frame) {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:text];
    [label setBordered:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setTextColor:DIALOG_SECONDARY_TEXT_COLOR];
    [label setFont:[NSFont systemFontOfSize:11]];
    [label setMaximumNumberOfLines:2];
    [label setLineBreakMode:NSLineBreakByWordWrapping];
    return label;
}

NSView *dialog_create_card_view(NSRect frame) {
    NSView *card = [[NSView alloc] initWithFrame:frame];
    [card setWantsLayer:YES];
    [card.layer setBackgroundColor:[DIALOG_CARD_BG_COLOR CGColor]];
    [card.layer setCornerRadius:10];
    [card.layer setBorderWidth:1];
    [card.layer setBorderColor:[DIALOG_CARD_BORDER_COLOR CGColor]];
    return card;
}

NSButton *dialog_create_button(NSString *title, NSRect frame, NSColor *color) {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    [button setTitle:title];
    [button setBezelStyle:NSBezelStyleRounded];
    if (@available(macOS 10.12, *)) {
        [button setBezelColor:color];
    }
    return button;
}