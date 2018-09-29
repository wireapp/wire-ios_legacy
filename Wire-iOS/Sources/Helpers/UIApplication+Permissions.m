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

@import Photos;
#import <AVFoundation/AVFoundation.h>

NSString * const UserGrantedAudioPermissionsNotification = @"UserGrantedAudioPermissionsNotification";

@implementation UIApplication (Permissions)

+ (void)wr_requestOrWarnAboutMicrophoneAccess:(void(^)(BOOL granted))grantedHandler
{
    BOOL audioPermissionsWereNotDetermined = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusNotDetermined;
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (! granted) {
                [self wr_warnAboutMicrophonePermission];
            }
            
            if (audioPermissionsWereNotDetermined && granted) {
                [[NSNotificationCenter defaultCenter] postNotificationName:UserGrantedAudioPermissionsNotification object:nil];
            }
            
            if (grantedHandler != nil) grantedHandler(granted);
        });
    }];
}

+ (void)wr_requestOrWarnAboutVideoAccess:(void(^)(BOOL granted))grantedHandler
{
    [UIApplication wr_requestVideoAccess:^(BOOL granted) {
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

+ (void)wr_requestOrWarnAboutPhotoLibraryAccess:(void(^)(BOOL granted))grantedHandler
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
    {
        switch (status) {
            case PHAuthorizationStatusRestricted:
                [self wr_warnAboutPhotoLibraryRestricted];
                grantedHandler(NO);
            case PHAuthorizationStatusDenied:
                [self wr_warnAboutPhotoLibaryDenied];
                grantedHandler(NO);
            case PHAuthorizationStatusNotDetermined:
                [self wr_warnAboutPhotoLibaryDenied];
                grantedHandler(NO);
            case PHAuthorizationStatusAuthorized:
                grantedHandler(YES);
        }
    }];
}

+ (void)wr_requestVideoAccess:(void(^)(BOOL granted))grantedHandler
{
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (grantedHandler != nil) grantedHandler(granted);
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
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                           options:@{}
                                 completionHandler:NULL];
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
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                           options:@{}
                                 completionHandler:NULL];
    }]];
    
    [[AppDelegate sharedAppDelegate].notificationsWindow.rootViewController presentViewController:noMicrophoneAlert animated:YES completion:nil];
}

+ (void)wr_warnAboutPhotoLibraryRestricted
{
    UIAlertController *libraryRestrictedAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"library.alert.permission_warning.title", nil)
                                                                                    message:NSLocalizedString(@"library.alert.permission_warning.restrictions.explaination", nil)
                                                                          cancelButtonTitle:NSLocalizedString(@"general.ok", nil)];

    [[AppDelegate sharedAppDelegate].notificationsWindow.rootViewController presentViewController:libraryRestrictedAlert animated:YES completion:nil];
}

+ (void)wr_warnAboutPhotoLibaryDenied
{
    UIAlertController *deniedAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"library.alert.permission_warning.title", nil)
                                                                         message:NSLocalizedString(@"library.alert.permission_warning.not_allowed.explaination", nil)
                                                               cancelButtonTitle:NSLocalizedString(@"general.cancel", nil)];

    [deniedAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"general.open_settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                           options:@{}
                                 completionHandler:NULL];
    }]];

    [[AppDelegate sharedAppDelegate].notificationsWindow.rootViewController presentViewController:deniedAlert animated:YES completion:nil];
}

@end
