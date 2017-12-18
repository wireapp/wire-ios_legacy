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

#import "FormStepDelegate.h"
#import "RegistrationRootViewController.h"
#import "WireSyncEngine+iOS.h"

@class AnalyticsTracker;
@class ZMEmailCredentials;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RegistrationFlow) {
    RegistrationFlowEmail,
    RegistrationFlowPhone
};


@protocol RegistrationViewControllerDelegate <NSObject>

- (void)registrationViewControllerDidCompleteRegistration;
- (void)registrationViewControllerDidSignIn;

@end



@interface RegistrationViewController : UIViewController

- (instancetype)initWithAuthenticationFlow:(AuthenticationFlowType)flow;

@property (nonatomic, weak) __nullable id<RegistrationViewControllerDelegate> delegate;
@property (nonatomic)  NSError * __nullable signInError;
@property (nonatomic) BOOL shouldHideCancelButton;

+ (RegistrationFlow)registrationFlow;

@end

NS_ASSUME_NONNULL_END
