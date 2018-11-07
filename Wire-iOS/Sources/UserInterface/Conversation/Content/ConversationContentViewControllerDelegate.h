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
@protocol UserType;


@protocol ConversationContentViewControllerDelegate <NSObject>

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
  willDisplayActiveMediaPlayerForMessage:(id<ZMConversationMessage>)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
didEndDisplayingActiveMediaPlayerForMessage:(id<ZMConversationMessage>)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
            didScrollWithOffsetFromBottom:(CGFloat)offset
                        withLatestMessage:(id<ZMConversationMessage>)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerResendingMessage:(id<ZMConversationMessage>)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerEditingMessage:(id<ZMConversationMessage>)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerReplyingToMessage:(id<ZMConversationMessage>)message;

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController performImageSaveAnimation:(UIView *)snapshotView sourceRect:(CGRect)sourceRect;

- (BOOL)conversationContentViewController:(ConversationContentViewController *)controller shouldBecomeFirstResponderWhenShowMenuFromCell:(UIView *)cell;

- (void)conversationContentViewControllerWantsToDismiss:(ConversationContentViewController *)controller;
    
- (void)conversationContentViewController:(ConversationContentViewController *)controller presentGuestOptionsFromView:(UIView *)sourceView;

- (void)conversationContentViewController:(ConversationContentViewController *)controller presentParticipantsDetailsWithSelectedUsers:(NSArray <ZMUser *>*)selectedUsers fromView:(UIView *)sourceView;

@optional

- (void)didTapOnUserAvatar:(id<UserType>)user view:(UIView *)view frame:(CGRect)frame;

@end
