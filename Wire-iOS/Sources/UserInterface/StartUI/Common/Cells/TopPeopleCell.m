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


#import "TopPeopleCell.h"
#import "TopPeopleCell+Internal.h"

#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

@implementation TopPeopleCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.accessibilityIdentifier = @"TopPeopleCell";
        self.isAccessibilityElement = YES;
        self.avatarContainer = [[UIView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.avatarContainer];

        self.conversationImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.avatarContainer addSubview:self.conversationImageView];

        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.nameLabel];

        UITapGestureRecognizer *doubleTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapper.numberOfTapsRequired = 2;
        doubleTapper.numberOfTouchesRequired = 1;
        doubleTapper.delaysTouchesBegan = YES;
        [self.contentView addGestureRecognizer:doubleTapper];

        [self createUserImageView];
        [self setNeedsUpdateConstraints];
        [self updateForContext];
    }
    return self;
}

- (void)createUserImageView
{
    [self.badgeUserImageView removeFromSuperview];

    self.badgeUserImageView = [[BadgeUserImageView alloc] init];
    self.badgeUserImageView.initialsFont = [UIFont systemFontOfSize:11 weight:UIFontWeightLight];
    self.badgeUserImageView.userSession = [ZMUserSession sharedSession];
    self.badgeUserImageView.size = UserImageViewSizeSmall;
    self.badgeUserImageView.userInteractionEnabled = NO;
    self.badgeUserImageView.wr_badgeIconSize = 16;
    self.badgeUserImageView.accessibilityIdentifier = @"TopPeopleAvatar";

    [self.avatarContainer addSubview:self.badgeUserImageView];
}

- (void)updateForContext
{
    self.nameLabel.font = UIFont.smallLightFont;
    self.nameLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];

    CGFloat squareImageWidth = 56;
    self.avatarViewSizeConstraint.constant = squareImageWidth;
    self.conversationImageViewSize.constant = squareImageWidth;
    
    self.badgeUserImageView.badgeColor = [UIColor whiteColor];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.conversationImageView.image = nil;
    self.conversationImageView.hidden = NO;
    self.badgeUserImageView.hidden = NO;
}

- (void)doubleTap:(UITapGestureRecognizer *)doubleTapper
{
    if (self.doubleTapAction != nil) {
        self.doubleTapAction(self);
    }
}

#pragma mark - Get, set

- (void)setUser:(id<UserType>)user
{
    _user = user;
    self.badgeUserImageView.user = user;
    self.displayName = user.displayName;
    self.accessibilityValue = user.displayName;
}

- (void)setConversation:(ZMConversation *)conversation
{
    _conversation = conversation;
    ZMUser *otherUser = conversation.connectedUser;
    self.user = otherUser;
    self.conversationImageView.image = nil;
}

- (void)setDisplayName:(NSString *)displayName
{
    if (_displayName == displayName) {
        return;
    }

    _displayName = [displayName copy];

    self.nameLabel.text = displayName.localizedUppercaseString;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    if (selected) {
        [self.badgeUserImageView setBadgeIcon:WRStyleKitIconCheckmark];
    } else {
        [self.badgeUserImageView removeBadgeIcon];
    }
}

@end
