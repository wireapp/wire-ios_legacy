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


#import "UserAuthentication.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

#import "FileManager.h"
#import "WireSyncEngine+iOS.h"

#else
    #import "WireSyncEngine+OS_X.h"
    #import "Constants.h"
#endif

#import "Analytics+iOS.h"
#import "AppDelegate.h"


NSString *const UserAuthenticationFailedNotification                = @"UserAuthenticationFailed";
NSString *const UserAuthenticationSucceededNotification             = @"UserAuthenticationSucceeded";
NSString *const UserRegistrationFailedNotification                  = @"UserRegistrationFailed";
NSString *const UserRegistrationPendingAuthenticationNotification   = @"UserRegistrationPendingAuthentication";
NSString *const UserAuthenticationUserInfoError                     = @"UserAuthenticationUserInfoError";



@interface UserAuthentication ()

@property(nonatomic, strong) ZMUserSession *userSession;
@property(nonatomic, copy) UserAuthCompletionHandler userAuthCompletionHandler;
@property(nonatomic, copy) UserAuthErrorHandler userAuthErrorHandler;

@property(readwrite, nonatomic, assign) BOOL isAuthenticated;
@property(readwrite, nonatomic, strong) NSError *currentAuthError;

@property (nonatomic) id<ZMAuthenticationObserverToken> token;
@end



@interface UserAuthentication (AuthenticationDelegate) <ZMAuthenticationObserver>
@end



@implementation UserAuthentication

- (void)dealloc
{
    [self.userSession removeAuthenticationObserverForToken:self.token];
}

+ (instancetype)sharedUserAuthentication
{
    return [AppDelegate sharedAppDelegate].userAuthentication;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUserAuthenticationWithUserSession:nil];
    }
    return self;
}

- (id)initWithUserSession:(ZMUserSession *)userSession
{
    self = [super init];
    if (self) {
        [self setupUserAuthenticationWithUserSession:userSession];
    }
    return self;
}

- (void)setupUserAuthenticationWithUserSession:(ZMUserSession *)userSession
{
    self.userSession = userSession != nil ? userSession : [ZMUserSession sharedSession];
    self.token = [self.userSession addAuthenticationObserver:self];
}

- (void)attemptToResumeSession
{
    [self.userSession start];
}

@end



@implementation UserAuthentication (AuthenticationDelegate)

- (void)authenticationDidSucceed
{
    DDLogDebug(@"authenticationDidSucceed");
    
    self.isAuthenticated = YES;
    self.currentAuthError = nil;

    [[Analytics shared] tagAuthenticationSucceeded];
    
    if (self.userAuthCompletionHandler) {
        self.userAuthCompletionHandler([ZMUser selfUser]);
        self.userAuthCompletionHandler = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UserAuthenticationSucceededNotification object:self];
}

- (void)authenticationDidFail:(NSError *)error
{
    DDLogDebug(@"authenticationDidFail");
    self.currentAuthError = error;
    self.isAuthenticated = NO;

    if (self.userAuthErrorHandler) {
        self.userAuthErrorHandler(nil);
        self.userAuthErrorHandler = nil;
    }
    
    if (error.code == ZMUserSessionAccountIsPendingActivation) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UserRegistrationPendingAuthenticationNotification object:self userInfo:@{UserAuthenticationUserInfoError : error}];
        }];
    }
    else {
        [[Analytics shared] tagAuthenticationFailedWithReason:error.localizedDescription];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UserAuthenticationFailedNotification object:self userInfo:@{UserAuthenticationUserInfoError : error}];
        }];
    }
}

@end
