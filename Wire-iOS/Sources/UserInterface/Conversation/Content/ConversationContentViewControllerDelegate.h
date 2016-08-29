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

@protocol ZMConversationMessage;
@class ZMUser;
@class ZMMessage;
@class ConversationContentViewController;
@protocol MediaPlayer;



@protocol ConversationContentViewControllerDelegate <NSObject>

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
  willDisplayActiveMediaPlayerForMessage:(id<ZMConversationMessage>)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
didEndDisplayingActiveMediaPlayerForMessage:(id<ZMConversationMessage>)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
            didScrollWithOffsetFromBottom:(CGFloat)offset
                        withLatestMessage:(id<ZMConversationMessage>)message;

/// Called either when the interactive scroll or the deceleration animation ends. In either case, the view is again in a stable state and not scrolling any more.
- (void)conversationContentViewControllerDidFinishScrolling:(ConversationContentViewController *)contentViewController;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerAddContactsButton:(UIButton *)button;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerResendingMessage:(ZMMessage *)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerEditingMessage:(ZMMessage *)message;

- (BOOL)conversationContentViewController:(ConversationContentViewController *)controller shouldBecomeFirstResponderWhenShowMenuFromCell:(UITableViewCell *)cell;

@optional

- (void)didTapOnUserAvatar:(ZMUser *)user view:(UIView *)view;

@end
