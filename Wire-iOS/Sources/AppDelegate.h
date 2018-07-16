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


@import UIKit;

#import "ApplicationLaunchType.h"

@class ZMUserSession;
@class UnauthenticatedSession;
@class CallWindowRootViewController;
@class FirstTimeUsageAgent;
@class ZMConversation;
@class MediaPlaybackManager;
@class SessionManager;
@class AppRootViewController;

FOUNDATION_EXPORT NSString * _Nonnull const ZMUserSessionDidBecomeAvailableNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, nonnull) UIWindow * window;

// Singletons
@property (readonly, nullable) UnauthenticatedSession *unauthenticatedSession;
@property (readonly, nonnull) SessionManager *sessionManager;
@property (readonly, nonnull) AppRootViewController *rootViewController;

@property (readonly, nullable) CallWindowRootViewController *callWindowRootViewController;
@property (readonly, nullable) UIWindow *notificationsWindow;
@property (readonly, nullable) MediaPlaybackManager *mediaPlaybackManager;

@property (readonly) ApplicationLaunchType launchType;

@property (nonatomic, copy, nullable) dispatch_block_t hockeyInitCompletion;

+ (instancetype _Nonnull )sharedAppDelegate;

@end
