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
#import "AuthenticationCoordinatedViewController.h"

typedef NS_ENUM(NSUInteger, AuthenticationFlowType) {
    AuthenticationFlowOnlyLogin = 0,
    AuthenticationFlowLogin,
    AuthenticationFlowRegistration
};

@class LoginCredentials, AuthenticationCoordinator;

NS_ASSUME_NONNULL_BEGIN

@interface RegistrationRootViewController : UIViewController <AuthenticationCoordinatedViewController>

@property (nonatomic) BOOL showLogin;
@property (nonatomic) BOOL shouldHideCancelButton;

@property (nonatomic, nullable) LoginCredentials *loginCredentials;

- (instancetype)initWithAuthenticationFlow:(AuthenticationFlowType)flow NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil NS_UNAVAILABLE;

- (void)presentLoginTab;
- (void)presentRegistrationTab;

@end

NS_ASSUME_NONNULL_END
