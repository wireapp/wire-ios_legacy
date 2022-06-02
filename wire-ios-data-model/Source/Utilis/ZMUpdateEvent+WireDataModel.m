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

@import WireProtos;

#import "ZMUpdateEvent+WireDataModel.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import <WireDataModel/WireDataModel-Swift.h>

@implementation ZMUpdateEvent (WireDataModel)

- (NSDate *)timestamp
{
    if (self.isTransient || self.type == ZMUpdateEventTypeUserConnection) {
        return nil;
    }
    return [self.payload optionalDateForKey:@"time"];
}

- (NSUUID *)senderUUID
{
    if (self.type == ZMUpdateEventTypeUserConnection) {
        return [[self.payload optionalDictionaryForKey:@"connection"] optionalUuidForKey:@"to"];
    }
    
    if (self.type == ZMUpdateEventTypeUserContactJoin) {
        return [[self.payload optionalDictionaryForKey:@"user"] optionalUuidForKey:@"id"];
    }

    return [self.payload optionalUuidForKey:@"from"];
}

- (NSUUID *)conversationUUID;
{
    if (self.type == ZMUpdateEventTypeUserConnection) {
        return  [[self.payload optionalDictionaryForKey:@"connection"] optionalUuidForKey:@"conversation"];
    }
    if (self.type == ZMUpdateEventTypeTeamConversationDelete) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalUuidForKey:@"conv"];
    }
    
    return [self.payload optionalUuidForKey:@"conversation"];
}

- (NSString *)senderClientID
{
    if (self.type == ZMUpdateEventTypeConversationOtrMessageAdd || self.type == ZMUpdateEventTypeConversationOtrAssetAdd) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"sender"];
    }
    return nil;
}

- (NSString *)senderDomain
{
    return [[self.payload optionalDictionaryForKey:@"qualified_from"] optionalStringForKey:@"domain"];
}

- (NSString *)conversationDomain
{
    return [[self.payload optionalDictionaryForKey:@"qualified_conversation"] optionalStringForKey:@"domain"];
}

- (NSString *)recipientClientID
{
    if (self.type == ZMUpdateEventTypeConversationOtrMessageAdd || self.type == ZMUpdateEventTypeConversationOtrAssetAdd) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"recipient"];
    }
    return nil;
}

@end


