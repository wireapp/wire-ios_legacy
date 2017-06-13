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


#import "CameraControlsViewController.h"

@import PureLayout;
#import <AVFoundation/AVFoundation.h>

#import "CameraController.h"
#import "CameraFocusRing.h"
#import "CameraExposureSlider.h"
#import "UIFont+MagicAccess.h"
#import "Wire-Swift.h"

#import "WAZUIMagicIOS.h"



static NSTimeInterval RefocusTimeoutInterval = 1;



static float clampValue(float value, float min, float max) {
    return MIN(MAX(value, min), max);
}

static float normalizeValue(float value, float min, float max) {
    return (value - min) / (max - min);
}

@interface CameraControlsViewController () <CameraSettingValueObserver>

@property (nonatomic) CameraController *cameraController;

@property (nonatomic) UITapGestureRecognizer *focusGestureRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *focusLockGestureRecognizer;
@property (nonatomic) UIPanGestureRecognizer *exposureGestureRecognizer;

@property (nonatomic) CameraFocusRing *focusRing;
@property (nonatomic) CameraExposureSlider *exposureSlider;

@property (nonatomic) UILabel *focusExposureLockLabel;
@property (nonatomic) UIView *focusExposureLockLabelContainer;

@property (nonatomic) CGFloat initialExposureValue;
@property (nonatomic, readonly) CGFloat maxExposureCompensation;
@property (nonatomic, readonly) CGFloat minExposureCompensation;

@property (nonatomic) NSTimeInterval lastRefocusInterval;
@property (nonatomic) BOOL focusAndExposureIsLocked;
@property (nonatomic) BOOL cameraControlsAreEnabled;

@property (nonatomic) BOOL initialConstraintsCreated;

@end

@implementation CameraControlsViewController

- (instancetype)initWithCameraController:(CameraController *)cameraController
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _cameraController = cameraController;
        
        _minExposureCompensation = 0.2;
        _maxExposureCompensation = 0.8;
        
        [self.cameraController registerObserver:self setting:CameraControllerObservableSettingExposureTargetBias];
        [self.cameraController registerObserver:self setting:CameraControllerObservableSettingSubjectAreaDidChange];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cameraControllerDidChangeCurrentCamera:)
                                                     name:CameraControllerDidChangeCurrentCamera
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.focusGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusOnTap:)];
    self.focusLockGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lockFocusOnLongPress:)];
    self.exposureGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(adjustExposureOnPan:)];
    
    self.focusLockGestureRecognizer.minimumPressDuration = 1;
    
    [self.view addGestureRecognizer:self.focusGestureRecognizer];
    [self.view addGestureRecognizer:self.focusLockGestureRecognizer];
    [self.view addGestureRecognizer:self.exposureGestureRecognizer];
    
    self.focusRing = [[CameraFocusRing alloc] init];
    self.focusRing.backgroundColor = [UIColor clearColor];
    self.focusRing.alpha = 0;
    [self.view addSubview:self.focusRing];
    
    self.exposureSlider = [[CameraExposureSlider alloc] init];
    self.exposureSlider.backgroundColor = [UIColor clearColor];
    [self.exposureSlider setNeedsDisplay];
    [self.view addSubview:self.exposureSlider];
    
    self.focusExposureLockLabelContainer = [[UIView alloc] initForAutoLayout];
    self.focusExposureLockLabelContainer.backgroundColor = [UIColor whiteColor];
    self.focusExposureLockLabelContainer.layer.cornerRadius = 8;
    self.focusExposureLockLabelContainer.hidden = YES;
    [self.view addSubview:self.focusExposureLockLabelContainer];
    
    self.focusExposureLockLabel = [[UILabel alloc] initForAutoLayout];
    self.focusExposureLockLabel.text = [NSLocalizedString(@"camera_controls.aeaf_lock", nil) uppercasedWithCurrentLocale];
    self.focusExposureLockLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"];
    self.focusExposureLockLabel.textColor = [UIColor blackColor];
    [self.focusExposureLockLabelContainer addSubview:self.focusExposureLockLabel];
    
    [self updateViewConstraints];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        [self.focusExposureLockLabelContainer autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
        [self.focusExposureLockLabelContainer autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.focusExposureLockLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(1, 8, 2, 8)];
        
        self.initialConstraintsCreated = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setInitialValues];
}

- (void)setFocusAndExposureIsLocked:(BOOL)focusAndExposureIsLocked
{
    _focusAndExposureIsLocked = focusAndExposureIsLocked;
    self.focusExposureLockLabelContainer.hidden = ! focusAndExposureIsLocked;
}

#pragma mark - Actions

- (void)resetFocus
{    
    if (self.cameraController.isContinousAutoFocusEnabled ||
        self.focusAndExposureIsLocked) {
        return;
    }
    
    if ([NSDate timeIntervalSinceReferenceDate] - self.lastRefocusInterval > RefocusTimeoutInterval) {
        self.cameraControlsAreEnabled = NO;
        self.lastRefocusInterval = [NSDate timeIntervalSinceReferenceDate];
        
        if (self.cameraController.isContinousAutoFocusSupported) {
            [self animateContinousAutoFocus];
            [self.cameraController enableContinousAutoFocus];
        } else {
            [self animateResetFocus];
            [self.cameraController enableContinousAutoFocus];
        }
    }
}

- (void)focusOnTap:(UITapGestureRecognizer *)tapRecognizer
{
    [self animateFocusRingAtPoint:[tapRecognizer locationInView:self.view]];
    [self.cameraController lockFocusAtPointOfInterest:[tapRecognizer locationInView:self.view]];
    self.focusAndExposureIsLocked = NO;
    self.cameraControlsAreEnabled = YES;
}

- (void)lockFocusOnLongPress:(UILongPressGestureRecognizer *)longPressRecognizer
{
    if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {
        [self animateFocusRingAtPoint:[longPressRecognizer locationInView:self.view]];
        [self.cameraController lockFocusAtPointOfInterest:[longPressRecognizer locationInView:self.view]];
        self.focusAndExposureIsLocked = YES;
        self.cameraControlsAreEnabled = YES;
    }
}

- (void)adjustExposureOnPan:(UIPanGestureRecognizer *)panRecognizer
{
    if (! self.cameraControlsAreEnabled) {
        return;
    }
    
    if (panRecognizer.state == UIGestureRecognizerStateBegan) {
        self.initialExposureValue = self.cameraController.exposureCompensation;
    }
    
    CGPoint translation = [panRecognizer translationInView:self.view];
    float newExposureBias = self.initialExposureValue - translation.y / 1200;
    self.cameraController.exposureCompensation = clampValue(newExposureBias, self.minExposureCompensation, self.maxExposureCompensation);
    self.lastRefocusInterval = [NSDate timeIntervalSinceReferenceDate]; // Prevent re-focus when changing the exposure.
}

#pragma mark - Animations

- (void)animateResetFocus
{
    [UIView animateWithDuration:0.35 delay:0 options:0 animations:^{
        self.focusRing.alpha = 0;
        self.exposureSlider.alpha = 0;
    } completion:nil];
}

- (void)animateContinousAutoFocus
{
    const CGFloat startSize = [WAZUIMagic floatForIdentifier:@"camera_overlay.focus_ring.autofocus.start_size"];
    const CGFloat endSize = [WAZUIMagic floatForIdentifier:@"camera_overlay.focus_ring.autofocus.end_size"];
    
    CGSize fromSize = CGSizeMake(startSize, startSize);
    CGSize toSize = CGSizeMake(endSize, endSize);
    
    CGPoint point = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    CGRect fromRect = CGRectMake(point.x - fromSize.width / 2 , point.y - fromSize.height / 2, fromSize.width, fromSize.height);
    CGRect toRect = CGRectMake(point.x - toSize.width / 2 , point.y - toSize.height / 2, toSize.width, toSize.height);

    self.focusRing.frame = fromRect;
    self.focusRing.alpha = 0.5;
    self.exposureSlider.alpha = 0;
    
    [UIView animateWithDuration:0.55 animations:^{
        self.focusRing.alpha = 1;
        self.focusRing.frame = toRect;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.35 delay:1 options:0 animations:^{
            self.focusRing.alpha = 0;
        } completion:nil];
    }];
}

- (void)animateFocusRingAtPoint:(CGPoint)point
{
    const CGFloat startSize = [WAZUIMagic floatForIdentifier:@"camera_overlay.focus_ring.tap_to_focus.start_size"];
    const CGFloat endSize = [WAZUIMagic floatForIdentifier:@"camera_overlay.focus_ring.tap_to_focus.end_size"];
    
    CGSize fromSize = CGSizeMake(startSize, startSize);
    CGSize toSize = CGSizeMake(endSize, endSize);
    
    CGRect fromRect = CGRectMake(point.x - fromSize.width / 2 , point.y - fromSize.height / 2, fromSize.width, fromSize.height);
    CGRect toRect = CGRectMake(point.x - toSize.width / 2 , point.y - toSize.height / 2, toSize.width, toSize.height);
    
    self.focusRing.frame = fromRect;
    
    const CGFloat exposuseSliderHeight = [WAZUIMagic floatForIdentifier:@"camera_overlay.exposure_slider_height"];
    const CGFloat exposureSliderMargin = 10;
    const CGFloat exposureSliderWidth = self.exposureSlider.intrinsicContentSize.width;
    CGRect leftSideRect = CGRectMake(toRect.origin.x - exposureSliderMargin - exposureSliderWidth, CGRectGetMidY(toRect) - exposuseSliderHeight / 2, exposureSliderWidth, exposuseSliderHeight);
    CGRect rightSideRect = CGRectMake(CGRectGetMaxX(toRect) + exposureSliderMargin, CGRectGetMidY(toRect) - exposuseSliderHeight / 2, exposureSliderWidth, exposuseSliderHeight);
    
    if (CGRectContainsRect(self.view.bounds, leftSideRect)) {
        self.exposureSlider.frame = leftSideRect;
    } else {
        self.exposureSlider.frame = rightSideRect;
    }
    
    self.exposureSlider.alpha = 0;
    self.focusRing.alpha = 0.5;
    
    [UIView animateWithDuration:0.35 animations:^{
        self.focusRing.alpha = 1;
        self.focusRing.frame = toRect;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            self.exposureSlider.alpha = 1;
        }];
    }];
}

#pragma mark - CameraController Notifications

- (void)cameraControllerDidChangeCurrentCamera:(NSNotification *)notification
{
    self.focusAndExposureIsLocked = NO;
    [self resetFocus];
}

#pragma mark - CameraSettingValueObserver

- (void)setInitialValues
{
    self.exposureSlider.value = 1.0 - normalizeValue(self.cameraController.exposureCompensation, self.minExposureCompensation, self.maxExposureCompensation);
}

- (void)cameraSetting:(NSString *)setting changedValue:(id)value
{
    if ([setting isEqualToString:CameraControllerObservableSettingExposureTargetBias]) {
        self.exposureSlider.value = 1.0 - normalizeValue(self.cameraController.exposureCompensation, self.minExposureCompensation, self.maxExposureCompensation);
    }
    else if ([setting isEqualToString:CameraControllerObservableSettingSubjectAreaDidChange]) {
        [self resetFocus];
    }
}

@end
