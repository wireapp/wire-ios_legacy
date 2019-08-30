////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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


@class ProfileFooterView;
@class IncomingRequestFooterView;
@class UserNameDetailView;
@class ProfileTitleView;
@class TabBarController;

@import WireSyncEngine;

NS_ASSUME_NONNULL_BEGIN

@interface ProfileViewController () <ZMUserObserver>

@property (nonatomic, readonly) ProfileViewControllerContext context;
@property (nonatomic, readonly, nullable) ZMConversation *conversation;

@property (nonatomic) ProfileFooterView *profileFooterView;
@property (nonatomic) IncomingRequestFooterView *incomingRequestFooter;
@property (nonatomic) UserNameDetailView *usernameDetailsView;
@property (nonatomic) ProfileTitleView *profileTitleView;
@property (nonatomic) TabBarController *tabsController;

- (ZMUser * _Nullable)fullUser;
- (void)updateShowVerifiedShield;

@end

NS_ASSUME_NONNULL_END
