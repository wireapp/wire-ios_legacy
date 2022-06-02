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


#import "ZMConversation.h"
#import "ZMManagedObject+Internal.h"
#import "ZMMessage.h"
#import "ZMConnection.h"
#import "ZMConversationSecurityLevel.h"

@import WireImages;

@class ZMClientMessage;
@class ZMAssetClientMessage;
@class ZMConnection;
@class ZMUser;
@class ZMConversationList;
@class ZMLastRead;
@class ZMCleared;
@class ZMUpdateEvent;
@class ZMLocationData;
@class ZMSystemMessage;
@class Team;

NS_ASSUME_NONNULL_BEGIN
extern NSString *const ZMConversationConnectionKey;
extern NSString *const ZMConversationHasUnreadMissedCallKey;
extern NSString *const ZMConversationHasUnreadUnsentMessageKey;
extern NSString *const ZMConversationNeedsToCalculateUnreadMessagesKey;
extern NSString *const ZMConversationIsArchivedKey;
extern NSString *const ZMConversationMutedStatusKey;
extern NSString *const ZMConversationAllMessagesKey;
extern NSString *const ZMConversationHiddenMessagesKey;
extern NSString *const ZMConversationParticipantRolesKey;
extern NSString *const ZMConversationHasUnreadKnock;
extern NSString *const ZMConversationUserDefinedNameKey;
extern NSString *const ZMVisibleWindowLowerKey;
extern NSString *const ZMVisibleWindowUpperKey;
extern NSString *const ZMIsDimmedKey;
extern NSString *const ZMNormalizedUserDefinedNameKey;
extern NSString *const ZMConversationListIndicatorKey;
extern NSString *const ZMConversationConversationTypeKey;
extern NSString *const ZMConversationExternalParticipantsStateKey;
extern NSString *const ZMConversationNeedsToDownloadRolesKey;

extern NSString *const ZMConversationLastReadServerTimeStampKey;
extern NSString *const ZMConversationLastServerTimeStampKey;
extern NSString *const ZMConversationClearedTimeStampKey;
extern NSString *const ZMConversationArchivedChangedTimeStampKey;
extern NSString *const ZMConversationSilencedChangedTimeStampKey;

extern NSString *const ZMNotificationConversationKey;
extern NSString *const ZMConversationRemoteIdentifierDataKey;
extern NSString *const TeamRemoteIdentifierDataKey;

extern const NSUInteger ZMConversationMaxTextMessageLength;
extern NSTimeInterval ZMConversationDefaultLastReadTimestampSaveDelay;
extern NSString *const ZMConversationEstimatedUnreadCountKey;

extern NSString *const ZMConversationInternalEstimatedUnreadSelfMentionCountKey;
extern NSString *const ZMConversationInternalEstimatedUnreadSelfReplyCountKey;
extern NSString *const ZMConversationInternalEstimatedUnreadCountKey;
extern NSString *const ZMConversationLastUnreadKnockDateKey;
extern NSString *const ZMConversationLastUnreadMissedCallDateKey;
extern NSString *const ZMConversationLastReadLocalTimestampKey;
extern NSString *const ZMConversationLegalHoldStatusKey;

extern NSString *const SecurityLevelKey;
extern NSString *const ZMConversationLabelsKey;
extern NSString *const ZMConversationDomainKey;

NS_ASSUME_NONNULL_END

@interface ZMConversation (Internal)

+ (nonnull ZMConversationList *)conversationsIncludingArchivedInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)archivedConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)clearedConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)conversationsExcludingArchivedInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)pendingConversationsInContext:(nonnull NSManagedObjectContext *)moc;

+ (nonnull NSPredicate *)predicateForSearchQuery:(nonnull NSString *)searchQuery team:(nullable Team *)team moc:(nonnull NSManagedObjectContext *)moc;
+ (nonnull NSPredicate *)userDefinedNamePredicateForSearchString:(nonnull NSString *)searchString;

@property (nonatomic) BOOL internalIsArchived;

@property (nonatomic, nullable) NSDate *pendingLastReadServerTimestamp;
@property (nonatomic, nullable) NSDate *previousLastReadServerTimestamp;
@property (nonatomic, nullable) NSDate *lastServerTimeStamp;
@property (nonatomic, nullable) NSDate *lastReadServerTimeStamp;
@property (nonatomic, nullable) NSDate *clearedTimeStamp;
@property (nonatomic, nullable) NSDate *archivedChangedTimestamp;
@property (nonatomic, nullable) NSDate *silencedChangedTimestamp;

@property (nonatomic, nullable) NSUUID *remoteIdentifier;
@property (nonatomic, nullable) NSUUID *teamRemoteIdentifier;
@property (readonly, nonatomic, nonnull) NSMutableSet<ZMMessage *> *mutableMessages;
@property (readonly, nonatomic, nonnull) NSSet<ZMMessage *> *hiddenMessages;
@property (nonatomic, nullable) ZMConnection *connection;
@property (readonly, nonatomic) enum ZMConnectionStatus relatedConnectionState; // This is a computed property, needed for snapshoting
@property (nonatomic, nonnull) ZMUser *creator;
@property (nonatomic, nullable) NSDate *lastModifiedDate;
@property (nonatomic) ZMConversationType conversationType;
@property (nonatomic, readonly) BOOL isSelfConversation;
@property (nonatomic, copy, nullable) NSString *normalizedUserDefinedName;
@property (nonatomic) NSTimeInterval lastReadTimestampSaveDelay;
@property (nonatomic) int64_t lastReadTimestampUpdateCounter;

/**
    Appends the given message in the conversation.
 
    @param message The message that should be inserted.
*/
- (void)appendMessage:(nonnull ZMMessage *)message;

- (void)mergeWithExistingConversationWithRemoteID:(nonnull NSUUID *)remoteID;

- (ZMConversationType)internalConversationType;

+ (nonnull NSUUID *)selfConversationIdentifierInContext:(nonnull NSManagedObjectContext *)context;
+ (nonnull ZMConversation *)selfConversationInContext:(nonnull NSManagedObjectContext *)managedObjectContext;

- (void)unarchiveIfNeeded;

@end


@interface NSUUID (ZMSelfConversation)

- (BOOL)isSelfConversationRemoteIdentifierInContext:(nonnull NSManagedObjectContext *)moc;

@end


@interface ZMConversation (Optimization)

+ (void)refreshObjectsThatAreNotNeededInSyncContext:(nonnull NSManagedObjectContext *)managedObjectContext;
@end


@interface ZMConversation (CoreDataGeneratedAccessors)

// CoreData autogenerated methods
- (void)addHiddenMessagesObject:(nonnull ZMMessage *)value;
- (void)removeHiddenMessagesObject:(nonnull ZMMessage *)value;
- (void)addHiddenMessages:(nonnull NSSet<ZMMessage *> *)values;
- (void)removeHiddenMessages:(nonnull NSSet<ZMMessage *> *)values;
- (void)addAllMessagesObject:(nonnull ZMMessage *)value;
- (void)removeAllMessagesObject:(nonnull ZMMessage *)value;
- (void)addAllMessages:(nonnull NSSet<ZMMessage *> *)values;
- (void)removeAllMessages:(nonnull NSSet<ZMMessage *> *)values;
@end

