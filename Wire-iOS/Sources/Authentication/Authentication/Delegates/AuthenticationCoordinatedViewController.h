//
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

#import <Foundation/Foundation.h>

@class AuthenticationCoordinator;

/**
 * Actions that can be performed by the view controllers when authentication fails.
 */

typedef NS_ENUM(NSUInteger, AuthenticationErrorFeedbackAction) {
    /// The view should display a guidance dot to indicate user input is invalid.
    AuthenticationErrorFeedbackActionShowGuidanceDot,
    /// The view should clear the input fields.
    AuthenticationErrorFeedbackActionClearInputFields
};

/**
 * A view controller that is managed by an authentication coordinator.
 */

@protocol AuthenticationCoordinatedViewController <NSObject>

/// The object that coordinates authentication.
@property (nonatomic, weak, nullable) AuthenticationCoordinator *authenticationCoordinator;

/**
 * The view controller should execute the action to indicate authentication failure.
 * @param feedbackAction The action to execute to provide feedback to the user.
 */

@optional
- (void)executeErrorFeedbackAction:(AuthenticationErrorFeedbackAction)feedbackAction NS_SWIFT_NAME(executeErrorFeedbackAction(_:));

/**
 * The view controller should display information about the specified error.
 * @param error The error to present to the user.
 */

@optional
- (void)displayError:(NSError * _Nonnull)error;

@end
