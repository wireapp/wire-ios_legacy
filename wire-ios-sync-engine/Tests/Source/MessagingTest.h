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
@import WireSyncEngine;
@import WireDataModel;

#import "NSManagedObjectContext+TestHelpers.h"


@class NSManagedObjectContext;
@class MockTransportSession;
@class ZMManagedObject;
@class ZMUser;
@class ZMConversation;
@class ZMConnection;
@class ApplicationMock;
@class ZMAssetClientMessage;

@import WireCryptobox;
@import WireImages;
@class UserClient;

@class MockUser;
@class ZMClientMessage;

NS_ASSUME_NONNULL_BEGIN

/// This is a base test class with utility stuff for all tests.
@interface MessagingTest : ZMTBaseTest

@property (nonatomic, readonly) NSManagedObjectContext *uiMOC;
@property (nonatomic, readonly) NSManagedObjectContext *syncMOC;
@property (nonatomic, readonly) NSManagedObjectContext *searchMOC;
@property (nonatomic, readonly) NSManagedObjectContext *eventMOC;
@property (nonatomic, readonly) CoreDataStack *coreDataStack;
@property (nonatomic, readonly) ApplicationMock<ZMApplication> *application;
@property (nonatomic, readonly) MockTransportSession *mockTransportSession;

@property (nonatomic, readonly) NSString *groupIdentifier;
@property (nonatomic, readonly) NSUUID *userIdentifier;
@property (nonatomic, readonly) NSURL *sharedContainerURL;
@property (nonatomic, readonly) NSURL *accountDirectory;
@property (nonatomic, readonly) NSMutableArray<ZMUpdateEvent *> *processedUpdateEvents;
@property (nonatomic, readonly) BOOL shouldUseInMemoryStore;

@property (nonatomic) CallNotificationStyle mockCallNotificationStyle;

/// perform operations pretending that the uiMOC is a syncMOC
- (void)performPretendingUiMocIsSyncMoc:(void(^)(void))block;

/// Deletes all the files in the shared container
- (void)removeFilesInSharedContainer;

@end

@interface MessagingTest (UserTesting)

- (void)setEmailAddress:(NSString *)emailAddress onUser:(ZMUser *)user;
- (void)setPhoneNumber:(NSString *)phoneNumber onUser:(ZMUser *)user;

@end

@interface MessagingTest (FilesInCache)

+ (NSURL *)cacheFolder;
+ (void)deleteAllFilesInCache;
+ (NSSet *)filesInCache;

@end

@interface MessagingTest (OTR)

- (UserClient *)setupSelfClientInMoc:(NSManagedObjectContext *)moc;
- (UserClient *)createSelfClient;

@end

@interface MessagingTest (SwiftBridgeConversation)

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
- (void)simulateUnreadMissedCallInConversation:(ZMConversation *)conversation;
- (void)simulateUnreadMissedKnockInConversation:(ZMConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
