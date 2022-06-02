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


@import WireImages;
@import WireProtos;
@import WireTransport;

#import "ZMMessage.h"
#import "ZMManagedObject+Internal.h"
#import "ZMFetchRequestBatch.h"

@class ZMUser;
@class Reaction;
@class ZMConversation;
@class ZMUpdateEvent;
@class ZMMessageConfirmation;
@class ZMReaction;
@class ZMClientMessage;

@protocol UserClientType;

extern NSString * _Nonnull const ZMMessageIsExpiredKey;
extern NSString * _Nonnull const ZMMessageMissingRecipientsKey;
extern NSString * _Nonnull const ZMMessageImageTypeKey;
extern NSString * _Nonnull const ZMMessageIsAnimatedGifKey;
extern NSString * _Nonnull const ZMMessageMediumRemoteIdentifierDataKey;
extern NSString * _Nonnull const ZMMessageMediumRemoteIdentifierKey;
extern NSString * _Nonnull const ZMMessageOriginalDataProcessedKey;
extern NSString * _Nonnull const ZMMessageOriginalSizeDataKey;
extern NSString * _Nonnull const ZMMessageOriginalSizeKey;
extern NSString * _Nonnull const ZMMessageConversationKey;
extern NSString * _Nonnull const ZMMessageHiddenInConversationKey;
extern NSString * _Nonnull const ZMMessageExpirationDateKey;
extern NSString * _Nonnull const ZMMessageNameKey;
extern NSString * _Nonnull const ZMMessageSenderClientIDKey;
extern NSString * _Nonnull const ZMMessageNeedsToBeUpdatedFromBackendKey;
extern NSString * _Nonnull const ZMMessageNonceDataKey;
extern NSString * _Nonnull const ZMMessageSenderKey;
extern NSString * _Nonnull const ZMMessageSystemMessageTypeKey;
extern NSString * _Nonnull const ZMMessageTextKey;
extern NSString * _Nonnull const ZMMessageUserIDsKey;
extern NSString * _Nonnull const ZMMessageUsersKey;
extern NSString * _Nonnull const ZMMessageClientsKey;
extern NSString * _Nonnull const ZMMessageConfirmationKey;
extern NSString * _Nonnull const ZMMessageCachedCategoryKey;
extern NSString * _Nonnull const ZMMessageSystemMessageClientsKey;
extern NSString * _Nonnull const ZMMessageDeliveryStateKey;
extern NSString * _Nonnull const ZMMessageRepliesKey;
extern NSString * _Nonnull const ZMMessageQuoteKey;
extern NSString * _Nonnull const ZMMessageConfirmationKey;
extern NSString * _Nonnull const ZMMessageLinkAttachmentsKey;
extern NSString * _Nonnull const ZMMessageNeedsLinkAttachmentsUpdateKey;

@interface ZMMessage : ZMManagedObject

+(instancetype _Nonnull )insertNewObjectInManagedObjectContext:(NSManagedObjectContext *_Nonnull)moc NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithNonce:(NSUUID * _Nonnull)nonce managedObjectContext:(NSManagedObjectContext * _Nonnull)managedObjectContext;
+ (nonnull NSSet <ZMMessage *> *)messagesWithRemoteIDs:(nonnull NSSet <NSUUID *>*)UUIDs inContext:(nonnull NSManagedObjectContext *)moc;

// Use these for sorting:
+ (NSArray<NSSortDescriptor *> * _Nonnull)defaultSortDescriptors;
- (NSComparisonResult)compare:(ZMMessage * _Nonnull)other;
- (void)updateWithPostPayload:(NSDictionary * _Nonnull)payload updatedKeys:(__unused NSSet * _Nullable)updatedKeys;
- (void)resend;
- (BOOL)shouldGenerateUnreadCount;

@property (nonatomic) BOOL delivered;

/// Removes the message and deletes associated content
/// @param clearingSender Whether information about the sender should be removed or not
- (void)removeMessageClearingSender:(BOOL)clearingSender;

+ (void)stopDeletionTimerForMessage:(ZMMessage * _Nonnull)message;

@end



@interface ZMTextMessage : ZMMessage <ZMTextMessageData>

@property (nonatomic, readonly, copy) NSString * _Nullable text;

@end



@interface ZMImageMessage : ZMMessage <ZMImageMessageData>

@property (nonatomic, readonly) BOOL mediumDataLoaded;
@property (nonatomic, readonly) BOOL originalDataProcessed;
@property (nonatomic, readonly) NSData * _Nullable mediumData; ///< N.B.: Will go away from public header
@property (nonatomic, readonly) NSData * _Nullable imageData; ///< This will either returns the mediumData or the original image data. Usefull only for newly inserted messages.
@property (nonatomic, readonly) NSString * _Nullable imageDataIdentifier; /// This can be used as a cache key for @c -imageData

@property (nonatomic, readonly) NSData * _Nullable previewData;
@property (nonatomic, readonly) NSString * _Nullable imagePreviewDataIdentifier; /// This can be used as a cache key for @c -previewData
@property (nonatomic, readonly) BOOL isAnimatedGIF; // If it is GIF and has more than 1 frame
@property (nonatomic, readonly) NSString * _Nullable imageType; // UTI e.g. kUTTypeGIF

@property (nonatomic, readonly) CGSize originalSize;

@end  



@interface ZMKnockMessage : ZMMessage <ZMKnockMessageData>

@end



@interface ZMSystemMessage : ZMMessage <ZMSystemMessageData>

@property (nonatomic) ZMSystemMessageType systemMessageType;
@property (nonatomic) NSSet<ZMUser *> * _Nonnull users;
@property (nonatomic) NSSet <id<UserClientType>>* _Nonnull clients;
@property (nonatomic) NSSet<ZMUser *> * _Nonnull addedUsers; // Only filled for ZMSystemMessageTypePotentialGap and ZMSystemMessageTypeIgnoredClient
@property (nonatomic) NSSet<ZMUser *> * _Nonnull removedUsers; // Only filled for ZMSystemMessageTypePotentialGap
@property (nonatomic, copy) NSString * _Nullable text;
@property (nonatomic) BOOL needsUpdatingUsers;

@property (nonatomic) NSTimeInterval duration; // Only filled for .performedCall
@property (nonatomic) id <ZMSystemMessageData> _Nullable parentMessage; // Only filled for .performedCall & .missedCall

@property (nonatomic, readonly) BOOL userIsTheSender; // Set to true if sender is the only user in users array. E.g. when a wireless user joins conversation
@property (nonatomic) NSNumber * _Nullable messageTimer; // Only filled for .messageTimerUpdate
@property (nonatomic) BOOL relevantForConversationStatus; // If true (default), the message is considered to be shown inside the conversation list
@property (nonatomic) NSNumber * _Nullable decryptionErrorCode; // If available this will be set for decryption error messages.
+ (ZMSystemMessage * _Nullable)fetchLatestPotentialGapSystemMessageInConversation:(ZMConversation * _Nonnull)conversation;
- (void)updateNeedsUpdatingUsersIfNeeded;

@end



@interface ZMMessage ()

@property (nonatomic) NSString * _Nullable senderClientID;
@property (nonatomic) NSUUID * _Nullable nonce;
@property (nonatomic, readonly) NSDate * _Nullable destructionDate;

@property (nonatomic, readonly) BOOL isUnreadMessage;
@property (nonatomic, readonly) BOOL isExpired;
@property (nonatomic, readonly) NSDate * _Nullable expirationDate;
@property (nonatomic, readonly) BOOL isObfuscated;
@property (nonatomic, readonly) BOOL needsReadConfirmation;
@property (nonatomic) NSString * _Nullable normalizedText;

@property (nonatomic) NSSet <Reaction *> * _Nonnull reactions;
@property (nonatomic, readonly) NSSet<ZMMessageConfirmation*> * _Nonnull confirmations;

- (void)setExpirationDate;
- (void)removeExpirationDate;
- (void)expire;

/// Sets a flag to mark the message as being delivered to the backend
- (void)markAsSent;

+ (instancetype _Nullable)fetchMessageWithNonce:(NSUUID * _Nullable)nonce
                      forConversation:(ZMConversation * _Nonnull)conversation
               inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;

+ (instancetype _Nullable)fetchMessageWithNonce:(NSUUID * _Nonnull)nonce
                      forConversation:(ZMConversation * _Nonnull)conversation
               inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc
                       prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult;

+ (instancetype _Nullable)fetchMessageWithNonce:(NSUUID * _Nonnull)nonce
                                forConversation:(ZMConversation * _Nonnull)conversation
                         inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc
                                 prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult
                   assumeMissingIfNotPrefetched:(BOOL)assumeMissingIfNotPrefetched;

- (NSString * _Nonnull)shortDebugDescription;

- (void)updateWithPostPayload:(NSDictionary * _Nonnull)payload updatedKeys:(NSSet * _Nonnull)updatedKeys;
+ (BOOL)doesEventTypeGenerateMessage:(ZMUpdateEventType)type;

/// Returns a predicate that matches messages that might expire if they are not sent in time
+ (NSPredicate * _Nonnull)predicateForMessagesThatWillExpire;


+ (void)setDefaultExpirationTime:(NSTimeInterval)defaultExpiration;
+ (NSTimeInterval)defaultExpirationTime;
+ (void)resetDefaultExpirationTime;

+ (ZMConversation * _Nullable)conversationForUpdateEvent:(ZMUpdateEvent * _Nonnull)event inContext:(NSManagedObjectContext * _Nonnull)moc prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult;

/// Returns the message represented in this update event
/// @param prefetchResult Contains a mapping from message nonce to message and `remoteIdentifier` to `ZMConversation`,
/// which should be used to avoid premature fetchRequests. If the class needs messages or conversations to be prefetched
/// and passed into this method it should conform to `ZMObjectStrategy` and return them in
/// `-messageNoncesToPrefetchToProcessEvents:` or `-conversationRemoteIdentifiersToPrefetchToProcessEvents`
+ (instancetype _Nullable)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc
                                      prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult;

- (void)updateWithUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent forConversation:(ZMConversation * _Nonnull)conversation;

/// Predicate to select messages that are part of a conversation
+ (NSPredicate * _Nonnull)predicateForMessageInConversation:(ZMConversation * _Nonnull)conversation withNonces:(NSSet <NSUUID *>*  _Nonnull)nonces;

/// Predicate to select messages whose link attachments need to be updated.
+ (NSPredicate * _Nonnull)predicateForMessagesThatNeedToUpdateLinkAttachments;

@end



@interface ZMTextMessage (Internal)

@property (nonatomic, copy) NSString * _Nullable text;

@end



extern NSString *  _Nonnull const ZMImageMessagePreviewNeedsToBeUploadedKey;
extern NSString *  _Nonnull const ZMImageMessageMediumNeedsToBeUploadedKey;
extern NSString *  _Nonnull const ZMMessageServerTimestampKey;

@interface ZMImageMessage (Internal) <ZMImageOwner>

@property (nonatomic) BOOL mediumDataLoaded;
@property (nonatomic) BOOL originalDataProcessed;
@property (nonatomic) NSUUID * _Nullable mediumRemoteIdentifier;
@property (nonatomic) NSData * _Nullable mediumData;
@property (nonatomic) NSData * _Nullable  previewData;
@property (nonatomic) CGSize originalSize;
@property (nonatomic) NSData * _Nullable originalImageData;

- (NSData * _Nullable)imageDataForFormat:(ZMImageFormat)format;

@end



@interface ZMKnockMessage (Internal)

@end


@interface ZMSystemMessage (Internal)

+ (BOOL)doesEventTypeGenerateSystemMessage:(ZMUpdateEventType)type;
+ (instancetype _Nullable)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;
+ (NSPredicate * _Nonnull)predicateForSystemMessagesInsertedLocally;

@end




@interface ZMMessage (Ephemeral)


/// Sets the destruction date to the current date plus the timeout
/// After this date the message "self-destructs", e.g. gets deleted from all sender & receiver devices or obfuscated if the sender is the selfUser
- (BOOL)startDestructionIfNeeded;

/// Obfuscates the message which means, it deletes the genericMessage content
- (void)obfuscate;

/// Inserts a delete message for the ephemeral and sets the destruction timeout to nil
- (void)deleteEphemeral;

/// Restarts the deletion timer with the given time interval. If a timer already
/// exists, it will be stopped first.
- (void)restartDeletionTimer:(NSTimeInterval)remainingTime;

/// Restarts the deletion timer with the given time interval. If a timer already
/// exists, it will be stopped first.
- (void)restartObfuscationTimer:(NSTimeInterval)remainingTime;

/// When we restart, we might still have messages that had a timer, but whose timer did not fire before killing the app
/// To delete those messages immediately use this method on startup (e.g. in the init of the ZMClientMessageTranscoder) to fetch and delete those messages
+ (void)deleteOldEphemeralMessages:(NSManagedObjectContext * _Nonnull)context;

@end

