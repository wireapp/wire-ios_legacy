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


#import "MockTransportSession+internal.h"

@import WireProtos;

@interface MockTransportSession (OTR)

- (MockUserClient *)otrMessageSender:(NSDictionary *)payload;

/// Returns a list of missing clients in the conversation that were not included in the list of intendend recipients
/// @param recipients list of intender recipients
/// @param onlyForUserId if not nil, only return missing recipients matching this user ID
- (NSDictionary *)missedClients:(NSDictionary *)recipients conversation:(MockConversation *)conversation sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId;

/// Returns a list of missing clients for broascasting that were not included in the list of intendend recipients
/// @param recipients list of intender recipients
/// @param onlyForUserId if not nil, only return missing recipients matching this user ID
- (NSDictionary *)missedClients:(NSDictionary *)recipients sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId;

/// Returns a list of redundant clients in the conversation that were included in the list of intendend recipients
/// @param recipients list of intender recipients
- (NSDictionary *)deletedClients:(NSDictionary *)recipients conversation:(MockConversation *)conversation;

/// Returns a list of redundant clients for broascasting that were included in the list of intendend recipients
/// @param recipients list of intender recipients
- (NSDictionary *)deletedClients:(NSDictionary *)recipients;

- (void)insertOTRMessageEventsToConversation:(MockConversation *)conversation
                              requestPayload:(NSDictionary *)requestPayload
                            createEventBlock:(MockEvent *(^)(MockUserClient *recipient, NSData *messageData))createEventBlock;

@end
