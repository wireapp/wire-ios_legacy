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

@import ZMCDataModel;
#import "MessagingTest.h"

@interface ZMSyncMergePolicyTests : MessagingTest

@property (nonatomic) ZMConversation *uiConversation;
@property (nonatomic) ZMConversation *syncConversation;
@property (nonatomic) id noteToken;
@property (nonatomic) id didChangeNoteToken;

@property (nonatomic) NSNotification *mergeNotificationToUIMOC;
@property (nonatomic) NSNotification *mergeNotificationToSyncMOC;
@property (nonatomic) NSMutableArray *objectsDidChangeNotifications;
@property (nonatomic) NSDate *lastMessageTime;

@end

@implementation ZMSyncMergePolicyTests

- (void)setUp {
    
    [super setUp];
    
    self.lastMessageTime = [NSDate date];
    
    self.uiConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    self.uiConversation.conversationType = ZMConversationTypeOneOnOne;
    [(ZMMessage *)[self.uiConversation appendMessageWithText:@"A"] setServerTimestamp:[self nextDate]];
    [(ZMMessage *)[self.uiConversation appendMessageWithText:@"B"] setServerTimestamp:[self nextDate]];
    [(ZMMessage *)[self.uiConversation appendMessageWithText:@"C"] setServerTimestamp:[self nextDate]];
    [self.uiConversation.mutableMessages sortUsingDescriptors:ZMMessage.defaultSortDescriptors];
    [self.uiMOC saveOrRollback];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        self.syncConversation = (id) [self.syncMOC objectWithID:self.uiConversation.objectID];
    }];
    
    self.noteToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSManagedObjectContext *savingMOC = note.object;
        if (savingMOC == self.uiMOC) {
            XCTAssertNil(self.mergeNotificationToSyncMOC);
            self.mergeNotificationToSyncMOC = note;
        } else if (savingMOC == self.syncMOC) {
            XCTAssertNil(self.mergeNotificationToUIMOC);
            self.mergeNotificationToUIMOC = note;
        }
    }];
    
    self.objectsDidChangeNotifications = [NSMutableArray array];
    self.didChangeNoteToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC queue:nil usingBlock:^(NSNotification *note) {
        [self.objectsDidChangeNotifications addObject:note];
    }];

}

- (NSDate *)nextDate
{
    NSDate *d = self.lastMessageTime;
    self.lastMessageTime = [self.lastMessageTime dateByAddingTimeInterval:60];
    return d;
}

- (void)mergeMOC_SyncFirst
{
    if(self.mergeNotificationToSyncMOC != nil) {
        [self.syncMOC performGroupedBlockAndWait:^{
            [self.syncMOC mergeChangesFromContextDidSaveNotification:self.mergeNotificationToSyncMOC];
            self.mergeNotificationToSyncMOC = nil;
            [self.syncMOC processPendingChanges];
        }];
    }
    
    if(self.mergeNotificationToUIMOC != nil) {
        [self.uiMOC mergeChangesFromContextDidSaveNotification:self.mergeNotificationToUIMOC];
        self.mergeNotificationToUIMOC = nil;
        [self.uiMOC processPendingChanges];
    }
}

- (void)mergeMOC_UIFirst
{
    if(self.mergeNotificationToUIMOC != nil) {
        [self.uiMOC mergeChangesFromContextDidSaveNotification:self.mergeNotificationToUIMOC];
        self.mergeNotificationToUIMOC = nil;
        
    }
    
    if(self.mergeNotificationToSyncMOC != nil) {
        [self.syncMOC performGroupedBlockAndWait:^{
            [self.syncMOC mergeChangesFromContextDidSaveNotification:self.mergeNotificationToSyncMOC];
            self.mergeNotificationToSyncMOC = nil;
            
        }];
    }
    
}


- (void)tearDown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.noteToken];
    self.noteToken = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self.didChangeNoteToken];
    self.didChangeNoteToken = nil;
    self.objectsDidChangeNotifications = nil;

    self.uiConversation = nil;
    self.syncConversation = nil;
    self.mergeNotificationToUIMOC = nil;
    self.mergeNotificationToSyncMOC = nil;
    [super tearDown];
}

- (void)testThatItMergesConflictingMessagesFromSyncMOCToUiMOC
{
    // given
    [(ZMMessage *)[self.uiConversation appendMessageWithText:@"D"] setServerTimestamp:[self nextDate]];
    [self.uiConversation.mutableMessages sortUsingDescriptors:ZMMessage.defaultSortDescriptors];
    
    // when
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMClientMessage *m = [ZMClientMessage insertNewObjectInManagedObjectContext:self.syncMOC];
        [m addData:[ZMGenericMessage messageWithText:@"X" nonce:[NSUUID createUUID].transportString].data];
        m.serverTimestamp = [self nextDate];
        [self.syncConversation.mutableMessages addObject:m];
        XCTAssert([self.syncMOC saveOrRollback]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"A", @"B", @"C", @"D"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"A", @"B", @"C", @"X"] failureRecorder:NewFailureRecorder()];
    
    // and when
    XCTAssert([self.uiMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"A", @"B", @"C", @"D", @"X"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"A", @"B", @"C", @"X"] failureRecorder:NewFailureRecorder()];
    
    // and when
    [self mergeMOC_SyncFirst];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"A", @"B", @"C", @"D", @"X"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"A", @"B", @"C", @"D", @"X"] failureRecorder:NewFailureRecorder()];
}

- (void)testThatItMergesReorderingOfMessagesFromSyncMOCToUiMOC
{
    // given
    [(ZMMessage *)[self.uiConversation appendMessageWithText:@"D"] setServerTimestamp:[self nextDate]];
    [self.uiConversation.mutableMessages sortUsingDescriptors:ZMMessage.defaultSortDescriptors];

    // when
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMClientMessage *m = self.syncConversation.messages[0];
        m.serverTimestamp = [self nextDate];
        [self.syncConversation.mutableMessages sortUsingDescriptors:ZMMessage.defaultSortDescriptors];
        XCTAssert([self.syncMOC saveOrRollback]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"A", @"B", @"C", @"D"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"B", @"C", @"A"] failureRecorder:NewFailureRecorder()];
    
    // and when
    XCTAssert([self.uiMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"B", @"C", @"A", @"D"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"B", @"C", @"A"] failureRecorder:NewFailureRecorder()];
    
    // and when
    [self mergeMOC_SyncFirst];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"B", @"C", @"A", @"D"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"B", @"C", @"A", @"D"] failureRecorder:NewFailureRecorder()];
}


- (void)testThatItMergesReorderingOfMessagesFromUiMOCToSyncMOC
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        [(ZMMessage *)[self.syncConversation appendMessageWithText:@"D"] setServerTimestamp:[self nextDate]];
        [self.syncConversation.mutableMessages sortUsingDescriptors:ZMMessage.defaultSortDescriptors];
    }];
    
    // when
    ZMTextMessage *m = self.uiConversation.messages[0];
    m.serverTimestamp = [self nextDate];
    [self.uiConversation.mutableMessages sortUsingDescriptors:ZMMessage.defaultSortDescriptors];
    XCTAssert([self.uiMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"B", @"C", @"A"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"A", @"B", @"C", @"D"] failureRecorder:NewFailureRecorder()];
    
    // and when
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssert([self.syncMOC saveOrRollback]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"B", @"C", @"A"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"B", @"C", @"A", @"D"] failureRecorder:NewFailureRecorder()];

    
    // and when
    [self mergeMOC_SyncFirst];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"B", @"C", @"A", @"D"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"B", @"C", @"A", @"D"] failureRecorder:NewFailureRecorder()];
}

- (void)testThatItMergesConflictingMessagesFromSyncUiToSyncMOC
{
    // given
    [(ZMMessage *)[self.uiConversation appendMessageWithText:@"D"] setServerTimestamp:[self nextDate]];
    [self.uiConversation.mutableMessages sortUsingDescriptors:ZMMessage.defaultSortDescriptors];

    // when
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMClientMessage *m = [ZMClientMessage insertNewObjectInManagedObjectContext:self.syncMOC];
        [m addData:[ZMGenericMessage messageWithText:@"X" nonce:[NSUUID createUUID].transportString].data];
        m.serverTimestamp = [self nextDate];
        [self.syncConversation.mutableMessages addObject:m];
    }];
    XCTAssert([self.uiMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"A", @"B", @"C", @"D"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"A", @"B", @"C", @"X"] failureRecorder:NewFailureRecorder()];
    
    // and when
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssert([self.syncMOC saveOrRollback]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"A", @"B", @"C", @"D"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"A", @"B", @"C", @"D", @"X"] failureRecorder:NewFailureRecorder()];
    
    // and when
    [self mergeMOC_SyncFirst];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [self checkTextInConversation:self.uiConversation isEqual:@[@"A", @"B", @"C", @"D", @"X"] failureRecorder:NewFailureRecorder()];
    [self checkTextInConversation:self.syncConversation isEqual:@[@"A", @"B", @"C", @"D", @"X"] failureRecorder:NewFailureRecorder()];
}

- (void)checkTextInConversation:(ZMConversation *)conversation isEqual:(NSArray *)texts failureRecorder:(ZMTFailureRecorder *)fr;
{
    [conversation.managedObjectContext performBlockAndWait:^{
        NSOrderedSet *t;
        t = [conversation.messages mapWithBlock:^id(id<ZMConversationMessage> msg) {
            return msg.messageText;
        }];
        FHAssertEqualArrays(fr, t.array, texts);
    }];
}

@end

