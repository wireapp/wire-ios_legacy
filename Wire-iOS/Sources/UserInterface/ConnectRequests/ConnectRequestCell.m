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


#import "ConnectRequestCell.h"
#import "WAZUIMagic.h"
#import "Wire-Swift.h"

#import <PureLayout/PureLayout.h>


#import "zmessaging+iOS.h"

@implementation ConnectRequestCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setUser:(ZMUser *)user
{
    _user = user;
    
    [self.connectRequestViewController.view removeFromSuperview];
    
    self.connectRequestViewController = [[UserConnectionViewController alloc] initWithUserSession:[ZMUserSession sharedSession] user:self.user];
    self.connectRequestViewController.showUserName = YES;
    @weakify(self);
    self.connectRequestViewController.onAction = ^(UserConnectionAction action) {
        @strongify(self);
        switch(action) {
            case UserConnectionActionAccept:
                self.acceptBlock();
                break;
            case UserConnectionActionIgnore:
                self.ignoreBlock();
                break;
            default:
                break;
        }
    };
    self.connectRequestViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.connectRequestViewController.view];
    
    [self.connectRequestViewController.view autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.connectRequestViewController.view autoPinEdgesToSuperviewEdges];
    
    [self.connectRequestViewController.view autoSetDimension:ALDimensionWidth toSize:420 relation:NSLayoutRelationLessThanOrEqual];
}

@end
