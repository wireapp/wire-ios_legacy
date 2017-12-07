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


#import <UIKit/UIKit.h>

@class InputBar;
@class IconButton;
@class ZMConversation;
@class ConversationInputBarViewController;
@class AnalyticsTracker;
@class AudioRecordViewController;
@protocol ZMConversationMessage;

typedef NS_ENUM(NSUInteger, ConversationInputBarViewControllerMode) {
    ConversationInputBarViewControllerModeTextInput,
    ConversationInputBarViewControllerModeAudioRecord,
    ConversationInputBarViewControllerModeCamera,
    ConversationInputBarViewControllerModeEmojiInput,
    ConversationInputBarViewControllerModeTimeoutConfguration
};


@protocol ConversationInputBarViewControllerDelegate <NSObject>

@optional
- (BOOL)conversationInputBarViewControllerShouldBeginEditing:(ConversationInputBarViewController *)controller isEditingMessage:(BOOL)isEditing;
- (BOOL)conversationInputBarViewControllerShouldEndEditing:(ConversationInputBarViewController *)controller;
- (void)conversationInputBarViewControllerDidNotSendMessageConversationDegraded:(ConversationInputBarViewController *)controller;
- (void)conversationInputBarViewControllerDidFinishEditingMessage:(id <ZMConversationMessage>)message withText:(NSString *)newText;
- (void)conversationInputBarViewControllerDidCancelEditingMessage:(id <ZMConversationMessage>)message;
- (void)conversationInputBarViewControllerEditLastMessage;

@end


@interface ConversationInputBarViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (nonatomic, readonly) IconButton *photoButton;
@property (nonatomic, readonly) IconButton *ephemeralIndicatorButton;
@property (nonatomic, readonly) IconButton *markdownButton;
@property (nonatomic, readonly) InputBar *inputBar;
@property (nonatomic, readonly) ZMConversation *conversation;
@property (nonatomic, weak) id <ConversationInputBarViewControllerDelegate> delegate;
@property (nonatomic) AnalyticsTracker *analyticsTracker;
@property (nonatomic) ConversationInputBarViewControllerMode mode;
@property (nonatomic, readonly) UIViewController *inputController;

- (instancetype)initWithConversation:(ZMConversation *)conversation;
- (void)bounceCameraIcon;

@end
