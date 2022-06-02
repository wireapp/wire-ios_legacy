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

#import "Tests-Swift.h"
#import "UserProfileTests.h"

@implementation UserProfileTests

- (void)setUp
{
    [super setUp];
    
    [self createSelfUserAndConversation];
}

- (void)testThatWeCanChangeUsernameAndAccentColorForSelfUser
{

    NSString *name = @"My New Name";
    ZMAccentColor accentColor = ZMAccentColorSoftPink;
    {
        // Create a UI context
        XCTAssertTrue([self login]);
        // Change the name & save
        ZMUser<ZMEditableUser> *selfUser = [ZMUser selfUserInUserSession:self.userSession];
        
        // sanity check
        XCTAssertNotEqual(selfUser.accentColorValue, accentColor);
        
        selfUser.name = name;
        selfUser.accentColorValue = accentColor;
        
        [self.userSession saveOrRollbackChanges];
        // Wait for merge ui->sync to be done
        WaitForAllGroupsToBeEmpty(0.5);
        
        
        XCTAssertEqual(selfUser.accentColorValue, accentColor);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self destroySessionManager];
    [self deleteAuthenticationCookie];
    [self createSessionManager];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // Wait for sync to be done
    XCTAssertTrue([self login]);
    
    // Check that user is updated:
    {
        // Get the self user
        ZMUser<ZMEditableUser> *selfUser = [ZMUser selfUserInUserSession:self.userSession];
        XCTAssertEqualObjects(selfUser.name, name);
        XCTAssertEqual(selfUser.accentColorValue, accentColor);
    }

    
}

- (void)testThatItNotifiesObserverWhenWeChangeAccentColorForSelfUser
{
    ZMAccentColor accentColor = ZMAccentColorSoftPink;
    
    XCTAssertTrue([self login]);

    ZMUser<ZMEditableUser> *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertNotEqual(selfUser.accentColorValue, accentColor);
    
    UserChangeObserver *observer = [[UserChangeObserver alloc] initWithUser:selfUser];
    
    // when
    selfUser.accentColorValue = accentColor;
    [self.userSession saveOrRollbackChanges];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    NSArray *notifications = observer.notifications;
    XCTAssertEqual(notifications.count, 1u);
    
    UserChangeInfo *note = notifications.firstObject;
    XCTAssertNotNil(note);
    XCTAssertTrue(note.accentColorValueChanged);
    
    XCTAssertEqual(selfUser.accentColorValue, accentColor);
}

@end


@implementation UserProfileTests (ChangeEmailAndPhoneAtSecondLogin)

- (void)testThatItCanSetsThePhoneAtTheSecondLogin
{
    // given
    NSString *phone = @"+9912312452";

    XCTAssertTrue([self login]);
    [self.mockTransportSession resetReceivedRequests];

    XCTAssertFalse(self.userSession.registeredOnThisDevice);
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.phoneNumber, @"");
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(ZMUserObserver)];
    id userObserverToken = [UserChangeInfo addObserver:userObserver forUser:selfUser inManagedObjectContext:self.userSession.managedObjectContext];
    
    id editableUserObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id editableUserObserverToken = [self.userSession.userProfile addObserver:editableUserObserver];
    
    [(id<ZMUserObserver>)[userObserver expect] userDidChange:OCMOCK_ANY]; // <- DONE: when receiving this, I know that the phone number was set
    
    // expect
    XCTestExpectation *phoneNumberVerificationCodeExpectation = [self expectationWithDescription:@"phoneNumberVerificationCodeExpectation"];
    [[[editableUserObserver expect] andDo:^(NSInvocation *inv) {
        NOT_USED(inv);
        [phoneNumberVerificationCodeExpectation fulfill];
    }] phoneNumberVerificationCodeRequestDidSucceed];
    
    // when
    [self.userSession.userProfile requestPhoneVerificationCodeWithPhoneNumber:phone]; // <- STEP 1
    
    if(![self waitForCustomExpectationsWithTimeout:0.5]) {
        XCTFail(@"phoneNumberVerificationCodeExpectation");
        return;
    }
    
    // and when
    [self.userSession.userProfile requestPhoneNumberChangeWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:phone verificationCode:self.mockTransportSession.phoneVerificationCodeForUpdatingProfile]];  // <- STEP 2
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    XCTAssertEqualObjects(selfUser.phoneNumber, phone);
    
    // after
    editableUserObserverToken = nil;
    userObserverToken = nil;
}

- (void)testThatItIsNotifiedWhenItConfirmsWithTheWrongCode
{
    // given
    NSString *phone = @"+9912312452";
    
    XCTAssertTrue([self login]);
    [self.mockTransportSession resetReceivedRequests];
    
    XCTAssertFalse(self.userSession.registeredOnThisDevice);
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.phoneNumber, @"");
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:userObserver];
    
    //expect
    [[userObserver expect] phoneNumberVerificationCodeRequestDidSucceed];
    [[userObserver expect] phoneNumberChangeDidFail:OCMOCK_ANY];
    
    // when
    [self.userSession.userProfile requestPhoneVerificationCodeWithPhoneNumber:phone];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.userSession.userProfile requestPhoneNumberChangeWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:phone verificationCode:self.mockTransportSession.invalidPhoneVerificationCode]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    
    // after
    token = nil;
}

- (void)testThatItIsNotifiedWhenItFailsToRequestAVerificationCode
{
    // given
    NSString *phone = @"+9912312452";
    
    XCTAssertTrue([self login]);
    [self.mockTransportSession resetReceivedRequests];
    
    XCTAssertFalse(self.userSession.registeredOnThisDevice);
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.phoneNumber, @"");
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:userObserver];
    
    // expect
    [[userObserver expect] phoneNumberVerificationCodeRequestDidFail:[OCMArg isNotNil]];

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/phone"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    
    
    // when
    [self.userSession.userProfile requestPhoneVerificationCodeWithPhoneNumber:phone];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);
    
    // after
    token = nil;
}


- (void)testThatItIsNotifiedWhenItFailsToRequestAVerificationCodeBecausePhoneNumberIsInUse
{
    // given
    NSString *phone = @"+9912312452";
    
    XCTAssertTrue([self login]);
    [self.mockTransportSession resetReceivedRequests];
    
    XCTAssertFalse(self.userSession.registeredOnThisDevice);
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.phoneNumber, @"");
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:userObserver];
    
    // expect
    [[userObserver expect] phoneNumberVerificationCodeRequestDidFail:[OCMArg checkWithBlock:^BOOL(NSError *error) {
        return error.code == ZMUserSessionPhoneNumberIsAlreadyRegistered && [error.domain isEqualToString:NSError.ZMUserSessionErrorDomain];
    }]];
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/phone"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label":@"key-exists"} HTTPStatus:409 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    
    
    // when
    [self.userSession.userProfile requestPhoneVerificationCodeWithPhoneNumber:phone];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);
    
    // after
    token = nil;
}


- (void)testThatItGetsInvalidPhoneNumberErrorWhenItFailsToRequestAVerificationCodeWithBadRequestResponse
{
    // given
    NSString *phone = @"+9912312452";
    
    XCTAssertTrue([self login]);
    [self.mockTransportSession resetReceivedRequests];
    
    XCTAssertFalse(self.userSession.registeredOnThisDevice);
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.phoneNumber, @"");
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:userObserver];
    
    // expect
    [[userObserver expect] phoneNumberVerificationCodeRequestDidFail:[OCMArg isNotNil]];
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/phone"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label": @"bad-request"} HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    
    
    // when
    [self.userSession.userProfile requestPhoneVerificationCodeWithPhoneNumber:phone];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);

    // after
    token = nil;
}

- (void)testThatItGetsInvalidPhoneNumberErrorWhenItFailsToRequestAVerificationCodeWithInvalidPhoneResponse
{
    // given
    NSString *phone = @"+9912312452";
    
    XCTAssertTrue([self login]);
    [self.mockTransportSession resetReceivedRequests];
    
    XCTAssertFalse(self.userSession.registeredOnThisDevice);
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.phoneNumber, @"");
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:userObserver];
    
    // expect
    [[userObserver expect] phoneNumberVerificationCodeRequestDidFail:[OCMArg isNotNil]];
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/phone"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label": @"invalid-phone"} HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    
    
    // when
    [self.userSession.userProfile requestPhoneVerificationCodeWithPhoneNumber:phone];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);
    
    // after
    token = nil;
}

- (BOOL)loginWithPhoneAndRemoveEmail
{
    NSString *phone = @"+99123456789";
    NSString *code = self.mockTransportSession.phoneVerificationCodeForLogin;
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        self.selfUser.phone = phone;
        [session whiteListPhone:phone];
    }];
    
    BOOL success = [self loginWithCredentials:[ZMPhoneCredentials credentialsWithPhoneNumber:phone verificationCode:code] ignoreAuthenticationFailures:NO];
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        NOT_USED(session);
        self.selfUser.email = nil;
        self.selfUser.password = nil;
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    return success;
}

- (void)disable_testThatItCanSetEmailAndPassword
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssertTrue([self loginWithPhoneAndRemoveEmail]);
    ZMEmailCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);

    // expect
    id editUserObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id editUserObserverToken = [self.userSession.userProfile addObserver:editUserObserver];
    [[editUserObserver expect] didSendVerificationEmail];
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(ZMUserObserver)];
    id userObserverToken = [UserChangeInfo addObserver:userObserver forUser:selfUser inManagedObjectContext:self.userSession.managedObjectContext];
    [(id<ZMUserObserver>)[userObserver expect] userDidChange:OCMOCK_ANY]; // <- DONE: when receiving this, I know that the email was set

    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil]; // <- STEP 1
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        // simulate user click on email
        NOT_USED(session);
        self.selfUser.email = email;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    XCTAssertEqualObjects(selfUser.emailAddress, email);
    
    // after
    editUserObserverToken = nil;
    userObserverToken = nil;
}

- (void)testThatItNotifiesWhenFailingToSetThePasswordForNetworkError
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssertTrue([self loginWithPhoneAndRemoveEmail]);
    ZMEmailCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:userObserver];
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/password"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[userObserver expect] passwordUpdateRequestDidFail];
    
    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);
    
    // after
    token = nil;
}

- (void)disable_testThatItSilentlyIgnoreWhenFailingToSetThePasswordBecauseThePasswordWasAlreadyThere
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssertTrue([self loginWithPhoneAndRemoveEmail]);
    ZMEmailCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id editingObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id editingToken = [self.userSession.userProfile addObserver:editingObserver];
    id userObserver = [OCMockObject mockForProtocol:@protocol(ZMUserObserver)];
    id userObserverToken = [UserChangeInfo addObserver:userObserver forUser:selfUser inManagedObjectContext:self.userSession.managedObjectContext];
    [(id<ZMUserObserver>)[userObserver expect] userDidChange:OCMOCK_ANY]; // when receiving this, I know that the email was set
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/password"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label":@"invalid-credentials"} HTTPStatus:403 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[editingObserver expect] didSendVerificationEmail];
    [[editingObserver expect] passwordUpdateRequestDidFail];
    
    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(5);
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        // simulate user click on email
        NOT_USED(session);
        self.selfUser.email = email;
    }];
    WaitForAllGroupsToBeEmpty(5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    XCTAssertEqualObjects(selfUser.emailAddress, email);
    
    // after
    editingToken = nil;
    userObserverToken = nil;
}

- (void)testThatItNotifiesWhenFailingToSetTheEmailBecauseOfGenericError
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssertTrue([self loginWithPhoneAndRemoveEmail]);
    ZMEmailCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id editiongObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:editiongObserver];
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/email"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[editiongObserver expect] emailUpdateDidFail:[NSError userSessionErrorWithErrorCode:ZMUserSessionUnknownError userInfo:nil]];
    
    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    
    // after
    token = nil;
    
}

- (void)disable_testThatItNotifiesWhenFailingToSetTheEmailBecauseOfInvalidEmail
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssertTrue([self loginWithPhoneAndRemoveEmail]);
    ZMEmailCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id editiongObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:editiongObserver];
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/email"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label":@"invalid-email"} HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[editiongObserver expect] emailUpdateDidFail:[NSError userSessionErrorWithErrorCode:ZMUserSessionInvalidEmail userInfo:nil]];
    
    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    
    // after
    token = nil;
    
}

- (void)disable_testThatItNotifiesWhenFailingToSetTheEmailBecauseOfEmailAlreadyInUse
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssertTrue([self loginWithPhoneAndRemoveEmail]);
    ZMEmailCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id editiongObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:editiongObserver];
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/email"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label":@"key-exists"} HTTPStatus:409 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[editiongObserver expect] emailUpdateDidFail:[NSError userSessionErrorWithErrorCode:ZMUserSessionEmailIsAlreadyRegistered userInfo:nil]];
    
    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    
    // after
    token = nil;
    
}

@end

