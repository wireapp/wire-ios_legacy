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

@import WireDataModel;

#import "MessagingTest.h"
#import "ZMLoginTranscoder+Internal.h"
#import "ZMCredentials.h"
#import "ZMAuthenticationStatus.h"
#import "NSError+ZMUserSession.h"
#import "ZMUserSessionRegistrationNotification.h"
#import "ZMClientRegistrationStatus.h"
#import "ZMAuthenticationStatus.h"
#import "ZMAuthenticationStatus_Internal.h"
#import "Tests-Swift.h"


@import WireUtilities;

static NSString * const TestEmail = @"bar@example.com";
static NSString * const TestPassword = @"super-secure-password-sijovhjs987y";
static NSString * const TestEmailVerificationCode = @"123456";

static NSString * const TestPhoneNumber = @"+7123456789";
static NSString * const TestPhoneCode = @"123456";

extern NSTimeInterval DefaultPendingValidationLoginAttemptInterval;

@interface TestTimedSingleRequest : NSObject

@property (nonatomic) NSTimeInterval timeInterval;
- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion;

@end



@implementation TestTimedSingleRequest

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion {
    return nil;
}

@end

@interface ZMLoginTranscoderTests : MessagingTest

@property (nonatomic) DispatchGroupQueue *groupQueue;
@property (nonatomic) MockAuthenticationStatusDelegate *mockAuthenticationStatusDelegate;
@property (nonatomic) ZMLoginTranscoder *sut;
@property (nonatomic) ZMAuthenticationStatus *authenticationStatus;
@property (nonatomic) id mockClientRegistrationStatus;
@property (nonatomic) id mockApplicationStatusDirectory;

@property (nonatomic) ZMCredentials *testEmailCredentials;
@property (nonatomic) ZMCredentials *testEmailCredentialsWithVerificationCode;
@property (nonatomic) ZMCredentials *testPhoneNumberCredentials;
@property (nonatomic) NSTimeInterval originalLoginTimerInterval;
@property (nonatomic) id mockLocale;
@property (nonatomic) MockUserInfoParser *mockUserInfoParser;

@end

@implementation ZMLoginTranscoderTests


- (void)setUp {
    [super setUp];

    self.mockUserInfoParser = [[MockUserInfoParser alloc] init];

    self.groupQueue = [[DispatchGroupQueue alloc] initWithQueue:dispatch_get_main_queue()];
    self.mockAuthenticationStatusDelegate = [[MockAuthenticationStatusDelegate alloc] init];
    self.originalLoginTimerInterval = DefaultPendingValidationLoginAttemptInterval;

    self.authenticationStatus = [[ZMAuthenticationStatus alloc] initWithDelegate:self.mockAuthenticationStatusDelegate
                                                                      groupQueue:self.groupQueue
                                                                  userInfoParser:self.mockUserInfoParser];

    self.mockClientRegistrationStatus = [OCMockObject niceMockForClass:[ZMClientRegistrationStatus class]];

    self.mockLocale = [OCMockObject niceMockForClass:[NSLocale class]];
    [[[self.mockLocale stub] andReturn:[NSLocale localeWithLocaleIdentifier:@"fr_FR"]] currentLocale];


    self.sut = [[ZMLoginTranscoder alloc] initWithGroupQueue:self.groupQueue
                                        authenticationStatus:self.authenticationStatus];

    self.testEmailCredentials = [ZMEmailCredentials credentialsWithEmail:TestEmail password:TestPassword];
    self.testEmailCredentialsWithVerificationCode = [ZMEmailCredentials credentialsWithEmail:TestEmail password:TestPassword emailVerificationCode:TestEmailVerificationCode];

    self.testPhoneNumberCredentials = [ZMPhoneCredentials credentialsWithPhoneNumber:TestPhoneNumber verificationCode:TestPhoneCode];
}

- (void)tearDown {
    [self.sut tearDown];
    self.groupQueue = nil;
    self.sut = nil;
    self.authenticationStatus = nil;
    self.mockClientRegistrationStatus = nil;
    self.mockLocale = nil;
    self.mockUserInfoParser = nil;
    DefaultPendingValidationLoginAttemptInterval = self.originalLoginTimerInterval;
    [super tearDown];
}

- (void)testThatItCreatesTheTimedRequestSyncWithZeroDelayInDefaultConstructor
{
    // given
    ZMLoginTranscoder *sut = [[ZMLoginTranscoder alloc] initWithGroupQueue:self.groupQueue authenticationStatus:self.authenticationStatus];

    // then
    XCTAssertNotNil(sut.timedDownstreamSync);
    XCTAssertEqualObjects(sut.timedDownstreamSync.groupQueue, self.groupQueue);
    XCTAssertEqualObjects(sut.timedDownstreamSync.transcoder, sut);
    XCTAssertEqual(sut.timedDownstreamSync.timeInterval, 0);

    // after
    [sut tearDown];
}

- (void)expectAuthenticationSucceedAfter:(void(^)(void))block;
{
    id mockAuthStatus = [OCMockObject partialMockForObject:self.authenticationStatus];
    [[[mockAuthStatus expect] andForwardToRealObject] loginSucceededWithResponse:OCMOCK_ANY];

    // when
    block();

    //then
    [mockAuthStatus verify];
}

- (void)expectAuthenticationFailedWithError:(ZMUserSessionErrorCode)code after:(void(^)(void))block;
{
    // when
    block();
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidSucceedEvents, 0);
    XCTAssertEqual(self.mockAuthenticationStatusDelegate.authenticationDidFailEvents.count, 1);
    XCTAssertEqual((ZMUserSessionErrorCode)self.mockAuthenticationStatusDelegate.authenticationDidFailEvents[0].code,code);
}

- (void)expectRegistrationSucceedAfter:(void(^)(void))block;
{
    //expect
    __block BOOL notified = NO;
    id token = [ZMUserSessionRegistrationNotification addObserverInContext:self.authenticationStatus withBlock:^(ZMUserSessionRegistrationNotificationType event, NSError *error) {
        NOT_USED(event);
        XCTAssertNil(error);
        notified = YES;
    }];

    // when
    block();

    //then
    XCTAssert(notified);
    token = nil;
}

- (void)expectRegistrationFailedWithError:(ZMUserSessionErrorCode)code after:(void(^)(void))block;
{
    //expect
    __block BOOL notified = NO;
    id token = [ZMUserSessionRegistrationNotification addObserverInContext:self.authenticationStatus withBlock:^(ZMUserSessionRegistrationNotificationType event, NSError *error) {
        NOT_USED(event);
        XCTAssertNotNil(error);
        XCTAssertEqual((ZMUserSessionErrorCode)error.code, code);
        notified = YES;
    }];

    // when
    block();

    //then
    XCTAssert(notified);
    token = nil;
}

@end

@implementation ZMLoginTranscoderTests (Login)

- (void)testThatItReturnsNoLoginRequestWhenTheUserSessionHasNoCredentials
{
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // then
    XCTAssertNil(request);
}


- (void)testThatItGeneratesALoginRequestWhenTheUserSessionHasCredentialsWithEmailAndWeAreNotLoggedIn
{
    // given
    NSDictionary *payload = @{@"email": self.testEmailCredentials.email,
                              @"password": self.testEmailCredentials.password,
                              @"label": CookieLabel.current.value};

    ZMTransportRequest *expectedRequest = [[ZMTransportRequest alloc] initWithPath:ZMLoginURL
                                                                            method:ZMMethodPOST
                                                                           payload:payload
                                                                    authentication:ZMTransportRequestAuthCreatesCookieAndAccessToken
                                                                        apiVersion:0];

    [self.authenticationStatus prepareForLoginWithCredentials:self.testEmailCredentials];

    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // then
    XCTAssertEqualObjects(request, expectedRequest);
}

- (void)testThatItGeneratesALoginRequestWhenTheUserSessionHasCredentialsWithPhoneNumberAndWeAreNotLoggedIn
{
    // given
    NSDictionary *payload = @{@"phone": self.testPhoneNumberCredentials.phoneNumber,
                              @"code": self.testPhoneNumberCredentials.phoneNumberVerificationCode,
                              @"label": CookieLabel.current.value};
    ZMTransportRequest *expectedRequest = [[ZMTransportRequest alloc] initWithPath:ZMLoginURL
                                                                            method:ZMMethodPOST
                                                                           payload:payload
                                                                    authentication:ZMTransportRequestAuthCreatesCookieAndAccessToken
                                                                        apiVersion:0];

    [self.authenticationStatus prepareForLoginWithCredentials:self.testPhoneNumberCredentials];

    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // then
    XCTAssertEqualObjects(request, expectedRequest);
}

- (void)testThatItGeneratesALoginRequestWhenTheUserSessionHasCredentialsWithEmailVerificationCodeAndWeAreNotLoggedIn
{
    // GIVEN
    NSDictionary *payload = @{@"email": self.testEmailCredentialsWithVerificationCode.email,
                              @"password": self.testEmailCredentialsWithVerificationCode.password,
                              @"verification_code": self.testEmailCredentialsWithVerificationCode.emailVerificationCode,
                              @"label": CookieLabel.current.value};

    ZMTransportRequest *expectedRequest = [[ZMTransportRequest alloc] initWithPath:ZMLoginURL
                                                                            method:ZMMethodPOST
                                                                           payload:payload
                                                                    authentication:ZMTransportRequestAuthCreatesCookieAndAccessToken
                                                                        apiVersion:0];

    [self.authenticationStatus prepareForLoginWithCredentials:self.testEmailCredentialsWithVerificationCode];

    // WHEN
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // THEN
    XCTAssertEqualObjects(request, expectedRequest);
}

- (void)testThatItDoesNotGenerateALoginRequestWhenTheUserSessionHasNoCredentials
{
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNil(request);
}

- (void)testThatItDoesNotGenerateALoginRequestWhenTheUserSessionIsLoggedIn
{
    // given
    [self.authenticationStatus setAuthenticationCookieData:[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];

    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNil(request);
}


@end


@implementation  ZMLoginTranscoderTests (AuthenticationDelegate)

-(void)testThatItCallsAuthenticationSucceededOnLoginSucceedsWithEmail
{
    // given
    NSDictionary *content = @{@"access_token": @"61184561417968870ce708ed0c319206914bc56db444d01227a63f9b9849045f.1.1401213378.a.3bc5750a-b965-40f8-aff2-831e9b5ac2e9.846754296078244309",
                              @"expires_in": @604800,
                              @"token_type": @"Bearer"
    };
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678"]];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:200 transportSessionError:nil apiVersion:0];

    // when

    [self expectAuthenticationSucceedAfter:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

-(void)testThatItCallsAuthenticationSucceededOnLoginSucceedsWithPhoneNumber
{
    // given
    NSDictionary *content = @{@"access_token": @"61184561417968870ce708ed0c319206914bc56db444d01227a63f9b9849045f.1.1401213378.a.3bc5750a-b965-40f8-aff2-831e9b5ac2e9.846754296078244309",
                              @"expires_in": @604800,
                              @"token_type": @"Bearer"
    };
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:@"+49123456789" verificationCode:@"123456"]];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:200 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationSucceedAfter:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

-(void)testThatItCallsAuthenticationFailOnInvalidEmailCredentialsIfNotDuplicatedEmailRegistered
{
    // given
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Invalid login credentials",
                              @"label":@"invalid-credentials"};
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678"]];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationFailedWithError:ZMUserSessionInvalidCredentials after:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

-(void)testThatItCallsAuthenticationFailOnEmailVerificationCodeNeeded
{
    // GIVEN
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Code Authentication Required",
                              @"label":@"code-authentication-required"};
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678"]];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // WHEN
    [self expectAuthenticationFailedWithError:ZMUserSessionAccountIsPendingVerification after:^{
        [[self.sut nextRequestForAPIVersion:0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

-(void)testThatItCallsAuthenticationFailOnInvalidEmailVerificationCode
{
    // GIVEN
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Code Authentication Failed",
                              @"label":@"code-authentication-failed"};
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678" emailVerificationCode: @"1234567"]];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // WHEN
    [self expectAuthenticationFailedWithError:ZMUserSessionInvalidEmailVerificationCode after:^{
        [[self.sut nextRequestForAPIVersion:0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

-(void)testThatItCallsRegistrationFailOnInvalidPhoneNumberCredentialsIfNotDuplicatedPhoneNumberRegistered
{
    // given
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Invalid login credentials",
                              @"label":@"invalid-credentials"};

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    [self.authenticationStatus prepareForLoginWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:@"+4912345678" verificationCode:@"123456"]];

    // when
    [self expectAuthenticationFailedWithError:ZMUserSessionInvalidCredentials after:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

-(void)testThatItCallsAuthenticationFailOnErrorResponseWithoutPayload
{
    // given
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:@"+4912345678" verificationCode:@"123456"]];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:nil HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationFailedWithError:ZMUserSessionUnknownError after:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

-(void)testThatItCallsAuthenticationFailOnPendingActivation
{
    // given
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Account pending activation",
                              @"label":@"pending-activation"};
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678"]];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationFailedWithError:ZMUserSessionAccountIsPendingActivation after:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

- (void)testThatItCallsAuthenticationFailOnPhoneLoginWithSuspendedAccount
{
    // given
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Account suspended.",
                              @"label":@"suspended"};
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:@"+4912345678" verificationCode:@"123456"]];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationFailedWithError:ZMUserSessionAccountSuspended after:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}


- (void)testThatItCallsAuthenticationFailOnEmailLoginWithSuspendedAccount
{
    // given
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Account suspended.",
                              @"label":@"suspended"};
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678"]];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationFailedWithError:ZMUserSessionAccountSuspended after:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

- (void) testThatItCallsAccountPendingVerification
{
    //GIVEN
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Code Authentication Required",
                              @"label":@"code-authentication-required"};
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678"]];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // WHEN
    [self expectAuthenticationFailedWithError:ZMUserSessionAccountIsPendingVerification after:^{
        [[self.sut nextRequestForAPIVersion:0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];

}

-(void)testThatItInvalidatesTheCredentialsOnLoginErrorWhenLoggingWithEmail
{
    // given
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Invalid login credentials",
                              @"label":@"invalid-credentials"};

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678"]];

    // when
    [self expectAuthenticationFailedWithError:ZMUserSessionInvalidCredentials after:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];

    // then
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseUnauthenticated);
    XCTAssertNil(self.authenticationStatus.loginCredentials);

}

-(void)testThatItInvalidatesTheCredentialsOnLoginErrorWhenLoggingWithPhoneNumber
{
    // given
    NSDictionary *content = @{@"code":@403,
                              @"message":@"Invalid login credentials",
                              @"label":@"invalid-credentials"};
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:@"+49123456789" verificationCode:@"12345678"]];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:403 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationFailedWithError:ZMUserSessionInvalidCredentials after:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }];

    // then
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseUnauthenticated);
    XCTAssertNil(self.authenticationStatus.loginCredentials);
}

- (void)testThatItDoesNotDeleteCredentialsButSwitchesToStateAuthenticatedOnLoginSucceedsWithPhone
{
    // given
    NSDictionary *content = @{@"access_token": @"61184561417968870ce708ed0c319206914bc56db444d01227a63f9b9849045f.1.1401213378.a.3bc5750a-b965-40f8-aff2-831e9b5ac2e9.846754296078244309",
                              @"expires_in": @604800,
                              @"token_type": @"Bearer"
    };
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:@"+49123456789" verificationCode:@"12345678"]];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:200 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationSucceedAfter:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
        [self.authenticationStatus continueAfterBackupImportStep];
        [self.authenticationStatus setAuthenticationCookieData:[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
        WaitForAllGroupsToBeEmpty(0.5);
    }];

    // then
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseAuthenticated);
    XCTAssertNotNil(self.authenticationStatus.loginCredentials);

}

- (void)testThatItDoesNotDeleteCredentialsButSwitchesToStateAuthenticatedOnLoginSucceedsWithEmail
{
    // given
    NSDictionary *content = @{@"access_token": @"61184561417968870ce708ed0c319206914bc56db444d01227a63f9b9849045f.1.1401213378.a.3bc5750a-b965-40f8-aff2-831e9b5ac2e9.846754296078244309",
                              @"expires_in": @604800,
                              @"token_type": @"Bearer"
    };
    [self.authenticationStatus prepareForLoginWithCredentials:[ZMEmailCredentials credentialsWithEmail:@"foo@example.com" password:@"12345678"]];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:content HTTPStatus:200 transportSessionError:nil apiVersion:0];

    // when
    [self expectAuthenticationSucceedAfter:^{
        [[self.sut nextRequestForAPIVersion:APIVersionV0] completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
        [self.authenticationStatus continueAfterBackupImportStep];
        [self.authenticationStatus setAuthenticationCookieData:[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
        WaitForAllGroupsToBeEmpty(0.5);
    }];

    // then
    XCTAssertEqual(self.authenticationStatus.currentPhase, ZMAuthenticationPhaseAuthenticated);
    XCTAssertNotNil(self.authenticationStatus.loginCredentials);

}

@end
