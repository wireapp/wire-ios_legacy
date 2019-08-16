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


#import <Foundation/Foundation.h>

/// Shows a confirmation dialog after picking an image in UIImagePickerController. If the user accepts
/// the image the imagePickedBlock is called.
@interface ImagePickerConfirmationController : NSObject <UINavigationControllerDelegate>

@property (nonatomic, copy) NSString *previewTitle;
@property (nonatomic, copy) void (^imagePickedBlock)(NSData *imageData);

///TODO: private
/// We need to store this reference to close the @c SketchViewController
@property (nonatomic) UIImagePickerController *presentingPickerController;

@end
