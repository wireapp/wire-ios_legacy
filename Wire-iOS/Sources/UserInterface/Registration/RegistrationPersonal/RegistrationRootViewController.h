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


#import <UIKit/UIKit.h>

#import "FormFlowViewController.h"

typedef NS_ENUM(NSUInteger, AuthenticationFlowType) {
    AuthenticationFlowRegular,
    AuthenticationFlowOnlyLogin,
    AuthenticationFlowOnlyRegistration
};

@class AnalyticsTracker, ZMIncompleteRegistrationUser, LoginCredentials;

@interface RegistrationRootViewController : FormFlowViewController

@property (nonatomic) BOOL hasSignInError;
@property (nonatomic) BOOL showLogin;
@property (nonatomic) LoginCredentials *loginCredentials;
@property (nonatomic) BOOL shouldHideCancelButton;

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser authenticationFlow:(AuthenticationFlowType)flow;
- (void)presentLoginTab;
- (void)presentRegistrationTab;

@end
