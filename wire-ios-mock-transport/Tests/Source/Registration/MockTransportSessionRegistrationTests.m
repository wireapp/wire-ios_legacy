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


#import "MockTransportSessionTests.h"
@import WireMockTransport;

@interface MockTransportSessionRegistrationTests : MockTransportSessionTests

@end

@implementation MockTransportSessionRegistrationTests

- (MockUser *)userForEmail:(NSString *)email
{
    __block MockUser *user;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat: @"email == %@", email];
        
        NSArray *users = [self.sut.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        if (users.count == 1) {
            user = users[0];
        }
    }];
    return user;
}

- (MockUser *)userForPhone:(NSString *)phone
{
    __block MockUser *user;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation>  __unused session) {
        
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat: @"phone == %@", phone];
        
        NSArray *users = [self.sut.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        if (users.count == 1) {
            user = users[0];
        }
    }];
    return user;
}

- (void)testThatRegistrationReturns404OnWrongMethod
{
    // GIVEN
    ZMTransportRequestMethod methods[] = {ZMMethodHEAD, ZMMethodGET, ZMMethodDELETE, ZMMethodPUT};
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    for(size_t i = 0; i < sizeof(methods)/sizeof(methods[0]); ++i) {
        // WHEN
        ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:methods[i] apiVersion:0];
        
        // THEN
        XCTAssertEqual(response.HTTPStatus, 404);
        MockUser *user = [self userForEmail:payload[@"email"]];
        XCTAssertNil(user);
    }
}

- (void)testThatRegistrationReturns200AndCreatesAUserWithEmailIfAllRequiredUserFieldWherePresentOnAPost
{
    // GIVEN
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertNotNil(user);
        XCTAssertEqualObjects(user.password, payload[@"password"]);
        XCTAssertEqualObjects(user.name, payload[@"name"]);
        XCTAssertEqualObjects(user.email, payload[@"email"]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationWithEmailReturnsCookies
{
    // GIVEN
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    NSURL *url = [NSURL URLWithString:@"/register" relativeToURL:self.sut.baseURL];
    
    // THEN
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:response.headers forURL:url];
    XCTAssertEqual(cookies.count, 1u);
    XCTAssertEqualObjects([(NSHTTPCookie *)cookies.firstObject name], @"zuid");
}

- (void)testThatRegistrationWithEmailStoresCookiesIfPolicyIsAlways
{
    // GIVEN
    [ZMPersistentCookieStorage setCookiesPolicy:NSHTTPCookieAcceptPolicyAlways];
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // WHEN
    __unused ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // expect
    __block NSData *cookieData;
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:ZM_ARG_SAVE(cookieData)];
    
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationWithEmailDoesNotStoreCookiesIfPolicyIsNever
{
    // GIVEN
    [ZMPersistentCookieStorage setCookiesPolicy:NSHTTPCookieAcceptPolicyAlways];
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // WHEN
    __unused ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // expect
    __block NSData *cookieData;
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:ZM_ARG_SAVE(cookieData)];
    
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatRegistrationCreatesAUserWithNoValidatedEmail
{
    // GIVEN
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertFalse(user.isEmailValidated);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationWithNotVerifiedEmailReturnsPayloadWithNoEmail
{
    // GIVEN
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNil([[response.payload asDictionary] optionalStringForKey:@"email"]);
}

- (void)testThatRegistrationCreatesAUserWithValidatedEmailIfItsWhitelisted
{
    // GIVEN
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session whiteListEmail:payload[@"email"]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    XCTAssertEqualObjects([[response.payload asDictionary] optionalStringForKey:@"email"], payload[@"email"]);

    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertTrue(user.isEmailValidated);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThattestThatARegisterEmailUserPendingValidationIsValidatedWhenWhitelisted
{
    // GIVEN
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    XCTAssertNotNil(response);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session whiteListEmail:payload[@"email"]];
    }];
    
    // THEN
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertTrue(user.isEmailValidated);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationWithEmailReturns200AndCreatesAUserWithallFieldsOnAPost
{
    // GIVEN
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              @"accent_id" : @(2)
                              };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertNotNil(user);
        XCTAssertEqualObjects(user.password, payload[@"password"]);
        XCTAssertEqualObjects(user.name, payload[@"name"]);
        XCTAssertEqualObjects(user.email, payload[@"email"]);
        XCTAssertEqualObjects(user.phone, payload[@"phone"]);
        XCTAssertEqual(user.accentID, [payload[@"accent_id"] integerValue]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationReturns400IfSomeRequiredFieldAreMissing
{
    // GIVEN
    NSDictionary *originalPayload = @{
                                      @"name" : @"Someone someone",
                                      @"email" : @"someone@example.com",
                                      @"password" : @"supersecure",
                                      };
    
    for(NSString *key in originalPayload.allKeys) {
        NSMutableDictionary *dictionaryWithoutAKey = [dictionaryWithoutAKey mutableCopy];
        [dictionaryWithoutAKey removeObjectForKey:key];
        
        // WHEN
        ZMTransportResponse *response = [self responseForPayload:dictionaryWithoutAKey path:@"/register" method:ZMMethodPOST apiVersion:0];
        
        // THEN
        XCTAssertEqual(response.HTTPStatus, 400);
        MockUser *user = [self userForEmail:originalPayload[@"email"]];
        XCTAssertNil(user);
    }
}

- (void)testThatRegistrationReturns409IfTheEmailIsAlreadyRegistered
{
    // GIVEN
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"xxx-someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *user = [session insertUserWithName:payload[@"name"]];
        user.email = payload[@"email"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertEqualObjects([response payloadLabel], @"key-exists");
}

- (void)requestVerificationCodeForPhone:(NSString *)phone {
    NSDictionary *requestPayload = @{@"phone":phone};
    NSString *path = [NSString pathWithComponents:@[@"/", @"activate", @"send"]];
    [self responseForPayload:requestPayload path:path method:ZMMethodPOST apiVersion:0];
}

- (void)testThatRegistrationWithPhoneNumberReturns201AndCreatesAUserIfItHasAValidPhoneVerificationCode
{
    // GIVEN
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.phoneVerificationCodeForRegistration,
                              };
    [self requestVerificationCodeForPhone:phone];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForPhone:phone];
    XCTAssertNotNil(user);
    XCTAssertEqualObjects(user.name, payload[@"name"]);
    XCTAssertEqualObjects(user.phone, payload[@"phone"]);
}

- (void)testThatRegistrationWithPhoneNumberReturns201AndSetsTheCookie
{
    // GIVEN
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.phoneVerificationCodeForRegistration,
                              };
    [self requestVerificationCodeForPhone:phone];
    
    // expect
    __block NSData *cookieData;
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:ZM_ARG_SAVE(cookieData)];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNotNil(cookieData);
}

- (void)testThatRegistrationWithPhoneNumberReturns409ItThereIsAlreadyAUserWithThatPhone
{
    // GIVEN
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.phoneVerificationCodeForRegistration,
                              };
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *user = [session insertUserWithName:payload[@"name"]];
        user.phone = payload[@"phone"];
    }];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertEqualObjects([response payloadLabel], @"key-exists");
}

- (void)testThatRegistrationWithPhoneNumberReturns404IfThereIsNoPhoneWithPendingVerificationCode
{
    // GIVEN
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.phoneVerificationCodeForRegistration,
                              };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatRegistrationWithPhoneNumberReturns404IfTheVerificationCodeIsWrong
{
    // GIVEN
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.invalidPhoneVerificationCode,
                              };
    [self requestVerificationCodeForPhone:phone];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 404);
}

@end
