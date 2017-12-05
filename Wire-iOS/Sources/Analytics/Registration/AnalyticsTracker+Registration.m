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


#import "AnalyticsTracker+Registration.h"


NSString *NSStringFromAnalyticsPhotoSource(AnalyticsPhotoSource source)
{
    switch (source) {
        case AnalyticsPhotoSourceCamera:
            return @"camera";
            break;
            
        case AnalyticsPhotoSourceCameraRoll:
            return @"gallery";
            break;
            
        case AnalyticsPhotoSourceUnsplash:
            return @"unsplash";
            break;
    }
}


@implementation AnalyticsTracker (Registration)

- (void)tagEvent:(NSString *)event error:(NSError *)error
{
    [self tagEvent:event error:error attributes:@{}];
}

- (void)tagEvent:(NSString *)event error:(NSError *)error attributes:(NSDictionary *)attributes
{
    NSMutableDictionary *mutableAttributes = [attributes mutableCopy];
    
    [mutableAttributes setObject:error == nil ? @"success" : @"fail" forKey:@"outcome"];
    
    if (error != nil) {
        NSString *message = error.userInfo[NSLocalizedDescriptionKey];
        if (message != nil) {
            [mutableAttributes setObject:message forKey:@"error"];
        }
    }
    
    [self tagEvent:event attributes:mutableAttributes];
}

- (void)tagAcceptedGenericInvite
{
    [self tagEvent:AnalyticsEventAcceptedGenericInvite];
}

- (void)tagRegistrationSucceded
{
    [self tagEvent:@"registration.succeeded"];
}

#pragma mark - Phone

- (void)tagEnteredPhone
{
    [self tagEnteredPhoneFailedWithError:nil];
}

- (void)tagEnteredPhoneFailedWithError:(NSError *)error
{
    [self tagEvent:@"registration.entered_phone" error:error];
}

- (void)tagVerifiedPhone
{
    [self tagVerifiedPhoneFailedWithError:nil];
}

- (void)tagVerifiedPhoneFailedWithError:(NSError *)error
{
    [self tagEvent:@"registration.verified_phone" error:error];
}

- (void)tagResentPhoneVerification
{
    [self tagResentPhoneVerificationFailedWithError:nil];
}

- (void)tagResentPhoneVerificationFailedWithError:(NSError *)error
{
    [self tagEvent:@"registration.resent_phone_verification" error:error];
}

- (void)tagSkippedAddingPhone
{
    [self tagEvent:@"registration.skipped_adding_phone"];
}

#pragma mark - Email

- (void)tagEnteredEmailAndPassword
{
    [self tagEvent:@"registration.entered_email_and_password" error:nil];
}

- (void)tagVerifiedEmail
{
    [self tagVerifiedEmailFailedWithError:nil];
}

- (void)tagVerifiedEmailFailedWithError:(NSError *)error
{
    [self tagEvent:@"registration.verified_email" error:error];
}

- (void)tagResentEmailVerification
{
    [self tagResentEmailVerificationFailedWithError:nil];
}

- (void)tagResentEmailVerificationFailedWithError:(NSError *)error
{
    [self tagEvent:@"registration.resent_email_verification" error:error];
}

- (void)tagSkippedAddingEmail
{
    [self tagEvent:@"registration.skipped_adding_email"];
}

#pragma mark - Additional Details

- (void)tagEnteredName
{
    [self tagEvent:@"registration.entered_name" error:nil];
}

- (void)tagAddedPhotoFromSource:(AnalyticsPhotoSource)source
{
    [self tagEvent:@"registration.added_photo"
             error:nil
        attributes:@{@"source" : NSStringFromAnalyticsPhotoSource(source)}];
}

- (void)tagAcceptedTermsOfUse
{
    [self tagEvent:@"registration.accepted_terms_of_use"];
}

- (void)tagRegistrationConfirmedPersonalInvite
{
    [self tagEvent:@"registration.confirmed_personal_invite"];
}

- (void)tagRegistrationCancelledPersonalInvite
{
    [self tagEvent:@"registration.cancelled_personal_invite"];
}

#pragma mark - Phone Login

- (void)tagRequestedPhoneLogin
{
    [self tagEvent:@"requested_phone_login"];
}

- (void)tagResentPhoneLoginVerification
{
    [self tagResentPhoneLoginVerificationFailedWithError:nil];
}

- (void)tagResentPhoneLoginVerificationFailedWithError:(NSError *)error
{
    [self tagEvent:@"resent_phone_login_verification" error:error];
}

- (void)tagPhoneLogin
{
    [self tagPhoneLoginFailedWithError:nil];
}

- (void)tagPhoneLoginFailedWithError:(NSError *)error
{
    [self tagEvent:@"phone_login" error:error];
}

#pragma mark - Email Login

- (void)tagRequestedEmailLogin
{
    [self tagEvent:@"requested_email_login"];
}

- (void)tagEmailLogin
{
    [self tagEmailLoginFailedWithError:nil];
}

- (void)tagEmailLoginFailedWithError:(NSError *)error
{
    [self tagEvent:@"email_login" error:error];
}

@end
