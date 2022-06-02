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


#import "MessagingTest.h"

extern NSString * const EventConversationAdd;
extern NSString * const EventConversationAddClientMessage;
extern NSString * const EventConversationAddOTRMessage;
extern NSString * const EventConversationAddAsset;
extern NSString * const EventConversationAddOTRAsset;
extern NSString * const EventConversationKnock;
extern NSString * const EventConversationHotKnock;
extern NSString * const IsExpiredKey;
extern NSString * const EventConversationTyping;
extern NSString * const EventConversationMemberJoin;
extern NSString * const EventConversationMemberLeave;
extern NSString * const EventConversationRename;
extern NSString * const EventConversationCreate;
extern NSString * const EventConversationDelete;
extern NSString * const EventUserConnection;
extern NSString * const EventConversationConnectionRequest;
extern NSString * const EventNewConnection;

@interface MessagingTest (EventFactory)

- (ZMUpdateEvent *)eventWithPayload:(NSDictionary *)data inConversation:(ZMConversation *)conversation type:(NSString *)type;

- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation
                                                  sender:(ZMUser *)sender
                                                    type:(NSString *)type
                                                    data:(NSDictionary *)data;

- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data;
- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data time:(NSDate *)date;
- (NSMutableDictionary *)payloadForMessageInConversation:(ZMConversation *)conversation type:(NSString *)type data:(id)data time:(NSDate *)date fromUser:(ZMUser *)fromUser;

@end
