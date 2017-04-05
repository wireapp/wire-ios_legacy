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
#import "Analytics+ConversationEvents.h"


@interface Message (UI)

+ (MessageType)messageType:(id<ZMConversationMessage>)message;

+ (BOOL)shouldShowTimestamp:(id<ZMConversationMessage>)message;

+ (BOOL)shouldShowDeliveryState:(id<ZMConversationMessage>)message;

+ (NSString *)formattedReceivedDateForMessage:(id<ZMConversationMessage>)message;

+ (BOOL)isPresentableAsNotification:(id<ZMConversationMessage>)message;

+ (NSString *)nonNilImageDataIdentifier:(id<ZMConversationMessage>)message;

+ (BOOL)canBePrefetched:(id<ZMConversationMessage>)message;

@end
