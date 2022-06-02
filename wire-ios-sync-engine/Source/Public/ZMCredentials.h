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


@interface ZMCredentials : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *email;
@property (nonatomic, copy, readonly, nullable) NSString *password;
@property (nonatomic, copy, readonly, nullable) NSString *phoneNumber;
@property (nonatomic, copy, readonly, nullable) NSString *phoneNumberVerificationCode;
@property (nonatomic, copy, readonly, nullable) NSString *emailVerificationCode;

@property (nonatomic, readonly) BOOL credentialWithEmail;
@property (nonatomic, readonly) BOOL credentialWithPhone;

@end


@interface ZMPhoneCredentials : ZMCredentials

+ (nonnull ZMPhoneCredentials *)credentialsWithPhoneNumber:(nonnull NSString *)phoneNumber verificationCode:(nonnull NSString *)verificationCode;

@end


@interface ZMEmailCredentials : ZMCredentials

+ (nonnull ZMEmailCredentials *)credentialsWithEmail:(nonnull NSString *)email password:(nonnull NSString *)password;

+ (nonnull ZMEmailCredentials *)credentialsWithEmail:(nonnull NSString *)email password:(nonnull NSString *)password emailVerificationCode:(nullable NSString *)code;

@end
