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

@interface MockTransportSessionConnectionsTests : MockTransportSessionTests

@end

@implementation MockTransportSessionConnectionsTests

- (void)testThatWeCanCreateAndRequestConnections;
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    
    __block MockConnection *connection1;
    __block MockConnection *connection2;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        [session addProfilePictureToUser:selfUser];
        user1 = [session insertUserWithName:@"Bar"];
        user2 = [session insertUserWithName:@"Baz"];
        
        connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        connection2 = [session insertConnectionWithSelfUser:selfUser toUser:user2];
        connection2.status = @"accepted";
        connection2.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399905742.921];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/connections" method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if(!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload.asDictionary[@"connections"] isKindOfClass:[NSArray class]]);
    NSArray *data = (NSArray *) response.payload.asDictionary[@"connections"];
    XCTAssertEqual(data.count, (NSUInteger) 2);
    
    [self checkThatTransportData:data[0] matchesConnection:connection2];
    [self checkThatTransportData:data[1] matchesConnection:connection1];
}


- (void)testThatWeCanPostAConnection
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    NSUUID *user1Identifier = [NSUUID createUUID];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        [session addProfilePictureToUser:selfUser];
        user1 = [session insertUserWithName:@"Bar"];
        user1.identifier = user1Identifier.transportString;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSString *message = @"Hello, World!";
    
    // WHEN
    NSDictionary *payload = @{
                              @"user": user1Identifier.transportString,
                              @"name": @"",
                              @"message": message
                              };
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/connections" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 201);
    __block NSDictionary *expectedPayload;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertEqual(user1.connectionsTo.count, 1u);
        MockConnection *firstConnection = [user1.connectionsTo firstObject];
        XCTAssertEqualObjects(firstConnection.to, user1);
        XCTAssertEqualObjects(firstConnection.from, selfUser);
        XCTAssertEqualObjects(firstConnection.message, message);
        XCTAssertEqualObjects(firstConnection.status, @"sent");
        expectedPayload = [firstConnection.transportData asDictionary];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqualObjects(response.payload, expectedPayload);
}


- (void)testThatPostingAConnectionCreatesAConversation
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    NSUUID *user1Identifier = [NSUUID createUUID];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        [session addProfilePictureToUser:selfUser];
        user1 = [session insertUserWithName:@"Bar"];
        user1.identifier = user1Identifier.transportString;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSDictionary *payload = @{
                              @"user": user1Identifier.transportString,
                              @"name": @"",
                              @"message": @""
                              };
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/connections" method:ZMMethodPOST apiVersion:0];
    
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 201);
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertEqual(user1.connectionsTo.count, 1u);
        MockConnection *firstConnection = [user1.connectionsTo firstObject];
        MockConversation *conversation = firstConnection.conversation;
        
        XCTAssertNotNil(conversation);
        XCTAssertEqualObjects(conversation.activeUsers, [NSOrderedSet orderedSetWithObject:selfUser]);
        XCTAssertEqual(conversation.type, ZMTConversationTypeConnection);
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatCanNotChangeConnectionFromCancelledToSent
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    NSUUID *user1Identifier = [NSUUID createUUID];
    __block MockConversation *conversation;
    __block MockConnection *connection;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        [session addProfilePictureToUser:selfUser];
        user1 = [session insertUserWithName:@"Bar"];
        user1.identifier = user1Identifier.transportString;
        [session createConnectionRequestFromUser:selfUser toUser:user1 message:@"message"];
        connection = [user1.connectionsTo firstObject];
        conversation = connection.conversation;
        connection.status = @"cancelled";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{
                              @"status": @"sent"
                              };
    ZMTransportResponse *response = [self responseForPayload:payload path:[NSString stringWithFormat:@"/connections/%@", connection.to.identifier] method:ZMMethodPUT apiVersion:0];
    XCTAssertEqual(response.HTTPStatus, 403);
}

- (void)testThatResendingACancelledConnectionDoesNotCreateConversation
{
    // GIVEN
    __block MockUser *selfUser;
    __block MockUser *user1;
    NSUUID *user1Identifier = [NSUUID createUUID];
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        [session addProfilePictureToUser:selfUser];
        user1 = [session insertUserWithName:@"Bar"];
        user1.identifier = user1Identifier.transportString;
        [session createConnectionRequestFromUser:selfUser toUser:user1 message:@"message"];
        MockConnection *connection = [user1.connectionsTo firstObject];
        conversation = connection.conversation;
        connection.status = @"cancelled";
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // WHEN
    NSDictionary *payload = @{
                              @"user": user1Identifier.transportString,
                              @"name": @"",
                              @"message": @""
                              };
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/connections" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 201);
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertEqual(user1.connectionsTo.count, 1u); // new connection should not be created after resending
        MockConnection *connection = [user1.connectionsTo lastObject];
        XCTAssertEqualObjects(connection.status, @"sent");
        XCTAssertEqualObjects(connection.conversation, conversation);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatCreatesANewConnectionWhenRequested
{
    // GIVEN
    NSUUID *userID = [NSUUID createUUID];
    NSUUID *selfUserID = [NSUUID createUUID];
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"Tom"];
        selfUser.identifier = selfUserID.transportString;
        
        MockUser *user = [session insertUserWithName:@"John"];
        user.identifier = userID.transportString;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{
                              @"user" : userID.transportString,
                              @"name" : @"John",
                              @"message" : @"Wassup"
                              };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/connections" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.result, ZMTransportResponseStatusSuccess);
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        NSFetchRequest *fetchRequest = [MockConnection sortedFetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"to.identifier == %@", userID.transportString];
        
        NSArray* result = [self.sut.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        XCTAssertEqual(result.count, 1u);
        
        MockConnection *connection = result.firstObject;
        XCTAssertEqualObjects(connection.to.identifier, userID.transportString);
        XCTAssertEqualObjects(connection.from.identifier, selfUserID.transportString);
        XCTAssertEqualObjects(connection.message, payload[@"message"]);
        XCTAssertEqualObjects(connection.status, @"sent");
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}


@end
