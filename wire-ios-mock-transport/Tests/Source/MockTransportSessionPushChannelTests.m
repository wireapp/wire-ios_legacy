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
@import WireMockTransport;
#import "MockTransportSessionTests.h"

@interface MockTransportSessionPushChannelTests : MockTransportSessionTests
@end

@implementation MockTransportSessionPushChannelTests

- (void)testThatAfterSimulatePushChannelClosedTheDelegateIsInvoked
{
    // GIVEN
    [self.sut.mockedTransportSession configurePushChannelWithConsumer:self groupQueue:self.fakeSyncContext];
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session simulatePushChannelClosed];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelDidCloseCount, 1u);
}

- (void)testThatAfterSimulatePushChannelOpenedTheDelegateIsInvoked
{
    // GIVEN
    [self.sut.mockedTransportSession configurePushChannelWithConsumer:self groupQueue:self.fakeSyncContext];
    __block NSDictionary *payload;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"Me Myself"];
        selfUser.email = @"me@example.com";
        selfUser.password = @"123456";
        
        payload = @{@"email" : selfUser.email, @"password" : selfUser.password};
    }];
    [self responseForPayload:payload path:@"/login" method:ZMMethodPOST apiVersion:0]; // this will simulate the user logging in
    
    // WHEN
    [self.sut.mockedTransportSession.pushChannel setKeepOpen:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelDidOpenCount, 1u);
}

- (void)testThatNoPushChannelEventIsSentBeforeThePushChannelIsOpened
{
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Old self username"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> ZM_UNUSED session)
    {
        selfUser.name = @"New";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
}

- (void)testThatPushChannelEventsAreSentWhenThePushChannelIsOpened
{
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Old self username"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
    
    // WHEN
    [self createAndOpenPushChannelAndCreateSelfUser:NO];
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> ZM_UNUSED session) {
        selfUser.name = @"New";
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
}

- (void)testThatNoPushChannelEventAreSentAfterThePushChannelIsClosed
{
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Old self username"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
    
    // WHEN
    [self createAndOpenPushChannelAndCreateSelfUser:NO];
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session simulatePushChannelClosed];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> ZM_UNUSED session) {
        selfUser.name = @"New";
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
}

- (void)testThatWeReceiveAPushEventWhenChangingSelfUserName
{
    // GIVEN
    NSString *newName = @"NEWNEWNEW";
    [self createAndOpenPushChannel];
    
    __block MockUser *selfUser;
    __block NSDictionary *expectedUserPayload;
    __block NSString *selfUserID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        selfUser = self.sut.selfUser;
        selfUserID = selfUser.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
    
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> ZM_UNUSED session) {
        selfUser.name = newName;
        expectedUserPayload = @{
                                @"id" : selfUserID,
                                @"name" : newName
                                };
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
    TestPushChannelEvent *nameEvent = self.pushChannelReceivedEvents.firstObject;
    XCTAssertEqual(nameEvent.type, ZMUpdateEventTypeUserUpdate);
    XCTAssertEqualObjects(nameEvent.payload.asDictionary[@"user"], expectedUserPayload);
}

- (void)testThatWeReceiveAPushEventWhenChangingSelfProfile
{
    // GIVEN
    NSString *newValue = @"NEWNEWNEW";
    [self createAndOpenPushChannel];
    
    __block MockUser *selfUser;
    __block NSDictionary *expectedUserPayload;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        selfUser = self.sut.selfUser;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
    
    
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        selfUser.email = [newValue stringByAppendingString:@"-email"];
        selfUser.phone = [newValue stringByAppendingString:@"-phone"];
        selfUser.accentID = 5567;
        expectedUserPayload = @{
                                @"id" : selfUser.identifier,
                                @"email" : selfUser.email,
                                @"phone" : selfUser.phone,
                                @"accent_id" : @(selfUser.accentID)
                                };
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
    TestPushChannelEvent *nameEvent = self.pushChannelReceivedEvents.firstObject;
    XCTAssertEqual(nameEvent.type, ZMUpdateEventTypeUserUpdate);
    XCTAssertEqualObjects(nameEvent.payload.asDictionary[@"user"], expectedUserPayload);
}

- (void)testThatWeReceiveAPushEventWhenChangingSelfProfilePictureAssetsV3
{
    // GIVEN
    [self createAndOpenPushChannel];
    
    __block MockUser *selfUser;
    __block NSDictionary *expectedUserPayload;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        selfUser = self.sut.selfUser;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        selfUser.previewProfileAssetIdentifier = @"preview-id";
        selfUser.completeProfileAssetIdentifier = @"complete-id";
        expectedUserPayload = @{
                                @"id" : selfUser.identifier,
                                @"assets" :
                                    @[
                                         @{ @"size" : @"preview", @"type" : @"image", @"key" : selfUser.previewProfileAssetIdentifier },
                                         @{ @"size" : @"complete", @"type" : @"image", @"key" : selfUser.completeProfileAssetIdentifier }
                                    ]
                                 };
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
    TestPushChannelEvent *nameEvent = self.pushChannelReceivedEvents.firstObject;
    XCTAssertEqual(nameEvent.type, ZMUpdateEventTypeUserUpdate);
    XCTAssertEqualObjects(nameEvent.payload.asDictionary[@"user"], expectedUserPayload);
}

- (void)testThatWeReceiveAPushEventWhenCreatingAConnection
{
    // GIVEN
    NSString *message = @"How're you doin'?";
    [self createAndOpenPushChannel];
    
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    __block id<ZMTransportData> expectedConnectionPayload;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = self.sut.selfUser;
        otherUser = [session insertUserWithName:@"Mr. Other User"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
    
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockConnection *connection = [session insertConnectionWithSelfUser:selfUser toUser:otherUser];
        connection.message = message;
        expectedConnectionPayload = connection.transportData;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
    TestPushChannelEvent *connectEvent = self.pushChannelReceivedEvents.firstObject;
    XCTAssertEqual(connectEvent.type, ZMUpdateEventTypeUserConnection);
    XCTAssertEqualObjects(connectEvent.payload.asDictionary[@"connection"], expectedConnectionPayload);
}

- (void)testThatWeReceiveAPushEventWhenChangingAConnection
{
    // GIVEN
    NSString *message = @"How're you doin'?";
    [self createAndOpenPushChannel];
    
    __block MockConnection *connection;
    __block id<ZMTransportData> expectedConnectionPayload;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = self.sut.selfUser;
        MockUser *otherUser = [session insertUserWithName:@"Mr. Other User"];
        connection = [session insertConnectionWithSelfUser:selfUser toUser:otherUser];
        connection.message = message;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.pushChannelReceivedEvents removeAllObjects];
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        connection.status = @"blocked";
        expectedConnectionPayload = connection.transportData;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
    TestPushChannelEvent *connectEvent = self.pushChannelReceivedEvents.firstObject;
    XCTAssertEqual(connectEvent.type, ZMUpdateEventTypeUserConnection);
    XCTAssertEqualObjects(connectEvent.payload.asDictionary[@"connection"], expectedConnectionPayload);
}

- (void)testThatWeReceivePushEventsWhenCreatingAConversationAndInsertingMessages
{
    // GIVEN
    [self createAndOpenPushChannel];
    __block id<ZMTransportData> conversationPayload;
    __block id<ZMTransportData> event1Payload;
    __block id<ZMTransportData> event2Payload;
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = self.sut.selfUser;
        MockUser *user1 = [session insertUserWithName:@"Name1 213"];
        MockUser *user2 = [session insertUserWithName:@"Name2 866"];
        
        
        MockConversation *conversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1,user2]];
        NSData *data1 = [@"Text 1" dataUsingEncoding:NSUTF8StringEncoding];
        NSData *data2 = [@"Text 2" dataUsingEncoding:NSUTF8StringEncoding];
        MockEvent *event1 = [conversation insertOTRMessageFromClient:user1.clients.anyObject toClient:user2.clients.anyObject data:data1];
        MockEvent *event2 = [conversation insertOTRMessageFromClient:user1.clients.anyObject toClient:user2.clients.anyObject data:data2];
        
        event1Payload = event1.data;
        event2Payload = event2.data;
        conversationPayload = conversation.transportData;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 4u);
    TestPushChannelEvent *createConversationEvent = [self popEventMatchingWithBlock:^BOOL(TestPushChannelEvent *event) {
        return event.type == ZMUpdateEventTypeConversationCreate;
    }];
    TestPushChannelEvent *memberJoinEvent = [self popEventMatchingWithBlock:^BOOL(TestPushChannelEvent *event) {
        return event.type == ZMUpdateEventTypeConversationMemberJoin;
    }];
    TestPushChannelEvent *textEvent1 = [self popEventMatchingWithBlock:^BOOL(TestPushChannelEvent *event) {
        return ((event.type == ZMUpdateEventTypeConversationOtrMessageAdd) &&
                [event.payload.asDictionary[@"data"] isEqual:event1Payload]);
    }];
    TestPushChannelEvent *textEvent2 = [self popEventMatchingWithBlock:^BOOL(TestPushChannelEvent *event) {
        return ((event.type == ZMUpdateEventTypeConversationOtrMessageAdd) &&
                [event.payload.asDictionary[@"data"] isEqual:event2Payload]);
    }];
    XCTAssertNotNil(createConversationEvent);
    XCTAssertEqualObjects(createConversationEvent.payload.asDictionary[@"data"], conversationPayload);
    XCTAssertNotNil(memberJoinEvent);
    XCTAssertNotNil(textEvent1);
    XCTAssertNotNil(textEvent2);
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 0u);
}

- (void)testThatWeReceiveAPushEventWhenChangingAConversationName
{
    // GIVEN
    NSString *name = @"So much name";
    [self createAndOpenPushChannel];
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = self.sut.selfUser;
        MockUser *user1 = [session insertUserWithName:@"Name1 213"];
        MockUser *user2 = [session insertUserWithName:@"Name2 866"];
        conversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1,user2]];
        [conversation changeNameByUser:self.sut.selfUser name:@"Something boring"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.pushChannelReceivedEvents removeAllObjects];
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        [conversation changeNameByUser:self.sut.selfUser name:name];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
    TestPushChannelEvent *nameChangeName = self.pushChannelReceivedEvents.firstObject;
    
    XCTAssertEqual(nameChangeName.type, ZMUpdateEventTypeConversationRename);
}

- (void)testThatWeReceiveAPushEventWhenCreatingAConversation
{
    // GIVEN
    [self createAndOpenPushChannel];
    __block MockConversation *conversation;
    __block id<ZMTransportData> expectedData;
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = self.sut.selfUser;
        MockUser *user1 = [session insertUserWithName:@"Name1 213"];
        MockUser *user2 = [session insertUserWithName:@"Name2 866"];
        conversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1,user2]];
        [conversation changeNameByUser:self.sut.selfUser name:@"Trolls"];
        
        expectedData = conversation.transportData;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    // THEN
    XCTAssertGreaterThanOrEqual(self.pushChannelReceivedEvents.count, 1u);
    NSUInteger index = [self.pushChannelReceivedEvents indexOfObjectPassingTest:^BOOL(TestPushChannelEvent *event, NSUInteger idx ZM_UNUSED, BOOL *stop ZM_UNUSED) {
        return event.type == ZMUpdateEventTypeConversationCreate;
    }];
    XCTAssertTrue(index != NSNotFound);
    if(index != NSNotFound) {
        TestPushChannelEvent *event = self.pushChannelReceivedEvents[index];
        XCTAssertEqualObjects(expectedData, event.payload.asDictionary[@"data"]);
    }
}

- (void)testThatWeReceiveAPushEventWhenAddingAParticipantToAConversation
{
    // GIVEN
    [self createAndOpenPushChannel];
    __block MockConversation *conversation;
    __block MockUser *user3;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = self.sut.selfUser;
        selfUser.name = @"Some self user name";
        MockUser *user1 = [session insertUserWithName:@"Name1 213"];
        MockUser *user2 = [session insertUserWithName:@"Name2 866"];
        user3 = [session insertUserWithName:@"Name3 555"];
        conversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1,user2]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.pushChannelReceivedEvents removeAllObjects];
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        [conversation addUsersByUser:self.sut.selfUser addedUsers:@[user3]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
    TestPushChannelEvent *memberAddEvent = self.pushChannelReceivedEvents.firstObject;
    
    XCTAssertEqual(memberAddEvent.type, ZMUpdateEventTypeConversationMemberJoin);
}

- (void)testThatWeReceiveAPushEventWhenRemovingAParticipantFromAConversation
{
    // GIVEN
    [self createAndOpenPushChannel];
    __block MockConversation *conversation;
    __block MockUser *user2;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = self.sut.selfUser;
        MockUser *user1 = [session insertUserWithName:@"Name1 213"];
        user2 = [session insertUserWithName:@"Name2 866"];
        conversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1,user2]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.pushChannelReceivedEvents removeAllObjects];
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> __unused session) {
        [conversation removeUsersByUser:self.sut.selfUser removedUser:user2];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 1u);
    TestPushChannelEvent *memberRemoveEvent = self.pushChannelReceivedEvents.firstObject;
    XCTAssertEqual(memberRemoveEvent.type, ZMUpdateEventTypeConversationMemberLeave);
}

- (void)testThatWeReceiveIsTypingPushEvents;
{
    [self createAndOpenPushChannel];
    __block MockConversation *conversation;
    __block MockUser *user2;
    __block NSString *conversationIdentifier;
    __block NSString *userIdentifier;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = self.sut.selfUser;
        MockUser *user1 = [session insertUserWithName:@"Name1 213"];
        user2 = [session insertUserWithName:@"Name2 866"];
        conversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1,user2]];
        conversationIdentifier = conversation.identifier;
        userIdentifier = user2.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.pushChannelReceivedEvents removeAllObjects];
    
    // WHEN
    [self.sut sendIsTypingEventForConversation:conversation user:user2 started:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssert([self waitWithTimeout:0.5 verificationBlock:^BOOL{
        return 1 == self.pushChannelReceivedEvents.count;
    }]);
    
    // THEN
    TestPushChannelEvent *isTypingEvent = self.pushChannelReceivedEvents.firstObject;
    
    XCTAssertEqual(isTypingEvent.type, ZMUpdateEventTypeConversationTyping);
    NSDictionary *expected = @{@"conversation": conversationIdentifier,
                               @"from": userIdentifier,
                               @"data": @{@"status": @"started"},
                               @"type": @"conversation.typing"};
    XCTAssertEqualObjects(isTypingEvent.payload, expected);
}

- (void)testThatThePushChannelIsOpenAfterALogin
{
    // GIVEN
    [self.sut.mockedTransportSession configurePushChannelWithConsumer:self groupQueue:self.fakeSyncContext];
    
    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    [[(id) self.cookieStorage stub] setAuthenticationCookieData:OCMOCK_ANY];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": password
                                                               } path:path method:ZMMethodPOST apiVersion:0];
    [self.sut.mockedTransportSession.pushChannel setKeepOpen:YES];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertTrue(self.sut.isPushChannelActive);
    XCTAssertEqual(self.pushChannelDidOpenCount, 1u);
}

- (void)testThatThePushChannelIsOpenAfterSimulateOpenPushChannel
{
    // WHEN
    [self createAndOpenPushChannel];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelDidOpenCount, 1u);
    XCTAssertTrue(self.sut.isPushChannelActive);
}

- (void)testThatThePushChannelIsClosedAfterSimulateClosePushChannel
{
    // GIVEN
    [self createAndOpenPushChannel];
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session simulatePushChannelClosed];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.pushChannelDidOpenCount, 1u);
    XCTAssertEqual(self.pushChannelDidCloseCount, 1u);
    XCTAssertFalse(self.sut.isPushChannelActive);
}

- (NSArray *)createConversationAndReturnExpectedNotificationTypes
{
    // GIVEN
    const NSInteger NUM_MESSAGES = 10;
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockConversation *conversation;
    
    NSMutableArray *expectedTypes = [NSMutableArray array];
    
    // do in separate blocks so I'm sure of the order of events - if done together there is a single
    // save and I don't know the order
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"SelfUser Name"];
        user1 = [session insertUserWithName:@"Name of User 1"];
        user2 = [session insertUserWithName:@"Name of user 2"];
        
        // two connection events
        [expectedTypes addObject:@"user.connection"];
        [expectedTypes addObject:@"user.connection"];
        
        
        MockConnection *connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        MockConnection *connection2 = [session insertConnectionWithSelfUser:selfUser toUser:user2];
        connection2.status = @"accepted";
    }];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        // conversation creation event + member join event
        [expectedTypes addObject:@"conversation.create"];
        [expectedTypes addObject:@"conversation.member-join"];
        
        conversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
    }];
    
    for(int i = 0; i < NUM_MESSAGES; ++i) {
        // NUM_MESSAGES message events
        [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
            [expectedTypes addObject:@"conversation.otr-message-add"];
            NSData *data = [[NSString stringWithFormat:@"Message %d", i] dataUsingEncoding:NSUTF8StringEncoding];
            [conversation insertOTRMessageFromClient:user1.clients.anyObject toClient:user2.clients.anyObject data:data];
            NOT_USED(session);
        }];
    }
    WaitForAllGroupsToBeEmpty(0.5);
    
    return expectedTypes;
}

- (void)testThatItReturnsTheLastPushChannelEventsWhenRequestingNotifications
{
    // GIVEN
    NSArray *expectedTypes = [self createConversationAndReturnExpectedNotificationTypes];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/notifications" method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.result, ZMTransportResponseStatusSuccess);
    NSArray* events = [[[response.payload asDictionary] arrayForKey:@"notifications" ] asDictionaries];
    XCTAssertEqual(events.count, expectedTypes.count);
    
    NSUInteger counter = 0;
    for(NSDictionary *eventData in events) {
        
        NSUUID *eventID = [eventData uuidForKey:@"id"];
        XCTAssertNotNil(eventID);
        
        NSString *type = [[[eventData arrayForKey:@"payload"] asDictionaries][0] stringForKey:@"type"];
        XCTAssertEqualObjects(type, expectedTypes[counter]);
        ++counter;
    }
}

- (void)testThatItReturnsTheLastPushChannelEventsEvenIfRequestingSinceANonExistingOne
{
    // GIVEN
    NSArray *expectedTypes = [self createConversationAndReturnExpectedNotificationTypes];
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/notifications?since=%@", [NSUUID createUUID].transportString];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 404);
    NSArray* events = [[[response.payload asDictionary] arrayForKey:@"notifications" ] asDictionaries];
    XCTAssertEqual(events.count, expectedTypes.count);
    
    NSUInteger counter = 0;
    for(NSDictionary *eventData in events) {
        
        NSUUID *eventID = [eventData uuidForKey:@"id"];
        XCTAssertNotNil(eventID);
        
        NSString *type = [[[eventData arrayForKey:@"payload"] asDictionaries][0] stringForKey:@"type"];
        XCTAssertEqualObjects(type, expectedTypes[counter]);
        ++counter;
    }
}

- (void)testThatItReturnsOnlyTheNotificationsFollowingTheOneRequested
{
    // GIVEN
    const NSUInteger eventsOffset = 4;
    NSArray *expectedTypes = [self createConversationAndReturnExpectedNotificationTypes];
    XCTAssertTrue(eventsOffset < expectedTypes.count);
    
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/notifications" method:ZMMethodGET apiVersion:0];
    
    NSArray *allEvents = [[[response.payload asDictionary] arrayForKey:@"notifications" ] asDictionaries];
    NSUUID *startingEventID = [allEvents[eventsOffset-1] uuidForKey:@"id"];
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/notifications?since=%@", startingEventID.transportString];
    response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    NSArray *expectedEvents = [allEvents subarrayWithRange:NSMakeRange(eventsOffset, allEvents.count - eventsOffset)];
    XCTAssertEqual(response.result, ZMTransportResponseStatusSuccess);
    NSArray *events = [[[response.payload asDictionary] arrayForKey:@"notifications" ] asDictionaries];
    
    XCTAssertEqualObjects(expectedEvents, events);
}

- (void)testThatItReturnsTheLastUpdateEventWhenRequested
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    
    NSMutableArray *expectedTypes = [NSMutableArray array];
    
    // do in separate blocks so I'm sure of the order of events - if done together there is a single
    // save and I don't know the order
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"SelfUser Name"];
        user1 = [session insertUserWithName:@"Name of User 1"];
        user2 = [session insertUserWithName:@"Name of user 2"];
        
        // two connection events
        [expectedTypes addObject:@"user.connection"];
        [expectedTypes addObject:@"user.connection"];
        
        
        MockConnection *connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        MockConnection *connection2 = [session insertConnectionWithSelfUser:selfUser toUser:user2];
        connection2.status = @"accepted";
    }];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/notifications/last" method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.result, ZMTransportResponseStatusSuccess);
    XCTAssertEqualObjects(response.payload, [self.sut.generatedPushEvents.lastObject transportData]);
}

@end
