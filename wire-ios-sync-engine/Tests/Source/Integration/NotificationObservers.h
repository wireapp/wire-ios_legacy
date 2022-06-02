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


@import WireDataModel;

#import <WireSyncEngine/WireSyncEngine-Swift.h>

typedef void(^ObserverCallback)(NSObject *note);



@interface ChangeObserver : NSObject

@property (nonatomic, readonly) NSMutableArray *notifications;
@property (nonatomic, copy) ObserverCallback notificationCallback;

- (void)clearNotifications;

@end



@interface ConversationChangeObserver : ChangeObserver <ZMConversationObserver>
- (instancetype)initWithConversation:(ZMConversation *)conversation;

@end



@interface ConversationListChangeObserver : ChangeObserver <ZMConversationListObserver>
- (instancetype)initWithConversationList:(ZMConversationList *)conversationList;
@property (nonatomic) NSMutableArray *conversationChangeInfos;

@end



@interface UserChangeObserver : ChangeObserver <ZMUserObserver>
- (instancetype)initWithUser:(ZMUser *)user;
- (instancetype)initWithUser:(id<UserType>)user managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end



@interface MessageChangeObserver : ChangeObserver <ZMMessageObserver>
- (instancetype)initWithMessage:(ZMMessage *)message;

@end

