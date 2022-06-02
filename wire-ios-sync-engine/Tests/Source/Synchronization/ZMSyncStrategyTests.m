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


#import "ZMSyncStrategyTests.h"
#import "ZMSyncStrategy+Internal.h"
#import "ZMSyncStrategy+ManagedObjectChanges.h"
#import "MessagingTest+EventFactory.h"
#import "Tests-Swift.h"

// Transcoders & strategies
#import "MessagingTest+EventFactory.h"
#import "Tests-Swift.h"

@interface OCMockObject (TearDown)
- (void)tearDown;
@end

// Only needed to be able to call these internal OCMock methods on teardown
@protocol MockOCMockMock <NSObject>
- (NSInvocation *)recordedInvocation;

@end

// A lot of objects end up in retain cycles because of extensive mocking.
// We need to break them manually by releasing some of the internal arrays
@implementation OCMockObject (TearDown)
- (void)tearDown
{
    for (id recorder in stubs) {
        objc_removeAssociatedObjects([recorder recordedInvocation]);
    }
    [stubs removeAllObjects];
    [exceptions removeAllObjects];
    [expectations removeAllObjects];
    [invocations removeAllObjects];
}

@end


@implementation ZMSyncStrategyTests;

- (void)cancelTaskWithIdentifier:(ZMTaskIdentifier *)taskIdentifier
{
    NOT_USED(taskIdentifier);
}

- (void)didStartSlowSync { }

- (void)didFinishSlowSync { }

- (void)didStartQuickSync { }

- (void)didFinishQuickSync { }

- (void)didRegisterSelfUserClient:(UserClient *)userClient {
    NOT_USED(userClient);
}

- (void)didFailToRegisterSelfUserClient:(NSError *)error {
    NOT_USED(error);
}

- (void)didDeleteSelfUserClient:(NSError *)error {
    NOT_USED(error);
}

- (void)setUp
{
    [super setUp];
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
    selfUser.remoteIdentifier = self.userIdentifier;
    
    ZMConversation *selfConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    selfConversation.remoteIdentifier = self.userIdentifier;
    selfConversation.conversationType = ZMConversationTypeSelf;
    
    self.syncMOC.zm_lastNotificationID = [NSUUID UUID];
    
    [self.syncMOC saveOrRollback];
        
    self.syncStateDelegate = [[MockSyncStateDelegate alloc] init];
    self.mockEventConsumer = [[MockEventConsumer alloc]  init];
    self.mockContextChangeTracker = [[MockContextChangeTracker alloc] init];
    
    MockStrategyDirectory *mockStrategyDirectory =
    [[MockStrategyDirectory alloc] init];
    mockStrategyDirectory.eventConsumers = @[self.mockEventConsumer];
    mockStrategyDirectory.contextChangeTrackers = @[self.mockContextChangeTracker];
    
    self.fetchRequestForTrackedObjects1 = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    self.fetchRequestForTrackedObjects1.predicate = [NSPredicate predicateWithFormat:@"name != nil"];
    self.fetchRequestForTrackedObjects2 = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    self.fetchRequestForTrackedObjects2.predicate = [NSPredicate predicateWithFormat:@"userDefinedName != nil"];

    self.applicationStatusDirectory = [[ApplicationStatusDirectory alloc] initWithManagedObjectContext:self.syncMOC cookieStorage:[[FakeCookieStorage alloc] init] requestCancellation:self application:self.application syncStateDelegate:self analytics:nil];
    
    NotificationDispatcher *notificationDispatcher =
    [[NotificationDispatcher alloc] initWithManagedObjectContext:self.coreDataStack.viewContext];
    
    EventProcessingTracker *eventProcessingTracker = [[EventProcessingTracker alloc] init];
        
    self.sut = [[ZMSyncStrategy alloc] initWithContextProvider:self.coreDataStack
                                       notificationsDispatcher:notificationDispatcher
                                    applicationStatusDirectory:self.applicationStatusDirectory
                                                   application:self.application
                                             strategyDirectory:mockStrategyDirectory
                                        eventProcessingTracker:eventProcessingTracker];
    
    self.application.applicationState = UIApplicationStateBackground;
    
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)tearDown;
{
    self.applicationStatusDirectory = nil;
    self.fetchRequestForTrackedObjects1 = nil;
    self.fetchRequestForTrackedObjects2 = nil;
    self.syncStateDelegate = nil;
    [self.sut tearDown];
    self.sut = nil;
    [super tearDown];
}

- (void)testThatCallingNextRequestFetchesObjectsAndDistributesThemToTheChangeTracker
{
    // given
    __block ZMUser *user;
    __block ZMConversation *conversation;
    [self.syncMOC performGroupedBlockAndWait:^{
        user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"User1";
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.userDefinedName = @"Conversation1";
        [self.syncMOC saveOrRollback];
    }];
    
    self.mockContextChangeTracker.fetchRequest = self.fetchRequestForTrackedObjects2;
        
    // when
    (void)[self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertTrue(self.mockContextChangeTracker.addTrackedObjectsCalled);
    XCTAssertTrue(self.mockContextChangeTracker.fetchRequestForTrackedObjectsCalled);
}

- (void)testThatManagedObjectChangesArePassedToAllSyncObjectsCaches
{
    
    // given
    id firstObject = [[ZMManagedObject alloc] init];
    id secondObject = [[ZMManagedObject alloc] init];
    
    NSSet *cacheInsertSet = [NSSet setWithObject:firstObject];
    NSSet *cacheUpdateSet = [NSSet setWithObject:secondObject];
    
    NSMutableSet *totalSet = [NSMutableSet setWithSet:cacheInsertSet];
    [totalSet unionSet:cacheUpdateSet];
        
    // when
    [self.sut processSaveWithInsertedObjects:cacheInsertSet updateObjects:cacheUpdateSet];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockContextChangeTracker.objectsDidChangeCalled);
}


- (void)testThatItSynchronizesChangesInUIContextToSyncContext
{
    // given
    ZMUser *uiUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.sut.syncMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        ZMUser *syncUser =  (ZMUser *)[self.sut.syncMOC objectWithID:uiUser.objectID];
        XCTAssertNotNil(syncUser);
        XCTAssertNil(syncUser.name);
    }];
    
    NSString *name = @"very-unique-name_w938ruojfdmnsf";

    // when
    uiUser.name = name;
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);
    // sut automagically synchronizes objects

    // then
    [self.sut.syncMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        ZMUser *syncUser =  (ZMUser *)[self.sut.syncMOC objectWithID:uiUser.objectID];
        XCTAssertNotNil(syncUser);
        XCTAssertEqualObjects(syncUser.name, name);
    }];
}

- (void)testThatItSynchronizesChangesInSyncContextToUIContext
{
    __block ZMUser *syncUser;
    
    // expect
    [self expectationForNotification:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC handler:nil];
    
    // when
    [self.syncMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        syncUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        XCTAssertTrue([self.syncMOC saveOrRollback]);
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    
    ZMUser *uiUser =  (ZMUser *)[self.uiMOC objectWithID:syncUser.objectID];
    XCTAssertNotNil(uiUser);
    XCTAssertNil(uiUser.name);
    
    NSString *name = @"very-unique-name_ps9ijsdnmf";

    // and expect
    [self expectationForNotification:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC handler:^BOOL(NSNotification *notification ZM_UNUSED) {
        return uiUser.name != nil;
    }];
    
    // when
    [self.syncMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        syncUser.name = name;
        XCTAssertTrue([self.syncMOC saveOrRollback]);
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.2]);
    
    // then
    XCTAssertEqualObjects(name, uiUser.name);
}

- (void)testThatContextChangeTrackerIsInformed_WhenObjectIsUpdated_OnUIContext {
    // given
    [ZMUser selfUserInContext:self.uiMOC].name = @"New name";
    
    // when
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockContextChangeTracker.objectsDidChangeCalled);
}

- (void)testThatContextChangeTrackerIsInformed_WhenObjectIsUpdated_OnSyncContext {
    // given
    [self.syncMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        [ZMUser selfUserInContext:self.self.syncMOC].name = @"New name";
    }];
    
    // when
        [self.syncMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        XCTAssertTrue([self.syncMOC saveOrRollback]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockContextChangeTracker.objectsDidChangeCalled);
}

- (void)testThatARollbackTriggersAnObjectsDidChange;
{
    // given
    __block ZMConversation *syncConversation;
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        syncConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        syncConversation.conversationType = ZMConversationTypeOneOnOne;
        [self.syncMOC saveOrRollback];
        moid = syncConversation.objectID;
    }];
    ZMConversation *uiConversation = (id) [self.uiMOC objectWithID:moid];
    WaitForAllGroupsToBeEmpty(0.5);
    //
    self.sut.contextMergingDisabled = YES;
    NSMutableArray *objectsDidChangeNotifications = [NSMutableArray array];
    id token1 = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC queue:nil usingBlock:^(NSNotification *note) {
        
        [objectsDidChangeNotifications addObject:note];
    }];
    NSMutableArray *didSaveNotificationsA = [NSMutableArray array];
    id token2A = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:self.uiMOC queue:nil usingBlock:^(NSNotification *note) {
        
        [didSaveNotificationsA addObject:note];
    }];
    NSMutableArray *didSaveNotificationsB = [NSMutableArray array];
    id token2B = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:self.syncMOC queue:nil usingBlock:^(NSNotification *note) {
        
        [didSaveNotificationsB addObject:note];
    }];
    //
    uiConversation.userDefinedName = @"UI";
    [self.syncMOC performGroupedBlockAndWait:^{
        syncConversation.userDefinedName = @"SYNC";
    }];
    [self.uiMOC saveOrRollback];
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC saveOrRollback];
    }];
    
    // when
    //
    // The conversation in the UI context is still 'USER', and we expect
    // 1 objects-did-cahnge about it changing to 'SYNC'
    [objectsDidChangeNotifications removeAllObjects];
    XCTAssertEqualObjects(uiConversation.userDefinedName, @"UI");
    // MERGE:
    self.sut.contextMergingDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:token2A];
    [[NSNotificationCenter defaultCenter] removeObserver:token2B];
    for (NSNotification *note in didSaveNotificationsA) {
        [[NSNotificationCenter defaultCenter] postNotification:note];
    }
    for (NSNotification *note in didSaveNotificationsB) {
        [[NSNotificationCenter defaultCenter] postNotification:note];
    }
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(uiConversation.userDefinedName, @"SYNC");
    XCTAssertEqual(objectsDidChangeNotifications.count, 1u);
    NSDictionary *userInfo = [(NSNotification *) objectsDidChangeNotifications.lastObject userInfo];
    XCTAssertEqual([userInfo[NSRefreshedObjectsKey] anyObject], uiConversation);
    
    // finally
    [[NSNotificationCenter defaultCenter] removeObserver:token1];
}

- (void)testThatItMergesTheUserInfoOfContexts {
    
    // The security level degradation info is stored in the user info. I'm using this one to verify that it is merged correcly
    // GIVEN
    __block ZMOTRMessage *message;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        conversation.remoteIdentifier = [NSUUID createUUID];
        
        message = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo bar bar bar"];
        message.causedSecurityLevelDegradation = YES;
        
        // WHEN
        [self.syncMOC saveOrRollback];
    }];
    [self spinMainQueueWithTimeout:0.2];
    
    // THEN
    ZMOTRMessage *uiMessage = [self.uiMOC existingObjectWithID:message.objectID error:nil];
    XCTAssertTrue(uiMessage.causedSecurityLevelDegradation);
}

@end

@implementation ZMSyncStrategyTests (Background)

- (void)goToBackground
{
    [self.application simulateApplicationDidEnterBackground];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)goToForeground
{
    [self.application simulateApplicationWillEnterForeground];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItUpdateOperationStatusWhenTheAppEntersBackground
{
    // given
    self.applicationStatusDirectory.operationStatus.isInBackground = NO;
    
    // when
    [self goToBackground];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.applicationStatusDirectory.operationStatus.isInBackground);
    
}


- (void)testThatItUpdateOperationStatusWhenTheAppWillEnterForeground
{
    // given
    self.applicationStatusDirectory.operationStatus.isInBackground = YES;

    // when
    [self goToForeground];
    
    // then
    XCTAssertFalse(self.applicationStatusDirectory.operationStatus.isInBackground);
}

- (void)testThatItNotifiesTheOperationLoopOfNewOperationWhenEnteringBackground
{
    // expect
    [self expectationForNotification:@"RequestAvailableNotification" object:nil handler:nil];

    // when
    [self goToBackground];
    
    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItNotifiesTheOperationLoopOfNewOperationWhenEnteringForeground
{
    // expect
    [self expectationForNotification:@"RequestAvailableNotification" object:nil handler:nil];
    
    // when
    [self goToForeground];
    
    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end
