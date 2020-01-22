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



#import "ProfileSelfPictureViewController.h"
#import "ProfileSelfPictureViewController+Internal.h"

@import MobileCoreServices;



#import "Analytics.h"


#import "Wire-Swift.h"

@interface ProfileSelfPictureViewController ()


@property (nonatomic) id userObserverToken;
@end

@implementation ProfileSelfPictureViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _imagePickerConfirmationController = [[ImagePickerConfirmationController alloc] init];
        
        ZM_WEAK(self);
        _imagePickerConfirmationController.imagePickedBlock = ^(NSData *imageData) {
            ZM_STRONG(self);
            [self dismissViewControllerAnimated:YES completion:nil];
            [self setSelfImageToData:imageData];
        };

        if ([ZMUserSession sharedSession] != nil) {
            self.userObserverToken = [UserChangeInfo addObserver:self forUser:[ZMUser selfUser] inUserSession:[ZMUserSession sharedSession]];
        }
    }
    
    return self;
}



/// This should be called when the user has confirmed their intent to set their image to this data. No custom presentations should be in flight, all previous presentations should be completed by this point.
- (void)setSelfImageToData:(NSData *)selfImageData
{
    // iOS11 uses HEIF image format, but BE expects JPEG
    NSData *jpegData = selfImageData.isJPEG ? selfImageData : UIImageJPEGRepresentation([UIImage imageWithData:selfImageData], 1.0);
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [[ZMUserSession sharedSession].profileUpdate updateImageWithImageData:jpegData];
    }];
}

#pragma mark - Button Handling

- (void)closeButtonTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

