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


#import "BadgeUserImageView.h"

#import <PureLayout/PureLayout.h>

#import "UserImageView.h"
#import "WAZUIMagicIOS.h"
#import "ZMUser+Additions.h"
#import "zmessaging+iOS.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "UserImageView+Magic.h"


@interface BadgeUserImageView () <ZMUserObserver>

@property (nonatomic) UIView *badgeShadow;
@property (nonatomic) BOOL initialBadgeUserImageViewConstraintsCreated;

@end

@implementation BadgeUserImageView

- (instancetype)initWithMagicPrefix:(NSString *)magicPrefix
{
    self = [super initWithMagicPrefix:magicPrefix];
    
    if (self) {
        _badgeIconSize = ZetaIconSizeTiny;
        _badgeColor = UIColor.whiteColor;

        [self createBadgeShadow];
        
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    }
    
    return self;
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)createBadgeShadow
{
    self.badgeShadow = [[UIView alloc] initForAutoLayout];
    [self.containerView addSubview:self.badgeShadow];
}

- (void)updateConstraints
{
    if (! self.initialBadgeUserImageViewConstraintsCreated) {
        
        self.initialBadgeUserImageViewConstraintsCreated = YES;
        
        [self.badgeShadow autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
    
    [super updateConstraints];
}

- (void)setUser:(id<ZMBareUser, ZMSearchableUser, AccentColorProvider>)user
{
    [super setUser:user];
    
    [self updateBadgeIcon];
}

- (void)updateBadgeIcon
{
    ZMUser *user = BareUserToUser(self.user);
    
    BOOL isPendingApprovalByOtherOther = [user isPendingApprovalByOtherUser];
    BOOL isPendingApprovalBySelfUser = [user isPendingApprovalBySelfUser];
    BOOL meetsPendingIconRequirements = isPendingApprovalByOtherOther || isPendingApprovalBySelfUser;
    
    if ([user isBlocked]) {
        [self setBadgeIcon:ZetaIconTypeBlock];
    }
    else if (meetsPendingIconRequirements) {
        [self setBadgeIcon:ZetaIconTypeClock];
    } else  {
        [self setBadgeIcon:ZetaIconTypeNone];
    }
}

- (void)setBadge:(UIView *)badge
{
    [self setBadge:badge animated:NO];
}

- (void)setBadge:(UIView *)badge animated:(BOOL)animated
{
    [self.badge removeFromSuperview];
    _badge = badge;
    
    if (badge) {
        badge.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:badge];
        [self.badge autoCenterInSuperview];
        
        dispatch_block_t hideBadge = ^{
            self.badge.transform = CGAffineTransformMakeScale(1.8, 1.8);
            self.badge.alpha  = 0;
        };
        
        dispatch_block_t showBadge = ^{
            self.badge.transform = CGAffineTransformIdentity;
            self.badge.alpha  = 1;
        };
        
        dispatch_block_t showShadow = ^{
            self.badgeShadow.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        };
        
        if (animated) {
            hideBadge();
            [UIView animateWithDuration:0.65 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:15.0 options:0 animations:showBadge completion:nil];
            [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutQuart duration:0.15 animations:showShadow];
        } else {
            showBadge();
            showShadow();
        }
    } else {
        self.badgeShadow.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    }
}

- (void)setBadgeIcon:(ZetaIconType)badgeIcon animated:(BOOL)animated
{
    if (_badgeIcon == badgeIcon) {
        return;
    }
    
    _badgeIcon = badgeIcon;
    
    if (badgeIcon == ZetaIconTypeNone) {
        self.badge = nil;
        return;
    }
    
    UIImage *iconImage = [UIImage imageForIcon:badgeIcon iconSize:self.badgeIconSize color:self.badgeColor];
    [self setBadge:[[UIImageView alloc] initWithImage:iconImage] animated:animated];
}

- (void)setBadgeIcon:(ZetaIconType)badgeIcon
{
    [self setBadgeIcon:badgeIcon animated:NO];
}

#pragma mark - ZMUserChangeObserver

- (void)userDidChange:(UserChangeInfo *)change
{
    [super userDidChange:change];
    
    if (change.connectionStateChanged) {
        [self updateBadgeIcon];
    }
}

@end
