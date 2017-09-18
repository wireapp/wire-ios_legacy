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

@class NetworkStatusViewController;
@class VoiceChannelController;
@class NetworkActivityViewController;
@class BarController;
@class AppLockViewController;
@class ChatHeadsViewController;

@interface NotificationWindowRootViewController : UIViewController

@property (nonatomic, readonly) NetworkStatusViewController *networkStatusViewController;
@property (nonatomic, readonly) VoiceChannelController *voiceChannelController;
@property (nonatomic, readonly) AppLockViewController *appLockViewController;
@property (nonatomic, readonly) ChatHeadsViewController *chatHeadsViewController;

@property (nonatomic) BOOL showLoadMessages;

@property (nonatomic) BOOL hideNetworkActivityView;

- (void)transitionToLoggedInSession;
- (void)showLocalNotification:(UILocalNotification*)notification;

@end
