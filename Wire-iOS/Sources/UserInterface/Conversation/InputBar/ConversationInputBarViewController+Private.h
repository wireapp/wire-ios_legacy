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


@class AudioRecordKeyboardViewController;
@class CameraKeyboardViewController;
@class ConversationInputBarSendController;
@class EmojiKeyboardViewController;
@class EphemeralKeyboardViewController;
@class ConversationInputBarButtonState;
@class ZMClientMessage;
@class ReplyComposingView;
@class TypingIndicatorView;
@class ZMUser;

@interface ConversationInputBarViewController ()

@property (nonatomic, nonnull) IconButton *audioButton;
@property (nonatomic, nonnull) IconButton *photoButton;
@property (nonatomic, nonnull) IconButton *uploadFileButton;
@property (nonatomic, nonnull) IconButton *sketchButton;
@property (nonatomic, nonnull) IconButton *pingButton;
@property (nonatomic, nonnull) IconButton *locationButton;
@property (nonatomic, nonnull) IconButton *ephemeralIndicatorButton;
@property (nonatomic, nonnull) IconButton *markdownButton;
@property (nonatomic, nonnull) IconButton *gifButton;
@property (nonatomic, nonnull) IconButton *mentionButton;
@property (nonatomic, nonnull) IconButton *sendButton;
@property (nonatomic, nonnull) IconButton *hourglassButton;
@property (nonatomic, nonnull) IconButton *videoButton;

@property (nonatomic, nonnull) InputBar *inputBar;

@property (nonatomic, nullable) TypingIndicatorView *typingIndicatorView;

@property (nonatomic, nullable) AudioRecordViewController *audioRecordViewController;
@property (nonatomic, nullable) UIView *audioRecordViewContainer;

@property (nonatomic, nullable) AudioRecordKeyboardViewController *audioRecordKeyboardViewController;
@property (nonatomic, nullable) CameraKeyboardViewController *cameraKeyboardViewController;
@property (nonatomic, nullable) EphemeralKeyboardViewController *ephemeralKeyboardViewController;
@property (nonatomic, nonnull)  ConversationInputBarSendController *sendController;
@property (nonatomic, nullable) id<ZMConversationMessage> editingMessage;
@property (nonatomic, nullable) id<ZMConversationMessage> quotedMessage;
@property (nonatomic, nullable) ReplyComposingView *replyComposingView;

@property (nonatomic, nullable) UIImpactFeedbackGenerator *impactFeedbackGenerator;

@property (nonatomic)           BOOL shouldRefocusKeyboardAfterImagePickerDismiss;

// Counter keeping track of calls being made when the audio keyboard ewas visible before.
@property (nonatomic)           NSInteger callCountWhileCameraKeyboardWasVisible;
@property (nonatomic, nullable)           id callStateObserverToken;
@property (nonatomic)           BOOL wasRecordingBeforeCall;

@property (nonatomic, nonnull) ConversationInputBarButtonState *sendButtonState;

@property (nonatomic) BOOL inRotation;

// PopoverPresenter
@property (nonatomic, nullable, weak) UIPopoverPresentationController *presentedPopover;
@property (nonatomic, nullable, weak) UIView *popoverPointToView;

@property (nonatomic, nullable) NSSet<ZMUser *> *typingUsers;

- (void)updateRightAccessoryView;
- (void)updateButtonIcons;
- (void)updateAccessoryViews;
- (void)updateNewButtonTitleLabel;
- (void)clearInputBar;

- (void)shiftReturnPressed;
- (void)commandReturnPressed;
- (void)upArrowPressed;
- (void)escapePressed;

@end
