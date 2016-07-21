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


@import ZMCSystem;
@import ZMUtilities;
@import ZMTransport;
@import ZMProtos;
@import CoreGraphics;
@import ImageIO;
@import MobileCoreServices;
@import Cryptobox;

#import "ZMClientMessage.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Transport.h"
#import "ZMUpdateEvent+ZMCDataModel.h"
#import "ZMGenericMessage+UpdateEvent.h"

#import "ZMGenericMessageData.h"
#import "ZMUser+Internal.h"
#import "ZMOTRMessage.h"
#import "ZMGenericMessage+External.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>

static NSString * const ClientMessageDataSetKey = @"dataSet";
static NSString * const ClientMessageGenericMessageKey = @"genericMessage";

NSString * const ZMFailedToCreateEncryptedMessagePayloadString = @"💣";
// From https://github.com/wearezeta/generic-message-proto:
// "If payload is smaller then 256KB then OM can be sent directly"
// Just to be sure we set the limit lower, to 128KB (base 10)
NSUInteger const ZMClientMessageByteSizeExternalThreshold = 128000;

@interface ZMClientMessage()

@property (nonatomic) ZMGenericMessage *genericMessage;

@end

@interface ZMClientMessage (ZMKnockMessageData) <ZMKnockMessageData>

@end

@interface ZMClientMessage (ZMLocationMessageData) <ZMLocationMessageData>

@end

@implementation ZMClientMessage

@synthesize genericMessage = _genericMessage;

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.nonce = nil;
}

+ (NSString *)entityName;
{
    return @"ClientMessage";
}

- (void)addData:(NSData *)data
{
    if (data == nil) {
        return;
    }
    
    ZMGenericMessageData *messageData = [NSEntityDescription insertNewObjectForEntityForName:[ZMGenericMessageData entityName] inManagedObjectContext:self.managedObjectContext];
    messageData.data = data;
    messageData.message = self;
    [self setGenericMessage:messageData.genericMessage];
    
    if (self.nonce == nil) {
        self.nonce = [NSUUID uuidWithTransportString:messageData.genericMessage.messageId];
    }
    
    [self setLocallyModifiedKeys:[NSSet setWithObject:ClientMessageDataSetKey]];
}

- (ZMGenericMessage *)genericMessage
{
    if (_genericMessage == nil) {
        _genericMessage = [self genericMessageFromDataSet] ?: (ZMGenericMessage *)[NSNull null];
    }
    if (_genericMessage == (ZMGenericMessage *)[NSNull null]) {
        return nil;
    }
    return _genericMessage;
}

- (void)setGenericMessage:(ZMGenericMessage *)genericMessage
{
    if ([genericMessage knownMessage] && !genericMessage.hasImage) {
        _genericMessage = genericMessage;
    }
}

- (ZMGenericMessage *)genericMessageFromDataSet
{
    // Later we need to loop through data set and merge it in one generic message somehow
    // for now we just pick the first data that can read
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(ZMGenericMessageData *evaluatedObject, NSDictionary *__unused bindings) {
        ZMGenericMessage *genericMessage = evaluatedObject.genericMessage;
        return [genericMessage knownMessage] && !genericMessage.hasImage;
    }];
    ZMGenericMessageData *messageData = [self.dataSet filteredOrderedSetUsingPredicate:predicate].firstObject;
    return [messageData genericMessage];
}

+ (NSSet *)keyPathsForValuesAffectingGenericMessage
{
    return [NSSet setWithObject:ClientMessageDataSetKey];
}

- (void)updateWithGenericMessage:(ZMGenericMessage *)message updateEvent:(ZMUpdateEvent *__unused)updateEvent
{
    [self addData:message.data];
}

- (NSString *)messageText
{
    if(self.genericMessage.hasText) {
        return self.genericMessage.text.content;
    }
    return nil;
}

- (id<ZMImageMessageData>)imageMessageData
{
    return nil;
}

- (id<ZMKnockMessageData>)knockMessageData
{
    if (self.genericMessage.hasKnock) {
        return self;
    }
    return nil;
}

- (id<ZMFileMessageData>)fileMessageData
{
    return nil;
}

- (id<ZMLocationMessageData>)locationMessageData
{
    if (self.genericMessage.hasLocation) {
        return self;
    }
    return nil;
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(__unused NSSet *)updatedKeys
{
    [super updateWithPostPayload:payload updatedKeys:nil];
    
    NSDate *serverTimestamp = [payload dateForKey:@"time"];
    if (serverTimestamp != nil) {
        self.serverTimestamp = serverTimestamp;
    }
    [self.conversation updateLastReadServerTimeStampIfNeededWithTimeStamp:serverTimestamp andSync:NO];
    [self.conversation resortMessagesWithUpdatedMessage:self];
    [self.conversation updateWithMessage:self timeStamp:serverTimestamp eventID:self.eventID];
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream
{
    NSPredicate *publicNotSynced = [NSPredicate predicateWithFormat:@"%K == NULL && %K == FALSE", ZMMessageEventIDDataKey, ZMMessageIsEncryptedKey];
    NSPredicate *encryptedNotSynced = [NSPredicate predicateWithFormat:@"%K == TRUE && %K == FALSE", ZMMessageIsEncryptedKey, DeliveredKey];
    NSPredicate *notSynced = [NSCompoundPredicate orPredicateWithSubpredicates:@[publicNotSynced, encryptedNotSynced]];
    NSPredicate *notExpired = [NSPredicate predicateWithFormat:@"%K == 0", ZMMessageIsExpiredKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[notSynced, notExpired]];
}

@end



@implementation ZMClientMessage (OTR)

- (NSData *)encryptedMessagePayloadData
{
    return [ZMClientMessage encryptedMessagePayloadDataWithGenericMessage:self.genericMessage
                                                             conversation:self.conversation
                                                     managedObjectContext:self.managedObjectContext
                                                             externalData:nil];
}

+ (NSData *)encryptedMessagePayloadDataWithGenericMessage:(ZMGenericMessage *)genericMessage
                                             conversation:(ZMConversation *)conversation
                                     managedObjectContext:(NSManagedObjectContext *)moc
                                             externalData:(NSData *)externalData
{
    UserClient *selfClient = [ZMUser selfUserInContext:moc].selfClient;
    if (selfClient.remoteIdentifier == nil) {
        return nil;
    }
    
    NSArray <ZMUserEntry *>*recipients = [ZMClientMessage recipientsWithDataToEncrypt:genericMessage.data
                                                                           selfClient:selfClient
                                                                         conversation:conversation];
    ZMNewOtrMessage *message = [ZMNewOtrMessage messageWithSender:selfClient nativePush:YES recipients:recipients blob:externalData];
    
    
    NSData *messageData = message.data;
    if (messageData.length > ZMClientMessageByteSizeExternalThreshold && nil == externalData) {
        
        // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
        // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
        [self rollbackUsersClientsSessionFromConversation:conversation selfClient:selfClient];
        return [self encryptedMessageDataWithExternalDataBlobFromMessage:genericMessage
                                                          inConversation:conversation
                                                    managedObjectContext:moc];
    }
    
    // here we know that the encrypted message(s) are going to be used to send a request, we persist the sessions
    [selfClient.keysStore.box saveSessionsRequiringSave];
    return messageData;
}

+ (NSArray <ZMUserEntry *>*)recipientsWithDataToEncrypt:(NSData *)dataToEncrypt selfClient:(UserClient *)selfClient conversation:(ZMConversation *)conversation;
{
    CBCryptoBox *box = selfClient.keysStore.box;
    
    NSArray <ZMUserEntry *>*recipients = [conversation.activeParticipants.array mapWithBlock:^ZMUserEntry *(ZMUser *user) {
        NSArray <ZMClientEntry *>*clientsEntries = [user.clients.allObjects mapWithBlock:^ZMClientEntry *(UserClient *client) {
            
            NSError *error;
            if (![client.remoteIdentifier isEqual:selfClient.remoteIdentifier]) {
                CBSession *session = [box sessionById:client.remoteIdentifier error:&error];
                
                // We do not have a session and will insert bogus data for this client
                // in order to show him a "failed to decrypt" message
                BOOL corruptedClient = client.failedToEstablishSession;
                client.failedToEstablishSession = NO;
                
                if (nil == session) {
                    if(corruptedClient) {
                        NSData *data = [ZMFailedToCreateEncryptedMessagePayloadString dataUsingEncoding:NSUTF8StringEncoding];
                        return [ZMClientEntry entryWithClient:client data:data];
                    } else {
                        return nil;
                    }
                }
                
                NSData *encryptedData = [session encrypt:dataToEncrypt error:&error];
                if (encryptedData != nil) {
                    [box setSessionToRequireSave:session];
                    return [ZMClientEntry entryWithClient:client data:encryptedData];
                } else {
                    // We failed to encrypt the data using that session, which is not normal.
                    // We rollback the session to the last serialised state
                    [box rollbackSession:session];
                }
            }

            return nil;
        }];
        
        if (clientsEntries.count == 0) {
            return nil;
        }
        
        return [ZMUserEntry entryWithUser:user clientEntries:clientsEntries];
    }];

    return recipients;
}

+ (void)rollbackUsersClientsSessionFromConversation:(ZMConversation *)conversation selfClient:(UserClient *)selfClient;
{
    CBCryptoBox *box = selfClient.keysStore.box;
    for (ZMUser *user in conversation.activeParticipants) {
        for (UserClient *client in user.clients) {
            if (![client.remoteIdentifier isEqual:selfClient.remoteIdentifier]) {

                NSError *error;
                CBSession *session = [box sessionById:client.remoteIdentifier error:&error];
                
                BOOL corruptedClient = client.failedToEstablishSession;
                client.failedToEstablishSession = NO;
                
                if (nil != session && !corruptedClient) {
                    [box rollbackSession:session];
                }
            }
        }
    }
}

@end



@implementation ZMClientMessage (External)


+ (NSData *)encryptedMessageDataWithExternalDataBlobFromMessage:(ZMGenericMessage *)message
                                                 inConversation:(ZMConversation *)conversation
                                           managedObjectContext:(NSManagedObjectContext *)context
{
    ZMExternalEncryptedDataWithKeys *encryptedDataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:message];
    ZMGenericMessage *externalGenericMessage = [ZMGenericMessage genericMessageWithKeyWithChecksum:encryptedDataWithKeys.keys
                                                                                         messageID:NSUUID.UUID.transportString];
    
    return [self encryptedMessagePayloadDataWithGenericMessage:externalGenericMessage
                                                  conversation:conversation
                                          managedObjectContext:context
                                                  externalData:encryptedDataWithKeys.data];
}

@end



@implementation ZMClientMessage (ZMKnockMessage)

@end

#pragma mark - ZMLocationMessageData

@implementation ZMClientMessage (ZMLocationMessageData)

- (float)latitude
{
    return self.genericMessage.location.latitude;
}

- (float)longitude
{
    return self.genericMessage.location.longitude;
}

- (NSString *)name
{
    if (self.genericMessage.location.hasName) {
        return self.genericMessage.location.name;
    }
    
    return nil;
}

- (int32_t)zoomLevel
{
    if (self.genericMessage.location.hasZoom) {
        return self.genericMessage.location.zoom;
    }
    
    return 0;
}

@end

