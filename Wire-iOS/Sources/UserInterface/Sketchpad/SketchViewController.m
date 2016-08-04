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


#import "SketchViewController.h"

#import "Logging.h"
#import "BackgroundViewController.h"
#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>
#import "UIImage+ZetaIconsNeue.h"
#import "SketchBottomView.h"
#import "SketchTopView.h"
#import "ColorPickerController+AccentColors.h"
#import "UIColor+WAZExtensions.h"
#import <PureLayout/PureLayout.h>
#import <SmoothLineView/SmoothLineView.h>
#import "WireStyleKit.h"
#import "IdentifiableColor+AccentColors.h"
#import "WAZUIMagicIOS.h"
#import "Constants.h"
#import "ZMUser+Additions.h"
#import "UIView+WR_Snapshot.h"
#import <CoreMotion/CoreMotion.h>
#import "UIViewController+Orientation.h"
#import "SketchColorPickerController.h"
#import "NSString+Wire.h"

#import "DeviceOrientationObserver.h"
#import "WRFunctions.h"
#import "UIImage+Transform.h"
#import "Wire-Swift.h"


static const CGFloat SketchBrushWidthThin = 6;



@interface UIImageView (Additions)

- (CGRect)calculateClientRectOfDisplayedImage;

@end

@implementation UIImageView (Additions)

- (CGRect)calculateClientRectOfDisplayedImage
{
    CGSize imgViewSize = self.frame.size;
    CGSize imgSize = self.image.size;
    
    // Calculate the aspect for UIViewContentModeScaleAspectFit
    CGFloat scaleW = imgViewSize.width / imgSize.width;
    CGFloat scaleH = imgViewSize.height / imgSize.height;
    CGFloat aspect = fmin(scaleW, scaleH);
    
    CGRect imageRect = { {0,0} , { imgSize.width * aspect, imgSize.height * aspect } };
    
    // Center image
    imageRect.origin.x = (imgViewSize.width - imageRect.size.width) / 2;
    imageRect.origin.y = (imgViewSize.height - imageRect.size.height) / 2;
    
    // Add imageView offset
    imageRect.origin.x += self.frame.origin.x;
    imageRect.origin.y += self.frame.origin.y;
    
    return imageRect;
}

@end



@interface SketchViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) BackgroundViewController *backgroundViewController;
/// Contains the user controls
@property (nonatomic) SketchBottomView *bottomView;
@property (nonatomic) SketchTopView *topView;
@property (nonatomic) BOOL initialConstraintsCreated;
/// The canvas container view. Contains the @c sketchView and the possible canvas image. We take the screen shot from this view.
@property (nonatomic) UIView *canvasView;
@property (nonatomic) UIImageView *canvasImageView;

@property (nonatomic) LVSmoothLineView *sketchView;
@property (nonatomic) UILabel *hintLabel;
@property (nonatomic) UIView *hintLabelUnderlayView;
@property (nonatomic) SketchColorPickerController *colorPickerController;

@end

@interface SketchViewController (ColorPicker) <SketchColorPickerControllerDelegate>
@end

@interface SketchViewController (SmoothLineViewDelegate) <LVSmoothLineViewDelegate>
@end

@implementation SketchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setUpBackgroundViewController];
    
    self.canvasView = [[UIView alloc] initForAutoLayout];
    self.canvasView.backgroundColor = [UIColor whiteColor];
    self.canvasView.opaque = YES;
    [self.view addSubview:self.canvasView];
    
    self.canvasImageView = [[UIImageView alloc] initForAutoLayout];
    self.canvasImageView.backgroundColor = [UIColor clearColor];
    self.canvasImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.canvasImageView.hidden = YES;
    [self.canvasView addSubview:self.canvasImageView];
    
    [self setUpSmoothLineView];
    [self setUpTopView];
    [self setUpBottomView];
    [self setUpColorPickerController];
    [self setUpHintLabel];
    
    self.topView.titleLabel.text = self.sketchTitle;

    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureRecognized:)];
    rotationRecognizer.delegate = self;
    [self.sketchView addGestureRecognizer:rotationRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:DeviceOrientationObserverDidDetectRotationNotification object:nil];
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    [self.bottomView updateButtonsOrientationWithDeviceOrientation:deviceOrientation];
    self.hintLabel.transform = WRDeviceOrientationToAffineTransform(deviceOrientation);
    
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[DeviceOrientationObserver sharedInstance] startMonitoringDeviceOrientation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[DeviceOrientationObserver sharedInstance] stopMonitoringDeviceOrientation];
}

- (void)setUpBackgroundViewController
{
    self.backgroundViewController = [BackgroundViewController new];
    self.backgroundViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundViewController.blurPercent = 1.0;
    self.backgroundViewController.forceFullScreen = YES;
    
    [self addChildViewController:self.backgroundViewController];
    [self.view addSubview:self.backgroundViewController.view];
    [self.backgroundViewController didMoveToParentViewController:self];
}

- (void)setUpSmoothLineView
{
    self.sketchView = [[LVSmoothLineView alloc] initForAutoLayout];
    self.sketchView.backgroundColor = [UIColor clearColor];
    self.sketchView.delegate = self;
    self.sketchView.opaque = NO;
    self.sketchView.brush.lineWidth = SketchBrushWidthThin;
    [self.canvasView addSubview:self.sketchView];
}

- (void)setUpColorPickerController
{    
    NSArray *sketchColors = @[[UIColor blackColor],
                              [UIColor whiteColor],
                              [UIColor colorForZMAccentColor:ZMAccentColorStrongBlue],
                              [UIColor colorForZMAccentColor:ZMAccentColorStrongLimeGreen],
                              [UIColor colorForZMAccentColor:ZMAccentColorBrightYellow],
                              [UIColor colorForZMAccentColor:ZMAccentColorVividRed],
                              [UIColor colorForZMAccentColor:ZMAccentColorBrightOrange],
                              [UIColor colorForZMAccentColor:ZMAccentColorSoftPink],
                              [UIColor colorForZMAccentColor:ZMAccentColorViolet],
                              [UIColor cas_colorWithHex:@"#96bed6"],
                              [UIColor cas_colorWithHex:@"#a3eba3"],
                              [UIColor cas_colorWithHex:@"#fee7a3"],
                              [UIColor cas_colorWithHex:@"#fda5a5"],
                              [UIColor cas_colorWithHex:@"#ffd4a3"],
                              [UIColor cas_colorWithHex:@"#fec4e7"],
                              [UIColor cas_colorWithHex:@"#dba3fe"],
                              [UIColor cas_colorWithHex:@"#a3a3a3"]];
    
    self.colorPickerController = [[SketchColorPickerController alloc] initWithNibName:nil bundle:nil];
    self.colorPickerController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.colorPickerController.delegate = self;
    
    [self addChildViewController:self.colorPickerController];
    [self.topView addSubview:self.colorPickerController.view];
    [self.colorPickerController didMoveToParentViewController:self];
    
    self.colorPickerController.sketchColors = sketchColors;
    
    // Pre-select with the user accent color
    UIColor *selectedColor = nil;
    __block NSInteger accentColorIndex = NSNotFound;
    [sketchColors enumerateObjectsUsingBlock:^(UIColor *color, NSUInteger idx, BOOL *stop) {
        if ([color isEqual:[UIColor accentColor]]) {
            accentColorIndex = idx;
            *stop = YES;
        }
    }];
    if (accentColorIndex != NSNotFound) {
        self.colorPickerController.selectedColorIndex = accentColorIndex;
        selectedColor = sketchColors[accentColorIndex];
    } else {
        selectedColor = [sketchColors firstObject];
    }
    [self sketchColorPickerController:self.colorPickerController changedSelectedColor:selectedColor];
}

- (void)setUpTopView
{
    self.topView = [[SketchTopView alloc] initForAutoLayout];
    [self.view addSubview:self.topView];
}

- (void)setUpBottomView
{
    SketchBottomView *bottomView = [SketchBottomView newAutoLayoutView];
    [self.view addSubview:bottomView];
    self.bottomView = bottomView;
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedOnUndo:)];
    longPressRecognizer.minimumPressDuration = 1.28;
    [bottomView.undoButton addGestureRecognizer:longPressRecognizer];
    
    [bottomView.undoButton addTarget:self action:@selector(undoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView.confirmButton addTarget:self action:@selector(confirmButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpHintLabel
{
    self.hintLabelUnderlayView = [UIView newAutoLayoutView];
    self.hintLabelUnderlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    self.hintLabelUnderlayView.hidden = YES;
    [self.view addSubview:self.hintLabelUnderlayView];

    self.hintLabel = [UILabel newAutoLayoutView];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.numberOfLines = 0;
    self.hintLabel.text = [NSLocalizedString(@"sketchpad.initial_hint", "") uppercaseStringWithCurrentLocale];
    [self.view addSubview:self.hintLabel];
}

- (void)setSketchTitle:(NSString *)sketchTitle
{
    _sketchTitle = [sketchTitle uppercaseStringWithCurrentLocale];
    
    self.topView.titleLabel.text = _sketchTitle;
    [self.topView.titleLabel sizeToFit];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (self.initialConstraintsCreated) {
        return;
    }
    
    // Background
    [self.backgroundViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    [self.topView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.topView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.topView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [self.topView autoSetDimension:ALDimensionHeight toSize:100];
    
    [self.topView.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:36];
    [self.topView.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.topView.titleLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.topView withOffset:-100];
    
    
    // Color picker
    [self.colorPickerController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topView.titleLabel withOffset:0];
    [self.colorPickerController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.colorPickerController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.colorPickerController.view autoSetDimension:ALDimensionHeight toSize:40];
    
    // Draw canvas
    [self.canvasView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topView];
    [self.canvasView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.canvasView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.canvasView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomView];
    
    [self.canvasImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.sketchView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    // Bottom view
    [self.bottomView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    [self.bottomView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [self.bottomView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
    
    [self.hintLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.hintLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.hintLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:1.0f relation:NSLayoutRelationLessThanOrEqual];
    
    [self.hintLabelUnderlayView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sketchView];
    [self.hintLabelUnderlayView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.sketchView];
    [self.hintLabelUnderlayView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topView];
    [self.hintLabelUnderlayView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    
    self.initialConstraintsCreated = YES;
}

- (void)setCanvasBackgroundImage:(UIImage *)canvasImage
{
    _canvasBackgroundImage = canvasImage;
    
    if (! canvasImage) {
        self.canvasImageView.image = nil;
        self.canvasImageView.hidden = YES;
        self.hintLabelUnderlayView.hidden = YES;
    }
    else {
        self.canvasImageView.image = canvasImage;
        self.canvasImageView.hidden = NO;
        self.hintLabelUnderlayView.hidden = NO;
        self.hintLabel.textColor = [UIColor whiteColor];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
 
    // The cheap way to hide the hint label: Just hide it on any action
    self.hintLabel.hidden = YES;
    self.hintLabelUnderlayView.hidden = YES;
    [self.hintLabel removeFromSuperview];
    self.hintLabel = nil;
}

- (void)longPressedOnUndo:(UILongPressGestureRecognizer *)regognizer
{
    // Clear the whole canvas on long press
    if (regognizer.state == UIGestureRecognizerStateBegan) {
        [self.sketchView clear];
    }
}

- (void)rotationGestureRecognized:(UIRotationGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        self.canvasImageView.transform = CGAffineTransformRotate(self.canvasImageView.transform, recognizer.rotation);
        recognizer.rotation = 0;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat degrees = atan2f(self.canvasImageView.transform.b, self.canvasImageView.transform.a);
        CGFloat rotationAngle = nearbyintf(degrees / M_PI_2) * M_PI_2;
        self.canvasImageView.transform = CGAffineTransformMakeRotation(rotationAngle);
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)undoButtonPressed:(id)sender
{
    [self.sketchView undo];
}

- (void)cancelButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(sketchViewControllerDidCancel:)]) {
        [self.delegate sketchViewControllerDidCancel:self];
    }
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (self.canvasImageView.image) {
        self.canvasImageView.hidden = ! self.canvasImageView.isHidden;
    }
}

- (void)confirmButtonPressed:(id)sender
{
    // Has anything been drew check
    if (! [self.sketchView canUndo] && !self.confirmsWithoutSketch) {
        [self cancelButtonPressed:nil];
        return;
    }

    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    // In case the user is drawing on landscape, we need to rotate the final
    // image, cause the sketch view controller only support portrait and the
    // posted image would be posted in wrong orientation
    BOOL finalImageNeedsBeRotated = (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight);
    UIImage *combinedImage = [self createBackgroundAndSketchCombinedImageAndStretchDrawBoxHorizontally:! finalImageNeedsBeRotated];
    if (finalImageNeedsBeRotated) {
        combinedImage = [combinedImage wr_imageRotatedByDegrees:(orientation == UIDeviceOrientationLandscapeLeft) ? -90: 90];
    }
    [self.delegate sketchViewController:self didSketchImage:combinedImage];
}

- (UIImage *)createBackgroundAndSketchCombinedImageAndStretchDrawBoxHorizontally:(BOOL)stretchFinalBoxHorizontally
{
    CGRect finalBox = [self.sketchView drawingBox];
    
    if (! self.canvasImageView.isHidden) {
        CGRect imageDrawRect = [self.canvasImageView calculateClientRectOfDisplayedImage];
        finalBox = CGRectUnion(finalBox, imageDrawRect);
    }
    
    UIImage *combinedImage = [self.canvasView wr_snapshotImage];
    
    // Prepare the final draw box:
    // We stretching the final box horizontally (x=0, width=full draw area
    // width) or vertically (y=0, height=full draw area height) and combining
    // those with the draw box on the sketch to have a rectangle image of the
    // drawing. This way the final image goes from one corner to other corner
    // in the conversation view
    const CGFloat verticalPadding = self.canvasImageView.isHidden ? 24: -1;
    if (stretchFinalBoxHorizontally) {
        finalBox.origin.x = 0;
        finalBox.size.width = self.sketchView.frame.size.width;
        finalBox = CGRectInset(finalBox, 0, -verticalPadding);
        finalBox.origin.y = MAX(0, finalBox.origin.y);
        finalBox.size.height = MIN(finalBox.size.height, self.canvasView.frame.size.height);
    } else {
        finalBox.origin.y = 0;
        finalBox.size.height = self.sketchView.frame.size.height;
        finalBox = CGRectInset(finalBox, 0, -verticalPadding);
        finalBox.origin.x = MAX(0, finalBox.origin.x);
        finalBox.size.width = MIN(finalBox.size.width, self.canvasView.frame.size.width);
    }
    
    // Scale the box, in case of retina
    finalBox.size.height = finalBox.size.height * [combinedImage scale];
    finalBox.size.width = finalBox.size.width * [combinedImage scale];
    finalBox.origin.x = finalBox.origin.x * [combinedImage scale];
    finalBox.origin.y = finalBox.origin.y * [combinedImage scale];

    // Crop the image with the final box
    CGImageRef imageRef = CGImageCreateWithImageInRect([combinedImage CGImage], finalBox);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef scale:[combinedImage scale] orientation:[combinedImage imageOrientation]];
    CGImageRelease(imageRef);
    
    return cropped;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    DDLogWarn(@"Memory warning %s", __FUNCTION__);
}

- (void)deviceDidRotate:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [(NSNumber *)notification.object integerValue];
    [self.bottomView updateButtonsOrientationWithDeviceOrientation:deviceOrientation];
    CGAffineTransform transform = WRDeviceOrientationToAffineTransform(deviceOrientation);
    
    [UIView animateWithDuration:0.2f animations:^{
        self.hintLabel.transform = transform;
    }];
}

@end

@implementation SketchViewController (ColorPicker)

- (void)sketchColorPickerController:(SketchColorPickerController *)controller changedSelectedColor:(UIColor *)color
{
    self.sketchView.brush.color = color;
    NSUInteger brushWidth = [controller brushWidthForColor:color];
    self.sketchView.brush.lineWidth = brushWidth;
}

@end

@implementation SketchViewController (SmoothLineViewDelegate)

- (void)smoothLineViewLongPressed:(LVSmoothLineView *)view
{
    UIColor *currentColor = self.colorPickerController.selectedColor;
    [self.sketchView fillWithColor:currentColor];
}

@end
