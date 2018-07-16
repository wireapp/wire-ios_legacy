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


#import <Foundation/Foundation.h>

@class ZMConversation;
@protocol ZMConversationMessage;
@class ConversationInputBarSendController;


@protocol ConversationInputBarSendControllerDelegate <NSObject>

@optional
- (void)conversationInputBarSendController:(ConversationInputBarSendController *)controller didSendMessage:(id<ZMConversationMessage>)message;

@end

@interface ConversationInputBarSendController : NSObject

@property (nonatomic, readonly) ZMConversation *conversation;
@property (nonatomic, weak) id<ConversationInputBarSendControllerDelegate> delegate;

- (instancetype)initWithConversation:(ZMConversation *)conversation;
- (void)sendMessageWithImageData:(NSData *)imageData completion:(dispatch_block_t)completionHandler;
- (void)sendTextMessage:(NSString *)text;
- (void)sendTextMessage:(NSString *)text withImageData:(NSData *)data;
- (void)sendMentionsToUsersInMessage:(NSString *)text;

@end
