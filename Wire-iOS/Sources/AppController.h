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


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AppUIState) {
    AppUIStateNotLoaded,
    AppUIStateLaunchController,
    AppUIStateRootController,
};

typedef NS_ENUM(NSUInteger, AppSEState) {
    AppSEStateNotLoaded,
    AppSEStateMigration,
    AppSEStateBlacklisted,
    AppSEStateAuthPending,
    AppSEStateAuthenticated,
    AppSEStateNotAuthenticated,
};

@class ZMUserSession;
@class NotificationWindowRootViewController;
@class MediaPlaybackManager;
@class LaunchImageViewController;
@class AccountManager;
@class FileBackupExcluder;
@class UnauthenticatedSession;

FOUNDATION_EXPORT NSString *const ZMUserSessionDidBecomeAvailableNotification;

@interface AppController : NSObject <UIApplicationDelegate>
@property (nonatomic) AppUIState uiState;
@property (nonatomic) AppSEState seState;

@property (nonatomic, readonly) ZMUserSession *zetaUserSession;
@property (nonatomic) UnauthenticatedSession *unautenticatedUserSession;

@property (nonatomic, readonly) NotificationWindowRootViewController *notificationWindowController;
@property (nonatomic, readonly) UIWindow *notificationsWindow;
@property (nonatomic, readonly) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic) AccountManager *accountManager;
@property (nonatomic, readonly, weak) LaunchImageViewController *launchImageViewController;
@property (nonatomic, readonly) FileBackupExcluder *fileBackupExcluder;

- (void)performAfterUserSessionIsInitialized:(dispatch_block_t)block;
- (void)uploadAddressBookIfNeeded;
- (void)setupUserSession:(ZMUserSession *)userSession;
- (void)loadUnauthenticatedUIWithError:(NSError *)error;

@end
