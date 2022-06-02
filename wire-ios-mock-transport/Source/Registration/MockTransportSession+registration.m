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


@import WireTransport;
@import WireUtilities;
@import WireSystem;
#import "MockTransportSession+registration.h"
#import <WireMockTransport/WireMockTransport-Swift.h>

@implementation MockTransportSession (Registration)

- (MockUser *)userWithEmail:(NSString *)email {
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"email == %@", email];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    if(users.count > 0u) {
        return users.firstObject;
    }
    return nil;
}

- (MockUser *)userWithPhone:(NSString *)phone {
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"phone == %@", phone];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    if(users.count > 0u) {
        return users.firstObject;
    }
    return nil;
}


/// Handles "/register"
- (ZMTransportResponse *)processRegistrationRequest:(ZMTransportRequest *)request
{
    if(request.method == ZMMethodPOST) {
        
        NSDictionary *userDetails = [request.payload asDictionary];
        
        NSString *name = [userDetails optionalStringForKey:@"name"];
        NSString *email = [userDetails optionalStringForKey:@"email"];
        NSString *phone = [userDetails optionalStringForKey:@"phone"];
        NSString *password = [userDetails optionalStringForKey:@"password"];
        NSString *phoneCode = [userDetails optionalStringForKey:@"phone_code"];
        NSString *invitationCode = [userDetails optionalStringForKey:@"invitation_code"];

        if( name == nil
           || (email == nil && phone == nil)
           || (email != nil && password == nil)
           || (phone != nil && phoneCode == nil && invitationCode == nil))
        {
            return [self errorResponseWithCode:400 reason:@"missing-key" apiVersion:request.apiVersion];
        }
        
        // check if it's already there
        if(email != nil && [self userWithEmail:email] != nil) {
            return [self errorResponseWithCode:409 reason:@"key-exists" apiVersion:request.apiVersion];
        }
        if(phone != nil && [self userWithPhone:phone] != nil) {
            return [self errorResponseWithCode:409 reason:@"key-exists" apiVersion:request.apiVersion];
        }
        
        if (phone != nil) {
            if (![self.phoneNumbersWaitingForVerificationForRegistration containsObject:phone])
            {
                return [self errorResponseWithCode:404 reason:@"invalid-key" apiVersion:request.apiVersion];
            }
            
            if(![phoneCode isEqualToString:self.phoneVerificationCodeForRegistration]) {
                return [self errorResponseWithCode:404 reason:@"invalid-credentials" apiVersion:request.apiVersion];
            }
        }
        
        // at this point, we validated everything
        MockUser *user = self.selfUser;
        if (user == nil){
            user = [self insertSelfUserWithName:name];
            self.selfUser = user;
        }
        else {
            user.name = name;
        }
        user.password = password;
        user.email = email;
        user.phone = phone;
        if(userDetails[@"accent_id"] != nil) {
            user.accentID = (int16_t) [[userDetails numberForKey:@"accent_id"] integerValue];
        }
        
        BOOL shouldReturnEmail = YES;
        if(user.email != nil && ![self.whitelistedEmails containsObject:user.email]) {
            user.isEmailValidated = NO;
            shouldReturnEmail = NO;
        }
        
        NSMutableDictionary *payload = [@{@"email": (user.email != nil && shouldReturnEmail) ? user.email : [NSNull null],
                                  @"phone": user.phone != nil ? user.phone : [NSNull null],
                                  @"accent_id": @(user.accentID),
                                  @"name": user.name,
                                  @"id": user.identifier
                                  } mutableCopy];
        
        // phone registration completed. this also triggers log in
        if(phone != nil && invitationCode == nil) {
            [self.phoneNumbersWaitingForVerificationForRegistration removeObject:phone];
        }

        NSString *cookiesValue = @"fake cookie";
        
        if ([ZMPersistentCookieStorage cookiesPolicy] != NSHTTPCookieAcceptPolicyNever) {
            self.cookieStorage.authenticationCookieData = [cookiesValue dataUsingEncoding:NSUTF8StringEncoding];
        }

        return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil headers:@{@"Set-Cookie": [NSString stringWithFormat:@"zuid=%@", cookiesValue]} apiVersion:request.apiVersion];
    }
    
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}

/// Handles "/activate"
- (ZMTransportResponse *)processPhoneActivationRequest:(ZMTransportRequest *)request;
{
    if (request.method == ZMMethodPOST) {
        NSDictionary *userDetails = [request.payload asDictionary];
        
        NSString *code = [userDetails optionalStringForKey:@"code"];
        NSString *phone = [userDetails optionalStringForKey:@"phone"];
        NSString *email = [userDetails optionalStringForKey:@"email"];

        BOOL dryrun = ((NSNumber *)[userDetails optionalNumberForKey:@"dryrun"]).boolValue;
        
        if(code == nil && (phone == nil || email == nil)) {
            return [self errorResponseWithCode:400 reason:@"missing-key" apiVersion:request.apiVersion];
        }

        if([self.emailsWaitingForVerificationForRegistration containsObject:email]){
            if(![code isEqualToString:self.emailActivationCode]) {
                return [self errorResponseWithCode:404 reason:@"not-found" apiVersion:request.apiVersion];
            }
            else {
                if(!dryrun) {
                    [self.emailsWaitingForVerificationForRegistration removeObject:email];
                }
                return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];

            }
        }
        else if([self.phoneNumbersWaitingForVerificationForRegistration containsObject:phone]) {
            if(![code isEqualToString:self.phoneVerificationCodeForRegistration]) {
                return [self errorResponseWithCode:404 reason:@"not-found" apiVersion:request.apiVersion];
            }
            else {
                if(!dryrun) {
                    [self.phoneNumbersWaitingForVerificationForRegistration removeObject:phone];
                }
                return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];

            }
        }
        else if([self.phoneNumbersWaitingForVerificationForProfile containsObject:phone]) {
            if(![code isEqualToString:self.phoneVerificationCodeForUpdatingProfile]) {
                return [self errorResponseWithCode:404 reason:@"not-found" apiVersion:request.apiVersion];
            }
            else {
                if(!dryrun) {
                    [self.phoneNumbersWaitingForVerificationForProfile removeObject:phone];
                    self.selfUser.phone = phone;
                    [self saveAndCreatePushChannelEventForSelfUser];
                }
                return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];
                
            }
        }
        else {
            return [self errorResponseWithCode:404 reason:@"not-found" apiVersion:request.apiVersion];
        }
    }
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}


/// Handles "/active/send"
- (ZMTransportResponse *)processVerificationCodeRequest:(ZMTransportRequest *)request
{
    if (request.method == ZMMethodPOST) {
        NSDictionary *userDetails = [request.payload asDictionary];
        
        NSString *email = [userDetails optionalStringForKey:@"email"];
        NSString *phone = [userDetails optionalStringForKey:@"phone"];
        
        if(email == nil && phone == nil) {
            return [self errorResponseWithCode:400 reason:@"missing-key" apiVersion:request.apiVersion];
        }
        
        if(email != nil) {
            MockUser *existingUser = [self userWithEmail:email];
            if(existingUser != nil
               && (
                   (existingUser == self.selfUser && self.selfUser.isEmailValidated)
                   || existingUser != self.selfUser
                   )
               ) {
                return [self errorResponseWithCode:409 reason:@"key-exists" apiVersion:request.apiVersion];
            }

            [self.emailsWaitingForVerificationForRegistration addObject:email];

        }
        else if(phone != nil) {
            if([self userWithPhone:phone] != nil) {
                return [self errorResponseWithCode:409 reason:@"key-exists" apiVersion:request.apiVersion];
            }
            
            [self.phoneNumbersWaitingForVerificationForRegistration addObject:phone];
        }
        
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];
    }
    
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}

@end
