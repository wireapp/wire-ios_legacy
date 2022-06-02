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


#import "ZMBaseManagedObjectTest.h"

extern NSString * _Nonnull const EventConversationAdd;
extern NSString * _Nonnull const EventConversationAddClientMessage;
extern NSString * _Nonnull const EventConversationAddOTRMessage;
extern NSString * _Nonnull const EventConversationAddAsset;
extern NSString * _Nonnull const EventConversationAddOTRAsset;
extern NSString * _Nonnull const EventConversationKnock;
extern NSString * _Nonnull const EventConversationHotKnock;
extern NSString * _Nonnull const IsExpiredKey;
extern NSString * _Nonnull const EventCallState;
extern NSString * _Nonnull const EventConversationTyping;
extern NSString * _Nonnull const EventConversationMemberJoin;
extern NSString * _Nonnull const EventConversationMemberLeave;
extern NSString * _Nonnull const EventConversationRename;
extern NSString * _Nonnull const EventConversationCreate;
extern NSString * _Nonnull const EventUserConnection;
extern NSString * _Nonnull const EventConversationConnectionRequest;
extern NSString * _Nonnull const EventConversationEncryptedMessage;
extern NSString * _Nonnull const EventNewConnection;

@interface ZMBaseManagedObjectTest (EventFactory)

/// Creates a call.state event payload for conversation with callParticipants and selfUser as active member
/// To use this method, set remoteIdentifiers on all managedObjects
- (NSDictionary * _Nonnull)payloadForCallStateEventInConversation:(ZMConversation * _Nonnull)conversation
                                         othersAreJoined:(BOOL)othersAreJoined
                                            selfIsJoined:(BOOL)selfIsJoined
                                                sequence:(NSNumber * _Nonnull)sequence;

- (NSDictionary * _Nonnull)payloadForCallStateEventInConversation:(ZMConversation * _Nonnull)conversation
                                         othersAreJoined:(BOOL)othersAreJoined
                                            selfIsJoined:(BOOL)selfIsJoined
                                     otherIsSendingVideo:(BOOL)otherIsSendingVideo
                                      selfIsSendingVideo:(BOOL)selfIsSendingVideo
                                                sequence:(NSNumber * _Nonnull)sequence;

- (NSDictionary * _Nonnull)payloadForCallStateEventInConversation:(ZMConversation * _Nonnull)conversation
                                             joinedUsers:(NSArray * _Nonnull)joinedUsers
                                       videoSendingUsers:(NSArray * _Nonnull)videoSendingUsers
                                                sequence:(NSNumber * _Nonnull)sequence;

- (ZMUpdateEvent * _Nonnull)callStateEventInConversation:(ZMConversation * _Nonnull)conversation
                                othersAreJoined:(BOOL)othersAreJoined
                                   selfIsJoined:(BOOL)selfIsJoined
                            otherIsSendingVideo:(BOOL)otherIsSendingVideo
                             selfIsSendingVideo:(BOOL)selfIsSendingVideo
                                       sequence:(NSNumber * _Nonnull)sequence;

- (ZMUpdateEvent * _Nonnull)callStateEventInConversation:(ZMConversation * _Nonnull)conversation
                                    joinedUsers:(NSArray * _Nonnull)joinedUsers
                              videoSendingUsers:(NSArray * _Nonnull)videoSendingUsers
                                       sequence:(NSNumber * _Nonnull)sequence;

- (ZMUpdateEvent * _Nonnull)callStateEventInConversation:(ZMConversation * _Nonnull)conversation
                                    joinedUsers:(NSArray * _Nonnull)joinedUsers
                              videoSendingUsers:(NSArray * _Nonnull)videoSendingUsers
                                       sequence:(NSNumber * _Nonnull)sequence
                                        session:(NSString * _Nullable)session;

- (ZMUpdateEvent * _Nonnull)eventWithPayload:(NSDictionary * _Nonnull)data
                              inConversation:(ZMConversation * _Nonnull)conversation
                                        type:(NSString * _Nonnull)type;

- (NSMutableDictionary * _Nonnull)payloadForMessageInConversation:(ZMConversation * _Nonnull)conversation
                                                  sender:(ZMUser * _Nonnull)sender
                                                    type:(NSString * _Nonnull)type
                                                    data:(NSDictionary * _Nonnull)data;

- (NSMutableDictionary * _Nonnull)payloadForMessageInConversation:(ZMConversation * _Nonnull)conversation
                                                    type:(NSString * _Nonnull)type
                                                    data:(id _Nonnull)data;
- (NSMutableDictionary * _Nonnull)payloadForMessageInConversation:(ZMConversation * _Nonnull)conversation
                                                    type:(NSString * _Nonnull)type
                                                    data:(id _Nonnull)data
                                                    time:(NSDate * _Nullable)date;
- (NSMutableDictionary * _Nonnull)payloadForMessageInConversation:(ZMConversation * _Nonnull)conversation
                                                             type:(NSString * _Nonnull)type
                                                             data:(id _Nonnull)data
                                                             time:(NSDate * _Nonnull)date
                                                         fromUser:(ZMUser * _Nonnull)fromUser;

@end
