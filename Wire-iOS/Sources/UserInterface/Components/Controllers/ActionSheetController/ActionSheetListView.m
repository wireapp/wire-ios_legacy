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

@import Classy;
#import "Wire-Swift.h"
#import "ActionSheetListView.h"
#import "ActionSheetController.h"

@implementation ActionSheetListView

- (instancetype)initWithActions:(NSArray *)actions
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        NSArray *buttons = [self buttonsForActions:actions];
        NSMutableArray *views = [NSMutableArray array];

        [buttons enumerateObjectsUsingBlock:^(UIView *button, NSUInteger idx, BOOL *stop) {
            SheetAction *action = actions[idx];
            
            if (idx > 0) {
                UIView *separator = [[UIView alloc] initForAutoLayout];
                [views addObject:separator];
                separator.cas_styleClass = action.style == SheetActionStyleCancel ? @"separator-strong" : @"separator";
                
                [self addSubview:separator];
                [separator autoSetDimension:ALDimensionHeight toSize:UIScreen.hairline];
                [separator autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                [separator autoPinEdgeToSuperviewEdge:ALEdgeRight];
            }
            
            [self addSubview:button];
            [views addObject:button];
            [button autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [button autoPinEdgeToSuperviewEdge:ALEdgeRight];
            [button autoSetDimension:ALDimensionHeight toSize:55];
        }];
        
        [views autoDistributeViewsAlongAxis:ALAxisVertical alignedTo:ALAttributeVertical withFixedSpacing:0 insetSpacing:NO matchedSizes:NO];
    }
    
    return self;
}

- (NSArray *)buttonsForActions:(NSArray *)actions
{
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (SheetAction *action in actions) {
        [buttons addObject:[self buttonsForAction:action]];
    }
    
    return buttons;
}

- (UIButton *)buttonsForAction:(SheetAction *)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.accessibilityIdentifier = action.accessibilityIdentifier;
    [button setTitle:[action.title uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    [button addTarget:action action:@selector(performAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

@end
