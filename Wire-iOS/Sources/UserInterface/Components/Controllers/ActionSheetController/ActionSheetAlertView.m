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


@import PureLayout;

#import "ActionSheetAlertView.h"
#import "IconButton.h"
#import "Button.h"


@interface ActionSheetAlertView ()

@property (nonatomic) UIView *verticalButtonContainer;
@property (nonatomic) UIView *horizontalButtonContainer;

@property (nonatomic) NSArray *verticalButtons;
@property (nonatomic) NSArray *horizontalButtons;

@end

@implementation ActionSheetAlertView

- (instancetype)initWithActions:(NSArray *)actions buttons:(NSArray *)buttons
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.verticalButtonContainer = [[UIView alloc] initForAutoLayout];
        self.horizontalButtonContainer = [[UIView alloc] initForAutoLayout];
        
        self.imageView = [[UIImageView alloc] initForAutoLayout];
        self.titleLabel = [[UILabel alloc] initForAutoLayout];
        self.titleLabel.numberOfLines = 0;
        self.messageLabel = [[UILabel alloc] initForAutoLayout];
        self.messageLabel.numberOfLines = 0;
        self.horizontalButtons = [self buttonsForActions:actions];
        self.verticalButtons = buttons;
        
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.messageLabel];
        [self addSubview:self.verticalButtonContainer];
        [self addSubview:self.horizontalButtonContainer];
        
        for (UIView *view in self.horizontalButtons) {
            [self.horizontalButtonContainer addSubview:view];
        }
        
        for (UIView *view in self.verticalButtons) {
            [self.verticalButtonContainer addSubview:view];
        }
        
        [self createInitialConstraints];
    }
    
    return self;
}

- (NSArray *)buttonsForActions:(NSArray *)actions
{
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (SheetAction *action in actions) {
        [buttons addObject:[self buttonForAction:action]];
    }
    
    return buttons;
}

- (Button *)buttonForAction:(SheetAction *)sheetAction
{
    Button *button = [Button buttonWithStyleClass:sheetAction.style == SheetActionStyleCancel ? @"dialogue-button-empty" : @"dialogue-button-full"];
    button.accessibilityIdentifier = sheetAction.accessibilityIdentifier;
    [button setTitle:sheetAction.title forState:UIControlStateNormal];
    [button addTarget:sheetAction action:@selector(performAction:) forControlEvents:UIControlEventTouchUpInside];
    [button autoSetDimension:ALDimensionHeight toSize:40];
    
    return button;
}

- (void)createInitialConstraints
{
    const CGFloat verticalButtonSpacing = self.verticalButtons.count == 0 ? 8 : 24;
    
    [self.imageView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.imageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    
    [self.imageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.titleLabel withOffset:-16];
    
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    
    [self.messageLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:5];
    [self.messageLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.messageLabel autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    [self.verticalButtonContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.messageLabel withOffset:verticalButtonSpacing];
    [self.verticalButtonContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.verticalButtonContainer autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    [self.horizontalButtonContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.verticalButtonContainer withOffset:verticalButtonSpacing];
    [self.horizontalButtonContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    
    if (self.verticalButtons.count > 1) {
        [self.verticalButtons autoDistributeViewsAlongAxis:ALAxisVertical alignedTo:ALAttributeVertical withFixedSpacing:0 insetSpacing:NO matchedSizes:NO];
    } else {
        [self.verticalButtons.lastObject autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.verticalButtons.lastObject autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    }
    
    if (self.horizontalButtons.count > 1) {
        [self.horizontalButtons autoDistributeViewsAlongAxis:ALAxisHorizontal alignedTo:ALAttributeBottom withFixedSpacing:16 insetSpacing:NO];
    } else {
        [self.horizontalButtons.lastObject autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.horizontalButtons.lastObject autoPinEdgeToSuperviewEdge:ALEdgeRight];
    }
    
    
    for (UIView *view in self.horizontalButtons) {
        [view autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    }
    
    for (UIView *view in self.verticalButtons) {
        [view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    }
}

@end
