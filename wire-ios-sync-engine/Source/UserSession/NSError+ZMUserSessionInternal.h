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


#import "NSError+ZMUserSession.h"

NS_ASSUME_NONNULL_BEGIN

@class ZMTransportResponse;

@interface NSError (ZMUserSessionInternal)

+ (instancetype)userSessionErrorWithErrorCode:(ZMUserSessionErrorCode)code userInfo:(nullable NSDictionary *)userInfo;

+ (__nullable instancetype)pendingLoginErrorWithResponse:(ZMTransportResponse *)response;
+ (__nullable instancetype)unauthorizedErrorWithResponse:(ZMTransportResponse *)response;
+ (__nullable instancetype)unauthorizedEmailErrorWithResponse:(ZMTransportResponse *)response;

+ (__nullable instancetype)invalidPhoneNumberErrorWithReponse:(ZMTransportResponse *)response;
+ (__nullable instancetype)phoneNumberIsAlreadyRegisteredErrorWithResponse:(ZMTransportResponse *)response;

+ (__nullable instancetype)invalidPhoneVerificationCodeErrorWithResponse:(ZMTransportResponse *)response;

+ (__nullable instancetype)invalidEmailVerificationCodeErrorWithResponse:(ZMTransportResponse *)response;

+ (__nullable instancetype)emailAddressInUseErrorWithResponse:(ZMTransportResponse *)response;
+ (__nullable instancetype)blacklistedEmailWithResponse:(ZMTransportResponse *)response;
+ (__nullable instancetype)domainBlockedWithResponse:(ZMTransportResponse *)response;
+ (__nullable instancetype)invalidEmailWithResponse:(ZMTransportResponse *)response;
+ (__nullable instancetype)keyExistsErrorWithResponse:(ZMTransportResponse *)response;

+ (__nullable instancetype)invalidInvitationCodeWithResponse:(ZMTransportResponse *)response;

+ (__nullable instancetype)lastUserIdentityCantBeRemovedWithResponse:(ZMTransportResponse *)response;

+ (__nullable instancetype)invalidActivationCodeWithResponse:(ZMTransportResponse *)response;

@end

NS_ASSUME_NONNULL_END
