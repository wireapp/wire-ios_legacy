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


#import <PureLayout/PureLayout.h>

#import "ConnectionRequestCell.h"
#import "WireSyncEngine+iOS.h"



@implementation ConnectionRequestCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self createConstraints];
    }
    
    return self;
}

- (void)createConstraints
{
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        [self.messageContentView autoSetDimension:ALDimensionHeight toSize:2];
    }];
}

- (void)configureForMessage:(ZMSystemMessage *)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties
{
    [super configureForMessage:message layoutProperties:[[ConversationCellLayoutProperties alloc] init]];
}

@end
