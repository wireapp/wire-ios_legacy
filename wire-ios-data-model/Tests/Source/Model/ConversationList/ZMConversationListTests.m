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

#import "ZMBaseManagedObjectTest.h"
#import "ZMConversationList+Internal.h"
#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConnection+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMMessage+Internal.h"
#import "WireDataModelTests-Swift.h"


@interface ZMConversationListTests : ZMBaseManagedObjectTest
@property (nonatomic) NotificationDispatcher *dispatcher;
@end



@implementation ZMConversationListTests

- (void)setUp {
    [super setUp];
    self.dispatcher = [[NotificationDispatcher alloc] initWithManagedObjectContext:self.uiMOC];
}

- (void)tearDown {
    [self.dispatcher tearDown];
    self.dispatcher = nil;
    [super tearDown];
}
- (void)testThatItDoesNotReturnTheSelfConversation;
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeSelf;
    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeOneOnOne;
    ZMConversation *c3 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c3.conversationType = ZMConversationTypeGroup;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    NSArray *list = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(list.count, 2u);
    NSArray *expected = @[c2, c3];
    AssertArraysContainsSameObjects(list, expected);
}

- (void)testThatItReturnsAllConversations
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeGroup;
    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeOneOnOne;
    ZMConversation *c3 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c3.conversationType = ZMConversationTypeGroup;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    NSArray *list = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(list.count, 3u);
    NSArray *expected = @[c1, c2, c3];
    AssertArraysContainsSameObjects(list, expected);
}

- (void)testThatItReturnsAllArchivedConversations
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeGroup;
    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeOneOnOne;
    ZMConversation *c3 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c3.conversationType = ZMConversationTypeGroup;
    c3.isArchived = YES;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    NSArray *list = [ZMConversation archivedConversationsInContext:self.uiMOC];
    XCTAssertEqual(list.count, 1u);
    NSArray *expected = @[c3];
    AssertArraysContainsSameObjects(list, expected);
}

- (void)testThatItDoesNotReturnIgnoredConnections
{
    // given
    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeConnection;
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.conversation = c2;
    connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusIgnored;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    NSArray *list = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(list.count, 0u);
}

- (void)testThatItReturnsAllUnarchivedConversations
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeGroup;
    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeOneOnOne;
    ZMConversation *c3 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c3.conversationType = ZMConversationTypeGroup;
    c3.isArchived = YES;
    ZMConversation *c4 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c4.conversationType = ZMConversationTypeOneOnOne;
    c4.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    c4.connection.status = ZMConnectionStatusBlocked;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    NSArray *list = [ZMConversation conversationsExcludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(list.count, 2u);
    NSArray *expected = @[c1, c2];
    AssertArraysContainsSameObjects(list, expected);
}

- (void)testThatItReturnsConversationsSorted
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeGroup;
    c1.lastModifiedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:417000000];
    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeOneOnOne;
    c2.lastModifiedDate = [c1.lastModifiedDate dateByAddingTimeInterval:10];
    ZMConversation *c3 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c3.conversationType = ZMConversationTypeGroup;
    c3.lastModifiedDate = [c1.lastModifiedDate dateByAddingTimeInterval:-10];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    NSArray *list = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(list.count, 3u);
    NSArray *expected = @[c2, c1, c3];
    XCTAssertEqualObjects(list, expected);
}

- (void)testThatItRecreatesListsAndTokens
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeGroup;
    c1.lastModifiedDate = [[NSDate date] dateByAddingTimeInterval:10];
    
    NSArray *list = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    ConversationListChangeObserver *obs = [[ConversationListChangeObserver alloc] initWithConversationList:(ZMConversationList *)list managedObjectContext:self.uiMOC];
    ZMConversation *c2;
    
    // when
    // conversation is inserted while the app is in the background
    {
        [self.dispatcher applicationDidEnterBackground];
        c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
        c2.conversationType = ZMConversationTypeGroup;
        c2.lastModifiedDate = [c1.lastModifiedDate dateByAddingTimeInterval:-20];
        XCTAssert([self.uiMOC saveOrRollback]);
        WaitForAllGroupsToBeEmpty(0.5);
        
        // then changes are not forwarded
        NSArray *expected = @[c1];
        XCTAssertEqualObjects(list, expected);
        XCTAssertEqual(obs.notifications.count, 0u);
    }
    // and when
    // refresh list and observer token
    {
        NSArray *allConversations = @[c1,c2];
        [(ZMConversationList*)list recreateWithAllConversations:allConversations];
        
        // then list is updated
        NSArray *expected = @[c1, c2];
        XCTAssertEqualObjects(list, expected);
    }
    // and when
    // forward accumulated changes
    {
        [self.dispatcher applicationWillEnterForeground];
        WaitForAllGroupsToBeEmpty(0.5);
        
        // then the updated snapshot prevents outdated list change notifications
        XCTAssertEqual(obs.notifications.count, 0u);
        NSArray *expected = @[c1, c2];
        XCTAssertEqualObjects(list, expected);
    }
}

- (void)testThatItUpdatesWhenNewConversationsAreInserted
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeGroup;
    c1.userDefinedName = @"c1";
    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeOneOnOne;
    c2.userDefinedName = @"c2";
    ZMConversation *c3 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c3.conversationType = ZMConversationTypeGroup;
    c3.userDefinedName = @"c3";
    XCTAssert([self.uiMOC saveOrRollback]);

    // then
    ZMConversationList *list = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(list.count, 3u);
    NSArray *expected = @[c1, c2, c3];
    AssertArraysContainsSameObjects(list, expected);
    
    // when
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:list managedObjectContext:self.uiMOC];
    
    ZMConversation *c4 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c4.conversationType = ZMConversationTypeGroup;
    XCTAssert([self.uiMOC saveOrRollback]);

    // then
    XCTAssertEqual(list.count, 4u);
    expected = @[c1, c2, c3, c4];
    AssertArraysContainsSameObjects(list, expected);
    (void)observer;
}

- (void)testThatItUpdatesWhenNewConversationLastModifiedChangesThroughTheNotificationDispatcher
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeGroup;
    c1.lastModifiedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:417000000];
    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeOneOnOne;
    c2.lastModifiedDate = [c1.lastModifiedDate dateByAddingTimeInterval:10];
    ZMConversation *c3 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c3.conversationType = ZMConversationTypeGroup;
    c3.lastModifiedDate = [c1.lastModifiedDate dateByAddingTimeInterval:-10];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    ZMConversationList *list = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(list.count, 3u);
    NSArray *expected = @[c2, c1, c3];
    XCTAssertEqualObjects(list, expected);
   
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:list managedObjectContext:self.uiMOC];
    
    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    
    c3.lastModifiedDate = [c1.lastModifiedDate dateByAddingTimeInterval:20];
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqual(list.count, 3u);
    expected = @[c3, c2, c1];
    XCTAssertEqualObjects(list, expected);
    (void)observer;
}

- (void)testThatItUpdatesWhenNewConnectionIsIgnored;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.lastModifiedDate = [NSDate date];
    conversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.status = ZMConnectionStatusPending;
    conversation.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);

    
    // then
    ZMConversationList *list = [ZMConversation pendingConversationsInContext:self.uiMOC];
    XCTAssertEqual(list.count, 1u);
    NSArray *expected = @[conversation];
    XCTAssertEqualObjects(list, expected);
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:list managedObjectContext:self.uiMOC];

    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    
    conversation.connection.status = ZMConnectionStatusIgnored;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqual(list.count, 0u);
    XCTAssertEqualObjects(list, @[]);
    (void)observer;
}

- (void)testThatItUpdatesWhenNewConnectionIsCancelled;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.lastModifiedDate = [NSDate date];
    conversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.status = ZMConnectionStatusSent;
    conversation.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    ZMConversationList *list = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(list.count, 1u);
    NSArray *expected = @[conversation];
    XCTAssertEqualObjects(list, expected);
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:list managedObjectContext:self.uiMOC];
    
    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    
    conversation.connection.status = ZMConnectionStatusIgnored;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqual(list.count, 0u);
    XCTAssertEqualObjects(list, @[]);
    (void)observer;
}

- (void)testThatItUpdatesWhenNewConnectionIsAccepted;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.lastModifiedDate = [NSDate date];
    conversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.status = ZMConnectionStatusPending;
    conversation.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    ZMConversationList *normalList = [ZMConversation conversationsExcludingArchivedInContext:self.uiMOC];
    ZMConversationList *pendingList = [ZMConversation pendingConversationsInContext:self.uiMOC];
    XCTAssertEqual(normalList.count, 0u);
    XCTAssertEqualObjects(normalList, @[]);
    XCTAssertEqual(pendingList.count, 1u);
    XCTAssertEqualObjects(pendingList, @[conversation]);
    
    ConversationListChangeObserver *normalObserver = [[ConversationListChangeObserver alloc] initWithConversationList:normalList managedObjectContext:self.uiMOC];
    ConversationListChangeObserver *pendingObserver = [[ConversationListChangeObserver alloc] initWithConversationList:pendingList managedObjectContext:self.uiMOC];

    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.connection.status = ZMConnectionStatusAccepted;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqual(normalList.count, 1u);
    XCTAssertEqualObjects(normalList, @[conversation]);
    XCTAssertEqual(pendingList.count, 0u);
    XCTAssertEqualObjects(pendingList, @[]);
    (void)normalObserver;
    (void)pendingObserver;
}

- (void)testThatItUpdatesWhenNewAUserIsUnblocked;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.lastModifiedDate = [NSDate date];
    conversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.status = ZMConnectionStatusBlocked;
    conversation.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);

    // then
    ZMConversationList *normalList = [ZMConversation conversationsExcludingArchivedInContext:self.uiMOC];
    XCTAssertEqual(normalList.count, 0u);
    XCTAssertEqualObjects(normalList, @[]);

    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:normalList managedObjectContext:self.uiMOC];
    
    // when
    conversation.connection.status = ZMConnectionStatusAccepted;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqual(normalList.count, 1u);
    XCTAssertEqualObjects(normalList, @[conversation]);
    (void)observer;
}

- (void)testThatItUpdatesWhenTwoNewConnectionsAreAccepted;
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.conversationType = ZMConversationTypeConnection;
    conversation1.lastModifiedDate = [NSDate date];
    conversation1.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.connection.status = ZMConnectionStatusPending;
    conversation1.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.conversationType = ZMConversationTypeConnection;
    conversation2.lastModifiedDate = [NSDate date];
    conversation2.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.connection.status = ZMConnectionStatusPending;
    conversation2.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    ZMConversationList *normalList = [ZMConversation conversationsExcludingArchivedInContext:self.uiMOC];
    ZMConversationList *pendingList = [ZMConversation pendingConversationsInContext:self.uiMOC];
    NSArray *conversations = @[conversation2, conversation1];
    XCTAssertEqual(normalList.count, 0u);
    XCTAssertEqualObjects(normalList, @[]);
    XCTAssertEqual(pendingList.count, 2u);
    XCTAssertEqualObjects(pendingList, conversations);
    
    ConversationListChangeObserver *normalObserver = [[ConversationListChangeObserver alloc] initWithConversationList:normalList managedObjectContext:self.uiMOC];
    ConversationListChangeObserver *pendingObserver =[[ConversationListChangeObserver alloc] initWithConversationList:pendingList managedObjectContext:self.uiMOC];

    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    
    conversation1.conversationType = ZMConversationTypeOneOnOne;
    conversation1.connection.status = ZMConnectionStatusAccepted;
    conversation2.conversationType = ZMConversationTypeOneOnOne;
    conversation2.connection.status = ZMConnectionStatusAccepted;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqual(normalList.count, 2u);
    XCTAssertEqualObjects(normalList, conversations);
    XCTAssertEqual(pendingList.count, 0u);
    XCTAssertEqualObjects(pendingList, @[]);
    (void)normalObserver;
    (void)pendingObserver;
}


- (void)testThatItUpdatesWhenNewAConversationIsArchived;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.lastModifiedDate = [NSDate date];
    conversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.status = ZMConnectionStatusAccepted;
    conversation.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    ZMConversationList *normalList = [ZMConversation conversationsExcludingArchivedInContext:self.uiMOC];
    ZMConversationList *archivedList = [ZMConversation archivedConversationsInContext:self.uiMOC];
    XCTAssertEqual(normalList.count, 1u);
    XCTAssertEqualObjects(normalList, @[conversation]);
    XCTAssertEqual(archivedList.count, 0u);
    XCTAssertEqualObjects(archivedList, @[]);
    
    ConversationListChangeObserver *normalObserver = [[ConversationListChangeObserver alloc] initWithConversationList:normalList managedObjectContext:self.uiMOC];
    ConversationListChangeObserver *archivedObserver =[[ConversationListChangeObserver alloc] initWithConversationList:archivedList managedObjectContext:self.uiMOC];

    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    conversation.isArchived = YES;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertTrue(conversation.isArchived);
    XCTAssertEqual(normalList.count, 0u);
    XCTAssertEqualObjects(normalList, @[]);
    XCTAssertEqual(archivedList.count, 1u);
    XCTAssertEqualObjects(archivedList, @[conversation]);
    (void)normalObserver;
    (void)archivedObserver;
}

- (void)testThatClearingConversationMovesItToClearedList
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeOneOnOne;
    c1.lastModifiedDate = [NSDate date];
    ZMMessage *message = (id)[c1 appendMessageWithText:@"message"];
    message.serverTimestamp = [NSDate date];
    c1.lastServerTimeStamp = message.serverTimestamp;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    ZMConversationList *activeList = [ZMConversation conversationsExcludingArchivedInContext:self.uiMOC];
    ZMConversationList *archivedList = [ZMConversation archivedConversationsInContext:self.uiMOC];
    ZMConversationList *clearedList = [ZMConversation clearedConversationsInContext:self.uiMOC];
    
    XCTAssertEqual(activeList.count, 1u);
    XCTAssertEqualObjects(activeList.firstObject, c1);
    XCTAssertEqual(archivedList.count, 0u);
    XCTAssertEqual(clearedList.count, 0u);

    XCTAssertTrue([self.uiMOC saveOrRollback]);

    // when
    [c1 clearMessageHistory];
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    
    // then
    XCTAssertEqual(activeList.count, 0u);
    XCTAssertEqual(archivedList.count, 0u);
    XCTAssertEqual(clearedList.count, 1u);
    XCTAssertEqualObjects(clearedList.firstObject, c1);
}

- (void)testThatClearingConversationDoesNotClearOtherConversations
{
    // GIVEN
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeOneOnOne;
    c1.lastModifiedDate = [NSDate date];
    ZMMessage *message1 = (id)[c1 appendMessageWithText:@"message 1"];
    message1.serverTimestamp = [NSDate date];
    c1.lastServerTimeStamp = message1.serverTimestamp;

    ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c2.conversationType = ZMConversationTypeOneOnOne;
    c2.lastModifiedDate = [NSDate date];
    ZMMessage *message2 = (id)[c2 appendMessageWithText:@"message 2"];
    message2.serverTimestamp = [NSDate date];
    c2.lastServerTimeStamp = message2.serverTimestamp;
    XCTAssert([self.uiMOC saveOrRollback]);

    NSSet *conversations = [NSSet setWithArray:@[c1, c2]];
    ZMConversationList *activeList = [ZMConversation conversationsExcludingArchivedInContext:self.uiMOC];
    ZMConversationList *archivedList = [ZMConversation archivedConversationsInContext:self.uiMOC];
    ZMConversationList *clearedList = [ZMConversation clearedConversationsInContext:self.uiMOC];

    XCTAssertTrue([c1.allMessages containsObject:message1]);
    XCTAssertTrue([c2.allMessages containsObject:message2]);

    XCTAssertEqual(activeList.count, 2u);
    XCTAssertEqualObjects(activeList.set, conversations);
    XCTAssertEqual(archivedList.count, 0u);
    XCTAssertEqual(clearedList.count, 0u);

    XCTAssertTrue([self.uiMOC saveOrRollback]);

    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [c1 clearMessageHistory];
    }];

    XCTAssertTrue([self.uiMOC saveOrRollback]);

    // then
    XCTAssertFalse([c1.allMessages containsObject:message1]);
    XCTAssertTrue([c2.allMessages containsObject:message2]);

    XCTAssertEqual(activeList.count, 1u);
    XCTAssertEqual(archivedList.count, 0u);
    XCTAssertEqual(clearedList.count, 1u);
    XCTAssertEqualObjects(clearedList.firstObject, c1);

}

- (void)testThatAddingMessageToClearedConversationMovesItToActiveConversationsList
{
    // given
    ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c1.conversationType = ZMConversationTypeOneOnOne;
    c1.lastModifiedDate = [NSDate date];
    ZMMessage *message = (id)[c1 appendMessageWithText:@"message"];
    message.serverTimestamp = [NSDate date];
    
    c1.lastServerTimeStamp = message.serverTimestamp;
    
    [c1 clearMessageHistory];
    XCTAssert([self.uiMOC saveOrRollback]);

    ZMConversationList *activeList = [ZMConversation conversationsExcludingArchivedInContext:self.uiMOC];
    ZMConversationList *archivedList = [ZMConversation archivedConversationsInContext:self.uiMOC];
    ZMConversationList *clearedList = [ZMConversation clearedConversationsInContext:self.uiMOC];
    
    XCTAssertEqual(activeList.count, 0u);
    XCTAssertEqual(archivedList.count, 0u);
    XCTAssertEqual(clearedList.count, 1u);
    XCTAssertEqualObjects(clearedList.firstObject, c1);

    XCTAssertTrue([self.uiMOC saveOrRollback]);

    // when
    //UI should call this when opening cleared conversation first time
    [c1 revealClearedConversation];

    // then
    XCTAssertTrue([self.uiMOC saveOrRollback]);

    XCTAssertEqual(activeList.count, 1u);
    XCTAssertEqualObjects(activeList.firstObject, c1);
    XCTAssertEqual(archivedList.count, 0u);
    XCTAssertEqual(clearedList.count, 0u);
}

@end



@implementation ZMConversationListTests (ZMChanges)

- (void)testThatTheSortedIsAffected;
{
    // given
    ZMConversationList *list = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    
    // then
    XCTAssertTrue([list sortingIsAffectedByConversationKeys:[NSSet setWithObject:ZMConversationListIndicatorKey]]);
    XCTAssertTrue([list sortingIsAffectedByConversationKeys:[NSSet setWithObject:ZMConversationIsArchivedKey]]);
    XCTAssertTrue([list sortingIsAffectedByConversationKeys:[NSSet setWithObject:@"lastModifiedDate"]]);
    XCTAssertTrue([list sortingIsAffectedByConversationKeys:[NSSet setWithObject:@"remoteIdentifier_data"]]);
}

- (void)testThatTheSortedIsNotAffected;
{
    // given
    ZMConversationList *list = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    
    NSEntityDescription *conversationEntity = self.uiMOC.persistentStoreCoordinator.managedObjectModel.entitiesByName[ZMConversation.entityName];
    
    NSMutableSet *conversationKeys = [NSMutableSet setWithArray:conversationEntity.propertiesByName.allKeys];

    [conversationKeys removeObject:ZMConversationIsArchivedKey];
    [conversationKeys removeObject:@"lastModifiedDate"];
    [conversationKeys removeObject:@"remoteIdentifier_data"];
    
    // then
    XCTAssertFalse([list sortingIsAffectedByConversationKeys:conversationKeys]);
}

@end
