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


@import ZMCSystem;

#import <ZMUtilities/ZMAccentColor.h>
#import "ZMUser.h"

@protocol ZMUserEditingObserver;
@protocol ZMUserEditingObserverToken;
@class ZMEmailCredentials;
@class ZMPhoneCredentials;

@protocol ZMEditableUser <NSObject>

@property (nonatomic, copy) NSString *name;
@property (nonatomic) ZMAccentColor accentColorValue;
@property (nonatomic, copy, readonly) NSString *emailAddress;
@property (nonatomic, copy, readonly) NSString *phoneNumber;

/// Setting this to compressed image data (e.g. JPEG or PNG) will generate user images from it and upload it to the backend.
/// Setting to @c nil is not supported. Use @c -deleteProfileImage to remove the profile image.
@property (nonatomic) NSData *originalProfileImageData;
/// Removes the profile image from the receiver.
- (void)deleteProfileImage;

@end



@protocol ZMUserEditingObserver <NSObject>

/// Invoked when the password could not be set on the backend
- (void)passwordUpdateRequestDidFail;

/// Invoked when the email could not be set on the backend (duplicated?).
/// The password might already have been set though - this is how BE is designed and there's nothing SE can do about it
- (void)emailUpdateDidFail:(NSError *)error;

/// Invoked when the email was sent to the backend
- (void)didSentVerificationEmail;

/// Invoked when requesting the phone number verification code failed
- (void)phoneNumberVerificationCodeRequestDidFail:(NSError *)error;

/// Invoken when requesting the phone number verification code succeeded
- (void)phoneNumberVerificationCodeRequestDidSucceed;

/// Invoked when the phone number code verification failed
- (void)phoneNumberVerificationDidFail:(NSError *)error;

// NOTE:
// - to know when the email was verified (by the user), just listen for changes in email on the self user
// - to know when the phone number was updated, just listen for changes in phone number on the self user

@end




@interface ZMCompleteRegistrationUser : NSObject <ZMEditableUser>

@property (nonatomic, readonly, copy) NSString *emailAddress;
@property (nonatomic, readonly, copy) NSString *password;
@property (nonatomic, readonly, copy) NSString *phoneNumber;
@property (nonatomic, readonly, copy) NSString *phoneVerificationCode;
@property (nonatomic, readonly, copy) NSString *invitationCode;

+ (instancetype)registrationUserWithEmail:(NSString *)email password:(NSString *)password;
+ (instancetype)registrationUserWithPhoneNumber:(NSString *)phoneNumber phoneVerificationCode:(NSString *)phoneVerificationCode;
+ (instancetype)registrationUserWithEmail:(NSString *)email password:(NSString *)password invitationCode:(NSString *)invitationCode;
+ (instancetype)registrationUserWithPhoneNumber:(NSString *)phoneNumber invitationCode:(NSString *)invitationCode;

@end



@interface ZMIncompleteRegistrationUser : NSObject <ZMEditableUser>

@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *phoneVerificationCode;
@property (nonatomic, copy) NSString *invitationCode;

/// This will assert if the email - password - phone - phoneVerificationCode is not set up properly.
- (ZMCompleteRegistrationUser *)completeRegistrationUser;

@end

