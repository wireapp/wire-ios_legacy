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
#import "Wire-Swift.h"

@import PureLayout;


#import "WireSyncEngine+iOS.h"

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
    self.connectRequestViewController = [[IncomingConnectionViewController alloc] initWithUserSession:[ZMUserSession sharedSession] user:self.user];

    @weakify(self);
    self.connectRequestViewController.onAction = ^(IncomingConnectionAction action) {
        @strongify(self);
        switch(action) {
            case IncomingConnectionActionAccept:
                self.acceptBlock();
                break;
            case IncomingConnectionActionIgnore:
                self.ignoreBlock();
                break;
        }
    };

    self.connectRequestViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.connectRequestViewController.view];

    [self.connectRequestViewController.view autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.connectRequestViewController.view autoPinEdgesToSuperviewMargins];
    [self.connectRequestViewController.view autoSetDimension:ALDimensionWidth toSize:420 relation:NSLayoutRelationLessThanOrEqual];
}

@end
