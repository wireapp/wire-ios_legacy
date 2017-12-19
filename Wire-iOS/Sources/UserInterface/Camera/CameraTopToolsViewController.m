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


#import "CameraTopToolsViewController.h"

@import PureLayout;

#import "CameraController.h"
#import "Constants.h"
@import WireExtensionComponents;
#import "WAZUIMagicIOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import "Settings.h"
#import "DeviceOrientationObserver.h"
#import "WRFunctions.h"



@interface CameraTopToolsViewController ()

@property (nonatomic) CameraController *cameraController;
@property (nonatomic) ButtonWithLargerHitArea *toggleFlashButton;
@property (nonatomic) ButtonWithLargerHitArea *toggleCameraButton;
@property (nonatomic) BOOL initialConstraintsCreated;

@end



@implementation CameraTopToolsViewController

- (instancetype)initWithCameraController:(CameraController *)cameraController
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _cameraController = cameraController;
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.toggleFlashButton = [[ButtonWithLargerHitArea alloc] init];
    self.toggleFlashButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toggleFlashButton setImage:[UIImage imageForIcon:ZetaIconTypeFlashOff iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.toggleFlashButton addTarget:self action:@selector(cycleFlashMode:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleFlashButton];
    
    self.toggleCameraButton = [[ButtonWithLargerHitArea alloc] init];
    self.toggleCameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toggleCameraButton setImage:[UIImage imageForIcon:ZetaIconTypeCameraSwitch iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.toggleCameraButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    self.toggleCameraButton.accessibilityIdentifier = @"toggleCameraButton";
    [self.view addSubview:self.toggleCameraButton];
    self.toggleCameraButton.hidden = ! [self.cameraController isCameraAvailable:CameraControllerCameraBack];
    
    [self updateViewConstraints];
    
    if (IS_IPHONE) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:DeviceOrientationObserverDidDetectRotationNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateFlash];
    [self updateFlashVisibility];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        const CGFloat Margin = [WAZUIMagic floatForIdentifier:@"camera_overlay.margin"];
        
        [self.toggleFlashButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.toggleFlashButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:Margin];
        
        [self.toggleCameraButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.toggleCameraButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:Margin];
        
        self.initialConstraintsCreated = YES;
    }
}

- (UIImage *)imageForFlashMode:(AVCaptureFlashMode)flashMode
{
    switch (flashMode) {
        case AVCaptureFlashModeAuto:
            return [UIImage imageForIcon:ZetaIconTypeFlashAuto iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]];
            break;
            
        case AVCaptureFlashModeOn:
            return [UIImage imageForIcon:ZetaIconTypeFlashOn iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]];
            break;
            
        case AVCaptureFlashModeOff:
            return [UIImage imageForIcon:ZetaIconTypeFlashOff iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]];
            break;
    }
}

- (void)updateFlash
{
    [self.toggleFlashButton setImage:[self imageForFlashMode:self.cameraController.flashMode] forState:UIControlStateNormal];
}

- (void)updateFlashVisibility
{
    if ([self.cameraController isFlashModeSupported:AVCaptureFlashModeOn]) {
        self.toggleFlashButton.hidden = NO;
    } else {
        self.toggleFlashButton.hidden = YES;
    }
}

#pragma mark - Actions

- (IBAction)cycleFlashMode:(id)sender
{
    AVCaptureFlashMode currentFlashMode = self.cameraController.flashMode;
    AVCaptureFlashMode nextFlashMode = (currentFlashMode + 1) % (AVCaptureFlashModeAuto + 1);
    
    self.cameraController.flashMode = nextFlashMode;
    [self.toggleFlashButton setImage:[self imageForFlashMode:nextFlashMode] forState:UIControlStateNormal];
    
    [[Settings sharedSettings] setPreferredFlashMode:nextFlashMode];
}

- (IBAction)switchCamera:(id)sender
{
    if (self.cameraController.currentCamera == CameraControllerCameraFront) {
        self.cameraController.currentCamera = CameraControllerCameraBack;
    } else {
        self.cameraController.currentCamera = CameraControllerCameraFront;
    }
    
    [self updateFlashVisibility];
}

#pragma mark - Device Rotation

- (void)didRotate:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [(NSNumber *)notification.object integerValue];
    CGAffineTransform transform = WRDeviceOrientationToAffineTransform(deviceOrientation);
    
    [UIView animateWithDuration:0.2f animations:^{
        self.toggleFlashButton.transform = transform;
        self.toggleCameraButton.transform = transform;
    }];
}

@end
