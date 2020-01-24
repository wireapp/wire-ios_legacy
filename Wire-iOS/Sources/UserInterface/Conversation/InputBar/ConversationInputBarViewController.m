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


@import MobileCoreServices;

#import "ConversationInputBarViewController.h"
#import "ConversationInputBarViewController+Private.h"
#import "ConversationInputBarViewController+Files.h"

#import "ConfirmAssetViewController.h"
#import "TextView.h"
#import "UIViewController+Errors.h"

#import "Analytics.h"
#import "Wire-Swift.h"


#import "Settings.h"
#import "ConversationInputBarSendController.h"
@import FLAnimatedImage;
#import "MediaAsset.h"
#import "UIView+WR_ExtendedBlockAnimations.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface ConversationInputBarViewController (Ping)

- (void)pingButtonPressed:(UIButton *)button;

@end

@interface ConversationInputBarViewController (Location) <LocationSelectionViewControllerDelegate>

@end

@interface ConversationInputBarViewController (ZMConversationObserver) <ZMConversationObserver>
@end

@interface ConversationInputBarViewController (ZMUserObserver) <ZMUserObserver>
@end

@interface ConversationInputBarViewController (ZMTypingChangeObserver) <ZMTypingChangeObserver>
@end

@interface ConversationInputBarViewController (Giphy)

- (void)giphyButtonPressed:(id)sender;

@end

@interface ConversationInputBarViewController (Sending)

- (void)sendButtonPressed:(id)sender;

@end

@interface ConversationInputBarViewController (Sketch)

- (void)sketchButtonPressed:(nullable id)sender;

@end


@interface  ConversationInputBarViewController (UIGestureRecognizerDelegate) <UIGestureRecognizerDelegate>

@end

@interface ConversationInputBarViewController (GiphySearchViewController) <GiphySearchViewControllerDelegate>

@end

@interface ConversationInputBarViewController ()

@property (nonatomic) UIGestureRecognizer *singleTapGestureRecognizer;

@property (nonatomic) UserImageView *authorImageView;

@property (nonatomic) ZMConversation *conversation;

@property (nonatomic) id conversationObserverToken;
@property (nonatomic) id userObserverToken;

@property (nonatomic) UIViewController *inputController;

@property (nonatomic) id typingObserverToken;

@property (nonatomic) UINotificationFeedbackGenerator *notificationFeedbackGenerator;
@end


@implementation ConversationInputBarViewController


/**
 init with a ZMConversation objcet

 @param conversation provide nil only for tests
 @return a ConversationInputBarViewController
 */
- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super init];
    if (self) {
        [self setupAudioSession];

        if (conversation != nil) {
            self.conversation = conversation;
            self.sendController = [[ConversationInputBarSendController alloc] initWithConversation:self.conversation];
            self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
            self.typingObserverToken = [conversation addTypingObserver:self];
        }

        self.sendButtonState = [[ConversationInputBarButtonState alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];

        [self setupInputLanguageObserver];

        self.notificationFeedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
        self.impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];

        [self setupViews];
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)didEnterBackground:(NSNotification *)notification
{
    NOT_USED(notification);
    if(self.inputBar.textView.text.length > 0) {
        [self.conversation setIsTyping:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupCallStateObserver];
    [self setupAppLockedObserver];
    
    [self createSingleTapGestureRecognizer];


    if (self.conversation.hasDraftMessage) {
        [self.inputBar.textView setDraftMessage:self.conversation.draftMessage];
    }

    [self configureAudioButton:self.audioButton];
    [self configureMarkdownButton];
    [self configureMentionButton];
    [self configureEphemeralKeyboardButton:self.hourglassButton];
    [self configureEphemeralKeyboardButton:self.ephemeralIndicatorButton];
    
    [self.sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.photoButton addTarget:self action:@selector(cameraButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoButton addTarget:self action:@selector(videoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.sketchButton addTarget:self action:@selector(sketchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.uploadFileButton addTarget:self action:@selector(docUploadPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.pingButton addTarget:self action:@selector(pingButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.gifButton addTarget:self action:@selector(giphyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.locationButton addTarget:self action:@selector(locationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.conversationObserverToken == nil && self.conversation != nil) {
        self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
    }

    if (self.userObserverToken == nil &&
        self.conversation.connectedUser != nil
        && ZMUserSession.sharedSession != nil) {
        self.userObserverToken = [UserChangeInfo addObserver:self forUser:self.conversation.connectedUser inUserSession:ZMUserSession.sharedSession];
    }
    
    [self updateAccessoryViews];
    [self updateInputBarVisibility];
    [self updateTypingIndicator];
    [self updateWritingStateAnimated:NO];
    [self updateButtonIcons];
    [self updateAvailabilityPlaceholder];

    [self setInputLanguage];
    [self setupStyle];
    
    if (@available(iOS 11.0, *)) {
        UIDropInteraction *interaction = [[UIDropInteraction alloc] initWithDelegate:self];
        [self.inputBar.textView addInteraction:interaction];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateRightAccessoryView];
    [self.inputBar updateReturnKey];
    [self.inputBar updateEphemeralState];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.inputBar.textView endEditing:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self endEditingMessageIfNeeded];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.ephemeralIndicatorButton.layer.cornerRadius = CGRectGetWidth(self.ephemeralIndicatorButton.bounds) / 2;
}

- (void)createSingleTapGestureRecognizer
{
    self.singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    self.singleTapGestureRecognizer.enabled = NO;
    self.singleTapGestureRecognizer.delegate = self;
    self.singleTapGestureRecognizer.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.singleTapGestureRecognizer];
}

- (void)updateAvailabilityPlaceholder
{
    if (!ZMUser.selfUser.hasTeam || self.conversation.conversationType != ZMConversationTypeOneOnOne) {
        return;
    }

    self.inputBar.availabilityPlaceholder = [AvailabilityStringBuilder stringFor:self.conversation.connectedUser
                                                                                with:AvailabilityLabelStylePlaceholder
                                                                               color:self.inputBar.placeholderColor];
}

- (void)updateNewButtonTitleLabel
{
    self.photoButton.titleLabel.hidden = self.inputBar.textView.isFirstResponder;
}

- (void)updateLeftAccessoryView
{
    self.authorImageView.alpha = self.inputBar.textView.isFirstResponder ? 1 : 0;
}

- (void)updateRightAccessoryView
{
    [self updateEphemeralIndicatorButtonTitle:self.ephemeralIndicatorButton];
    
    NSString *trimmed = [self.inputBar.textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    [self.sendButtonState updateWithTextLength:trimmed.length
                                       editing:nil != self.editingMessage
                                   markingDown:self.inputBar.isMarkingDown
                            destructionTimeout:self.conversation.messageDestructionTimeoutValue
                              conversationType:self.conversation.conversationType
                                          mode:self.mode
               syncedMessageDestructionTimeout:self.conversation.hasSyncedMessageDestructionTimeout];

    self.sendButton.hidden = self.sendButtonState.sendButtonHidden;
    self.hourglassButton.hidden = self.sendButtonState.hourglassButtonHidden;
    self.ephemeralIndicatorButton.hidden = self.sendButtonState.ephemeralIndicatorButtonHidden;
    self.ephemeralIndicatorButton.enabled = self.sendButtonState.ephemeralIndicatorButtonEnabled;

    [self.ephemeralIndicatorButton setBackgroundImage:self.conversation.timeoutImage forState:UIControlStateNormal];
    [self.ephemeralIndicatorButton setBackgroundImage:self.conversation.disabledTimeoutImage
                                             forState:UIControlStateDisabled];
}

- (void)updateButtonIcons
{
    [self.audioButton setIcon:WRStyleKitIconMicrophone
                     withSize:16
                     forState:UIControlStateNormal];
    
    [self.videoButton setIcon:WRStyleKitIconVideoMessage
                     withSize:16
                     forState:UIControlStateNormal];
    
    [self.photoButton setIcon:WRStyleKitIconCameraLens
                     withSize:16
                     forState:UIControlStateNormal];
    
    [self.uploadFileButton setIcon:WRStyleKitIconPaperclip
                          withSize:16
                          forState:UIControlStateNormal];
    
    [self.sketchButton setIcon:WRStyleKitIconBrush
                      withSize:16
                      forState:UIControlStateNormal];
    
    [self.pingButton setIcon:WRStyleKitIconPing
                    withSize:16
                    forState:UIControlStateNormal];
    
    [self.locationButton setIcon:WRStyleKitIconLocationPin
                        withSize:16
                        forState:UIControlStateNormal];
    
    [self.gifButton setIcon:WRStyleKitIconGif
                   withSize:16
                   forState:UIControlStateNormal];

    [self.mentionButton setIcon:WRStyleKitIconMention
                   withSize:16
                   forState:UIControlStateNormal];

    [self.sendButton setIcon:WRStyleKitIconSend
                    withSize:16
                    forState:UIControlStateNormal];
}

- (void)updateAccessoryViews
{
    [self updateLeftAccessoryView];
    [self updateRightAccessoryView];
}

- (void)clearInputBar
{
    self.inputBar.textView.text = @"";
    [self.inputBar.markdownView resetIcons];
    [self.inputBar.textView resetMarkdown];
    [self updateRightAccessoryView];
    [self.conversation setIsTyping:NO];
    [self.replyComposingView removeFromSuperview];
    self.replyComposingView = nil;
    self.quotedMessage = nil;
}

- (void)updateInputBarVisibility
{
    self.view.hidden = self.conversation.isReadOnly;
}

#pragma mark - Keyboard Shortcuts

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)commandReturnPressed
{
    [self sendText];
}

- (void)shiftReturnPressed
{
    [self.inputBar.textView replaceRange:self.inputBar.textView.selectedTextRange withText:@"\n"];
}

- (void)upArrowPressed
{
    if ([self.delegate respondsToSelector:@selector(conversationInputBarViewControllerEditLastMessage)]) {
        [self.delegate conversationInputBarViewControllerEditLastMessage];
    }
}

- (void)escapePressed
{
    [self endEditingMessageIfNeeded];
}

#pragma mark - Haptic Feedback

- (void)playInputHapticFeedback
{
    [self.impactFeedbackGenerator prepare];
    [self.impactFeedbackGenerator impactOccurred];
}

#pragma mark - Input views handling

- (void)onSingleTap:(UITapGestureRecognizer *)recognier
{
    if (recognier.state == UIGestureRecognizerStateRecognized) {
        self.mode = ConversationInputBarViewControllerModeTextInput;
    }
}

- (void)setMode:(ConversationInputBarViewControllerMode)mode
{
    if (_mode == mode) {
        return;
    }
    _mode = mode;
    
    switch (mode) {
        case ConversationInputBarViewControllerModeTextInput:
            self.inputController = nil;
            self.singleTapGestureRecognizer.enabled = NO;
            [self selectInputControllerButton:nil];
            break;
    
        case ConversationInputBarViewControllerModeAudioRecord:
            [self clearTextInputAssistentItemIfNeeded];
            
            if (self.inputController == nil || self.inputController != self.audioRecordKeyboardViewController) {
                if (self.audioRecordKeyboardViewController == nil) {
                    self.audioRecordKeyboardViewController = [[AudioRecordKeyboardViewController alloc] init];
                    self.audioRecordKeyboardViewController.delegate = self;
                }

                self.inputController = self.audioRecordKeyboardViewController;
            }

            self.singleTapGestureRecognizer.enabled = YES;
            [self selectInputControllerButton:self.audioButton];
            break;
            
        case ConversationInputBarViewControllerModeCamera:
            [self clearTextInputAssistentItemIfNeeded];
            
            if (self.inputController == nil || self.inputController != self.cameraKeyboardViewController) {
                if (self.cameraKeyboardViewController == nil) {
                    [self createCameraKeyboardViewController];
                }

                self.inputController = self.cameraKeyboardViewController;
            }
            
            self.singleTapGestureRecognizer.enabled = YES;
            [self selectInputControllerButton:self.photoButton];
            break;

        case ConversationInputBarViewControllerModeTimeoutConfguration:
            [self clearTextInputAssistentItemIfNeeded];

            if (self.inputController == nil || self.inputController != self.ephemeralKeyboardViewController) {
                if (self.ephemeralKeyboardViewController == nil) {
                    [self createEphemeralKeyboardViewController];
                }

                self.inputController = self.ephemeralKeyboardViewController;
            }

            self.singleTapGestureRecognizer.enabled = YES;
            [self selectInputControllerButton:self.hourglassButton];
            break;


    }
    
    [self updateRightAccessoryView];
}

- (void)selectInputControllerButton:(IconButton *)button
{
    for (IconButton *otherButton in @[self.photoButton, self.audioButton, self.hourglassButton]) {
        otherButton.selected = [button isEqual:otherButton];
    }
}

- (void)clearTextInputAssistentItemIfNeeded
{
    if (nil != [UITextInputAssistantItem class]) {
        UITextInputAssistantItem *item = self.inputBar.textView.inputAssistantItem;
        item.leadingBarButtonGroups = @[];
        item.trailingBarButtonGroups = @[];
    }
}

- (void)setInputController:(UIViewController *)inputController
{
    [_inputController.view removeFromSuperview];
    
    _inputController = inputController;
    [self deallocateUnusedInputControllers];

    
    if (inputController != nil) {
        CGSize inputViewSize = [UIView wr_lastKeyboardSize];

        CGRect inputViewFrame = (CGRect) {CGPointZero, inputViewSize};
        UIInputView *inputView = [[UIInputView alloc] initWithFrame:inputViewFrame
                                                     inputViewStyle:UIInputViewStyleKeyboard];
        if (@selector(allowsSelfSizing) != nil && [inputView respondsToSelector:@selector(allowsSelfSizing)]) {
            inputView.allowsSelfSizing = YES;
        }

        inputView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputController.view.frame = inputView.frame;
        inputController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [inputView addSubview:inputController.view];

        self.inputBar.textView.inputView = inputView;
    }
    else {
        self.inputBar.textView.inputView = nil;
    }
    
    [self.inputBar.textView reloadInputViews];
}

- (void)deallocateUnusedInputControllers
{
    if (! [self.cameraKeyboardViewController isEqual:self.inputController]) {
        self.cameraKeyboardViewController = nil;
    }
    if (! [self.audioRecordKeyboardViewController isEqual:self.inputController]) {
        self.audioRecordKeyboardViewController = nil;
    }
    if (! [self.ephemeralKeyboardViewController isEqual:self.inputController]) {
        self.ephemeralKeyboardViewController = nil;
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    if (!self.inRotation && !self.audioRecordKeyboardViewController.isRecording) {
        self.mode = ConversationInputBarViewControllerModeTextInput;
    }
}

#pragma mark - Animations

- (void)bounceCameraIcon;
{
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1.3, 1.3);
    
    dispatch_block_t scaleUp = ^{
        self.photoButton.transform = scaleTransform;
    };
    
    dispatch_block_t scaleDown = ^{
        self.photoButton.transform = CGAffineTransformIdentity;
    };

    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:scaleUp completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.6 options:UIViewAnimationOptionCurveEaseOut animations:scaleDown completion:nil];
    }];
}

@end


@implementation ConversationInputBarViewController(TextViewProtocol)
#pragma mark - Informal TextView delegate methods

- (void)textView:(UITextView *)textView hasImageToPaste:(id<MediaAsset>)image
{
    ConfirmAssetViewController *confirmImageViewController = [[ConfirmAssetViewController alloc] init];
    confirmImageViewController.image = image;
    confirmImageViewController.previewTitle = [self.conversation.displayName uppercasedWithCurrentLocale];
    
    ZM_WEAK(self);
    
    confirmImageViewController.onConfirm = ^(UIImage *editedImage){
        ZM_STRONG(self);
        [self dismissViewControllerAnimated:NO completion:nil];
        id<MediaAsset> finalImage = editedImage == nil ? image : editedImage;
        [self postImage:finalImage];
    };
    
    confirmImageViewController.onCancel = ^() {
        ZM_STRONG(self);
        [self dismissViewControllerAnimated:NO completion:nil];
    };
    
    [self presentViewController:confirmImageViewController animated:NO completion:nil];
}

- (void)textView:(UITextView *)textView firstResponderChanged:(NSNumber *)resigned
{
    [self updateAccessoryViews];
    [self updateNewButtonTitleLabel];
}

- (void)postImage:(id<MediaAsset>)image
{
    [self.sendController sendMessageWithImageData:image.data completion:^() {}];
}

@end

@interface ZMAssetMetaDataEncoder (Test)

+ (CGSize)imageSizeForImageData:(NSData *)imageData;

@end

@implementation ConversationInputBarViewController (Sketch)

- (void)sketchButtonPressed:(id)sender
{
    [self.inputBar.textView resignFirstResponder];
    
    CanvasViewController *viewController = [[CanvasViewController alloc] init];
    viewController.delegate = self;
    viewController.title = self.conversation.displayName.uppercaseString;
    
    [self.parentViewController presentViewController:[viewController wrapInNavigationController] animated:YES completion:nil];
}

@end

@implementation ConversationInputBarViewController (Location)

- (void)locationSelectionViewController:(LocationSelectionViewController *)viewController didSelectLocationWithData:(ZMLocationData *)locationData
{
    [ZMUserSession.sharedSession enqueueChanges:^{
        [self.conversation appendMessageWithLocationData:locationData];
        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionLocation inConversation:self.conversation];
    }];
    
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)locationSelectionViewControllerDidCancel:(LocationSelectionViewController *)viewController
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end


@implementation ConversationInputBarViewController (Giphy)

- (void)giphyButtonPressed:(id)sender
{
    if (![AppDelegate isOffline]) {
        
        GiphySearchViewController *giphySearchViewController = [[GiphySearchViewController alloc] initWithSearchTerm:@"" conversation:self.conversation];
        giphySearchViewController.delegate = self;
        [[ZClientViewController sharedZClientViewController] presentViewController:[giphySearchViewController wrapInsideNavigationController] animated:YES completion:^{
            [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
        }];
    }
}

@end



#pragma mark - SendButton

@implementation ConversationInputBarViewController (Sending)

- (void)sendButtonPressed:(id)sender
{
    [self.inputBar.textView autocorrectLastWord];
    [self sendText];
}

@end



#pragma mark - PingButton

@implementation ConversationInputBarViewController (Ping)

- (void)pingButtonPressed:(UIButton *)button
{
    [self appendKnock];
}

- (void)appendKnock
{
    [self.notificationFeedbackGenerator prepare];
    [[ZMUserSession sharedSession] enqueueChanges:^{
        id<ZMConversationMessage> knockMessage = [self.conversation appendKnock];
        if (knockMessage) {
            [Analytics.shared tagMediaActionCompleted:ConversationMediaActionPing inConversation:self.conversation];

            [AVSMediaManager.sharedInstance playKnockSound];
            [self.notificationFeedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
        }
    }];
    
    self.pingButton.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.pingButton.enabled = YES;
    });
}

@end


@implementation ConversationInputBarViewController (ZMConversationObserver)

- (void)conversationDidChange:(ConversationChangeInfo *)change
{    
    if (change.participantsChanged || change.connectionStateChanged) {
        [self updateInputBarVisibility];
    }
    
    if (change.destructionTimeoutChanged) {
        [self updateAccessoryViews];
        [self updateInputBar];
    }
}

@end

@implementation ConversationInputBarViewController (ZMUserObserver)

- (void)userDidChange:(UserChangeInfo *)changeInfo
{
    if (changeInfo.availabilityChanged) {
        [self updateAvailabilityPlaceholder];
    }
}

@end


@implementation ConversationInputBarViewController (ZMTypingChangeObserver)

- (void)typingDidChangeWithConversation:(ZMConversation *)conversation typingUsers:(NSArray<id<UserType>> *)typingUsers
{
    [self updateTypingIndicator];
}

@end


@implementation ConversationInputBarViewController (UIGestureRecognizerDelegate)

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.singleTapGestureRecognizer == gestureRecognizer || self.singleTapGestureRecognizer == otherGestureRecognizer) {
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    if (self.singleTapGestureRecognizer == gestureRecognizer) {
        return YES;
    }
    else {
        return CGRectContainsPoint(gestureRecognizer.view.bounds, [touch locationInView:gestureRecognizer.view]);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}

@end

@implementation ConversationInputBarViewController (GiphySearchViewControllerDelegate)

- (void)giphySearchViewController:(GiphySearchViewController *)giphySearchViewController didSelectImageData:(NSData *)imageData searchTerm:(NSString *)searchTerm
{
    [self clearInputBar];
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *messageText = nil;
        
        if ([searchTerm isEqualToString:@""]) {
            messageText = [NSString stringWithFormat:NSLocalizedString(@"giphy.conversation.random_message", nil), searchTerm];
        } else {
            messageText = [NSString stringWithFormat:NSLocalizedString(@"giphy.conversation.message", nil), searchTerm];
        }
        
        [self.sendController sendTextMessage:messageText mentions:@[] withImageData:imageData];
    }];
}

@end
