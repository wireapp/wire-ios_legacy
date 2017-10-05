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


#import <WireSyncEngine/WireSyncEngine.h>

@protocol ZMConversationMessage;

NS_ASSUME_NONNULL_BEGIN

@interface ZMConversation (Additions)

- (nullable id<ZMConversationMessage>)firstTextMessage;
- (nullable id<ZMConversationMessage>)lastTextMessage;
- (nullable id<ZMConversationMessage>)lastMessageSentByUser:(ZMUser *)user limit:(NSUInteger)limit;

/// Convenience method for easier access of the last active user in the conversation. This method also contains the logic of selecting the other user in case its of a 1:1 conversation. Might return @c nil
- (nullable ZMUser *)lastMessageSender;

/// YES = this message is the first in a burst, and UI should present a burst separator (timestamp header) with it.
- (BOOL)shouldShowBurstSeparatorForMessage:(id<ZMConversationMessage>)message;

- (BOOL)selfUserIsActiveParticipant;

- (nullable ZMUser *)firstActiveParticipantOtherThanSelf;

- (ZMConversation *)addParticipantsOrCreateConversation:(NSSet *)participants;

@end

NS_ASSUME_NONNULL_END
