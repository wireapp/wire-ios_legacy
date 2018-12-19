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
@import PureLayout;
#import "Constants.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

@interface TopPeopleCell ()

@property (nonatomic, strong) BadgeUserImageView *badgeUserImageView;
@property (nonatomic, strong) UIImageView *conversationImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *avatarContainer;

@property (nonatomic, assign) BOOL initialConstraintsCreated;
@property (nonatomic, strong) NSLayoutConstraint *avatarViewSizeConstraint;
@property (nonatomic, strong) NSLayoutConstraint *conversationImageViewSize;

@end


@implementation TopPeopleCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        self.accessibilityIdentifier = @"TopPeopleCell";
        self.isAccessibilityElement = YES;
        self.avatarContainer = [[UIView alloc] initWithFrame:CGRectZero];
        self.avatarContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.avatarContainer];

        self.conversationImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.conversationImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.avatarContainer addSubview:self.conversationImageView];

        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
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
    self.badgeUserImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.badgeUserImageView.userInteractionEnabled = NO;
    self.badgeUserImageView.badgeIconSize = ZetaIconSizeTiny;
    self.badgeUserImageView.accessibilityIdentifier = @"TopPeopleAvatar";

    [self.avatarContainer addSubview:self.badgeUserImageView];
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        [self.contentView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.badgeUserImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

        self.conversationImageViewSize = [self.conversationImageView autoSetDimension:ALDimensionWidth toSize:80];
        [self.conversationImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.conversationImageView];

        self.avatarViewSizeConstraint = [self.avatarContainer autoSetDimension:ALDimensionWidth toSize:80];
        [self.avatarContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.avatarContainer];

        [self.avatarContainer autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
        [self.avatarContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft];

        [self.conversationImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
        [self.conversationImageView autoPinEdgeToSuperviewEdge:ALEdgeLeft];

        [self.nameLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.avatarContainer withOffset:8];
        [self.nameLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.avatarContainer];
        [self.nameLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.avatarContainer];

        self.initialConstraintsCreated = YES;
        [self updateForContext];
    }
    [super updateConstraints];
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

- (void)setUser:(id<UserType, AccentColorProvider>)user
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
        [self.badgeUserImageView setBadgeIcon:ZetaIconTypeCheckmark];
    } else {
        self.badgeUserImageView.badgeIcon = ZetaIconTypeNone;
    }
}

@end
