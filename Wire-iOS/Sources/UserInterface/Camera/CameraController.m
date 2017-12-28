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


#import "CameraController.h"

#import <AVFoundation/AVFoundation.h>

#import "DeviceOrientationObserver.h"

NSString * const CameraControllerWillChangeCurrentCamera = @"CameraControllerWillChangeCurrentCamera";
NSString * const CameraControllerDidChangeCurrentCamera = @"CameraControllerDidChangeCurrentCamera";

NSString * const CameraControllerObservableSettingExposureDuration = @"CameraControllerObservableSettingExposureDuration";
NSString * const CameraControllerObservableSettingExposureTargetBias = @"CameraControllerObservableSettingExposureTargetBias";
NSString * const CameraControllerObservableSettingAdjustingExposure = @"CameraControllerObservableSettingAdjustingExposure";
NSString * const CameraControllerObservableSettingAdjustingFocus = @"CameraControllerObservableSettingAdjustingFocus";
NSString * const CameraControllerObservableSettingSubjectAreaDidChange = @"CameraControllerObservableSettingSubjectAreaDidChange";

NSString * const CameraSettingExposureDuration = @"exposureDuration";
NSString * const CameraSettingExposureTargetBias = @"exposureTargetBias";



@interface CameraController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, readwrite) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, readwrite) AVCaptureSession *session;

@property (nonatomic) AVCaptureDevice *frontCameraDevice;
@property (nonatomic) AVCaptureDevice *backCameraDevice;

@property (nonatomic) AVCaptureDeviceInput *frontCameraDeviceInput;
@property (nonatomic) AVCaptureDeviceInput *backCameraDeviceInput;

@property (nonatomic) AVCaptureVideoDataOutput *snapshotOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillCameraOutput;
@property (nonatomic) AVCaptureDevice *currentCameraDevice;
@property (nonatomic, readonly) AVCaptureConnection *snapshotConnection;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t snapshotQueue;

@property (nonatomic) NSMutableDictionary *observers;

@property (nonatomic, copy) void (^snapshotBlock)(UIImage *image);

@end


@implementation CameraController

- (instancetype)init {
    return [self initCameraController];
}

- (nullable instancetype)initCameraController {
#if TARGET_OS_SIMULATOR
    return nil;
#else
    self = [super init];
    
    if (self) {
        self.observers = [NSMutableDictionary dictionary];
        self.sessionQueue = dispatch_queue_create("com.wire.session_access_queue", DISPATCH_QUEUE_SERIAL);
        self.snapshotQueue = dispatch_queue_create("com.wire.snapshot_queue", DISPATCH_QUEUE_SERIAL);
        
        [self initializeSession];
        [self createPreviewLayer];
    }
    
    return self;
#endif
}

- (void)dealloc
{
    [self unobserveSettings];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initializeSession
{
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    if ([self.delegate respondsToSelector:@selector(cameraControllerAllowedAccessToCamera:)]) {
                        [self.delegate cameraControllerAllowedAccessToCamera:self];
                    }
                    [self configureSession];
                } else {
                    if ([self.delegate respondsToSelector:@selector(cameraControllerDeniedAccessToCamera:)]) {
                        [self.delegate cameraControllerDeniedAccessToCamera:self];
                    }
                }
            }];
        }
            break;
            
        case AVAuthorizationStatusAuthorized:
            [self configureSession];
            break;
            
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChangeNotification:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
}

- (void)configureSession
{
    [self configureDeviceInput];
    [self observeSettings];
    [self configureStillImageCameraOutput];
    [self configureSnapshotOutput];
}

- (BOOL)isCameraAccessDenied
{
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return authorizationStatus == AVAuthorizationStatusDenied || authorizationStatus == AVAuthorizationStatusRestricted;
}

- (void)createPreviewLayer
{
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
}

- (void)setCurrentCamera:(CameraControllerCamera)currentCamera
{
    if (! [self isCameraAvailable:currentCamera]) {
        return;
    }
    
    _currentCamera = currentCamera;
    
    if (self.session) {
        self.currentCameraDevice = currentCamera == CameraControllerCameraFront ? self.frontCameraDevice : self.backCameraDevice;
    }
}

- (BOOL)isCameraAvailable:(CameraControllerCamera)camera
{
    NSArray *availableCameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevicePosition devicePosition = camera == CameraControllerCameraFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    
    for (AVCaptureDevice *device in availableCameraDevices) {
        if (device.position == devicePosition) {
            return YES;
        }
    }
    
    return NO;
}

- (void)startRunning
{    
    [self performConfiguration:^{
        [self.session startRunning];
    }];
}

- (void)stopRunning
{
    [self performConfiguration:^{
        [self.session stopRunning];
    }];
}

- (void)registerObserver:(id<CameraSettingValueObserver>)observer setting:(NSString *)setting
{
    NSPointerArray *observersForSetting = [self.observers valueForKey:setting];
    
    if (! observersForSetting) {
        observersForSetting = [NSPointerArray weakObjectsPointerArray];
        self.observers[setting] = observersForSetting;
    }
    
    [observersForSetting addPointer:(__bridge  void *)observer];
}

- (void)unregisterObserver:(id<CameraSettingValueObserver>)observer setting:(NSString *)setting
{
    NSPointerArray *observersForSetting = [self.observers valueForKey:setting];
    
    for (NSUInteger i = 0; i < observersForSetting.count; i++) {
        if ([observersForSetting pointerAtIndex:i] == (__bridge void *)(observer)) {
            [observersForSetting removePointerAtIndex:i];
            break;
        }
    }
}

- (UIImage *)videoSnapshot
{
    if (! self.session.isRunning) {
        return nil;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block UIImage *snapshot = nil;
    dispatch_async(self.snapshotQueue, ^{
        self.snapshotBlock = ^(UIImage *image) {
            snapshot = image;
            dispatch_semaphore_signal(semaphore);
        };
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return snapshot;
}

- (AVCaptureConnection *)snapshotConnection
{
    return [self.snapshotOutput connectionWithMediaType:AVMediaTypeVideo];
}

#pragma mark - Observe Settings

- (void)observeSettings
{
    for (AVCaptureDevice *device in [self configuredDevices]) {
        [device addObserver:self forKeyPath:CameraSettingExposureDuration options:NSKeyValueObservingOptionNew context:NULL];
        [device addObserver:self forKeyPath:CameraSettingExposureTargetBias options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)unobserveSettings
{
    for (AVCaptureDevice *device in [self configuredDevices]) {
        [device removeObserver:self forKeyPath:CameraSettingExposureDuration];
        [device removeObserver:self forKeyPath:CameraSettingExposureTargetBias];
    }
}

- (NSArray *)configuredDevices
{
    NSMutableArray *array = [NSMutableArray array];
    
    if (self.frontCameraDevice) {
        [array addObject:self.frontCameraDevice];
    }
    
    if (self.backCameraDevice) {
        [array addObject:self.backCameraDevice];
    }
    
    return [array copy];
}

- (void)notifyObserversForSetting:(NSString *)setting value:(id)value
{
    NSPointerArray *observersForSetting = [self.observers valueForKey:setting];
    
    for (id<CameraSettingValueObserver> observer in observersForSetting) {
        [observer cameraSetting:setting changedValue:value];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object != self.currentCameraDevice) {
        return;
    }
    
    NSString *key = nil;
    id newValue = change[NSKeyValueChangeNewKey];
    
    if ([keyPath isEqualToString:CameraSettingExposureDuration]) {
        key = CameraControllerObservableSettingExposureDuration;
    }
    else if ([keyPath isEqualToString:CameraSettingExposureTargetBias]) {
        key = CameraControllerObservableSettingExposureTargetBias;
    }

    if (key != nil) {
        [self notifyObserversForSetting:key value:newValue];
    }
}

- (void)subjectAreaDidChangeNotification:(NSNotification *)notification
{
    [self notifyObserversForSetting:CameraControllerObservableSettingSubjectAreaDidChange value:nil];
}

#pragma mark - Configure Session

- (void)configureDeviceInput
{
    NSArray *availableCameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *cameraDevice in availableCameraDevices) {
        if (cameraDevice.position == AVCaptureDevicePositionBack) {
            self.backCameraDevice = cameraDevice;
        }
        else if (cameraDevice.position == AVCaptureDevicePositionFront) {
            self.frontCameraDevice = cameraDevice;
        }
    }
    
    if (self.backCameraDevice) {
        NSError *error = nil;
        if ([self.backCameraDevice lockForConfiguration:&error]) {
            self.backCameraDevice.subjectAreaChangeMonitoringEnabled = YES;
            [self.backCameraDevice unlockForConfiguration];
        }
        
        if (error == nil) {
            self.backCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backCameraDevice error:&error];
        }
        
        if (error != nil) {
            DDLogError(@"Error while configuring device input: %@", error);
        }
    }
    
    if (self.frontCameraDevice) {
        NSError *error = nil;
        if ([self.frontCameraDevice lockForConfiguration:&error]) {
            self.frontCameraDevice.subjectAreaChangeMonitoringEnabled = YES;
            [self.frontCameraDevice unlockForConfiguration];
        }
        
        if (error == nil) {
            self.frontCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.frontCameraDevice error:&error];
        }
        
        if (error != nil) {
            DDLogError(@"Error while configuring device input: %@", error);
        }
    }
    
    if ([self isCameraAvailable:self.currentCamera]) {
        self.currentCameraDevice = self.currentCamera == CameraControllerCameraFront ? self.frontCameraDevice : self.backCameraDevice;
    } else {
        self.currentCameraDevice = [self.configuredDevices firstObject];
    }
    
    _currentCamera = self.currentCameraDevice == self.frontCameraDevice ? CameraControllerCameraFront : CameraControllerCameraBack;
}

- (void)setCurrentCameraDevice:(AVCaptureDevice *)cameraDevice
{
    if (cameraDevice == self.currentCameraDevice) {
        return;
    }
    
    BOOL initialDeviceConfiguration = self.currentCameraDevice == nil;
    
    if (! initialDeviceConfiguration) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CameraControllerWillChangeCurrentCamera object:self];
    }
    
    AVCaptureDeviceInput *addedCameraDeviceInput = cameraDevice == self.frontCameraDevice ? self.frontCameraDeviceInput : self.backCameraDeviceInput;
    AVCaptureDeviceInput *removedCameraDeviceInput = self.currentCameraDevice == self.frontCameraDeviceInput.device ? self.frontCameraDeviceInput : self.backCameraDeviceInput;
    
    [self performConfiguration:^{
        [self.session beginConfiguration];
        
        [self.session removeInput:removedCameraDeviceInput];
        [self.session addInput:addedCameraDeviceInput];
        
        [self.session commitConfiguration];
    }];
    
    _currentCameraDevice = cameraDevice;
    
    if (! initialDeviceConfiguration) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CameraControllerDidChangeCurrentCamera object:self];
    }
}

- (void)configureSnapshotOutput
{
    [self performConfiguration:^{
        self.snapshotOutput = [[AVCaptureVideoDataOutput alloc] init];
        self.snapshotOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
        [self.snapshotOutput setSampleBufferDelegate:self queue:self.snapshotQueue];
        
        if([self.session canAddOutput:self.snapshotOutput]) {
            [self.session addOutput:self.snapshotOutput];
        }
    }];
}

- (void)setSnapshotVideoOrientation:(AVCaptureVideoOrientation)snapshotVideoOrientation
{
    [self performConfiguration:^{
        AVCaptureConnection *connection = self.snapshotConnection;
        if ([connection isVideoOrientationSupported]) {
            connection.videoOrientation = snapshotVideoOrientation;
        }
    }];
}

- (AVCaptureVideoOrientation)snapshotVideoOrientation
{
    return self.snapshotConnection.videoOrientation;
}

- (void)configureStillImageCameraOutput
{
    [self performConfiguration:^{
        self.stillCameraOutput = [[AVCaptureStillImageOutput alloc] init];
        self.stillCameraOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG,
                                                   AVVideoQualityKey : @0.9 };
        
        if ([self.session canAddOutput:self.stillCameraOutput]) {
            [self.session addOutput:self.stillCameraOutput];
        }
    }];
}

#pragma mark - Flash

- (void)setFlashMode:(AVCaptureFlashMode)flashMode
{
    [self performConfigurationOnCurrentCameraDevice:^(AVCaptureDevice *currentDevice) {
        if ([currentDevice isFlashModeSupported:flashMode]) {
            currentDevice.flashMode = flashMode;
        }
    }];
}

- (AVCaptureFlashMode)flashMode
{
    return self.currentCameraDevice.flashMode;
}

- (BOOL)isFlashModeSupported:(AVCaptureFlashMode)flashMode
{
    return [self.currentCameraDevice isFlashModeSupported:flashMode];
}

#pragma mark - Focus

- (void)lockFocusAtPointOfInterest:(CGPoint)point
{
    CGPoint pointInCamera = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    [self performConfigurationOnCurrentCameraDevice:^(AVCaptureDevice *currentDevice) {
        if (currentDevice.focusPointOfInterestSupported) {
            currentDevice.focusPointOfInterest = pointInCamera;
            currentDevice.focusMode = AVCaptureFocusModeAutoFocus;
        }
        
        if (currentDevice.exposurePointOfInterestSupported) {
            currentDevice.exposurePointOfInterest = pointInCamera;
            currentDevice.exposureMode = AVCaptureExposureModeAutoExpose;
        }
        
        [currentDevice setExposureTargetBias:0 completionHandler:nil];
    }];
}

- (void)enableContinousAutoFocus
{
    [self performConfigurationOnCurrentCameraDevice:^(AVCaptureDevice *currentDevice) {
        if (currentDevice.focusPointOfInterestSupported) {
            currentDevice.focusPointOfInterest = CGPointMake(0.5, 0.5);
        }
        
        if ([currentDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            currentDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        
        if ([currentDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            currentDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
        [currentDevice setExposureTargetBias:0 completionHandler:nil];
    }];
}

- (BOOL)isContinousAutoFocusSupported
{
    return [self.currentCameraDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
}

- (BOOL)isContinousAutoFocusEnabled
{
    return self.currentCameraDevice.focusMode == AVCaptureFocusModeContinuousAutoFocus;
}

- (void)setExposureBias:(CGFloat)exposureBias
{
    [self performConfigurationOnCurrentCameraDevice:^(AVCaptureDevice *currentDevice) {
        [currentDevice setExposureTargetBias:exposureBias completionHandler:nil];
    }];
}

- (CGFloat)exposureBias
{
    return self.currentCameraDevice.exposureTargetBias;
}

- (void)setExposureCompensation:(CGFloat)exposureCompensation
{
    exposureCompensation = MIN(MAX(0, exposureCompensation), 1);
    float exposureTargetBiasRange = self.currentCameraDevice.maxExposureTargetBias - self.currentCameraDevice.minExposureTargetBias;
    self.exposureBias = exposureCompensation * exposureTargetBiasRange + self.currentCameraDevice.minExposureTargetBias;
}

- (CGFloat)exposureCompensation
{
    float exposureTargetBiasRange = self.currentCameraDevice.maxExposureTargetBias - self.currentCameraDevice.minExposureTargetBias;
    return (self.currentCameraDevice.exposureTargetBias - self.currentCameraDevice.minExposureTargetBias) / exposureTargetBiasRange;
}

#pragma mark - Capture Photo

- (void)captureStillImageWithCompletionHandler:(void (^)(NSData * _Nullable imageData, NSDictionary * _Nullable metaData, NSError * _Nullable error))completionHandler;
{
    ///for iPad split/slide over mode, the session is not running
    if (!self.session.isRunning) {
        return;
    }

    dispatch_async(self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillCameraOutput connectionWithMediaType:AVMediaTypeVideo];
        UIDeviceOrientation deviceOrientation = [[DeviceOrientationObserver sharedInstance] deviceOrientation];
        __block AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;


        if (deviceOrientation == UIDeviceOrientationFaceDown || deviceOrientation == UIDeviceOrientationFaceUp) {
            // Face up/down can't be translated into a video orientation so we fall back to the orientation of the user interface
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            dispatch_async(dispatch_get_main_queue(), ^{
                videoOrientation = (AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation];
                dispatch_group_leave(group);
            });
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        }
        
        
        connection.videoOrientation = videoOrientation;
        connection.automaticallyAdjustsVideoMirroring = NO;
        connection.videoMirrored = NO;


        [self.stillCameraOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (error == nil) {

                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];

                NSDictionary *metaData = (__bridge NSDictionary *)(CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate));

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(imageData, metaData, nil);
                });
            } else {
                completionHandler(nil, nil, error);
            }
        }];
    });
}

- (void)performConfiguration:(void (^)())block
{
    dispatch_async(self.sessionQueue, block);
}

- (void)performConfigurationOnCurrentCameraDevice:(void (^)(AVCaptureDevice *currentDevice))configurationBlock
{
    AVCaptureDevice *currentDevice = self.currentCameraDevice;
    
    if (currentDevice) {
        [self performConfiguration:^{
            NSError *error = nil;
            if ([currentDevice lockForConfiguration:&error]) {
                configurationBlock(currentDevice);
                [currentDevice unlockForConfiguration];
            }
        }];
    }
}

#pragma mark - Capture Snapshot

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.snapshotBlock != nil) {
        UIImageOrientation imageOrientation = UIImageOrientationUp;
        if (self.currentCameraDevice == self.frontCameraDevice) {
            imageOrientation = UIImageOrientationUpMirrored;
        }
        
        self.snapshotBlock([self imageFromSampleBuffer:sampleBuffer imageOrientation:imageOrientation]);
        self.snapshotBlock = nil;
    }
}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer imageOrientation:(UIImageOrientation)imageOrientation
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(baseAddress, width,
                                                 height, 8,
                                                 bytesPerRow, colorSpace,
                                                 kCGBitmapByteOrder32Little |
                                                 kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:imageOrientation];
    CGImageRelease(quartzImage);
    
    return (image);
}

@end
