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


@import WireMockTransport;
@import WireRequestStrategy;

#import "MessagingTest.h"
#import <libkern/OSAtomic.h>
#import <CommonCrypto/CommonCrypto.h>

@import MobileCoreServices;
@import CoreData;
@import WireTransport;
@import WireTransport.Testing;
@import WireMockTransport;
@import WireDataModel;

#import "ZMTimingTests.h"
#import "MockModelObjectContextFactory.h"

#import "ZMSelfStrategy.h"
#import "ZMMissingUpdateEventsTranscoder.h"
#import "ZMLastUpdateEventIDTranscoder.h"
#import "ZMLoginTranscoder.h"
#import "ZMLoginCodeRequestTranscoder.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "Tests-Swift.h"

static ZMReachability *sharedReachabilityMock = nil;

@interface MockTransportSession (Reachability)
@property (nonatomic, readonly) ZMReachability *reachability;
@end

@implementation MockTransportSession (Reachability)

- (ZMReachability *)reachability
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedReachabilityMock = OCMClassMock(ZMReachability.class);
        [[[(id)sharedReachabilityMock stub] andReturnValue:[NSNumber numberWithBool:YES]] mayBeReachable];
    });
    return sharedReachabilityMock;
}

@end

@interface MessagingTest ()

@property (nonatomic) CoreDataStack *coreDataStack;

@property (nonatomic) NSString *groupIdentifier;
@property (nonatomic) NSUUID *userIdentifier;
@property (nonatomic) NSURL *sharedContainerURL;

@property (nonatomic) MockTransportSession *mockTransportSession;

@property (nonatomic) NSTimeInterval originalConversationLastReadTimestampTimerValue; // this will speed up the tests A LOT

@end

@implementation MessagingTest

- (BOOL)shouldSlowTestTimers
{
    return [self.class isDebuggingTests] && !self.ignoreTestDebugFlagForTestTimers;
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

- (BOOL)shouldUseRealKeychain;
{
    return NO;
}

- (BOOL)shouldUseInMemoryStore;
{
    return YES;
}

- (NSURL *)storeURL
{
    return self.accountDirectory.URLByAppendingPersistentStoreLocation;
}

- (NSURL *)accountDirectory
{
    return [CoreDataStack accountDataFolderWithAccountIdentifier:self.userIdentifier applicationContainer:self.sharedContainerURL];
}

- (NSURL *)keyStoreURL
{
    return self.sharedContainerURL;
}

- (void)setUp;
{
    [super setUp];
    BackgroundActivityFactory.sharedFactory.activityManager = UIApplication.sharedApplication;
    [BackgroundActivityFactory.sharedFactory resume];
    
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *bundleIdentifier = [NSBundle bundleForClass:self.class].bundleIdentifier;
    self.groupIdentifier = [@"group." stringByAppendingString:bundleIdentifier];
    self.userIdentifier = [NSUUID UUID];
    self.sharedContainerURL = [fm containerURLForSecurityApplicationGroupIdentifier:self.groupIdentifier];
    self.mockCallNotificationStyle = CallNotificationStylePushNotifications;
    
    NSURL *otrFolder = [NSFileManager keyStoreURLForAccountInDirectory:self.accountDirectory createParentIfNeeded:NO];
    [fm removeItemAtURL:otrFolder error: nil];
    
    _application = [[ApplicationMock alloc] init];
    
    self.originalConversationLastReadTimestampTimerValue = ZMConversationDefaultLastReadTimestampSaveDelay;
    ZMConversationDefaultLastReadTimestampSaveDelay = 0.02;
    
    NSString *testName = NSStringFromSelector(self.invocation.selector);
    NSString *methodName = [NSString stringWithFormat:@"setup%@%@", [testName substringToIndex:1].capitalizedString, [testName substringFromIndex:1]];
    SEL selector = NSSelectorFromString(methodName);
    if ([self respondsToSelector:selector]) {
        ZM_SILENCE_CALL_TO_UNKNOWN_SELECTOR([self performSelector:selector]);
    }

    self.coreDataStack = [self createCoreDataStack];

    [self setupKeyStore];
    [self setupCaches];


    if (self.shouldUseRealKeychain) {
        [ZMPersistentCookieStorage setDoNotPersistToKeychain:NO];
        
#if ! TARGET_IPHONE_SIMULATOR
        // On the Xcode Continuous Intergration server the tests run as a user whose username starts with an underscore.
        BOOL const runningOnIntegrationServer = [[[NSProcessInfo processInfo] environment][@"USER"] hasPrefix:@"_"];
        if (runningOnIntegrationServer) {
            [ZMPersistentCookieStorage setDoNotPersistToKeychain:YES];
        }
#endif
    } else {
        [ZMPersistentCookieStorage setDoNotPersistToKeychain:YES];
    }

    ZMPersistentCookieStorage *cookieStorage = [[ZMPersistentCookieStorage alloc] init];
    [cookieStorage deleteKeychainItems];

    self.mockTransportSession = [[MockTransportSession alloc] initWithDispatchGroup:self.dispatchGroup];
    Require([self waitForAllGroupsToBeEmptyWithTimeout:5]);
}

- (void)setupKeyStore
{
    [self performPretendingUiMocIsSyncMoc:^{
        NSURL *url = [CoreDataStack accountDataFolderWithAccountIdentifier:self.userIdentifier
                                                  applicationContainer:self.sharedContainerURL];
        [self.uiMOC setupUserKeyStoreInAccountDirectory:url
                                   applicationContainer:self.sharedContainerURL];
    }];
}

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

- (NSManagedObjectContext *)eventMOC
{
    return self.coreDataStack.eventContext;
}

- (void)tearDown;
{
    Require([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    
    BackgroundActivityFactory.sharedFactory.activityManager = nil;

    ZMConversationDefaultLastReadTimestampSaveDelay = self.originalConversationLastReadTimestampTimerValue;

    [self wipeCaches];

    self.coreDataStack = nil;

    // teardown all mmanagedObjectContexts

    [self.mockTransportSession.managedObjectContext performBlockAndWait:^{
        // Do nothing
    }];
    [self.mockTransportSession tearDown];
    self.mockTransportSession = nil;

    self.ignoreTestDebugFlagForTestTimers = NO;
    [MessagingTest deleteAllFilesInCache];
    [self removeFilesInSharedContainer];

    _application = nil;
    self.groupIdentifier = nil;
    self.sharedContainerURL = nil;
    
    [super tearDown];
    Require([self waitForAllGroupsToBeEmptyWithTimeout:5]);
}

- (void)removeFilesInSharedContainer
{
    for (NSURL *url in [NSFileManager.defaultManager contentsOfDirectoryAtURL:self.sharedContainerURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil]) {
        NSError *error = nil;
        [NSFileManager.defaultManager removeItemAtURL:url error:&error];
        if (error) {
            ZMLogError(@"Error cleaning up %@ in %@: %@", url, self.self.sharedContainerURL, error);
        }
    }
}

- (NSArray *)allManagedObjectContexts;
{
    NSMutableArray *result = [NSMutableArray array];
    if (self.uiMOC != nil) {
        [result addObject:self.uiMOC];
    }
    if (self.syncMOC != nil) {
        [result addObject:self.syncMOC];
    }
    if (self.searchMOC != nil) {
        [result addObject:self.searchMOC];
    }
    if (self.mockTransportSession.managedObjectContext != nil) {
        [result addObject:self.mockTransportSession.managedObjectContext];
    }

    return result;
}

- (NSArray *)allDispatchGroups;
{
    NSMutableArray *groups = [NSMutableArray array];
    [groups addObject:self.dispatchGroup];
    for (NSManagedObjectContext *moc in self.allManagedObjectContexts) {
        [groups addObject:moc.dispatchGroup];
    }
    return groups;
}

@end

@implementation MessagingTest (UserTesting)

- (void)setEmailAddress:(NSString *)emailAddress onUser:(ZMUser *)user;
{
    user.emailAddress = emailAddress;
}

- (void)setPhoneNumber:(NSString *)phoneNumber onUser:(ZMUser *)user;
{
    user.phoneNumber = phoneNumber;
}

@end

@implementation MessagingTest (FilesInCache)

+ (NSURL *)cacheFolder {
    return (NSURL *)[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
}

+ (void)deleteAllFilesInCache {
    NSFileManager *fm = [NSFileManager defaultManager];
    for(NSURL *url in [self filesInCache]) {
        [fm removeItemAtURL:url error:nil];
    }
}

+ (NSSet *)filesInCache {
    return [NSSet setWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self cacheFolder] includingPropertiesForKeys:@[NSURLNameKey] options:0 error:nil]];
}

@end

@implementation MessagingTest (OTR)

- (UserClient *)setupSelfClientInMoc:(NSManagedObjectContext *)moc;
{
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];
    if (selfUser.remoteIdentifier == nil) {
        selfUser.remoteIdentifier = [NSUUID createUUID];
    }
    
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:moc];
    client.remoteIdentifier = [NSString createAlphanumericalString];
    client.user = selfUser;
    
    [moc setPersistentStoreMetadata:client.remoteIdentifier forKey:ZMPersistedClientIdKey];
    [moc saveOrRollback];
    
    return client;
}

- (UserClient *)createSelfClient
{
    UserClient *selfClient = [self setupSelfClientInMoc:self.syncMOC];
    NSDictionary *payload = @{@"id": selfClient.remoteIdentifier, @"type": @"permanent", @"time": [[NSDate date] transportString]};
    NOT_USED([UserClient createOrUpdateSelfUserClient:payload context:self.syncMOC]);
    [self.syncMOC saveOrRollback];
    
    return selfClient;
}

@end

@implementation  MessagingTest (SwiftBridgeConversation)

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
{
    BOOL isSyncContext = conversation.managedObjectContext.zm_isSyncContext;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConv = conversation;
        if (!isSyncContext) {
            NSManagedObjectID *objectID = conversation.objectID;
            syncConv = (id)[self.syncMOC objectWithID:objectID];
        }
        syncConv.internalEstimatedUnreadCount = [@(unreadCount) intValue];
        [self.syncMOC saveOrRollback];
    }];
    if (!isSyncContext) {
        [self.uiMOC refreshObject:conversation mergeChanges:YES];
    }
}

- (void)simulateUnreadMissedCallInConversation:(ZMConversation *)conversation;
{
    BOOL isSyncContext = conversation.managedObjectContext.zm_isSyncContext;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConv = conversation;
        if (!isSyncContext) {
            NSManagedObjectID *objectID = conversation.objectID;
            syncConv = (id)[self.syncMOC objectWithID:objectID];
        }
        syncConv.lastUnreadMissedCallDate = [NSDate date];
        [self.syncMOC saveOrRollback];
    }];
    if (!isSyncContext) {
        [self.uiMOC refreshObject:conversation mergeChanges:YES];
    }
}


- (void)simulateUnreadMissedKnockInConversation:(ZMConversation *)conversation;
{
    BOOL isSyncContext = conversation.managedObjectContext.zm_isSyncContext;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConv = conversation;
        if (!isSyncContext) {
            NSManagedObjectID *objectID = conversation.objectID;
            syncConv = (id)[self.syncMOC objectWithID:objectID];
        }
        syncConv.lastUnreadKnockDate = [NSDate date];
        [self.syncMOC saveOrRollback];
    }];
    if (!isSyncContext) {
        [self.uiMOC refreshObject:conversation mergeChanges:YES];
    }
}

@end
