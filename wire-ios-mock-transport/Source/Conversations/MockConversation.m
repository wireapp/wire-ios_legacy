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
@import WireUtilities;
@import WireCryptobox;

#import "MockConversation.h"
#import "MockEvent.h"
#import "MockAsset.h"
#import <WireMockTransport/WireMockTransport-Swift.h>


@interface MockConversation ()

@property (nonatomic, readonly) NSMutableOrderedSet *mutableActiveUsers;

@end


@implementation MockConversation

@dynamic creator;
@dynamic identifier;
@dynamic selfIdentifier;
@dynamic selfRole;
@dynamic name;
@dynamic type;
@dynamic activeUsers;
@dynamic events;
@dynamic otrArchived;
@dynamic otrArchivedRef;
@dynamic otrMuted;
@dynamic otrMutedRef;
@dynamic otrMutedStatus;
@dynamic team;
@dynamic accessRole;
@dynamic accessRoleV2;
@dynamic guestLinkFeatureStatus;
@dynamic accessMode;
@dynamic link;
@dynamic receiptMode;
@dynamic nonTeamRoles;
@dynamic participantRoles;

+ (instancetype)insertConversationIntoContext:(NSManagedObjectContext *)moc withSelfUser:(MockUser *)selfUser creator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)type
{
    NSAssert(selfUser.identifier, @"The self user needs to have an identifier for this to work.");
    MockConversation *conversation = (id) [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:moc];
    conversation.selfIdentifier = selfUser.identifier;
    conversation.type = type;
    NSMutableOrderedSet *addedUsers = [NSMutableOrderedSet orderedSetWithArray:otherUsers];
    [addedUsers insertObject:creator atIndex:0];
    [conversation addUsersByUser:creator addedUsers:addedUsers.array];
    conversation.identifier = [NSUUID createUUID].transportString;
    conversation.creator = creator;
    conversation.accessMode = [MockConversation defaultAccessModeWithConversationType:type team:nil];
    conversation.accessRole = [MockConversation defaultAccessRoleWithConversationType:type team:nil];
    conversation.accessRoleV2 = [MockConversation defaultAccessRoleV2WithConversationType:type team:nil];
    [conversation.mutableActiveUsers addObject:creator];
    return conversation;
}

+ (instancetype)insertConversationIntoContext:(NSManagedObjectContext *)moc creator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)type
{
    MockConversation *conversation = (id) [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:moc];
    conversation.type = type;
    NSMutableOrderedSet *addedUsers = [NSMutableOrderedSet orderedSetWithArray:otherUsers];
    [addedUsers insertObject:creator atIndex:0];
    [conversation addUsersByUser:creator addedUsers:addedUsers.array];
    conversation.identifier = [NSUUID createUUID].transportString;
    conversation.creator = creator;
    [conversation.mutableActiveUsers addObject:creator];
    conversation.accessMode = [MockConversation defaultAccessModeWithConversationType:type team:nil];
    conversation.accessRole = [MockConversation defaultAccessRoleWithConversationType:type team:nil];
    conversation.accessRoleV2 = [MockConversation defaultAccessRoleV2WithConversationType:type team:nil];
    return conversation;
}

+ (instancetype)conversationInMoc:(NSManagedObjectContext *)moc withCreator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)type
{
    return [self insertConversationIntoContext:moc withSelfUser:creator creator:creator otherUsers:otherUsers type:type];
}

- (MockEvent *)eventIfNeededByUser:(MockUser *)byUser type:(ZMUpdateEventType)type data:(id)data
{
    NSArray *eventTypesWithPushOnInsert = @[@(ZMUpdateEventTypeConversationAssetAdd),
                                            @(ZMUpdateEventTypeConversationMessageAdd),
                                            @(ZMUpdateEventTypeConversationClientMessageAdd),
                                            @(ZMUpdateEventTypeConversationOtrMessageAdd),
                                            @(ZMUpdateEventTypeConversationOtrAssetAdd),
                                            @(ZMUpdateEventTypeConversationCreate),
                                            @(ZMUpdateEventTypeConversationMemberJoin),
                                            @(ZMUpdateEventTypeConversationConnectRequest),
                                            @(ZMUpdateEventTypeConversationKnock),
                                            @(ZMUpdateEventTypeConversationMemberUpdate)];
    

    if(self.isInserted && ![eventTypesWithPushOnInsert containsObject:@(type)]) {
        return nil;
    }
    
    MockEvent *event = (id) [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    
    if ([[MockEvent persistentEvents] containsObject:@(type)]) {
        event.identifier =  [NSString stringWithFormat:@"%llx.aabb", (unsigned long long) self.filteredEvents.count+1];
    }
    event.time = [NSDate date];
    event.conversation = self;
    event.from = byUser;
    event.type = [MockEvent stringFromType:type];
    event.data = data;
    
    if (event.identifier) {
        [self.mutableEvents addObject:event];
    }
    
    return event;
}

- (NSMutableOrderedSet *)mutableActiveUsers;
{
    return [self mutableOrderedSetValueForKey:@"activeUsers"];
}

- (NSMutableOrderedSet *)mutableEvents;
{
    return [self mutableOrderedSetValueForKey:@"events"];
}

- (NSOrderedSet *)filteredEvents {
    return [self.events filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"identifier != NULL"]];
}

- (NSNumber *)transportConversationType;
{
    switch (self.type) {
        case ZMTConversationTypeSelf:
            return @1;
        case ZMTConversationTypeOneOnOne:
            return @2;
        case ZMTConversationTypeGroup:
            return @0;
        case ZMTConversationTypeConnection:
            return @3;
        case ZMTConversationTypeInvalid:
        default:
            Require(NO);
            return nil;
    }
}

- (id<ZMTransportData>)transportData;
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"creator"] = self.creator ? self.creator.identifier: [NSNull null];
    data[@"name"] = self.name ?: [NSNull null];
    data[@"id"] = self.identifier ?: [NSNull null];
    data[@"type"] = self.transportConversationType;
    data[@"access"] = self.accessMode;
    data[@"access_role"] = self.accessRole;
    data[@"access_role_v2"] = self.accessRoleV2;
    data[@"team"] = self.team.identifier ?: [NSNull null];
    
    if (self.receiptMode != nil) {
        data[@"receipt_mode"] = self.receiptMode;
    }

    NSMutableDictionary *members = [NSMutableDictionary dictionary];
    data[@"members"] = members;
    members[@"self"] = [self selfInfoDictionaryForEvent:NO];
    
    NSMutableArray *others = [NSMutableArray array];
    
    for (MockUser *activeUser in self.activeUsers) {
        if([activeUser.identifier isEqualToString:self.selfIdentifier]) { // self user should not be in others
            continue;
        }
        MockRole *role = [activeUser roleIn:self];
        NSString *roleName = role != nil ? role.name : MockRole.adminRole.name;
        [others addObject:@{ @"id": activeUser.identifier,
                             @"conversation_role": roleName}];
        
    }
    
    members[@"others"] = others;
    return data;
}


- (NSDictionary *)selfInfoDictionaryForEvent:(BOOL)forEvent
{
    NSMutableDictionary *selfInfo = [NSMutableDictionary dictionary];
    if (forEvent) {
        selfInfo[@"target"] = self.selfIdentifier;
    } else {
        selfInfo[@"id"] = self.selfIdentifier;
    }
    selfInfo[@"conversation_role"] = self.selfRole;
    selfInfo[@"otr_muted_ref"] = self.otrMutedRef ?: [NSNull null];
    selfInfo[@"otr_muted"] = @(self.otrMuted);
    selfInfo[@"otr_muted_status"] = self.otrMutedStatus ?: [NSNull null];
    selfInfo[@"otr_archived_ref"] = self.otrArchivedRef ?: [NSNull null];
    selfInfo[@"otr_archived"] = @(self.otrArchived);
    
    return selfInfo;
}


+ (NSFetchRequest *)sortedFetchRequest;
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES];
    request.sortDescriptors = @[sd];
    request.predicate = [NSPredicate predicateWithFormat:@"type != %d", (int) ZMTConversationTypeInvalid];
    return request;
}

+ (NSFetchRequest *)sortedFetchRequestWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [self sortedFetchRequest];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, predicate]];
    return request;
}

- (MockEvent *)insertClientMessageFromUser:(MockUser *)fromUser data:(NSData *)data
{
    return [self eventIfNeededByUser:fromUser type:ZMUpdateEventTypeConversationClientMessageAdd data:[data base64EncodedStringWithOptions:0]];
}


- (MockEvent *)insertOTRMessageFromClient:(MockUserClient *)fromClient
                                 toClient:(MockUserClient *)toClient
                                     data:(NSData *)data;
{
    Require(fromClient.identifier != nil);
    Require(toClient.identifier != nil);
    Require(data != nil);
    NSDictionary *eventData = @{
                                @"sender": fromClient.identifier,
                                @"recipient": toClient.identifier,
                                @"text": [data base64EncodedStringWithOptions:0]
                                };
    return [self eventIfNeededByUser:fromClient.user type:ZMUpdateEventTypeConversationOtrMessageAdd data:eventData];
}

- (MockEvent *)encryptAndInsertDataFromClient:(MockUserClient *)fromClient
                                     toClient:(MockUserClient *)toClient
                                         data:(NSData *)data;
{
    Require(fromClient.identifier != nil);
    Require(toClient.identifier != nil);
    Require(data != nil);
    NSData *encrypted = [MockUserClient encryptedWithData:data from:fromClient to:toClient];
    return [self insertOTRMessageFromClient:fromClient toClient:toClient data:encrypted];
}

- (MockEvent *)insertOTRAssetFromClient:(MockUserClient *)fromClient
                               toClient:(MockUserClient *)toClient
                               metaData:(NSData *)metaData
                              imageData:(NSData *)imageData
                                assetId:(NSUUID *)assetId
                               isInline:(BOOL)isInline
{
    Require(fromClient.identifier != nil);
    Require(toClient.identifier != nil);
    Require(assetId != nil);
    Require(metaData != nil);
    NSDictionary *eventData = @{
                                @"sender": fromClient.identifier,
                                @"recipient": toClient.identifier,
                                @"id": assetId.transportString,
                                @"key": [metaData base64EncodedStringWithOptions:0],
                                @"data": imageData != nil && isInline ? [imageData base64EncodedStringWithOptions:0] : [NSNull null]
                                };
    return [self eventIfNeededByUser:fromClient.user type:ZMUpdateEventTypeConversationOtrAssetAdd data:eventData];
}

- (MockEvent *)remotelyArchiveFromUser:(MockUser *)fromUser referenceDate:(NSDate *)referenceDate
{
    self.otrArchivedRef = referenceDate.transportString;
    self.otrArchived = YES;
    return [self eventIfNeededByUser:fromUser type:ZMUpdateEventTypeConversationMemberUpdate data:(id<ZMTransportData>)[self selfInfoDictionaryForEvent:YES]];
}

- (MockEvent *)remotelyClearHistoryFromUser:(MockUser *)fromUser referenceDate:(NSDate *)referenceDate
{
    self.otrArchivedRef = referenceDate.transportString;
    self.otrArchived = YES;
    return [self eventIfNeededByUser:fromUser type:ZMUpdateEventTypeConversationMemberUpdate data:(id<ZMTransportData>)[self selfInfoDictionaryForEvent:YES]];
}

- (MockEvent *)remotelyDeleteFromUser:(MockUser *)fromUser referenceDate:(NSDate *)referenceDate
{
    return [self remotelyClearHistoryFromUser:fromUser referenceDate:referenceDate];
}

- (MockEvent *)insertKnockFromUser:(MockUser *)fromUser nonce:(NSUUID *)nonce;
{
    return [self eventIfNeededByUser:fromUser type:ZMUpdateEventTypeConversationKnock data:@{@"nonce": nonce.transportString}];
}

- (void)insertImageEventsFromUser:(MockUser *)fromUser;
{
    NSUUID *correlationID = [NSUUID createUUID];
    NSUUID *nonce = [NSUUID createUUID];
    
    [self insertPreviewImageEventFromUser:fromUser correlationID:correlationID none:nonce];
    [self insertMediumImageEventFromUser:fromUser correlationID:correlationID none:nonce];
}

- (MockEvent *)insertTypingEventFromUser:(MockUser *)fromUser isTyping:(BOOL)isTyping
{
    NSDictionary *data = @{@"status": isTyping ? @"started" : @"stopped"};
    
    return [self eventIfNeededByUser:fromUser type:ZMUpdateEventTypeConversationTyping data:data];
}


- (void)insertPreviewImageEventFromUser:(MockUser *)fromUser correlationID:(NSUUID *)correlationID none:(NSUUID *)nonce
{
    NSData *previewImageData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"tiny"withExtension:@"jpg"]];
    Require(previewImageData);
    Require(correlationID);
    Require(nonce);
    
    NSDictionary *previewInfo = @{
                                  @"correlation_id": correlationID.transportString,
                                  @"height": @29,
                                  @"width": @38,
                                  @"name": [NSNull null],
                                  @"nonce": nonce.transportString,
                                  @"original_height": @768,
                                  @"original_width": @1024,
                                  @"public": @NO,
                                  @"tag": @"preview",
                                  @"inline": @YES
                                  };
    
    
    [self insertAssetUploadEventForUser:fromUser data:previewImageData disposition:previewInfo dataTypeAsMIME:@"image/jpeg" assetID:[NSUUID createUUID].transportString];
}

- (void)insertMediumImageEventFromUser:(MockUser *)fromUser correlationID:(NSUUID *)correlationID none:(NSUUID *)nonce
{
    NSData *mediumImageData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"medium"withExtension:@"jpg"]];
    Require(mediumImageData);
    Require(correlationID);
    Require(nonce);
    
    NSDictionary *mediumInfo = @{
                                 @"correlation_id": correlationID.transportString,
                                 @"height": @432,
                                 @"width": @543,
                                 @"name": [NSNull null],
                                 @"nonce": nonce.transportString,
                                 @"original_height": @768,
                                 @"original_width": @1024,
                                 @"public": @NO,
                                 @"tag": @"medium",
                                 };
    NSString *assetID = [NSUUID createUUID].transportString;
    
    MockAsset *asset = [MockAsset insertIntoManagedObjectContext:self.managedObjectContext];
    asset.identifier = assetID;
    asset.conversation = self.identifier;
    asset.data = mediumImageData;
    
    [self insertAssetUploadEventForUser:fromUser data:mediumImageData disposition:mediumInfo dataTypeAsMIME:@"image/jpeg" assetID:asset.identifier];
}

- (MockEvent *)addUsersByUser:(MockUser *)byUser addedUsers:(NSArray *)addedUsers;
{
    if (addedUsers.count < 1) {
        return nil;
    }
    for(MockUser *user in addedUsers) {
        [self.mutableActiveUsers addObject:user];
    }
    NSDictionary *data = @{
                       @"user_ids" : [addedUsers mapWithBlock:^NSString *(MockUser *obj) {
                           return [obj identifier];
                       }],
                       };
    return [self eventIfNeededByUser:byUser type:ZMUpdateEventTypeConversationMemberJoin data:data];
}

- (MockEvent *)connectRequestByUser:(MockUser *)byUser toUser:(MockUser *)user message:(NSString *)message
{
    NSDictionary *data = @{
                           @"email" : [NSNull null],
                           @"message" : @"",
                           @"name" : user.name,
                           @"recipient" : user.identifier
                           };
    return [self eventIfNeededByUser:byUser type:ZMUpdateEventTypeConversationConnectRequest data:data];
}

- (MockEvent *)removeUsersByUser:(MockUser *)byUser removedUser:(MockUser *)removedUser;
{
    [self.mutableActiveUsers removeObject:removedUser];
    
    NSDictionary *data = @{@"user_ids" : @[removedUser.identifier] };
    return [self eventIfNeededByUser:byUser type:ZMUpdateEventTypeConversationMemberLeave data:data];
}

-(MockEvent *)changeNameByUser:(MockUser *)user name:(NSString *)name
{
    [self setValue:name forKey:@"name"];
    return [self eventIfNeededByUser:user type:ZMUpdateEventTypeConversationRename data:@{@"name" : name}];

}

- (MockEvent *)changeReceiptModeByUser:(MockUser *)user receiptMode:(NSInteger)receiptMode
{
    self.receiptMode = @(receiptMode);
    return [self eventIfNeededByUser:user type:ZMUpdateEventTypeConversationReceiptModeUpdate data:@{@"receipt_mode": self.receiptMode }];
}

- (MockEvent *)insertAssetUploadEventForUser:(MockUser *)user data:(NSData *)data disposition:(NSDictionary *)disposition dataTypeAsMIME:(NSString *)dataTypeAsMIME assetID:(NSString *)assetID
{
    BOOL const inlineData = [disposition[@"inline"] boolValue];
    NSDictionary *payload = @{
                           @"content_length" : @(data.length),
                           @"content_type" : dataTypeAsMIME,
                           @"data" : inlineData ? [data base64EncodedStringWithOptions:0] : [NSNull null],
                           @"id" : assetID,
                           @"info" : @{
                                   @"correlation_id" : disposition[@"correlation_id"],
                                   @"height" : disposition[@"height"],
                                   @"name" : [NSNull null],
                                   @"nonce" : disposition[@"nonce"],
                                   @"original_height" : disposition[@"original_height"],
                                   @"original_width" : disposition[@"original_width"],
                                   @"public" : disposition[@"public"],
                                   @"tag" : disposition[@"tag"],
                                   @"width" : disposition[@"width"]
                                   }
                           };
    
    return [self eventIfNeededByUser:user type:ZMUpdateEventTypeConversationAssetAdd data:payload];
}

@end
