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
@class CameraViewController;
@class AnalyticsTracker;
@class ImageMetadata;


typedef NS_ENUM(NSInteger, CameraViewControllerCamera) {
    CameraViewControllerCameraFront,
    CameraViewControllerCameraBack
};

typedef NS_ENUM(NSInteger, CameraViewControllerPreviewSize) {
    CameraViewControllerPreviewSizePreserveAspectRatio,
    CameraViewControllerPreviewSizeFullscreen
};


@protocol CameraViewControllerDelegate <NSObject>

- (void)cameraViewControllerDidCancel:(CameraViewController *)cameraViewController;
- (void)cameraViewController:(CameraViewController *)cameraViewController didPickImageData:(NSData *)imageData imageMetadata:(ImageMetadata *)metadata;

@end


@interface CameraViewController : UIViewController

@property (nonatomic, copy) NSString *previewTitle;
@property (nonatomic) CameraViewControllerCamera defaultCamera;
@property (nonatomic) CameraViewControllerPreviewSize preferedPreviewSize;
@property (nonatomic, weak) id <CameraViewControllerDelegate> delegate;
@property (nonatomic) AnalyticsTracker *analyticsTracker;
@property (nonatomic) BOOL savePhotosToCameraRoll;
@property (nonatomic) BOOL disableSketch;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCameraController:(CameraController *)cameraController NS_DESIGNATED_INITIALIZER;

@end
