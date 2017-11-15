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

#import "IconLabelButton.h"
#import "UILabel+TextTransform.h"

@import PureLayout;

@interface IconLabelButton ()
@property (nonatomic) UIControlState priorState;
@end

@implementation IconLabelButton


- (instancetype)init
{
    self = [super init];
    if (nil != self) {
        self.iconButton = [IconButton iconButtonCircularLight];
        self.iconButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.iconButton.userInteractionEnabled = NO;
        [self addSubview:self.iconButton];
        
        [self.iconButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.iconButton];
        [self.iconButton autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.iconButton autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.iconButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
        
        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.subtitleLabel.textTransform = TextTransformUpper;
        [self addSubview:self.subtitleLabel];
        
        [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.subtitleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.iconButton withOffset:8];
        [self.subtitleLabel autoSetDimension:ALDimensionHeight toSize:16];
    }
    
    return self;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [self updateForNewState];
}

#pragma mark - Observing state

- (void)setHighlighted:(BOOL)highlighted
{
    _priorState = self.state;
    [super setHighlighted:highlighted];
    [self.iconButton setHighlighted:highlighted];
    [self updateForNewStateIfNeeded];
}

- (void)setSelected:(BOOL)selected
{
    _priorState = self.state;
    [super setSelected:selected];
    [self.iconButton setSelected:selected];
    [self updateForNewStateIfNeeded];
}

- (void)setEnabled:(BOOL)enabled
{
    _priorState = self.state;
    [super setEnabled:enabled];
    [self.iconButton setEnabled:enabled];
    [self updateForNewStateIfNeeded];
}

- (void)updateForNewStateIfNeeded
{
    if(self.state != _priorState)
    {
        _priorState = self.state;
        [self updateForNewState];
    }
}

- (void)updateForNewState
{
    // Update for new state (selected, highlighted, disabled) here if needed
    self.subtitleLabel.font = self.titleLabel.font;
    self.subtitleLabel.textColor = [self titleColorForState:self.state];
}

@end
