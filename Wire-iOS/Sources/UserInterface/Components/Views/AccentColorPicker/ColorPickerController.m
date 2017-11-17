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


#import "ColorPickerController.h"

#import "ColorPickerController+Internal.h"
#import "ColorPickerView.h"
#import "ColorPickerKnobView.h"
#import "ColorBandsView.h"
#import "IdentifiableColor.h"
#import "UIColor+WAZExtensions.h"
#import "Geometry.h"



@interface ColorPickerController () <ColorPickerViewDelegate>

@property (nonatomic, assign) CGFloat circleTargetX;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSUInteger displayLinksInFlight;

@property (nonatomic, strong) ColorPickerView *colorPickerView;

@property (nonatomic, strong, readwrite) NSArray *colors;

@end



@implementation ColorPickerController

- (instancetype)initWithColors:(NSArray *)colors
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.displayLinksInFlight = 0;
        self.colors = colors;
    }
    return self;
}

- (void)dealloc
{
    if (self.displayLinksInFlight) {
        // force-release the displaylink
        self.displayLinksInFlight = 0;
        [self releaseDisplayLink];
    }
}


- (void)loadView
{
    self.colorPickerView = [[ColorPickerView alloc] initWithColors:self.colors];
    self.colorPickerView.accessibilityIdentifier = @"AccentColorPickerView";
    self.view = self.colorPickerView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
    longPressRecognizer.minimumPressDuration = 0.7;
    [self.view addGestureRecognizer:longPressRecognizer];
    
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self.view addGestureRecognizer:tapper];

    self.panner = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.colorPickerView.knobView addGestureRecognizer:self.panner];
    self.panner.delaysTouchesBegan = NO;
    self.panner.cancelsTouchesInView = NO;

    self.colorPickerView.delegate = self;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self relayoutColorPicker];
}

#pragma mark - Gestures

- (void)didLongPress:(UITapGestureRecognizer *)tapper
{
    if (tapper.state == UIGestureRecognizerStateBegan) {
        CGFloat x = [tapper locationInView:self.view].x;
        IdentifiableColor *selectedColor = [self colorForX:x];
        if ([self.delegate respondsToSelector:@selector(colorPickerWillLongPressOnColor:)]) {
            [self.delegate colorPickerWillLongPressOnColor:selectedColor];
        }
    }
}

- (void)didTap:(UITapGestureRecognizer *)tapper
{
    if (tapper.state == UIGestureRecognizerStateRecognized) {
        CGFloat x = [tapper locationInView:self.view].x;
        IdentifiableColor *selectedColor = [self colorForX:x];
        self.selectedColor = selectedColor;        
        [self.delegate colorPickerDidSelectColor:selectedColor];

        [self animateKnobToColor:selectedColor];
    }
}

- (void)didPan:(UITapGestureRecognizer *)_panner
{
    if (self.panner.state == UIGestureRecognizerStateChanged) {
        ColorPickerView *pickerView = self.colorPickerView;
        ColorPickerKnobView *knob = pickerView.knobView;

        CGFloat x = [self.panner locationInView:self.view].x;

        // Don’t allow dragging over the edges
        x = CGClamp(16, pickerView.bounds.size.width - 16, x);

        CGPoint knobCenter = knob.center;
        knobCenter.x = x;
        knob.center = knobCenter;

        [pickerView relayoutKnobAndColorBandsFromGestureHandler];
    }

    if ((self.panner.state == UIGestureRecognizerStateCancelled) || (self.panner.state == UIGestureRecognizerStateEnded)) {
        ColorPickerView *pickerView = self.colorPickerView;
        ColorPickerKnobView *knob = pickerView.knobView;
        UIView *ghostKnobView = pickerView.ghostKnobView;
        knob.pickedUp = NO;

        CGFloat x = [self.panner locationInView:self.view].x;
        x = CGClamp(16, pickerView.bounds.size.width - 16, x);

        [self createDisplayLinkIfNeeded];

        CGRect f = knob.frame;
        f.origin.x = [self colorBandMiddleXForProposedX:x] - f.size.width / 2;

        if (self.panner.state == UIGestureRecognizerStateEnded) {
            // if the gesture ended successfully, upate the selected color
            IdentifiableColor *color = [self colorForX:x];
            self.selectedColor = color;
            [self.delegate colorPickerDidSelectColor:color];
        }
        
        [UIView animateWithDuration:0.4
                              delay:0
             usingSpringWithDamping:0.6
              initialSpringVelocity:3
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
            ghostKnobView.frame = f;
        } completion:^(BOOL finished) {
            [self releaseDisplayLinkIfNeeded];
        }];
    }
}


#pragma mark - Display link

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    ColorPickerView *colorPickerView = self.colorPickerView;
    [colorPickerView relayoutKnobAndColorBandsFromAnimationCallback];
}

- (void)createDisplayLinkIfNeeded
{
    if (self.displayLinksInFlight == 0) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    self.displayLinksInFlight ++;
}

- (void)releaseDisplayLinkIfNeeded
{
    if (self.displayLinksInFlight == 0) {
        return;
    }

    self.displayLinksInFlight --;
    if (self.displayLinksInFlight == 0) {
        [self releaseDisplayLink];
    }
}

- (void)releaseDisplayLink
{
    [self.displayLink invalidate];
}


#pragma mark - Utilities

- (void)animateKnobToColor:(IdentifiableColor *)color
{
    ColorPickerView *pickerView = self.colorPickerView;
    
    UIView *ghostKnobView = pickerView.ghostKnobView;
    ColorPickerKnobView *knob = pickerView.knobView;
    CGRect f = knob.frame;
    f.origin.x = [self colorBandMiddleXForColor:color] - f.size.width / 2;
    
    [self createDisplayLinkIfNeeded];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:2 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        ghostKnobView.frame = f;
    } completion:^(BOOL finished) {
         [self releaseDisplayLinkIfNeeded];
     }];
}

- (CGFloat)colorBandMiddleXForProposedX:(CGFloat)proposedX
{
    CGFloat x = 0;
    NSUInteger bandIndex = 0;
    CGFloat currentBandWidth = 0;
    while (proposedX > x) {
        currentBandWidth = [self.colorPickerView.colorBandWidths[bandIndex] floatValue];
        x += currentBandWidth;
        bandIndex ++;
    }
    x -= floor(currentBandWidth / 2);
    return x;
}

- (CGFloat)colorBandMiddleXForColor:(IdentifiableColor *)color
{
    ColorPickerView *pickerView = self.colorPickerView;
    CGFloat leftOffset = 0;
    for (NSUInteger bandIndex = 0; bandIndex < pickerView.colors.count; bandIndex ++) {
        IdentifiableColor *c = pickerView.colors[bandIndex];
        CGFloat bandWidth = [pickerView.colorBandWidths[bandIndex] floatValue];
        if (c == color) {
            return leftOffset + floor(bandWidth / 2);
        }
        leftOffset += bandWidth;
    }
    
    return 0;
}

- (IdentifiableColor *)colorForX:(CGFloat)x
{
    ColorPickerView *pickerView = self.colorPickerView;
    CGFloat leftOffset = 0;
    for (NSUInteger bandIndex = 0; bandIndex < pickerView.colors.count; bandIndex ++) {
        CGFloat bandWidth = [pickerView.colorBandWidths[bandIndex] floatValue];
        leftOffset += bandWidth;
        if (x < leftOffset) {
            IdentifiableColor *identifiableColor = pickerView.colors[bandIndex];
            return identifiableColor;
        }
    }

    return nil;
}

- (void)relayoutColorPicker
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Reposition the knob based on selected color
        ColorPickerView *pickerView = self.colorPickerView;
        CGFloat middleX = [self colorBandMiddleXForColor:self.selectedColor];
        CGPoint knobCenter = pickerView.knobView.center;
        knobCenter.x = middleX;
        pickerView.knobView.center = knobCenter;
        dispatch_async(dispatch_get_main_queue(), ^{
            [pickerView relayoutKnobAndColorBandsFromGestureHandler];
        });
    });
}



#pragma mark - ColorPickerViewDelegate

- (void)colorPickerViewDisplayedColorChangedTo:(IdentifiableColor *)color
{
    // The below condition makes sure that the picker does not render
    // the intermediate preview colors as the knob is flying
    // through different bands in case of an animation.
    // If you want the preview color to also be set during this animation, remove this return.
    if (self.panner.state != UIGestureRecognizerStateChanged) {
        return;
    }
    
    self.previewColor = color;
}

#pragma mark - Setters

- (void)setSelectedColor:(IdentifiableColor *)selectedColor
{
    if (_selectedColor != selectedColor) {
        _selectedColor = selectedColor;
        _previewColor = selectedColor;
    }
}

- (void)setPreviewColor:(IdentifiableColor *)previewColor
{
    if (previewColor != _previewColor) {
        _previewColor = previewColor;
        [self.delegate colorPickerDidChangePreviewColor:previewColor];
    }
}

@end
