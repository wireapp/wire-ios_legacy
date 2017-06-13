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


#import "ProfileFooterView.h"

#import "WAZUIMagicIOS.h"

@import PureLayout;
#import "IconButton.h"
#import "NSLayoutConstraint+Helpers.h"



@implementation ProfileFooterView

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self createViews];
        [self setupConstraints];
    }
    return self;
}

- (void)createViews
{
    self.leftButton = [IconButton iconButtonCircular];
    self.leftButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.leftButton.accessibilityIdentifier = @"OtherUserMetaControllerLeftButton";
    [self addSubview:self.leftButton];
    
    self.rightButton = [IconButton iconButtonCircular];
    self.rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightButton.accessibilityIdentifier = @"OtherUserMetaControllerRightButton";
    [self addSubview:self.rightButton];
}

- (void)setupConstraints
{
    [self.leftButton addConstraintForLeftMargin:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"] relativeToView:self];
    [self.leftButton addConstraintForBottomMargin:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_bottom_margin"] relativeToView:self];
    [self.leftButton addConstraintForTopMargin:0 relativeToView:self];
    [self.leftButton autoSetDimension:ALDimensionHeight
                               toSize:32];
    
    [self.rightButton addConstraintForRightMargin:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_right_margin"] relativeToView:self];
    [self.rightButton addConstraintForBottomMargin:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_bottom_margin"] relativeToView:self];
    [self.rightButton addConstraintForTopMargin:0 relativeToView:self];
    [self.rightButton autoMatchDimension:ALDimensionWidth
                             toDimension:ALDimensionHeight
                                  ofView:self.rightButton];
    [self.rightButton autoSetDimension:ALDimensionWidth
                                toSize:32];
}

- (void)setIconTypeForLeftButton:(ZetaIconType)iconType
{
    self.leftButton.hidden = (iconType == ZetaIconTypeNone);
    if (iconType != ZetaIconTypeNone) {
        [self setIconType:iconType forButton:self.leftButton];
    }
}

- (void)setIconTypeForRightButton:(ZetaIconType)iconType
{
    self.rightButton.hidden = (iconType == ZetaIconTypeNone);
    if (iconType != ZetaIconTypeNone) {
        [self setIconType:iconType forButton:self.rightButton];
    }
}

- (void)setIconType:(ZetaIconType)iconType forButton:(IconButton *)button
{
    [button setIcon:iconType withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
}

@end
