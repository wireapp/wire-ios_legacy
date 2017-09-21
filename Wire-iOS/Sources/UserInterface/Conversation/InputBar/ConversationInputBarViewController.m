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


@import PureLayout;
@import MobileCoreServices;
@import AVFoundation;

#import "ConversationInputBarViewController.h"
#import "ConversationInputBarViewController+Private.h"
#import "ConversationInputBarViewController+Files.h"
#import "Analytics+Events.h"
@import WireExtensionComponents;
#import "ConfirmAssetViewController.h"
#import "TextView.h"
#import "CameraViewController.h"
#import "UIView+Borders.h"
#import "UIViewController+Errors.h"

#import "ZClientViewController.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker+Sketchpad.h"
#import "AnalyticsTracker+FileTransfer.h"
#import "Wire-Swift.h"

#import "WireSyncEngine+iOS.h"
#import "ZMUser+Additions.h"
#import "avs+iOS.h"
#import "Constants.h"
#import "Settings.h"
#import "GiphyViewController.h"
#import "ConversationInputBarSendController.h"
@import FLAnimatedImage;
#import "MediaAsset.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "UIView+Borders.h"
#import "ImageMessageCell.h"
#import "WAZUIMagic.h"


@interface ConversationInputBarViewController (Commands)

- (void)runCommand:(NSArray *)args;

@end



@interface ConversationInputBarViewController (CameraViewController)
- (void)cameraButtonPressed:(id)sender;
- (void)videoButtonPressed:(id)sender;
@end

@interface ConversationInputBarViewController (Ping)

- (void)pingButtonPressed:(UIButton *)button;

@end

@interface ConversationInputBarViewController (Location) <LocationSelectionViewControllerDelegate>

- (void)locationButtonPressed:(IconButton *)sender;

@end

@interface ConversationInputBarViewController (ZMConversationObserver) <ZMConversationObserver>
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

@property (nonatomic) IconButton *audioButton;
@property (nonatomic) IconButton *videoButton;
@property (nonatomic) IconButton *photoButton;
@property (nonatomic) IconButton *uploadFileButton;
@property (nonatomic) IconButton *sketchButton;
@property (nonatomic) IconButton *pingButton;
@property (nonatomic) IconButton *locationButton;
@property (nonatomic) IconButton *sendButton;
@property (nonatomic) IconButton *ephemeralIndicatorButton;
@property (nonatomic) IconButton *emojiButton;
@property (nonatomic) IconButton *markdownButton;
@property (nonatomic) IconButton *gifButton;
@property (nonatomic) IconButton *hourglassButton;

@property (nonatomic) UIGestureRecognizer *singleTapGestureRecognizer;

@property (nonatomic) UserImageView *authorImageView;
@property (nonatomic) TypingIndicatorView *typingIndicatorView;

@property (nonatomic) InputBar *inputBar;
@property (nonatomic) ZMConversation *conversation;

@property (nonatomic) NSSet *typingUsers;
@property (nonatomic) id conversationObserverToken;

@property (nonatomic) UIViewController *inputController;

@property (nonatomic) BOOL inRotation;

@property (nonatomic) id typingObserverToken;
@end


@implementation ConversationInputBarViewController

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.sendController = [[ConversationInputBarSendController alloc] initWithConversation:self.conversation];
        self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
        self.sendButtonState = [[ConversationInputBarButtonState alloc] init];
        self.typingObserverToken = [conversation addTypingObserver:self];
        self.typingUsers = conversation.typingUsers;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    [self createSingleTapGestureRecognizer];
    
    [self createInputBar]; // Creates all input bar buttons
    [self createSendButton];
    [self createEphemeralIndicatorButton];
//    [self createEmojiButton];
    [self createMarkdownButton];

    [self createHourglassButton];
    [self createTypingIndicatorView];
    
    if (self.conversation.hasDraftMessageText) {
        self.inputBar.textView.text = self.conversation.draftMessageText;
    }
    
    [self configureAudioButton:self.audioButton];
    [self configureEmojiButton:self.emojiButton];
    [self configureMarkdownButton];
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
    
    if (self.conversationObserverToken == nil) {
        self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
    }
    
    [self updateAccessoryViews];
    [self updateInputBarVisibility];
    [self updateTypingIndicatorVisibility];
    [self updateWritingStateAnimated:NO];
    [self updateButtonIconsForEphemeral];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateRightAccessoryView];
    [self updateButtonIconsForEphemeral];
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.inRotation = YES;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.inRotation = NO;
    }];
}

- (void)setAnalyticsTracker:(AnalyticsTracker *)analyticsTracker
{
    _analyticsTracker = analyticsTracker;
    self.sendController.analyticsTracker = analyticsTracker;
}

- (void)createInputBar
{
    self.audioButton = [[IconButton alloc] init];
    self.audioButton.hitAreaPadding = CGSizeZero;
    self.audioButton.accessibilityIdentifier = @"audioButton";
    [self.audioButton setIconColor:[UIColor accentColor] forState:UIControlStateSelected];

    self.videoButton = [[IconButton alloc] init];
    self.videoButton.hitAreaPadding = CGSizeZero;
    self.videoButton.accessibilityIdentifier = @"videoButton";
    
    self.photoButton = [[IconButton alloc] init];
    self.photoButton.hitAreaPadding = CGSizeZero;
    self.photoButton.accessibilityIdentifier = @"photoButton";
    [self.photoButton setIconColor:[UIColor accentColor] forState:UIControlStateSelected];

    self.uploadFileButton = [[IconButton alloc] init];
    self.uploadFileButton.hitAreaPadding = CGSizeZero;
    self.uploadFileButton.accessibilityIdentifier = @"uploadFileButton";
    
    self.sketchButton = [[IconButton alloc] init];
    self.sketchButton.hitAreaPadding = CGSizeZero;
    self.sketchButton.accessibilityIdentifier = @"sketchButton";
    
    self.pingButton = [[IconButton alloc] init];
    self.pingButton.hitAreaPadding = CGSizeZero;
    self.pingButton.accessibilityIdentifier = @"pingButton";
    
    self.locationButton = [[IconButton alloc] init];
    self.locationButton.hitAreaPadding = CGSizeZero;
    self.locationButton.accessibilityIdentifier = @"locationButton";
    
    self.gifButton = [[IconButton alloc] init];
    self.gifButton.hitAreaPadding = CGSizeZero;
    self.gifButton.accessibilityIdentifier = @"gifButton";
    
    self.inputBar = [[InputBar alloc] initWithButtons:@[self.photoButton, self.videoButton, self.sketchButton, self.gifButton, self.audioButton, self.pingButton, self.uploadFileButton, self.locationButton]];
    self.inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputBar.textView.delegate = self;
    
    [self.view addSubview:self.inputBar];
    [self.inputBar autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.inputBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    }];
    self.inputBar.editingView.delegate = self;
}

- (void)createSingleTapGestureRecognizer
{
    self.singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    self.singleTapGestureRecognizer.enabled = NO;
    self.singleTapGestureRecognizer.delegate = self;
    self.singleTapGestureRecognizer.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.singleTapGestureRecognizer];
}

- (void)createAudioRecordViewController
{
    self.audioRecordViewController = [[AudioRecordViewController alloc] init];
    self.audioRecordViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.audioRecordViewController.view.hidden = true;
    self.audioRecordViewController.delegate = self;
    
    [self addChildViewController:self.audioRecordViewController];
    [self.inputBar addSubview:self.audioRecordViewController.view];
    [self.audioRecordViewController.view autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.inputBar.buttonContainer];
    
    CGRect recordButtonFrame = [self.inputBar convertRect:self.audioButton.bounds fromView:self.audioButton];
    CGFloat width = CGRectGetMaxX(recordButtonFrame) + 56;
    [self.audioRecordViewController.view autoSetDimension:ALDimensionWidth toSize:width];
    [self.audioRecordViewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.audioRecordViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.inputBar withOffset:0.5];
}

- (void)createSendButton
{
    self.sendButton = [IconButton iconButtonDefault];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.sendButton.accessibilityIdentifier = @"sendButton";
    self.sendButton.adjustsImageWhenHighlighted = NO;
    self.sendButton.adjustBackgroundImageWhenHighlighted = YES;
    self.sendButton.cas_styleClass = @"send-button";
    self.sendButton.hitAreaPadding = CGSizeMake(30, 30);

    [self.inputBar.rightAccessoryView addSubview:self.sendButton];
    CGFloat edgeLength = 28;
    [self.sendButton autoSetDimensionsToSize:CGSizeMake(edgeLength, edgeLength)];
    [self.sendButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.sendButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:14];
    CGFloat rightInset = ([WAZUIMagic cgFloatForIdentifier:@"content.left_margin"] - edgeLength) / 2;
    [self.sendButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:rightInset relation:NSLayoutRelationGreaterThanOrEqual];
}

- (void)createEphemeralIndicatorButton
{
    self.ephemeralIndicatorButton = [[IconButton alloc] initForAutoLayout];
    self.ephemeralIndicatorButton.layer.borderWidth = 0.5;

    self.ephemeralIndicatorButton.accessibilityIdentifier = @"ephemeralTimeIndicatorButton";
    self.ephemeralIndicatorButton.adjustsTitleWhenHighlighted = YES;
    self.ephemeralIndicatorButton.adjustsBorderColorWhenHighlighted = YES;

    [self.inputBar.rightAccessoryView addSubview:self.ephemeralIndicatorButton];

    [self.ephemeralIndicatorButton autoSetDimensionsToSize:CGSizeMake(32, 32)];
    [self.ephemeralIndicatorButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.sendButton];
    [self.ephemeralIndicatorButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.sendButton];

    [self updateEphemeralIndicatorButtonTitle:self.ephemeralIndicatorButton];
}

- (void)createEmojiButton
{
    const CGFloat senderDiameter = 28;
    
    self.emojiButton = IconButton.iconButtonCircular;
    self.emojiButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.emojiButton.accessibilityIdentifier = @"emojiButton";

    [self.inputBar.leftAccessoryView addSubview:self.emojiButton];
    [self.emojiButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.emojiButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:14];
    [self.emojiButton autoSetDimensionsToSize:CGSizeMake(senderDiameter, senderDiameter)];
}

- (void)createMarkdownButton
{
    const CGFloat senderDiameter = 28;
    
    self.markdownButton = IconButton.iconButtonCircular;
    self.markdownButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.markdownButton.accessibilityIdentifier = @"markdownButton";
    [self.inputBar.leftAccessoryView addSubview:self.markdownButton];
    [self.markdownButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.markdownButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:14];
    [self.markdownButton autoSetDimensionsToSize:CGSizeMake(senderDiameter, senderDiameter)];
}

- (void)createHourglassButton
{
    self.hourglassButton = IconButton.iconButtonDefault;
    self.hourglassButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.hourglassButton setIcon:ZetaIconTypeHourglass withSize:ZetaIconSizeTiny forState:UIControlStateNormal];

    self.hourglassButton.accessibilityIdentifier = @"ephemeralTimeSelectionButton";
    self.hourglassButton.cas_styleClass = @"hourglass";
    [self.inputBar.rightAccessoryView addSubview:self.hourglassButton];

    [self.hourglassButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.sendButton];
    [self.hourglassButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.sendButton withOffset:0];
    [self.hourglassButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.sendButton withOffset:0];
}

- (void)createTypingIndicatorView
{
    self.typingIndicatorView = [[TypingIndicatorView alloc] init];
    self.typingIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.typingIndicatorView.accessibilityIdentifier = @"typingIndicator";
    self.typingIndicatorView.typingUsers = self.typingUsers.allObjects;
    [self.typingIndicatorView setHidden:YES animated:NO];
    
    [self.inputBar  addSubview:self.typingIndicatorView];
    [self.typingIndicatorView  autoConstrainAttribute:(ALAttribute)ALAxisHorizontal toAttribute:ALAttributeTop ofView:self.inputBar];
    [self.typingIndicatorView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.typingIndicatorView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:48 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.typingIndicatorView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:48 relation:NSLayoutRelationGreaterThanOrEqual];
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
    
    NSString *trimmed = [self.inputBar.textView.preparedText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    [self.sendButtonState updateWithTextLength:trimmed.length
                                       editing:nil != self.editingMessage
                                   markingDown:self.inputBar.isMarkingDown
                            destructionTimeout:self.conversation.messageDestructionTimeout
                              conversationType:self.conversation.conversationType
                                          mode:self.mode];

    self.sendButton.hidden = self.sendButtonState.sendButtonHidden;
    self.hourglassButton.hidden = self.sendButtonState.hourglassButtonHidden;
    self.ephemeralIndicatorButton.hidden = self.sendButtonState.ephemeralIndicatorButtonHidden;

    [self.ephemeralIndicatorButton setBackgroundImage:self.conversation.timeoutImage forState:UIControlStateNormal];
}

- (void)updateButtonIconsForEphemeral
{
    [self.audioButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypeMicrophoneEphemeral : ZetaIconTypeMicrophone
                     withSize:ZetaIconSizeTiny
                     forState:UIControlStateNormal];
    
    [self.videoButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypeVideoMessageEphemeral : ZetaIconTypeVideoMessage
                     withSize:ZetaIconSizeTiny
                     forState:UIControlStateNormal];
    
    [self.photoButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypeCameraLensEphemeral : ZetaIconTypeCameraLens
                     withSize:ZetaIconSizeTiny
                     forState:UIControlStateNormal];
    
    [self.uploadFileButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypePaperclipEphemeral : ZetaIconTypePaperclip
                          withSize:ZetaIconSizeTiny
                          forState:UIControlStateNormal];
    
    [self.sketchButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypeBrushEphemeral : ZetaIconTypeBrush
                      withSize:ZetaIconSizeTiny
                      forState:UIControlStateNormal];
    
    [self.pingButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypePingEphemeral : ZetaIconTypePing
                    withSize:ZetaIconSizeTiny
                    forState:UIControlStateNormal];
    
    [self.locationButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypeLocationPinEphemeral : ZetaIconTypeLocationPin
                        withSize:ZetaIconSizeTiny
                        forState:UIControlStateNormal];
    
    [self.gifButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypeGifEphemeral : ZetaIconTypeGif
                   withSize:ZetaIconSizeTiny
                   forState:UIControlStateNormal];
 
    [self.sendButton setIcon:self.sendButtonState.ephemeral ? ZetaIconTypeSendEphemeral : ZetaIconTypeSend
                    withSize:ZetaIconSizeTiny
                    forState:UIControlStateNormal];
    
    [self updateEmojiButton:self.emojiButton];
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
    [self updateRightAccessoryView];
    [self.conversation setIsTyping:NO];
}

- (void)setInputBarOverlapsContent:(BOOL)inputBarOverlapsContent
{
    _inputBarOverlapsContent = inputBarOverlapsContent;
}

- (void)setTypingUsers:(NSSet *)typingUsers
{
    _typingUsers = typingUsers;
    
    [self updateTypingIndicatorVisibility];
}

- (void)updateTypingIndicatorVisibility
{
    if (self.typingUsers.count > 0) {
        self.typingIndicatorView.typingUsers = self.typingUsers.allObjects;
        [self.typingIndicatorView layoutIfNeeded];
    }
    
    [self.typingIndicatorView setHidden:self.typingUsers.count == 0 animated: true];
}

- (void)updateInputBarVisibility
{
    self.view.hidden = self.conversation.isReadOnly;
}

#pragma mark - Keyboard Shortcuts

- (NSArray<UIKeyCommand *> *)keyCommands
{
    return @[
             [UIKeyCommand keyCommandWithInput:@"\r"
                                 modifierFlags:UIKeyModifierCommand
                                        action:@selector(commandReturnPressed)
                          discoverabilityTitle:NSLocalizedString(@"conversation.input_bar.shortcut.send", nil)]
             ];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)commandReturnPressed
{
    NSString *candidateText = self.inputBar.textView.preparedText;
    if (nil != candidateText) {
        [self sendOrEditText:candidateText];
    }
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
            [Analytics.shared tagMediaAction:ConversationMediaActionAudioMessage inConversation:self.conversation];

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
            
        case ConversationInputBarViewControllerModeEmojiInput:
            [self clearTextInputAssistentItemIfNeeded];
            
            if (self.inputController == nil || self.inputController != self.emojiKeyboardViewController) {
                if (self.emojiKeyboardViewController == nil) {
                    [self createEmojiKeyboardViewController];
                }
                
                self.inputController = self.emojiKeyboardViewController;
            }

            self.singleTapGestureRecognizer.enabled = NO;
            [self selectInputControllerButton:self.emojiButton];
            [Analytics.shared tagEmojiKeyboardOpenend:self.conversation];
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
    [self updateButtonIconsForEphemeral];
}

- (void)selectInputControllerButton:(IconButton *)button
{
    for (IconButton *otherButton in @[self.photoButton, self.audioButton, self.hourglassButton]) {
        otherButton.selected = [button isEqual:otherButton];
    }

    [self updateEmojiButton:self.emojiButton];
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
    if (! [self.emojiKeyboardViewController isEqual:self.inputController]) {
        self.emojiKeyboardViewController = nil;
    }
    if (! [self.ephemeralKeyboardViewController isEqual:self.inputController]) {
        self.ephemeralKeyboardViewController = nil;
    }
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    if (!self.inRotation) {
        self.mode = ConversationInputBarViewControllerModeTextInput;
    }
}

- (void)sendOrEditText:(NSString *)text
{
    NSString *candidateText = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL conversationWasNotDeleted = self.conversation.managedObjectContext != nil;
    
    if (self.inputBar.isEditing && nil != self.editingMessage) {
        NSString *previousText = [self.editingMessage.textMessageData.messageText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (![candidateText isEqualToString:previousText]) {
            [self sendEditedMessageAndUpdateStateWithText:candidateText];
        }
        
        return;
    }
    
    if (candidateText.length && conversationWasNotDeleted) {
        
        [self clearInputBar];
        
        NSArray *args = candidateText.args;
        if(args.count > 0) {
            [self runCommand:args];
        }
        else {
            [self.sendController sendTextMessage:candidateText];
        }
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

#pragma mark - Categories

@implementation ConversationInputBarViewController (UITextViewDelegate)

- (void)textViewDidChange:(UITextView *)textView
{
    // In case the conversation isDeleted
    if (self.conversation.managedObjectContext == nil)  {
        return;
    }
    
    if (textView.text.length > 0) {
        [self.conversation setIsTyping:YES];
    }
    else {
        [self.conversation setIsTyping:NO];
    }
    
    [self updateRightAccessoryView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // markdown text view needs to detect newlines
    // in order to automatically insert new list items
    if ([text isEqualToString:@"\n"] || [text isEqualToString:@"\r"]) {
        [self.inputBar.textView handleNewLine];
    }
    
    // send only if send key pressed
    if (textView.returnKeyType == UIReturnKeySend && [text isEqualToString:@"\n"]) {
        [self.inputBar.textView autocorrectLastWord];
        NSString *candidateText = self.inputBar.textView.preparedText;
        [self sendOrEditText:candidateText];
        return NO;
    }
    
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (self.mode == ConversationInputBarViewControllerModeAudioRecord) {
        return YES;
    }
    else if ([self.delegate respondsToSelector:@selector(conversationInputBarViewControllerShouldBeginEditing:isEditingMessage:)]) {
        return [self.delegate conversationInputBarViewControllerShouldBeginEditing:self isEditingMessage:(nil != self.editingMessage)];
    }
    else {
        return YES;
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self updateAccessoryViews];
    [self updateNewButtonTitleLabel];
    [AppDelegate checkNetworkAndFlashIndicatorIfNecessary];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(conversationInputBarViewControllerShouldEndEditing:)]) {
        return [self.delegate conversationInputBarViewControllerShouldEndEditing:self];
    }

    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView.text.length > 0) {
        [self.conversation setIsTyping:NO];
    }
    [[ZMUserSession sharedSession] enqueueChanges:^{
        self.conversation.draftMessageText = textView.text;
    }];
}

#pragma mark - Informal TextView delegate methods

- (void)textView:(UITextView *)textView hasImageToPaste:(id<MediaAsset>)image
{
    ConfirmAssetViewController *confirmImageViewController = [[ConfirmAssetViewController alloc] init];
    confirmImageViewController.image = image;
    confirmImageViewController.previewTitle = [self.conversation.displayName uppercasedWithCurrentLocale];
    
    @weakify(self);
    
    confirmImageViewController.onConfirm = ^(UIImage *editedImage){
        @strongify(self);
        [self dismissViewControllerAnimated:NO completion:nil];
        id<MediaAsset> finalImage = editedImage == nil ? image : editedImage;
        [self postImage:finalImage];
    };
    
    confirmImageViewController.onCancel = ^() {
        @strongify(self);
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.sendController sendMessageWithImageData:image.data completion:^() {
            [[Analytics shared] tagMediaSentPictureSourceOtherInConversation:self.conversation source:ConversationMediaPictureSourcePaste];
        }];
    });
}

@end


@implementation ConversationInputBarViewController (CameraViewController)

- (void)cameraButtonPressed:(id)sender
{
    if (self.mode == ConversationInputBarViewControllerModeCamera) {
        [self.inputBar.textView resignFirstResponder];
        self.cameraKeyboardViewController = nil;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.mode = ConversationInputBarViewControllerModeTextInput;
        });
    }
    else {
        [UIApplication wr_requestOrWarnAboutVideoAccess:^(BOOL granted) {
            [self executeWithCameraRollPermission:^(BOOL success){
                self.mode = ConversationInputBarViewControllerModeCamera;
                [self.inputBar.textView becomeFirstResponder];
            }];
        }];
    }
}

- (void)videoButtonPressed:(IconButton *)sender
{
    [Analytics.shared tagMediaAction:ConversationMediaActionVideoMessage inConversation:self.conversation];
    self.videoSendContext = ConversationMediaVideoContextCursorButton;
    [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera mediaTypes:@[(id)kUTTypeMovie] allowsEditing:false];
}

#pragma mark - Video save callback

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (nil != error) {
        DDLogError(@"Error saving video: %@", error);
    }
}

@end

@interface ZMAssetMetaDataEncoder (Test)

+ (CGSize)imageSizeForImageData:(NSData *)imageData;

@end

@implementation ConversationInputBarViewController (Sketch)

- (void)sketchButtonPressed:(id)sender
{
    [self.inputBar.textView resignFirstResponder];
    [Analytics.shared tagMediaAction:ConversationMediaActionSketch inConversation:self.conversation];
    
    CanvasViewController *viewController = [[CanvasViewController alloc] init];
    viewController.delegate = self;
    viewController.title = self.conversation.displayName.uppercaseString;
    viewController.source = ConversationMediaSketchSourceSketchButton;
    
    [self.parentViewController presentViewController:[viewController wrapInNavigationController] animated:YES completion:nil];
}

@end

@implementation ConversationInputBarViewController (Location)

- (void)locationButtonPressed:(IconButton *)sender
{
    [[Analytics shared] tagMediaAction:ConversationMediaActionLocation inConversation:self.conversation];
    
    LocationSelectionViewController *locationSelectionViewController = [[LocationSelectionViewController alloc] initForPopoverPresentation:IS_IPAD];
    locationSelectionViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController* popoverPresentationController = locationSelectionViewController.popoverPresentationController;
    popoverPresentationController.sourceView = sender.superview;
    popoverPresentationController.sourceRect = sender.frame;
    locationSelectionViewController.title = self.conversation.displayName;
    locationSelectionViewController.delegate = self;
    [self.parentViewController presentViewController:locationSelectionViewController animated:YES completion:nil];
}

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
    if (![AppDelegate checkNetworkAndFlashIndicatorIfNecessary]) {
        
        [Analytics.shared tagMediaAction:ConversationMediaActionGif inConversation:self.conversation];
    
        NSString *searchTerm = [self.inputBar.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        GiphySearchViewController *giphySearchViewController = [[GiphySearchViewController alloc] initWithSearchTerm:searchTerm conversation:self.conversation];
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
    [self sendOrEditText:self.inputBar.textView.preparedText];
    [self.inputBar.textView resetTypingAttributes];
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
    [[ZMUserSession sharedSession] enqueueChanges:^{
        id<ZMConversationMessage> knockMessage = [self.conversation appendKnock];
        if (knockMessage) {
            [Analytics.shared tagMediaAction:ConversationMediaActionPing inConversation:self.conversation];
            [Analytics.shared tagMediaActionCompleted:ConversationMediaActionPing inConversation:self.conversation];
            
            [[[AVSProvider shared] mediaManager] playSound:MediaManagerSoundOutgoingKnockSound];
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
}

@end


@implementation ConversationInputBarViewController (Commands)

- (void)runCommand:(NSArray *)args
{
    if (args.count == 0) {
        return;
    }
    
    [self.sendController sendTextMessage:[NSString stringWithFormat:@"/%@", [args componentsJoinedByString:@" "]]];
}

@end


@implementation ConversationInputBarViewController (ZMTypingChangeObserver)

- (void)typingDidChangeWithConversation:(ZMConversation *)conversation typingUsers:(NSSet<ZMUser *> *)typingUsers
{
    NSPredicate *filterSelfUserPredicate = [NSPredicate predicateWithFormat:@"SELF != %@", [ZMUser selfUser]];
    NSSet *filteredSet = [typingUsers filteredSetUsingPredicate:filterSelfUserPredicate];
    
    self.typingUsers = filteredSet;
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

@end

@implementation ConversationInputBarViewController (GiphySearchViewControllerDelegate)

- (void)giphySearchViewController:(GiphySearchViewController *)giphySearchViewController didSelectImageData:(NSData *)imageData searchTerm:(NSString *)searchTerm
{
    [[Analytics shared] tagMediaSentPictureSourceOtherInConversation:self.conversation source:ConversationMediaPictureSourceGiphy];
    [self clearInputBar];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
    
    NSString *messageText = nil;
    
    if ([searchTerm isEqualToString:@""]) {
        messageText = [NSString stringWithFormat:NSLocalizedString(@"giphy.conversation.random_message", nil), searchTerm];
    } else {
        messageText = [NSString stringWithFormat:NSLocalizedString(@"giphy.conversation.message", nil), searchTerm];
    }
    
    [self.sendController sendTextMessage:messageText withImageData:imageData];
}

@end
