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
@import WireTransport;
@import WireTesting;

#import "MessagingTest+EventFactory.h"
#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"

NSString * const EventConversationAdd = @"conversation.message-add";
NSString * const EventConversationAddClientMessage = @"conversation.client-message-add";
NSString * const EventConversationAddOTRMessage = @"conversation.otr-message-add";
NSString * const EventConversationAddAsset = @"conversation.asset-add";
NSString * const EventConversationAddOTRAsset = @"conversation.otr-asset-add";
NSString * const EventConversationKnock = @"conversation.knock";
NSString * const EventConversationTyping = @"conversation.typing";

NSString * const EventCallState = @"call.state";

NSString * const EventConversationMemberJoin = @"conversation.member-join";
NSString * const EventConversationMemberLeave = @"conversation.member-leave";
NSString * const EventConversationRename = @"conversation.rename";
NSString * const EventConversationCreate = @"conversation.create";
NSString * const EventUserConnection = @"user.connection";
NSString * const EventConversationConnectionRequest = @"conversation.connect-request";
NSString * const EventConversationEncryptedMessage = @"conversation.otr-message-add";
NSString * const EventNewConnection = @"user.contact-join";

@implementation ZMBaseManagedObjectTest (EventFactory)


- (NSDictionary *)payloadForCallStateEventInConversation:(ZMConversation *)conversation
                                         othersAreJoined:(BOOL)othersAreJoined
                                            selfIsJoined:(BOOL)selfIsJoined
                                                sequence:(NSNumber *)sequence
{
    return [self payloadForCallStateEventInConversation:conversation
                                                othersAreJoined:othersAreJoined
                                                   selfIsJoined:selfIsJoined
                                            otherIsSendingVideo:NO
                                             selfIsSendingVideo:NO
                                                       sequence:sequence];
}

- (NSDictionary *)payloadForCallStateEventInConversation:(ZMConversation *)conversation
                                         othersAreJoined:(BOOL)othersAreJoined
                                            selfIsJoined:(BOOL)selfIsJoined
                                     otherIsSendingVideo:(BOOL)otherIsSendingVideo
                                      selfIsSendingVideo:(BOOL)selfIsSendingVideo
                                                sequence:(NSNumber *)sequence
{
    ZMUser *selfUser = [ZMUser selfUserInContext:conversation.managedObjectContext];
    NSMutableArray *joinedUsers = [NSMutableArray array];
    if (othersAreJoined) {
        if (conversation.conversationType == ZMConversationTypeGroup) {
            [joinedUsers addObjectsFromArray:conversation.localParticipants.allObjects];
        } else {
            [joinedUsers addObject:conversation.connectedUser];
        }
    }
    if (selfIsJoined) {
        [joinedUsers addObject:selfUser];
    }
    NSMutableArray *usersSendingVideo = [NSMutableArray array];
    if (otherIsSendingVideo) {
        if (conversation.conversationType == ZMConversationTypeGroup) {
            [usersSendingVideo addObjectsFromArray:conversation.localParticipants.allObjects];
        } else {
            [usersSendingVideo addObject:conversation.connectedUser];
        }
    }
    if (selfIsSendingVideo) {
        [usersSendingVideo addObject:selfUser];
    }
    
    return [self payloadForCallStateEventInConversation:conversation joinedUsers:joinedUsers videoSendingUsers:usersSendingVideo sequence:sequence];
}

- (NSDictionary *)userDictionaryState:(BOOL)isJoined isSendingVideo:(BOOL)isSendingVideo
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"state"] = isJoined ? @"joined" : @"idle";
    if (isSendingVideo) {
        dict[@"videod"] = @YES;
    }
    return dict;
}

- (NSDictionary *)payloadForCallStateEventInConversation:(ZMConversation *)conversation
                                             joinedUsers:(NSArray *)joinedUsers
                                       videoSendingUsers:(NSArray *)videoSendingUsers
                                                sequence:(NSNumber *)sequence
{
    return [self payloadForCallStateEventInConversation:conversation joinedUsers:joinedUsers videoSendingUsers:videoSendingUsers sequence:sequence session:nil];
}


- (NSDictionary *)payloadForCallStateEventInConversation:(ZMConversation *)conversation
                                             joinedUsers:(NSArray *)joinedUsers
                                       videoSendingUsers:(NSArray *)videoSendingUsers
                                                sequence:(NSNumber *)sequence
                                                 session:(NSString *)sessionID
{
    ZMUser *selfUser = [ZMUser selfUserInContext:conversation.managedObjectContext];
    NSDictionary *selfStateDict = [self userDictionaryState:[joinedUsers containsObject:selfUser] isSendingVideo:[videoSendingUsers containsObject:selfUser]];
    
    NSMutableArray *otherStates = [NSMutableArray array];
    NSArray *otherUUIDs = [conversation.sortedActiveParticipants mapWithBlock:^id(ZMUser *user) {
        if (user.remoteIdentifier != nil) {
            NSDictionary *otherStateDict = [self userDictionaryState:[joinedUsers containsObject:user] isSendingVideo:[videoSendingUsers containsObject:user]];
            [otherStates addObject:otherStateDict];
        } else {
            NSLog(@"WARNING: did not set remoteID for otherActiveUser %@", user);
        }
        return user.remoteIdentifier.transportString;
    }];
    
    NSMutableDictionary *participantsDict = [NSMutableDictionary dictionaryWithObjects:otherStates forKeys:otherUUIDs];
    participantsDict[selfUser.remoteIdentifier.transportString] = selfStateDict;
    
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"self"] = selfStateDict;
    payload[@"participants"] = participantsDict;
    payload[@"cause"] = @"requested";
    payload[@"type"] = @"call.state";
    payload[@"conversation"] = conversation.remoteIdentifier.transportString;
    if (sequence != nil) {
        payload[@"sequence"] = sequence;
    }
    if (sessionID != nil) {
        payload[@"session"] = sessionID;
    }
    
    return [payload copy];
}

- (ZMUpdateEvent *)callStateEventInConversation:(ZMConversation *)conversation
                              othersAreJoined:(BOOL)othersAreJoined
                                 selfIsJoined:(BOOL)selfIsJoined
                          otherIsSendingVideo:(BOOL)otherIsSendingVideo
                           selfIsSendingVideo:(BOOL)selfIsSendingVideo
                                     sequence:(NSNumber *)sequence
{
    NSDictionary *payload = [self payloadForCallStateEventInConversation:conversation
                                                         othersAreJoined:othersAreJoined
                                                            selfIsJoined:selfIsJoined
                                                     otherIsSendingVideo:otherIsSendingVideo
                                                      selfIsSendingVideo:selfIsSendingVideo
                                                                sequence:sequence];
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event, @"The event could not be created");
    return event;
}

- (ZMUpdateEvent *)callStateEventInConversation:(ZMConversation *)conversation
                                    joinedUsers:(NSArray *)joinedUsers
                              videoSendingUsers:(NSArray *)videoSendingUsers
                                       sequence:(NSNumber *)sequence;
{
    return [self callStateEventInConversation:conversation joinedUsers:joinedUsers videoSendingUsers:videoSendingUsers sequence:sequence session:nil];
}

- (ZMUpdateEvent *)callStateEventInConversation:(ZMConversation *)conversation
                                    joinedUsers:(NSArray *)joinedUsers
                              videoSendingUsers:(NSArray *)videoSendingUsers
                                       sequence:(NSNumber *)sequence
                                        session:(NSString *)session;
{
    NSDictionary *payload = [self payloadForCallStateEventInConversation:conversation
                                                             joinedUsers:joinedUsers
                                                       videoSendingUsers:videoSendingUsers
                                                                sequence:sequence
                                                                 session:session];
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    XCTAssertNotNil(event, @"The event could not be created");
    return event;

}

- (ZMUpdateEvent *)eventWithPayload:(NSDictionary *)data inConversation:(ZMConversation *)conversation type:(NSString *)type
{
    NSDictionary *payload = [self payloadForMessageInConversation:conversation type:type data:data];
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    
    return event;
}

- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation
                                                  sender:(ZMUser *)sender
                                                    type:(NSString *)type
                                                    data:(NSDictionary *)data
{
    NSUUID *userRemoteID = sender.remoteIdentifier;
    NSUUID *convRemoteID = conversation.remoteIdentifier ?: [NSUUID createUUID];
    data = data ?: @{};
    
    return [@{
              @"conversation" : convRemoteID.transportString,
              @"data" : data,
              @"from" : userRemoteID.transportString,
              @"type" : type,
              } mutableCopy];
}


- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data
{
    return [self payloadForMessageInConversation:conversation type:type data:data time:nil];
}

- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data time:(NSDate *)date;
{
    //      {
    //         "conversation" : "8500be67-3d7c-4af0-82a6-ef2afe266b18",
    //         "data" : {
    //            "content" : "test test",
    //            "nonce" : "c61a75f3-285b-2495-d0f6-6f0e17f0c73a"
    //         },
    //         "from" : "39562cc3-717d-4395-979c-5387ae17f5c3",
    //         "id" : "11.800122000a4ab4f0",
    //         "time" : "2014-06-22T19:57:50.948Z",
    //         "type" : "conversation.message-add"
    //      }
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:conversation.managedObjectContext];
    user.remoteIdentifier = NSUUID.createUUID;
    return [self payloadForMessageInConversation:conversation type:type data:data time:date fromUser:user];
}

- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data time:(NSDate *)date fromUser:(ZMUser *)fromUser;
{
    date = date ?: [NSDate date];
    
    return [@{
              @"conversation" : conversation.remoteIdentifier.transportString,
              @"data" : data ?: @[],
              @"from" : fromUser.remoteIdentifier.transportString ?: [NSNull null],
              @"time" : date.transportString,
              @"type" : type
              } mutableCopy];
}


@end
