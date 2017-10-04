// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "UIApplication+Permissions.h"
#import "AppDelegate.h"
#import "UIAlertController+Wire.h"
#import "UIResponder+FirstResponder.h"

#import <AVFoundation/AVFoundation.h>

@implementation UIApplication (Permissions)

+ (void)wr_requestOrWarnAboutMicrophoneAccess:(void(^)(BOOL granted))grantedHandler
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (! granted) {
                [self wr_warnAboutMicrophonePermission];
            }
            if (grantedHandler != nil) grantedHandler(granted);
        });
    }];
}

+ (void)wr_requestOrWarnAboutVideoAccess:(void(^)(BOOL granted))grantedHandler
{
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (! granted) {
                [self wr_warnAboutCameraPermissionWithCompletion:^{
                    if (grantedHandler != nil) grantedHandler(granted);
                }];
            }
            else {
                if (grantedHandler != nil) grantedHandler(granted);
            }
        });
    }];
}

+ (void)wr_warnAboutCameraPermissionWithCompletion:(dispatch_block_t)completion
{
    id currentResponder = (id)[UIResponder wr_currentFirstResponder];
    if ([currentResponder respondsToSelector:@selector(endEditing:)]) {
        [currentResponder endEditing:YES];
    }
    
    UIAlertController *noVideoAlert =
    [UIAlertController alertControllerWithTitle:NSLocalizedString(@"voice.alert.camera_warning.title", nil)
                                        message:NSLocalizedString(@"voice.alert.camera_warning.explanation", nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionSettings = [UIAlertAction actionWithTitle:NSLocalizedString(@"general.open_settings", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        if (nil != completion) completion();
    }];
    
    [noVideoAlert addAction:actionSettings];
    
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:NSLocalizedString(@"general.ok", nil)
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * _Nonnull action) {
         [[AppDelegate sharedAppDelegate].notificationsWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
         if (nil != completion) completion();
                                                     }];
    
    [noVideoAlert addAction:actionOK];
    
    [[AppDelegate sharedAppDelegate].notificationsWindow.rootViewController presentViewController:noVideoAlert animated:YES completion:nil];
}


+ (void)wr_warnAboutMicrophonePermission
{
    UIAlertController *noMicrophoneAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"voice.alert.microphone_warning.title", nil)
                                                                               message:NSLocalizedString(@"voice.alert.microphone_warning.explanation", nil)
                                                                     cancelButtonTitle:NSLocalizedString(@"general.ok", nil)];
    
    [noMicrophoneAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"general.open_settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    
    [[AppDelegate sharedAppDelegate].notificationsWindow.rootViewController presentViewController:noMicrophoneAlert animated:YES completion:nil];
}


@end
