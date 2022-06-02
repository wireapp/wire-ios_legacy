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
@import WireSyncEngine;
@import WireUtilities;

#import "MessagingTest.h"
#import "ZMLoginCodeRequestTranscoder.h"
#import "ZMAuthenticationStatus.h"
#import "ZMCredentials.h"
#import "ZMAuthenticationStatus.h"
#import "Tests-Swift.h"

@interface ZMLoginCodeRequestTranscoderTests : MessagingTest

@property (nonatomic) ZMLoginCodeRequestTranscoder *sut;
@property (nonatomic) ZMAuthenticationStatus *authenticationStatus;
@property (nonatomic) MockAuthenticationStatusDelegate *mockAuthenticationStatusDelegate;
@property (nonatomic) MockUserInfoParser *userInfoParser;

@end

@implementation ZMLoginCodeRequestTranscoderTests

- (void)setUp {
    [super setUp];

    self.mockAuthenticationStatusDelegate = [[MockAuthenticationStatusDelegate alloc] init];
    self.userInfoParser = [[MockUserInfoParser alloc] init];
    DispatchGroupQueue *groupQueue = [[DispatchGroupQueue alloc] initWithQueue:dispatch_get_main_queue()];
    self.authenticationStatus = [[ZMAuthenticationStatus alloc] initWithDelegate:self.mockAuthenticationStatusDelegate
                                                                      groupQueue:groupQueue
                                                                  userInfoParser:self.userInfoParser];
    self.sut = [[ZMLoginCodeRequestTranscoder alloc] initWithGroupQueue:groupQueue authenticationStatus:self.authenticationStatus];
}

- (void)tearDown {
    self.mockAuthenticationStatusDelegate = nil;
    self.authenticationStatus = nil;
    self.sut = nil;
    self.userInfoParser = nil;
    [super tearDown];
}

- (void)testThatItReturnsNoRequestWhenThereAreNoCredentials
{
    ZMTransportRequest *request;
    request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertNil(request);
}

- (void)testThatItReturnsExpectedRequestWhenThereIsPhoneNumber
{
    NSString *phoneNumber = @"+7123456789";
    [self.authenticationStatus prepareForRequestingPhoneVerificationCodeForLogin:phoneNumber];

    ZMTransportRequest *expectedRequest = [[ZMTransportRequest alloc] initWithPath:@"/login/send" method:ZMMethodPOST payload:@{@"phone": phoneNumber} authentication:ZMTransportRequestAuthNone apiVersion:0];
    
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertEqualObjects(request, expectedRequest);
}

-(void)testThatItReturnsExpectedRequestWhenThereIsEmailThatNeedsVerificationCode
{
    NSString *email = @"test@wire.com";
    NSString *loginAction = @"login";
    [self.authenticationStatus prepareForRequestingEmailVerificationCodeForLogin:email];

    ZMTransportRequest *expectedRequest = [[ZMTransportRequest alloc] initWithPath:@"/verification-code/send"
                                                                            method:ZMMethodPOST
                                                                           payload:@{@"email": email, @"action": loginAction}
                                                                    authentication:ZMTransportRequestAuthNone
                                                                        apiVersion:APIVersionV0];

    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertEqualObjects(request, expectedRequest);
}

- (void)testThatItInformTheAuthCenterThatTheCodeWasReceived
{
    // given
    NSString *phoneNumber = @"+7123456789";
    [self.authenticationStatus prepareForRequestingPhoneVerificationCodeForLogin:phoneNumber];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // when
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion]];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseUnauthenticated);
}

- (void)testThatItInformTheAuthCenterThatTheCodeRequestFailed
{
    // given
    NSString *phoneNumber = @"+7123456789";
    [self.authenticationStatus prepareForRequestingPhoneVerificationCodeForLogin:phoneNumber];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // when
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:nil
                                                                HTTPStatus:400
                                                     transportSessionError:nil
                                                                apiVersion:request.apiVersion]];
    WaitForAllGroupsToBeEmpty(0.2);

    // then
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents.count, 1);
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].code,
                   (long) ZMUserSessionUnknownError);
    XCTAssertEqualObjects(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].domain,
                          NSError.ZMUserSessionErrorDomain);
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseUnauthenticated);
}


- (void)testThatItInformTheAuthCenterThatTheCodeRequestFailedBecauseOfInvalidPhoneNumber
{
    // given
    NSString *phoneNumber = @"+7123456789";
    [self.authenticationStatus prepareForRequestingPhoneVerificationCodeForLogin:phoneNumber];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // when
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:@{@"label":@"invalid-phone"} HTTPStatus:400 transportSessionError:nil apiVersion:request.apiVersion]];
    WaitForAllGroupsToBeEmpty(0.2);

    // then
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents.count, 1);
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].code,
                   (long) ZMUserSessionInvalidPhoneNumber);
    XCTAssertEqualObjects(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].domain,
                          NSError.ZMUserSessionErrorDomain);
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseUnauthenticated);
}


- (void)testThatItInformTheAuthCenterThatTheCodeRequestFailedBecauseOfPendingLogin
{
    // given
    NSString *phoneNumber = @"+7123456789";
    [self.authenticationStatus prepareForRequestingPhoneVerificationCodeForLogin:phoneNumber];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // when
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:@{@"label":@"pending-login"} HTTPStatus:403 transportSessionError:nil apiVersion:request.apiVersion]];
    WaitForAllGroupsToBeEmpty(0.2);

    // then
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents.count, 1);
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].code,
                   (long) ZMUserSessionCodeRequestIsAlreadyPending);
    XCTAssertEqualObjects(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].domain,
                          NSError.ZMUserSessionErrorDomain);
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseUnauthenticated);
}


- (void)testThatItInformTheAuthCenterThatTheCodeRequestFailedBecauseThePhoneIsUnauthorized
{
    // given
    NSString *phoneNumber = @"+7123456789";
    [self.authenticationStatus prepareForRequestingPhoneVerificationCodeForLogin:phoneNumber];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // when
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:@{@"label":@"unauthorized"} HTTPStatus:403 transportSessionError:nil apiVersion:request.apiVersion]];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents.count, 1);
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].code,
                   (long) ZMUserSessionInvalidPhoneNumber);
    XCTAssertEqualObjects(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].domain,
                          NSError.ZMUserSessionErrorDomain);
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseUnauthenticated);
}

@end
