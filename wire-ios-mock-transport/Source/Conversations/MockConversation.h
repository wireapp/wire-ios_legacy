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
@import CoreData;
@import WireTransport;

@class MockTeam;
@class MockUser;
@class MockEvent;
@class MockUserClient;
@class MockRole;
@class MockParticipantRole;

typedef NS_ENUM(int16_t, ZMTConversationType) {
    ZMTConversationTypeGroup = 0,
    ZMTConversationTypeSelf = 1,
    ZMTConversationTypeOneOnOne = 2,
    ZMTConversationTypeConnection = 3,
    ZMTConversationTypeInvalid = 100
};

@interface MockConversation : NSManagedObject

@property (nonatomic, nullable) NSString *otrArchivedRef;
@property (nonatomic, nullable) NSString *otrMutedRef;
@property (nonatomic, nullable) NSNumber *otrMutedStatus;
@property (nonatomic) BOOL otrArchived;
@property (nonatomic) BOOL otrMuted;
@property (nonatomic, nonnull) NSString *selfRole;

@property (nonatomic, nullable) MockUser *creator;
@property (nonatomic, nonnull) NSArray<NSString *> *accessMode;
@property (nonatomic, nullable) NSNumber *receiptMode;
@property (nonatomic, nonnull) NSString *accessRole;
@property (nonatomic, nonnull) NSArray<NSString *> *accessRoleV2;
@property (nonatomic, nullable) NSString *link;
@property (nonatomic, nullable) NSString *guestLinkFeatureStatus;
@property (nonatomic, nonnull) NSString *identifier;
@property (nonatomic, nonnull) NSString *selfIdentifier; // Identifier of self user, used to filter out self from participants in the payload
@property (nonatomic, readonly, nullable) NSString *name;
@property (nonatomic) ZMTConversationType type;
/**
  participants that are not self
  mocks ZMConversation.activeParticipants
 */
@property (nonatomic, readonly, nonnull) NSOrderedSet *activeUsers;

@property (nonatomic, readonly, nonnull) NSOrderedSet *events;

@property (nonatomic, nullable) NSSet<MockRole *> *nonTeamRoles;
@property (nonatomic, nullable) NSSet<MockParticipantRole *> *participantRoles;

@property (nonatomic, nullable) MockTeam *team;

- (nonnull id<ZMTransportData>)transportData;

+ (nonnull NSFetchRequest *)sortedFetchRequest;
+ (nonnull NSFetchRequest *)sortedFetchRequestWithPredicate:(nonnull NSPredicate *)predicate;

+ (nonnull instancetype)insertConversationIntoContext:(nonnull NSManagedObjectContext *)moc withSelfUser:(nonnull MockUser *)selfUser creator:(nonnull MockUser *)creator otherUsers:(nullable NSArray *)otherUsers type:(ZMTConversationType)type;
+ (nonnull instancetype)insertConversationIntoContext:(nonnull NSManagedObjectContext *)moc creator:(nonnull MockUser *)creator otherUsers:(nullable NSArray *)otherUsers type:(ZMTConversationType)type;

+ (nonnull instancetype)conversationInMoc:(nonnull NSManagedObjectContext *)moc withCreator:(nonnull MockUser *)creator otherUsers:(nullable NSArray *)otherUsers type:(ZMTConversationType)type;

- (nonnull MockEvent *)insertClientMessageFromUser:(nonnull MockUser *)fromUser data:(nonnull NSData *)data;

/// Encrypts and inserts a OTR message using the gerneric message data sent from the given client to the given client
- (nonnull MockEvent *)encryptAndInsertDataFromClient:(nonnull MockUserClient *)fromClient
                                             toClient:(nonnull MockUserClient *)toClient
                                                 data:(nonnull NSData *)data;

- (nonnull MockEvent *)insertOTRMessageFromClient:(nonnull MockUserClient *)fromClient
                                         toClient:(nonnull MockUserClient *)toClient
                                             data:(nonnull NSData *)data;

- (nonnull MockEvent *)insertOTRAssetFromClient:(nonnull MockUserClient *)fromClient
                                       toClient:(nonnull MockUserClient *)toClient
                                       metaData:(nonnull NSData *)metaData
                                      imageData:(nullable NSData *)imageData
                                        assetId:(nonnull NSUUID *)assetId
                                       isInline:(BOOL)isInline;

- (nonnull MockEvent *)insertKnockFromUser:(nonnull MockUser *)fromUser nonce:(nonnull NSUUID *)nonce;
- (nonnull MockEvent *)insertTypingEventFromUser:(nonnull MockUser *)fromUser isTyping:(BOOL)isTyping;
- (nonnull MockEvent *)remotelyArchiveFromUser:(nonnull MockUser *)fromUser referenceDate:(nonnull NSDate *)referenceDate;
- (nonnull MockEvent *)remotelyClearHistoryFromUser:(nonnull MockUser *)fromUser referenceDate:(nonnull NSDate *)referenceDate;
- (nonnull MockEvent *)remotelyDeleteFromUser:(nonnull MockUser *)fromUser referenceDate:(nonnull NSDate *)referenceDate;

- (void)insertImageEventsFromUser:(nonnull MockUser *)fromUser;
- (void)insertPreviewImageEventFromUser:(nonnull MockUser *)fromUser correlationID:(nonnull NSUUID *)correlationID none:(nonnull NSUUID *)nonce;
- (void)insertMediumImageEventFromUser:(nonnull MockUser *)fromUser correlationID:(nonnull NSUUID *)correlationID none:(nonnull NSUUID *)nonce;

- (nullable MockEvent *)addUsersByUser:(nonnull MockUser *)byUser addedUsers:(nonnull NSArray *)addedUsers;
- (nonnull MockEvent *)removeUsersByUser:(nonnull MockUser *)byUser removedUser:(nonnull MockUser *)removedUser;
- (nonnull MockEvent *)changeNameByUser:(nonnull MockUser *)user name:(nullable NSString *)name;
- (nonnull MockEvent *)changeReceiptModeByUser:(nonnull MockUser *)user receiptMode:(NSInteger)receiptMode;
- (nonnull MockEvent *)insertAssetUploadEventForUser:(nonnull MockUser *)user data:(nonnull NSData *)data disposition:(nonnull NSDictionary *)disposition dataTypeAsMIME:(nonnull NSString *)dataTypeAsMIME assetID:(nonnull NSString *)assetID;
- (nonnull MockEvent *)connectRequestByUser:(nonnull MockUser *)byUser toUser:(nonnull MockUser *)user message:(nullable NSString *)message;

@end
