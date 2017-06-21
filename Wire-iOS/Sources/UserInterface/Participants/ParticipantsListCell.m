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
@import PureLayout;
#import "BadgeUserImageView.h"
#import "WireSyncEngine+iOS.h"
#import "UserImageView+Magic.h"
#import "Wire-Swift.h"

@interface ParticipantsListCell ()
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) BadgeUserImageView *userImageView;
@property (nonatomic) RoundedTextBadge *guestLabel;
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
    self.nameLabel = [[UILabel alloc] initForAutoLayout];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.nameLabel];

    BadgeUserImageView *userImageView = [[BadgeUserImageView alloc] initWithMagicPrefix:@"participants"];
    userImageView.userSession = [ZMUserSession sharedSession];
    userImageView.badgeColor = [UIColor whiteColor];
    userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:userImageView];
    self.userImageView = userImageView;
    
    self.guestLabel = [[RoundedTextBadge alloc] initForAutoLayout];
    self.guestLabel.textLabel.text = NSLocalizedString(@"participants.avatar.guest.title", @"");
    self.guestLabel.hidden = YES;
    self.guestLabel.accessibilityIdentifier = @"guest label";
    [self.contentView addSubview:self.guestLabel];
    
    [self.userImageView autoCenterInSuperview];
    [self.userImageView autoSetDimensionsToSize:CGSizeMake(80, 80)];
    [self.nameLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.userImageView withOffset:8];
    [self.nameLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.userImageView];
    [self.nameLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.userImageView];
    
    [self.guestLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.userImageView withOffset:1];
    [self.guestLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

#pragma mark - Getters / setters
- (void)updateForUser:(ZMUser *)user inConversation:(ZMConversation *)conversation
{
    self.userImageView.user = user;
    self.nameLabel.text = [user.displayName uppercaseString];
    self.guestLabel.hidden = ![user isGuestIn:conversation];
}

@end
