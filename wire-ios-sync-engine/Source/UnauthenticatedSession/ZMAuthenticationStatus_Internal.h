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


#import <WireSyncEngine/WireSyncEngine.h>

@class ZMCompleteRegistrationUser;

@interface ZMAuthenticationStatus () <ZMTimerClient>

@property (nonatomic, copy) NSString *registrationPhoneNumberThatNeedsAValidationCode;
@property (nonatomic, copy) NSString *loginPhoneNumberThatNeedsAValidationCode;
@property (nonatomic, copy) NSString *loginEmailThatNeedsAValidationCode;

@property (nonatomic) ZMCredentials *internalLoginCredentials;
@property (nonatomic) ZMPhoneCredentials *registrationPhoneValidationCredentials;
@property (nonatomic) ZMCompleteRegistrationUser *internalRegistrationUser;

@property (nonatomic) BOOL isWaitingForEmailVerification;
@property (nonatomic) BOOL isWaitingForBackupImport;
@property (nonatomic) BOOL completedRegistration;

@property (nonatomic) BOOL isWaitingForLogin;
@property (nonatomic) BOOL canClearCredentials;

@property (nonatomic, weak) id<ZMSGroupQueue> groupQueue;
@property (nonatomic) ZMTimer *loginTimer;

- (void)resetLoginAndRegistrationStatus;
- (void)setLoginCredentials:(ZMCredentials *)credentials;

@end

