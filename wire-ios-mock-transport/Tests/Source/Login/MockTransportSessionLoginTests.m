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

@interface MockTransportSessionLoginTests : MockTransportSessionTests

@end

@implementation MockTransportSessionLoginTests

- (void)testThatLoginSucceedsAndSetsTheCookieWithEmail
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": password
                                                               } path:path method:ZMMethodPOST apiVersion:0];

    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    [self verifyMockLater:self.cookieStorage];

}

- (void)testThatLoginSucceedsAndSetsTheCookieWithPhoneNumberAfterRequestingALoginCode
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *phone = @"+49000000";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = phone;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST apiVersion:0];

    // and when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"phone": phone,
                                                               @"code": self.sut.phoneVerificationCodeForLogin
                                                               } path:@"/login" method:ZMMethodPOST apiVersion:0];

    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    [self verifyMockLater:self.cookieStorage];

}

- (void)testThatLoginSucceedsAndSetsTheCookie_WhenLoggingInWithCorrectEmailVerificationCode
{
    // GIVEN
    __block MockUser *selfUser;
    NSString *email = @"test@wire.com";
    NSString *password = @"Bar481516";
    NSString *action = @"login";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    ZMTransportResponse *verificationCodeSendResponse = [self responseForPayload:@{@"email":email, @"action":action}
                                                                            path:@"/verification-code/send"
                                                                          method:ZMMethodPOST
                                                                      apiVersion:0];

    [self responseForPayload:@{@"email":email} path:@"/login/send" method:ZMMethodPOST apiVersion:0];

    // and when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": password,
                                                               @"verification_code": self.sut.generatedEmailVerificationCode
                                                               } path:@"/login" method:ZMMethodPOST apiVersion:0];

    // THEN
    XCTAssertNotNil(response);
    XCTAssertNotNil(verificationCodeSendResponse);
    XCTAssertEqual(response.HTTPStatus, 200);
    [self verifyMockLater:self.cookieStorage];
}

- (void)testThatLoginFails_WhenLoggingInWithMissingEmailVerificationCode

{
    // GIVEN
    __block MockUser *selfUser;
    NSString *email = @"test@wire.com";
    NSString *password = @"Bar481516";
    NSString *action = @"login";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    ZMTransportResponse *verificationCodeSendResponse = [self responseForPayload:@{
                                                                                  @"email":email,
                                                                                  @"action":action
                                                                                  } path:@"/verification-code/send" method:ZMMethodPOST apiVersion:0];

    // THEN
    XCTAssertNotNil(verificationCodeSendResponse);
    XCTAssertEqual(verificationCodeSendResponse.HTTPStatus, 200);

    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": password,
                                                               } path:@"/login" method:ZMMethodPOST apiVersion:0];

    // THEN
    XCTAssertNotNil(verificationCodeSendResponse);
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects([response payloadLabel], @"code-authentication-required");
    [self verifyMockLater:self.cookieStorage];
}

- (void)testThatPhoneLoginFailsIfTheLoginCodeIsWrong
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *phone = @"+49000000";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = phone;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST apiVersion:0];

    // and when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"phone": phone,
                                                               @"code": self.sut.invalidPhoneVerificationCode
                                                               } path:@"/login" method:ZMMethodPOST apiVersion:0];

    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 404);
    [self verifyMockLater:self.cookieStorage];

}

- (void)testThatLoginFails_WhenLoggingInWithIncorrectEmailVerificationCode
{
    // GIVEN
    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";
    NSString *verificationCode = @"123457";
    NSString *action = @"login";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
    }];

    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    ZMTransportResponse *verificationCodeSendResponse = [self responseForPayload:@{@"email":email, @"action":action}
                                                                            path:@"/verification-code/send"
                                                                          method:ZMMethodPOST
                                                                      apiVersion:0];

    // THEN
    XCTAssertNotNil(verificationCodeSendResponse);
    XCTAssertEqual(verificationCodeSendResponse.HTTPStatus, 200);


    // and when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": password,
                                                               @"verification_code": verificationCode,
                                                               } path:@"/login" method:ZMMethodPOST apiVersion:0];

    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects([response payloadLabel], @"code-authentication-failed");
    [self verifyMockLater:self.cookieStorage];
}

- (void)testThatPhoneLoginFailsIfThereIsNoUserWithSuchPhone
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *phone = @"+49000000";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = @"+491231231231231123";
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST apiVersion:0];

    // and when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"phone": phone,
                                                               @"code": self.sut.phoneVerificationCodeForLogin
                                                               } path:@"/login" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 404);
    [self verifyMockLater:self.cookieStorage];

}

- (void)testThatRequestingThePhoneLoginCodeSucceedsIfThereIsAUserWithSuchPhone
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *phone = @"+49000000";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = phone;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

     // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
}


- (void)testThatRequestingThePhoneLoginCodeFailsIfThereIsNoUserWithSuchPhone
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *phone = @"+49000000";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = @"4324324";
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatPhoneLoginFailsIfNoVerificationCodeWasRequested
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *phone = @"+49000000";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = phone;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"phone": phone,
                                                               @"code": self.sut.phoneVerificationCodeForLogin
                                                               } path:@"/login" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 404);
    [self verifyMockLater:self.cookieStorage];

}


- (void)testThatItReturns403PendingActivationIfTheUserIsPendingEmailValidation
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
        selfUser.isEmailValidated = NO;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // WHEN
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": password
                                                               } path:path method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects([response payloadLabel], @"pending-activation");
}

- (void)testThatLoginFailsAndDoesNotSetTheCookie
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"good"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [[(id) self.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];

    // WHEN
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": @"invalid"
                                                               } path:path method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects(response.payload.asDictionary[@"label"], @"invalid-credentials");
    [self verifyMockLater:self.cookieStorage];
}



- (void)testThatLoginFailsForWrongEmailAndDoesNotSetTheCookie
{
    // GIVEN

    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"good"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [[(id) self.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];


    // WHEN
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": @"invalid@example.com",
                                                               @"password": password
                                                               } path:path method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects(response.payload.asDictionary[@"label"], @"invalid-credentials");
    [self verifyMockLater:self.cookieStorage];


}

@end
