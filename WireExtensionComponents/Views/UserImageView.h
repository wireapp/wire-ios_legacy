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

@import WireDataModel;
#import "AvatarImageView.h"
#import "AccentColorProvider.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, UserImageViewSize) {
    UserImageViewSizeTiny = 16,
    UserImageViewSizeSmall = 32,
    UserImageViewSizeNormal = 64,
    UserImageViewSizeBig = 320
};

@class UserImageView, ZMUserSession, Team;

@protocol UserType;

@protocol UserImageViewDelegate <NSObject>
@optional
- (void)userImageViewTouchUpInside:(UserImageView *)userImageView;
@end

@interface UserImageView : AvatarImageView <ZMUserObserver>

@property (nonatomic, nullable) id<UserType> user;
@property (nonatomic, nullable, weak) ZMUserSession *userSession;
@property (nonatomic) BOOL shouldDesaturate;
@property (nonatomic) BOOL indicatorEnabled;

@property (nonatomic) UserImageViewSize size;
@property (nonatomic, weak, nullable) id<UserImageViewDelegate> delegate;

- (instancetype)initWithSize:(UserImageViewSize)size;
- (void)setUserImage:(UIImage * _Nullable)userImage;

@end

NS_ASSUME_NONNULL_END
