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
@import WireProtos;

@interface MockTransportSessionConversationsTests : MockTransportSessionTests

@end

@implementation MockTransportSessionConversationsTests

- (void)testThatWeReceive_200_WhenRequestingConversationWhichExists
{
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    __block MockConversation *groupConversation;
    
    // GIVEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        otherUser = [session insertUserWithName:@"Foo"];
        groupConversation = [session insertConversationWithCreator:otherUser otherUsers:@[selfUser] type:ZMTConversationTypeGroup];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/conversations/" stringByAppendingPathComponent:groupConversation.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    [self checkThatTransportData:response.payload matchesConversation:groupConversation];
}

- (void)testReceivedPayloadWhenSelfUserIsAdmin
{
    __block MockUser *selfUser;
    __block MockConversation *groupConversation;
    
    // GIVEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        groupConversation = [session insertConversationWithCreator:selfUser otherUsers:@[] type:ZMTConversationTypeGroup];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/conversations/" stringByAppendingPathComponent:groupConversation.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    [self checkThatTransportData:response.payload selfUserHasGroupRole:@"wire_admin"];
}

- (void)testReceivedPayloadWhenSelfUserIsMember
{
    __block MockUser *selfUser;
    __block MockConversation *groupConversation;
    
    // GIVEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        groupConversation = [session insertConversationWithCreator:selfUser otherUsers:@[] type:ZMTConversationTypeGroup];
        groupConversation.selfRole = @"wire_member";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/conversations/" stringByAppendingPathComponent:groupConversation.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    [self checkThatTransportData:response.payload selfUserHasGroupRole:@"wire_member"];
}

- (void)testReceivedPayloadWhenOtherUserIsAdmin
{
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    __block MockConversation *groupConversation;
    
    // GIVEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        otherUser = [session insertUserWithName:@"Foo"];
        groupConversation = [session insertConversationWithCreator:otherUser otherUsers:@[selfUser] type:ZMTConversationTypeGroup];
        
        MockRole *roleAdmin = [MockRole insertIn:self.sut.managedObjectContext name:MockConversation.admin actions:[MockTeam createAdminActionsWithContext:self.sut.managedObjectContext]];
        MockParticipantRole * participantRole = [MockParticipantRole insertIn:self.sut.managedObjectContext conversation:groupConversation user:otherUser];
        participantRole.role = roleAdmin;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/conversations/" stringByAppendingPathComponent:groupConversation.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    [self checkThatTransportData:response.payload firstOtherUserHasGroupRole:@"wire_admin"];
}

- (void)testReceivedPayloadWhenOtherUserIsMember
{
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    __block MockConversation *groupConversation;
    
    // GIVEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        otherUser = [session insertUserWithName:@"Foo"];
        groupConversation = [session insertConversationWithCreator:otherUser otherUsers:@[selfUser] type:ZMTConversationTypeGroup];
        MockRole *roleMember = [MockRole insertIn:self.sut.managedObjectContext name:MockConversation.member actions:[MockTeam createMemberActionsWithContext:self.sut.managedObjectContext]];
        MockParticipantRole * participantRole = [MockParticipantRole insertIn:self.sut.managedObjectContext conversation:groupConversation user:otherUser];
        participantRole.role = roleMember;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/conversations/" stringByAppendingPathComponent:groupConversation.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    [self checkThatTransportData:response.payload firstOtherUserHasGroupRole:@"wire_member"];
}

- (void)testThatWeReceive_403_WhenRequestingConversationWhichExistsButWeAreNotAMemberOf
{
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    __block MockConversation *groupConversation;
    
    // GIVEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        otherUser = [session insertUserWithName:@"Foo"];
        groupConversation = [session insertConversationWithCreator:otherUser otherUsers:@[] type:ZMTConversationTypeGroup];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/conversations/" stringByAppendingPathComponent:groupConversation.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 403);
}

- (void)testThatWeReceive_404_WhenRequestingConversationWhichDoesntExists
{
    __block MockUser *selfUser;
    
    // GIVEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [@"/conversations/" stringByAppendingPathComponent:NSUUID.createUUID.transportString];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatWeCanManuallyCreateAndRequestAllConversations;
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    
    __block MockConnection *connection1;
    
    __block MockConversation *selfConversation;
    __block MockConversation *oneOnOneConversation;
    __block MockConversation *groupConversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        user2 = [session insertUserWithName:@"Bar"];
        
        connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
        selfConversation = [session insertSelfConversationWithSelfUser:selfUser];
        oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.creator = user1;
        groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
        groupConversation.creator = user2;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/conversations/" method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    
    NSArray *data = [[response.payload asDictionary] arrayForKey:@"conversations"];
    XCTAssertNotNil(data);
    XCTAssertEqual(data.count, (NSUInteger) 3);
    
    [self checkThatTransportData:data[0] matchesConversation:selfConversation];
    [self checkThatTransportData:data[1] matchesConversation:oneOnOneConversation];
    [self checkThatTransportData:data[2] matchesConversation:groupConversation];
}

- (void)testThatWeCanCreateAConversationWithAPostRequest
{
    
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    __block NSString *user1ID;
    __block NSString *user2ID;
    
    __block MockConnection *connection1;
    __block MockConnection *connection2;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"The Great Quux"];
        user1 = [session insertUserWithName:@"Foo"];
        user1ID = user1.identifier;
        user2 = [session insertUserWithName:@"Bar"];
        user2ID = user2.identifier;
        
        connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
        connection2 = [session insertConnectionWithSelfUser:selfUser toUser:user2];
        connection2.status = @"accepted";
        connection2.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.098];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{ @"users": @[user1ID, user2ID] };
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/conversations/" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    
    NSDictionary *responsePayload = (id) response.payload;
    NSString *conversationID = [responsePayload stringForKey:@"id"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", conversationID];
    NSFetchRequest *fetchRequest = [MockConversation sortedFetchRequestWithPredicate:predicate];
    [self.sut.managedObjectContext performBlockAndWait:^{
        NSArray *conversations = [self.sut.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        XCTAssertNotNil(conversations);
        XCTAssertEqual(1u, conversations.count);
        
        MockConversation *storedConversation = conversations[0];
        
        NSDictionary *expectedPayload = (NSDictionary *)[storedConversation transportData];
        XCTAssertEqualObjects(expectedPayload, responsePayload);
        XCTAssertEqualObjects([user1 roleIn:storedConversation].name, MockConversation.admin);
        XCTAssertEqualObjects([user2 roleIn:storedConversation].name, MockConversation.admin);
    }];
}

- (void)testThatWeCanCreateAConversationWithAllMembers
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    __block NSString *user1ID;
    __block NSString *user2ID;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"The Great Quux"];
        user1 = [session insertUserWithName:@"Foo"];
        user1ID = user1.identifier;
        user2 = [session insertUserWithName:@"Bar"];
        user2ID = user2.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{ @"users": @[user1ID, user2ID],
                               @"conversation_role" : @"wire_member"
                               };
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/conversations/" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    
    NSDictionary *responsePayload = (id) response.payload;
    NSString *conversationID = [responsePayload stringForKey:@"id"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", conversationID];
    NSFetchRequest *fetchRequest = [MockConversation sortedFetchRequestWithPredicate:predicate];
    [self.sut.managedObjectContext performBlockAndWait:^{
        NSArray *conversations = [self.sut.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        XCTAssertNotNil(conversations);
        XCTAssertEqual(1u, conversations.count);
        
        MockConversation *storedConversation = conversations[0];
        
        NSDictionary *expectedPayload = (NSDictionary *)[storedConversation transportData];
        XCTAssertEqualObjects(expectedPayload, responsePayload);
        XCTAssertEqualObjects([storedConversation.creator roleIn:storedConversation].name, MockConversation.admin);
        XCTAssertEqualObjects([user1 roleIn:storedConversation].name, MockConversation.member);
        XCTAssertEqualObjects([user2 roleIn:storedConversation].name, MockConversation.member);
    }];
}

- (ZMTransportResponse *)responseForAddingMessageWithPayload:(NSDictionary *)payload path:(NSString *)path expectedEventType:(NSString *)expectedEventType
{
    // GIVEN
    
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    __block MockConversation *oneOnOneConversation;
    __block NSString *selfUserID;
    __block NSString *oneOnOneConversationID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        selfUserID = selfUser.identifier;
        user1 = [session insertUserWithName:@"Foo"];
        
        oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversationID = oneOnOneConversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSString *requestPath = [NSString pathWithComponents:@[@"/", @"conversations", oneOnOneConversationID, path]];
    ZMTransportResponse *response = [self responseForPayload:payload path:requestPath method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return nil;
    }
    
    XCTAssertEqual(response.HTTPStatus, 201);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *responsePayload = [response.payload asDictionary];
    XCTAssertEqualObjects(responsePayload[@"conversation"], oneOnOneConversationID);
    XCTAssertEqualObjects(responsePayload[@"from"], selfUserID);
    XCTAssertEqualObjects(responsePayload[@"type"], expectedEventType);
    XCTAssertNotNil([responsePayload dateFor:@"time"]);
    AssertDateIsRecent([responsePayload dateFor:@"time"]);
    
    path = @"/notifications";
    ZMTransportResponse *eventsResponse = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertNotNil(eventsResponse);
    if (!eventsResponse) {
        return nil;
    }
    
    XCTAssertEqual(eventsResponse.HTTPStatus, 200);
    XCTAssertNil(eventsResponse.transportSessionError);
    NSArray *events = [[eventsResponse.payload asDictionary] arrayForKey:@"notifications"];
    XCTAssertNotNil(events);
    XCTAssertGreaterThanOrEqual(events.count, 1u);
    
    NSDictionary *messageRoundtripPayload = [[[events lastObject] optionalArrayForKey:@"payload"] firstObject];
    XCTAssertEqualObjects(messageRoundtripPayload[@"conversation"], oneOnOneConversationID);
    XCTAssertEqualObjects(messageRoundtripPayload[@"from"], selfUserID);
    XCTAssertEqualObjects(messageRoundtripPayload[@"type"], expectedEventType);
    XCTAssertNotNil([messageRoundtripPayload dateFor:@"time"]);
    XCTAssertEqualObjects([responsePayload dateFor:@"time"], [messageRoundtripPayload dateFor:@"time"]);
    
    return response;
}

- (void)testThatItReturnsMissingClientsWhenReceivingOTRMessage
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *selfClient;
    __block MockUserClient *secondSelfClient;
    
    __block MockUser *otherUser;
    __block MockUserClient *otherUserClient;
    __block MockUserClient *secondOtherUserClient;
    
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"foo"];
        [session registerClientForUser:selfUser label:@"self user" type:@"permanent" deviceClass:@"phone"];
        otherUser = [session insertUserWithName:@"bar"];
        conversation = [session insertConversationWithCreator:selfUser otherUsers:@[otherUser] type:ZMTConversationTypeOneOnOne];
        
        selfClient = [selfUser.clients anyObject];
        secondSelfClient = [session registerClientForUser:selfUser label:@"self2" type:@"permanent" deviceClass:@"phone"];
        
        otherUserClient = [otherUser.clients anyObject];
        secondOtherUserClient = [session registerClientForUser:otherUser label:@"other2" type:@"permanent" deviceClass:@"phone"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    NSUInteger previousNotificationsCount = self.sut.generatedPushEvents.count;

    NSData *messageData = [@"Fofooof" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Content = [messageData base64EncodedStringWithOptions:0];
    
    NSString *redundantClientId = [NSString createAlphanumericalString];
    NSDictionary *payload = @{
                              @"sender": selfClient.identifier,
                              @"recipients" : @{
                                      otherUser.identifier: @{
                                              otherUserClient.identifier: base64Content,
                                              redundantClientId: base64Content
                                              }
                                      }
                              };
    
    // WHEN
    NSString *requestPath = [NSString pathWithComponents:@[@"/", @"conversations", conversation.identifier, @"otr", @"messages"]];
    ZMTransportResponse *response = [self responseForPayload:payload path:requestPath method:ZMMethodPOST apiVersion:0];
    
    XCTAssertNotNil(response);
    XCTAssertNil(response.transportSessionError);
    
    if (response != nil) {
        XCTAssertEqual(response.HTTPStatus, 412);
        
        NSDictionary *expectedResponsePayload = @{
                                                  @"missing": @{
                                                          selfUser.identifier: @[secondSelfClient.identifier],
                                                          otherUser.identifier: @[secondOtherUserClient.identifier]
                                                          },
                                                  @"deleted": @{
                                                          otherUser.identifier: @[redundantClientId]
                                                          }
                                                  };
        
        AssertEqualDictionaries(expectedResponsePayload[@"missing"], response.payload.asDictionary[@"missing"]);
        AssertEqualDictionaries(expectedResponsePayload[@"deleted"], response.payload.asDictionary[@"deleted"]);
    }
    
    XCTAssertEqual(self.sut.generatedPushEvents.count, previousNotificationsCount);
}

- (void)testThatItReturnsMissingClientsOnlyForOneUserWhenReceivingOTRMessage
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *selfClient;
    __block MockUserClient *secondSelfClient;
    
    __block MockUser *otherUser;
    __block MockUserClient *otherUserClient1;
    __block MockUserClient *otherUserClient2;
    
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"foo"];
        [session registerClientForUser:selfUser label:@"self user" type:@"permanent" deviceClass:@"phone"];
        otherUser = [session insertUserWithName:@"bar"];
        MockUser *extraUser = [session insertUserWithName:@"bar"];
        conversation = [session insertConversationWithCreator:selfUser otherUsers:@[otherUser, extraUser] type:ZMTConversationTypeOneOnOne];
        
        selfClient = [selfUser.clients anyObject];
        secondSelfClient = [session registerClientForUser:selfUser label:@"self2" type:@"permanent" deviceClass:@"phone"];
        
        otherUserClient1 = [otherUser.clients anyObject];
        otherUserClient2 = [session registerClientForUser:otherUser label:@"other2" type:@"permanent" deviceClass:@"phone"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    NSUInteger previousNotificationsCount = self.sut.generatedPushEvents.count;
    
    NSData *messageData = [@"Fofooof" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Content = [messageData base64EncodedStringWithOptions:0];
    
    NSDictionary *payload = @{
                              @"sender": selfClient.identifier,
                              @"recipients" : @{
                                      otherUser.identifier: @{
                                              otherUserClient1.identifier: base64Content,
                                              }
                                      }
                              };
    
    // WHEN
    NSString *requestBasePath = [NSString pathWithComponents:@[@"/", @"conversations", conversation.identifier, @"otr", @"messages"]];
    NSString *requestPath = [NSString stringWithFormat:@"%@?report_missing=%@", requestBasePath, otherUser.identifier];
    ZMTransportResponse *response = [self responseForPayload:payload path:requestPath method:ZMMethodPOST apiVersion:0];
    
    XCTAssertNotNil(response);
    XCTAssertNil(response.transportSessionError);
    
    if (response != nil) {
        XCTAssertEqual(response.HTTPStatus, 412);
        
        NSDictionary *expectedResponsePayload = @{
                                                  @"missing": @{
                                                          otherUser.identifier: @[otherUserClient2.identifier]
                                                          },
                                                  };
        
        AssertEqualDictionaries(expectedResponsePayload[@"missing"], response.payload.asDictionary[@"missing"]);
    }
    
    XCTAssertEqual(self.sut.generatedPushEvents.count, previousNotificationsCount);
}

- (void)testThatItDoesNotReturnsMissingClientsOnlyForOneUserWhenReceivingOTRMessage
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *selfClient;
    __block MockUserClient *secondSelfClient;
    
    __block MockUser *otherUser;
    __block MockUserClient *otherUserClient;
    
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"foo"];
        [session registerClientForUser:selfUser label:@"self user" type:@"permanent" deviceClass:@"phone"];
        otherUser = [session insertUserWithName:@"bar"];
        MockUser *extraUser = [session insertUserWithName:@"bar"];
        conversation = [session insertConversationWithCreator:selfUser otherUsers:@[otherUser, extraUser] type:ZMTConversationTypeOneOnOne];
        
        selfClient = [selfUser.clients anyObject];
        secondSelfClient = [session registerClientForUser:selfUser label:@"self2" type:@"permanent" deviceClass:@"phone"];
        
        otherUserClient = [otherUser.clients anyObject];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    NSUInteger previousNotificationsCount = self.sut.generatedPushEvents.count;

    NSData *messageData = [@"Fofooof" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Content = [messageData base64EncodedStringWithOptions:0];
    
    NSDictionary *payload = @{
                              @"sender": selfClient.identifier,
                              @"recipients" : @{
                                      otherUser.identifier: @{
                                              otherUserClient.identifier: base64Content,
                                              }
                                      }
                              };
    
    // WHEN
    NSString *requestBasePath = [NSString pathWithComponents:@[@"/", @"conversations", conversation.identifier, @"otr", @"messages"]];
    NSString *requestPath = [NSString stringWithFormat:@"%@?report_missing=%@", requestBasePath, otherUser.identifier];
    ZMTransportResponse *response = [self responseForPayload:payload path:requestPath method:ZMMethodPOST apiVersion:0];
    
    XCTAssertNotNil(response);
    XCTAssertNil(response.transportSessionError);
    
    if (response != nil) {
        XCTAssertEqual(response.HTTPStatus, 201);
    }
    
    XCTAssertEqual(self.sut.generatedPushEvents.count, previousNotificationsCount+1);
}

- (void)testThatItCreatesPushEventsWhenReceivingOTRMessageWithoutMissedClients
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *selfClient;
    __block MockUserClient *secondSelfClient;
    
    __block MockUser *otherUser;
    __block MockUserClient *otherUserClient;
    __block MockUserClient *secondOtherUserClient;
    
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"foo"];
        [session registerClientForUser:selfUser label:@"self user" type:@"permanent" deviceClass:@"phone"];

        otherUser = [session insertUserWithName:@"bar"];
        conversation = [session insertConversationWithCreator:selfUser otherUsers:@[otherUser] type:ZMTConversationTypeOneOnOne];
        
        selfClient = [selfUser.clients anyObject];
        secondSelfClient = [session registerClientForUser:selfUser label:@"self2" type:@"permanent" deviceClass:@"phone"];
        
        otherUserClient = [otherUser.clients anyObject];
        secondOtherUserClient = [session registerClientForUser:otherUser label:@"other2" type:@"permanent" deviceClass:@"phone"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    NSUInteger previousNotificationsCount = self.sut.generatedPushEvents.count;

    NSData *messageData = [@"Fofooof" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Content = [messageData base64EncodedStringWithOptions:0];
    
    NSString *redundantClientId = [NSString createAlphanumericalString];
    NSDictionary *payload = @{
                              @"sender": selfClient.identifier,
                              @"recipients" : @{
                                      selfUser.identifier: @{
                                              secondSelfClient.identifier: base64Content
                                              },
                                      otherUser.identifier: @{
                                              otherUserClient.identifier: base64Content,
                                              secondOtherUserClient.identifier: base64Content,
                                              redundantClientId: base64Content
                                              }
                                      }
                              };
    
    // WHEN
    NSString *requestPath = [NSString pathWithComponents:@[@"/", @"conversations", conversation.identifier, @"otr", @"messages"]];
    ZMTransportResponse *response = [self responseForPayload:payload path:requestPath method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertNil(response.transportSessionError);
    
    if (response != nil) {
        XCTAssertEqual(response.HTTPStatus, 201);
        
        NSDictionary *expectedResponsePayload = @{
                                                  @"missing": @{},
                                                  @"deleted": @{
                                                          otherUser.identifier: @[redundantClientId]
                                                          }
                                                  };
        
        AssertEqualDictionaries(expectedResponsePayload[@"missing"], response.payload.asDictionary[@"missing"]);
        AssertEqualDictionaries(expectedResponsePayload[@"deleted"], response.payload.asDictionary[@"deleted"]);
    }
    
    XCTAssertEqual(self.sut.generatedPushEvents.count, previousNotificationsCount+3u);
    if (self.sut.generatedPushEvents.count > 4u) {
        NSArray *otrEvents = [self.sut.generatedPushEvents subarrayWithRange:NSMakeRange(self.sut.generatedPushEvents.count-3, 3)];
        for (MockPushEvent *event in otrEvents) {
            NSDictionary *eventPayload = event.payload.asDictionary;
            XCTAssertEqualObjects(eventPayload[@"type"], @"conversation.otr-message-add");
        }
    }
}

- (void)testThatItCreatesPushEventsWhenReceivingEncryptedOTRMessageWithCorrectData;
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *selfClient;
    
    __block MockUser *otherUser;
    __block MockUserClient *otherUserClient;
    
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"foo"];
        [session registerClientForUser:selfUser label:@"self user" type:@"permanent" deviceClass:@"phone"];
        otherUser = [session insertUserWithName:@"bar"];
        conversation = [session insertConversationWithCreator:selfUser otherUsers:@[otherUser] type:ZMTConversationTypeOneOnOne];
        
        selfClient = [selfUser.clients anyObject];
        otherUserClient = [otherUser.clients anyObject];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSData *messageData = [@"Fofooof" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Content = [messageData base64EncodedStringWithOptions:0];
    
    // WHEN
    [self.sut performRemoteChanges:^(__unused id<MockTransportSessionObjectCreation> session) {
        NSData *encryptedData = [MockUserClient encryptedWithData:messageData from:otherUserClient to:selfClient];
        [conversation insertOTRMessageFromClient:otherUserClient toClient:selfClient data:encryptedData];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    MockPushEvent *lastEvent = self.sut.generatedPushEvents.lastObject;
    NSDictionary *lastEventPayload = [lastEvent.payload asDictionary];
    XCTAssertEqualObjects(lastEventPayload[@"type"], @"conversation.otr-message-add");
    XCTAssertEqualObjects(lastEventPayload[@"data"][@"recipient"], selfClient.identifier);
    XCTAssertEqualObjects(lastEventPayload[@"data"][@"sender"], otherUserClient.identifier);
    XCTAssertNotEqualObjects(lastEventPayload[@"data"][@"text"], base64Content);
}

- (void)testThatItCreatesPushEventsWhenReceivingEncryptedOTRAssetWithCorrectData;
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *selfClient;
    
    __block MockUser *otherUser;
    __block MockUserClient *otherUserClient;
    
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"foo"];
        [session registerClientForUser:selfUser label:@"self user" type:@"permanent" deviceClass:@"phone"];
        otherUser = [session insertUserWithName:@"bar"];
        conversation = [session insertConversationWithCreator:selfUser otherUsers:@[otherUser] type:ZMTConversationTypeOneOnOne];
        
        selfClient = [selfUser.clients anyObject];
        otherUserClient = [otherUser.clients anyObject];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    NSUUID *assetID = [NSUUID createUUID];
    NSData *imageData = [self verySmallJPEGData];
    
    NSData *messageData = [@"Fofooof" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Content = [messageData base64EncodedStringWithOptions:0];
    // WHEN
    [self.sut performRemoteChanges:^(__unused id<MockTransportSessionObjectCreation> session) {
        NSData *encryptedData = [MockUserClient encryptedWithData:messageData from:otherUserClient to:selfClient];
        [conversation insertOTRAssetFromClient:otherUserClient toClient:selfClient metaData:encryptedData imageData:imageData assetId:assetID isInline:YES];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    MockPushEvent *lastEvent = self.sut.generatedPushEvents.lastObject;
    NSDictionary *lastEventPayload = [lastEvent.payload asDictionary];
    XCTAssertEqualObjects(lastEventPayload[@"type"], @"conversation.otr-asset-add");
    XCTAssertEqualObjects(lastEventPayload[@"data"][@"recipient"], selfClient.identifier);
    XCTAssertEqualObjects(lastEventPayload[@"data"][@"sender"], otherUserClient.identifier);
    XCTAssertEqualObjects(lastEventPayload[@"data"][@"data"], [imageData base64String]);
    XCTAssertNotEqualObjects(lastEventPayload[@"data"][@"key"], base64Content);
}

- (void)testThatInsertingArbitraryEventWithBlock:(MockEvent *(^)(id<MockTransportSessionObjectCreation> session, MockConversation *conversation))eventBlock expectedPayloadData:(id)expectedPayloadData
{
    // GIVEN
    __block MockUser *selfUser;
    
    __block MockConversation *conversation;
    __block MockEvent *event;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        [session registerClientForUser:selfUser label:@"Self Client" type:@"permanent" deviceClass:@"phone"];
        conversation = [session insertSelfConversationWithSelfUser:selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> ZM_UNUSED session) {
        event = eventBlock(session, conversation);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertNotNil(event);
        if ([[MockEvent persistentEvents] containsObject:@(event.eventType)]) {
            XCTAssertNotNil(event.identifier);
        }
        XCTAssertEqual(event.from, selfUser);
        XCTAssertEqualObjects(event.conversation, conversation);
        XCTAssertEqualObjects(event.data, expectedPayloadData);
    }];
}

- (void)testThatInsertEventInConversationSetsProperValues
{
    NSString *newConversationName = @"¡Ay caramba!";
    NSDictionary *expectedPayloadData = @{@"name": newConversationName};
    
    [self testThatInsertingArbitraryEventWithBlock:^MockEvent *(id<MockTransportSessionObjectCreation> __unused session, MockConversation *conversation) {
        return [conversation changeNameByUser:self.sut.selfUser name:@"¡Ay caramba!"];
    } expectedPayloadData:expectedPayloadData];
}

- (void)testThatChangeReceiptModeInConversationSetsProperValues
{
    [self testThatInsertingArbitraryEventWithBlock:^MockEvent *(id<MockTransportSessionObjectCreation> __unused session, MockConversation *conversation) {
        return [conversation changeReceiptModeByUser:self.sut.selfUser receiptMode:1];
    } expectedPayloadData:@{ @"receipt_mode": @(1) }];
}


- (void)testThatInsertClientMessageInConversationSetsProperValues
{
    NSString *text = [self.name stringByAppendingString:@" message 12534"];
    NSData *messageData = [text dataUsingEncoding:NSUTF8StringEncoding];
    id<ZMTransportData> expectedPayloadData = [messageData base64EncodedStringWithOptions:0];
    
    [self testThatInsertingArbitraryEventWithBlock:^MockEvent *(id<MockTransportSessionObjectCreation> __unused session, MockConversation *conversation) {
        return [conversation insertClientMessageFromUser:self.sut.selfUser data:messageData];
    } expectedPayloadData:expectedPayloadData];
}

- (void)testThatInsertOTRMessageInConversationSetsProperValues
{
    NSString *text = [self.name stringByAppendingString:@" message 12534"];
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    __block NSMutableDictionary *expectedPayloadData = [@{@"text": [data base64EncodedStringWithOptions:0]} mutableCopy];
    
    [self testThatInsertingArbitraryEventWithBlock:^MockEvent *(id<MockTransportSessionObjectCreation> session, MockConversation *conversation) {
        MockUserClient *client1 = [session registerClientForUser:self.sut.selfUser label:@"client1" type:@"permanent" deviceClass:@"phone"];
        MockUserClient *client2 = [session registerClientForUser:self.sut.selfUser label:@"client2" type:@"permanent" deviceClass:@"phone"];
        expectedPayloadData[@"sender"] = client1.identifier;
        expectedPayloadData[@"recipient"] = client2.identifier;
        return [conversation insertOTRMessageFromClient:client1 toClient:client2 data:data];
    } expectedPayloadData:expectedPayloadData];
}

- (void)testThatInsertNotInlineOTRAssetInConversationSetsProperValues
{
    NSData *info = [@"some data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *imageData = [@"image" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUUID *assetId = [NSUUID createUUID];
    __block NSMutableDictionary *expectedPayloadData = [@{@"data": [NSNull null],
                                                          @"key": [info base64EncodedStringWithOptions:0],
                                                          @"id": assetId.transportString} mutableCopy];
    
    [self testThatInsertingArbitraryEventWithBlock:^MockEvent *(id<MockTransportSessionObjectCreation> session, MockConversation *conversation) {
        MockUserClient *client1 = [session registerClientForUser:self.sut.selfUser label:@"client1" type:@"permanent" deviceClass:@"phone"];
        MockUserClient *client2 = [session registerClientForUser:self.sut.selfUser label:@"client2" type:@"permanent" deviceClass:@"phone"];
        expectedPayloadData[@"sender"] = client1.identifier;
        expectedPayloadData[@"recipient"] = client2.identifier;
        
        return [conversation insertOTRAssetFromClient:client1 toClient:client2 metaData:info imageData:imageData assetId:assetId isInline:NO];
    } expectedPayloadData:expectedPayloadData];
}

- (void)testThatInsertInlineOTRAssetInConversationSetsProperValues
{
    NSData *info = [@"some data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *imageData = [@"image" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUUID *assetId = [NSUUID createUUID];
    __block NSMutableDictionary *expectedPayloadData = [@{@"data": [imageData base64EncodedStringWithOptions:0],
                                                          @"key": [info base64EncodedStringWithOptions:0],
                                                          @"id": assetId.transportString} mutableCopy];
    
    [self testThatInsertingArbitraryEventWithBlock:^MockEvent *(id<MockTransportSessionObjectCreation> session, MockConversation *conversation) {
        MockUserClient *client1 = [self.sut.selfUser.clients anyObject];
        MockUserClient *client2 = [session registerClientForUser:self.sut.selfUser label:@"client2" type:@"permanent" deviceClass:@"phone"];
        expectedPayloadData[@"sender"] = client1.identifier;
        expectedPayloadData[@"recipient"] = client2.identifier;
        
        return [conversation insertOTRAssetFromClient:client1 toClient:client2 metaData:info imageData:imageData assetId:assetId isInline:YES];
    } expectedPayloadData:expectedPayloadData];
}

- (void)testThatItAddsTwoImageEventsToTheConversation
{
    // GIVEN
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"Me Myself"];
        conversation = [session insertSelfConversationWithSelfUser:selfUser];
        
        // WHEN
        [conversation insertImageEventsFromUser:selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertNotNil(conversation.events);
        XCTAssertNotEqual([conversation.events indexOfObjectPassingTest:^BOOL(MockEvent *event, NSUInteger idx, BOOL *stop) {
            NOT_USED(idx);
            NOT_USED(stop);
            
            if (! [event.type isEqualToString:@"conversation.asset-add"]) {
                return NO;
            }
            
            NSDictionary *info = event.data[@"info"];
            if (! [info[@"tag"] isEqualToString:@"preview"]) {
                return NO;
            }
            
            return YES;
        }], (NSUInteger) NSNotFound);
        
        
        
        XCTAssertNotEqual([conversation.events indexOfObjectPassingTest:^BOOL(MockEvent *event, NSUInteger idx, BOOL *stop) {
            NOT_USED(idx);
            NOT_USED(stop);
            
            if (! [event.type isEqualToString:@"conversation.asset-add"]) {
                return NO;
            }
            
            NSDictionary *info = event.data[@"info"];
            if (! [info[@"tag"] isEqualToString:@"medium"]) {
                return NO;
            }
            
            return YES;
        }], (NSUInteger) NSNotFound);
    }];
}

- (void)testThatWeCanSetAConversationNameUsingPUT
{
    // GIVEN
    NSString *conversationName = @"New name";
    __block MockConversation *conversation;
    __block NSString *conversationID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session insertSelfUserWithName:@"Me Myself"];
        conversation = [session insertSelfConversationWithSelfUser:self.sut.selfUser];
        [conversation changeNameByUser:self.sut.selfUser name:@"Boring old name"];
        conversationID = conversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{ @"name": conversationName };
    
    NSString *path = [@"/conversations/" stringByAppendingString:conversationID];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPUT apiVersion:0];
    
    // THEN
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertEqualObjects(conversation.name, conversationName);
        XCTAssertNotNil(response);
        XCTAssertEqual(response.HTTPStatus, 200);
    }];
}

- (void)testThatWeReturnCorrectResponseForRequestToSetReceiptMode
{
    // GIVEN
    __block MockConversation *conversation;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session insertSelfUserWithName:@"Me Myself"];
        conversation = [session insertGroupConversationWithSelfUser:self.sut.selfUser otherUsers:@[]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{ @"receipt_mode": @(1) };
    
    NSString *path = [[@"/conversations/" stringByAppendingString:conversation.identifier] stringByAppendingString:@"/receipt-mode"];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPUT apiVersion:0];
    
    // THEN
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertEqualObjects(conversation.receiptMode, @(1));
        XCTAssertNotNil(response);
        XCTAssertEqual(response.HTTPStatus, 200);
    }];
}

- (void)testThatWeCanDeleteAParticipantFromAConversation
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    
    __block MockConversation *groupConversation;
    __block NSString *groupConversationID;
    __block NSString *user1ID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        user1ID = user1.identifier;
        user2 = [session insertUserWithName:@"Bar"];
        
        groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
        groupConversation.creator = user2;
        groupConversationID = groupConversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSString *path = [NSString pathWithComponents:@[@"/", @"conversations", groupConversationID, @"members", user1ID]];
    
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodDELETE apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertEqualObjects(groupConversation.activeUsers.set, ([NSSet setWithObjects:selfUser, user2, nil]) );
    }];
}

- (void)testThatWeCanChangeAParticipantGroupRoleInAConversation
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    
    __block MockConversation *groupConversation;
    __block NSString *groupConversationID;
    __block NSString *user1ID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        user1ID = user1.identifier;
        user2 = [session insertUserWithName:@"Bar"];
        
        groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
        groupConversationID = groupConversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSString *path = [NSString pathWithComponents:@[@"/", @"conversations", groupConversationID, @"members", user1ID]];
    NSDictionary *payload = @{
                              @"conversation_role": MockConversation.member
                              };
    
    //WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPUT apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertEqualObjects([user1 roleIn:groupConversation].name, MockConversation.member);
        XCTAssertEqualObjects([selfUser roleIn:groupConversation].name, MockConversation.admin);
    }];
}


- (void)testThatWeCanAddParticipantsToAConversation
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockUser *user3;
    
    __block MockConversation *groupConversation;
    __block NSString *groupConversationID;
    __block NSString *user3ID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        user2 = [session insertUserWithName:@"Bar"];
        user3 = [session insertUserWithName:@"H.P. Baxxter"];
        user3ID = user3.identifier;
        
        MockConnection *connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user3];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
        groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
        groupConversation.creator = user2;
        groupConversationID = groupConversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSString *path = [NSString pathWithComponents:@[@"/", @"conversations", groupConversationID, @"members"]];
    NSDictionary *payload = @{
                              @"users": @[user3ID.lowercaseString]
                              };
    
    //WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    [self.sut.managedObjectContext performGroupedBlock:^{
        NSOrderedSet *activeUsers = groupConversation.activeUsers;
        XCTAssertEqualObjects(activeUsers, ([NSOrderedSet orderedSetWithObjects:selfUser, user1, user2, user3, nil]) );
        XCTAssertEqualObjects([user3 roleIn:groupConversation].name, MockConversation.admin);
    }];
}

- (void)testThatWeCanAddNewParticipantsToAConversationWithSpecificGroupRole
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockUser *user3;
    
    __block MockConversation *groupConversation;
    __block NSString *groupConversationID;
    __block NSString *user3ID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        user2 = [session insertUserWithName:@"Bar"];
        user3 = [session insertUserWithName:@"H.P. Baxxter"];
        user3ID = user3.identifier;
        
        groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
        groupConversation.creator = user2;
        groupConversationID = groupConversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSString *path = [NSString pathWithComponents:@[@"/", @"conversations", groupConversationID, @"members"]];
    NSDictionary *payload = @{
                              @"users": @[user3ID.lowercaseString],
                              @"conversation_role": MockConversation.member
                              };

    //WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    [self.sut.managedObjectContext performGroupedBlock:^{
        XCTAssertEqualObjects([user3 roleIn:groupConversation].name, MockConversation.member);
    }];
}

- (void)testThatItRefusesToAddMembersToTheConversationThatAreNotConnectedToTheSelfUser
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockUser *user3;
    
    __block MockConversation *groupConversation;
    __block NSString *groupConversationID;
    __block NSString *user3ID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        user2 = [session insertUserWithName:@"Bar"];
        user3 = [session insertUserWithName:@"H.P. Baxxter"];
        user3ID = user3.identifier;
        
        groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
        groupConversation.creator = user2;
        groupConversationID = groupConversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSString *path = [NSString pathWithComponents:@[@"/", @"conversations", groupConversationID, @"members"]];
    NSDictionary *payload = @{
                              @"users": @[user3ID.lowercaseString]
                              };
    
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertNil(response.transportSessionError);
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertEqualObjects(groupConversation.activeUsers.set, ([NSSet setWithObjects:selfUser, user1, user2, nil]) );
    }];
}

- (void)testThatItReturnsAllConversationIDs
{
    // GIVEN
    __block MockUser *selfUser;
    
    NSMutableArray *conversationIDs = [NSMutableArray array];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        MockUser *user1 = [session insertUserWithName:@"Foo"];
        MockUser *user2 = [session insertUserWithName:@"Bar"];
        
        for (int i=0; i < 278; ++i ) {
            MockConversation *groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
            [conversationIDs addObject:groupConversation.identifier];
        }
        
    }];
    
    // WHEN
    NSString *path = @"/conversations/ids";
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    NSArray *receivedTransportIDs = response.payload.asDictionary[@"conversations"];
    XCTAssertEqualObjects([NSSet setWithArray:receivedTransportIDs], [NSSet setWithArray:conversationIDs]);
    
}

- (void)testThatItReturnsConversationsForSpecificIDs
{
    // GIVEN
    __block MockUser *selfUser;
    
    NSMutableDictionary *conversationMap = [NSMutableDictionary dictionary];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        MockUser *user1 = [session insertUserWithName:@"Foo"];
        MockUser *user2 = [session insertUserWithName:@"Bar"];
        
        for (int i = 0; i < 78; ++i) {
            MockConversation *groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
            conversationMap[groupConversation.identifier] = groupConversation;
        }
    }];
    
    NSMutableSet *randomlyPickedConversations = [NSMutableSet set];
    for (int i = 0; i < 14; ++i) {
        NSUInteger randomIndex = arc4random() % (conversationMap.allValues.count - 1);
        [randomlyPickedConversations addObject: conversationMap.allValues[randomIndex]];
    }
    
    NSArray *requestedConversationIDs = [randomlyPickedConversations.allObjects mapWithBlock:^id(MockConversation *obj) {
        return obj.identifier;
    }];
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/conversations?ids=%@", [requestedConversationIDs componentsJoinedByString:@","]];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    NSArray *receivedConversations = response.payload.asDictionary[@"conversations"];
    NSMutableSet *receivedConversationIDs = [NSMutableSet set];
    
    for (NSDictionary *rawConversation in receivedConversations) {
        NSString *conversationID = rawConversation[@"id"];
        MockConversation *conversation = conversationMap[conversationID];
        [self checkThatTransportData:rawConversation matchesConversation:conversation];
        [receivedConversationIDs addObject:conversationID];
    }
    
    XCTAssertEqualObjects(receivedConversationIDs, [NSSet setWithArray:requestedConversationIDs]);
}

@end




@implementation MockTransportSessionConversationsTests (ConversationArchiveAndMuted)

- (void)testThatItSetsTheArchivedEventOnTheConversationWhenAsked
{
    // GIVEN
    __block MockConversation *conversation;
    __block NSString *conversationID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session insertSelfUserWithName:@"Me Myself"];
        conversation = [session insertSelfConversationWithSelfUser:self.sut.selfUser];
        conversationID = conversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDate *archivedTime = [[NSDate date] dateByAddingTimeInterval:-50];
    NSDictionary *payload = @{ @"otr_archived_ref":  archivedTime.transportString,
                               @"otr_archived" : @1 };
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/self", conversationID];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPUT apiVersion:0];
    
    // THEN
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertNotNil(response);
        XCTAssertEqual(response.HTTPStatus, 200);
        XCTAssertEqualObjects(response.payload, nil);
        XCTAssertEqualObjects(conversation.otrArchivedRef, archivedTime.transportString);
        XCTAssertTrue(conversation.otrArchived);
    }];
    
}

- (void)testThatItUnsetsTheArchivedEventOnTheConversationWhenAsked
{
    // GIVEN
    __block MockConversation *conversation;
    __block NSString *conversationID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session insertSelfUserWithName:@"Me Myself"];
        conversation = [session insertSelfConversationWithSelfUser:self.sut.selfUser];
        conversationID = conversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDate *archivedTime = [[NSDate date] dateByAddingTimeInterval:-50];
    NSDictionary *payload = @{ @"otr_archived_ref":  archivedTime.transportString,
                               @"otr_archived" : @0 };
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/self", conversationID];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPUT apiVersion:0];
    
    // THEN
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertNotNil(response);
        XCTAssertEqual(response.HTTPStatus, 200);
        XCTAssertEqualObjects(response.payload, nil);
        XCTAssertFalse(conversation.otrArchived);
        XCTAssertEqualObjects(conversation.otrArchivedRef, archivedTime.transportString);
    }];
    
}

- (void)testThatItSetsMutedOnTheConversationWhenAsked
{
    // GIVEN
    __block MockConversation *conversation;
    __block NSString *conversationID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session insertSelfUserWithName:@"Me Myself"];
        conversation = [session insertSelfConversationWithSelfUser:self.sut.selfUser];
        conversationID = conversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDate *mutedTime = [[NSDate date] dateByAddingTimeInterval:-50];
    NSDictionary *payload = @{ @"otr_muted_ref":  mutedTime.transportString,
                               @"otr_muted" : @1 };
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/self", conversationID];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPUT apiVersion:0];
    
    // THEN
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertNotNil(response);
        XCTAssertEqual(response.HTTPStatus, 200);
        XCTAssertEqualObjects(response.payload, nil);
        XCTAssertTrue(conversation.otrMuted);
        XCTAssertEqualObjects(conversation.otrMutedRef, mutedTime.transportString);
    }];
    
}

- (void)testThatItUnsetsMutedOnTheConversationWhenAsked
{
    // GIVEN
    __block MockConversation *conversation;
    __block NSString *conversationID;
    NSDate *mutedDate = [NSDate date];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session insertSelfUserWithName:@"Me Myself"];
        conversation = [session insertSelfConversationWithSelfUser:self.sut.selfUser];
        conversationID = conversation.identifier;
        conversation.otrMuted = YES;
        conversation.otrMutedRef = mutedDate.transportString;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{ @"otr_muted_ref":  mutedDate.transportString,
                               @"otr_muted" : @0 };
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/self", conversationID];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:path method:ZMMethodPUT apiVersion:0];
    
    // THEN
    [self.sut.managedObjectContext performBlockAndWait:^{
        XCTAssertNotNil(response);
        XCTAssertEqual(response.HTTPStatus, 200);
        XCTAssertEqualObjects(response.payload, nil);
        XCTAssertFalse(conversation.otrMuted);
        XCTAssertEqualObjects(conversation.otrMutedRef, mutedDate.transportString);
    }];
    
}

@end
