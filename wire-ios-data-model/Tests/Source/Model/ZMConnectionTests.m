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

#import "ModelObjectsTests.h"

#import "ZMUser+Internal.h"
#import "ZMConnection+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMManagedObject+Internal.h"
#import "ZMConnection+Helper.h"


@interface ZMConnection(Testing)

+ (instancetype)insertNewPendingConnectionFromUser:(ZMUser *)user;

@end

@implementation ZMConnection(Testing)

+ (instancetype)insertNewPendingConnectionFromUser:(ZMUser *)user
{
    VerifyReturnValue(user.connection == nil, user.connection);
    RequireString(user != nil, "Can not create a connection to <nil> user.");
    ZMConnection *connection = [self insertNewObjectInManagedObjectContext:user.managedObjectContext];
    connection.to = user;
    connection.lastUpdateDate = [NSDate date];
    connection.status = ZMConnectionStatusPending;
    connection.conversation = [ZMConversation insertNewObjectInManagedObjectContext:user.managedObjectContext];
    [connection.conversation addParticipantAndUpdateConversationStateWithUser:user role:nil];
    connection.conversation.creator = [ZMUser selfUserInContext:user.managedObjectContext];
    connection.conversation.conversationType = ZMConversationTypeConnection;
    connection.conversation.lastModifiedDate = connection.lastUpdateDate;
    return connection;
}

@end


@interface ZMConnectionTests : ModelObjectsTests
@end


@implementation ZMConnectionTests

- (void)testThatWeCanSetAttributesOnConnection
{
    [self checkConnectionAttributeForKey:@"status" value:@(ZMConnectionStatusAccepted)];
    [self checkConnectionAttributeForKey:@"lastUpdateDate" value:[NSDate dateWithTimeIntervalSince1970:123456789]];
    [self checkConnectionAttributeForKey:@"message" value:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit."];
}

- (void)checkConnectionAttributeForKey:(NSString *)key value:(id)value;
{
    [self checkAttributeForClass:[ZMConnection class] key:key value:value];
}

- (void)testStatusFromString
{
    XCTAssertEqual([ZMConnection statusFromString:@"accepted"], ZMConnectionStatusAccepted);
    XCTAssertEqual([ZMConnection statusFromString:@"pending"], ZMConnectionStatusPending);
    XCTAssertEqual([ZMConnection statusFromString:@"foo"], ZMConnectionStatusInvalid);
    XCTAssertEqual([ZMConnection statusFromString:@""], ZMConnectionStatusInvalid);
    XCTAssertEqual([ZMConnection statusFromString:nil], ZMConnectionStatusInvalid);
}

- (void)testThatTheMessageTextIsCopied
{
    // given
    NSString *originalValue = @"will@foo.co";
    NSMutableString *mutableValue = [originalValue mutableCopy];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    connection.message = mutableValue;
    [mutableValue appendString:@".uk"];
    
    // then
    XCTAssertEqualObjects(connection.message, originalValue);
}

- (void)testThatItReturnsTheListOfAllConnections;
{
    // given
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]; // this is used to make sure it doesn't return all objects
    [self.uiMOC processPendingChanges];
    
    // when
    NSArray *fetchedConnections = [ZMConnection connectionsInManagedObjectContext:self.uiMOC];
    
    // then
    XCTAssertNotNil(fetchedConnections);
    XCTAssertEqual(1u, fetchedConnections.count);
    XCTAssertNotEqual([fetchedConnections indexOfObjectIdenticalTo:connection], (NSUInteger) NSNotFound);
}

- (void)testThatAcceptingAConnectionMarksTheUserAsNeedingToBeUpdated;
{
    // given
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to.remoteIdentifier = [NSUUID createUUID];
        connection.to.needsToBeUpdatedFromBackend = NO;
        connection.status = ZMConnectionStatusPending;
        
        [self.syncMOC saveOrRollback];
        moid = connection.objectID;
    }];
    
    // when
    ZMConnection *connection = (id) [self.uiMOC objectWithID:moid];
    connection.status = ZMConnectionStatusAccepted;
    
    // then
    XCTAssertNotNil(connection.to);
    XCTAssertTrue(connection.to.needsToBeUpdatedFromBackend);
}

- (void)testThatAcceptingAConnectionUnarchivesTheConversation;
{
    // given
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.isArchived = YES;

        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to.remoteIdentifier = [NSUUID createUUID];
        connection.conversation = conversation;
        connection.status = ZMConnectionStatusPending;

        [self.syncMOC saveOrRollback];
        moid = connection.objectID;
    }];

    // when
    ZMConnection *connection = (id) [self.uiMOC objectWithID:moid];
    connection.status = ZMConnectionStatusAccepted;

    // then
    XCTAssertNotNil(connection.conversation);
    XCTAssertFalse(connection.conversation.isArchived);
}

- (void)testThatCancellingAConnectionDeletesTheUserRelationship;
{
    // given
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to.remoteIdentifier = [NSUUID createUUID];
        connection.conversation = conversation;
        connection.status = ZMConnectionStatusSent;

        [self.syncMOC saveOrRollback];
        moid = connection.objectID;
    }];

    // when
    ZMConnection *connection = (id) [self.uiMOC objectWithID:moid];
    connection.status = ZMConnectionStatusCancelled;

    // then
    XCTAssertNil(connection.to);
}

- (void)testThatChangingTheStatusUpdatesTheConversationType
{
    [self assertConversationType:ZMConversationTypeOneOnOne afterUpdatingConnectionStatus:ZMConnectionStatusAccepted];

    [self assertConversationType:ZMConversationTypeOneOnOne afterUpdatingConnectionStatus:ZMConnectionStatusBlocked];

    [self assertConversationType:ZMConversationTypeConnection afterUpdatingConnectionStatus:ZMConnectionStatusPending];

    [self assertConversationType:ZMConversationTypeConnection afterUpdatingConnectionStatus:ZMConnectionStatusSent];

    [self assertConversationType:ZMConversationTypeConnection afterUpdatingConnectionStatus:ZMConnectionStatusIgnored];

    [self assertConversationType:ZMConversationTypeInvalid afterUpdatingConnectionStatus:ZMConnectionStatusCancelled];
}

- (void)testThatChangingTheStatusNotifiesSearchDirectory
{
    // given
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to.remoteIdentifier = [NSUUID createUUID];
        connection.to.needsToBeUpdatedFromBackend = NO;
        connection.status = ZMConnectionStatusPending;
        
        [self.syncMOC saveOrRollback];
        moid = connection.objectID;
    }];
    
    
    // expect
    XCTestExpectation *expectation = [self expectationWithDescription:@"Notified"];
    id token = [NotificationInContext addObserverWithName:ZMConnection.invalidateTopConversationCacheNotificationName
                                       context:self.uiMOC.notificationContext
                                        object:nil
                                         queue:nil using:^(NotificationInContext * note __unused) {
                                             [expectation fulfill];
                                         }];
    
    // when
    ZMConnection *connection = (id) [self.uiMOC objectWithID:moid];
    connection.status = ZMConnectionStatusAccepted;

    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.2]);
    token = nil;
}

- (void)testThatItDoesNotCreateANewSentConnectionToAUserThatAlreadyHasAConnection;
{
    // given
    __block NSManagedObjectID *userMOID;
    __block NSManagedObjectID *connectionMOID;
    __block NSManagedObjectID *conversationMOID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];
        selfUser.name = @"Neal Stephenson";
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"John";
        user.remoteIdentifier = [NSUUID createUUID];
        user.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        user.connection.conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        XCTAssert([self.syncMOC saveOrRollback]);
        userMOID = user.objectID;
        connectionMOID = user.connection.objectID;
        conversationMOID = user.connection.conversation.objectID;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    ZMUser *user = (id) [self.uiMOC objectWithID:userMOID];
    
    // when
    __block ZMConnection *connection;
    [self performIgnoringZMLogError:^{
        connection = [ZMConnection insertNewSentConnectionToUser:user];
    }];
    XCTAssertFalse(connection.hasChanges);
    XCTAssertNotNil(connection);
    XCTAssertEqualObjects(connection.objectID, connectionMOID);
    XCTAssertNotNil(connection.conversation);
    XCTAssertEqualObjects(connection.conversation.objectID, conversationMOID);
}

// MARK: - Helpers

- (void)assertConversationType:(ZMConversationType)conversationType
 afterUpdatingConnectionStatus:(ZMConnectionStatus)status
{
    // given
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to.remoteIdentifier = [NSUUID createUUID];
        connection.conversation = conversation;
        connection.status = ZMConnectionStatusSent;

        [self.syncMOC saveOrRollback];
        moid = connection.objectID;
    }];

    // when
    ZMConnection *connection = (id) [self.uiMOC objectWithID:moid];
    connection.status = status;

    // then
    XCTAssertEqual(connection.conversation.conversationType, conversationType);
}

@end
