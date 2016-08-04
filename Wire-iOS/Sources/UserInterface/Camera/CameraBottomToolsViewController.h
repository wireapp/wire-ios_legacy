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


#import <UIKit/UIKit.h>



@class CameraController;
@class ImageMetadata;


@protocol CameraBottomToolsViewControllerDelegate <NSObject>

- (void)cameraBottomToolsViewController:(id)controller didPickImageData:(NSData *)imageData imageMetadata:(ImageMetadata *)metadata;
- (void)cameraBottomToolsViewController:(id)controller didCaptureImageData:(NSData *)imageData imageMetadata:(ImageMetadata *)metadata;
- (void)cameraBottomToolsViewControllerDidCancel:(id)controller;

@end



@interface CameraBottomToolsViewController : UIViewController

@property (nonatomic) NSString *previewTitle;
@property (nonatomic, weak) id<CameraBottomToolsViewControllerDelegate> delegate;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCameraController:(CameraController *)cameraController NS_DESIGNATED_INITIALIZER;

@end
