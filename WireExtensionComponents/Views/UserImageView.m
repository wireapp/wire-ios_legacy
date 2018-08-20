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


#import "UserImageView.h"
@import PureLayout;
@import WireSyncEngine;
#import "UIImage+ImageUtilities.h"
#import "UIImage+ZetaIconsNeue.h"

#import "weakify.h"

#import <WireExtensionComponents/WireExtensionComponents-Swift.h>

@interface UserImageView ()

@property (nonatomic) id userObserverToken;
@property (nonatomic) RoundedView *indicator;

@end



@implementation UserImageView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupBasicProperties];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupBasicProperties];
    }
    return self;
}

- (instancetype)initWithSize:(UserImageViewSize)size
{
    self = [self initWithFrame:CGRectZero];

    if (self) {
        self.size = size;
    }

    return self;
}

- (void)setupBasicProperties
{
    _shouldDesaturate = YES;
    _size = UserImageViewSizeSmall;

    self.accessibilityElementsHidden = YES;
    
    [self createIndicator];
    [self createConstraints];
}

- (CGSize)intrinsicContentSize
{
    CGFloat imageSize = self.size;
    return CGSizeMake(imageSize, imageSize);
}

- (void)setUser:(id<UserType, AccentColorProvider>)user
{    
    _user = user;
    
    if (self.userSession != nil && user != nil && ([user isKindOfClass:[ZMUser class]] || [user isKindOfClass:[ZMSearchUser class]])) {
        self.userObserverToken = [UserChangeInfo addObserver:self forUser:user userSession:self.userSession];
    }
    
    self.initials.textColor = UIColor.whiteColor;
    self.initials.text = user.initials.uppercaseString;
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self updateForServiceUserIfNeeded:user];
    [self setUserImage:nil];
    [self updateIndicatorColor];
    [self updateUserImage];
}

- (void)updateForServiceUserIfNeeded:(id <UserType>)user
{
    self.shape = [self shapeForUser:user];
    self.containerView.layer.borderColor = [self borderColorForUser:user];
    self.containerView.layer.borderWidth = [self borderWidthForUser:user];
    self.imageView.backgroundColor = [self containerBackgroundColorForUser:user];
    if (user.isServiceUser) {
        self.shouldDesaturate = false;
    }
}

- (AvatarImageViewShape)shapeForUser:(id <UserType>)user
{
    return user.isServiceUser ? AvatarImageViewShapeRoundedRelative : AvatarImageViewShapeCircle;
}

- (UIColor *)containerBackgroundColorForUser:(id <UserType>)user
{
    return user.isServiceUser ? UIColor.whiteColor : UIColor.clearColor;
}

- (CGColorRef)borderColorForUser:(id <UserType>)user
{
    return user.isServiceUser ? [UIColor.blackColor colorWithAlphaComponent:0.08].CGColor : nil;
}

- (CGFloat)borderWidthForUser:(id <UserType>)user
{
    return user.isServiceUser ? 0.5 : 0;
}

- (void)createIndicator
{
    self.indicator = [[RoundedView alloc ] initForAutoLayout];
    self.indicator.backgroundColor = UIColor.redColor;
    self.indicator.hidden = YES;
    [self.indicator toggleCircle];
    
    [self addSubview:self.indicator];
}

- (void)createConstraints
{
    [self setContentHuggingPriority:1000 forAxis:UILayoutConstraintAxisVertical];
    [self setContentHuggingPriority:1000 forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.indicator autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.indicator autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.indicator autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView withMultiplier:1.0f / 3.0f];
    [self.indicator autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.indicator];
}

- (void)updateIndicatorColor
{
    self.indicator.backgroundColor = [(id)self.user accentColor];
}

- (void)setUserImage:(UIImage *)userImage
{
    self.initials.hidden = userImage != nil;
    self.imageView.hidden = userImage == nil;
    self.imageView.image = userImage;
    
    BOOL isWireless = NO;
    if ([self.user respondsToSelector:@selector(isWirelessUser)]) {
        isWireless = [(id)self.user isWirelessUser];
    }
    
    if (userImage) {
        self.containerView.backgroundColor = [self containerBackgroundColorForUser:self.user];
    }
    else if ([self.user respondsToSelector:@selector(accentColor)] &&
             (self.user.isConnected || self.user.isSelfUser || self.user.isTeamMember || isWireless)) {
        self.containerView.backgroundColor = [(id)self.user accentColor];
    }
    else {
        self.containerView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if ([self.delegate respondsToSelector:@selector(userImageViewTouchUpInside:)]) {
        [self.delegate userImageViewTouchUpInside:self];
    }
}

#pragma mark - Indicator

- (void)setIndicatorEnabled:(BOOL)indicatorEnabled
{
    _indicatorEnabled = indicatorEnabled;
    
    self.indicator.hidden = ! indicatorEnabled;
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)change
{
    if (self.size == UserImageViewSizeBig) {
        if (change.imageMediumDataChanged || change.connectionStateChanged) {
            [self updateUserImage];
        }
    }
    else {
        if (change.imageSmallProfileDataChanged || change.connectionStateChanged || change.teamsChanged) {
            [self updateUserImage];
        }
    }
    
    if (change.accentColorValueChanged) {
        [self updateIndicatorColor];
    }
}

@end
