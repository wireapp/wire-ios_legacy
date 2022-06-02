//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

#import "ZMConnection+Helper.h"
#import "ZMUser+Internal.h"

@implementation ZMConnection (Helper)

+ (instancetype)insertNewSentConnectionToUser:(ZMUser *)user existingConversation:(ZMConversation *)conversation
{
    VerifyReturnValue(user.connection == nil, user.connection);
    RequireString(user != nil, "Can not create a connection to <nil> user.");
    ZMConnection *connection = [self insertNewObjectInManagedObjectContext:user.managedObjectContext];
    connection.to = user;
    connection.lastUpdateDate = [NSDate date];
    connection.status = ZMConnectionStatusSent;
    if (conversation == nil) {
        connection.conversation = [ZMConversation insertNewObjectInManagedObjectContext:user.managedObjectContext];

        [connection addWithUser:user];

        connection.conversation.creator = [ZMUser selfUserInContext:user.managedObjectContext];
    }
    else {
        connection.conversation = conversation;
        ///TODO: add user if not exists in participantRoles??
    }
    connection.conversation.conversationType = ZMConversationTypeConnection;
    connection.conversation.lastModifiedDate = connection.lastUpdateDate;
    return connection;
}

+ (instancetype)insertNewSentConnectionToUser:(ZMUser *)user;
{
    return [self insertNewSentConnectionToUser:user existingConversation:nil];
}

@end
