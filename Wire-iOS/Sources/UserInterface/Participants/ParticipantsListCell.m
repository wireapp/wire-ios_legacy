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


#import "ParticipantsListCell.h"

#import <PureLayout/PureLayout.h>

#import "BadgeUserImageView.h"
#import "WireSyncEngine+iOS.h"

#import "UserImageView+Magic.h"

@interface ParticipantsListCell ()
@property (weak, nonatomic) UILabel *nameLabel;
@property (weak, nonatomic) BadgeUserImageView *userImageView;
@end

@implementation ParticipantsListCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubviews];
    }
    return self;
}

- (void)addSubviews
{
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:nameLabel];
    self.nameLabel = nameLabel;

    BadgeUserImageView *userImageView = [[BadgeUserImageView alloc] initWithMagicPrefix:@"participants"];
    userImageView.userSession = [ZMUserSession sharedSession];
    userImageView.badgeColor = [UIColor whiteColor];
    userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:userImageView];
    self.userImageView = userImageView;
    
    [self.userImageView autoCenterInSuperview];
    [self.userImageView autoSetDimensionsToSize:CGSizeMake(80, 80)];
    [self.nameLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.userImageView withOffset:8];
    [self.nameLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.userImageView];
    [self.nameLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.userImageView];
}

#pragma mark - Getters / setters

- (void)setRepresentedObject:(ZMUser *)representedObject
{
    _representedObject = representedObject;
    
    ZMUser *user = (ZMUser *)representedObject;
    self.userImageView.user = representedObject;
    self.nameLabel.text = [user.displayName uppercaseString];
}

@end
