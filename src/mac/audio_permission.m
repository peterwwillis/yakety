#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

bool check_and_request_microphone_permission(void) {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    switch (status) {
        case AVAuthorizationStatusAuthorized:
            NSLog(@"Microphone permission already granted");
            return true;
            
        case AVAuthorizationStatusNotDetermined:
            // For now, just log and return false - the actual request will happen
            // when miniaudio tries to open the device, which will trigger the system prompt
            NSLog(@"Microphone permission not determined - will be requested when needed");
            return true; // Return true to let initialization continue
            
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            NSLog(@"Microphone permission denied or restricted");
            // Show alert to user about needing to enable in System Settings
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Microphone Access Required"];
                [alert setInformativeText:@"Yakety needs microphone access to transcribe speech. Please enable microphone access in System Settings > Privacy & Security > Microphone."];
                [alert addButtonWithTitle:@"Open System Settings"];
                [alert addButtonWithTitle:@"Cancel"];
                
                NSInteger response = [alert runModal];
                if (response == NSAlertFirstButtonReturn) {
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"]];
                }
            });
            return false;
    }
    
    return false;
}