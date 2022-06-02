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


#import "ModelObjectsTests.h"

#import "ZMManagedObject+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMMessage+Internal.h"



@interface CoreDataRelationshipsTests : ModelObjectsTests
@end



@implementation CoreDataRelationshipsTests

- (void)testModelledRelationships;
{
    // Create objects:
    
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    ZMClientMessage *message1 = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message1.serverTimestamp = [NSDate date];
    ZMClientMessage *message2 = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message2.serverTimestamp = [NSDate date];
    ZMClientMessage *message3 = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message3.serverTimestamp = [NSDate date];
    
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    ZMConnection *connection1 = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection2 = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // Create relationships:
    
    [conversation1.mutableMessages addObjectsFromArray:@[message1, message2]];
    [conversation2.mutableMessages addObject:message3];
    
    connection1.conversation = conversation1;
    conversation2.connection = connection2;
    
    connection1.to = user1;
    user2.connection = connection2;
    
    conversation1.creator = user1;
    conversation2.creator = user2;
    
    [conversation1 addParticipantAndUpdateConversationStateWithUser:user1 role:nil];
    [conversation1 addParticipantAndUpdateConversationStateWithUser:user3 role:nil];
    
    [conversation2 addParticipantAndUpdateConversationStateWithUser:user2 role:nil];
    [conversation2 addParticipantAndUpdateConversationStateWithUser:user3 role:nil];
    
    // Check that the inverse have been set:
    [self.uiMOC processPendingChanges];
    
    XCTAssertEqual(message1.conversationLike, conversation1);
    XCTAssertEqual(message2.conversationLike, conversation1);
    XCTAssertEqual(message3.conversationLike, conversation2);
    
    XCTAssertEqual(conversation1.connection, connection1);
    XCTAssertEqual(connection2.conversation, conversation2);
    
    XCTAssertEqual(user1.connection, connection1);
    XCTAssertEqual(connection2.to, user2);
    
    XCTAssertTrue([[user1 valueForKey:@"conversationsCreated"] containsObject:conversation1]);
    XCTAssertTrue([[user2 valueForKey:@"conversationsCreated"] containsObject:conversation2]);
    
    id s1 = [NSSet setWithArray:@[user1, user3]];
    XCTAssertEqualObjects(conversation1.localParticipants, s1);
    id s2 = [NSSet setWithArray:@[user2, user3]];
    XCTAssertEqualObjects(conversation2.localParticipants, s2);
    
    XCTAssertEqualObjects(user1.conversations, [NSSet setWithObject:conversation1]);
    XCTAssertEqualObjects(user2.conversations, [NSSet setWithObject:conversation2]);
    id ac = [NSSet setWithArray:@[conversation1, conversation2]];
    XCTAssertEqualObjects(user3.conversations, ac);

    __block NSError *error = nil;
    XCTAssertTrue([self.uiMOC save:&error], @"Save failed: %@", error);
    [NSThread sleepForTimeInterval:0.5];

    // Save and check that relationships can be traversed in the other context:
    
    [self.syncMOC performBlockAndWait:^{
        ZMConversation *c2Conversation1 = (id) [self.syncMOC existingObjectWithID:conversation1.objectID error:&error];
        XCTAssertEqualObjects(c2Conversation1.objectID, conversation1.objectID, @"Failed to read in 2nd context: %@", error);
        
        ZMConversation *c2Conversation2 = (id) [self.syncMOC existingObjectWithID:conversation2.objectID error:&error];
        XCTAssertEqualObjects(c2Conversation2.objectID, conversation2.objectID, @"Failed to read in 2nd context: %@", error);
        
        NSArray *c2Messages1 = [c2Conversation1 lastMessagesWithLimit:10];
        XCTAssertEqual(c2Messages1.count, (NSUInteger) 2);
        NSArray *c2Messages2 = [c2Conversation2 lastMessagesWithLimit:10];
        XCTAssertEqual(c2Messages2.count, (NSUInteger) 1);
        ZMTextMessage *c2Message1 = c2Messages1[1];
        ZMTextMessage *c2Message2 = c2Messages1[0];
        ZMTextMessage *c2Message3 = c2Messages2[0];
        XCTAssertEqualObjects(c2Message1.objectID, message1.objectID);
        XCTAssertEqualObjects(c2Message2.objectID, message2.objectID);
        XCTAssertEqualObjects(c2Message3.objectID, message3.objectID);
        
        XCTAssertEqual(c2Message1.conversationLike, c2Conversation1);
        XCTAssertEqual(c2Message2.conversationLike, c2Conversation1);
        XCTAssertEqual(c2Message3.conversationLike, c2Conversation2);
        
        ZMUser *c2User1 = c2Conversation1.creator;
        XCTAssertEqualObjects(c2User1.objectID, user1.objectID);
        ZMUser *c2User2 = c2Conversation2.creator;
        XCTAssertEqualObjects(c2User2.objectID, user2.objectID);
    }];
}

@end
