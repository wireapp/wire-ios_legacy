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

@class RootViewController;
@class ZMUserSession;
@class NotificationWindowRootViewController;
@class FirstTimeUsageAgent;
@class ZMConversation;
@class MediaPlaybackManager;



@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// Singletons
@property (readonly, nonatomic) ZMUserSession *zetaUserSession;

@property (readonly, nonatomic) NotificationWindowRootViewController *notificationWindowController;
@property (readonly, nonatomic) UIWindow *notificationsWindow;
@property (readonly, nonatomic) MediaPlaybackManager *mediaPlaybackManager;

@property (nonatomic, assign, readonly) ApplicationLaunchType launchType;

@property (nonatomic, copy) dispatch_block_t hockeyInitCompletion;

+ (instancetype)sharedAppDelegate;

@end
