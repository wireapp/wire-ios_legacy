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


#import "MockTransportSession+OTR.h"
#import <WireMockTransport/WireMockTransport-Swift.h>


@implementation MockTransportSession (OTR)

- (MockUserClient *)otrMessageSender:(NSDictionary *)payload
{
    NSString *senderClientId = payload[@"sender"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", senderClientId];
    MockUserClient *client = [self.managedObjectContext executeFetchRequestOrAssert:request].firstObject;
    return client;
}

- (NSDictionary *)missedClients:(NSDictionary *)recipients conversation:(MockConversation *)conversation sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId
{
    return [self missedClients:recipients users:conversation.activeUsers.set sender:sender onlyForUserId:onlyForUserId];
}

- (NSDictionary *)missedClients:(NSDictionary *)recipients sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId
{
    return [self missedClients:recipients users:self.selfUser.connectionsAndTeamMembers sender:sender onlyForUserId:onlyForUserId];
}


- (NSDictionary *)deletedClients:(NSDictionary *)recipients conversation:(MockConversation *)conversation
{
    return [self deletedClients:recipients users:conversation.activeUsers.set];
}

- (NSDictionary *)deletedClients:(NSDictionary *)recipients
{
    return [self deletedClients:recipients users:self.selfUser.connectionsAndTeamMembers];
}

- (NSDictionary *)deletedClients:(NSDictionary *)recipients users:(NSSet<MockUser *> *)users
{
    NSMutableDictionary *deletedClients = [NSMutableDictionary new];
    for (NSString *userId in recipients) {
        NSDictionary *recipientPayload = recipients[userId];
        MockUser *user = [users filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", userId]].anyObject;
        NSArray *recipientClients = [recipientPayload allKeys];
        NSSet *userClients = [user.clients mapWithBlock:^id(MockUserClient *client) {
            return client.identifier;
        }];
        NSMutableSet *deletedUserClients = [NSMutableSet setWithArray:recipientClients];
        [deletedUserClients minusSet:userClients];
        if (deletedUserClients.count > 0) {
            deletedClients[userId] = deletedUserClients.allObjects;
        }
    }
    return deletedClients;
}

- (void)insertOTRMessageEventsToConversation:(MockConversation *)conversation
                              requestPayload:(NSDictionary *)requestPayload
                            createEventBlock:(MockEvent *(^)(MockUserClient *recipient, NSData *messageData))createEventBlock
{
    NSDictionary *recipients = requestPayload[@"recipients"];
    
    NSArray *activeClients = [conversation.activeUsers.array flattenWithBlock:^NSArray *(MockUser *user) {
        return user.clients.allObjects;
    }];
    
    for (MockUserClient *activeClient in activeClients) {
        NSString *keyPath = [NSString stringWithFormat:@"%@.%@", activeClient.user.identifier, activeClient.identifier];
        NSString *messageContent = [recipients valueForKeyPath:keyPath];
        if (messageContent == nil) {
            continue;
        }
        NSData *messageData = [[NSData alloc] initWithBase64EncodedString:messageContent options:0];
        createEventBlock(activeClient, messageData);
    }
}

@end
