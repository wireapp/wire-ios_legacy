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
@import CoreGraphics;
@import Foundation;
@import MobileCoreServices;
@import WireImages;

#import "ModelObjectsTests.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMMessageTests.h"
#import "MessagingTest+EventFactory.h"
#import "ZMUpdateEvent+WireDataModel.h"
#import "NSString+RandomString.h"
#import "WireDataModelTests-Swift.h"

NSString * const IsExpiredKey = @"isExpired";
NSString * const ReactionsKey = @"reactions";
NSUInteger const ZMClientMessageByteSizeExternalThreshold = 128000;

@implementation BaseZMMessageTests : ModelObjectsTests

- (void)setUp
{
    [super setUp];
    BackgroundActivityFactory.sharedFactory.activityManager = UIApplication.sharedApplication;
    [BackgroundActivityFactory.sharedFactory resume];
}

- (void)tearDown
{
    BackgroundActivityFactory.sharedFactory.activityManager = nil;
    [super tearDown];
}

@end

@implementation ZMMessageTests

- (void)testThatItIgnoresNanosecondSettingServerTimestampOnInsert
{
    // given
    ZMMessage *message = [[ZMMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    double millisecondsSince1970 = [message.serverTimestamp timeIntervalSince1970]*1000;
    
    // then
    XCTAssertEqual(millisecondsSince1970, floor(millisecondsSince1970));
}

- (void)testThatItHasLocallyModifiedDataFields
{
    XCTAssertTrue([ZMImageMessage isTrackingLocalModifications]);
    NSEntityDescription *entity = self.uiMOC.persistentStoreCoordinator.managedObjectModel.entitiesByName[ZMImageMessage.entityName];
    XCTAssertNotNil(entity.attributesByName[@"modifiedKeys"]);
}

- (void)testThatWeCanSetAttributesOnTextMessage
{
    Class aClass = [ZMTextMessage class];
    [self checkBaseMessageAttributeForClass:aClass];
    [self checkAttributeForClass:aClass key:@"text" value:@"Foo Bar"];
}

- (void)testThatWeCanSetAttributesOnKnockMessage
{
    Class aClass = [ZMKnockMessage class];
    [self checkBaseMessageAttributeForClass:aClass];
}

- (void)testThatItCanSetData;
{
    // given
    ZMImageMessage *sut = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // when
    sut.originalSize = CGSizeMake(123.45f,125);
    
    // then
    XCTAssertEqualWithAccuracy(sut.originalSize.width, 123.45, 0.001);
    XCTAssertEqualWithAccuracy(sut.originalSize.height, 125, 0.001);
}

- (void)testThatWeCanSetAttributesOnSystemMessage
{
    Class aClass = [ZMSystemMessage class];
    [self checkBaseMessageAttributeForClass:aClass];
    [self checkAttributeForClass:aClass key:@"systemMessageType" value:@(ZMSystemMessageTypeConversationNameChanged)];
    
    // generate a few users and save their objectIDs for later comparison
    NSMutableSet * userObjectIDs = [NSMutableSet set];
    NSMutableSet * users = [NSMutableSet set];
    
    for(int i = 0; i < 4; ++i)
    {
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        NSError *error;
        XCTAssertTrue([self.uiMOC save:&error], @"Save failed: %@", error);
        XCTAssertNotNil(user.objectID);
        XCTAssertFalse(user.objectID.isTemporaryID);
        
        [users addObject:user];
        [userObjectIDs addObject:user.objectID];
        
        
    }
    
    // load a message from the second context and check that the objectIDs for users are as expected
    ZMSystemMessage *message = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    XCTAssertNotNil(message);
    message.users = users;
    XCTAssertEqualObjects([message users], users);

    
    NSError *error;
    XCTAssertTrue([self.uiMOC save:&error], @"Save failed: %@", error);
    __block NSMutableSet *loadedUserIDs = nil;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        NSError *errorOnSync;

        ZMSystemMessage *message2 = (id) [self.syncMOC existingObjectWithID:message.objectID error:&errorOnSync];
        XCTAssertNotNil(message2, @"Failed to load into other context: %@", errorOnSync);
        NSSet *loadedUsers = message2.users;
        XCTAssertNotNil(loadedUsers);
        
        loadedUserIDs = [NSMutableSet set];
        for(ZMUser * u in loadedUsers) {
            [loadedUserIDs addObject:u.objectID];
        }
    }];
    
    XCTAssertEqualObjects(userObjectIDs, loadedUserIDs);
}


- (void)testThatTheServerTimeStampIsNilWhenTheServerTimestampIsNil;
{
    // given
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // when
    message.serverTimestamp = nil;
    
    // then
    XCTAssertNil(message.serverTimestamp);
}

- (void)testThatTheServerTimeStampIsUpdatedWhenTheServerTimestampIsUpdated;
{
    // given
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // when
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:12346789];
    NSDate *timestamp1 = message.serverTimestamp;
    message.serverTimestamp = [message.serverTimestamp dateByAddingTimeInterval:3000];
    NSDate *timestamp2 = message.serverTimestamp;
    
    // then
    XCTAssertEqualWithAccuracy([timestamp2 timeIntervalSinceDate:timestamp1], 3000, 0.01);
}

- (void)testThatTheServerTimeStampIsOffsetFromServerTimestampByTheLocalTimeZone
{
    // given
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // when
    NSDate *gmtTimestamp = [NSDate date];
    message.serverTimestamp = gmtTimestamp;
    
    // then
    XCTAssertEqualWithAccuracy([message.serverTimestamp timeIntervalSinceDate:message.serverTimestamp],
                               0,
                               0.01);
}

- (void)testThatItAlwaysReturnsZMDeliveryStateDeliveredForNonOTRMessages
{
    // given
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateDelivered);
}

- (void)testThatItResetsTheExpirationDateWhenResending
{
    // given
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    [message expire];
    
    NSDate *expectedDate = [NSDate dateWithTimeIntervalSinceNow:ZMTransportRequestDefaultExpirationInterval];
    
    // when
    [message resend];
    
    // then
    XCTAssertNotNil(message.expirationDate);
    XCTAssertEqualWithAccuracy([message.expirationDate timeIntervalSinceNow], [expectedDate timeIntervalSinceNow], 0.001);
}


- (void)testThatItResetsTheExpiredStateWhenResending
{
    // given
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    [message expire];
    
    // when
    [message resend];
    
    // then
    XCTAssertFalse(message.isExpired);
}

- (void)checkBaseMessageAttributeForClass:(Class)aClass;
{
    [self checkAttributeForClass:aClass key:@"nonce" value:[NSUUID createUUID]];
    [self checkAttributeForClass:aClass key:@"serverTimestamp" value:[NSDate dateWithTimeIntervalSince1970:1234567] ];
    [self checkSenderForClass:aClass];
}

- (void)checkSenderForClass:(Class)aClass;
{
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSError *error;
    XCTAssertTrue([self.uiMOC save:&error], @"Save failed: %@", error);
    XCTAssertNotNil(user.objectID);
    XCTAssertFalse(user.objectID.isTemporaryID);
    
    ZMMessage *message = [aClass insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssertNotNil(message);
    message.sender = user;
    XCTAssertEqual(message.sender, user);
    
    XCTAssertTrue([self.uiMOC save:&error], @"Save failed: %@", error);
    [self.syncMOC performGroupedBlockAndWait:^{
        NSError *errorOnSync;

        ZMMessage *message2 = (id) [self.syncMOC existingObjectWithID:message.objectID error:&errorOnSync];
        XCTAssertNotNil(message2, @"Failed to load into other context: %@", errorOnSync);
        ZMUser *user2 = message2.sender;
        XCTAssertNotNil(user2);
        XCTAssertEqualObjects(user2.objectID, user.objectID);
    }];
}

- (void)testThatItDoesNotUseTemporaryIDsForSender;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = user;
    
    // when
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    [self.uiMOC refreshObject:user mergeChanges:NO];
    [self.uiMOC refreshObject:message mergeChanges:NO];
    
    // then
    XCTAssertEqual(message.sender, user);
}

- (void)testThatExpiringAMessageSetsTheExpirationDateToNil
{
    // given
    ZMMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    [ZMMessage setDefaultExpirationTime:12345];
    [message setExpirationDate];
    XCTAssertFalse(message.isExpired);
    
    // when
    [message expire];

    // then
    XCTAssertTrue(message.isExpired);
    XCTAssertNil(message.expirationDate);
    
    // finally
    [ZMMessage resetDefaultExpirationTime];
}

- (void)testThatSpecialKeysAreNotPartOfTheLocallyModifiedKeysForTextMessages
{
    //given
    NSSet *expected = [NSSet setWithObject:IsExpiredKey];

    // when
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertEqualObjects(message.keysTrackedForLocalModifications, expected);
}

- (void)testThatSpecialKeysAreNotPartOfTheLocallyModifiedKeysForSystemMessages
{
    //given
    NSSet *expected = [NSSet setWithObject:IsExpiredKey];
    
    // when
    ZMSystemMessage *message = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertEqualObjects(message.keysTrackedForLocalModifications, expected);
}


- (void)testThatSpecialKeysAreNotPartOfTheLocallyModifiedKeysForImageMessages
{
    // given
    NSSet *expected = [NSSet setWithObject:IsExpiredKey];
    
    // when
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertEqualObjects(message.keysTrackedForLocalModifications, expected);
}

- (void)testThat_doesEventGenerateMessage_returnsTrueForAllKnownTypes
{
    NSArray *validTypes = @[
                            @(ZMUpdateEventTypeConversationMemberJoin),
                            @(ZMUpdateEventTypeConversationMemberLeave),
                            @(ZMUpdateEventTypeConversationRename),
                            @(ZMUpdateEventTypeConversationMessageAdd),
                            @(ZMUpdateEventTypeConversationClientMessageAdd),
                            @(ZMUpdateEventTypeConversationOtrMessageAdd),
                            @(ZMUpdateEventTypeConversationOtrAssetAdd),
                            @(ZMUpdateEventTypeConversationAssetAdd),
                            @(ZMUpdateEventTypeConversationKnock),
                            ];
    for(NSUInteger evt = 0; evt <= ZMUpdateEventTypeUserPropertiesDelete; ++evt) {
        XCTAssertEqual([ZMMessage doesEventTypeGenerateMessage:evt], [validTypes containsObject:@(evt)]);
    }
}

- (void)testThatTheTextIsCopied
{
    // given
    NSString *originalValue = @"will@foo.co";
    NSMutableString *mutableValue = [originalValue mutableCopy];
    ZMTextMessage *msg = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // when
    msg.text = mutableValue;
    [mutableValue appendString:@".uk"];
    
    // then
    XCTAssertEqualObjects(msg.text, originalValue);
}

- (void)testThatItFetchesTheLatestPotentialGapSystemMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSDate *olderDate = [NSDate dateWithTimeIntervalSinceNow:-1000];
    NSDate *newerDate = [NSDate date];
    [conversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:olderDate];
    [conversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:newerDate];
    
    // when
    ZMSystemMessage *fetchedMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:conversation];
    
    // then
    XCTAssertNotNil(fetchedMessage);
    XCTAssertTrue(fetchedMessage.needsUpdatingUsers);
    XCTAssertEqualObjects(newerDate, fetchedMessage.serverTimestamp);
}

- (void)testThatItOnlyFetchesSystemMesssagesInTheCorrectConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *otherConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSDate *olderDate = [NSDate dateWithTimeIntervalSinceNow:-1000];
    NSDate *newerDate = [NSDate date];
    
    [conversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:olderDate];
    [conversation appendMessageWithText:@"Awesome Text"];
    [otherConversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:newerDate];
    
    // when
    ZMSystemMessage *fetchedMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:conversation];
    
    // then
    XCTAssertNotNil(fetchedMessage);
    XCTAssertTrue(fetchedMessage.needsUpdatingUsers);
    XCTAssertEqualObjects(olderDate, fetchedMessage.serverTimestamp);
}

- (void)testThatItUpdatedNeedsUpdatingUsersOnPotentialGapSystemMessageCorrectlyIfUserNameIsNil
{
    // given
    ZMUser *firstUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *secondUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSSet <ZMUser *>*users = [NSSet setWithObjects:firstUser, secondUser, nil];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:NSDate.date];
    
    ZMSystemMessage *systemMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:conversation];
    XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageTypePotentialGap);
    XCTAssertTrue(systemMessage.needsUpdatingUsers);
    
    // when
    [conversation updatePotentialGapSystemMessagesIfNeededWithUsers:users];
    [systemMessage updateNeedsUpdatingUsersIfNeeded];
    
    // then
    XCTAssertTrue(systemMessage.needsUpdatingUsers);
    XCTAssertEqualObjects(systemMessage.addedUsers, users);
    
    // when
    firstUser.name = @"Annette";
    [systemMessage updateNeedsUpdatingUsersIfNeeded];
    
    // then
    XCTAssertTrue(systemMessage.needsUpdatingUsers);
    
    // when
    secondUser.name = @"Heiner";
    [systemMessage updateNeedsUpdatingUsersIfNeeded];
    
    // then
    XCTAssertFalse(systemMessage.needsUpdatingUsers);
}

#pragma mark - TextMessage

- (void)testThatATextMessageHasTextMessageData
{
    // given
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.text = @"Foo";
    // then
    XCTAssertEqualObjects(message.text, @"Foo");
    XCTAssertNil(message.systemMessageData);
    XCTAssertNil(message.imageMessageData);
    XCTAssertNil(message.knockMessageData);
}


#pragma mark - ImageMessages

- (void)testThatSettingTheOriginalDataRecognizesAGif
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.originalImageData = [self dataForResource:@"animated" extension:@"gif"];
    
    // then
    XCTAssertTrue(message.isAnimatedGIF);
}


- (void)testThatSettingTheOriginalDataRecognizesAStaticImageAsNotGif
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.originalImageData = [self dataForResource:@"tiny" extension:@"jpg"];
    
    // then
    XCTAssertFalse(message.isAnimatedGIF);
}

- (void)testThatAnEmptyImageMessageIsNotAnAnimatedGIF
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertFalse(message.isAnimatedGIF);
}

- (void)testThatAMediumJPEGIsNotAnAnimatedGIF
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.mediumData = [self dataForResource:@"tiny" extension:@"jpg"];
    XCTAssertNotNil(message.mediumData);
    
    // then
    XCTAssertFalse(message.isAnimatedGIF);
}

- (void)testThatAGIFWithOnlyOneFrameIsNotAnAnimatedGIF
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.mediumData = [self dataForResource:@"not_animated" extension:@"gif"];
    XCTAssertNotNil(message.mediumData);
    
    // then
    XCTAssertFalse(message.isAnimatedGIF);
}


- (void)testThatAGIFWithMoreThanOneFrameIsRecognizedAsAnimatedGIF
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.mediumData = [self dataForResource:@"animated" extension:@"gif"];
    XCTAssertNotNil(message.mediumData);
    
    // then
    XCTAssertTrue(message.isAnimatedGIF);
}

- (void)testThatAnEmptyImageMessageHasNoType
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertNil(message.imageType);
}

- (void)testThatAMediumJPEGIsHasJPGType
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.mediumData = [self dataForResource:@"tiny" extension:@"jpg"];
    XCTAssertNotNil(message.mediumData);
    
    // then
    NSString *expected = (__bridge NSString *) kUTTypeJPEG;
    XCTAssertEqualObjects(message.imageType, expected);
}

- (void)testThatAOneFrameMediumGIFHasGIFType
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.mediumData = [self dataForResource:@"not_animated" extension:@"gif"];
    XCTAssertNotNil(message.mediumData);
    
    // then
    NSString *expected = (__bridge NSString *) kUTTypeGIF;
    XCTAssertEqualObjects(message.imageType, expected);
}

- (void)testThatAnAnimatedMediumGIFHasGIFType
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.mediumData = [self dataForResource:@"animated" extension:@"gif"];
    XCTAssertNotNil(message.mediumData);
    
    // then
    NSString *expected = (__bridge NSString *) kUTTypeGIF;
    XCTAssertEqualObjects(message.imageType, expected);
}

- (void)testThatAnImageMessageHasImageMessageData
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertNil(message.textMessageData.messageText);
    XCTAssertNil(message.systemMessageData);
    XCTAssertNotNil(message.imageMessageData);
    XCTAssertNil(message.knockMessageData);
}

- (void)testThatImageDataCanBeFetchedAsynchrounously
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    NSData *imageData = [self dataForResource:@"tiny" extension:@"jpg"];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.previewData = imageData;
    message.mediumData = imageData;
    [self.uiMOC saveOrRollback];
    
    // expect
    XCTestExpectation *imageDataArrived = [self expectationWithDescription:@"image data arrived"];
    
    // when
    [message fetchImageDataWithQueue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0) completionHandler:^(NSData *imageDataResult) {
        XCTAssertEqualObjects(imageDataResult, imageData);
        [imageDataArrived fulfill];
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

#pragma mark - ImageIdentifiersForCaching

- (void)testThatItDoesNotReturnAnIdentifierWhenTheImageDataIsNil
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.originalImageData = nil;
    message.mediumData = nil;
    message.mediumRemoteIdentifier = nil;

    // when
    NSString *identifier = message.imageDataIdentifier;
    
    // then
    XCTAssertNil(identifier);
}

- (void)testThatItReturnsATemporaryIdentifierForTheOriginalImageData;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.originalImageData = self.verySmallJPEGData;
    
    // when
    NSString *identifierA = message.imageDataIdentifier;
    message.mediumRemoteIdentifier = NSUUID.createUUID;
    NSString *identifierB = message.imageDataIdentifier;
    
    // then
    XCTAssertNotNil(identifierA);
    XCTAssertNotNil(identifierB);
    XCTAssertNotEqualObjects(identifierA, identifierB);
}

- (void)testThatItReturnsAnIdentifierForTheImageData;
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.mediumRemoteIdentifier = NSUUID.createUUID;
    
    // when
    NSString *identifierA = message.imageDataIdentifier;
    message.mediumRemoteIdentifier = NSUUID.createUUID;
    NSString *identifierB = message.imageDataIdentifier;
    
    // then
    XCTAssertNotNil(identifierA);
    XCTAssertNotNil(identifierB);
    XCTAssertNotEqualObjects(identifierA, identifierB);
}

- (void)testThatItReturnsAnIdentifierForTheImagePreviewData;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.sender = self.selfUser;
    message.visibleInConversation = conversation;
    message.previewData = self.verySmallJPEGData;
    
    // when
    NSString *identifier = message.imagePreviewDataIdentifier;
    
    // then
    XCTAssertNotNil(identifier);
    XCTAssertGreaterThan(identifier.length, 0u);
}

- (void)testThatItDoesNotReturnAnIdentifierWhenTheImagePreviewDataIsNil
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.previewData = nil;
    
    // when
    NSString *identifier = message.imagePreviewDataIdentifier;
    
    // then
    XCTAssertNil(identifier);
}

#pragma mark - ImageMessageUploadAttributes

- (void)testThatItRequiresPreviewAndMediumData
{
    // given
    ZMImageMessage *message = [[ZMImageMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    NSOrderedSet *expectedFormats = [NSOrderedSet orderedSetWithObjects:@(ZMImageFormatPreview), @(ZMImageFormatMedium), nil];
    
    //then
    XCTAssertEqualObjects(message.requiredImageFormats,  expectedFormats);
}

#pragma mark - CreateSystemMessageFromUpdateEvent


- (void)testThat_isEventTypeGeneratingSystemMessage_returnsNo
{
    // valid types
    NSArray *validTypes = @[
        @(ZMUpdateEventTypeConversationMemberJoin),
        @(ZMUpdateEventTypeConversationMemberLeave),
        @(ZMUpdateEventTypeConversationRename)
    ];
    
    for(NSUInteger evt = 0; evt <= ZMUpdateEventTypeUserPropertiesDelete; ++evt) {
        XCTAssertEqual([ZMSystemMessage doesEventTypeGenerateSystemMessage:evt], [validTypes containsObject:@(evt)]);
    }
}

- (ZMSystemMessage *)createSystemMessageFromType:(ZMUpdateEventType)updateEventType inConversation:(ZMConversation *)conversation withUsersIDs:(NSArray *)userIDs senderID:(NSUUID *)senderID
{
    NSDictionary *data =@{
                          @"user_ids" : [userIDs mapWithBlock:^id(id obj) {
                              return [obj transportString];
                          }],
                          @"reason" : @"missed"
                          };
    ZMUpdateEvent *updateEvent = [self mockEventOfType:updateEventType forConversation:conversation sender:senderID data:data];
    ZMSystemMessage *systemMessage = [ZMSystemMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    return systemMessage;
}

- (ZMSystemMessage *)createConversationNameChangeSystemMessageInConversation:(ZMConversation *)conversation inManagedObjectContext:(NSManagedObjectContext *)moc
{
    NSDictionary *data = @{@"name" : conversation.displayName};
    ZMUpdateEvent *updateEvent = [self mockEventOfType:ZMUpdateEventTypeConversationRename forConversation:conversation sender:nil data:data];

    ZMSystemMessage *systemMessage = [ZMSystemMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:moc prefetchResult:nil];
    return systemMessage;
}

- (ZMSystemMessage *)createConversationConnectRequestSystemMessageInConversation:(ZMConversation *)conversation inManagedObjectContext:(NSManagedObjectContext *)moc
{
    NSDictionary *data = @{
                           @"message" : @"This is a very important message"
                           };
    ZMUpdateEvent *updateEvent = [self mockEventOfType:ZMUpdateEventTypeConversationConnectRequest forConversation:conversation sender:nil data:data];
    ZMSystemMessage *systemMessage = [ZMSystemMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:moc prefetchResult:nil];
    return systemMessage;
}

- (void)checkThatUpdateEventTypeDoesNotGenerateMessage:(ZMUpdateEventType)updateEventType {
    
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    // when
    ZMSystemMessage *message = [self createSystemMessageFromType:updateEventType inConversation:conversation withUsersIDs:@[] senderID:nil];
    
    // then
    XCTAssertNil(message);
}

- (void)testThatItDoesNotGenerateSystemMessagesFromUpdateEventsOfTheWrongType
{
    for(NSUInteger evt = 0; evt <= ZMUpdateEventTypeUserPropertiesDelete; ++evt)
    {
        if( ! [ZMSystemMessage doesEventTypeGenerateSystemMessage:evt] ) {
            [self checkThatUpdateEventTypeDoesNotGenerateMessage:evt];
        }
    }
}

- (void)testThatItStoresPermanentManagedObjectIdentifiersInTheUserField
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        
        ZMSystemMessage *message = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.syncMOC];
        message.users = [NSSet setWithObjects:user1, user2, nil];
        [self.syncMOC saveOrRollback];
    }];
    
    // when
    NSFetchRequest *request = [ZMSystemMessage sortedFetchRequest];
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];

    // then
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, 1u);
    ZMSystemMessage *message = result[0];
    XCTAssertNotNil(message);
    NSSet *users = message.users;
    
    XCTAssertEqual(users.count, 2u);
}

- (void)testThatItSavesTheConversationTitleInConversationNameChangeSystemMessage
{
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.userDefinedName = @"Conversation Name1";
        conversation.remoteIdentifier = [NSUUID createUUID];
        conversation.conversationType = ZMConversationTypeGroup;
        XCTAssertNotNil(conversation);
        XCTAssertEqualObjects(conversation.displayName, conversation.userDefinedName);
        
        // load a message from the second context and check that the objectIDs for users are as expected
        ZMSystemMessage *message = [self createConversationNameChangeSystemMessageInConversation:conversation inManagedObjectContext:self.syncMOC];
        XCTAssertNotNil(message);
        [self.syncMOC saveOrRollback];
    }];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.userDefinedName = @"Conversation Name2";
        conversation.remoteIdentifier = [NSUUID createUUID];
        conversation.conversationType = ZMConversationTypeGroup;

        XCTAssertNotNil(conversation);
        XCTAssertEqualObjects(conversation.displayName, conversation.userDefinedName);
        
        // load a message from the second context and check that the objectIDs for users are as expected
        ZMSystemMessage *message = [self createConversationNameChangeSystemMessageInConversation:conversation inManagedObjectContext:self.syncMOC];
        XCTAssertNotNil(message);
        [self.syncMOC saveOrRollback];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSFetchRequest *request = [ZMSystemMessage sortedFetchRequest];
    NSArray *messages = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 2u);

    XCTAssertNotNil(messages[0]);
    NSString *text1 = [(ZMTextMessage *)messages[0] text];
    XCTAssertNotNil(text1);
    XCTAssertEqualObjects(text1, @"Conversation Name1");

    XCTAssertNotNil(messages[1]);
    NSString *text2 = [(ZMTextMessage *)messages[1] text];
    XCTAssertNotNil(text2);
    XCTAssertEqualObjects(text2, @"Conversation Name2");
}

- (void)testThatItReturnsSenderIFItsTheOnlyUserContainedInUserIDs
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    conversation.conversationType = ZMConversationTypeGroup;
    XCTAssertNotNil(conversation);
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
    
    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];
    [self.uiMOC saveOrRollback];
    
    __block ZMSystemMessage *message;
    [self performPretendingUiMocIsSyncMoc:^{
        message = [self createSystemMessageFromType:ZMUpdateEventTypeConversationMemberJoin inConversation:conversation withUsersIDs:@[sender.remoteIdentifier] senderID:sender.remoteIdentifier];
    }];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSFetchRequest *request = [ZMSystemMessage sortedFetchRequest];
    NSArray *messages = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 1u);
    
    XCTAssertNotNil(messages.firstObject);
    XCTAssertEqualObjects(messages.firstObject, message);
    
    NSSet *userSet = message.users;
    XCTAssertNotNil(userSet);
    XCTAssertEqual(userSet.count, 1u);
    XCTAssertEqualObjects(userSet, [NSSet setWithObject:message.sender]);
}

- (void)testThatItReturnsOnlyOtherUsersIfTheSenderIsNotTheOnlyUserContainedInUserIDs
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    conversation.conversationType = ZMConversationTypeGroup;
    XCTAssertNotNil(conversation);
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
    
    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];
    [self.uiMOC saveOrRollback];
    
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser.remoteIdentifier = [NSUUID createUUID];
    [self.uiMOC saveOrRollback];
    
    __block ZMSystemMessage *message;
    [self performPretendingUiMocIsSyncMoc:^{
        message = [self createSystemMessageFromType:ZMUpdateEventTypeConversationMemberJoin inConversation:conversation withUsersIDs:@[sender.remoteIdentifier, otherUser.remoteIdentifier] senderID:sender.remoteIdentifier];
    }];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSFetchRequest *request = [ZMSystemMessage sortedFetchRequest];
    NSArray *messages = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 1u);
    
    XCTAssertNotNil(messages.firstObject);
    XCTAssertEqualObjects(messages.firstObject, message);
    
    NSSet *userSet = message.users;
    XCTAssertNotNil(userSet);
    XCTAssertEqual(userSet.count, 1u);
    XCTAssertEqualObjects(userSet, [NSSet setWithObject:otherUser]);
}

- (void)testThatItCreatesASystemMessageForAddingTheSelfUserToAGroupConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    conversation.conversationType = ZMConversationTypeGroup;
    XCTAssertNotNil(conversation);
    
    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID createUUID];
    [self.uiMOC saveOrRollback];

    // add selfUser to the conversation
    __block ZMSystemMessage *message;
    [self performPretendingUiMocIsSyncMoc:^{
        message = [self createSystemMessageFromType:ZMUpdateEventTypeConversationMemberJoin inConversation:conversation withUsersIDs:@[sender.remoteIdentifier, selfUser.remoteIdentifier] senderID:sender.remoteIdentifier];
    }];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSFetchRequest *request = [ZMSystemMessage sortedFetchRequest];
    NSArray *messages = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 1u);
    
    XCTAssertNotNil(messages.firstObject);
    XCTAssertEqualObjects(messages.firstObject, message);
    
    NSSet *userSet = message.users;
    XCTAssertNotNil(userSet);
    XCTAssertEqual(userSet.count, 1u);
    XCTAssertEqualObjects(userSet, [NSSet setWithObject:selfUser]);
}


- (void)testThatItDoesNotCreateASystemMessageForAddingTheSelfuserToAConnectionConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    conversation.conversationType = ZMConversationTypeConnection;
    XCTAssertNotNil(conversation);
    
    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID createUUID];
    [self.uiMOC saveOrRollback];
    
    // add selfUser to the conversation
    __block ZMSystemMessage *message;
    [self performPretendingUiMocIsSyncMoc:^{
        message = [self createSystemMessageFromType:ZMUpdateEventTypeConversationMemberJoin inConversation:conversation withUsersIDs:@[sender.remoteIdentifier, selfUser.remoteIdentifier] senderID:sender.remoteIdentifier];
    }];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSFetchRequest *request = [ZMSystemMessage sortedFetchRequest];
    NSArray *messages = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(messages.count, 0u);
}

- (void)testThatASystemMessageHasSystemMessageData
{
    // given
    ZMSystemMessage *message = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertNil(message.textMessageData.messageText);
    XCTAssertNotNil(message.systemMessageData);
    XCTAssertNil(message.imageMessageData);
    XCTAssertNil(message.knockMessageData);
}

- (void)testThatItReturnsTheOriginalImageDataWhenTheMediumDataIsNotAvailable;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    NSData *jpegData = [self.verySmallJPEGData wr_imageDataWithoutMetadataAndReturnError:nil];
    id<ZMConversationMessage> temporaryMessage = [conversation appendMessageWithImageData:jpegData];
    
    // when
    NSData *imageData = [temporaryMessage imageMessageData].imageData;
    
    // then
    XCTAssertNotNil(imageData);
    if (@available(iOS 14, *)) {
        // TODO:  [Bill] check why 1 btye is removed from jpegData?
        XCTAssertEqual(imageData.length, jpegData.length + 1);
    } else {
        XCTAssertEqual(imageData.length, jpegData.length);
    }
}

- (void)testThatFlagIsSetWhenSenderIsTheOnlyUser
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    conversation.conversationType = ZMConversationTypeGroup;
    XCTAssertNotNil(conversation);

    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];

    // add selfUser to the conversation
    __block ZMSystemMessage *message;
    [self performPretendingUiMocIsSyncMoc:^{
        message = [self createSystemMessageFromType:ZMUpdateEventTypeConversationMemberJoin inConversation:conversation withUsersIDs:@[sender.remoteIdentifier] senderID:sender.remoteIdentifier];
    }];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);


    // then
    XCTAssertTrue(message.userIsTheSender);
}

@end


@implementation ZMMessageTests (CreateImageMessageFromUpdateEvent)

- (NSMutableDictionary *)previewImageDataWithCorrelationID:(NSUUID *)correlationID
{
    NSMutableDictionary *imageData = [@{
                                        @"content_length" : @795,
                                        @"content_type" : @"image/jpeg",
                                        @"data" : @"/9j/4AAQSkZJRgABAQAAAQABAAD/4QBARXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAJqADAAQAAAABAAAAHQAAAAD/2wBDACAWGBwYFCAcGhwkIiAmMFA0MCwsMGJGSjpQdGZ6eHJmcG6AkLicgIiuim5woNqirr7EztDOfJri8uDI8LjKzsb/2wBDASIkJDAqMF40NF7GhHCExsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsb/wgARCAAdACYDASIAAhEBAxEB/8QAGAAAAwEBAAAAAAAAAAAAAAAAAAEDAgT/xAAXAQEBAQEAAAAAAAAAAAAAAAABAAID/9oADAMBAAIQAxAAAAG5Q3iGuStWGJZZXPfE7MqkxP/EAB0QAAICAwADAAAAAAAAAAAAAAABAhEDEBITICL/2gAIAQEAAQUC0nZRRWr4yLIn6Tg/JDEmJUujol9CdLtn/8QAFhEBAQEAAAAAAAAAAAAAAAAAEQAQ/9oACAEDAQE/ASMML//EABgRAAMBAQAAAAAAAAAAAAAAAAABEhEQ/9oACAECAQE/AdN5SKRZ/8QAGhAAAgIDAAAAAAAAAAAAAAAAECABAhEhUf/aAAgBAQAGPwIaWyzheH//xAAdEAACAgMAAwAAAAAAAAAAAAAAAREhMUFhECBx/9oACAEBAAE/IYIEO01rPoIQ3aV2PYdN+YHkbWIW5eikmT5HybsuD4sj4H//2gAMAwEAAgADAAAAEIvvgPQf/8QAFhEBAQEAAAAAAAAAAAAAAAAAABEB/9oACAEDAQE/EDWYpNi3/8QAGBEAAgMAAAAAAAAAAAAAAAAAABEBEFH/2gAIAQIBAT8QEbHYIf/EACAQAQADAAIBBQEAAAAAAAAAAAEAESExQVFhcYGRwdH/2gAIAQEAAT8Qhi6QtDxPVKQ8oyE6mE89wRrKOyVRTNjZi85kLW0/xlTPEKVS6youp29zp+4o4fuC4FDLXPufLGFBXqnOVDcEf//Z",
                                        @"id" : @"420936ed-e795-51e3-8829-9e07c4c0a23e",
                                        @"info" : [@{
                                                     @"correlation_id" : correlationID.transportString,
                                                     @"height" : @29,
                                                     @"nonce" : [NSUUID createUUID].transportString,
                                                     @"original_height" : @768,
                                                     @"original_width" : @1024,
                                                     @"public" : @NO,
                                                     @"tag" : @"preview",
                                                     @"width" : @38
                                                     } mutableCopy]
                                        } mutableCopy];
    return imageData;
}

- (NSMutableDictionary *)payloadForPreviewImageMessageInConversation:conversation correlationID:(NSUUID *)correlationID time:(NSDate *)time
{
    return [self payloadForMessageInConversation:conversation
                                            type:EventConversationAddAsset
                                            data:[self previewImageDataWithCorrelationID:correlationID]
                                            time:time];
}

- (NSMutableDictionary *)payloadForPreviewImageMessageInConversation:conversation correlationID:(NSUUID *)correlationID
{
    return [self payloadForPreviewImageMessageInConversation:conversation correlationID:correlationID time:nil];
}

- (NSMutableDictionary *)mediumImageDataWithCorrelationId:(NSUUID *)correlationID
{
    NSMutableDictionary *imageData = [@{
                                        @"content_length" : @795,
                                        @"content_type" : @"image/jpeg",
                                        @"id" : @"420936ed-e795-51e3-8829-9e07c4c0a23e",
                                        @"info" : [@{
                                                     @"correlation_id" : correlationID.transportString,
                                                     @"height" : @29,
                                                     @"nonce" : @"49faac5e-7bd4-a209-eaa1-f386b6df96aa",
                                                     @"original_height" : @768,
                                                     @"original_width" : @1024,
                                                     @"public" : @NO,
                                                     @"tag" : @"medium",
                                                     @"width" : @38
                                                     } mutableCopy]
                                        } mutableCopy];
    return imageData;
}

- (NSMutableDictionary *)payloadForMediumImageMessageInConversation:conversation correlationID:(NSUUID *)correlationID time:(NSDate *)time
{
    return [self payloadForMessageInConversation:conversation
                                            type:EventConversationAddAsset
                                            data:[self mediumImageDataWithCorrelationId:correlationID]
                                            time:time];
}

- (NSMutableDictionary *)payloadForMediumImageMessageInConversation:conversation correlationID:(NSUUID *)correlationID
{
    return [self payloadForMediumImageMessageInConversation:conversation correlationID:correlationID time:nil];
}

- (void)testThatItDoesNotCreatesPreviewImageMessagesFromUpdateEvent
{
    
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSUUID *correlationID = [NSUUID createUUID];
    NSDictionary *payload = [self payloadForPreviewImageMessageInConversation:conversation correlationID:correlationID];
    
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event);
    
    // when
    __block ZMImageMessage *sut;
    [self performPretendingUiMocIsSyncMoc:^{
        sut = [ZMImageMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
        
    // then
    XCTAssertNil(sut);
}





- (void)testThatItSortsPendingAndNonPendingMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *pendingMessage1 = (id)[conversation appendMessageWithText:@"P1"];
    pendingMessage1.visibleInConversation = conversation;
    
    ZMTextMessage *lastServerMessage = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    lastServerMessage.text = @"A3";
    lastServerMessage.visibleInConversation = conversation;
    lastServerMessage.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:10*1000];
    
    ZMTextMessage *firstServerMessage = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    firstServerMessage.text = @"A1";
    firstServerMessage.visibleInConversation = conversation;
    firstServerMessage.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:1*1000];
    
    ZMTextMessage *middleServerMessage = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    middleServerMessage.text = @"A2";
    middleServerMessage.visibleInConversation = conversation;
    middleServerMessage.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:5*1000];
    
    ZMMessage *pendingMessage2 = (id)[conversation appendMessageWithText:@"P2"];
    pendingMessage2.visibleInConversation = conversation;

    ZMMessage *pendingMessage3 = (id)[conversation appendMessageWithText:@"P3"];
    pendingMessage2.visibleInConversation = conversation;
    
    NSArray *expectedOrder = @[firstServerMessage, middleServerMessage, lastServerMessage, pendingMessage1, pendingMessage2, pendingMessage3];
    
    NSArray *allMessages = @[pendingMessage1, lastServerMessage, firstServerMessage, middleServerMessage, pendingMessage2, pendingMessage3];
    
    // when
    NSArray *sorted = [allMessages sortedArrayUsingDescriptors:[ZMMessage defaultSortDescriptors]];
    
    // then
    XCTAssertEqualObjects(expectedOrder, sorted);
}

- (void)testThatTheServerTimestampIsSetByDefault
{
    // given
    ZMTextMessage *msg = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertNotNil(msg.serverTimestamp);
    AssertDateIsRecent(msg.serverTimestamp);
}

@end



@implementation ZMMessageTests (KnockMessage)

- (void)testThatItDoesNotCreatesAKnockMessageFromAnUpdateEvent
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSUUID *nonce = [NSUUID createUUID];
    NSDictionary *data = @{@"nonce" : nonce.transportString};
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:EventConversationKnock data:data time:[NSDate dateWithTimeIntervalSinceReferenceDate:450000000]];
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    
    // when
    __block ZMKnockMessage *message;
    [self performPretendingUiMocIsSyncMoc:^{
        message = [ZMKnockMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];
    
    // then
    XCTAssertNil(message);
}

- (void)testThatAKnockMessageHasKnockMessageData
{
    // given
    ZMKnockMessage *message = [[ZMKnockMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // then
    XCTAssertNil(message.textMessageData.messageText);
    XCTAssertNil(message.systemMessageData);
    XCTAssertNil(message.imageMessageData);
    XCTAssertNotNil(message.knockMessageData);
}

@end

@implementation ZMMessageTests (Deletion)

- (void)testThatRepliesAreRemoved
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMClientMessage *message1 = (ZMClientMessage *)[conversation appendMessageWithText:@"Test"];
    ZMClientMessage *message2 = (ZMClientMessage *)[conversation appendText:@"Test 2" mentions:@[] replyingToMessage:message1 fetchLinkPreview:NO nonce:NSUUID.createUUID];
    XCTAssertEqualObjects(message2.quote, message1);
    XCTAssertFalse(message1.replies.isEmpty);
    
    // when
    [message1 removeMessageClearingSender:YES];
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertTrue(message1.replies.isEmpty);
    XCTAssertNil(message2.quote);
}

- (void)testThatQuotesAreRemoved
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    ZMClientMessage *message1 = (ZMClientMessage *)[conversation appendMessageWithText:@"Test"];
    ZMClientMessage *message2 = (ZMClientMessage *)[conversation appendText:@"Test 2" mentions:@[] replyingToMessage:message1 fetchLinkPreview:NO nonce:NSUUID.createUUID];
    XCTAssertEqualObjects(message2.quote, message1);
    XCTAssertFalse(message1.replies.isEmpty);
    
    // when
    [message2 removeMessageClearingSender:YES];
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertTrue(message1.replies.isEmpty);
    XCTAssertNil(message2.quote);
}


@end

@implementation ZMMessageTests (Reaction)

- (void)testThatAUnSentMessageCanNotBeLiked;
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];

    ZMMessage *message = (id)[conversation appendMessageWithText:self.name];
    [self.uiMOC saveOrRollback];
    XCTAssertEqual(message.deliveryState, ZMDeliveryStatePending);

    // when
    // this is the UI facing call to add reaction
    [ZMMessage addReaction:MessageReactionLike toMessage:message];
    [self.uiMOC saveOrRollback];

    //then
    XCTAssertEqual(conversation.hiddenMessages.count, 0lu);
    XCTAssertTrue(message.reactions.isEmpty);
}

- (void)testThatAddingAReactionWithUnicodeProperlyAddReactionForUserOnMessage;
{
    //given
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMTextMessage *textMessage = [[ZMTextMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    textMessage.visibleInConversation = conversation;
    [self.uiMOC saveOrRollback];
    
    //when
    NSString *reactionUnicode = @"❤️";
    // this is the UI facing call to add reaction
    [textMessage addReaction:reactionUnicode forUser:selfUser];
    [self.uiMOC saveOrRollback];
    
    
    textMessage = (ZMTextMessage *)[ZMMessage fetchMessageWithNonce:nonce forConversation:conversation inManagedObjectContext:self.uiMOC];
    
    //then
    NSDictionary *reactions = textMessage.usersReaction;
    XCTAssertEqual(reactions.count, 1lu);
    NSArray<ZMUser *> *usersThatReacted = reactions[reactionUnicode];
    XCTAssertEqual(usersThatReacted.count, 1lu);
    XCTAssertEqualObjects([usersThatReacted lastObject], selfUser);
}

- (void)testThatAddingAReactionWithoutUnicodeRemoveUserOnReaction;
{
    //given
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMTextMessage *textMessage = [[ZMTextMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    textMessage.visibleInConversation = conversation;
    [self.uiMOC saveOrRollback];
    
    NSString *reactionUnicode = @"❤️";
    // this is the UI facing call to add reaction
    [textMessage addReaction:reactionUnicode forUser:selfUser];
    [self.uiMOC saveOrRollback];

    //sanity check
    
    textMessage = (ZMTextMessage *)[ZMMessage fetchMessageWithNonce:nonce forConversation:conversation inManagedObjectContext:self.uiMOC];
    
    NSDictionary *reactions = textMessage.usersReaction;
    XCTAssertEqual(reactions.count, 1lu);
    NSArray<ZMUser *> *usersThatReacted = reactions[reactionUnicode];
    XCTAssertEqual(usersThatReacted.count, 1lu);
    XCTAssertEqualObjects([usersThatReacted lastObject], selfUser);

    //when
    [textMessage addReaction:@"" forUser:selfUser];
    [self.uiMOC saveOrRollback];
    
    //then
    reactions = textMessage.usersReaction;
    XCTAssertEqual(reactions.count, 0lu);
    usersThatReacted = reactions[reactionUnicode];
    XCTAssertEqual(usersThatReacted.count, 0lu);

}

- (void)testThatAddingAReactionForTwoUserWithSameUnicodeAgregates;
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    NSUUID *nonce = [NSUUID createUUID];
    ZMTextMessage *textMessage = [[ZMTextMessage alloc] initWithNonce:nonce managedObjectContext:self.uiMOC];
    textMessage.visibleInConversation = conversation;
    [self.uiMOC saveOrRollback];
    
    //when
    NSString *reactionUnicode = @"❤️";
    [textMessage addReaction:reactionUnicode forUser:selfUser];
    [textMessage addReaction:reactionUnicode forUser:user1];
    [self.uiMOC saveOrRollback];
    
    
    textMessage = (ZMTextMessage *)[ZMMessage fetchMessageWithNonce:nonce forConversation:conversation inManagedObjectContext:self.uiMOC];
    
    //then
    NSDictionary *reactions = textMessage.usersReaction;
    XCTAssertEqual(reactions.count, 1lu);
    NSArray<ZMUser *> *usersThatReacted = reactions[reactionUnicode];
    XCTAssertEqual(usersThatReacted.count, 2lu);
}

- (void)testThatReactionKeyIsIgnored
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:self.name];
    
    // then
    XCTAssertTrue([message.ignoredKeys containsObject:@"reactions"]);
}

- (void)testThatItKnowsThatItCannotUnreadTheMessage_selfMessage {
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:self.name];
    
    // then
    XCTAssertFalse([message canBeMarkedUnread]);
}

@end


@implementation BaseZMMessageTests (Ephemeral)

- (NSString *)textMessageRequiringExternalMessageWithNumberOfClients:(NSUInteger)count
{
    NSMutableString *text = @"Long Text".mutableCopy;
    while ([text dataUsingEncoding:NSUTF8StringEncoding].length < ZMClientMessageByteSizeExternalThreshold / count) {
        [text appendString:text];
    }
    return text;
}

- (ZMUpdateEvent *)encryptedExternalMessageFixtureWithBlobFromClient:(UserClient *)fromClient
{
    NSError *error;
    NSURL *encryptedMessageURL = [self fileURLForResource:@"EncryptedBase64EncondedExternalMessageTestFixture" extension:@"txt"];
    NSString *encryptedMessageFixtureString = [[NSString alloc] initWithContentsOfURL:encryptedMessageURL encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    
    NSDictionary *payload = @{
                              @"conversation": NSUUID.createUUID.transportString,
                              @"data": @"CiQzMzRmN2Y3Yi1hNDk5LTQ1MTMtOTJhOC1hZTg4MDI0OTQ0ZTlCRAog4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7wSIJCkkpWzMVxHXfu33pMQfEK+u/5qY426AbK9sC3Fu8Mx",
                              @"external": encryptedMessageFixtureString,
                              @"from": fromClient.remoteIdentifier,
                              @"time": NSDate.date.transportString,
                              @"type": @"conversation.otr-message-add"
                              };
    
    return [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:NSUUID.createUUID];
}

- (NSString *)expectedExternalMessageText
{
    NSError *error;
    NSURL *messageFixtureURL = [self fileURLForResource:@"ExternalMessageTextFixture" extension:@"txt"];
    NSString *messageFixtureString = [[NSString alloc] initWithContentsOfURL:messageFixtureURL encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    
    return messageFixtureString;
}

@end

