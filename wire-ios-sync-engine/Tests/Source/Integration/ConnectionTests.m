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
@import WireSyncEngine;
@import WireDataModel;

#import "Tests-Swift.h"

@interface ConnectionTests : IntegrationTest

@property (nonatomic) ConversationChangeObserver *conversationChangeObserver;

@end

@implementation ConnectionTests


- (void)setUp
{
    [super setUp];
    
    [self createSelfUserAndConversation];
    [self createExtraUsersAndConversations];
    
    self.conversationChangeObserver = [[ConversationChangeObserver alloc] init];
}

- (void)tearDown
{
    self.conversationChangeObserver = nil;
    
    [super tearDown];
}


- (ZMConversation *)oneOnOneConversationForConnectedMockUser:(MockUser*)mockUser
{
    MockConnection *mockConnection = mockUser.connectionsTo.firstObject;
    ZMConversation *conversation = [self conversationForMockConversation:mockConnection.conversation];
    return conversation;
}

- (void)testThatWeRequestToTheBackendAConnectionFromASearchUser
{
    // given
    NSString *searchUserName = @"Karl McUser";
    NSUUID *userID = [NSUUID createUUID];
    [self createUserWithName:searchUserName uuid:userID];
    
    
    XCTAssertTrue([self login]);
    
    // when
    [self searchAndConnectToUserWithName:searchUserName searchQuery:@"McUser"];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMTransportRequest *foundRequest = [self.mockTransportSession.receivedRequests firstObjectMatchingWithBlock:^BOOL(ZMTransportRequest *request) {
        return [request.path hasPrefix:@"/connections"] &&
            (request.method == ZMMethodPOST)
        && [[[request.payload asDictionary] uuidForKey:@"user"] isEqual:userID];
    }];
    XCTAssertNotNil(foundRequest);
}

- (void)testThatWhenConnectingToASearchUserAndResynchronizingWeHaveThatConnection
{
    // given
    NSString *searchUserName = @"Karl McUser";
    NSUUID *userID = [NSUUID createUUID];
    [self createUserWithName:searchUserName uuid:userID];
    
    XCTAssertTrue([self login]);
    
    [self searchAndConnectToUserWithName:searchUserName searchQuery:@"McUser"];
    WaitForAllGroupsToBeEmpty(0.5);

    [self recreateSessionManagerAndDeleteLocalData];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    XCTAssertTrue([self login]);
    
    // then
    NSArray *allConversations = [ZMConversationList conversationsInUserSession:self.userSession];
    ZMConversation *foundConversation = [allConversations firstObjectMatchingWithBlock:^BOOL(ZMConversation *conv) {
        if([conv.connectedUser.name isEqualToString:@"Karl McUser"]) {
            return YES;
        }
        return NO;
    }];
    
    XCTAssertNotNil(foundConversation);
}

- (void)testThatWeRequestToTheBackendAConnectionForAUserWeAreInAConversationWith
{
    // given
    NSString *userName = @"Extra User4";
    NSUUID *userID = [NSUUID createUUID];
    [self createUserWithName:userName uuid:userID];
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        NOT_USED(session);
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", userID.transportString]];
        NSArray *users = [self.mockTransportSession.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        XCTAssertEqual(users.count, 1u);
        [self.groupConversation addUsersByUser:self.selfUser addedUsers:@[users[0]]];
    }];

    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    ZMUser *userToConnectTo = [conversation.sortedActiveParticipants firstObjectMatchingWithBlock:^BOOL(ZMUser* user) {
        return [user.name isEqual:userName];
    }];
    XCTAssertNotNil(userToConnectTo);
    
    // when
    [userToConnectTo connectWithCompletion:^(NSError * error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMTransportRequest *foundRequest = [self.mockTransportSession.receivedRequests firstObjectMatchingWithBlock:^BOOL(ZMTransportRequest *request) {
        return [request.path hasPrefix:@"/connections"] &&
        (request.method == ZMMethodPOST)
        && [[[request.payload asDictionary] uuidForKey:@"user"] isEqual:userID];
    }];
    XCTAssertNotNil(foundRequest);
}

- (void)testThatAPendingIncomingConnectionRequestIsDisplayedCorrectly;
{
    // given
    XCTAssertTrue([self login]);
    ZMConversationList *pending = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];
    ZMConversationList *active = [ZMConversationList conversationsInUserSession:self.userSession];

    // when
    NSString *userName = @"Hans Von Üser";
    MockUser *mockUser = [self createPendingConnectionFromUserWithName:userName uuid:NSUUID.createUUID];
    
    // then
    ZMConversation *conversation = [self oneOnOneConversationForConnectedMockUser:mockUser];
    XCTAssertEqualObjects(conversation.displayName, userName);
    XCTAssertTrue(conversation.isPendingConnectionConversation);
    
    ZMUser *otherUser = [self userForMockUser:mockUser];
    XCTAssertNotNil(otherUser);
    XCTAssertEqual(conversation.connectedUser, otherUser);
    
    //pending connections should be in pending conversations list
    XCTAssertFalse([active containsObject:conversation]);
    XCTAssertTrue([pending containsObject:conversation]);
}

- (void)testThatASentConnectionRequestIsDisplayedCorrectly;
{
    // given
    
    XCTAssertTrue([self login]);
    ZMConversationList *pending = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];
    ZMConversationList *active = [ZMConversationList conversationsInUserSession:self.userSession];
    
    // when
    NSString *userName = @"Hans Von Üser";
    MockUser *mockUser = [self createSentConnectionFromUserWithName:userName uuid:NSUUID.createUUID];

    // then
    ZMConversation *conversation = [self oneOnOneConversationForConnectedMockUser:mockUser];
    XCTAssertNotNil(conversation);
    XCTAssertEqualObjects(conversation.displayName, userName);
    XCTAssertFalse(conversation.isPendingConnectionConversation);
    
    ZMUser *otherUser = [self userForMockUser:mockUser];
    XCTAssertNotNil(otherUser);
    XCTAssertEqual(conversation.connectedUser, otherUser);
    
    //sent connections should be in active conversations list
    XCTAssertTrue([active containsObject:conversation]);
    XCTAssertFalse([pending containsObject:conversation]);
}


- (void)testThatAConnectionRequestIsRemovedFromThePendingConnectionsListWhenItIsIgnored;
{
    // given
    XCTAssertTrue([self login]);

    MockUser *mockUser = [self createPendingConnectionFromUserWithName:@"Hans Von Üser" uuid:NSUUID.createUUID];
    ZMConversation *conversation = [self oneOnOneConversationForConnectedMockUser:mockUser];
    ZMUser *user = [self userForMockUser:mockUser];
    XCTAssertEqual(user, conversation.connectedUser);
    
    ZMConversationList *pending = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];
    XCTAssertTrue([pending containsObject:conversation]);
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:pending];
    
    // when ignoring:
    [user ignoreWithCompletion:^(NSError * error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    // then
    XCTAssertFalse([pending containsObject:conversation]);
    XCTAssertEqual(observer.notifications.count, 1u);
}

- (void)testThatAConnectionRequestIsRemovedFromConversationsListWhenItIsCancelled;
{
    // given
    XCTAssertTrue([self login]);
    
    MockUser *mockUser = [self createSentConnectionFromUserWithName:@"Hans Von Üser" uuid:NSUUID.createUUID];
    ZMConversation *conversation = [self oneOnOneConversationForConnectedMockUser:mockUser];
    ZMUser *user = [self userForMockUser:mockUser];
    XCTAssertEqual(user, conversation.connectedUser);
    
    ZMConversationList *conversations = [ZMConversationList conversationsIncludingArchivedInUserSession:self.userSession];
    XCTAssertTrue([conversations containsObject:conversation]);
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:conversations];
    
    // when cancelling:
    [user cancelConnectionRequestWithCompletion:^(NSError * error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    // then
    XCTAssertFalse([conversations containsObject:conversation]);
    XCTAssertEqual(observer.notifications.count, 1u);
}

- (void)testThatConnectionRequestsFromTwoUsersAreBothAddedToActiveConversations;
{
    // given
    
    XCTAssertTrue([self login]);
    
    MockUser *mockUser1 = [self createPendingConnectionFromUserWithName:@"Hans Von Üser" uuid:NSUUID.createUUID];
    ZMConversation *conversation1 = [self oneOnOneConversationForConnectedMockUser:mockUser1];
    XCTAssertEqual(conversation1.conversationType, ZMConversationTypeConnection);
    ZMUser *realUser1 = [self userForMockUser:mockUser1];
    XCTAssertEqualObjects(realUser1, conversation1.connectedUser);
    
    MockUser *mockUser2 = [self createPendingConnectionFromUserWithName:@"Hannelore Isstgern" uuid:NSUUID.createUUID];
    ZMConversation *conversation2 = [self oneOnOneConversationForConnectedMockUser:mockUser2];
    XCTAssertEqual(conversation2.conversationType, ZMConversationTypeConnection);
    ZMUser *realUser2 = [self userForMockUser:mockUser2];
    XCTAssertEqualObjects(realUser2, conversation2.connectedUser);
    
    ZMConversationList *active = [ZMConversationList conversationsInUserSession:self.userSession];
    ZMConversationList *pending = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];
    
    XCTAssertFalse([active containsObject:conversation1]);
    XCTAssertFalse([active containsObject:conversation2]);
    XCTAssertTrue([pending containsObject:conversation1]);
    XCTAssertTrue([pending containsObject:conversation2]);

    
    ConversationListChangeObserver *pendingObserver = [[ConversationListChangeObserver alloc] initWithConversationList:pending];
    ConversationListChangeObserver *activeObserver = [[ConversationListChangeObserver alloc] initWithConversationList:active];
    
    // when accepting:
    [realUser1 acceptWithCompletion:^(NSError * error) { NOT_USED(error); }];
    [realUser2 acceptWithCompletion:^(NSError * error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    
    XCTAssertTrue([active containsObject:conversation1]);
    XCTAssertTrue([active containsObject:conversation2]);
    XCTAssertFalse([pending containsObject:conversation1]);
    XCTAssertFalse([pending containsObject:conversation2]);
    
    XCTAssertEqual(conversation1.conversationType, ZMConversationTypeOneOnOne);
    XCTAssertEqual(conversation2.conversationType, ZMConversationTypeOneOnOne);

    XCTAssertGreaterThanOrEqual(pendingObserver.notifications.count, 1u);
    __block NSInteger deletionsCount = 0;
    for (ConversationListChangeInfo *note in pendingObserver.notifications) {
        deletionsCount += note.deletedIndexes.count;
        //should be no insertions, moves, deletions in pending list
        XCTAssertEqual(note.insertedIndexes.count, 0u);
        XCTAssertEqual(note.updatedIndexes.count, 0u);
        XCTAssertEqual(note.zm_movedIndexPairs.count, 0u);
    }
    XCTAssertEqual(deletionsCount, 2);

    XCTAssertGreaterThanOrEqual(activeObserver.notifications.count, 1u);
    __block NSInteger insertionsCount = 0;
    for (ConversationListChangeInfo *note in activeObserver.notifications) {
        insertionsCount += note.insertedIndexes.count;
        //should be no deletions in active list
        XCTAssertEqual(note.deletedIndexes.count, 0u);
    }
    XCTAssertEqual(insertionsCount, 2);
}

- (void)addConnectionRequestInMockTransportsession:(MockTransportSession<MockTransportSessionObjectCreation> *)session forUser:(MockUser *)mockUser
{
    MockConversation *conversation =
    [session insertConversationWithSelfUser:self.selfUser creator:mockUser otherUsers:nil type:ZMTConversationTypeGroup];
    MockConnection *connection = [session insertConnectionWithSelfUser:self.selfUser toUser:mockUser];
    connection.message = @"Hello, my friend.";
    connection.status = @"pending";
    connection.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-20000];
    connection.conversation = conversation;
}

- (void)testThatConnectionRequestsFromTwoUsersTriggerNotifications;
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversationList *conversationList = [ZMConversationList conversationsInUserSession:self.userSession];
    XCTAssertEqual(conversationList.count, 3u);
    ConversationListChangeObserver *conversationListObserver = [[ConversationListChangeObserver alloc] initWithConversationList:conversationList];
    
    ZMConversationList *pendingConversationsList = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];
    ConversationListChangeObserver *pendingConversationListObserver = [[ConversationListChangeObserver alloc] initWithConversationList:pendingConversationsList];
    
    ConversationChangeObserver *convObserver = self.conversationChangeObserver;
    
    NSString *userName1 = @"Hans Von Üser";
    NSUUID *userID1 = NSUUID.createUUID;
    MockUser *mockUser1 = [self createUserWithName:userName1 uuid:userID1];
    
    NSString *userName2 = @"Hannelore Isstgern";
    NSUUID *userID2 = NSUUID.createUUID;
    MockUser *mockUser2 = [self createUserWithName:userName2 uuid:userID2];
    
    ZMUser *realUser1;
    ZMUser *realUser2;
    
    ZMConversation *conv1;
    ZMConversation *conv2;    
    
    
    // when we add connection requests from remote users to the selfuser
    {
        [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
            [self addConnectionRequestInMockTransportsession:(MockTransportSession<MockTransportSessionObjectCreation> *)session forUser:mockUser1];
            [self addConnectionRequestInMockTransportsession:(MockTransportSession<MockTransportSessionObjectCreation> *)session forUser:mockUser2];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // then the conversations should be accessible after sync and have the status pending
    {
        realUser1 = [self userForMockUser:mockUser1];
        XCTAssertNotNil(realUser1);
        
        realUser2 = [self userForMockUser:mockUser2];
        XCTAssertNotNil(realUser2);
        
        conv1 = realUser1.oneToOneConversation;
        XCTAssertNotNil(conv1);
        XCTAssertEqual(conv1.conversationType, ZMConversationTypeConnection);
        
        conv2 = realUser2.oneToOneConversation;
        XCTAssertNotNil(conv2);
        XCTAssertEqual(conv2.conversationType, ZMConversationTypeConnection);
        
        NSArray *listNotes = pendingConversationListObserver.notifications;
        XCTAssertNotNil(listNotes);
        XCTAssertGreaterThan(listNotes.count, 0);
        [conversationListObserver clearNotifications];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    id token1 = [ConversationChangeInfo addObserver:convObserver forConversation:conv1];
    id token2 = [ConversationChangeInfo addObserver:convObserver forConversation:conv2];
    
    // when accepting the connection requests
    {
        [realUser1 acceptWithCompletion:^(NSError * error) { NOT_USED(error); }];
        [realUser2 acceptWithCompletion:^(NSError * error) { NOT_USED(error); }];
        WaitForAllGroupsToBeEmpty(0.5);
        [self.mockTransportSession waitForAllRequestsToCompleteWithTimeout:0.5];
    }
    
    // we should receive notifcations about the list change and the conversation updates and the connection status should change
    {
        NSIndexSet *expectedSet1 = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];

        NSArray *listNotes = conversationListObserver.notifications;
        XCTAssertGreaterThan(listNotes.count, 1u); // 1 insertion update and x list re-order updates

        ConversationListChangeInfo *listNote1 = listNotes.firstObject;

        XCTAssertEqualObjects(listNote1.insertedIndexes, expectedSet1);
        XCTAssertEqualObjects(listNote1.updatedIndexes, [NSIndexSet indexSet]);
        XCTAssertEqualObjects(listNote1.deletedIndexes, [NSIndexSet indexSet]);
        XCTAssertEqual(listNote1.zm_movedIndexPairs.count, 0u);

        NSArray *convNotes = convObserver.notifications;
        convNotes = convObserver.notifications;
        XCTAssertNotNil(convNotes);
        
        BOOL conv1StateChanged = NO;
        BOOL conv2StateChanged = NO;
        BOOL conv1MessagesChanged = NO;
        BOOL conv2MessagesChanged = NO;

        for (ConversationChangeInfo *note  in convNotes) {
            ZMConversation *conv = note. conversation;
            if (note.messagesChanged) {
                conv1MessagesChanged = conv1MessagesChanged ? YES :(conv == conv1);
                conv2MessagesChanged = conv2MessagesChanged ? YES :(conv == conv2);
            }
            if (note.connectionStateChanged) {
                conv1StateChanged = conv1StateChanged ? YES :(conv == conv1);
                conv2StateChanged = conv2StateChanged ? YES :(conv == conv2);
            }
        }
        XCTAssertTrue(conv1StateChanged);
        XCTAssertEqual(conv1.conversationType, ZMConversationTypeOneOnOne);
        XCTAssertEqual(conv1.allMessages.count, 1u); // accepting connection request produces a new conversation system message
        XCTAssertEqual(((ZMSystemMessage *)conv1.lastMessage).systemMessageType, ZMSystemMessageTypeNewConversation);

        XCTAssertTrue(conv2StateChanged);
        XCTAssertEqual(conv2.conversationType, ZMConversationTypeOneOnOne);
        XCTAssertEqual(conv2.allMessages.count, 1u); // accepting connection request produces a new conversation system message
        XCTAssertEqual(((ZMSystemMessage *)conv2.lastMessage).systemMessageType, ZMSystemMessageTypeNewConversation);
    }
    
    (void)token1;
    (void)token2;
}

- (void)disabled_testThatConnectionRequestsToTwoUsersAreAddedToPending
{
    // given two remote users
    NSString *userName1 = @"Hans Von Üser";
    NSString *userName2 = @"Hannelore Isstgern";

    __block MockUser *mockUser1;
    __block MockUser *mockUser2;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        mockUser1 = [session insertUserWithName:userName1];
        mockUser1.handle = @"hans";
        XCTAssertNotNil(mockUser1.identifier);
        mockUser1.email = @"";
        mockUser1.phone = @"";
        
        mockUser2 = [session insertUserWithName:userName2];
        mockUser2.handle = @"hannelore";
        XCTAssertNotNil(mockUser2.identifier);
        mockUser2.email = @"";
        mockUser2.phone = @"";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self login]);

    ZMConversationList *active = [ZMConversationList conversationsInUserSession:self.userSession];
    NSUInteger count = active.count;
    
    ConversationListChangeObserver *listObserver = [[ConversationListChangeObserver alloc] initWithConversationList:active];
    
    ZMConversation *conv1;
    ZMConversation *conv2;
    
    // when we search and send connection requests to users
    {
        [self.userSession performChanges:^{
            [self searchAndConnectToUserWithName:userName1 searchQuery:@"Hans"];
            [self searchAndConnectToUserWithName:userName2 searchQuery:@"Hannelore"];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // we should see two new active conversations
    {
        ZMUser *realUser1 = [self userForMockUser:mockUser1];
        XCTAssertNotNil(realUser1);
        XCTAssertEqual(realUser1.connection.status, ZMConnectionStatusSent);
        
        ZMUser *realUser2 = [self userForMockUser:mockUser2];
        XCTAssertNotNil(realUser2);
        XCTAssertEqual(realUser2.connection.status, ZMConnectionStatusSent);
        
        conv1 = realUser1.oneToOneConversation;
        XCTAssertNotNil(conv1);
        
        conv2 = realUser2.oneToOneConversation;
        XCTAssertNotNil(conv2);
        
        XCTAssertEqual(active.count, count+2);
    }
    
    ConversationChangeObserver *observer = self.conversationChangeObserver;
    id token1 = [ConversationChangeInfo addObserver:observer forConversation:conv1];
    id token2 = [ConversationChangeInfo addObserver:observer forConversation:conv2];

    // when the remote users accept the connection requests
    {
        [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
            [session remotelyAcceptConnectionToUser:mockUser1];
            [session remotelyAcceptConnectionToUser:mockUser2];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        [NSThread sleepForTimeInterval:0.1];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    WaitForAllGroupsToBeEmpty(0.5);

    // we should receive notifications about the changed status and participants
    {
        NSArray *notifications = observer.notifications;
        XCTAssertNotNil(notifications);
        
        BOOL conv1StateChanged = NO;
        BOOL conv2StateChanged = NO;
        BOOL conv1ParticipantsChanged = NO;
        BOOL conv2ParticipantsChanged = NO;
        
        for (ConversationChangeInfo *note  in notifications) {
            ZMConversation *conv = note.conversation;
            if (note.participantsChanged) {
                conv1ParticipantsChanged = conv1ParticipantsChanged ? YES :(conv == conv1);
                conv2ParticipantsChanged = conv2ParticipantsChanged ? YES :(conv == conv2);
            }
            if (note.connectionStateChanged) {
                conv1StateChanged = conv1StateChanged ? YES :(conv == conv1);
                conv2StateChanged = conv2StateChanged ? YES :(conv == conv2);
            }
        }
        XCTAssertTrue(conv1StateChanged);
        XCTAssertTrue(conv2StateChanged);
        XCTAssertTrue(conv1ParticipantsChanged);
        XCTAssertTrue(conv2ParticipantsChanged);
    }
    
    (void)token1;
    (void)token2;
    (void)listObserver;
}

- (void)DISABLED_testThatWeDontSeeASystemMessageWhenAUserAcceptsAConnectionRequest;
{
    // given two remote users
    NSString *userName1 = @"Hans Von Üser";
    
    __block MockUser *mockUser1;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        mockUser1 = [session insertUserWithName:userName1];
        XCTAssertNotNil(mockUser1.identifier);
        mockUser1.email = @"";
        mockUser1.phone = @"";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self login]);
    
    NSArray *active = [ZMConversationList conversationsInUserSession:self.userSession];
    NSUInteger count = active.count;
    
    ZMConversation *conv1;
    
    // when we search and send connection requests to users
    {
        [self.userSession performChanges:^{
            [self searchAndConnectToUserWithName:userName1 searchQuery:@"Hans"];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // we should see a new active conversation
    {
        ZMUser *realUser1 = [self userForMockUser:mockUser1];
        XCTAssertNotNil(realUser1);
        XCTAssertEqual(realUser1.connection.status, ZMConnectionStatusSent);
        
        conv1 = realUser1.oneToOneConversation;
        XCTAssertNotNil(conv1);
        XCTAssertEqual(active.count, count+1);
    }
    
    
    // when the remote users accept the connection requests
    {
        [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
            [session remotelyAcceptConnectionToUser:mockUser1];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // we should not see a system message in the conversation
    {
        XCTAssertEqual(conv1.conversationType, ZMConversationTypeOneOnOne);
        XCTAssertEqual(conv1.allMessages.count, 1u, @"%@", [conv1 lastMessagesWithLimit:50]);
        ZMSystemMessage *message1 = (ZMSystemMessage *)conv1.lastMessage;
        XCTAssertEqual(message1.systemMessageType, ZMSystemMessageTypeConnectionRequest);
        XCTAssertEqual(message1.text, @"Hola");
    }
}

- (void)testThatTheConnectionTypeChangesAfterARemoteUserAcceptsOurConnectionRequest
{
    // given a remote users
    NSString *userName1 = @"Hans Von Üser";
    
    __block MockUser *mockUser1;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        mockUser1 = [session insertUserWithName:userName1];
        XCTAssertNotNil(mockUser1.identifier);
        mockUser1.email = @"";
        mockUser1.phone = @"";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self login]);
    
    ZMConversation *conv1;
    ZMUser *realUser1;
    
    // when we search and send connection requests to users
    {
        [self.userSession performChanges:^{
            [self searchAndConnectToUserWithName:userName1 searchQuery:@"Hans"];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // we should see a new active conversation
    {
        realUser1 = [self userForMockUser:mockUser1];
        XCTAssertNotNil(realUser1);
        XCTAssertEqual(realUser1.connection.status, ZMConnectionStatusSent);
        
        conv1 = realUser1.oneToOneConversation;
        XCTAssertNotNil(conv1);
        XCTAssertEqual(conv1.conversationType, ZMConversationTypeConnection);

    }
    
    // when the remote users accept the connection requests
    {
        [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
            [session remotelyAcceptConnectionToUser:mockUser1];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // we should not see a system message in the conversation
    {
        XCTAssertEqual(conv1.conversationType, ZMConversationTypeOneOnOne);
        XCTAssertEqual(realUser1.oneToOneConversation.conversationType, ZMConversationTypeOneOnOne);
    }
}

- (void)testThatTheObserverGetsNotifiedWhenARemoteUserAcceptsOurConnectionRequest
{
    // given two remote users
    NSString *userName1 = @"Hans Von Üser";
    
    __block MockUser *mockUser1;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        mockUser1 = [session insertUserWithName:userName1];
        XCTAssertNotNil(mockUser1.identifier);
        mockUser1.email = @"foo@bar.example.com";
        mockUser1.phone = @"123123124";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self login]);
    
    ZMConversation *conv1;
    
    // when we search and send connection requests to users
    {
        [self.userSession performChanges:^{
            [self searchAndConnectToUserWithName:userName1 searchQuery:@"Hans"];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // we should see two new active conversations
    {
        ZMUser *realUser1 = [self userForMockUser:mockUser1];
        XCTAssertNotNil(realUser1);
        XCTAssertEqual(realUser1.connection.status, ZMConnectionStatusSent);
        
        conv1 = realUser1.oneToOneConversation;
        XCTAssertNotNil(conv1);
        XCTAssertEqual(conv1.conversationType, ZMConversationTypeConnection);
        
    }
    
    ConversationChangeObserver *observer = self.conversationChangeObserver;
    id token1 = [ConversationChangeInfo addObserver:observer forConversation:conv1];
    [observer clearNotifications];
    
    // when the remote users accept the connection requests
    {
        [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
            [session remotelyAcceptConnectionToUser:mockUser1];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return observer.notifications.count >= 1;
    } timeout:0.6]);
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // we should not see a system message in the conversation
    {
        XCTAssertEqual(conv1.conversationType, ZMConversationTypeOneOnOne);
        
        NSArray *notifications = observer.notifications;
        XCTAssertNotNil(notifications);
        
        BOOL conv1StateChanged = NO;
        BOOL conv1ParticipantsChanged = NO;
        
        for (ConversationChangeInfo *note  in notifications) {
            ZMConversation *conv = note.conversation;
            if (note.participantsChanged) {
                conv1ParticipantsChanged = conv1ParticipantsChanged ? YES :(conv == conv1);
            }
            if (note.connectionStateChanged) {
                conv1StateChanged = conv1StateChanged ? YES :(conv == conv1);
            }
        }
        XCTAssertTrue(conv1StateChanged);
        XCTAssertTrue(conv1ParticipantsChanged);
    }
    
    WaitForAllGroupsToBeEmpty(0.5);
    (void)token1;
}

- (void)testThatItNotifiesObserversWhenWeSendAConnectionRequest
{
    // given two remote users
    NSString *userName1 = @"Hans Von Üser";
    
    __block MockUser *mockUser1;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        mockUser1 = [session insertUserWithName:userName1];
        XCTAssertNotNil(mockUser1.identifier);
        mockUser1.email = @"";
        mockUser1.phone = @"";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self login]);
    
    ZMConversationList *activeConversations = [ZMConversationList conversationsInUserSession:self.userSession];
    NSUInteger activeCount = activeConversations.count;
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:activeConversations];
    [observer clearNotifications];
    
    
    // when we search and send connection requests to users
    {
        [self.userSession performChanges:^{
            [self searchAndConnectToUserWithName:userName1 searchQuery:@"Hans"];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // we should see one new active conversation
    {
        XCTAssertEqual(activeConversations.count, activeCount+1u);
     
        NSArray *notifications = observer.notifications;
        XCTAssertNotNil(notifications);
        
        ConversationListChangeInfo *note = notifications.firstObject;
        XCTAssertNotNil(note);
        XCTAssertEqualObjects(note.insertedIndexes, [NSIndexSet indexSetWithIndex:0]);
        XCTAssertTrue(note.deletedIndexes.count == 0);
        XCTAssertTrue(note.zm_movedIndexPairs.count == 0);
    }
}

- (void)testThatItTheConnectionRequestConversationIsOnTopOfTheConversationList
{
    // given two remote users
    NSString *userName1 = @"Hans Von Üser";
    
    __block MockUser *mockUser;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        mockUser = [session insertUserWithName:userName1];
        XCTAssertNotNil(mockUser.identifier);
        mockUser.email = @"";
        mockUser.phone = @"";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self login]);
    
    NSArray *active = [ZMConversationList conversationsInUserSession:self.userSession];
    
    // when we search and send connection requests to users
    [self.userSession performChanges:^{
        [self searchAndConnectToUserWithName:userName1 searchQuery:@"Hans"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // the new conversation should be the first item in the list

    ZMUser *user = [self userForMockUser:mockUser];
    ZMConversation *conversation = user.oneToOneConversation;
    XCTAssertEqualObjects(active.firstObject, conversation);
}

- (void)testThatItResendsConnectionRequestAfterItWasCancelled
{
    // given
    XCTAssertTrue([self login]);
    WaitForAllGroupsToBeEmpty(0.5);

    MockUser *mockUser = [self createSentConnectionFromUserWithName:@"Hans Von Üser" uuid:NSUUID.createUUID];
    ZMConversation *conversation = [self oneOnOneConversationForConnectedMockUser:mockUser];
    ZMUser *user = [self userForMockUser:mockUser];
    XCTAssertEqual(user, conversation.connectedUser);
    
    ZMConversationList *conversations = [ZMConversationList conversationsIncludingArchivedInUserSession:self.userSession];
    XCTAssertTrue([conversations containsObject:conversation]);
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:conversations];
    
    // when cancelling:
    [user cancelConnectionRequestWithCompletion:^(NSError * error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5);

    XCTAssertFalse([conversations containsObject:conversation]);
    XCTAssertEqual(observer.notifications.count, 1u);
    [observer clearNotifications];

    //when sending again
    [user connectWithCompletion:^(NSError * error) { NOT_USED(error); }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue([conversations containsObject:conversation]);
    XCTAssertEqual(observer.notifications.count, 1u);
}

#pragma mark - ConnectionLimit

- (ZMCustomResponseGeneratorBlock)responseBlockForConnectionLimit;
{
    return ^ZMTransportResponse *(ZMTransportRequest *request) {
        if (![request.path hasPrefix:@"/connections"] || (request.method == ZMMethodGET)) {
            return nil;
        }
        NSInteger statusCode = 403;
        NSDictionary *payload = @{@"label": @"connection-limit",
                                  @"code": @(statusCode),
                                  @"message": @"" };
        return [[ZMTransportResponse alloc] initWithPayload:payload HTTPStatus:statusCode transportSessionError:nil headers:nil apiVersion:0];
    };

}

- (void)testThatItDeletesTheConversationWhenConnectionIsRejectedByBackendAndNotifiesObservers
{
    // given
    NSString *searchUserName = @"Karl McUser";
    [self createUserWithName:searchUserName uuid:NSUUID.createUUID];
    
    self.mockTransportSession.responseGeneratorBlock = self.responseBlockForConnectionLimit;
    
    XCTAssertTrue([self login]);
    ZMConversationList *conversations = [ZMConversationList conversationsInUserSession:self.userSession];
    NSUInteger beforeInsertingCount = conversations.count;
    
    // when
    [self searchAndConnectToUserWithName:searchUserName searchQuery:@"McUser"];
    [self.mockTransportSession waitForAllRequestsToCompleteWithTimeout:0.5];
    
    // then
    XCTAssertEqual(conversations.count, beforeInsertingCount);
}

#pragma mark - MissingLegalHoldConsent

- (ZMCustomResponseGeneratorBlock)responseBlockForMissingLegalHoldConsent;
{
    return ^ZMTransportResponse *(ZMTransportRequest *request) {
        if (![request.path hasPrefix:@"/connections"] || (request.method == ZMMethodGET)) {
            return nil;
        }
        NSDictionary *payload = @{@"label": @"missing-legalhold-consent"};
        return [[ZMTransportResponse alloc] initWithPayload:payload HTTPStatus:412 transportSessionError:nil headers:nil apiVersion:0];
    };

}

- (void)testThatItDeletesTheConversationWhenConnectionIsRejectedByBackend_MissingLegalHoldConsent
{
    // given
    NSString *searchUserName = @"Karl McUser";
    [self createUserWithName:searchUserName uuid:NSUUID.createUUID];

    self.mockTransportSession.responseGeneratorBlock = self.responseBlockForMissingLegalHoldConsent;

    XCTAssertTrue([self login]);
    ZMConversationList *conversations = [ZMConversationList conversationsInUserSession:self.userSession];
    NSUInteger beforeInsertingCount = conversations.count;

    // when
    [self searchAndConnectToUserWithName:searchUserName searchQuery:@"McUser"];
    [self.mockTransportSession waitForAllRequestsToCompleteWithTimeout:0.5];

    // then
    XCTAssertEqual(conversations.count, beforeInsertingCount);
}

@end
