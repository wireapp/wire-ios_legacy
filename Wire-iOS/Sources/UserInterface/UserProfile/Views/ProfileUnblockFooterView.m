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


#import "ProfileUnblockFooterView.h"
#import "Button.h"

@import WireExtensionComponents;

@interface ProfileUnblockFooterView ()
@property (nonatomic, strong, readwrite) UIButton *unblockButton;
@end

@implementation ProfileUnblockFooterView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.unblockButton = [Button buttonWithStyle:ButtonStyleFull];
        self.unblockButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.unblockButton];

        [self.unblockButton addConstraintForHeight:40];
        [self.unblockButton addConstraintsFittingToView:self edgeInsets:UIEdgeInsetsMake(0, 24, 24, 24)];
        
        [self.unblockButton setTitle:NSLocalizedString(@"profile.unblock_button_title", @"").localizedUppercaseString
                            forState:UIControlStateNormal];

    }
    return self;
}

@end
