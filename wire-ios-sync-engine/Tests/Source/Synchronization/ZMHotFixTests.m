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
@import WireDataModel;

#import "MessagingTest.h"
#import "ZMHotFix.h"
#import "ZMHotFixDirectory.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>



@interface FakeHotFixDirectory : ZMHotFixDirectory
@property (nonatomic) NSUInteger method1CallCount;
@property (nonatomic) NSUInteger method2CallCount;
@property (nonatomic) NSUInteger method3CallCount;

@end

@implementation FakeHotFixDirectory

- (void)methodOne:(NSObject *)object
{
    NOT_USED(object);
    self.method1CallCount++;
}

- (void)methodTwo:(NSObject *)object
{
    NOT_USED(object);
    self.method2CallCount++;
}

- (void)methodThree:(NSObject *)object
{
    NOT_USED(object);
    self.method3CallCount++;
}

- (NSArray *)patches
{
    return @[
             [ZMHotFixPatch patchWithVersion:@"1.0" patchCode:^(NSManagedObjectContext *moc){ [self methodOne:moc]; [self methodThree:moc]; }],
             [ZMHotFixPatch patchWithVersion:@"0.1" patchCode:^(NSManagedObjectContext *moc){ [self methodTwo:moc]; }],
    ];
}

@end



@interface PushTokenNotificationObserver : NSObject
@property (nonatomic) NSUInteger notificationCount;
@end


@implementation PushTokenNotificationObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.notificationCount = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFired) name:ZMUserSession.registerCurrentPushTokenNotificationName object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)notificationFired
{
    self.notificationCount++;
}

@end



@interface ZMHotFixTests : MessagingTest

@property (nonatomic) FakeHotFixDirectory *fakeHotFixDirectory;
@property (nonatomic) ZMHotFix *sut;

@end


@implementation ZMHotFixTests

- (void)setUp {
    [super setUp];

    [self.syncMOC performGroupedBlockAndWait:^{
        [self createSelfClient];
        self.fakeHotFixDirectory = [[FakeHotFixDirectory alloc] init];
        self.sut = [[ZMHotFix alloc] initWithHotFixDirectory:self.fakeHotFixDirectory syncMOC:self.syncMOC];
    }];
}

- (void)tearDown {
    self.fakeHotFixDirectory = nil;
    self.sut = nil;
    [super tearDown];
}

- (void)saveNewVersion
{
    [self.syncMOC setPersistentStoreMetadata:@"0.1" forKey:@"lastSavedVersion"];
}

- (void)updateLastSavedVersion:(NSString *)lastSavedVersion
{
    [self.syncMOC setPersistentStoreMetadata:lastSavedVersion forKey:@"lastSavedVersion"];
}

- (void)testThatItOnlyCallsMethodsForVersionsNewerThanTheLastSavedVersion
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self saveNewVersion];

        // when
        [self.sut applyPatchesForCurrentVersion:@"1.0"];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertEqual(self.fakeHotFixDirectory.method1CallCount, 1u);
        XCTAssertEqual(self.fakeHotFixDirectory.method3CallCount, 1u);
        XCTAssertEqual(self.fakeHotFixDirectory.method2CallCount, 0u);
    }];
}

- (void)testThatItDoesntCallAnyMethodsIfThereIsNoLastSavedVersionButUpdateLastSavedVersion
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // when
        [self.sut applyPatchesForCurrentVersion:@"1.0"];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        NSString *newVersion = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion, @"1.0");
        XCTAssertEqual(self.fakeHotFixDirectory.method1CallCount, 0u);
        XCTAssertEqual(self.fakeHotFixDirectory.method2CallCount, 0u);
        XCTAssertEqual(self.fakeHotFixDirectory.method3CallCount, 0u);
    }];
}

- (void)testThatItRunsFixesOnlyOnce
{
    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        [self saveNewVersion];

        // when
        [self.sut applyPatchesForCurrentVersion:@"1.0"];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{

        // then
        XCTAssertEqual(self.fakeHotFixDirectory.method1CallCount, 1u);

        // and when
        [self.sut applyPatchesForCurrentVersion:@"1.0"];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertEqual(self.fakeHotFixDirectory.method1CallCount, 1u);
    }];
}

- (void)testThatItSetsTheCurrentVersionAfterApplyingTheFixes
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self saveNewVersion];

        // when
        [self.sut applyPatchesForCurrentVersion:@"1.2"];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        NSString *newVersion = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion, @"1.2");
    }];
}


#pragma mark - CurrentFixes

- (void)testThatItSendsOutResetPushTokenNotificationVersion_40_4
{
    PushTokenNotificationObserver *observer = [[PushTokenNotificationObserver alloc] init];

    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        [self updateLastSavedVersion:@"40.3"];

        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"40.4"];
        }];

    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        NSString *newVersion = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion, @"40.4");
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"40.4"];
        }];
    }];
    
    // then
    XCTAssertEqual(observer.notificationCount, 1lu);

    [self.syncMOC performGroupedBlockAndWait:^{
        // when
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"40.5"];
        }];
    }];
    
    // then
    XCTAssertEqual(observer.notificationCount, 1lu);
}

- (void)testThatItRemovesTheSharingExtensionURLs
{
    NSURL *directoryURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[NSUserDefaults groupName]];
    NSURL *imageURL = [directoryURL URLByAppendingPathComponent:@"profile_images"];
    NSURL *conversationUrl = [directoryURL URLByAppendingPathComponent:@"conversations"];

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self updateLastSavedVersion:@"40.22"];
        
        [[NSFileManager defaultManager] createDirectoryAtURL:imageURL withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] createDirectoryAtURL:conversationUrl withIntermediateDirectories:YES attributes:nil error:nil];

        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[imageURL relativePath]]);
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[conversationUrl relativePath]]);

        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"40.23"];
        }];

    }];
    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[imageURL relativePath]]);
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[conversationUrl relativePath]]);
    }];
}

- (void)testThatItCopiesTheAPSDecryptionKeysFromKeyChainToSelfClient_41_43
{
    __block UserClient *userClient = nil;
    NSData *encryptionKey = [NSData randomEncryptionKey];
    NSData *verificationKey = [NSData randomEncryptionKey];

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self updateLastSavedVersion:@"41.41"];
        userClient = [self createSelfClient];

        [ZMKeychain setData:verificationKey forAccount:@"APSVerificationKey"];
        [ZMKeychain setData:encryptionKey forAccount:@"APSDecryptionKey"];

        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"41.42"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        NSString *newVersion = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion, @"41.42");

        // then
        XCTAssertEqualObjects(userClient.apsVerificationKey, verificationKey);
        XCTAssertEqualObjects(userClient.apsDecryptionKey, encryptionKey);
        XCTAssertFalse(userClient.needsToUploadSignalingKeys);
        XCTAssertFalse([userClient hasLocalModificationsForKey:@"needsToUploadSignalingKeys"]);

        // and when
        // the keys change and afterwards we are updating again
        userClient.apsDecryptionKey = [NSData randomEncryptionKey];
        userClient.apsVerificationKey = [NSData randomEncryptionKey];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"41.43"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        NSString *newVersion2 = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion2, @"41.43");

        // then
        // we didn't overwrite the keys witht the old ones stored in the keychain
        XCTAssertNotEqualObjects(userClient.apsVerificationKey, verificationKey);
        XCTAssertNotEqualObjects(userClient.apsDecryptionKey, encryptionKey);

        [ZMKeychain deleteAllKeychainItemsWithAccountName:@"APSVerificationKey"];
        [ZMKeychain deleteAllKeychainItemsWithAccountName:@"APSDecryptionKey"];
    }];
}

- (void)testThatItSetsNeedsToUploadSignalingKeysIfKeysNotPresentInKeyChain_41_43
{
    __block UserClient *userClient = nil;

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self updateLastSavedVersion:@"41.41"];
        userClient = [self createSelfClient];
        XCTAssertFalse(userClient.needsToUploadSignalingKeys);
        XCTAssertFalse([userClient hasLocalModificationsForKey:@"needsToUploadSignalingKeys"]);

        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"41.42"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        NSString *newVersion = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion, @"41.42");

        // then
        XCTAssertTrue(userClient.needsToUploadSignalingKeys);
        XCTAssertTrue([userClient hasLocalModificationsForKey:@"needsToUploadSignalingKeys"]);

        // and when
        // we created and stored signaling keys and are updatign again
        userClient.apsVerificationKey = [NSData randomEncryptionKey];
        userClient.needsToUploadSignalingKeys = NO;
        [userClient resetLocallyModifiedKeys:[NSSet setWithObject:@"needsToUploadSignalingKeys"]];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"41.43"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        NSString *newVersion2 = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion2, @"41.43");

        // then
        // we are not reuploading the keys
        XCTAssertFalse(userClient.needsToUploadSignalingKeys);
        XCTAssertFalse([userClient hasLocalModificationsForKey:@"needsToUploadSignalingKeys"]);
    }];
}

- (void)testThatItSetsNotUploadedAssetClientMessagesToFailedAndAlsoExpiresFailedImageMessages_42_11
{
    __block ZMAssetClientMessage *uploadedImageMessage = nil;
    __block ZMAssetClientMessage *notUploadedImageMessage = nil;
    __block ZMAssetClientMessage *uploadedFileMessage = nil;
    __block ZMAssetClientMessage *notUploadedFileMessage = nil;

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self updateLastSavedVersion:@"41.10"];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeOneOnOne;
        conversation.remoteIdentifier = NSUUID.createUUID;

        uploadedImageMessage = (id)[conversation appendImageFromData:self.mediumJPEGData nonce:NSUUID.createUUID];
        [uploadedImageMessage markAsSent];
        [uploadedImageMessage updateTransferState:AssetTransferStateUploaded synchronize:NO];
        uploadedImageMessage.assetId = NSUUID.createUUID;
        XCTAssertTrue(uploadedImageMessage.delivered);
        XCTAssertTrue(uploadedImageMessage.hasDownloadedFile);

        notUploadedImageMessage = (id)[conversation appendImageFromData:self.mediumJPEGData nonce:NSUUID.createUUID];
        [notUploadedImageMessage updateTransferState:AssetTransferStateUploading synchronize:NO];
        XCTAssertFalse(notUploadedImageMessage.delivered);
        XCTAssertTrue(notUploadedImageMessage.hasDownloadedFile);

        uploadedFileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMVideoMetadata alloc] initWithFileURL:self.testVideoFileURL thumbnail:self.verySmallJPEGData]];
        [uploadedFileMessage markAsSent];
        [uploadedFileMessage updateTransferState:AssetTransferStateUploaded synchronize:NO];
        uploadedFileMessage.assetId = NSUUID.createUUID;
        XCTAssertTrue(uploadedFileMessage.delivered);
        XCTAssertTrue(uploadedFileMessage.hasDownloadedFile);

        notUploadedFileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMVideoMetadata alloc] initWithFileURL:self.testVideoFileURL thumbnail:self.verySmallJPEGData]];
        [notUploadedFileMessage markAsSent];
        [notUploadedFileMessage updateTransferState:AssetTransferStateUploading synchronize:NO];
        XCTAssertTrue(notUploadedFileMessage.delivered);
        XCTAssertTrue(notUploadedFileMessage.hasDownloadedFile);

        XCTAssertTrue([self.syncMOC saveOrRollback]);
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"42.11"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        NSString *newVersion = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion, @"42.11");

        // then
        XCTAssertTrue(uploadedImageMessage.delivered);
        XCTAssertTrue(uploadedImageMessage.hasDownloadedFile);
        XCTAssertEqual(uploadedImageMessage.transferState, AssetTransferStateUploaded);

        XCTAssertFalse(notUploadedImageMessage.delivered);
        XCTAssertTrue(notUploadedImageMessage.hasDownloadedFile);
        XCTAssertEqual(notUploadedImageMessage.transferState, AssetTransferStateUploadingFailed);

        XCTAssertTrue(uploadedFileMessage.delivered);
        XCTAssertTrue(uploadedFileMessage.hasDownloadedFile);
        XCTAssertEqual(uploadedFileMessage.transferState, AssetTransferStateUploaded);

        XCTAssertTrue(notUploadedFileMessage.delivered);
        XCTAssertTrue(notUploadedFileMessage.hasDownloadedFile);
        XCTAssertEqual(notUploadedFileMessage.transferState, AssetTransferStateUploadingFailed);
    }];
}

- (void)testThatItAddANewConversationSystemMessageForAllOneOnOneAndGroupConversation_HasHistory_44_4;
{
    __block ZMConversation *oneOnOneConversation = nil;
    __block ZMConversation *groupConversation = nil;
    __block ZMConversation *selfConversation = nil;
    __block ZMConversation *connectionConversation = nil;

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self.syncMOC setPersistentStoreMetadata:@YES forKey:@"HasHistory"];
        [self.syncMOC setPersistentStoreMetadata:@"1.0.0" forKey:@"lastSavedVersion"];

        oneOnOneConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        oneOnOneConversation.conversationType = ZMConversationTypeOneOnOne;

        groupConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        groupConversation.conversationType = ZMConversationTypeGroup;

        selfConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        selfConversation.conversationType = ZMConversationTypeSelf;

        connectionConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        connectionConversation.conversationType = ZMConversationTypeConnection;
        XCTAssertTrue([self.syncMOC saveOrRollback]);
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertEqual(oneOnOneConversation.allMessages.count, 0u);
        XCTAssertEqual(groupConversation.allMessages.count, 0u);
        XCTAssertEqual(selfConversation.allMessages.count, 0u);
        XCTAssertEqual(connectionConversation.allMessages.count, 0u);

        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"44.4"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{///TODO: crash for this class is not key value coding-compliant for the key localParticipants.'
        NSString *newVersion = [self.syncMOC persistentStoreMetadataForKey:@"lastSavedVersion"];
        XCTAssertEqualObjects(newVersion, @"44.4");

        // then
        XCTAssertEqual(oneOnOneConversation.allMessages.count, 0u);

        XCTAssertEqual(groupConversation.allMessages.count, 1u);
        ZMSystemMessage *message = (ZMSystemMessage *)groupConversation.lastMessage;
        XCTAssertEqual(message.systemMessageType, ZMSystemMessageTypeNewConversation);

        XCTAssertEqual(selfConversation.allMessages.count, 0u);

        XCTAssertEqual(connectionConversation.allMessages.count, 0u);
    }];
}

- (void)testThatItPurgesPinCachesInHostBundle_60_0_0
{
    // given
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *cachesDirectory = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSArray *PINCaches = @[@"com.pinterest.PINDiskCache.images", @"com.pinterest.PINDiskCache.largeUserImages", @"com.pinterest.PINDiskCache.smallUserImages"];
    // Create folder which shouldn't be deleted
    NSURL *directoryNotBeDeleted = [cachesDirectory URLByAppendingPathComponent:@"dontDeleteMe" isDirectory:YES];

    [self.syncMOC performGroupedBlockAndWait:^{
        [self updateLastSavedVersion:@"60.0.0"];
        // Create expected PINCache folders
        for (NSString *cache in PINCaches) {
            NSURL *cacheURL = [cachesDirectory URLByAppendingPathComponent:cache isDirectory:YES];
            XCTAssertTrue([fileManager createDirectoryAtURL:cacheURL withIntermediateDirectories:YES attributes:nil error:nil]);
        }

        XCTAssertTrue([fileManager createDirectoryAtURL:directoryNotBeDeleted withIntermediateDirectories:YES attributes:nil error:nil]);

        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"61.0.0"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC saveOrRollback];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        for (NSString *cache in PINCaches) {
            NSURL *cacheURL = [cachesDirectory URLByAppendingPathComponent:cache isDirectory:YES];
            XCTAssertFalse([fileManager fileExistsAtPath:cacheURL.path]);
        }

        XCTAssertTrue([fileManager fileExistsAtPath:directoryNotBeDeleted.path]);

        // clean up
        XCTAssertTrue([fileManager removeItemAtURL:directoryNotBeDeleted error:nil]);
    }];
}

- (NSURL *)testVideoFileURL
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    
    NSURL *url = [bundle URLForResource:@"video" withExtension:@"mp4"];
    if (nil == url) XCTFail("Unable to load video fixture from disk");
    return url;
}

- (void)testThatItMarksConnectedUsersToBeUpdatedFromTheBackend_62_3_1
{
    __block ZMUser *connectedUser = nil;
    __block ZMUser *selfUser = nil;
    __block ZMUser *unconnectedUser = nil;

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self updateLastSavedVersion:@"62.41"];
        connectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connectedUser.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connectedUser.connection.status = ZMConnectionStatusAccepted;
        connectedUser.needsToBeUpdatedFromBackend = NO;

        selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.needsToBeUpdatedFromBackend = NO;

        unconnectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        unconnectedUser.needsToBeUpdatedFromBackend = NO;

        [self.syncMOC saveOrRollback];

        XCTAssertTrue(connectedUser.isConnected);
        XCTAssertFalse(unconnectedUser.isConnected);
        XCTAssertFalse(connectedUser.needsToBeUpdatedFromBackend);
        XCTAssertFalse(unconnectedUser.needsToBeUpdatedFromBackend);
        XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend);
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"62.3.1"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC saveOrRollback];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertTrue(connectedUser.needsToBeUpdatedFromBackend);
        XCTAssertTrue(unconnectedUser.needsToBeUpdatedFromBackend);
        XCTAssertTrue(selfUser.needsToBeUpdatedFromBackend);
    }];
}

- (void)testThatItMarksConnectedUsersToBeUpdatedFromTheBackend_76_0_0
{
    // As some users might already have updated their profile pictures using the /assets/v3 endpoint
    // before the iOS client was able to download it (and the update event was alreday processed) we need
    // to redownload all users as soon as we support downloading profile pictures using the /v3/ endpoint.
    __block ZMUser *connectedUser = nil;
    __block ZMUser *selfUser = nil;
    __block ZMUser *unconnectedUser = nil;

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self updateLastSavedVersion:@"75.0.0"];
        connectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connectedUser.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connectedUser.connection.status = ZMConnectionStatusAccepted;
        connectedUser.needsToBeUpdatedFromBackend = NO;

        // We might already have uploaded a picture for the selfUser form a different client.
        selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.needsToBeUpdatedFromBackend = NO;

        unconnectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        unconnectedUser.needsToBeUpdatedFromBackend = NO;

        [self.syncMOC saveOrRollback];

        XCTAssertTrue(connectedUser.isConnected);
        XCTAssertFalse(unconnectedUser.isConnected);
        XCTAssertFalse(connectedUser.needsToBeUpdatedFromBackend);
        XCTAssertFalse(unconnectedUser.needsToBeUpdatedFromBackend);
        XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend);
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"76.0.0"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC saveOrRollback];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertTrue(connectedUser.needsToBeUpdatedFromBackend);
        XCTAssertTrue(unconnectedUser.needsToBeUpdatedFromBackend);
        XCTAssertTrue(selfUser.needsToBeUpdatedFromBackend);
    }];
}

- (void)testThatItMarksConnectedUsersToBeUpdatedFromTheBackend_157_0_0
{
    __block ZMUser *connectedUser = nil;
    __block ZMUser *selfUser = nil;
    __block ZMUser *unconnectedUser = nil;

    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [self.syncMOC setPersistentStoreMetadata:@"156.0.0" forKey:@"lastSavedVersion"];
        connectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connectedUser.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connectedUser.connection.status = ZMConnectionStatusAccepted;
        connectedUser.needsToBeUpdatedFromBackend = NO;

        selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.needsToBeUpdatedFromBackend = NO;

        unconnectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        unconnectedUser.needsToBeUpdatedFromBackend = NO;

        [self.syncMOC saveOrRollback];

        XCTAssertTrue(connectedUser.isConnected);
        XCTAssertFalse(unconnectedUser.isConnected);
        XCTAssertFalse(connectedUser.needsToBeUpdatedFromBackend);
        XCTAssertFalse(unconnectedUser.needsToBeUpdatedFromBackend);
        XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend);
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // when
        self.sut = [[ZMHotFix alloc] initWithSyncMOC:self.syncMOC];
        [self performIgnoringZMLogError:^{
            [self.sut applyPatchesForCurrentVersion:@"157.0.0"];
        }];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC saveOrRollback];
    }];

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertTrue(connectedUser.needsToBeUpdatedFromBackend);
        XCTAssertTrue(unconnectedUser.needsToBeUpdatedFromBackend);
    }];
}

@end
