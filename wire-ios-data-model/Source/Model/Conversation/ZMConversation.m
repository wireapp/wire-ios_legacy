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


@import Foundation;
@import WireImages;
@import WireUtilities;
@import WireTransport;
@import WireCryptobox;
@import MobileCoreServices;
@import WireImages;

#import "ZMManagedObject+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+UnreadCount.h"

#import "ZMUser+Internal.h"

#import "ZMMessage+Internal.h"

#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConnection+Internal.h"

#import "ZMConversationList+Internal.h"

#import "ZMConversationListDirectory.h"
#import <WireDataModel/WireDataModel-Swift.h>
#import "NSPredicate+ZMSearch.h"

static NSString* ZMLogTag ZM_UNUSED = @"Conversations";

NSString *const ZMConversationConnectionKey = @"connection";
NSString *const ZMConversationHasUnreadMissedCallKey = @"hasUnreadMissedCall";
NSString *const ZMConversationHasUnreadUnsentMessageKey = @"hasUnreadUnsentMessage";
NSString *const ZMConversationNeedsToCalculateUnreadMessagesKey = @"needsToCalculateUnreadMessages";
NSString *const ZMConversationIsArchivedKey = @"internalIsArchived";
NSString *const ZMConversationMutedStatusKey = @"mutedStatus";
NSString *const ZMConversationAllMessagesKey = @"allMessages";
NSString *const ZMConversationHiddenMessagesKey = @"hiddenMessages";
NSString *const ZMConversationParticipantRolesKey = @"participantRoles";
NSString *const ZMConversationNonTeamRolesKey = @"nonTeamRoles";
NSString *const ZMConversationHasUnreadKnock = @"hasUnreadKnock";
NSString *const ZMConversationUserDefinedNameKey = @"userDefinedName";
NSString *const ZMIsDimmedKey = @"zmIsDimmed";
NSString *const ZMNormalizedUserDefinedNameKey = @"normalizedUserDefinedName";
NSString *const ZMConversationListIndicatorKey = @"conversationListIndicator";
NSString *const ZMConversationConversationTypeKey = @"conversationType";
NSString *const ZMConversationLastServerTimeStampKey = @"lastServerTimeStamp";
NSString *const ZMConversationLastReadServerTimeStampKey = @"lastReadServerTimeStamp";
NSString *const ZMConversationClearedTimeStampKey = @"clearedTimeStamp";
NSString *const ZMConversationArchivedChangedTimeStampKey = @"archivedChangedTimestamp";
NSString *const ZMConversationSilencedChangedTimeStampKey = @"silencedChangedTimestamp";
NSString *const ZMConversationExternalParticipantsStateKey = @"externalParticipantsState";
NSString *const ZMConversationNeedsToDownloadRolesKey = @"needsToDownloadRoles";
NSString *const ZMConversationLegalHoldStatusKey = @"legalHoldStatus";
NSString *const ZMConversationNeedsToVerifyLegalHoldKey = @"needsToVerifyLegalHold";
NSString *const ZMNotificationConversationKey = @"ZMNotificationConversationKey";
NSString *const ZMConversationEstimatedUnreadCountKey = @"estimatedUnreadCount";
NSString *const ZMConversationRemoteIdentifierDataKey = @"remoteIdentifier_data";
NSString *const SecurityLevelKey = @"securityLevel";
NSString *const ZMConversationLabelsKey = @"labels";
NSString *const ZMConversationDomainKey = @"domain";

static NSString *const ConnectedUserKey = @"connectedUser";
static NSString *const CreatorKey = @"creator";
static NSString *const DraftMessageDataKey = @"draftMessageData";
static NSString *const DraftMessageNonceKey = @"draftMessageNonce";
static NSString *const IsPendingConnectionConversationKey = @"isPendingConnectionConversation";
static NSString *const LastModifiedDateKey = @"lastModifiedDate";
static NSString *const LastReadMessageKey = @"lastReadMessage";
static NSString *const lastEditableMessageKey = @"lastEditableMessage";
static NSString *const NeedsToBeUpdatedFromBackendKey = @"needsToBeUpdatedFromBackend";
static NSString *const RemoteIdentifierKey = @"remoteIdentifier";
static NSString *const TeamRemoteIdentifierKey = @"teamRemoteIdentifier";
NSString *const TeamRemoteIdentifierDataKey = @"teamRemoteIdentifier_data";
static NSString *const VoiceChannelKey = @"voiceChannel";
static NSString *const VoiceChannelStateKey = @"voiceChannelState";

static NSString *const LocalMessageDestructionTimeoutKey = @"localMessageDestructionTimeout";
static NSString *const SyncedMessageDestructionTimeoutKey = @"syncedMessageDestructionTimeout";
static NSString *const HasReadReceiptsEnabledKey = @"hasReadReceiptsEnabled";

static NSString *const LanguageKey = @"language";

static NSString *const DownloadedMessageIDsDataKey = @"downloadedMessageIDs_data";
static NSString *const LastEventIDDataKey = @"lastEventID_data";
static NSString *const ClearedEventIDDataKey = @"clearedEventID_data";
static NSString *const ArchivedEventIDDataKey = @"archivedEventID_data";
static NSString *const LastReadEventIDDataKey = @"lastReadEventID_data";

static NSString *const TeamKey = @"team";

static NSString *const AccessModeStringsKey = @"accessModeStrings";
static NSString *const AccessRoleStringKey = @"accessRoleString";
static NSString *const AccessRoleStringsKeyV2 = @"accessRoleStringsV2";


NSTimeInterval ZMConversationDefaultLastReadTimestampSaveDelay = 3.0;

const NSUInteger ZMConversationMaxEncodedTextMessageLength = 1500;
const NSUInteger ZMConversationMaxTextMessageLength = ZMConversationMaxEncodedTextMessageLength - 50; // Empirically we verified that the encoding adds 44 bytes

@interface ZMConversation ()

@property (nonatomic) NSString *normalizedUserDefinedName;
@property (nonatomic) ZMConversationType conversationType;

@property (nonatomic) NSTimeInterval lastReadTimestampSaveDelay;
@property (nonatomic) int64_t lastReadTimestampUpdateCounter;
@property (nonatomic) BOOL internalIsArchived;

@property (nonatomic) NSDate *pendingLastReadServerTimestamp;
@property (nonatomic) NSDate *previousLastReadServerTimestamp;
@property (nonatomic) NSDate *lastReadServerTimeStamp;
@property (nonatomic) NSDate *lastServerTimeStamp;
@property (nonatomic) NSDate *clearedTimeStamp;
@property (nonatomic) NSDate *archivedChangedTimestamp;
@property (nonatomic) NSDate *silencedChangedTimestamp;

@end

/// Declaration of properties implemented (automatically) by Core Data
@interface ZMConversation (CoreDataForward)

@property (nonatomic) NSDate *primitiveLastReadServerTimeStamp;
@property (nonatomic) NSDate *primitiveLastServerTimeStamp;
@property (nonatomic) NSUUID *primitiveRemoteIdentifier;
@property (nonatomic) NSNumber *primitiveConversationType;
@property (nonatomic) NSData *remoteIdentifier_data;

@property (nonatomic) ZMConversationSecurityLevel securityLevel;
@end


@implementation ZMConversation

@dynamic userDefinedName;
@dynamic allMessages;
@dynamic lastModifiedDate;
@dynamic creator;
@dynamic normalizedUserDefinedName;
@dynamic conversationType;
@dynamic clearedTimeStamp;
@dynamic lastReadServerTimeStamp;
@dynamic lastServerTimeStamp;
@dynamic internalIsArchived;
@dynamic archivedChangedTimestamp;
@dynamic silencedChangedTimestamp;
@dynamic team;
@dynamic labels;
@dynamic participantRoles;
@dynamic nonTeamRoles;
@dynamic domain;

@synthesize pendingLastReadServerTimestamp;
@synthesize previousLastReadServerTimestamp;
@synthesize lastReadTimestampSaveDelay;
@synthesize lastReadTimestampUpdateCounter;

- (BOOL)isArchived
{
    return self.internalIsArchived;
}

- (void)setIsArchived:(BOOL)isArchived
{
    self.internalIsArchived = isArchived;
    
    if (self.lastServerTimeStamp != nil) {
        [self updateArchived:self.lastServerTimeStamp synchronize:YES];
    }
}

- (NSUInteger)estimatedUnreadCount
{
    return (unsigned long)self.internalEstimatedUnreadCount;
}

- (NSUInteger)estimatedUnreadSelfMentionCount
{
    return (unsigned long)self.internalEstimatedUnreadSelfMentionCount;
}

- (NSUInteger)estimatedUnreadSelfReplyCount
{
    return (unsigned long)self.internalEstimatedUnreadSelfReplyCount;
}

+ (NSSet *)keyPathsForValuesAffectingEstimatedUnreadCount
{
    return [NSSet setWithObjects: ZMConversationInternalEstimatedUnreadCountKey, ZMConversationLastReadServerTimeStampKey, nil];
}

+ (NSFetchRequest *)sortedFetchRequest
{
    NSFetchRequest *request = [super sortedFetchRequest];

    if(request.predicate) {
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, self.predicateForFilteringResults]];
    }
    else {
        request.predicate = self.predicateForFilteringResults;
    }
    return request;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;
{
    NSPredicate *superPredicate = [super predicateForObjectsThatNeedToBeInsertedUpstream];
    NSPredicate *onlyGoupPredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMConversationConversationTypeKey, @(ZMConversationTypeGroup)];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[superPredicate, onlyGoupPredicate]];
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    NSPredicate *superPredicate = [super predicateForObjectsThatNeedToBeUpdatedUpstream];
    NSPredicate *onlyGoupPredicate = [NSPredicate predicateWithFormat:@"(%K != NULL) AND (%K != %@) AND (%K == 0)",
                                      [self remoteIdentifierDataKey],
                                      ZMConversationConversationTypeKey, @(ZMConversationTypeInvalid),
                                      NeedsToBeUpdatedFromBackendKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[superPredicate, onlyGoupPredicate]];
}

- (void)awakeFromFetch;
{
    [super awakeFromFetch];
    self.lastReadTimestampSaveDelay = ZMConversationDefaultLastReadTimestampSaveDelay;
    if (self.managedObjectContext.zm_isSyncContext && self.needsToCalculateUnreadMessages) {
        // From the documentation: The managed object context’s change processing is explicitly disabled around this method so that you can use public setters to establish transient values and other caches without dirtying the object or its context.
        // Therefore we need to do a dispatch async  here in a performGroupedBlock to update the unread properties outside of awakeFromFetch
        ZM_WEAK(self);
        [self.managedObjectContext performGroupedBlock:^{
            ZM_STRONG(self);
            [self calculateLastUnreadMessages];
        }];
    }
}

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.lastReadTimestampSaveDelay = ZMConversationDefaultLastReadTimestampSaveDelay;
    
    if (self.managedObjectContext.zm_isSyncContext && self.needsToCalculateUnreadMessages) {
        // From the documentation: You are typically discouraged from performing fetches within an implementation of awakeFromInsert. Although it is allowed, execution of the fetch request can trigger the sending of internal Core Data notifications which may have unwanted side-effects. Since we fetch the unread messages here, we should do a dispatch async
        [self.managedObjectContext performGroupedBlock:^{
            [self calculateLastUnreadMessages];
        }];
    }
}

- (ZMUser *)connectedUser
{
    ZMConversationType internalConversationType = self.internalConversationType;
    
    if (internalConversationType == ZMConversationTypeOneOnOne || internalConversationType == ZMConversationTypeConnection) {
        return self.connection.to;
    }
    else if (self.conversationType == ZMConversationTypeOneOnOne) {
        return self.localParticipantsExcludingSelf.anyObject;
    }
    
    return nil;
}

+ (NSSet *)keyPathsForValuesAffectingConnectedUser
{
    return [NSSet setWithObject:ZMConversationConversationTypeKey];
}


- (ZMConnectionStatus)relatedConnectionState
{
    if(self.connection != nil) {
        return self.connection.status;
    }
    return ZMConnectionStatusInvalid;
}

+ (NSSet *)keyPathsForValuesAffectingRelatedConnectionState
{
    return [NSSet setWithObjects:@"connection.status", @"connection", nil];
}

- (NSSet *)ignoredKeys;
{
    static NSSet *ignoredKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *keys = [super ignoredKeys];
        NSString * const KeysIgnoredForTrackingModifications[] = {
            ZMConversationConnectionKey,
            ZMConversationConversationTypeKey,
            CreatorKey,
            DraftMessageDataKey,
            DraftMessageNonceKey,
            LastModifiedDateKey,
            ZMNormalizedUserDefinedNameKey,
            ZMConversationParticipantRolesKey,
            ZMConversationNonTeamRolesKey,
            VoiceChannelKey,
            ZMConversationHasUnreadMissedCallKey,
            ZMConversationHasUnreadUnsentMessageKey,
            ZMConversationNeedsToCalculateUnreadMessagesKey,
            ZMConversationAllMessagesKey,
            ZMConversationHiddenMessagesKey,
            ZMConversationLastServerTimeStampKey,
            SecurityLevelKey,
            ZMConversationLastUnreadKnockDateKey,
            ZMConversationLastUnreadMissedCallDateKey,
            ZMConversationLastReadLocalTimestampKey,
            ZMConversationInternalEstimatedUnreadCountKey,
            ZMConversationInternalEstimatedUnreadSelfMentionCountKey,
            ZMConversationInternalEstimatedUnreadSelfReplyCountKey,
            ZMConversationIsArchivedKey,
            ZMConversationMutedStatusKey,
            LocalMessageDestructionTimeoutKey,
            SyncedMessageDestructionTimeoutKey,
            DownloadedMessageIDsDataKey,
            LastEventIDDataKey,
            ClearedEventIDDataKey,
            ArchivedEventIDDataKey,
            LastReadEventIDDataKey,
            TeamKey,
            TeamRemoteIdentifierKey,
            TeamRemoteIdentifierDataKey,
            AccessModeStringsKey,
            AccessRoleStringKey,
            AccessRoleStringsKeyV2,
            LanguageKey,
            HasReadReceiptsEnabledKey,
            ZMConversationLegalHoldStatusKey,
            ZMConversationNeedsToVerifyLegalHoldKey,
            ZMConversationLabelsKey,
            ZMConversationNeedsToDownloadRolesKey,
            @"isSelfAnActiveMember", // DEPRECATED
            @"lastServerSyncedActiveParticipants", // DEPRECATED
            ZMConversationDomainKey
        };
        
        NSSet *additionalKeys = [NSSet setWithObjects:KeysIgnoredForTrackingModifications count:(sizeof(KeysIgnoredForTrackingModifications) / sizeof(*KeysIgnoredForTrackingModifications))];
        ignoredKeys = [keys setByAddingObjectsFromSet:additionalKeys];
    });
    return ignoredKeys;
}

- (BOOL)isReadOnly
{
    return
    (self.conversationType == ZMConversationTypeInvalid) ||
    (self.conversationType == ZMConversationTypeSelf) ||
    (self.conversationType == ZMConversationTypeConnection) ||
    (self.conversationType == ZMConversationTypeGroup && !self.isSelfAnActiveMember);
}

+ (NSSet *)keyPathsForValuesAffectingIsReadOnly;
{
    return [NSSet setWithObjects:ZMConversationConversationTypeKey, ZMConversationParticipantRolesKey, nil];
}

+ (instancetype)existingOneOnOneConversationWithUser:(ZMUser *)otherUser inUserSession:(id<ContextProvider>)session;
{
    NOT_USED(session);
    return otherUser.connection.conversation;
}

- (void)setClearedTimeStamp:(NSDate *)clearedTimeStamp
{
    [self willChangeValueForKey:ZMConversationClearedTimeStampKey];
    [self setPrimitiveValue:clearedTimeStamp forKey:ZMConversationClearedTimeStampKey];
    [self didChangeValueForKey:ZMConversationClearedTimeStampKey];
    if (self.managedObjectContext.zm_isSyncContext) {
        [self deleteOlderMessages];
    }
}

- (void)setLastReadServerTimeStamp:(NSDate *)lastReadServerTimeStamp
{
    [self willChangeValueForKey:ZMConversationLastReadServerTimeStampKey];
    [self setPrimitiveValue:lastReadServerTimeStamp forKey:ZMConversationLastReadServerTimeStampKey];
    [self didChangeValueForKey:ZMConversationLastReadServerTimeStampKey];
    
    if (self.managedObjectContext.zm_isSyncContext) {
        [self calculateLastUnreadMessages];
    }
}

- (NSUUID *)remoteIdentifier;
{
    return [self transientUUIDForKey:RemoteIdentifierKey];
}

- (void)setRemoteIdentifier:(NSUUID *)remoteIdentifier;
{
    [self setTransientUUID:remoteIdentifier forKey:RemoteIdentifierKey];
}

- (NSUUID *)teamRemoteIdentifier;
{
    return [self transientUUIDForKey:TeamRemoteIdentifierKey];
}

- (void)setTeamRemoteIdentifier:(NSUUID *)teamRemoteIdentifier;
{
    [self setTransientUUID:teamRemoteIdentifier forKey:TeamRemoteIdentifierKey];
}


+ (NSSet *)keyPathsForValuesAffectingRemoteIdentifier
{
    return [NSSet setWithObject:ZMConversationRemoteIdentifierDataKey];
}

- (void)setUserDefinedName:(NSString *)aName {
    
    [self willChangeValueForKey:ZMConversationUserDefinedNameKey];
    [self setPrimitiveValue:[[aName copy] stringByRemovingExtremeCombiningCharacters] forKey:ZMConversationUserDefinedNameKey];
    [self didChangeValueForKey:ZMConversationUserDefinedNameKey];
    
    self.normalizedUserDefinedName = [self.userDefinedName normalizedString];
}

- (ZMConversationType)conversationType
{
    ZMConversationType conversationType = [self internalConversationType];
    
    // Exception: the group conversation is considered a 1-1 if:
    // 1. Belongs to the team.
    // 2. Has no name given.
    // 3. Conversation has only one other participant.

    // Performance note: localParticipantsExcludingSelf will enumerate over all
    // local participant roles, so check its count first to avoid unncessary iterations.

    if (conversationType == ZMConversationTypeGroup &&
        self.teamRemoteIdentifier != nil &&
        self.userDefinedName.length == 0 &&
        self.localParticipantRoles.count == 2 &&
        self.localParticipantsExcludingSelf.count == 1)
    {
        conversationType = ZMConversationTypeOneOnOne;
    }
    
    return conversationType;
}

- (BOOL)isSelfConversation {
    return self.conversationType == ZMConversationTypeSelf;
}

+ (NSArray *)defaultSortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:ZMConversationIsArchivedKey ascending:YES],
             [NSSortDescriptor sortDescriptorWithKey:LastModifiedDateKey ascending:NO],
             [NSSortDescriptor sortDescriptorWithKey:ZMConversationRemoteIdentifierDataKey ascending:YES],];
}

- (BOOL)isPendingConnectionConversation;
{
    return self.connection != nil && self.connection.status == ZMConnectionStatusPending;
}

+ (NSSet *)keyPathsForValuesAffectingIsPendingConnectionConversation
{
    return [NSSet setWithObjects:ZMConversationConnectionKey, @"connection.status", nil];
}

- (ZMConversationListIndicator)conversationListIndicator;
{
    if (self.connectedUser.isPendingApprovalByOtherUser) {
        return ZMConversationListIndicatorPending;
    }
    else if (self.isCallDeviceActive) {
        return ZMConversationListIndicatorActiveCall;
    }
    else if (self.isIgnoringCall) {
        return ZMConversationListIndicatorInactiveCall;        
    }
    
    return [self unreadListIndicator];
}

+ (NSSet *)keyPathsForValuesAffectingConversationListIndicator
{
    return [[ZMConversation keyPathsForValuesAffectingUnreadListIndicator] union:[NSSet setWithObject: @"voiceChannelState"]];
}


- (BOOL)hasDraftMessage
{
    return (0 < self.draftMessage.text.length);
}

+ (NSSet *)keyPathsForValuesAffectingHasDraftMessage
{
    return [NSSet setWithObject:DraftMessageDataKey];
}

- (ZMMessage *)lastEditableMessage;
{
    __block ZMMessage *result;
    [[self lastMessagesWithLimit:50] enumerateObjectsUsingBlock:^(ZMMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
        NOT_USED(idx);
        if ([message isEditableMessage]) {
            result = message;
            *stop = YES;
        }
    }];
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingFirstUnreadMessage
{
    return [NSSet setWithObjects:ZMConversationAllMessagesKey, ZMConversationLastReadServerTimeStampKey, nil];
}

- (NSSet<NSString *> *)filterUpdatedLocallyModifiedKeys:(NSSet<NSString *> *)updatedKeys
{
    NSMutableSet *newKeys = [super filterUpdatedLocallyModifiedKeys:updatedKeys].mutableCopy;
    
    // Don't sync the conversation name if it was set before inserting the conversation
    // as it will already get synced when inserting the conversation on the backend.
    if (self.isInserted && nil != self.userDefinedName && [newKeys containsObject:ZMConversationUserDefinedNameKey]) {
        [newKeys removeObject:ZMConversationUserDefinedNameKey];
    }
    
    return newKeys;
}

- (BOOL)canMarkAsUnread
{
    if (self.estimatedUnreadCount > 0) {
        return NO;
    }
    
    if (nil == [self lastMessageCanBeMarkedUnread]) {
        return NO;
    }
    
    return YES;
}

- (ZMMessage *)lastMessageCanBeMarkedUnread
{
    for (ZMMessage *message in [self lastMessagesWithLimit:50]) {
        if (message.canBeMarkedUnread) {
            return message;
        }
    }
    
    return nil;
}

- (void)markAsUnread
{
    ZMMessage *lastMessageCanBeMarkedUnread = [self lastMessageCanBeMarkedUnread];
    
    if (lastMessageCanBeMarkedUnread == nil) {
        ZMLogError(@"Cannot mark as read: no message to mark in %@", self);
        return;
    }
    
    [lastMessageCanBeMarkedUnread markAsUnread];
}

@end



@implementation ZMConversation (Internal)

@dynamic connection;
@dynamic creator;
@dynamic lastModifiedDate;
@dynamic normalizedUserDefinedName;
@dynamic hiddenMessages;

+ (NSSet *)keyPathsForValuesAffectingIsArchived
{
    return [NSSet setWithObject:ZMConversationIsArchivedKey];
}

+ (NSString *)entityName;
{
    return @"Conversation";
}

- (NSMutableSet<ZMMessage *> *)mutableMessages;
{
    return [self mutableSetValueForKey:ZMConversationAllMessagesKey];
}

+ (ZMConversationList *)conversationsIncludingArchivedInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.conversationsIncludingArchived;
}

+ (ZMConversationList *)archivedConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.archivedConversations;
}

+ (ZMConversationList *)clearedConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.clearedConversations;
}

+ (ZMConversationList *)conversationsExcludingArchivedInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.unarchivedConversations;
}

+ (ZMConversationList *)pendingConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.pendingConnectionConversations;
}

- (ZMConversationType)internalConversationType
{
    [self willAccessValueForKey:ZMConversationConversationTypeKey];
    ZMConversationType conversationType =  (ZMConversationType)[[self primitiveConversationType] shortValue];
    [self didAccessValueForKey:ZMConversationConversationTypeKey];
    return conversationType;
}

// Used to merge a local 1:1 conversation with the remote conversation after a connection
// request has been accepted.
- (void)mergeWithExistingConversationWithRemoteID:(NSUUID *)remoteID;
{
    ZMConversation *existingConversation = [ZMConversation internalFetchObjectWithRemoteIdentifier:remoteID inManagedObjectContext:self.managedObjectContext];
    if ((existingConversation != nil) && ![existingConversation isEqual:self]) {
        Require(self.remoteIdentifier == nil);
        [self.mutableMessages unionSet:existingConversation.allMessages];
        // Just to be on the safe side, force update:
        self.needsToBeUpdatedFromBackend = YES;
        // This is a duplicate. Delete the other one
        [self.managedObjectContext deleteObject:existingConversation];
    }
    self.remoteIdentifier = remoteID;
}

+ (NSPredicate *)predicateForSearchQuery:(NSString *)searchQuery team:(Team *)team moc:(NSManagedObjectContext *)moc
{
    NSPredicate *teamPredicate = [NSPredicate predicateWithFormat:@"(%K == %@)", TeamKey, team];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[[ZMConversation predicateForSearchQuery:searchQuery selfUser: [ZMUser selfUserInContext:moc]], teamPredicate]];
}

+ (NSPredicate *)userDefinedNamePredicateForSearchString:(NSString *)searchString;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormatDictionary:@{ZMNormalizedUserDefinedNameKey: @"%K MATCHES %@"}
                                                   matchingSearchString:[searchString normalizedForSearch]];
    return predicate;
}


+ (NSUUID *)selfConversationIdentifierInContext:(NSManagedObjectContext *)context;
{
    // remoteID of self-conversation is guaranteed to be the same as remoteID of self-user
    ZMUser *selfUser = [ZMUser selfUserInContext:context];
    return selfUser.remoteIdentifier;
}

+ (ZMConversation *)selfConversationInContext:(NSManagedObjectContext *)managedObjectContext
{
    NSUUID *selfUserID = [ZMConversation selfConversationIdentifierInContext:managedObjectContext];
    return [ZMConversation fetchWith:selfUserID in:managedObjectContext];
}

- (void)appendMessage:(ZMMessage *)message;
{
    Require(message != nil);
    [message updateNormalizedText];
    message.visibleInConversation = self;
    
    [self addAllMessagesObject:message];
    [self updateTimestampsAfterInsertingMessage:message];
}

- (void)unarchiveIfNeeded
{
    if (self.isArchived) {
        self.isArchived = NO;
    }
}

@end


@implementation ZMConversation (KeyValueValidation)

- (BOOL)validateUserDefinedName:(NSString **)ioName error:(NSError **)outError
{
    BOOL result = [ExtremeCombiningCharactersValidator validateValue:ioName error:outError];
    if (!result || (outError != nil && *outError != nil)) {
        return NO;
    }
    
    result &= *ioName == nil || [StringLengthValidator validateValue:ioName
                                                 minimumStringLength:1
                                                 maximumStringLength:64
                                                   maximumByteLength:INT_MAX
                                                               error:outError];

    return result;
}

@end


@implementation ZMConversation (Connections)

- (NSString *)connectionMessage;
{
    return self.connection.message.stringByRemovingExtremeCombiningCharacters;
}

@end


@implementation NSUUID (ZMSelfConversation)

- (BOOL)isSelfConversationRemoteIdentifierInContext:(NSManagedObjectContext *)moc;
{
    // The self conversation has the same remote ID as the self user:
    return [self isSelfUserRemoteIdentifierInContext:moc];
}

@end


@implementation ZMConversation (Optimization)

+ (void)refreshObjectsThatAreNotNeededInSyncContext:(NSManagedObjectContext *)managedObjectContext;
{
    NSMutableArray *conversationsToKeep = [NSMutableArray array];
    NSMutableSet *usersToKeep = [NSMutableSet set];
    NSMutableSet *messagesToKeep = [NSMutableSet set];
    
    // make sure that the Set is not mutated while being enumerated
    NSSet *registeredObjects = managedObjectContext.registeredObjects;
    
    // gather objects to keep
    for(NSManagedObject *obj in registeredObjects) {
        if (!obj.isFault) {
            if ([obj isKindOfClass:ZMConversation.class]) {
                ZMConversation *conversation = (ZMConversation *)obj;
                
                if(conversation.shouldNotBeRefreshed) {
                    [conversationsToKeep addObject:conversation];
                    [usersToKeep unionSet:conversation.localParticipants];
                }
            } else if ([obj isKindOfClass:ZMOTRMessage.class]) {
                ZMOTRMessage *message = (ZMOTRMessage *)obj;
                if (![message hasFaultForRelationshipNamed:ZMMessageMissingRecipientsKey] && !message.missingRecipients.isEmpty) {
                    [messagesToKeep addObject:obj];
                }
            }
        }
    }
    [usersToKeep addObject:[ZMUser selfUserInContext:managedObjectContext]];
    
    // turn into a fault
    for(NSManagedObject *obj in registeredObjects) {
        if(!obj.isFault) {
            
            const BOOL isUser = [obj isKindOfClass:ZMUser.class];
            const BOOL isMessage = [obj isKindOfClass:ZMMessage.class];
            const BOOL isConversation = [obj isKindOfClass:ZMConversation.class];
            
            const BOOL isOfTypeToBeRefreshed = isUser || isMessage || isConversation;
            
            if ((isConversation && [conversationsToKeep indexOfObjectIdenticalTo:obj] != NSNotFound) ||
                (isUser && [usersToKeep.allObjects indexOfObjectIdenticalTo:obj] != NSNotFound) ||
                (isMessage && [messagesToKeep.allObjects indexOfObjectIdenticalTo:obj] != NSNotFound) ||
                !isOfTypeToBeRefreshed) {
                continue;
            }
            [managedObjectContext refreshObject:obj mergeChanges:obj.hasChanges];
        }
    }
}

- (BOOL)shouldNotBeRefreshed
{
    static const int HOUR_IN_SEC = 60 * 60;
    static const NSTimeInterval STALENESS = -36 * HOUR_IN_SEC;
    return (self.isFault) || (self.lastModifiedDate == nil) || (self.lastModifiedDate.timeIntervalSinceNow > STALENESS);
}

@end


@implementation ZMConversation (History)


- (void)clearMessageHistory
{
    self.isArchived = YES;
    self.clearedTimeStamp = self.lastServerTimeStamp; // the setter of this deletes all messages
    self.lastReadServerTimeStamp = self.lastServerTimeStamp;
}

- (void)revealClearedConversation
{
    self.isArchived = NO;
}

@end
