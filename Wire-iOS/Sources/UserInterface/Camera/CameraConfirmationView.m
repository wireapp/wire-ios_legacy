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


#import "CameraConfirmationView.h"

@import PureLayout;

#import "Button.h"
#import "UIColor+WAZExtensions.h"
#import "WAZUIMagicIOS.h"

#import "Wire-Swift.h"


@interface CameraConfirmationView ()

@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) UIView *interitemView;
@end



@implementation CameraConfirmationView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.acceptButton = [Button buttonWithStyleClass:@"dialogue-button-full"];
        self.acceptButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.acceptButton setTitle:[NSLocalizedString(@"image_confirmer.confirm", @"") uppercasedWithCurrentLocale] forState:UIControlStateNormal];
        self.acceptButton.backgroundColor = UIColor.accentColor;
        [self addSubview:self.acceptButton];
        
        self.rejectButton = [Button buttonWithStyleClass:@"dialogue-button-empty"];
        self.rejectButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.rejectButton setTitle:[NSLocalizedString(@"image_confirmer.cancel", @"") uppercasedWithCurrentLocale] forState:UIControlStateNormal];
        [self addSubview:self.rejectButton];
        
        self.interitemView = [[UIView alloc] initForAutoLayout];
        [self addSubview:self.interitemView];
        
        [self setNeedsUpdateConstraints];
    }
    
    return self;
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        
        const CGFloat Margin = [WAZUIMagic floatForIdentifier:@"camera_overlay.margin"];
        
        [self.acceptButton autoSetDimension:ALDimensionHeight toSize:40];
        [self.acceptButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.acceptButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.acceptButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.interitemView];
        
        [self.rejectButton autoSetDimension:ALDimensionHeight toSize:40];
        [self.rejectButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.rejectButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.rejectButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.interitemView];
        
        [self.interitemView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.interitemView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.interitemView autoSetDimension:ALDimensionWidth toSize:16.0f];
        [self.interitemView autoSetDimension:ALDimensionHeight toSize:16.0f];
        
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
            [self.acceptButton autoSetDimension:ALDimensionWidth toSize:184];
            [self.rejectButton autoSetDimension:ALDimensionWidth toSize:184];
            [self.rejectButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:Margin];
            [self.acceptButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:Margin];
        }];
        [self.acceptButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.rejectButton];
    }
    
    [super updateConstraints];
}

@end
