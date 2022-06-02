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


#import "ZMConversationTests.h"
#import "ZMConversationList+Internal.h"


@interface ZMConversationGapsAndWindowTests : ZMConversationTestsBase
@end

@implementation ZMConversationGapsAndWindowTests



- (void)testThatItInsertsANewConversationInUserSession
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    
    // when
    ZMConversation *conversation = [ZMConversation insertGroupConversationWithSession:self.coreDataStack
                                                                         participants:@[user1, user2, user3]
                                                                                 name:NULL
                                                                                 team:NULL
                                                                          allowGuests:YES
                                                                        allowServices:YES
                                                                         readReceipts:NO
                                                                     participantsRole:nil];
    
    // then
    NSFetchRequest *fetchRequest = [ZMConversation sortedFetchRequest];
    NSArray *conversations = [self.uiMOC executeFetchRequestOrAssert:fetchRequest];
    
    XCTAssertEqual(conversations.count, 1u);
    ZMConversation *fetchedConversation = conversations[0];
    XCTAssertEqual(fetchedConversation.conversationType, ZMConversationTypeGroup);
    XCTAssertEqualObjects(conversation.objectID, fetchedConversation.objectID);
    
    NSSet *expectedParticipants = [NSSet setWithObjects:user1, user2, user3, selfUser, nil];
    XCTAssertEqualObjects(expectedParticipants, conversation.localParticipants);
    
}


- (void)testThatItReturnsTheListOfAllConversationsInTheUserSession;
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.conversationType = ZMConversationTypeOneOnOne;
    [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]; // this is used to make sure it doesn't return all objects
    
    [self.uiMOC processPendingChanges];
    
    // when
    NSArray *fetchedConversations = [ZMConversationList conversationsInUserSession:self.coreDataStack];
    
    // then
    XCTAssertNotNil(fetchedConversations);
    XCTAssertEqual(1u, fetchedConversations.count);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation1], (NSUInteger) NSNotFound);
}


- (void)testThatItReturnsTheListOfAllincomingConnectionConversationsConnectionsInTheUserSession;
{
    // given
    ZMConversation *nonPendingConnectionConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    nonPendingConnectionConversation.conversationType = ZMConversationTypeOneOnOne;
    ZMConnection *nonPendingConnection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    nonPendingConnection.status = ZMConnectionStatusAccepted;
    nonPendingConnection.conversation = nonPendingConnectionConversation;
    
    ZMConversation *pendingConnectionConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    pendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    ZMConnection *pendingConnection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    pendingConnection.status = ZMConnectionStatusPending;
    pendingConnection.conversation = pendingConnectionConversation;

    [self.uiMOC processPendingChanges];
    
    // when
    NSArray *fetchedConversations = [ZMConversationList pendingConnectionConversationsInUserSession:self.coreDataStack];
    
    // then
    XCTAssertNotNil(fetchedConversations);
    XCTAssertEqual(1u, fetchedConversations.count);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:pendingConnectionConversation], (NSUInteger) NSNotFound);
}


- (void)testThatItReturnsTheListOfAllConversationWithoutASave
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.userDefinedName = @"Foo++";
    conversation1.conversationType = ZMConversationTypeOneOnOne;
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.userDefinedName = @"Bar--";
    conversation2.conversationType = ZMConversationTypeGroup;
    
    [self.uiMOC processPendingChanges];

    // when
    NSArray *fetchedConversations = [ZMConversationList conversationsIncludingArchivedInUserSession:self.coreDataStack];
    
    // then
    XCTAssertNotNil(fetchedConversations);
    XCTAssertEqual(2u, fetchedConversations.count);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation1], (NSUInteger) NSNotFound);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation2], (NSUInteger) NSNotFound);
}

- (void)testThatItReturnsTheListOfAllConversationWithASave
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.userDefinedName = @"Foo++";
    conversation1.conversationType = ZMConversationTypeOneOnOne;
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.userDefinedName = @"Bar--";
    conversation2.conversationType = ZMConversationTypeGroup;
    
    XCTAssertTrue([self.uiMOC saveOrRollback]);

    // when
    NSArray *fetchedConversations = [ZMConversationList conversationsIncludingArchivedInUserSession:self.coreDataStack];
    
    // then
    XCTAssertNotNil(fetchedConversations);
    XCTAssertEqual(2u, fetchedConversations.count);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation1], (NSUInteger) NSNotFound);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation2], (NSUInteger) NSNotFound);
}

- (void)testThatHasDraftMessageTextReturnsNOWhenEmpty;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.draftMessage = [[DraftMessage alloc] initWithText:@"" mentions:@[] quote:nil];
    
    // then
    XCTAssertFalse(conversation.hasDraftMessage);
    
    // when
    conversation.draftMessage = nil;
    
    // then
    XCTAssertFalse(conversation.hasDraftMessage);
}

- (void)testThatHasDraftMessageTextReturnsYESWhenNotEmpty;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.draftMessage = [[DraftMessage alloc] initWithText:@"A" mentions:@[] quote:nil];
    
    // then
    XCTAssertTrue(conversation.hasDraftMessage);
    
    // when
    conversation.draftMessage =[[DraftMessage alloc] initWithText: @"Once upon a time" mentions:@[] quote:nil];
    
    // then
    XCTAssertTrue(conversation.hasDraftMessage);
}

- (void)testThatTheConversationIsNotArchivedByDefault
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // then
    XCTAssertFalse(conversation.isArchived);
}


@end


