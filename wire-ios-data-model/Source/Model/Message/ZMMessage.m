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


@import WireUtilities;
@import WireProtos;
@import MobileCoreServices;
@import ImageIO;


#import "ZMMessage+Internal.h"
#import "ZMConversation.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConversation+Internal.h"

#import "ZMConversation+UnreadCount.h"
#import "ZMUpdateEvent+WireDataModel.h"

#import <WireDataModel/WireDataModel-Swift.h>
#import <WireCryptobox/cbox.h>


static NSString *ZMLogTag ZM_UNUSED = @"ephemeral";

static NSTimeInterval ZMDefaultMessageExpirationTime = 30;

NSString * const ZMMessageEventIDDataKey = @"eventID_data";
NSString * const ZMMessageIsExpiredKey = @"isExpired";
NSString * const ZMMessageMissingRecipientsKey = @"missingRecipients";
NSString * const ZMMessageServerTimestampKey = @"serverTimestamp";
NSString * const ZMMessageImageTypeKey = @"imageType";
NSString * const ZMMessageIsAnimatedGifKey = @"isAnimatedGIF";
NSString * const ZMMessageMediumRemoteIdentifierDataKey = @"mediumRemoteIdentifier_data";
NSString * const ZMMessageMediumRemoteIdentifierKey = @"mediumRemoteIdentifier";
NSString * const ZMMessageOriginalDataProcessedKey = @"originalDataProcessed";
NSString * const ZMMessageMediumDataLoadedKey = @"mediumDataLoaded";
NSString * const ZMMessageOriginalSizeDataKey = @"originalSize_data";
NSString * const ZMMessageOriginalSizeKey = @"originalSize";
NSString * const ZMMessageConversationKey = @"visibleInConversation";
NSString * const ZMMessageHiddenInConversationKey = @"hiddenInConversation";
NSString * const ZMMessageExpirationDateKey = @"expirationDate";
NSString * const ZMMessageNameKey = @"name";
NSString * const ZMMessageNeedsToBeUpdatedFromBackendKey = @"needsToBeUpdatedFromBackend";
NSString * const ZMMessageNonceDataKey = @"nonce_data";
NSString * const ZMMessageSenderKey = @"sender";
NSString * const ZMMessageSystemMessageTypeKey = @"systemMessageType";
NSString * const ZMMessageSystemMessageClientsKey = @"clients";
NSString * const ZMMessageTextKey = @"text";
NSString * const ZMMessageUserIDsKey = @"users_ids";
NSString * const ZMMessageParticipantsRemovedReasonKey = @"participantsRemovedReason";
NSString * const ZMMessageUsersKey = @"users";
NSString * const ZMMessageClientsKey = @"clients";
NSString * const ZMMessageAddedUsersKey = @"addedUsers";
NSString * const ZMMessageRemovedUsersKey = @"removedUsers";
NSString * const ZMMessageNeedsUpdatingUsersKey = @"needsUpdatingUsers";
NSString * const ZMMessageSenderClientIDKey = @"senderClientID";
NSString * const ZMMessageReactionKey = @"reactions";
NSString * const ZMMessageConfirmationKey = @"confirmations";
NSString * const ZMMessageDestructionDateKey = @"destructionDate";
NSString * const ZMMessageIsObfuscatedKey = @"isObfuscated";
NSString * const ZMMessageCachedCategoryKey = @"cachedCategory";
NSString * const ZMMessageNormalizedTextKey = @"normalizedText";
NSString * const ZMMessageDeliveryStateKey = @"deliveryState";
NSString * const ZMMessageDurationKey = @"duration";
NSString * const ZMMessageChildMessagesKey = @"childMessages";
NSString * const ZMMessageParentMessageKey = @"parentMessage";
NSString * const ZMSystemMessageMessageTimerKey = @"messageTimer";
NSString * const ZMSystemMessageRelevantForConversationStatusKey = @"relevantForConversationStatus";
NSString * const ZMSystemMessageAllTeamUsersAddedKey = @"allTeamUsersAdded";
NSString * const ZMSystemMessageNumberOfGuestsAddedKey = @"numberOfGuestsAdded";
NSString * const ZMMessageRepliesKey = @"replies";
NSString * const ZMMessageQuoteKey = @"quote";
NSString * const ZMMessageExpectReadConfirmationKey = @"expectsReadConfirmation";
NSString * const ZMMessageLinkAttachmentsKey = @"linkAttachments";
NSString * const ZMMessageNeedsLinkAttachmentsUpdateKey = @"needsLinkAttachmentsUpdate";
NSString * const ZMMessageDiscoveredClientsKey = @"discoveredClients";
NSString * const ZMMessageButtonStatesKey = @"buttonStates";
NSString * const ZMMessageDecryptionErrorCodeKey = @"decryptionErrorCode";


@interface ZMMessage ()

+ (ZMConversation *)conversationForUpdateEvent:(ZMUpdateEvent *)event inContext:(NSManagedObjectContext *)context prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)event forConversation:(ZMConversation *)conversation;

@property (nonatomic) NSSet *missingRecipients;

@end;



@interface ZMMessage (CoreDataForward)

@property (nonatomic) BOOL isExpired;
@property (nonatomic) NSDate *expirationDate;
@property (nonatomic) NSDate *destructionDate;
@property (nonatomic) BOOL isObfuscated;

@end


@interface ZMImageMessage (CoreDataForward)

@property (nonatomic) NSData *primitiveMediumData;

@end



@implementation ZMMessage

@dynamic missingRecipients;
@dynamic isExpired;
@dynamic expirationDate;
@dynamic destructionDate;
@dynamic senderClientID;
@dynamic reactions;
@dynamic confirmations;
@dynamic isObfuscated;
@dynamic normalizedText;
@dynamic delivered;

- (instancetype)initWithNonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self.class entityName] inManagedObjectContext:managedObjectContext];
    self = [super initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
    
    if (self != nil) {
        self.nonce = nonce;
    }
    
    return self;
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
{
    ZMMessage *message = [self createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:moc prefetchResult:nil];
    [message updateCategoryCache];
    return message;
}

- (BOOL)isUnreadMessage
{
    NSDate *lastReadTimeStamp = self.conversation.lastReadServerTimeStamp;
    
    // has conversation && (no last read timestamp || last read timstamp is earlier than msg timestamp)
    return self.conversation != nil &&
            (lastReadTimeStamp == nil ||
             (self.serverTimestamp != nil && [self.serverTimestamp compare:lastReadTimeStamp] == NSOrderedDescending));
}

- (BOOL)shouldGenerateUnreadCount
{
    return YES;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    return [NSPredicate predicateWithValue:NO];
}

+ (NSString *)remoteIdentifierKey;
{
    return ZMMessageNonceDataKey;
}

+ (NSString *)entityName;
{
    return @"Message";
}

+ (NSString *)sortKey;
{
    return ZMMessageNonceDataKey;
}

+ (void)setDefaultExpirationTime:(NSTimeInterval)defaultExpiration
{
    ZMDefaultMessageExpirationTime = defaultExpiration;
}

+ (NSTimeInterval)defaultExpirationTime
{
    return ZMDefaultMessageExpirationTime;
}

+ (void)resetDefaultExpirationTime
{
    ZMDefaultMessageExpirationTime = ZMTransportRequestDefaultExpirationInterval;
}

- (void)resend;
{
    self.isExpired = NO;
    [self setExpirationDate];
    [self prepareToSend];
}

- (void)setExpirationDate
{
    self.expirationDate = [NSDate dateWithTimeIntervalSinceNow:[self.class defaultExpirationTime]];
}

- (void)removeExpirationDate;
{
    self.expirationDate = nil;
}

- (void)markAsSent
{
    self.isExpired = NO;
    [self removeExpirationDate];
}

- (BOOL)needsReadConfirmation {
    return NO;
}

- (void)expire;
{
    self.isExpired = YES;
    [self removeExpirationDate];
    self.conversation.hasUnreadUnsentMessage = YES;
}

+ (NSSet *)keyPathsForValuesAffectingDeliveryState;
{
    return [NSMutableSet setWithObjects: ZMMessageIsExpiredKey, ZMMessageConfirmationKey, nil];
}

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.serverTimestamp = [self dateIgnoringNanoSeconds];
}

- (NSDate *)dateIgnoringNanoSeconds
{
    double currentMilliseconds = floor([[NSDate date] timeIntervalSince1970]*1000);
    return [NSDate dateWithTimeIntervalSince1970:(currentMilliseconds/1000)];
}


- (NSUUID *)nonce;
{
    return [self transientUUIDForKey:@"nonce"];
}

- (void)setNonce:(NSUUID *)nonce;
{
    [self setTransientUUID:nonce forKey:@"nonce"];
}

+ (NSArray *)defaultSortDescriptors;
{
    static NSArray *sd;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSortDescriptor *serverTimestamp = [NSSortDescriptor sortDescriptorWithKey:ZMMessageServerTimestampKey ascending:YES];
        sd = @[serverTimestamp];
    });
    return sd;
}

- (NSComparisonResult)compare:(ZMMessage *)other;
{
    for (NSSortDescriptor *sd in [[self class] defaultSortDescriptors]) {
        NSComparisonResult r = [sd compareObject:self toObject:other];
        if (r != NSOrderedSame) {
            return r;
        }
    }
    return NSOrderedSame;
}

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)event forConversation:(ZMConversation *)conversation
{    
    self.visibleInConversation = conversation;
    ZMUser *sender = [ZMUser fetchOrCreateWith:event.senderUUID domain:event.senderDomain in:self.managedObjectContext];
    if (sender != nil && !sender.isZombieObject && self.managedObjectContext == sender.managedObjectContext) {
        self.sender = sender;
    } else {
        ZMLogError(@"Sender is nil or from a different context than message. \n Sender is zombie %@: %@ \n Message: %@", @(sender.isZombieObject), sender, self);
    }
    
    [self updateQuoteRelationships];
    [conversation updateTimestampsAfterUpdatingMessage:self];
}

+ (ZMConversation *)conversationForUpdateEvent:(ZMUpdateEvent *)event inContext:(NSManagedObjectContext *)moc prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    NSUUID *conversationUUID = event.conversationUUID;
    
    VerifyReturnNil(conversationUUID != nil);

    ZMConversation *conversation = prefetchResult.conversationsByRemoteIdentifier[conversationUUID];
    if (nil != conversation && (conversation.domain == nil || conversation.domain == event.conversationDomain)) {
        return conversation;
    }

    return [ZMConversation fetchOrCreateWith:conversationUUID domain:event.conversationDomain in:moc];
}

- (void)removeMessageClearingSender:(BOOL)clearingSender
{
    self.hiddenInConversation = self.conversation;
    self.visibleInConversation = nil;
    self.replies = [[NSSet alloc] init];
    [self clearAllReactions];
    [self clearConfirmations];
    
    if (clearingSender) {
        self.sender = nil;
        self.senderClientID = nil;
    }
}

+ (void)stopDeletionTimerForMessage:(ZMMessage *)message
{
    NSManagedObjectContext *uiMOC = message.managedObjectContext;
    if (!uiMOC.zm_isUserInterfaceContext) {
        uiMOC = uiMOC.zm_userInterfaceContext;
    }
    NSManagedObjectID *messageID = message.objectID;
    [uiMOC performGroupedBlock:^{
        NSError *error;
        ZMMessage *uiMessage = [uiMOC existingObjectWithID:messageID error:&error];
        if (error != nil || uiMessage == nil) {
            return;
        }
        [uiMOC.zm_messageDeletionTimer stopTimerForMessage:uiMessage];
    }];
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(__unused NSSet *)updatedKeys
{
    NSUUID *nonce = [self nonceFromPostPayload:payload];
    if (nonce != nil && ![self.nonce isEqual:nonce]) {
        ZMLogWarn(@"send message response nonce does not match");
        return;
    }
    
    NSDate *timestamp = [payload dateFor:@"time"];
    if (timestamp == nil) {
        ZMLogWarn(@"No time in message post response from backend.");
    } else {
        self.serverTimestamp = timestamp;
    }
    
    [self.conversation updateTimestampsAfterUpdatingMessage:self];
}

- (NSString *)shortDebugDescription;
{
    // This will make "seconds since" easier to read:
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = YES;
    
    return [NSString stringWithFormat:@"<%@: %p> id: %@, conversation: %@, nonce: %@, sender: %@, server timestamp: %@",
            self.class, self,
            self.objectID.URIRepresentation.lastPathComponent,
            self.conversation.objectID.URIRepresentation.lastPathComponent,
            [self.nonce.UUIDString.lowercaseString substringToIndex:4],
            self.sender.objectID.URIRepresentation.lastPathComponent,
            [formatter stringFromNumber:@(self.serverTimestamp.timeIntervalSinceNow)]
            ];
}

+ (instancetype)fetchMessageWithNonce:(NSUUID *)nonce
                      forConversation:(ZMConversation *)conversation
               inManagedObjectContext:(NSManagedObjectContext *)moc
{
    return [self fetchMessageWithNonce:nonce
                       forConversation:conversation
                inManagedObjectContext:moc
                        prefetchResult:nil
          assumeMissingIfNotPrefetched:NO];
}

+ (instancetype)fetchMessageWithNonce:(NSUUID *)nonce
                      forConversation:(ZMConversation *)conversation
               inManagedObjectContext:(NSManagedObjectContext *)moc
                       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    return [self fetchMessageWithNonce:nonce
                       forConversation:conversation
                inManagedObjectContext:moc
                        prefetchResult:prefetchResult
          assumeMissingIfNotPrefetched:NO];
}


+ (instancetype)fetchMessageWithNonce:(NSUUID *)nonce
                      forConversation:(ZMConversation *)conversation
               inManagedObjectContext:(NSManagedObjectContext *)moc
                       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
         assumeMissingIfNotPrefetched:(BOOL)assumeMissingIfNotPrefetched
{
    NSSet <ZMMessage *>* prefetchedMessages = prefetchResult.messagesByNonce[nonce];
    
    if (nil != prefetchedMessages) {
        for (ZMMessage *prefetchedMessage in prefetchedMessages) {
            if ([prefetchedMessage isKindOfClass:[self class]]) {
                return prefetchedMessage;
            }
        }
    }

    if (prefetchResult != nil && assumeMissingIfNotPrefetched) {
        return nil;
    }
    
    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.entityName];
    NSPredicate *noncePredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageNonceDataKey, [nonce data]];
    
    BOOL checkedAllHiddenMessages = NO;
    BOOL checkedAllVisibleMessage = NO;

    if (![conversation hasFaultForRelationshipNamed:ZMConversationAllMessagesKey]) {
        checkedAllVisibleMessage = YES;
        for (ZMMessage *message in conversation.allMessages) {
            if (message.isFault) {
                checkedAllVisibleMessage = NO;
            } else if ([message.entity isKindOfEntity:entity] && [noncePredicate evaluateWithObject:message]) {
                return (id) message;
            }
        }
    }
    
    if (![conversation hasFaultForRelationshipNamed:ZMConversationHiddenMessagesKey]) {
        checkedAllHiddenMessages = YES;
        for (ZMMessage *message in conversation.hiddenMessages) {
            if (message.isFault) {
                checkedAllHiddenMessages = NO;
            } else if ([message.entity isKindOfEntity:entity] && [noncePredicate evaluateWithObject:message]) {
                return (id) message;
            }
        }
    }

    if (checkedAllVisibleMessage && checkedAllHiddenMessages) {
        return nil;
    }

    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@", ZMMessageConversationKey, conversation.objectID, ZMMessageHiddenInConversationKey, conversation.objectID];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[noncePredicate, conversationPredicate]];
    NSFetchRequest *fetchRequest = [ZMMessage sortedFetchRequestWithPredicate:predicate];
    fetchRequest.fetchLimit = 2;
    fetchRequest.includesSubentities = YES;
    
    NSArray* fetchResult = [moc executeFetchRequestOrAssert:fetchRequest];
    VerifyString([fetchResult count] <= 1, "More than one message with the same nonce in the same conversation");
    ZMMessage *message = fetchResult.firstObject;
    
    if ([message.entity isKindOfEntity:entity]) {
        return message;
    } else {
        return nil;
    }
}


+ (NSPredicate *)predicateForMessagesThatWillExpire;
{
    return [NSPredicate predicateWithFormat:@"%K == 0 && %K > %@",
            ZMMessageIsExpiredKey,
            ZMMessageExpirationDateKey,
            [NSDate dateWithTimeIntervalSince1970:0]];
}


+ (BOOL)doesEventTypeGenerateMessage:(ZMUpdateEventType)type;
{
    return
        (type == ZMUpdateEventTypeConversationAssetAdd) ||
        (type == ZMUpdateEventTypeConversationMessageAdd) ||
        (type == ZMUpdateEventTypeConversationClientMessageAdd) ||
        (type == ZMUpdateEventTypeConversationOtrMessageAdd) ||
        (type == ZMUpdateEventTypeConversationOtrAssetAdd) ||
        (type == ZMUpdateEventTypeConversationKnock) ||
        [ZMSystemMessage doesEventTypeGenerateSystemMessage:type];
}


+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *__unused)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *__unused)moc
                                      prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass(self), NSStringFromSelector(_cmd));
    return nil;
}

+ (NSPredicate *)predicateForMessageInConversation:(ZMConversation *)conversation withNonces:(NSSet<NSUUID *> *)nonces;
{
    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@", ZMMessageConversationKey, conversation.objectID, ZMMessageHiddenInConversationKey, conversation.objectID];
    NSSet *noncesData = [nonces mapWithBlock:^NSData*(NSUUID *uuid) {
        return uuid.data;
    }];
    NSPredicate *noncePredicate = [NSPredicate predicateWithFormat:@"%K IN %@", noncesData];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[conversationPredicate, noncePredicate]];
}

+ (NSPredicate *)predicateForMessagesThatNeedToUpdateLinkAttachments
{
    return [NSPredicate predicateWithFormat:@"(%K == YES)", ZMMessageNeedsLinkAttachmentsUpdateKey];
}

+ (NSSet <ZMMessage *> *)messagesWithRemoteIDs:(NSSet <NSUUID *>*)UUIDs inContext:(NSManagedObjectContext *)moc;
{
    return [self fetchObjectsWithRemoteIdentifiers:UUIDs inManagedObjectContext:moc];
}

+(NSString *)remoteIdentifierDataKey {
    return ZMMessageNonceDataKey;
}

@end



@implementation ZMMessage (PersistentChangeTracking)

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;
{
    return [NSPredicate predicateWithValue:NO];
}

- (NSSet *)ignoredKeys;
{
    static NSSet *ignoredKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *keys = [super ignoredKeys];
        NSArray *newKeys = @[
                             ZMMessageConversationKey,
                             ZMMessageExpirationDateKey,
                             ZMMessageImageTypeKey,
                             ZMMessageIsAnimatedGifKey,
                             ZMMessageMediumRemoteIdentifierDataKey,
                             ZMMessageNameKey,
                             ZMMessageNonceDataKey,
                             ZMMessageOriginalDataProcessedKey,
                             ZMMessageOriginalSizeDataKey,
                             ZMMessageSenderKey,
                             ZMMessageServerTimestampKey,
                             ZMMessageSystemMessageTypeKey,
                             ZMMessageTextKey,
                             ZMMessageUserIDsKey,
                             ZMMessageParticipantsRemovedReasonKey,
                             ZMMessageEventIDDataKey,
                             ZMMessageUsersKey,
                             ZMMessageClientsKey,
                             ZMMessageHiddenInConversationKey,
                             ZMMessageMissingRecipientsKey,
                             ZMMessageMediumDataLoadedKey,
                             ZMMessageAddedUsersKey,
                             ZMMessageRemovedUsersKey,
                             ZMMessageNeedsUpdatingUsersKey,
                             ZMMessageSenderClientIDKey,
                             ZMMessageConfirmationKey,
                             ZMMessageReactionKey,
                             ZMMessageDestructionDateKey,
                             ZMMessageIsObfuscatedKey,
                             ZMMessageCachedCategoryKey,
                             ZMMessageNormalizedTextKey,
                             ZMMessageDurationKey,
                             ZMMessageChildMessagesKey,
                             ZMMessageParentMessageKey,
                             ZMMessageRepliesKey,
                             ZMMessageQuoteKey,
                             ZMSystemMessageMessageTimerKey,
                             ZMSystemMessageRelevantForConversationStatusKey,
                             ZMSystemMessageAllTeamUsersAddedKey,
                             ZMSystemMessageNumberOfGuestsAddedKey,
                             DeliveredKey,
                             ZMMessageExpectReadConfirmationKey,
                             ZMMessageLinkAttachmentsKey,
                             ZMMessageNeedsLinkAttachmentsUpdateKey,
                             ZMMessageDiscoveredClientsKey,
                             ZMMessageButtonStatesKey,
                             ZMMessageDecryptionErrorCodeKey
                             ];
        ignoredKeys = [keys setByAddingObjectsFromArray:newKeys];
    });
    return ignoredKeys;
}

@end



#pragma mark - Text message

@implementation ZMTextMessage

@dynamic text;

+ (NSString *)entityName;
{
    return @"TextMessage";
}

- (NSString *)shortDebugDescription;
{
    return [[super shortDebugDescription] stringByAppendingFormat:@", \'%@\'", self.text];
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent __unused *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext __unused *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult __unused *)prefetchResult
{
    return nil;
}

- (NSString *)messageText
{
    return self.text;
}

- (LinkMetadata *)linkPreview
{
    return nil;
}

- (id<ZMTextMessageData>)textMessageData
{
    return self;
}

- (NSData *)linkPreviewImageData
{
    return nil;
}

- (BOOL)linkPreviewHasImage
{
    return NO;
}

- (NSString *)linkPreviewImageCacheKey
{
    return nil;
}

- (NSArray<Mention *> *)mentions
{
    return @[];
}

- (ZMMessage *)quote
{
    return nil;
}

-(NSSet<ZMMessage *> *)replies
{
    return [NSSet set];
}

-(BOOL)hasQuote
{
    return NO;
}

-(BOOL)isQuotingSelf
{
    return NO;
}

- (void)removeMessageClearingSender:(BOOL)clearingSender
{
    self.text = nil;
    [super removeMessageClearingSender:clearingSender];
}

- (void)fetchLinkPreviewImageDataWithQueue:(dispatch_queue_t)queue completionHandler:(void (^)(NSData *))completionHandler
{
    NOT_USED(queue);
    NOT_USED(completionHandler);
}

- (void)requestLinkPreviewImageDownload
{
    
}

- (void)editText:(NSString *)text mentions:(NSArray<Mention *> *)mentions fetchLinkPreview:(BOOL)fetchLinkPreview
{
    NOT_USED(text);
    NOT_USED(mentions);
    NOT_USED(fetchLinkPreview);
}

@end





# pragma mark - Knock message

@implementation ZMKnockMessage

+ (NSString *)entityName;
{
    return @"KnockMessage";
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent __unused *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext __unused *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult __unused *)prefetchResult
{
    return nil;
}

- (id<ZMKnockMessageData>)knockMessageData
{
    return self;
}

@end



# pragma mark - System message

@implementation ZMSystemMessage

@dynamic text;

+ (NSString *)entityName;
{
    return @"SystemMessage";
}

@dynamic systemMessageType;
@dynamic users;
@dynamic clients;
@dynamic addedUsers;
@dynamic removedUsers;
@dynamic needsUpdatingUsers;
@dynamic duration;
@dynamic childMessages;
@dynamic parentMessage;
@dynamic messageTimer;
@dynamic relevantForConversationStatus;
@dynamic decryptionErrorCode;

- (instancetype)initWithNonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self.class entityName] inManagedObjectContext:managedObjectContext];
    self = [super initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
    
    if (self != nil) {
        self.nonce = nonce;
        self.relevantForConversationStatus = YES; //default value
    }
    
    return self;
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    ZMSystemMessageType type = [self.class systemMessageTypeFromEventType:updateEvent.type];
    if (type == ZMSystemMessageTypeInvalid) {
        return nil;
    }
    
    ZMConversation *conversation = [self conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    
    // Only create connection request system message if conversation type is valid.
    // Note: if type is not connection request, then it relates to group conversations (see first line of this method).
    // We don't explicitly check for group conversation type b/c if this is the first time we were added to the conversation,
    // then the default conversation type is `invalid` (b/c we haven't fetched from BE yet), so we assume BE sent the
    // update event for a group conversation.
    if (conversation.conversationType == ZMConversationTypeConnection && type != ZMSystemMessageTypeConnectionRequest) {
        return nil;
    }
    
    NSString *messageText = [[[updateEvent.payload dictionaryForKey:@"data"] optionalStringForKey:@"message"] stringByRemovingExtremeCombiningCharacters];
    NSString *name = [[[updateEvent.payload dictionaryForKey:@"data"] optionalStringForKey:@"name"] stringByRemovingExtremeCombiningCharacters];

    NSMutableSet *usersSet = [NSMutableSet setWithArray:[self usersFromUpdateEvent:updateEvent context:moc]];
    ZMSystemMessage *message = [[ZMSystemMessage alloc] initWithNonce:NSUUID.UUID managedObjectContext:moc];
    message.systemMessageType = type;
    message.visibleInConversation = conversation;
    message.serverTimestamp = updateEvent.timestamp;
    
    [message updateWithUpdateEvent:updateEvent forConversation:conversation];
    
    if (![usersSet isEqual:[NSSet setWithObject:message.sender]]) {
        [usersSet removeObject:message.sender];
    }
    message.participantsRemovedReason = [self updateEventParticipantsRemovedReason:updateEvent];
    message.users = usersSet;
    message.text = messageText != nil ? messageText : name;
    
    [conversation updateTimestampsAfterUpdatingMessage:message];
    
    return message;
}

- (NSDictionary<NSString *,NSArray<ZMUser *> *> *)usersReaction
{
    return [NSDictionary dictionary];
}

+ (ZMSystemMessage *)fetchLatestPotentialGapSystemMessageInConversation:(ZMConversation *)conversation
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:ZMMessageServerTimestampKey ascending:NO]];
    request.fetchBatchSize = 1;
    request.predicate = [self predicateForPotentialGapSystemMessagesNeedingUpdatingUsersInConversation:conversation];
    NSArray *result = [conversation.managedObjectContext executeFetchRequestOrAssert:request];
    return result.firstObject;
}

+ (NSPredicate *)predicateForPotentialGapSystemMessagesNeedingUpdatingUsersInConversation:(ZMConversation *)conversation
{
    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageConversationKey, conversation];
    NSPredicate *missingMessagesTypePredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageSystemMessageTypeKey, @(ZMSystemMessageTypePotentialGap)];
    NSPredicate *needsUpdatingUsersPredicate = [NSPredicate predicateWithFormat:@"%K == YES", ZMMessageNeedsUpdatingUsersKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[conversationPredicate, missingMessagesTypePredicate, needsUpdatingUsersPredicate]];
}

+ (NSPredicate *)predicateForSystemMessagesInsertedLocally
{
    return [NSPredicate predicateWithBlock:^BOOL(ZMSystemMessage *msg, id ZM_UNUSED bindings) {
        if (![msg isKindOfClass:[ZMSystemMessage class]]){
            return NO;
        }
        switch (msg.systemMessageType) {
            case ZMSystemMessageTypeNewClient:
            case ZMSystemMessageTypePotentialGap:
            case ZMSystemMessageTypeIgnoredClient:
            case ZMSystemMessageTypePerformedCall:
            case ZMSystemMessageTypeUsingNewDevice:
            case ZMSystemMessageTypeDecryptionFailed:
            case ZMSystemMessageTypeDecryptionFailedResolved:
            case ZMSystemMessageTypeReactivatedDevice:
            case ZMSystemMessageTypeConversationIsSecure:
            case ZMSystemMessageTypeMessageDeletedForEveryone:
            case ZMSystemMessageTypeDecryptionFailed_RemoteIdentityChanged:
            case ZMSystemMessageTypeTeamMemberLeave:
            case ZMSystemMessageTypeMissedCall:
            case ZMSystemMessageTypeReadReceiptsEnabled:
            case ZMSystemMessageTypeReadReceiptsDisabled:
            case ZMSystemMessageTypeReadReceiptsOn:
            case ZMSystemMessageTypeLegalHoldEnabled:
            case ZMSystemMessageTypeLegalHoldDisabled:
            case ZMSystemMessageTypeSessionReset:
                
                return YES;
            case ZMSystemMessageTypeInvalid:
            case ZMSystemMessageTypeConversationNameChanged:
            case ZMSystemMessageTypeConnectionRequest:
            case ZMSystemMessageTypeConnectionUpdate:
            case ZMSystemMessageTypeNewConversation:
            case ZMSystemMessageTypeParticipantsAdded:
            case ZMSystemMessageTypeParticipantsRemoved:
            case ZMSystemMessageTypeMessageTimerUpdate:
                return NO;
        }
    }];
}

- (void)updateNeedsUpdatingUsersIfNeeded
{
    if (self.systemMessageType == ZMSystemMessageTypePotentialGap && self.needsUpdatingUsers == YES) {
        BOOL (^matchUnfetchedUserBlock)(ZMUser *) = ^BOOL(ZMUser *user) {
            return user.name == nil;
        };
        
        self.needsUpdatingUsers = [self.addedUsers anyObjectMatchingWithBlock:matchUnfetchedUserBlock] ||
                                  [self.removedUsers anyObjectMatchingWithBlock:matchUnfetchedUserBlock];
    }
}

- (BOOL)isDecryptionErrorRecoverable {
    if (self.decryptionErrorCode == nil) {
        return NO;
    }
    
    NSInteger errorCode = self.decryptionErrorCode.integerValue;
    
    if (errorCode == CBOX_TOO_DISTANT_FUTURE ||
        errorCode == CBOX_DEGENERATED_KEY ||
        errorCode == CBOX_PREKEY_NOT_FOUND) {
        return YES;
    }
    
    return NO;
}

+ (ZMSystemMessageType)systemMessageTypeFromEventType:(ZMUpdateEventType)type
{
    NSNumber *number = self.eventTypeToSystemMessageTypeMap[@(type)];
    if(number == nil) {
        return ZMSystemMessageTypeInvalid;
    }
    else {
        return (ZMSystemMessageType) number.integerValue;
    }
}

+ (BOOL)doesEventTypeGenerateSystemMessage:(ZMUpdateEventType)type;
{
    return [self.eventTypeToSystemMessageTypeMap.allKeys containsObject:@(type)];
}

+ (NSDictionary *)eventTypeToSystemMessageTypeMap   
{
    return @{
             @(ZMUpdateEventTypeConversationMemberJoin) : @(ZMSystemMessageTypeParticipantsAdded),
             @(ZMUpdateEventTypeConversationMemberLeave) : @(ZMSystemMessageTypeParticipantsRemoved),
             @(ZMUpdateEventTypeConversationRename) : @(ZMSystemMessageTypeConversationNameChanged)
             };
}

- (id<ZMSystemMessageData>)systemMessageData
{
    return self;
}

- (BOOL)shouldGenerateUnreadCount;
{
    switch (self.systemMessageType) {
        case ZMSystemMessageTypeParticipantsRemoved:
        case ZMSystemMessageTypeParticipantsAdded:
        {
            ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
            return [self.users containsObject:selfUser] && !self.sender.isSelfUser;
        }
        case ZMSystemMessageTypeNewConversation:
            return !self.sender.isSelfUser;
        case ZMSystemMessageTypeMissedCall:
            return self.relevantForConversationStatus;
        default:
            return NO;
    }
}

- (BOOL)userIsTheSender
{
    BOOL onlyOneUser = self.users.count == 1;
    BOOL isSender = [self.users containsObject:self.sender];
    return onlyOneUser && isSender;
}

- (void)updateQuoteRelationships
{
    // System messages don't support quotes at the moment
}

-(NSSet <id<UserType>>*)userTypes
{
    return [self users];
}

-(NSSet <id<UserType>>*)addedUserTypes
{
    return [self addedUsers];
}

-(NSSet <id<UserType>>*)removedUserTypes
{
    return [self removedUsers];
}

@end




@implementation ZMMessage (Ephemeral)


- (BOOL)startDestructionIfNeeded
{
    if (self.destructionDate != nil || !self.isEphemeral) {
        return NO;
    }
    BOOL isSelfUser = self.sender.isSelfUser;
    if (isSelfUser && self.managedObjectContext.zm_isSyncContext) {
        self.destructionDate = [NSDate dateWithTimeIntervalSinceNow:self.deletionTimeout];
        ZMMessageDestructionTimer *timer = self.managedObjectContext.zm_messageObfuscationTimer;
        if (timer != nil) { 
            [timer startObfuscationTimerWithMessage:self timeout:self.deletionTimeout];
            return YES;
        } else {
            return NO;
        }
    }
    else if (!isSelfUser && self.managedObjectContext.zm_isUserInterfaceContext){
        ZMMessageDestructionTimer *timer = self.managedObjectContext.zm_messageDeletionTimer;
        if (timer != nil) { 
            NSTimeInterval matchedTimeInterval = [timer startDeletionTimerWithMessage:self timeout:self.deletionTimeout];
            self.destructionDate = [NSDate dateWithTimeIntervalSinceNow:matchedTimeInterval];
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

- (void)obfuscate;
{
    ZMLogDebug(@"obfuscating message %@", self.nonce.transportString);
    self.isObfuscated = YES;
    self.destructionDate = nil;
}

- (void)deleteEphemeral;
{
    ZMLogDebug(@"deleting ephemeral %@", self.nonce.transportString);
    if (self.conversation.conversationType != ZMConversationTypeGroup) {
        self.destructionDate = nil;
    }
    [ZMMessage deleteForEveryone:self];
    self.isObfuscated = NO;
}

+ (NSFetchRequest *)fetchRequestForEphemeralMessagesThatNeedToBeDeleted
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K != nil AND %K != nil AND %K == FALSE",
                              ZMMessageDestructionDateKey,          // If it has a destructionDate, the timer did not fire in time
                              ZMMessageSenderKey,                   // As soon as the message is deleted, we would delete the sender
                              ZMMessageIsObfuscatedKey];            // If the message is obfuscated, we don't need to obfuscate it again
    
    // We add a sort descriptor to force core data to scan the table using the destructionDate index.
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:ZMMessageDestructionDateKey ascending:NO]];
    return fetchRequest;
}

+ (void)deleteOldEphemeralMessages:(NSManagedObjectContext *)context
{
    ZMLogDebug(@"deleting old ephemeral messages");
    NSFetchRequest *request = [self fetchRequestForEphemeralMessagesThatNeedToBeDeleted];
    NSArray *messages = [context executeFetchRequestOrAssert:request];

    for (ZMMessage *message in messages) {
        NSTimeInterval timeToDeletion = [message.destructionDate timeIntervalSinceNow];
        if (timeToDeletion > 0) {
            // The timer has not run out yet, we want to start a timer with the remaining time
            if (message.sender.isSelfUser) {
                [message restartObfuscationTimer:timeToDeletion];
            } else {
                [message restartDeletionTimer:timeToDeletion];
            }
        } else {
            // The timer has run out, we want to delete the message or obfuscate if we are the sender
            if (message.sender.isSelfUser) {
                // message needs to be obfuscated
                [message obfuscate];
            } else {
                [message deleteEphemeral];
            }
        }
    }
}

- (void)restartDeletionTimer:(NSTimeInterval)remainingTime
{
    NSManagedObjectContext *uiContext = self.managedObjectContext;
    if (!uiContext.zm_isUserInterfaceContext) {
        uiContext = self.managedObjectContext.zm_userInterfaceContext;
    }
    [uiContext performGroupedBlock:^{
        NSError *error;
        ZMMessage *message = [uiContext existingObjectWithID:self.objectID error:&error];
        if (error == nil && message != nil) {
            [uiContext.zm_messageDeletionTimer stopTimerForMessage:message];
            NOT_USED([uiContext.zm_messageDeletionTimer startDeletionTimerWithMessage:message timeout:remainingTime]);
        }
    }];
}

- (void)restartObfuscationTimer:(NSTimeInterval)remainingTime
{
    NSManagedObjectContext *syncContext = self.managedObjectContext;
    if (!syncContext.zm_isSyncContext) {
        syncContext = self.managedObjectContext.zm_syncContext;
    }
    [syncContext performGroupedBlock:^{
        NSError *error;
        ZMMessage *message = [syncContext existingObjectWithID:self.objectID error:&error];
        if (error == nil && message != nil) {
            [syncContext.zm_messageObfuscationTimer stopTimerForMessage:message];
            NOT_USED([syncContext.zm_messageObfuscationTimer startObfuscationTimerWithMessage:message timeout:remainingTime]);
        }
    }];
}

@end

