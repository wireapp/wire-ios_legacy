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
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const CameraControllerWillChangeCurrentCamera;
FOUNDATION_EXTERN NSString * const CameraControllerDidChangeCurrentCamera;

FOUNDATION_EXTERN NSString * const CameraControllerObservableSettingExposureDuration;
FOUNDATION_EXTERN NSString * const CameraControllerObservableSettingExposureTargetBias;
FOUNDATION_EXTERN NSString * const CameraControllerObservableSettingAdjustingExposure;
FOUNDATION_EXTERN NSString * const CameraControllerObservableSettingAdjustingFocus;
FOUNDATION_EXTERN NSString * const CameraControllerObservableSettingSubjectAreaDidChange;



typedef NS_ENUM(NSInteger, CameraControllerCamera) {
    CameraControllerCameraFront,
    CameraControllerCameraBack
};



@protocol CameraSettingValueObserver <NSObject>

- (void)cameraSetting:(NSString *)setting changedValue:(id)value;

@end



@protocol CameraControllerDelegate <NSObject>

- (void)cameraControllerDeniedAccessToCamera:(id)controller;

@optional
- (void)cameraControllerAllowedAccessToCamera:(id)controller;

@end



@interface CameraController : NSObject

@property (nonatomic, weak, nullable) id<CameraControllerDelegate> delegate;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic) CameraControllerCamera currentCamera;
@property (nonatomic) AVCaptureFlashMode flashMode;
@property (nonatomic) CGFloat exposureBias;
@property (nonatomic) CGFloat exposureCompensation;
@property (nonatomic, readonly, nullable) UIImage *videoSnapshot;
@property (nonatomic) AVCaptureVideoOrientation snapshotVideoOrientation;

@property (nonatomic, readonly) BOOL isContinousAutoFocusSupported;
@property (nonatomic, readonly) BOOL isContinousAutoFocusEnabled;
@property (nonatomic, readonly) BOOL isCameraAccessDenied;

- (nullable instancetype)initCameraController NS_DESIGNATED_INITIALIZER;

- (void)startRunning;
- (void)stopRunning;

- (BOOL)isFlashModeSupported:(AVCaptureFlashMode)flashMode;
- (BOOL)isCameraAvailable:(CameraControllerCamera)camera;

- (void)enableContinousAutoFocus;
- (void)lockFocusAtPointOfInterest:(CGPoint)point;

- (void)captureStillImageWithCompletionHandler:(void (^)(NSData * _Nullable imageData, NSDictionary * _Nullable metaData, NSError * _Nullable error))completionHandler;

/// Register an observer for a camera setting. The observer is not retained.
- (void)registerObserver:(id<CameraSettingValueObserver>)observer setting:(NSString *)setting;

/// Unregister an observer for a camera setting.
- (void)unregisterObserver:(id<CameraSettingValueObserver>)observe setting:(NSString *)setting;

@end

NS_ASSUME_NONNULL_END
