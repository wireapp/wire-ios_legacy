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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import UIKit;

@class ZMConversation;
@class ZMMessage;

@interface ZMStoredLocalNotification : NSObject

@property (nonatomic, readonly) ZMConversation *conversation;
@property (nonatomic, readonly) ZMMessage *message;
@property (nonatomic, readonly) NSUUID *senderUUID;

@property (nonatomic, readonly) NSString *category;
@property (nonatomic, readonly) NSString *actionIdentifier;
@property (nonatomic, readonly) NSString *textInput;

- (instancetype)initWithNotification:(UILocalNotification *)notification
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                    actionIdentifier:(NSString *)identifier
                           textInput:(NSString*)textInput;

- (instancetype)initWithPushPayload:(NSDictionary *)userInfo
               managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

