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


#import "ZMBaseManagedObjectTest.h"
#import <libkern/OSAtomic.h>
#import <CommonCrypto/CommonCrypto.h>

#import "WireDataModelTests-Swift.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "NSManagedObjectContext+zmessaging-Internal.h"
#import "MockModelObjectContextFactory.h"

#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMConversation+UnreadCount.h"

#import "NSString+RandomString.h"

@import WireTransport.Testing;

@interface ZMBaseManagedObjectTest ()

@property (nonatomic, readwrite) NSUUID *userIdentifier;
@property (nonatomic) CoreDataStack *coreDataStack;
@property (nonatomic) NSTimeInterval originalConversationLastReadTimestampTimerValue; // this will speed up the tests A LOT

@end


@implementation ZMBaseManagedObjectTest

- (BOOL)shouldUseRealKeychain;
{
    return NO;
}

- (BOOL)shouldUseInMemoryStore;
{
    return YES;
}

- (void)performPretendingUiMocIsSyncMoc:(void(^)(void))block;
{
    if(!block) {
        return;
    }
    [self.uiMOC resetContextType];
    [self.uiMOC markAsSyncContext];
    block();
    [self.uiMOC resetContextType];
    [self.uiMOC markAsUIContext];
}

- (void)performPretendingSyncMocIsUiMoc:(void(^)(void))block
{
    if(!block) {
        return;
    }
    [self.syncMOC resetContextType];
    [self.syncMOC markAsUIContext];
    block();
    [self.syncMOC resetContextType];
    [self.syncMOC markAsSyncContext];
}

- (void)setUp;
{
    [super setUp];

    [ZMPersistentCookieStorage setDoNotPersistToKeychain:!self.shouldUseRealKeychain];

    self.originalConversationLastReadTimestampTimerValue = ZMConversationDefaultLastReadTimestampSaveDelay;
    ZMConversationDefaultLastReadTimestampSaveDelay = 0.02;

    self.userIdentifier = NSUUID.UUID;
    self.coreDataStack = [self createCoreDataStack];
    
    NSString *testName = NSStringFromSelector(self.invocation.selector);
    NSString *methodName = [NSString stringWithFormat:@"setup%@%@", [testName substringToIndex:1].capitalizedString, [testName substringFromIndex:1]];
    SEL selector = NSSelectorFromString(methodName);
    if ([self respondsToSelector:selector]) {
        ZM_SILENCE_CALL_TO_UNKNOWN_SELECTOR([self performSelector:selector]);
    }

    [self setupKeyStore];
    [self setupTimers];
    [self setupCaches];

    WaitForAllGroupsToBeEmpty(500); // we want the test to get stuck if there is something wrong. Better than random failures
}

- (void)setupTimers 
{
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC zm_createMessageObfuscationTimer];
    }];
    [self.uiMOC zm_createMessageDeletionTimer];
}

- (void)setupKeyStore
{
    [self performPretendingUiMocIsSyncMoc:^{
        NSURL *url = [CoreDataStack accountDataFolderWithAccountIdentifier:self.userIdentifier
                                                  applicationContainer:self.storageDirectory];
        [self.uiMOC setupUserKeyStoreInAccountDirectory:url
                                   applicationContainer:self.storageDirectory];
    }];
}

- (void)tearDown;
{
    ZMConversationDefaultLastReadTimestampSaveDelay = self.originalConversationLastReadTimestampTimerValue;

    WaitForAllGroupsToBeEmpty(500); // we want the test to get stuck if there is something wrong. Better than random failures
    [self wipeCaches];
    self.coreDataStack = nil;
    [self deleteStorageDirectoryAndReturnError:nil];
    [super tearDown];
}

- (NSManagedObjectContext *)uiMOC
{
    return self.coreDataStack.viewContext;
}

- (NSManagedObjectContext *)syncMOC
{
    return self.coreDataStack.syncContext;
}

- (NSManagedObjectContext *)searchMOC
{
    return self.coreDataStack.searchContext;
}

- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistentStore
{
    self.coreDataStack = nil;
    self.coreDataStack = [self createCoreDataStack];
    [self setupTimers];
    [self setupCaches];
}

@end


@implementation ZMBaseManagedObjectTest (UserTesting)

- (void)setEmailAddress:(NSString *)emailAddress onUser:(ZMUser *)user;
{
    user.emailAddress = emailAddress;
}

- (void)setPhoneNumber:(NSString *)phoneNumber onUser:(ZMUser *)user;
{
    user.phoneNumber = phoneNumber;
}

@end


@implementation ZMBaseManagedObjectTest (FilesInCache)

- (void)setupCaches
{
    self.uiMOC.zm_userImageCache = [[UserImageLocalCache alloc] initWithLocation:nil];
    self.uiMOC.zm_fileAssetCache = [[FileAssetCache alloc] initWithLocation:nil];

    [self.syncMOC performGroupedBlockAndWait:^{
        self.syncMOC.zm_fileAssetCache = self.uiMOC.zm_fileAssetCache;
        self.syncMOC.zm_userImageCache = self.uiMOC.zm_userImageCache;
    }];
}

- (void)wipeCaches
{
    [self.uiMOC.zm_fileAssetCache wipeCaches];
    [self.uiMOC.zm_userImageCache wipeCache];

    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC.zm_fileAssetCache wipeCaches];
        [self.syncMOC.zm_userImageCache wipeCache];
    }];
    [PersonName.stringsToPersonNames removeAllObjects];
}

@end


@implementation ZMBaseManagedObjectTest (OTR)

- (UserClient *)createSelfClient
{
    return [self createSelfClientOnMOC:self.uiMOC];
}

- (UserClient *)createSelfClientOnMOC:(NSManagedObjectContext *)moc
{
    __block ZMUser *selfUser = nil;
    
    selfUser = [ZMUser selfUserInContext:moc];
    selfUser.remoteIdentifier = selfUser.remoteIdentifier ?: [NSUUID createUUID];
    UserClient *selfClient = [UserClient insertNewObjectInManagedObjectContext:moc];
    selfClient.remoteIdentifier = [NSString createAlphanumericalString];
    selfClient.user = selfUser;
    
    [moc setPersistentStoreMetadata:selfClient.remoteIdentifier forKey:ZMPersistedClientIdKey];
    
    [self performPretendingUiMocIsSyncMoc:^{
        NSDictionary *payload = @{@"id": selfClient.remoteIdentifier, @"type": @"permanent", @"time": [[NSDate date] transportString]};
        NOT_USED([UserClient createOrUpdateSelfUserClient:payload context:moc]);
    }];
    
    [moc saveOrRollback];
    
    return selfClient;
}

- (UserClient *)createClientForUser:(ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser
{
    return [self createClientForUser:user createSessionWithSelfUser:createSessionWithSeflUser onMOC:self.uiMOC];
}

- (UserClient *)createClientForUser:(ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser onMOC:(NSManagedObjectContext *)moc
{
    if(user.remoteIdentifier == nil) {
        user.remoteIdentifier = [NSUUID createUUID];
    }
    UserClient *userClient = [UserClient insertNewObjectInManagedObjectContext:moc];
    userClient.remoteIdentifier = [NSString createAlphanumericalString];
    userClient.user = user;
    
    if (createSessionWithSeflUser) {
        UserClient *selfClient = [ZMUser selfUserInContext:moc].selfClient;
        [self performPretendingUiMocIsSyncMoc:^{
            NSError *error;
            NSString *key = [selfClient.keysStore lastPreKeyAndReturnError:&error];
            NOT_USED([selfClient establishSessionWithClient:userClient usingPreKey:key]);
        }];
    }
    return userClient;
}

@end


@implementation  ZMBaseManagedObjectTest (SwiftBridgeConversation)

- (void)performChangesSyncConversation:(ZMConversation *)conversation
                            mergeBlock:(void(^)(void))mergeBlock
                           changeBlock:(void(^)(ZMConversation*))changeBlock
{
    BOOL isSyncContext = conversation.managedObjectContext.zm_isSyncContext;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConv = conversation;
        if (!isSyncContext) {
            NSManagedObjectID *objectID = conversation.objectID;
            syncConv = (id)[self.syncMOC objectWithID:objectID];
        }
        changeBlock(syncConv);
        [self.syncMOC saveOrRollback];
    }];
    if (!isSyncContext) {
        if (mergeBlock) {
            mergeBlock();
        } else {
            [self.uiMOC refreshObject:conversation mergeChanges:YES];
        }
    }
}
- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.internalEstimatedUnreadCount = [@(unreadCount) intValue];
    }];
}

- (void)simulateUnreadSelfMentionCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.internalEstimatedUnreadSelfMentionCount = [@(unreadCount) intValue];
    }];
}

- (void)simulateUnreadSelfReplyCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.internalEstimatedUnreadSelfReplyCount = [@(unreadCount) intValue];
    }];
}

- (void)simulateUnreadMissedCallInConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.lastUnreadMissedCallDate = [NSDate date];
    }];
}

- (void)simulateUnreadMissedKnockInConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
{
    [self performChangesSyncConversation:conversation mergeBlock:mergeBlock changeBlock:^(ZMConversation * syncConv) {
        syncConv.lastUnreadKnockDate = [NSDate date];
    }];
}

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadCount:unreadCount forConversation:conversation mergeBlock:nil];
}

- (void)simulateUnreadSelfMentionCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadSelfMentionCount:unreadCount forConversation:conversation mergeBlock:nil];
}

- (void)simulateUnreadSelfReplyCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadSelfReplyCount:unreadCount forConversation:conversation mergeBlock:nil];
}

- (void)simulateUnreadMissedCallInConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadMissedCallInConversation:conversation mergeBlock:nil];
}

- (void)simulateUnreadMissedKnockInConversation:(ZMConversation *)conversation;
{
    [self simulateUnreadMissedKnockInConversation:conversation mergeBlock:nil];
}

@end
