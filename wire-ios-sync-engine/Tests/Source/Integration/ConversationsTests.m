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
@import WireSyncEngine;
@import WireTransport;
@import WireMockTransport;
@import WireUtilities;
@import WireTesting;

#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "ConversationTestsBase.h"
#import "Tests-Swift.h"


@interface ZMConversationList (ObjectIDs)

@end

@implementation ZMConversationList (ObjectIDs)

- (NSArray <NSManagedObjectID *> *)objectIDs {
    return [self mapWithBlock:^NSManagedObjectID *(ZMConversation *conversation) {
        return conversation.objectID;
    }];
}

@end


@interface ConversationTests : ConversationTestsBase

@property (nonatomic) NSUInteger previousZMConversationTranscoderListPageSize;

@end


#pragma mark - Conversation tests
@implementation ConversationTests

- (void)testThatItCallsInitialSyncDone
{
    XCTAssertTrue([self login]);
}

- (void)testThatAConversationIsResyncedAfterRestartingFromScratch
{
    NSString *conversationName = @"My conversation";
    {
        // Create a UI context
        XCTAssertTrue([self login]);
        // Get the users:
        ZMUser *user1 = [self userForMockUser:self.user1];
        XCTAssertNotNil(user1);
        ZMUser *user2 = [self userForMockUser:self.user2];
        XCTAssertNotNil(user2);
        
        // Create a conversation
        __block ZMConversation *conversation;
        [self.userSession performChanges:^{
            conversation = [ZMConversation
                            insertGroupConversationIntoManagedObjectContext :self.userSession.managedObjectContext
                            withParticipants:@[user1, user2]];
            conversation.userDefinedName = conversationName;
        }];
        
        // Wait for merge ui->sync to be done
        WaitForAllGroupsToBeEmpty(0.5);
        XCTAssert([self waitOnMainLoopUntilBlock:^BOOL{
            return conversation.lastModifiedDate != nil;
        } timeout:0.5]);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateSessionManagerAndDeleteLocalData];

    {
        // Wait for sync to be done
        XCTAssertTrue([self login]);
        
        // Check that conversation is there
        ZMConversation *conversation = [[ZMConversationList conversationsInUserSession:self.userSession] firstObjectMatchingWithBlock:^BOOL(ZMConversation *c) {
            return [c.userDefinedName isEqual:conversationName];
        }];
        XCTAssertNotNil(conversation);
    }
}

- (void)testThatChangeToAConversationNameIsResyncedAfterRestartingFromScratch;
{
    NSString *name = @"My New Name";
    {
        // Create a UI context
        XCTAssertTrue([self login]);
        // Get the group conversation
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation);
        // Change the name & save
        conversation.userDefinedName = name;
        [self.userSession saveOrRollbackChanges];
        XCTAssertFalse(conversation.hasChanges, @"Rollback?");
        XCTAssertTrue([conversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
        
        // Wait for merge ui->sync to be done
        WaitForAllGroupsToBeEmpty(0.5);
        
        XCTAssertFalse([conversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateSessionManagerAndDeleteLocalData];
    
    // Wait for sync to be done
    XCTAssertTrue([self login]);
    
    // Check that conversation name is updated:
    {
        // Get the group conversation
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertEqualObjects(conversation.userDefinedName, name);
    }
}

- (void)testThatChangeToAConversationNameIsNotResyncedIfNil;
{
    ZMConversation *conversation = nil;
    
    NSString *name = nil;
    NSString *formerName = nil;
    {
        // Create a UI context
        XCTAssertTrue([self login]);
        // Get the group conversation
        [self.mockTransportSession resetReceivedRequests];
        conversation = [self conversationForMockConversation:self.groupConversation];
        
        XCTAssertNotNil(conversation);
        // Change the name & save
        formerName = conversation.userDefinedName;
        conversation.userDefinedName = name;
        [self.userSession saveOrRollbackChanges];
        XCTAssertFalse(conversation.hasChanges, @"Rollback?");
        XCTAssertTrue([conversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
        
        // Wait for merge ui->sync to be done
        WaitForAllGroupsToBeEmpty(0.5);
        ZMConversation *syncConversation = [self.userSession.syncManagedObjectContext objectWithID:conversation.objectID];
        
        XCTAssertFalse([syncConversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
        XCTAssertFalse([conversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
        XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 0lu);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateSessionManagerAndDeleteLocalData];
    
    // Wait for sync to be done
    XCTAssertTrue([self login]);
    
    // Check that conversation name is updated:
    {
        // Get the group conversation
        conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertEqualObjects(conversation.userDefinedName, formerName);
    }
}

@end

@implementation ConversationTests (DisplayName)

- (void)testThatReceivingAPushEventForNameChangeChangesTheConversationName
{
    
    // given
    // Create a UI context
    XCTAssertTrue([self login]);
    // Get the group conversation
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(conversation);
    XCTAssertEqualObjects(conversation.userDefinedName, @"Group conversation");
    
    // when
    NSString *newConversationName = @"New Conversation Name";

    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation>  _Nonnull __strong __unused session) {
        [self.groupConversation changeNameByUser:self.user3 name:newConversationName];
    }];
    
    // then
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return observer.notifications.count >= 1;
    } timeout:0.5]);
    
    XCTAssertEqualObjects(conversation.userDefinedName, newConversationName);
}

#pragma mark - Participants
- (void)testThatParticipantsAreAddedToAConversationWhenTheyAreAddedRemotely
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [self.groupConversation addUsersByUser:((MockTransportSession *)session).selfUser addedUsers:@[self.user4]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMUser *user4 = [self userForMockUser:self.user4];
    XCTAssertTrue([groupConversation.localParticipants containsObject:user4]);
    XCTAssertEqual(groupConversation.keysThatHaveLocalModifications.count, 0u);
}

- (void)testThatParticipantsAreRemovedFromAConversationWhenTheyAreRemovedRemotely
{
    // given
    XCTAssertTrue([self login]);
    
    ZMUser *user3 = [self userForMockUser:self.user3];
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    XCTAssertTrue([groupConversation.localParticipants containsObject:user3]);
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [self.groupConversation removeUsersByUser:((MockTransportSession *)session).selfUser removedUser:self.user3];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertFalse([groupConversation.localParticipants containsObject:user3]);
    XCTAssertEqual(groupConversation.keysThatHaveLocalModifications.count, 0u);
}

- (void)testThatServiceUsersAreRemovedFromAConversationWhenTheyAreRemovedRemotely
{
    // given
    [self createTeamAndConversations];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertTrue([self login]);
    
    ZMUser *bot = [self userForMockUser:self.serviceUser];
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversationWithServiceUser];
    XCTAssertNotNil(groupConversation);
    XCTAssertTrue([groupConversation.localParticipants containsObject:bot]);
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [self.groupConversationWithServiceUser removeUsersByUser:((MockTransportSession *)session).selfUser removedUser:self.serviceUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertFalse([groupConversation.localParticipants containsObject:bot]);
    XCTAssertEqual(groupConversation.keysThatHaveLocalModifications.count, 0u);
}

- (void)testThatlocalParticipantsInOneOnOneConversationsAreAllParticipants
{
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    
    [self.userSession saveOrRollbackChanges];
    
    XCTAssertEqual(conversation.localParticipants.count, 2u);
}

- (void)testThatlocalParticipantsInOneOnOneConversationWithABlockedUserAreAllParticipants
{
    // given
    
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    
    [self.userSession saveOrRollbackChanges];
    
    XCTAssertEqual(conversation.localParticipants.count, 2u);
    
    // when
    ZMUser *user1 = [self userForMockUser:self.user1];
    XCTAssertFalse(user1.isBlocked);

    [user1 blockWithCompletion:^(NSError *error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue(user1.isBlocked);
    XCTAssertEqual(conversation.localParticipants.count, 2u);
}

- (NSArray *)movedIndexPairsForChangeSet:(ConversationListChangeInfo *)note
{
    NSMutableArray *indexes = [NSMutableArray array];
    [note enumerateMovedIndexes:^(NSInteger from, NSInteger to) {
        ZMMovedIndex *index = [[ZMMovedIndex alloc] initFrom:(NSUInteger)from to:(NSUInteger)to];
        [indexes addObject:index];
    }];
    
    return indexes;
}

- (void)testThatSelfUserSeesConversationWhenItIsAddedToConversationByOtherUser
{
    // given
    
    XCTAssertTrue([self login]);

    __block MockConversation *groupConversation;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        groupConversation = [session insertConversationWithCreator:self.user3 otherUsers:@[self.user1, self.user2] type:ZMTConversationTypeGroup];
        [groupConversation changeNameByUser:self.selfUser name:@"Group conversation 2"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversationList *conversationList = [ZMConversationList conversationsInUserSession:self.userSession];
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation>  _Nonnull __strong __unused session) {
        [groupConversation addUsersByUser:self.user1 addedUsers:@[self.selfUser]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.userSession.syncManagedObjectContext saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);

    //By this moment new conversation should be created and self user should be it's member
    ZMConversation *newConv = [self conversationForMockConversation:groupConversation];
    ZMUser *user = [self userForMockUser:self.selfUser];

    XCTAssertEqualObjects(conversationList.firstObject, newConv);
    XCTAssertTrue([newConv.localParticipants containsObject:user]);
}


@end

#pragma mark - Conversation list
@implementation ConversationTests (ConversationStatusAndOrder)

- (void)testThatAConversationListListenerOnlyReceivesNotificationsForTheSpecificListItSignedUpFor
{
    // given
    XCTAssertTrue([self login]);
    ZMConversationList *convList1 = [ZMConversationList conversationsInUserSession:self.userSession];
    ZMConversationList *convList2 = [ZMConversationList archivedConversationsInUserSession:self.userSession];
    
    ConversationListChangeObserver *convListener1 = [[ConversationListChangeObserver alloc] initWithConversationList:convList1];
    ConversationListChangeObserver *convListener2 = [[ConversationListChangeObserver alloc] initWithConversationList:convList2];
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        NOT_USED(session);
        [session insertConversationWithSelfUser:self.selfUser creator:self.selfUser otherUsers:@[self.user1, self.user2] type:ZMTConversationTypeGroup];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];
    
    // then
    XCTAssertGreaterThanOrEqual(convListener1.notifications.count, 0u);
    XCTAssertEqual(convListener2.notifications.count, 0u);
}

- (void)testThatConversationGoesOnTopAfterWeAcceptIncommingConnectionRequest
{
    //given
    XCTAssertTrue([self login]);

    MockUser *mockUser = [self createPendingConnectionFromUserWithName:@"Hans" uuid:NSUUID.createUUID];
    ZMUser *realUser = [self userForMockUser:mockUser];
    
    ZMConversationList *pending = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];
    XCTAssertEqual(pending.count, 1u);
    ZMConversation *pendingConnversation = pending.lastObject;

    ZMConversationList *activeConversations = [ZMConversationList conversationsInUserSession:self.userSession];
    NSUInteger activeCount = activeConversations.count;
    ConversationListChangeObserver *activeObserver = [[ConversationListChangeObserver alloc] initWithConversationList:activeConversations];
    ConversationListChangeObserver *pendingObserver = [[ConversationListChangeObserver alloc] initWithConversationList:pending];
    
    // when
    [realUser acceptWithCompletion:^(NSError *error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5f);

    //then
    XCTAssertEqual(pending.count, 0u);
    XCTAssertEqual(activeConversations.count, activeCount + 1u);
    XCTAssertTrue([activeConversations containsObject:pendingConnversation]);
    XCTAssertEqualObjects(activeConversations.firstObject, pendingConnversation);
    
    NSInteger deletionsCount = 0;
    for (ConversationListChangeInfo *note in pendingObserver.notifications) {
        deletionsCount += note.deletedIndexes.count;
        //should be no updates, insertions, moves in pending list
        XCTAssertEqual(note.insertedIndexes.count, 0u);
        XCTAssertEqual(note.updatedIndexes.count, 0u);
        XCTAssertEqual(note.zm_movedIndexPairs.count, 0u);
    }
    XCTAssertEqual(deletionsCount, 1);
    
    NSInteger insertionsCount = 0;
    for (ConversationListChangeInfo *note in activeObserver.notifications) {
        insertionsCount += note.insertedIndexes.count;
        //should be no deletions in active list
        XCTAssertEqual(note.deletedIndexes.count, 0u);
    }
    XCTAssertEqual(insertionsCount, 1);
}


#pragma mark - Archiving and silencing
- (void)testThatArchivingAConversationIsSynchronizedToTheBackend
{
    {
        // given
        NSDate *previousArchivedDate = [NSDate dateWithTimeIntervalSince1970:-1];
        [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
            // set last read
            NOT_USED(session);
            self.groupConversation.otrArchived = NO;
            self.groupConversation.otrArchivedRef = previousArchivedDate.transportString;
        }];
        
        XCTAssertTrue([self login]);
        [self.mockTransportSession resetReceivedRequests];
        
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation.lastServerTimeStamp);
        XCTAssertFalse(conversation.isArchived);
        XCTAssertTrue([conversation.lastServerTimeStamp compare:conversation.archivedChangedTimestamp] == NSOrderedDescending);
        
        // when
        [self.userSession performChanges:^{
            conversation.isArchived = YES;
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        
        // then
        ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
        NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
        XCTAssertEqualObjects(request.path, expectedPath);
        XCTAssertEqual(request.method, ZMMethodPUT);
        XCTAssertEqualObjects(request.payload.asDictionary[@"otr_archived_ref"], conversation.archivedChangedTimestamp.transportString);
        XCTAssertEqualObjects(request.payload.asDictionary[@"otr_archived"], @(conversation.isArchived));
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateSessionManagerAndDeleteLocalData];
    
    {
        // Wait for sync to be done
        XCTAssertTrue([self login]);
        
        // then
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertTrue(conversation.isArchived);
    }
    
}

- (void)testThatUnarchivingAConversationIsSynchronizedToTheBackend
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    [self.userSession performChanges:^{
        conversation.isArchived = YES;
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    [self.mockTransportSession resetReceivedRequests];
    
    // when
    [self.userSession performChanges:^{
        conversation.isArchived = NO;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
    NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
    XCTAssertEqualObjects(request.path, expectedPath);
    XCTAssertEqual(request.method, ZMMethodPUT);
    XCTAssertEqualObjects(conversation.lastServerTimeStamp, conversation.archivedChangedTimestamp);
    XCTAssertEqualObjects(request.payload.asDictionary[@"otr_archived_ref"], conversation.archivedChangedTimestamp.transportString);
    XCTAssertEqualObjects(request.payload.asDictionary[@"otr_archived"], @(conversation.isArchived));
}

- (void)testThatOnlyMentionsConversationIsSynchronizedToTheBackend
{
    {
        // given
        XCTAssertTrue([self login]);
        [self.mockTransportSession resetReceivedRequests];
        
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        
        // when
        [self.userSession performChanges:^{
            conversation.isFullyMuted = YES;
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        
        // then
        ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
        NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
        XCTAssertEqualObjects(request.path, expectedPath);
        XCTAssertEqual(request.method, ZMMethodPUT);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, conversation.silencedChangedTimestamp);
        XCTAssertEqualObjects(request.payload.asDictionary[@"otr_muted_ref"], conversation.silencedChangedTimestamp.transportString);
        XCTAssertEqualObjects(request.payload.asDictionary[@"otr_muted_status"], @(conversation.isFullyMuted ? 3 : 0));
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateSessionManagerAndDeleteLocalData];
    
    {
        // Wait for sync to be done
        XCTAssertTrue([self login]);
        
        // then
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertTrue(conversation.isFullyMuted);
    }
}
- (void)testThatSilencingAConversationIsSynchronizedToTheBackend
{
    {
        // given
        XCTAssertTrue([self login]);
        [self.mockTransportSession resetReceivedRequests];

        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];

        // when
        [self.userSession performChanges:^{
            conversation.isFullyMuted = YES;
        }];
        WaitForAllGroupsToBeEmpty(0.5);

        // then
        ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
        NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
        XCTAssertEqualObjects(request.path, expectedPath);
        XCTAssertEqual(request.method, ZMMethodPUT);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, conversation.silencedChangedTimestamp);
        XCTAssertEqualObjects(request.payload.asDictionary[@"otr_muted_ref"], conversation.silencedChangedTimestamp.transportString);
        XCTAssertEqualObjects(request.payload.asDictionary[@"otr_muted_status"], @(conversation.isFullyMuted ? 3 : 0));
    }

    // Tears down context(s) &
    // Re-create contexts
    [self recreateSessionManagerAndDeleteLocalData];

    {
        // Wait for sync to be done
        XCTAssertTrue([self login]);

        // then
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertTrue(conversation.isFullyMuted);
    }

}

- (void)testThatUnsilencing_OnlyMentionsConversation_IsSynchronizedToTheBackend
{
    // given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    [self.userSession performChanges:^{
        conversation.isMutedDisplayingMentions = YES;
    }];

    WaitForAllGroupsToBeEmpty(0.5);
    [self.mockTransportSession resetReceivedRequests];

    // when
    [self.userSession performChanges:^{
        conversation.isMutedDisplayingMentions = NO;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
    NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
    XCTAssertEqualObjects(request.path, expectedPath);
    XCTAssertEqual(request.method, ZMMethodPUT);
    XCTAssertEqualObjects(request.payload.asDictionary[@"otr_muted_ref"], conversation.lastServerTimeStamp.transportString);
    XCTAssertEqualObjects(request.payload.asDictionary[@"otr_muted_status"], @0);
}

- (void)testThatUnsilencingAConversationIsSynchronizedToTheBackend
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    [self.userSession performChanges:^{
        conversation.isFullyMuted = YES;
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    [self.mockTransportSession resetReceivedRequests];
    
    // when
    [self.userSession performChanges:^{
        conversation.isFullyMuted = NO;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
    NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
    XCTAssertEqualObjects(request.path, expectedPath);
    XCTAssertEqual(request.method, ZMMethodPUT);
    XCTAssertEqualObjects(request.payload.asDictionary[@"otr_muted_ref"], conversation.lastServerTimeStamp.transportString);
    XCTAssertEqualObjects(request.payload.asDictionary[@"otr_muted_status"], @0);
}
- (void)testThatWhenBlockingAUserTheOneOnOneConversationIsRemovedFromTheConversationList
{
    // login
    XCTAssertTrue([self login]);
    
    // given
    
    ZMUser *user1 = [self userForMockUser:self.user1];
    (void) user1.name;
    XCTAssertFalse(user1.isBlocked);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    (void) conversation.allMessages; // Make sure we've faulted in the messages
    XCTAssertNotNil(conversation);
    XCTAssertEqualObjects(conversation.connectedUser, user1);
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeOneOnOne);

    ZMConversationList *active = [ZMConversationList conversationsInUserSession:self.userSession];
    XCTAssertEqual(active.count, 5u);
    XCTAssertTrue([active containsObject:conversation]);

    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:active];
    
    // when blocking user 1
    [user1 blockWithCompletion:^(NSError *error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then the conversation should not be in the active list anymore
    XCTAssertTrue(user1.isBlocked);
    XCTAssertEqual(conversation.connection.status, ZMConnectionStatusBlocked);

    XCTAssertEqual(active.count, 4u);
    XCTAssertFalse([active containsObject:conversation]);
    (void)observer;
}

- (void)checkThatItUnarchives:(BOOL)shouldUnarchive silenced:(BOOL)isSilenced mockConversation:(MockConversation *)mockConversation withBlock:(void (^)(MockTransportSession<MockTransportSessionObjectCreation> *session))block
{
    // given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    [self.userSession performChanges:^{
        conversation.isArchived = YES;
        if (isSilenced) {
            conversation.isFullyMuted = YES;
        }
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertTrue(conversation.isArchived);
    if (isSilenced) {
        XCTAssertTrue(conversation.isFullyMuted);
    }

    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        block(((MockTransportSession<MockTransportSessionObjectCreation> *)session));
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    if (shouldUnarchive) {
        XCTAssertFalse(conversation.isArchived);
    } else {
        XCTAssertTrue(conversation.isArchived);
    }
}

- (void)testThatAddingUsersToAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;

    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation addUsersByUser:session.selfUser addedUsers:@[self.user5]];
    }];
}

- (void)testThatRemovingUsersFromAnArchivedConversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;

    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:self.user2];
    }];
}

- (void)testThatRemovingUsersFromAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;

    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:self.user2];
    }];
}

- (void)testThatRemovingSelfUserFromAnArchivedConversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;

    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:session.selfUser];
    }];
}

- (void)testThatRemovingSelfUserFromAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;

    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:session.selfUser];
    }];
}

- (void)testThatAcceptingArchivedOutgoingRequest_Unarchives_ThisConversation
{
    // given
    XCTAssertTrue([self login]);

    MockUser *mockUser = [self createSentConnectionFromUserWithName:@"Hans" uuid:NSUUID.createUUID];
    ZMConversation *conversation = [[self userForMockUser:mockUser] oneToOneConversation];
    
    [self.userSession performChanges:^{
        conversation.isArchived = YES;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertTrue(conversation.isArchived);
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session remotelyAcceptConnectionToUser:mockUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertFalse(conversation.isArchived);
}

#pragma mark - Last read

- (void)testThatItDoesNotSendALastReadEventWhenInsertingAMessage
{
    // given
    XCTAssertTrue([self login]);
    
    [self.mockTransportSession resetReceivedRequests];
    ZMConversation *conv =  [self conversationForMockConversation:self.selfToUser1Conversation];
    ZMConversation *selfConv = [ZMConversation selfConversationInContext:self.userSession.managedObjectContext];
    __block ZMMessage *textMsg;
    __block ZMMessage *imageMsg;

    // when
    [self.userSession performChanges:^{
        textMsg = (id)[conv appendMessageWithText:@"bla bla"];
        imageMsg = (id)[conv appendMessageWithImageData:self.verySmallJPEGData];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMTransportRequest *lastReadRequest = [self.mockTransportSession.receivedRequests firstObjectMatchingWithBlock:^BOOL(ZMTransportRequest *request){
        return [request.path isEqualToString:[NSString stringWithFormat:@"/conversations/%@/otr/messages", selfConv.remoteIdentifier.transportString]];
    }];
    XCTAssertNil(lastReadRequest);
    
    XCTAssertEqual(conv.estimatedUnreadCount, 0u);
}

#pragma mark - Clearing history

- (void)testThatItSetsTheLastReadWhenReceivingARemoteLastReadThroughTheSelfConversation
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    [self.userSession performChanges:^{
        ZMMessage *message = (id)[conversation appendMessageWithText:@"lalala"];
        conversation.lastReadServerTimeStamp = message.serverTimestamp;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    NSDate *newLastRead = [conversation.lastReadServerTimeStamp dateByAddingTimeInterval:500];
    
    // when
    [self remotelyAppendSelfConversationWithZMLastReadForMockConversation:self.selfToUser1Conversation atTime:newLastRead];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual([conversation.lastReadServerTimeStamp timeIntervalSince1970], [newLastRead timeIntervalSince1970]);
}


- (void)testThatItClearsMessagesWhenReceivingARemoteClearedThroughTheSelfConversation
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    __block ZMMessage *message1;
    __block ZMMessage *message2;
    __block ZMMessage *message3;

    [self.userSession performChanges:^{
        [conversation appendMessageWithText:@"lalala"];
        [self spinMainQueueWithTimeout:0.1]; // this is needed so the timeStamps are at least a millisecond appart
        [conversation appendMessageWithText:@"boohoohoo"];
        [self spinMainQueueWithTimeout:0.1]; // this is needed so the timeStamps are at least a millisecond appart
        message1 = (id)[conversation appendMessageWithText:@"hehehe"];
        [NSThread sleepForTimeInterval:0.2]; // this is needed so the timeStamps are at least a millisecond appart
        message2 = (id)[conversation appendMessageWithText:@"I will not go away"];
        [self spinMainQueueWithTimeout:0.1]; // this is needed so the timeStamps are at least a millisecond appart
        message3 = (id)[conversation appendMessageWithText:@"I will stay for sure"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(conversation.allMessages.count, 5u);

    NSArray *remainingMessages = @[message3, message2];
    NSDate *cleared = message1.serverTimestamp;
    
    // when
    [self remotelyAppendSelfConversationWithZMClearedForMockConversation:self.selfToUser1Conversation atTime:cleared];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual([conversation.clearedTimeStamp timeIntervalSince1970], [cleared timeIntervalSince1970]);
    XCTAssertEqual(conversation.allMessages.count, 2u);
    AssertArraysContainsSameObjects([conversation lastMessagesWithLimit:10], remainingMessages);
}

#pragma mark - Reactions
- (void)testThatAppendingAReactionWithSendAMessageWithReaction;
{
    // given
    XCTAssertTrue([self login]);
    
    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];
    WaitForAllGroupsToBeEmpty(0.5);
    
    MockConversation *mockConversation = self.selfToUser1Conversation;
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    __block ZMTextMessage *message;
    [self.userSession performChanges:^{
        message = (ZMTextMessage *)[conversation appendMessageWithText:@"Je t'aime JCVD"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *reactionEmoji = @"❤️";
    [self.userSession performChanges:^{
        [ZMMessage addReaction:MessageReactionLike toMessage:message];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    XCTAssertEqual(message.usersReaction.count, 1lu);
    XCTAssertNotNil(message.usersReaction[reactionEmoji]);
    XCTAssertEqual([message.usersReaction[reactionEmoji] count], 1lu);
    XCTAssertEqualObjects([message.usersReaction[reactionEmoji] firstObject], [self userForMockUser:self.selfUser]);
    XCTAssertEqual(conversation.hiddenMessages.count, 0lu);
    XCTAssertNotNil([self.mockTransportSession.receivedRequests lastObject]);
}

- (void)testThatAppendingAReactionNotifiesObserverOfAddedReactions;
{
    //given
    XCTAssertTrue([self login]);
    
    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];
    WaitForAllGroupsToBeEmpty(0.5);
    
    MockConversation *mockConversation = self.selfToUser1Conversation;
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    __block ZMTextMessage *message;
    [self.userSession performChanges:^{
        message = (ZMTextMessage *)[conversation appendMessageWithText:@"Je t'aime JCVD"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    MessageChangeObserver *observer = [[MessageChangeObserver alloc] initWithMessage:message];

    // when
    [self.userSession performChanges:^{
        [ZMMessage addReaction:MessageReactionLike toMessage:message];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    XCTAssertEqual(observer.notifications.count, 1lu);
    MessageChangeInfo *changes = [observer.notifications lastObject];
    XCTAssertTrue(changes.reactionsChanged);
}

- (void)testThatAppendingAReactionNotifiesObserverOfChangesInReactions;
{
    //given
    XCTAssertTrue([self login]);
    
    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];
    WaitForAllGroupsToBeEmpty(0.5);
    
    MockConversation *mockConversation = self.selfToUser1Conversation;
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    __block ZMTextMessage *message;
    [self.userSession performChanges:^{
        message = (ZMTextMessage *)[conversation appendMessageWithText:@"Je t'aime JCVD"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    [self.userSession performChanges:^{
        [ZMMessage addReaction:MessageReactionLike toMessage:message];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    MessageChangeObserver *observer = [[MessageChangeObserver alloc] initWithMessage:message];
    
    [self.userSession performChanges:^{
        // removes reaction for self user
        [ZMMessage removeReactionOnMessage:message];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    XCTAssertEqual(observer.notifications.count, 1lu);
    MessageChangeInfo *changes = [observer.notifications lastObject];
    XCTAssertTrue(changes.reactionsChanged);
}

- (void)testThatLikesAreResetWhenEditingAMessage;
{
    //given
    XCTAssertTrue([self login]);
    
    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];
    WaitForAllGroupsToBeEmpty(0.5);
    
    MockConversation *mockConversation = self.selfToUser1Conversation;
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    __block ZMTextMessage *message;
    [self.userSession performChanges:^{
        message = (ZMTextMessage *)[conversation appendMessageWithText:@"Je t'aime JCVD"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    [self.userSession performChanges:^{
        [ZMMessage addReaction:MessageReactionLike toMessage:message];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // sanity check
    XCTAssertEqual(message.usersReaction.count, 1lu);
    
    // when
    [self.userSession performChanges:^{
        [message.textMessageData editText:@"Je t'aime JCVD, plus que tout!" mentions:@[] fetchLinkPreview:NO];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    XCTAssertEqual(message.usersReaction.count, 0lu);
}

@end

