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


@import WireTesting;
@import WireDataModel;

#import "NSManagedObjectContext+TestHelpers.h"
#import "ZMUser.h"


@class NSManagedObjectContext;
@class ZMManagedObject;
@class ZMUser;
@class ZMConversation;
@class ZMConnection;
@protocol ZMObjectStrategyDirectory;
@class ZMAssetClientMessage;

@import WireCryptobox;
@import WireImages;
@class UserClient;

@class ZMClientMessage;

/// This is a base test class with utility stuff for all tests.
@interface ZMBaseManagedObjectTest : ZMTBaseTest

@property (nonatomic, readonly, nonnull) NSUUID* userIdentifier;

@property (nonatomic, readonly, nonnull) CoreDataStack *coreDataStack;
@property (nonatomic, readonly, nonnull) NSManagedObjectContext *uiMOC;
@property (nonatomic, readonly, nonnull) NSManagedObjectContext *syncMOC;
@property (nonatomic, readonly, nonnull) NSManagedObjectContext *searchMOC;

@property (nonatomic, readonly) BOOL shouldUseRealKeychain;
@property (nonatomic, readonly) BOOL shouldUseInMemoryStore;

/// reset ui and sync contexts
- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistantStore;

/// perform operations pretending that the uiMOC is a syncMOC
- (void)performPretendingUiMocIsSyncMoc:(nonnull void(^)(void))block;

/// perform operations pretending that the syncMOC is a uiMOC
- (void)performPretendingSyncMocIsUiMoc:(nonnull void(^)(void))block;

@end



@interface ZMBaseManagedObjectTest (UserTesting)

- (void)setEmailAddress:(nullable NSString *)emailAddress onUser:(nonnull ZMUser *)user;
- (void)setPhoneNumber:(nullable NSString *)phoneNumber onUser:(nonnull ZMUser *)user;

@end



@interface ZMBaseManagedObjectTest (FilesInCache)

/// Wipes the asset caches on the managed object contexts
- (void)wipeCaches;

/// Setups the asset caches on the managed object contexts
- (void)setupCaches;

@end


@interface ZMBaseManagedObjectTest (OTR)

- (nonnull UserClient *)createSelfClient;
- (nonnull UserClient *)createSelfClientOnMOC:(nonnull NSManagedObjectContext *)moc;

- (nonnull UserClient *)createClientForUser:(nonnull ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser;
- (nonnull UserClient *)createClientForUser:(nonnull ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser onMOC:(nonnull NSManagedObjectContext *)moc;

@end


@interface ZMBaseManagedObjectTest (SwiftBridgeConversation)

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation;
- (void)simulateUnreadSelfMentionCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation;
- (void)simulateUnreadSelfReplyCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation;
- (void)simulateUnreadMissedCallInConversation:(nonnull ZMConversation *)conversation;
- (void)simulateUnreadMissedKnockInConversation:(nonnull ZMConversation *)conversation;

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
- (void)simulateUnreadSelfMentionCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
- (void)simulateUnreadSelfReplyCount:(NSUInteger)unreadCount forConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
- (void)simulateUnreadMissedCallInConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;
- (void)simulateUnreadMissedKnockInConversation:(nonnull ZMConversation *)conversation mergeBlock:(void(^_Nullable)(void))mergeBlock;

@end

