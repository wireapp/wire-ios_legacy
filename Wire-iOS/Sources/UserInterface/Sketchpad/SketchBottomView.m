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


#import "SketchBottomView.h"

#import "UIImage+ZetaIconsNeue.h"
#import <PureLayout/PureLayout.h>
#import "WireStyleKit.h"
#import <WireExtensionComponents/WireExtensionComponents.h>
#import <Classy/Classy.h>
#import "WRFunctions.h"



static CGFloat SketchBottomViewHeight = 80.0;

@interface SketchBottomView ()

@property (nonatomic, readwrite) UIButton *undoButton;
@property (nonatomic, readwrite) UIButton *cancelButton;
@property (nonatomic, readwrite) UIButton *confirmButton;
@property (nonatomic) UIView *separatorView;
@property (nonatomic) BOOL initialConstraintsCreated;

@end

@implementation SketchBottomView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSeparatorView];
        [self createButtons];
    }
    return self;
}

- (void)addSeparatorView
{
    UIView *separatorView = [UIView newAutoLayoutView];
    [self addSubview:separatorView];
    self.separatorView = separatorView;
}

- (void)createButtons
{
    IconButton *undoButton = [IconButton iconButtonCircular];
    undoButton.translatesAutoresizingMaskIntoConstraints = NO;
    [undoButton setIcon:ZetaIconTypeUndo withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.undoButton = undoButton;
    [self addSubview:self.undoButton];
    self.undoButton.accessibilityIdentifier = @"SketchUndoButton";

    IconButton *cancelButton = [IconButton iconButtonCircular];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.cancelButton = cancelButton;
    [self addSubview:self.cancelButton];
    self.cancelButton.accessibilityIdentifier = @"SketchCancelButton";
    
    IconButton *confirmButton = [IconButton iconButtonCircular];
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.confirmButton = confirmButton;
    [confirmButton setIcon:ZetaIconTypeCheckmark withSize:ZetaIconSizeMedium forState:UIControlStateNormal];
    [self addSubview:self.confirmButton];
    self.confirmButton.accessibilityIdentifier = @"SketchConfirmButton";
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        const CGSize buttonSize = CGSizeMake(32, 32);
        
        [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
        [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
        [self.separatorView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
        [self.separatorView autoSetDimension:ALDimensionHeight toSize:0.5f];

        
        [self.undoButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.undoButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.undoButton autoSetDimensionsToSize:buttonSize];

        [self.cancelButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        [self.cancelButton autoSetDimensionsToSize:buttonSize];
        
        [self.confirmButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.confirmButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.confirmButton autoSetDimensionsToSize:CGSizeMake(60, 60)];
    }
}

- (CGSize)intrinsicContentSize
{
    return (CGSize){UIViewNoIntrinsicMetric, SketchBottomViewHeight};
}

- (void)updateButtonsOrientationWithDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    CGAffineTransform transform = WRDeviceOrientationToAffineTransform(deviceOrientation);
    
    [UIView animateWithDuration:0.2f animations:^{
        self.undoButton.transform = transform;
        self.cancelButton.transform = transform;
        self.confirmButton.transform = transform;
    }];
}

@end
