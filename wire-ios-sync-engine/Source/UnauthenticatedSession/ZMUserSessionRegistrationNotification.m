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


@import WireSystem;
@import WireDataModel;

#import "ZMUserSessionRegistrationNotification.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

static NSString * const UserSessionRegistrationNotificationName = @"ZMUserSessionRegistrationNotification";
static NSString * const VerificationEmailResendRequestNotificationName = @"ZMVerificationEmailResendRequest";

static NSString * const ZMUserSessionRegistrationEventKey = @"ZMUserSessionRegistrationEventKey";
static NSString * const ZMUserSessionRegistrationErrorKey = @"ZMUserSessionRegistrationErrorKey";

@interface ZMUserSessionRegistrationNotification()

@end

@implementation ZMUserSessionRegistrationNotification

+ (NSNotificationName)name {
    return UserSessionRegistrationNotificationName;
}

+ (void)notifyRegistrationDidFail:(NSError *)error context:(ZMAuthenticationStatus *)authenticationStatus
{
    NSCParameterAssert(error);
    NSDictionary *userInfo = @{ ZMUserSessionRegistrationEventKey : @(ZMRegistrationNotificationRegistrationDidFail),
                                ZMUserSessionRegistrationErrorKey : error };
    
    [[[NotificationInContext alloc] initWithName:self.name context:authenticationStatus object:nil userInfo:userInfo] post];
}

+ (void)notifyPhoneNumberVerificationDidFail:(NSError *)error context:(ZMAuthenticationStatus *)authenticationStatus
{
    NSCParameterAssert(error);
    NSDictionary *userInfo = @{ ZMUserSessionRegistrationEventKey : @(ZMRegistrationNotificationPhoneNumberVerificationDidFail),
                                ZMUserSessionRegistrationErrorKey : error };
    
    [[[NotificationInContext alloc] initWithName:self.name context:authenticationStatus object:nil userInfo:userInfo] post];
}

+ (void)notifyPhoneNumberVerificationCodeRequestDidFail:(NSError *)error context:(ZMAuthenticationStatus *)authenticationStatus
{
    NSCParameterAssert(error);
    NSDictionary *userInfo = @{ ZMUserSessionRegistrationEventKey : @(ZMRegistrationNotificationPhoneNumberVerificationCodeRequestDidFail),
                                ZMUserSessionRegistrationErrorKey : error };
    
    [[[NotificationInContext alloc] initWithName:self.name context:authenticationStatus object:nil userInfo:userInfo] post];
}

+ (void)notifyPhoneNumberVerificationCodeRequestDidSucceedInContext:(ZMAuthenticationStatus *)authenticationStatus;
{
    NSDictionary *userInfo = @{ ZMUserSessionRegistrationEventKey : @(ZMRegistrationNotificationPhoneNumberVerificationCodeRequestDidSucceed) };
    
    [[[NotificationInContext alloc] initWithName:self.name context:authenticationStatus object:nil userInfo:userInfo] post];
}

+ (void)notifyEmailVerificationDidSucceedInContext:(ZMAuthenticationStatus *)authenticationStatus
{
    NSDictionary *userInfo = @{ ZMUserSessionRegistrationEventKey : @(ZMRegistrationNotificationEmailVerificationDidSucceed) };
    
    [[[NotificationInContext alloc] initWithName:self.name context:authenticationStatus object:nil userInfo:userInfo] post];
}

+ (void)notifyPhoneNumberVerificationDidSucceedInContext:(ZMAuthenticationStatus *)authenticationStatus
{
    NSDictionary *userInfo = @{ ZMUserSessionRegistrationEventKey : @(ZMRegistrationNotificationPhoneNumberVerificationDidSucceed) };
    
    [[[NotificationInContext alloc] initWithName:self.name context:authenticationStatus object:nil userInfo:userInfo] post];
}

+ (id)addObserverInSession:(UnauthenticatedSession *)session withBlock:(void (^)(ZMUserSessionRegistrationNotificationType, NSError *))block
{
    return [self addObserverInContext:session.authenticationStatus withBlock:block];
}

+ (id)addObserverInContext:(ZMAuthenticationStatus *)context withBlock:(void (^)(ZMUserSessionRegistrationNotificationType, NSError *))block
{
    return [NotificationInContext addObserverWithName:self.name context:context object:nil queue:nil using:^(NotificationInContext * notification) {
        ZMUserSessionRegistrationNotificationType event = [notification.userInfo[ZMUserSessionRegistrationEventKey] unsignedIntegerValue];
        NSError *error = notification.userInfo[ZMUserSessionRegistrationErrorKey];
        block(event, error);
    }];
}

@end



@implementation ZMUserSessionRegistrationNotification (ResendVerificationEmail)

+ (void)resendValidationForRegistrationEmailInContext:(ZMAuthenticationStatus *)context;
{
    [[[NotificationInContext alloc] initWithName:VerificationEmailResendRequestNotificationName context:context object:nil userInfo:@{}] post];
}

+ (id)addObserverForRequestForVerificationEmail:(id<ZMRequestVerificationEmailObserver>)observer context:(ZMAuthenticationStatus *)context ZM_MUST_USE_RETURN;
{
    ZM_WEAK(observer);
    return [NotificationInContext addObserverWithName:VerificationEmailResendRequestNotificationName context:context object:nil queue:nil using:^(NotificationInContext * notification __unused) {
        ZM_STRONG(observer);
        [observer didReceiveRequestToResendValidationEmail];
    }];
}

@end


