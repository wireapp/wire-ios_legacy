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

@class UserClient;



@protocol ZMClientRegistrationStatusDelegate <NSObject>

- (void)didRegisterSelfUserClient:(UserClient *)userClient;
- (void)didFailToRegisterSelfUserClient:(NSError *)error NS_SWIFT_NAME(didFailToRegisterSelfUserClient(error:));
- (void)didDeleteSelfUserClient:(NSError *)error NS_SWIFT_NAME(didDeleteSelfUserClient(error:));

@end



@protocol ZMSyncStateDelegate <ZMClientRegistrationStatusDelegate>

/// The session did start the slow sync (fetching of users, conversations, ...)
- (void)didStartSlowSync;
/// The session did finish the slow sync
- (void)didFinishSlowSync;
/// The session did start the quick sync (fetching of the notification stream)
- (void)didStartQuickSync;
/// The session did finish the quick sync
- (void)didFinishQuickSync;

@end
