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

@import WireTesting;
@import WireDataModel;

@implementation ZMConversation (Testing)

- (void)setUnreadCount:(NSUInteger)count;
{
    self.lastServerTimeStamp = [NSDate date];
    self.lastReadServerTimeStamp = self.lastServerTimeStamp;
    
    for (NSUInteger idx = 0; idx < count; idx++) {
        ZMMessage *message = [[ZMMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.managedObjectContext];
        message.serverTimestamp = [self.lastServerTimeStamp dateByAddingTimeInterval:5];
        self.lastServerTimeStamp = message.serverTimestamp;
    }
}

- (void)addUnreadMissedCall
{
    ZMSystemMessage *systemMessage = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.managedObjectContext];
    systemMessage.systemMessageType = ZMSystemMessageTypeMissedCall;
    systemMessage.serverTimestamp = self.lastReadServerTimeStamp ?
    [self.lastReadServerTimeStamp dateByAddingTimeInterval:1000] :
    [NSDate dateWithTimeIntervalSince1970:1231234];
    [self calculateLastUnreadMessages];
}

- (void)setHasExpiredMessage:(BOOL)hasUnreadUnsentMessage
{
    self.hasUnreadUnsentMessage = hasUnreadUnsentMessage;
}

@end

