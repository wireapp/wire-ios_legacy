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


@import Foundation;
@import WireSystem;

@class ZMAuthenticationStatus;
@class UnauthenticatedSession;


typedef NS_ENUM(NSUInteger, ZMUserSessionRegistrationNotificationType) {
    ZMRegistrationNotificationEmailVerificationDidSucceed,
    ZMRegistrationNotificationEmailVerificationDidFail,
    ZMRegistrationNotificationPhoneNumberVerificationDidSucceed,
    ZMRegistrationNotificationPhoneNumberVerificationDidFail,
    ZMRegistrationNotificationPhoneNumberVerificationCodeRequestDidFail,
    ZMRegistrationNotificationPhoneNumberVerificationCodeRequestDidSucceed,
    ZMRegistrationNotificationRegistrationDidFail
};

@interface ZMUserSessionRegistrationNotification : NSObject

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic) NSError *error;
@property (nonatomic) ZMUserSessionRegistrationNotificationType type;

/// Notifies all @c ZMAuthenticationObserver that the authentication failed
+ (void)notifyRegistrationDidFail:(NSError *)error context:(ZMAuthenticationStatus *)authenticationStatus;
+ (void)notifyPhoneNumberVerificationDidFail:(NSError *)error context:(ZMAuthenticationStatus *)authenticationStatus;
+ (void)notifyPhoneNumberVerificationCodeRequestDidFail:(NSError *)error context:(ZMAuthenticationStatus *)authenticationStatus;

+ (void)notifyEmailVerificationDidSucceedInContext:(ZMAuthenticationStatus *)authenticationStatus;
+ (void)notifyPhoneNumberVerificationDidSucceedInContext:(ZMAuthenticationStatus *)authenticationStatus;
+ (void)notifyPhoneNumberVerificationCodeRequestDidSucceedInContext:(ZMAuthenticationStatus *)authenticationStatus;

+ (id)addObserverInSession:(UnauthenticatedSession *)session withBlock:(void(^)(ZMUserSessionRegistrationNotificationType event, NSError *error))block ZM_MUST_USE_RETURN;
+ (id)addObserverInContext:(ZMAuthenticationStatus *)context withBlock:(void(^)(ZMUserSessionRegistrationNotificationType event, NSError *error))block ZM_MUST_USE_RETURN;

+ (NSNotificationName)name;

@end


@protocol ZMRequestVerificationEmailObserver
- (void)didReceiveRequestToResendValidationEmail;
@end


@interface ZMUserSessionRegistrationNotification (VerificationEmail)

+ (void)resendValidationForRegistrationEmailInContext:(ZMAuthenticationStatus *)context;
+ (id)addObserverForRequestForVerificationEmail:(id<ZMRequestVerificationEmailObserver>)observer context:(ZMAuthenticationStatus *)context ZM_MUST_USE_RETURN;

@end

