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


#import "ConversationTestsBase.h"
#import "Tests-Swift.h"

@interface ConversationTestsBase()

@property (nonatomic, strong) NSMutableArray *testFiles;

@end

@implementation ConversationTestsBase

- (void)setUp{
    [super setUp];
    self.testFiles = [NSMutableArray array];
    [self setupGroupConversationWithOnlyConnectedParticipants];

    BackgroundActivityFactory.sharedFactory.activityManager = UIApplication.sharedApplication;
}

- (void)tearDown
{
    BackgroundActivityFactory.sharedFactory.activityManager = nil;

    [self.userSession.syncManagedObjectContext performGroupedBlockAndWait:^{
        [self.userSession.syncManagedObjectContext zm_teardownMessageObfuscationTimer];
    }];
    XCTAssert([self waitForAllGroupsToBeEmptyWithTimeout: 0.5]);
    
    [self.userSession.managedObjectContext zm_teardownMessageDeletionTimer];
    XCTAssert([self waitForAllGroupsToBeEmptyWithTimeout: 0.5]);
    self.groupConversationWithOnlyConnected = nil;

    for (NSURL *testFile in self.testFiles) {
        [NSFileManager.defaultManager removeItemAtURL:testFile error:nil];
    }
    [super tearDown];
}

- (NSURL *)createTestFile:(NSString *)name
{
    NSError *error;
    NSFileManager *fm = NSFileManager.defaultManager;
    NSURL *directory = [fm URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    XCTAssertNil(error);

    NSString *fileName = [NSString stringWithFormat:@"%@.dat", name];
    NSURL *fileURL = [directory URLByAppendingPathComponent:fileName].filePathURL;
    NSData *testData = [NSData secureRandomDataOfLength:256];
    XCTAssertTrue([testData writeToFile:fileURL.path atomically:YES]);

    [self.testFiles addObject:fileURL];

    return fileURL;
}

- (void)makeConversationSecured:(ZMConversation *)conversation
{
    NSArray *participants = [[conversation localParticipants] allObjects];
    NSArray *allClients = [participants flattenWithBlock:^id(ZMUser *user) {
        return [user clients].allObjects;
    }];
    UserClient *selfClient = [ZMUser selfUserInUserSession:self.userSession].selfClient;
    
    [self.userSession performChanges:^{
        for (UserClient *client in allClients) {
            [selfClient trustClient:client];
        }
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue(conversation.allUsersTrusted);
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
}

- (void)makeConversationSecuredWithIgnored:(ZMConversation *)conversation
{
    ZMUser *selfUser = [self userForMockUser:self.selfUser];
    NSArray *participants = [[conversation localParticipants] allObjects];
    NSArray *allClients = [participants flattenWithBlock:^id(ZMUser *user) {
        return [user clients].allObjects;
    }];
    
    NSMutableSet *allClientsSet = [NSMutableSet setWithArray:allClients];
    [allClientsSet minusSet:[NSSet setWithObject:selfUser.selfClient]];
    
    [self.userSession performChanges:^{
        [selfUser.selfClient trustClients:allClientsSet];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    
    [self.userSession performChanges:^{
        [selfUser.selfClient ignoreClients:allClientsSet];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
}

- (void)setupInitialSecurityLevel:(ZMConversationSecurityLevel)initialSecurityLevel inConversation:(ZMConversation *)conversation
{
    if(conversation.securityLevel == initialSecurityLevel) {
        return;
    }
    switch (initialSecurityLevel) {
        case ZMConversationSecurityLevelSecure:
        {
            [self makeConversationSecured:conversation];
            XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        }
            break;
            
        case ZMConversationSecurityLevelSecureWithIgnored:
        {
            [self makeConversationSecuredWithIgnored:conversation];
            XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
        }
            break;
        default:
            break;
    }
}

- (void)setDate:(NSDate *)date forAllEventsInMockConversation:(MockConversation *)conversation
{
    for(MockEvent *event in conversation.events) {
        event.time = date;
    }
}

- (void)setupGroupConversationWithOnlyConnectedParticipants
{
    [self createSelfUserAndConversation];
    [self createExtraUsersAndConversations];

    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        
        NSDate *selfConversationDate = [NSDate dateWithTimeIntervalSince1970:1400157817];
        NSDate *connection1Date = [NSDate dateWithTimeInterval:500 sinceDate:selfConversationDate];
        NSDate *connection2Date = [NSDate dateWithTimeInterval:1000 sinceDate:connection1Date];
        NSDate *groupConversationDate = [NSDate dateWithTimeInterval:1000 sinceDate:connection2Date];
        
        [self setDate:selfConversationDate forAllEventsInMockConversation:self.selfConversation];
        [self setDate:connection1Date forAllEventsInMockConversation:self.selfToUser1Conversation];
        [self setDate:connection2Date forAllEventsInMockConversation:self.selfToUser2Conversation];
        [self setDate:groupConversationDate forAllEventsInMockConversation:self.groupConversation];
        
        self.connectionSelfToUser1.lastUpdate = connection1Date;
        self.connectionSelfToUser2.lastUpdate = connection2Date;

        self.groupConversationWithOnlyConnected = [session insertGroupConversationWithSelfUser:self.selfUser
                                                                                    otherUsers:@[self.user1, self.user2]];
        self.groupConversationWithOnlyConnected.creator = self.selfUser;
        [self.groupConversationWithOnlyConnected changeNameByUser:self.selfUser name:@"Group conversation with only connected participants"];
        
        self.emptyGroupConversation = [session insertGroupConversationWithSelfUser:self.selfUser otherUsers:@[]];
        self.emptyGroupConversation.creator = self.selfUser;
        [self.emptyGroupConversation changeNameByUser:self.selfUser name:@"Empty group conversation"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                                    ignoreLastRead:(BOOL)ignoreLastRead
                        onRemoteMessageCreatedWith:(void(^)(void))createMessage
                                            verify:(void(^)(ZMConversation *))verifyConversation
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    // when
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation>  _Nonnull __strong __unused session) {
        createMessage();
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ConversationChangeInfo *unreadCountChange = [observer.notifications firstObjectMatchingWithBlock:^BOOL(ConversationChangeInfo *change) {
        return change.unreadCountChanged;
    }];
    
    ConversationChangeInfo *messageChange = [observer.notifications firstObjectMatchingWithBlock:^BOOL(ConversationChangeInfo *change) {
        return change.messagesChanged;
    }];
        
    XCTAssertNotNil(messageChange);
    XCTAssertTrue(messageChange.messagesChanged);
    XCTAssertFalse(messageChange.participantsChanged);
    XCTAssertTrue(messageChange.lastModifiedDateChanged);
    XCTAssertFalse(messageChange.connectionStateChanged);
    
    if(!ignoreLastRead) {
        XCTAssertTrue(unreadCountChange.unreadCountChanged);
    }
    
    verifyConversation(conversation);
}

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                        onRemoteMessageCreatedWith:(void(^)(void))createMessage
                                verifyWithObserver:(void(^)(ZMConversation *, ConversationChangeObserver *))verifyConversation;
{
    [self testThatItSendsANotificationInConversation:mockConversation
                                     afterLoginBlock:nil
                          onRemoteMessageCreatedWith:createMessage
                                  verifyWithObserver:verifyConversation];
}

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                                   afterLoginBlock:(void(^)(void))afterLoginBlock
                        onRemoteMessageCreatedWith:(void(^)(void))createMessage
                                verifyWithObserver:(void(^)(ZMConversation *, ConversationChangeObserver *))verifyConversation;
{
    // given
    XCTAssertTrue([self login]);
    afterLoginBlock();
    WaitForAllGroupsToBeEmpty(0.5);
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    // when
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation>  _Nonnull __strong __unused session) {
        createMessage();
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    verifyConversation(conversation, observer);
}

- (BOOL)conversation:(ZMConversation *)conversation hasMessagesWithNonces:(NSArray *)nonces
{
    BOOL hasAllMessages = YES;
    for (NSUUID *nonce in nonces) {
        BOOL hasMessageWithNonce = [conversation.allMessages.allObjects containsObjectMatchingWithBlock:^BOOL(ZMMessage *msg) {
            return [msg.nonce isEqual:nonce];
        }];
        hasAllMessages &= hasMessageWithNonce;
    }
    return hasAllMessages;
}

- (void)testThatItAppendsMessageToConversation:(MockConversation *)mockConversation
                                     withBlock:(NSArray *(^)(MockTransportSession<MockTransportSessionObjectCreation> *session))appendMessages
                                        verify:(void(^)(ZMConversation *))verifyConversation
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    // when
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    __block NSArray *messsagesNonces;
    
    // expect
    XCTestExpectation *exp = [self expectationWithDescription:@"All messages received"];
    observer.notificationCallback = (ObserverCallback) ^(ConversationChangeInfo * __unused note) {
        BOOL hasAllMessages = [self conversation:conversation hasMessagesWithNonces:messsagesNonces];
        if (hasAllMessages) {
            [exp fulfill];
        }
    };
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        messsagesNonces = appendMessages(((MockTransportSession<MockTransportSessionObjectCreation> *)session));
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    verifyConversation(conversation);
    
}

@end

