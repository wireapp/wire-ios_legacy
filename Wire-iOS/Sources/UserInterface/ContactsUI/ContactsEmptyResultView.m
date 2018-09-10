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


#import "ContactsEmptyResultView.h"
@import PureLayout;
#import "Button.h"
@import WireExtensionComponents;

@interface ContactsEmptyResultView ()
@property (nonatomic) UIView *containerView;
@end

@implementation ContactsEmptyResultView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupViews];
        [self setupLayout];
    }
    return self;
}

#pragma mark - Setup

- (void)setupViews
{
    self.containerView = [[UIView alloc] initForAutoLayout];
    [self addSubview:self.containerView];

    self.messageLabel = [[UILabel alloc] initForAutoLayout];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    [self.containerView addSubview:self.messageLabel];

    self.actionButton = [Button buttonWithStyle:ButtonStyleFull];
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.actionButton];
}

- (void)setupLayout
{
    [self.messageLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.actionButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.actionButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.messageLabel withOffset:24];
    [self.actionButton autoSetDimension:ALDimensionHeight toSize:28];

    [self.containerView autoCenterInSuperview];
}


@end
