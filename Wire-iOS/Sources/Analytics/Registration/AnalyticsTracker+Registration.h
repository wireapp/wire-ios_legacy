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


#import "AnalyticsTracker.h"

typedef NS_ENUM(NSUInteger, AnalyticsPhotoSource) {
    AnalyticsPhotoSourceUnsplash,
    AnalyticsPhotoSourceCamera,
    AnalyticsPhotoSourceCameraRoll
};

NSString *NSStringFromAnalyticsPhotoSource(AnalyticsPhotoSource source);

@interface AnalyticsTracker (Registration)

#pragma mark - Phone

- (void)tagEnteredPhone;
- (void)tagEnteredPhoneFailedWithError:(NSError *)error;
- (void)tagVerifiedPhone;
- (void)tagVerifiedPhoneFailedWithError:(NSError *)error;
- (void)tagResentPhoneVerification;
- (void)tagResentPhoneVerificationFailedWithError:(NSError *)error;
- (void)tagSkippedAddingPhone;

#pragma mark - Email

- (void)tagEnteredEmailAndPassword;
- (void)tagVerifiedEmail;
- (void)tagVerifiedEmailFailedWithError:(NSError *)error;
- (void)tagResentEmailVerification;
- (void)tagResentEmailVerificationFailedWithError:(NSError *)error;
- (void)tagSkippedAddingEmail;

#pragma mark - Additional Details

- (void)tagEnteredName;
- (void)tagAddedPhotoFromSource:(AnalyticsPhotoSource)source;
- (void)tagAcceptedTermsOfUse;
- (void)tagRegistrationSucceded;
- (void)tagRegistrationConfirmedPersonalInvite;
- (void)tagRegistrationCancelledPersonalInvite;
- (void)tagAcceptedGenericInvite;

#pragma mark - Phone Login

- (void)tagRequestedPhoneLogin;
- (void)tagResentPhoneLoginVerification;
- (void)tagResentPhoneLoginVerificationFailedWithError:(NSError *)error;
- (void)tagPhoneLogin;
- (void)tagPhoneLoginFailedWithError:(NSError *)error;

#pragma mark - Email Login

- (void)tagRequestedEmailLogin;
- (void)tagEmailLogin;
- (void)tagEmailLoginFailedWithError:(NSError *)error;

@end
