#include "models_dialog.h"
#include "../../model_definitions.h"
#include "../../utils.h"
#import <objc/runtime.h>

// Button action methods
// Window delegate to handle close button
@interface ModelsDialogWindowDelegate : NSObject <NSWindowDelegate>
@end

@implementation ModelsDialogWindowDelegate
- (BOOL)windowShouldClose:(NSWindow *)sender {
    // User clicked the close button - treat as cancel
    [NSApp stopModalWithCode:NSModalResponseCancel];
    return YES;
}
@end

@interface NSWindow (TableViewDataSource) <NSTableViewDataSource, NSTableViewDelegate>
@end

@interface NSButton (ModelsDialogActions)
- (void)modelButtonClicked:(id)sender;
- (void)applyButtonClicked:(id)sender;
- (void)cancelButtonClicked:(id)sender;
- (void)deleteModelClicked:(id)sender;
- (void)updateModelButtonStates:(NSWindow *)window selectedPath:(NSString *)selectedPath;
- (void)updateButtonStatesInView:(NSView *)view selectedPath:(NSString *)selectedPath;
@end

bool models_dialog_show(const char *title, char *selected_model, size_t model_buffer_size, 
                        char *selected_language, size_t language_buffer_size,
                        char *download_url, size_t url_buffer_size) {
    @autoreleasepool {
        // Create the main window - larger to accommodate language selection
        NSRect windowFrame = NSMakeRect(0, 0, 750, 680);
        NSWindow *window = [[NSWindow alloc] initWithContentRect:windowFrame
                                                       styleMask:(NSWindowStyleMaskTitled | 
                                                                 NSWindowStyleMaskClosable |
                                                                 NSWindowStyleMaskResizable)
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        
        [window setTitle:[NSString stringWithUTF8String:title]];
        [window center];
        [window setMinSize:NSMakeSize(700, 650)];
        
        // Set up window delegate to handle close button
        ModelsDialogWindowDelegate *windowDelegate = [[ModelsDialogWindowDelegate alloc] init];
        [window setDelegate:windowDelegate];
        
        // Setup window appearance
        dialog_setup_window_appearance(window);
        NSView *contentView = [window contentView];
        
        // App icon in top-left corner
        NSImageView *iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(30, 620, 40, 40)];
        NSImage *appIcon = [NSApp applicationIconImage];
        if (appIcon) {
            [iconView setImage:appIcon];
            [contentView addSubview:iconView];
        }
        
        // Content title (moved right to make room for icon)
        NSTextField *contentTitle = dialog_create_title_label(@"Models & Language Settings", 
                                                            NSMakeRect(80, 620, 640, 35));
        [contentView addSubview:contentTitle];
        
        // Language selection section
        NSTextField *languageTitle = dialog_create_section_label(@"Language", 
                                                               NSMakeRect(30, 580, 690, 25));
        [contentView addSubview:languageTitle];
        
        // Language dropdown
        NSPopUpButton *languagePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(30, 540, 250, 30)];
        [languagePopup removeAllItems];
        
        // Add "Auto-detect" option first
        [languagePopup addItemWithTitle:@"Auto-detect (adds latency)"];
        [[languagePopup lastItem] setRepresentedObject:@"auto"];
        
        // Add major languages from centralized definitions
        for (int i = 0; i < SUPPORTED_LANGUAGES_COUNT; i++) {
            NSString *langName = [NSString stringWithUTF8String:SUPPORTED_LANGUAGES[i].name];
            NSString *langCode = [NSString stringWithUTF8String:SUPPORTED_LANGUAGES[i].code];
            [languagePopup addItemWithTitle:langName];
            [[languagePopup lastItem] setRepresentedObject:langCode];
        }
        
        // Set current language as default from preferences
        const char *current_language = preferences_get_string("language");
        NSString *currentLangCode = current_language ? [NSString stringWithUTF8String:current_language] : @"en";
        
        // Find and select current language
        bool found = false;
        for (int i = 0; i < [languagePopup numberOfItems]; i++) {
            NSMenuItem *item = [languagePopup itemAtIndex:i];
            NSString *itemCode = [item representedObject];
            if (itemCode && [itemCode isEqualToString:currentLangCode]) {
                [languagePopup selectItemAtIndex:i];
                found = true;
                break;
            }
        }
        if (!found) {
            [languagePopup selectItemAtIndex:1]; // Default to English if not found
        }
        
        [contentView addSubview:languagePopup];
        
        // Language description
        NSTextField *languageDesc = dialog_create_description_label(
            @"Select the language for transcription. Auto-detect analyzes audio to determine language but adds processing time.",
            NSMakeRect(30, 515, 690, 18));
        [contentView addSubview:languageDesc];
        
        // Models section
        NSTextField *modelsTitle = dialog_create_section_label(@"Models", 
                                                             NSMakeRect(30, 470, 690, 25));
        [contentView addSubview:modelsTitle];
        
        // Check for user models in ~/.yakety/models/
        NSString *homeDir = NSHomeDirectory();
        NSString *modelsDir = [homeDir stringByAppendingPathComponent:@".yakety/models"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *userModelFiles = [fileManager contentsOfDirectoryAtPath:modelsDir error:nil];
        
        // Define available models using centralized definitions
        NSMutableArray *allModels = [NSMutableArray array];
        
        // Bundled model (always available as "downloaded")
        [allModels addObject:[@{
            @"name": [NSString stringWithUTF8String:BUNDLED_MODEL.name],
            @"description": [NSString stringWithUTF8String:BUNDLED_MODEL.description],
            @"size": [NSString stringWithUTF8String:BUNDLED_MODEL.size], 
            @"path": @"", // Empty path means bundled
            @"state": @"downloaded",
            @"download_url": @"" // No download needed
        } mutableCopy]];
        
        // User models from ~/.yakety/models/
        for (NSString *filename in userModelFiles) {
            if ([filename hasSuffix:@".bin"] || [filename hasSuffix:@".gguf"]) {
                NSString *fullPath = [modelsDir stringByAppendingPathComponent:filename];
                
                // Calculate actual file size
                NSString *sizeString = @"Unknown";
                NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:fullPath error:nil];
                if (fileAttributes) {
                    unsigned long long fileSize = [fileAttributes fileSize];
                    if (fileSize >= 1024 * 1024 * 1024) {
                        sizeString = [NSString stringWithFormat:@"%.1f GB", fileSize / (1024.0 * 1024.0 * 1024.0)];
                    } else if (fileSize >= 1024 * 1024) {
                        sizeString = [NSString stringWithFormat:@"%.1f MB", fileSize / (1024.0 * 1024.0)];
                    } else if (fileSize >= 1024) {
                        sizeString = [NSString stringWithFormat:@"%.1f KB", fileSize / 1024.0];
                    } else {
                        sizeString = [NSString stringWithFormat:@"%llu B", fileSize];
                    }
                }
                
                // Try to find model info by filename
                const ModelInfo *modelInfo = find_model_by_filename([filename UTF8String]);
                
                NSString *displayName;
                NSString *description;
                
                if (modelInfo) {
                    // Use official model info
                    displayName = [NSString stringWithUTF8String:modelInfo->name];
                    description = [NSString stringWithUTF8String:modelInfo->description];
                } else {
                    // Use filename as fallback
                    displayName = [filename stringByDeletingPathExtension];
                    description = @"Custom model installed by user. Performance and accuracy depend on the specific model variant and quantization.";
                }
                
                [allModels addObject:[@{
                    @"name": displayName,
                    @"description": description,
                    @"size": sizeString,
                    @"path": fullPath,
                    @"state": @"downloaded",
                    @"download_url": @"" // No download needed
                } mutableCopy]];
            }
        }
        
        // Downloadable models from centralized definitions (only show if not already on disk)
        for (int i = 0; i < DOWNLOADABLE_MODELS_COUNT; i++) {
            const ModelInfo *model = &DOWNLOADABLE_MODELS[i];
            NSString *modelPath = [modelsDir stringByAppendingPathComponent:[NSString stringWithUTF8String:model->filename]];
            bool exists = [fileManager fileExistsAtPath:modelPath];
            
            // Only add if the model doesn't exist on disk (to avoid duplicates)
            if (!exists) {
                [allModels addObject:[@{
                    @"name": [NSString stringWithUTF8String:model->name],
                    @"description": [NSString stringWithUTF8String:model->description],
                    @"size": [NSString stringWithUTF8String:model->size],
                    @"path": modelPath,
                    @"state": @"available",
                    @"download_url": [NSString stringWithUTF8String:model->download_url]
                } mutableCopy]];
            }
        }
        
        // Models table view with automatic layout and scrolling
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(30, 80, 690, 370)];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setBorderType:NSNoBorder];
        [scrollView setBackgroundColor:[NSColor clearColor]];
        [contentView addSubview:scrollView];
        
        NSTableView *tableView = [[NSTableView alloc] initWithFrame:[scrollView bounds]];
        [tableView setRowHeight:110]; // Height for each model card
        [tableView setIntercellSpacing:NSMakeSize(0, 10)]; // 10pt spacing between rows
        [tableView setHeaderView:nil]; // No column headers
        [tableView setBackgroundColor:[NSColor clearColor]];
        [tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
        
        // Single column for model cards
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"ModelColumn"];
        [column setWidth:670];
        [column setResizingMask:NSTableColumnAutoresizingMask];
        [tableView addTableColumn:column];
        
        [scrollView setDocumentView:tableView];
        
        // Storage for selected values
        NSMutableString *selectedModelPath = [NSMutableString string];
        NSMutableString *selectedLanguageCode = [NSMutableString stringWithString:@"en"];
        NSMutableString *selectedDownloadUrl = [NSMutableString string];
        
        // Get current model - use resolved path from utils_get_model_path()
        const char *resolved_model_path = utils_get_model_path();
        const char *current_model = preferences_get_string("model");
        
        // If no custom model is set in preferences, use empty string (represents bundled model)
        NSString *currentModelPath = (current_model && strlen(current_model) > 0) ? [NSString stringWithUTF8String:current_model] : @"";
        
        // Find initially selected model
        int selectedRow = -1;
        for (int i = 0; i < [allModels count]; i++) {
            NSDictionary *modelData = allModels[i];
            NSString *modelPath = modelData[@"path"];
            
            bool isCurrentModel = false;
            if ([modelPath length] == 0) {
                isCurrentModel = [currentModelPath length] == 0;
            } else {
                isCurrentModel = [modelPath isEqualToString:currentModelPath];
            }
            
            if (isCurrentModel) {
                selectedRow = i;
                [selectedModelPath setString:modelPath];
                if ([modelData[@"state"] isEqualToString:@"available"]) {
                    [selectedDownloadUrl setString:modelData[@"download_url"]];
                }
                break;
            }
        }
        
        // Configure table view data source and delegate
        tableView.dataSource = (id<NSTableViewDataSource>)window;
        tableView.delegate = (id<NSTableViewDelegate>)window;
        
        // Store data and selection state with the table view
        objc_setAssociatedObject(tableView, "allModels", allModels, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(tableView, "selectedModelPath", selectedModelPath, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(tableView, "selectedDownloadUrl", selectedDownloadUrl, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(tableView, "currentModelPath", currentModelPath, OBJC_ASSOCIATION_RETAIN);
        
        // Reload data and select current model
        [tableView reloadData];
        if (selectedRow >= 0) {
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        }
        
        // Bottom buttons
        NSButton *cancelButton = dialog_create_button(@"Cancel", NSMakeRect(30, 30, 100, 35), [NSColor systemGrayColor]);
        [cancelButton setTarget:cancelButton];
        [cancelButton setAction:@selector(cancelButtonClicked:)];
        objc_setAssociatedObject(cancelButton, "window", window, OBJC_ASSOCIATION_ASSIGN);
        [contentView addSubview:cancelButton];
        
        NSButton *applyButton = dialog_create_button(@"Apply", NSMakeRect(620, 30, 100, 35), [NSColor systemBlueColor]);
        objc_setAssociatedObject(applyButton, "window", window, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(applyButton, "selectedModel", selectedModelPath, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(applyButton, "selectedLanguage", selectedLanguageCode, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(applyButton, "selectedDownloadUrl", selectedDownloadUrl, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(applyButton, "languagePopup", languagePopup, OBJC_ASSOCIATION_RETAIN);
        [applyButton setTarget:applyButton];
        [applyButton setAction:@selector(applyButtonClicked:)];
        [contentView addSubview:applyButton];
        
        // Show window modally and ensure it's focused
        [NSApp activateIgnoringOtherApps:YES];
        [window makeKeyAndOrderFront:nil];
        [window orderFrontRegardless];
        
        // Run modal loop with proper cleanup
        NSModalSession session = NULL;
        NSModalResponse response = NSModalResponseContinue;
        
        @try {
            session = [NSApp beginModalSessionForWindow:window];
            
            while (response == NSModalResponseContinue) {
                response = [NSApp runModalSession:session];
                
                // Small delay to prevent busy waiting and allow UI updates
                usleep(10000); // 10ms
            }
        }
        @finally {
            // Ensure modal session is always cleaned up
            if (session) {
                [NSApp endModalSession:session];
            }
            [window close];
        }
        
        // Check if user made selections
        if ([selectedModelPath length] > 0 || response == NSModalResponseOK) {
            strncpy(selected_model, [selectedModelPath UTF8String], model_buffer_size - 1);
            selected_model[model_buffer_size - 1] = '\0';
            
            strncpy(selected_language, [selectedLanguageCode UTF8String], language_buffer_size - 1);
            selected_language[language_buffer_size - 1] = '\0';
            
            strncpy(download_url, [selectedDownloadUrl UTF8String], url_buffer_size - 1);
            download_url[url_buffer_size - 1] = '\0';
            
            return true;
        }
        
        return false;
    }
}

@implementation NSButton (ModelsDialogActions)
- (void)modelButtonClicked:(id)sender {
    NSDictionary *modelData = objc_getAssociatedObject(sender, "modelData");
    NSMutableString *selectedModel = objc_getAssociatedObject(sender, "selectedModel");
    NSMutableString *selectedDownloadUrl = objc_getAssociatedObject(sender, "selectedDownloadUrl");
    NSWindow *window = objc_getAssociatedObject(sender, "window");
    
    NSString *state = modelData[@"state"];
    if ([state isEqualToString:@"downloaded"]) {
        // Select this model
        [selectedModel setString:modelData[@"path"]];
        [selectedDownloadUrl setString:@""]; // No download needed
        
        // Update all buttons in the window to show unselected state
        [self updateModelButtonStates:window selectedPath:modelData[@"path"]];
    } else {
        // Set model for download (don't actually download, just mark it for selection)
        [selectedModel setString:modelData[@"path"]];
        [selectedDownloadUrl setString:modelData[@"download_url"]];
        
        // Update all buttons in the window to show unselected state
        [self updateModelButtonStates:window selectedPath:modelData[@"path"]];
    }
}

- (void)updateModelButtonStates:(NSWindow *)window selectedPath:(NSString *)selectedPath {
    // Find all button subviews and update their states
    [self updateButtonStatesInView:[window contentView] selectedPath:selectedPath];
}

- (void)updateButtonStatesInView:(NSView *)view selectedPath:(NSString *)selectedPath {
    for (NSView *subview in [view subviews]) {
        if ([subview isKindOfClass:[NSButton class]]) {
            NSButton *button = (NSButton *)subview;
            NSDictionary *modelData = objc_getAssociatedObject(button, "modelData");
            if (modelData) {
                NSString *buttonPath = modelData[@"path"];
                NSString *state = modelData[@"state"];
                
                if ([buttonPath isEqualToString:selectedPath]) {
                    [button setTitle:@"Selected"];
                    if (@available(macOS 10.12, *)) {
                        [button setBezelColor:[NSColor systemOrangeColor]];
                    }
                } else {
                    [button setTitle:@"Select"];
                    if (@available(macOS 10.12, *)) {
                        [button setBezelColor:[NSColor systemBlueColor]];
                    }
                }
            }
        } else {
            // Recursively check subviews
            [self updateButtonStatesInView:subview selectedPath:selectedPath];
        }
    }
}


- (void)applyButtonClicked:(id)sender {
    NSWindow *window = objc_getAssociatedObject(sender, "window");
    NSMutableString *selectedModel = objc_getAssociatedObject(sender, "selectedModel");
    NSMutableString *selectedLanguage = objc_getAssociatedObject(sender, "selectedLanguage");
    NSMutableString *selectedDownloadUrl = objc_getAssociatedObject(sender, "selectedDownloadUrl");
    NSPopUpButton *languagePopup = objc_getAssociatedObject(sender, "languagePopup");
    
    // Get selected language
    NSMenuItem *selectedItem = [languagePopup selectedItem];
    NSString *languageCode = [selectedItem representedObject];
    if (languageCode) {
        [selectedLanguage setString:languageCode];
    }
    
    // If no model selected, use bundled model (empty string)
    if ([selectedModel length] == 0) {
        [selectedModel setString:@""];
        [selectedDownloadUrl setString:@""]; // No download needed for bundled model
    }
    
    [NSApp stopModalWithCode:NSModalResponseOK];
}

- (void)cancelButtonClicked:(id)sender {
    NSWindow *window = objc_getAssociatedObject(sender, "window");
    [NSApp stopModalWithCode:NSModalResponseCancel];
}

- (void)deleteModelClicked:(id)sender {
    NSDictionary *modelData = objc_getAssociatedObject(sender, "modelData");
    NSTableView *tableView = objc_getAssociatedObject(sender, "tableView");
    
    if (!modelData) return;
    
    NSString *modelName = modelData[@"name"];
    NSString *modelPath = modelData[@"path"];
    
    // Don't allow deletion of bundled model (empty path)
    if ([modelPath length] == 0) {
        return;
    }
    
    // Confirm deletion
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:@"Delete %@?", modelName]];
    [alert setInformativeText:@"This will permanently delete the model file from your computer. This action cannot be undone."];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    // Use sheet modal to avoid closing the parent models dialog
    NSWindow *parentWindow = [[NSApplication sharedApplication] keyWindow];
    [alert beginSheetModalForWindow:parentWindow completionHandler:^(NSModalResponse response) {
        if (response == NSAlertFirstButtonReturn) {
            // Delete the file
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error = nil;
            BOOL success = [fileManager removeItemAtPath:modelPath error:&error];
            
            if (success) {
                // Check if the deleted model was currently selected
                NSMutableString *selectedModelPath = objc_getAssociatedObject(tableView, "selectedModelPath");
                NSMutableString *selectedDownloadUrl = objc_getAssociatedObject(tableView, "selectedDownloadUrl");
                BOOL wasSelected = [selectedModelPath isEqualToString:modelPath];
                
                // Update the model state to "available" instead of removing it
                NSMutableArray *allModels = objc_getAssociatedObject(tableView, "allModels");
                
                // Find the deleted model and update its state
                for (NSInteger i = 0; i < [allModels count]; i++) {
                    NSMutableDictionary *model = allModels[i];
                    if ([model[@"path"] isEqualToString:modelPath]) {
                        // Convert to mutable dictionary if needed
                        if (![model isKindOfClass:[NSMutableDictionary class]]) {
                            NSMutableDictionary *mutableModel = [model mutableCopy];
                            [allModels replaceObjectAtIndex:i withObject:mutableModel];
                            model = mutableModel;
                        }
                        
                        // Update state to available and add download URL
                        [model setObject:@"available" forKey:@"state"];
                        
                        // Find the download URL from the model definitions
                        NSString *modelName = model[@"name"];
                        for (int j = 0; j < DOWNLOADABLE_MODELS_COUNT; j++) {
                            const ModelInfo *modelInfo = &DOWNLOADABLE_MODELS[j];
                            NSString *defName = [NSString stringWithUTF8String:modelInfo->name];
                            if ([defName isEqualToString:modelName]) {
                                [model setObject:[NSString stringWithUTF8String:modelInfo->download_url] forKey:@"download_url"];
                                break;
                            }
                        }
                        
                        break;
                    }
                }
                
                // If the deleted model was selected, keep it selected but update to download state
                if (wasSelected) {
                    // Keep the same model selected, but now it needs to be downloaded
                    // selectedModelPath stays the same (the path where it should be downloaded)
                    // Update the download URL so Apply will trigger download
                    NSString *modelName = modelData[@"name"];
                    for (int j = 0; j < DOWNLOADABLE_MODELS_COUNT; j++) {
                        const ModelInfo *modelInfo = &DOWNLOADABLE_MODELS[j];
                        NSString *defName = [NSString stringWithUTF8String:modelInfo->name];
                        if ([defName isEqualToString:modelName]) {
                            [selectedDownloadUrl setString:[NSString stringWithUTF8String:modelInfo->download_url]];
                            break;
                        }
                    }
                }
                
                // Reload the table view - this will recreate all cells with correct button states
                [tableView reloadData];
            } else {
                // Show error message as sheet
                NSAlert *errorAlert = [[NSAlert alloc] init];
                [errorAlert setMessageText:@"Delete Failed"];
                [errorAlert setInformativeText:[NSString stringWithFormat:@"Failed to delete %@: %@", modelName, error ? [error localizedDescription] : @"Unknown error"]];
                [errorAlert addButtonWithTitle:@"OK"];
                [errorAlert setAlertStyle:NSAlertStyleCritical];
                [errorAlert beginSheetModalForWindow:parentWindow completionHandler:nil];
            }
        }
    }];
}
@end

@implementation NSWindow (TableViewDataSource)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSArray *allModels = objc_getAssociatedObject(tableView, "allModels");
    return [allModels count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSArray *allModels = objc_getAssociatedObject(tableView, "allModels");
    NSMutableString *selectedModelPath = objc_getAssociatedObject(tableView, "selectedModelPath");
    NSMutableString *selectedDownloadUrl = objc_getAssociatedObject(tableView, "selectedDownloadUrl");
    NSString *currentModelPath = objc_getAssociatedObject(tableView, "currentModelPath");
    
    if (row >= [allModels count]) return nil;
    
    NSDictionary *modelData = allModels[row];
    
    // Create the card view for this row
    NSView *cardView = dialog_create_card_view(NSMakeRect(0, 0, 670, 95));
    
    // Model name
    NSTextField *nameLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 65, 400, 22)];
    [nameLabel setStringValue:modelData[@"name"]];
    [nameLabel setBordered:NO];
    [nameLabel setEditable:NO];
    [nameLabel setSelectable:NO];
    [nameLabel setBackgroundColor:[NSColor clearColor]];
    [nameLabel setTextColor:DIALOG_TEXT_COLOR];
    [nameLabel setFont:[NSFont boldSystemFontOfSize:16]];
    [cardView addSubview:nameLabel];
    
    // Description
    NSTextField *descLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 25, 400, 35)];
    [descLabel setStringValue:modelData[@"description"]];
    [descLabel setBordered:NO];
    [descLabel setEditable:NO];
    [descLabel setSelectable:NO];
    [descLabel setBackgroundColor:[NSColor clearColor]];
    [descLabel setTextColor:DIALOG_SECONDARY_TEXT_COLOR];
    [descLabel setFont:[NSFont systemFontOfSize:11]];
    [descLabel setMaximumNumberOfLines:3];
    [descLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [cardView addSubview:descLabel];
    
    // Size info
    NSTextField *sizeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 8, 80, 16)];
    [sizeLabel setStringValue:[NSString stringWithFormat:@"Size: %@", modelData[@"size"]]];
    [sizeLabel setBordered:NO];
    [sizeLabel setEditable:NO];
    [sizeLabel setSelectable:NO];
    [sizeLabel setBackgroundColor:[NSColor clearColor]];
    [sizeLabel setTextColor:DIALOG_TERTIARY_TEXT_COLOR];
    [sizeLabel setFont:[NSFont systemFontOfSize:10]];
    [cardView addSubview:sizeLabel];
    
    // Status badge - using NSButton for better text centering
    NSString *state = modelData[@"state"];
    NSButton *statusBadge = [[NSButton alloc] initWithFrame:NSMakeRect(110, 6, 70, 18)];
    [statusBadge setButtonType:NSButtonTypeMomentaryPushIn];
    [statusBadge setBordered:NO];
    [statusBadge setWantsLayer:YES];
    [statusBadge.layer setCornerRadius:3.0];
    
    // Create attributed string for proper text styling
    NSColor *textColor;
    NSColor *bgColor;
    NSString *titleText;
    
    if ([state isEqualToString:@"downloaded"] || [state isEqualToString:@"bundled"]) {
        titleText = @"Installed";
        textColor = [NSColor systemGreenColor];
        bgColor = [[NSColor systemGreenColor] colorWithAlphaComponent:0.15];
    } else {
        titleText = @"Available";
        textColor = [NSColor systemBlueColor];
        bgColor = [[NSColor systemBlueColor] colorWithAlphaComponent:0.15];
    }
    
    // Set background using layer
    [statusBadge.layer setBackgroundColor:[bgColor CGColor]];
    
    // Create attributed string for text color
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:titleText];
    [attributedTitle addAttribute:NSForegroundColorAttributeName 
                            value:textColor 
                            range:NSMakeRange(0, [titleText length])];
    [attributedTitle addAttribute:NSFontAttributeName 
                            value:[NSFont boldSystemFontOfSize:9] 
                            range:NSMakeRange(0, [titleText length])];
    
    [statusBadge setAttributedTitle:attributedTitle];
    [statusBadge setEnabled:NO]; // Make it non-clickable, just a visual badge
    
    [cardView addSubview:statusBadge];
    
    // Add delete button for downloaded models (not bundled)  
    if ([state isEqualToString:@"downloaded"] && [modelData[@"path"] length] > 0) {
        NSButton *deleteButton = [[NSButton alloc] initWithFrame:NSMakeRect(185, 6, 60, 18)];
        [deleteButton setButtonType:NSButtonTypeMomentaryPushIn];
        [deleteButton setTitle:@"Delete"];
        [deleteButton setFont:[NSFont systemFontOfSize:9]];
        [deleteButton setBordered:YES];
        [deleteButton setBezelStyle:NSBezelStyleRounded];
        [deleteButton setWantsLayer:YES];
        
        // Style as a small red button
        if (@available(macOS 10.12, *)) {
            [deleteButton setBezelColor:[[NSColor systemRedColor] colorWithAlphaComponent:0.8]];
        }
        
        // Create attributed string for white text
        NSMutableAttributedString *deleteTitle = [[NSMutableAttributedString alloc] initWithString:@"Delete"];
        [deleteTitle addAttribute:NSForegroundColorAttributeName 
                            value:[NSColor whiteColor] 
                            range:NSMakeRange(0, 6)];
        [deleteTitle addAttribute:NSFontAttributeName 
                            value:[NSFont systemFontOfSize:9] 
                            range:NSMakeRange(0, 6)];
        
        [deleteButton setAttributedTitle:deleteTitle];
        
        // Store model data for delete action
        objc_setAssociatedObject(deleteButton, "modelData", modelData, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(deleteButton, "tableView", tableView, OBJC_ASSOCIATION_ASSIGN);
        
        [deleteButton setTarget:deleteButton];
        [deleteButton setAction:@selector(deleteModelClicked:)];
        
        [cardView addSubview:deleteButton];
    }
    
    // Action button
    NSString *modelPath = modelData[@"path"];
    
    // Check if this is the current model
    bool isCurrentModel = false;
    if ([modelPath length] == 0) {
        isCurrentModel = [currentModelPath length] == 0;
    } else {
        isCurrentModel = [modelPath isEqualToString:currentModelPath];
    }
    
    NSButton *actionButton;
    if (isCurrentModel) {
        actionButton = dialog_create_button(@"Selected", NSMakeRect(520, 30, 100, 35), [NSColor systemOrangeColor]);
    } else {
        actionButton = dialog_create_button(@"Select", NSMakeRect(520, 30, 100, 35), [NSColor systemBlueColor]);
    }
    
    // Store model data with button
    objc_setAssociatedObject(actionButton, "modelData", modelData, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(actionButton, "selectedModel", selectedModelPath, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(actionButton, "selectedDownloadUrl", selectedDownloadUrl, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(actionButton, "window", self, OBJC_ASSOCIATION_ASSIGN);
    
    [actionButton setTarget:actionButton];
    [actionButton setAction:@selector(modelButtonClicked:)];
    [cardView addSubview:actionButton];
    
    return cardView;
}

@end