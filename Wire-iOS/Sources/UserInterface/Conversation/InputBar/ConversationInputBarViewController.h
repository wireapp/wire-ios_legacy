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

NS_ASSUME_NONNULL_BEGIN

@class Mention;
@class InputBar;
@class IconButton;
@class ZMConversation;
@class ConversationInputBarViewController;
@class AudioRecordViewController;
@class MentionsHandler;
@protocol ZMConversationMessage;
@protocol Dismissable;
@protocol UserList;
@protocol KeyboardCollapseObserver;
@protocol AVAudioSessionType;

typedef NS_ENUM(NSUInteger, ConversationInputBarViewControllerMode) {
    ConversationInputBarViewControllerModeTextInput,
    ConversationInputBarViewControllerModeAudioRecord,
    ConversationInputBarViewControllerModeCamera,
    ConversationInputBarViewControllerModeEmojiInput,
    ConversationInputBarViewControllerModeTimeoutConfguration
};


@protocol ConversationInputBarViewControllerDelegate <NSObject>

- (void)conversationInputBarViewControllerDidComposeText:(NSString *)text
                                                mentions:(NSArray<Mention *> *)mentions
                                       replyingToMessage:(nullable id <ZMConversationMessage>)message;

@optional
- (BOOL)conversationInputBarViewControllerShouldBeginEditing:(ConversationInputBarViewController *)controller;
- (BOOL)conversationInputBarViewControllerShouldEndEditing:(ConversationInputBarViewController *)controller;
- (void)conversationInputBarViewControllerDidNotSendMessageConversationDegraded:(ConversationInputBarViewController *)controller;
- (void)conversationInputBarViewControllerDidFinishEditingMessage:(id <ZMConversationMessage>)message withText:(NSString *)newText mentions:(NSArray <Mention *> *)mentions;
- (void)conversationInputBarViewControllerDidCancelEditingMessage:(id <ZMConversationMessage>)message;
- (void)conversationInputBarViewControllerWantsToShowMessage:(id <ZMConversationMessage>)message;
- (void)conversationInputBarViewControllerEditLastMessage;

@end


@interface ConversationInputBarViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (nonatomic, readonly) IconButton *photoButton;
@property (nonatomic, readonly) IconButton *ephemeralIndicatorButton;
@property (nonatomic, readonly) IconButton *markdownButton;
@property (nonatomic, readonly) IconButton *mentionButton;
@property (nonatomic, readonly) InputBar *inputBar;
@property (nonatomic, readonly) ZMConversation *conversation;
@property (nonatomic, weak, nullable) id <ConversationInputBarViewControllerDelegate> delegate;
@property (nonatomic) ConversationInputBarViewControllerMode mode;
@property (nonatomic, readonly, nullable) UIViewController *inputController;
@property (nonatomic, strong, nullable) MentionsHandler *mentionsHandler;
@property (nonatomic, weak, nullable) id<Dismissable, UserList, KeyboardCollapseObserver> mentionsView;
@property (nonatomic, strong, nullable) id textfieldObserverToken;
@property (nonatomic, nonnull) id<AVAudioSessionType> audioSession;

- (instancetype)initWithConversation:(ZMConversation *)conversation;
- (void)bounceCameraIcon;

- (void)playInputHapticFeedback;

@end

NS_ASSUME_NONNULL_END
