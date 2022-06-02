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


@import WireUtilities;
@import WireTransport;
@import WireDataModel;

#import "ZMLoginTranscoder+Internal.h"
#import "ZMAuthenticationStatus.h"
#import "ZMCredentials.h"
#import "NSError+ZMUserSessionInternal.h"
#import "ZMUserSessionRegistrationNotification.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

NSString * const ZMLoginURL = @"/login?persist=true";
NSString * const ZMResendVerificationURL = @"/activate/send";
static ZMTransportRequestMethod const LoginMethod = ZMMethodPOST;
NSTimeInterval DefaultPendingValidationLoginAttemptInterval = 5;


@interface ZMLoginTranscoder ()

@property (nonatomic, weak) ZMAuthenticationStatus *authenticationStatus;
@property (nonatomic, readonly) ZMSingleRequestSync *verificationResendRequest;
@property (nonatomic, weak) id<ZMSGroupQueue> groupQueue;

@end


@implementation ZMLoginTranscoder

- (instancetype)initWithGroupQueue:(id<ZMSGroupQueue>)groupQueue
              authenticationStatus:(ZMAuthenticationStatus *)authenticationStatus
{
    return [self initWithGroupQueue:groupQueue
               authenticationStatus:authenticationStatus
                timedDownstreamSync:nil
          verificationResendRequest:nil];
}

- (instancetype)initWithGroupQueue:(id<ZMSGroupQueue>)groupQueue
              authenticationStatus:(ZMAuthenticationStatus *)authenticationStatus
               timedDownstreamSync:(ZMTimedSingleRequestSync *)timedDownstreamSync
         verificationResendRequest:(ZMSingleRequestSync *)verificationResendRequest
{
    self = [super init];
    
    if (self != nil) {
        self.groupQueue = groupQueue;
        self.authenticationStatus = authenticationStatus;
        _timedDownstreamSync = timedDownstreamSync ?: [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:0 groupQueue:groupQueue];
        _verificationResendRequest = verificationResendRequest ?: [[ZMSingleRequestSync alloc] initWithSingleRequestTranscoder:self groupQueue:groupQueue];

        _loginWithPhoneNumberSync = [[ZMSingleRequestSync alloc] initWithSingleRequestTranscoder:self groupQueue:groupQueue];
    }
    return self;
}

- (ZMStrategyConfigurationOption)configuration
{
    return ZMStrategyConfigurationOptionAllowsRequestsWhileUnauthenticated;
}

- (void)didChangeAuthenticationData
{
    self.timedDownstreamSync.timeInterval = 0;
}

- (void)tearDown
{
    [self.timedDownstreamSync invalidate];
}

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion
{
    ZMAuthenticationStatus *authenticationStatus = self.authenticationStatus;
    ZMTransportRequest *request;
    
    request = [self.verificationResendRequest nextRequestForAPIVersion:apiVersion];
    if(request) {
        return request;
    }
    
    if(authenticationStatus.currentPhase == ZMAuthenticationPhaseLoginWithPhone) {
        [self.loginWithPhoneNumberSync readyForNextRequestIfNotBusy];
        return [self.loginWithPhoneNumberSync nextRequestForAPIVersion:apiVersion];
    }
    if(authenticationStatus.currentPhase == ZMAuthenticationPhaseLoginWithEmail) {
        [self.timedDownstreamSync readyForNextRequestIfNotBusy];
        request = [self.timedDownstreamSync nextRequestForAPIVersion:apiVersion];
    }

    return request;
}

- (void)processEvents:(NSArray<ZMUpdateEvent *> __unused *)events
           liveEvents:(BOOL __unused)liveEvents
       prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult;
{
    // no op
}

- (NSArray *)contextChangeTrackers
{
    return @[];
}

- (ZMTransportRequest *)requestForSingleRequestSync:(ZMSingleRequestSync *)sync apiVersion:(APIVersion)apiVersion
{
    if (sync == self.timedDownstreamSync ||
        sync == self.loginWithPhoneNumberSync) {
        return [self loginRequestForAPIVersion: apiVersion];
    } else {
        return nil;
    }
}

- (ZMTransportRequest *)loginRequestForAPIVersion:(APIVersion)apiVersion
{
    ZMAuthenticationStatus *authenticationStatus = self.authenticationStatus;
    if (authenticationStatus.currentPhase == ZMAuthenticationPhaseAuthenticated) {
        return nil;
    }
    ZMCredentials *credentials = authenticationStatus.loginCredentials;
    if(credentials == nil) {
        return nil;
    }
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    if (credentials.emailVerificationCode != nil && credentials.email != nil && credentials.password != nil) {
       payload[@"email"] = credentials.email;
       payload[@"password"] = credentials.password;
       payload[@"verification_code"]  = credentials.emailVerificationCode;
    }
    else if (credentials.email != nil && credentials.password != nil) {
        payload[@"email"] = credentials.email;
        payload[@"password"] = credentials.password;
    }
    else if (credentials.phoneNumber != nil && credentials.phoneNumberVerificationCode != nil) {
        payload[@"phone"] = credentials.phoneNumber;
        payload[@"code"] = credentials.phoneNumberVerificationCode;
    }
    else {
        return nil;
    }
    if (CookieLabel.current.length != 0) {
        payload[@"label"] = CookieLabel.current.value;
    }
    return [[ZMTransportRequest alloc] initWithPath:ZMLoginURL method:LoginMethod payload:payload authentication:ZMTransportRequestAuthCreatesCookieAndAccessToken apiVersion:apiVersion];

}

- (void)didReceiveResponse:(ZMTransportResponse *)response forSingleRequest:(ZMSingleRequestSync *)sync
{
    if (sync == self.verificationResendRequest) {
        return;
    }
    
    BOOL shouldStartTimer = NO;
    ZMAuthenticationStatus * authenticationStatus = self.authenticationStatus;
    if (response.result == ZMTransportResponseStatusSuccess) {
        [authenticationStatus loginSucceededWithResponse:response];
    }
    else if (response.result == ZMTransportResponseStatusPermanentError) {
        
        if ([self isResponseForSuspendedAccount:response]) {
            [authenticationStatus didFailLoginBecauseAccountSuspended];
        } else if ([self isResponseForMissingEmailVerificationCode:response]){
            [authenticationStatus didFailLoginWithEmailBecauseVerificationCodeIsRequired];
        } else if ([self isResponseForInvalidEmailVerificationCode:response]) {
            [authenticationStatus didFailLoginWithEmailBecauseVerificationCodeIsInvalid];
        }
        else if (sync == self.timedDownstreamSync) {
            
            if ([self isResponseForPendingEmailActionvation:response]) {
                [authenticationStatus didFailLoginWithEmailBecausePendingValidation];
                shouldStartTimer = YES;
            }
            else {
                [authenticationStatus didFailLoginWithEmail:[self isResponseForInvalidCredentials:response]];
            }
        }
        else if (sync == self.loginWithPhoneNumberSync) {
            [authenticationStatus didFailLoginWithPhone:[self isResponseForInvalidCredentials:response]];
        }
    }

    if (shouldStartTimer) {
        if(self.timedDownstreamSync.timeInterval != DefaultPendingValidationLoginAttemptInterval) {
            self.timedDownstreamSync.timeInterval = DefaultPendingValidationLoginAttemptInterval;
        }
    }
    else {
        self.timedDownstreamSync.timeInterval = 0;
    }
}

- (BOOL)isResponseForInvalidCredentials:(ZMTransportResponse *)response
{
    NSString *label = [response.payload asDictionary][@"label"];
    return [label isEqualToString:@"invalid-credentials"] || [label isEqualToString:@"invalid-key"];
}

- (BOOL)isResponseForPendingEmailActionvation:(ZMTransportResponse *)response
{
    NSString *label = [response.payload asDictionary][@"label"];
    return [label isEqualToString:@"pending-activation"];
}

- (BOOL)isResponseForMissingEmailVerificationCode:(ZMTransportResponse *)response
{
    NSString *label = [response.payload asDictionary][@"label"];
    return [label isEqualToString:@"code-authentication-required"];
}

- (BOOL)isResponseForInvalidEmailVerificationCode:(ZMTransportResponse *)response
{
    NSString *label = [response.payload asDictionary][@"label"];
    return response.HTTPStatus == 403 && [label isEqualToString:@"code-authentication-failed"];
}

- (BOOL)isResponseForSuspendedAccount:(ZMTransportResponse *)response
{
    NSString *label = [response.payload asDictionary][@"label"];
    return response.HTTPStatus == 403 && [label isEqualToString:@"suspended"];
}

@end
