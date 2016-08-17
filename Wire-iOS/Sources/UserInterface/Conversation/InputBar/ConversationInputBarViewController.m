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


#import <AVFoundation/AVAudioSession.h>
#import <PureLayout.h>
@import MobileCoreServices;

#import "ConversationInputBarViewController.h"
#import "ConversationInputBarViewController+Private.h"
#import "ConversationInputBarViewController+Files.h"
#import "Analytics+Events.h"
#import "UIAlertView+Zeta.h"
#import <WireExtensionComponents/WireExtensionComponents.h>
#import "ConfirmAssetViewController.h"
#import "TextView.h"
#import "TypingConversationView.h"
#import "CameraViewController.h"
#import "SketchViewController.h"
#import "UIView+Borders.h"
#import "UIViewController+Errors.h"

#import "ZClientViewController.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker+Sketchpad.h"
#import "AnalyticsTracker+FileTransfer.h"
#import "NSString+Wire.h"


#import "ZMUserSession+Additions.h"
#import "zmessaging+iOS.h"
#import "ZMUser+Additions.h"
#import "avs+iOS.h"
#import "Constants.h"
#import "Settings.h"
#import "GiphyViewController.h"
#import "ConversationInputBarSendController.h"
#import "FLAnimatedImage.h"
#import "MediaAsset.h"
#import "Wire-Swift.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "UIView+Borders.h"

#import "Wire-Swift.h"


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

@interface ConversationInputBarViewController (VerifiedShield)

- (void)verifiedShieldButtonPressed:(UIButton *)sender;

@end

@interface ConversationInputBarViewController (Giphy)

- (void)giphyButtonPressed:(id)sender;

@end

@interface ConversationInputBarViewController (UITextViewDelegate) <UITextViewDelegate>

@end

@interface  ConversationInputBarViewController (UIGestureRecognizerDelegate) <UIGestureRecognizerDelegate>

@end



@interface ConversationInputBarViewController ()

@property (nonatomic) IconButton *audioButton;
@property (nonatomic) IconButton *videoButton;
@property (nonatomic) IconButton *photoButton;
@property (nonatomic) IconButton *uploadFileButton;
@property (nonatomic) IconButton *sketchButton;
@property (nonatomic) IconButton *pingButton;
@property (nonatomic) IconButton *locationButton;
@property (nonatomic) IconButton *gifButton;

@property (nonatomic) UIGestureRecognizer *singleTapGestureRecognizer;

@property (nonatomic) UserImageView *authorImageView;
@property (nonatomic) TypingConversationView *typingView;
@property (nonatomic) UIView *verifiedContainerView;
@property (nonatomic) UILabel *verifiedLabelView;
@property (nonatomic) ButtonWithLargerHitArea *verifiedShieldButton;
@property (nonatomic) NSLayoutConstraint *collapseViewConstraint;

@property (nonatomic) InputBar *inputBar;
@property (nonatomic) ZMConversation *conversation;

@property (nonatomic) NSSet *typingUsers;
@property (nonatomic) id <ZMConversationObserverOpaqueToken> conversationObserverToken;

@property (nonatomic) UIViewController *inputController;

@property (nonatomic) BOOL inRotation;
@end


@implementation ConversationInputBarViewController

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.sendController = [[ConversationInputBarSendController alloc] initWithConversation:self.conversation];
        self.conversationObserverToken = [self.conversation addConversationObserver:self];
        
        if ([self.conversation shouldDisplayIsTyping]) {
            [_conversation addTypingObserver:self];
            self.typingUsers = _conversation.typingUsers;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [ZMConversation removeConversationObserverForToken:self.conversationObserverToken];
    if ([self.conversation shouldDisplayIsTyping]) {
        [ZMConversation removeTypingObserver:self];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSingleTapGestureRecognizer];
    
    [self createInputBar];
    [self createGifButton];
    [self createVerifiedView];
    [self createAuthorImageView];
    [self createTypingView];
    
    if (self.conversation.hasDraftMessageText) {
        self.inputBar.textView.text = self.conversation.draftMessageText;
    }
    
    [self configureAudioButton:self.audioButton];
    
    [self.photoButton addTarget:self action:@selector(cameraButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoButton addTarget:self action:@selector(videoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.sketchButton addTarget:self action:@selector(sketchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.uploadFileButton addTarget:self action:@selector(docUploadPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.pingButton addTarget:self action:@selector(pingButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.gifButton addTarget:self action:@selector(giphyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.verifiedShieldButton addTarget:self action:@selector(verifiedShieldButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.locationButton addTarget:self action:@selector(locationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.conversationObserverToken == nil) {
        self.conversationObserverToken = [self.conversation addConversationObserver:self];
    }
    
    [self updateAccessoryViews];
    [self updateInputBarVisibility];
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
    [self.audioButton setIcon:ZetaIconTypeMicrophone withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.audioButton setIconColor:[UIColor accentColor] forState:UIControlStateSelected];

    self.videoButton = [[IconButton alloc] init];
    self.videoButton.hitAreaPadding = CGSizeZero;
    self.videoButton.accessibilityIdentifier = @"videoButton";
    [self.videoButton setIcon:ZetaIconTypeVideoMessage withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    
    self.photoButton = [[IconButton alloc] init];
    self.photoButton.hitAreaPadding = CGSizeZero;
    self.photoButton.accessibilityIdentifier = @"photoButton";
    [self.photoButton setIcon:ZetaIconTypeCameraLens withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.photoButton setIconColor:[UIColor accentColor] forState:UIControlStateSelected];

    self.uploadFileButton = [[IconButton alloc] init];
    self.uploadFileButton.hitAreaPadding = CGSizeZero;
    self.uploadFileButton.accessibilityIdentifier = @"uploadFileButton";
    [self.uploadFileButton setIcon:ZetaIconTypePaperclip withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    
    self.sketchButton = [[IconButton alloc] init];
    self.sketchButton.hitAreaPadding = CGSizeZero;
    self.sketchButton.accessibilityIdentifier = @"sketchButton";
    [self.sketchButton setIcon:ZetaIconTypeBrush withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    
    self.pingButton = [[IconButton alloc] init];
    self.pingButton.hitAreaPadding = CGSizeZero;
    self.pingButton.accessibilityIdentifier = @"pingButton";
    [self.pingButton setIcon:ZetaIconTypePing withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    
    self.locationButton = [[IconButton alloc] init];
    self.locationButton.hitAreaPadding = CGSizeZero;
    self.locationButton.accessibilityIdentifier = @"locationButton";
    [self.locationButton setIcon:ZetaIconTypeLocationPin withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    

    self.inputBar = [[InputBar alloc] initWithButtons:@[self.photoButton, self.videoButton, self.sketchButton, self.locationButton, self.audioButton, self.pingButton, self.uploadFileButton]];
    self.inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputBar.textView.delegate = self;
    
    [self.view addSubview:self.inputBar];
    [self.inputBar autoPinEdgesToSuperviewEdges];
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
    CGFloat width = CGRectGetMaxX(recordButtonFrame) + 60;
    [self.audioRecordViewController.view autoSetDimension:ALDimensionWidth toSize:width];
    [self.audioRecordViewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.audioRecordViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.inputBar withOffset:0.5];
}

- (void)createGifButton
{
    self.gifButton = [IconButton iconButtonCircular];
    self.gifButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.gifButton setIcon:ZetaIconTypeGif withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.gifButton.cas_styleClass = @"gif-button";
    self.gifButton.accessibilityIdentifier = @"gifButton";
    
    [self.inputBar.rightAccessoryView addSubview:self.gifButton];
    [self.gifButton autoSetDimensionsToSize:CGSizeMake(32, 32)];
    [self.gifButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(12, 0, 0, 0) excludingEdge:ALEdgeBottom];
}

- (void)createVerifiedView
{
    self.verifiedLabelView = [[UILabel alloc] initForAutoLayout];
    self.verifiedLabelView.cas_styleClass = @"conversationVerifiedLabel";
    self.verifiedLabelView.accessibilityIdentifier = @"verifiedConversationLabel";
    self.verifiedLabelView.text = NSLocalizedString(@"conversation.input_bar.verified", @"");
    self.verifiedLabelView.alpha = 0;
    [self.inputBar.rightAccessoryView addSubview:self.verifiedLabelView];
    
    self.verifiedShieldButton = [[ButtonWithLargerHitArea alloc] initForAutoLayout];
    self.verifiedShieldButton.accessibilityIdentifier = @"verifiedConversationIndicator";
    [self.verifiedShieldButton setImage:[WireStyleKit imageOfShieldverified] forState:UIControlStateNormal];
    [self.inputBar.rightAccessoryView addSubview:self.verifiedShieldButton];
    
    [self.verifiedLabelView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.verifiedShieldButton];
    [self.verifiedLabelView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.verifiedShieldButton withOffset:-12.0f];
    
    [self.verifiedShieldButton autoAlignAxis:ALAxisVertical toSameAxisOfView:self.gifButton];
    [self.verifiedShieldButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.gifButton];
}


- (void)createAuthorImageView
{
    const CGFloat senderDiameter = [WAZUIMagic floatForIdentifier:@"content.sender_image_tile_diameter"];
    
    self.authorImageView = [[UserImageView alloc] initWithMagicPrefix:@"content.author_image"];
    self.authorImageView.accessibilityIdentifier = @"authorImage";
    self.authorImageView.suggestedImageSize = UserImageViewSizeTiny;
    self.authorImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.authorImageView.userInteractionEnabled = NO;
    self.authorImageView.borderWidth = 0.0f;
    self.authorImageView.alpha = 0.0f;
    self.authorImageView.user = [ZMUser selfUser];
    [self.inputBar.leftAccessoryView addSubview:self.authorImageView];
    [self.authorImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.authorImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:14];
    [self.authorImageView autoSetDimensionsToSize:CGSizeMake(senderDiameter, senderDiameter)];
}

- (void)createTypingView
{
    self.typingView = [[TypingConversationView alloc] initForAutoLayout];
    self.typingView.userInteractionEnabled = NO;
    self.typingView.users = self.typingUsers;
    [self.inputBar.leftAccessoryView addSubview:self.typingView];
    [self.typingView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.typingView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:14];
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
    const NSUInteger textLength = self.inputBar.textView.text.length;
    self.gifButton.hidden = ! (textLength > 0 && textLength < 20) || self.inputBar.isEditing;
    self.verifiedShieldButton.hidden = self.conversation.securityLevel != ZMConversationSecurityLevelSecure || self.inputBar.textView.isFirstResponder || textLength > 0;
}

- (void)updateAccessoryViews
{
    [self updateLeftAccessoryView];
    [self updateRightAccessoryView];
}

- (void)clearInputBar
{
    self.inputBar.textView.text = @"";
    [self updateRightAccessoryView];
}

- (void)setTypingUsers:(NSSet *)typingUsers
{
    _typingUsers = typingUsers;
    self.typingView.users = typingUsers;
}

- (void)updateInputBarVisibility
{
    if (self.conversation.isReadOnly && self.inputBar.superview != nil) {
        [self.inputBar removeFromSuperview];
        self.collapseViewConstraint = [self.view autoSetDimension:ALDimensionHeight toSize:0];
    } else if (! self.conversation.isReadOnly && self.inputBar.superview == nil) {
        [self.view removeConstraint:self.collapseViewConstraint];
        [self.view addSubview:self.inputBar];
        [self.inputBar autoPinEdgesToSuperviewEdges];
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
            self.audioButton.selected = NO;
            self.photoButton.selected = NO;
            break;
    
        case ConversationInputBarViewControllerModeAudioRecord:
            if (nil != [UITextInputAssistantItem class]) {
                UITextInputAssistantItem* item = self.inputBar.textView.inputAssistantItem;
                item.leadingBarButtonGroups = @[];
                item.trailingBarButtonGroups = @[];
            }
            
            if (self.inputController == nil || self.inputController != self.audioRecordKeyboardViewController) {
                if (self.audioRecordKeyboardViewController == nil) {
                    self.audioRecordKeyboardViewController = [[AudioRecordKeyboardViewController alloc] init];
                    self.audioRecordKeyboardViewController.delegate = self;
                }
                self.cameraKeyboardViewController = nil;
                self.inputController = self.audioRecordKeyboardViewController;
            }
            [Analytics.shared tagMediaAction:ConversationMediaActionAudioMessage inConversation:self.conversation];

            self.singleTapGestureRecognizer.enabled = YES;
            self.audioButton.selected = YES;
            self.photoButton.selected = NO;
            break;
            
        case ConversationInputBarViewControllerModeCamera:
            if (nil != [UITextInputAssistantItem class]) {
                UITextInputAssistantItem* item = self.inputBar.textView.inputAssistantItem;
                item.leadingBarButtonGroups = @[];
                item.trailingBarButtonGroups = @[];
            }
            
            if (self.inputController == nil || self.inputController != self.cameraKeyboardViewController) {
                if (self.cameraKeyboardViewController == nil) {
                    [self createCameraKeyboardViewController];
                }
                self.audioRecordViewController = nil;
                self.inputController = self.cameraKeyboardViewController;
            }
            
            self.singleTapGestureRecognizer.enabled = YES;
            self.audioButton.selected = NO;
            self.photoButton.selected = YES;
            break;
    }
}

- (void)setInputController:(UIViewController *)inputController
{
    [_inputController.view removeFromSuperview];
    
    _inputController = inputController;
    
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

- (void)keyboardDidHide:(NSNotification *)notification
{
    if (!self.inRotation) {
        self.mode = ConversationInputBarViewControllerModeTextInput;
    }
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
    
    if ([self.conversation shouldDisplayIsTyping]) {
        if (textView.text.length > 0) {
            [self.conversation setIsTyping:YES];
        }
        else {
            [self.conversation setIsTyping:NO];
        }
    }
    
    [self updateRightAccessoryView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        
        NSString *candidateText = textView.text;
        candidateText = [candidateText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL conversationWasNotDeleted  = self.conversation.managedObjectContext != nil;
        if (candidateText.length && conversationWasNotDeleted) {
            
            [self clearInputBar];
            
            NSArray *args = candidateText.args;
            if(args.count > 0) {
                [self runCommand:args];
            }
            else if (self.inputBar.isEditing && nil != self.editingMessage) {
                [self sendEditedMessageAndUpdateStateWithText:candidateText];
            }
            else {
                [self.sendController sendTextMessage:candidateText];
            }
        }

        return NO;
    }
    
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (self.mode == ConversationInputBarViewControllerModeAudioRecord) {
        return YES;
    }
    else if ([self.delegate respondsToSelector:@selector(conversationInputBarViewControllerShouldBeginEditing:)]) {
        return [self.delegate conversationInputBarViewControllerShouldBeginEditing:self];
    }
    else {
        return YES;
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self updateAccessoryViews];
    [self updateNewButtonTitleLabel];
    [[ZMUserSession sharedSession] checkNetworkAndFlashIndicatorIfNecessary];
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
    [[ZMUserSession sharedSession] enqueueChanges:^{
        self.conversation.draftMessageText = textView.text;
    }];
}

#pragma mark - Informal TextView delegate methods

- (void)textView:(UITextView *)textView hasImageToPaste:(id<MediaAsset>)image
{
    ConfirmAssetViewController *confirmImageViewController = [[ConfirmAssetViewController alloc] init];
    confirmImageViewController.image = image;
    confirmImageViewController.previewTitle = [self.conversation.displayName uppercaseStringWithCurrentLocale];
    
    @weakify(self);
    
    confirmImageViewController.onConfirm = ^{
        @strongify(self);
        [self dismissViewControllerAnimated:NO completion:nil];
        [self postImage:image];
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

@implementation ConversationInputBarViewController (Sketch)

- (void)sketchButtonPressed:(id)sender
{
    [self.inputBar.textView resignFirstResponder];
    [Analytics.shared tagMediaAction:ConversationMediaActionSketch inConversation:self.conversation];
    
    SketchViewController *viewController = [[SketchViewController alloc] init];
    viewController.sketchTitle = self.conversation.displayName;
    viewController.delegate = self;
    viewController.source = ConversationMediaSketchSourceSketchButton;
    
    ZMUser *lastSender = self.conversation.lastMessageSender;
    [self.parentViewController presentViewController:viewController animated:YES completion:^{
        [viewController.backgroundViewController setUser:lastSender animated:NO];
        [self.analyticsTracker tagNavigationViewEnteredSketchpad];
    }];
}

- (void)sketchViewControllerDidCancel:(SketchViewController *)controller
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:^{
        [self.analyticsTracker tagNavigationViewSkippedSketchpad];
    }];
}

- (void)sketchViewController:(SketchViewController *)controller didSketchImage:(UIImage *)image
{
    @weakify(self);
    [self hideCameraKeyboardViewController:^{
        @strongify(self);
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        if (image) {
            NSData *imageData = UIImagePNGRepresentation(image);
            [self.sendController sendMessageWithImageData:imageData completion:^{
                   [[Analytics shared] tagMediaSentPictureSourceSketchInConversation:self.conversation sketchSource:controller.source];
            }];
        }
    }];
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

@implementation ConversationInputBarViewController (VerifiedShield)

- (void)verifiedShieldButtonPressed:(UIButton *)sender
{
    sender.userInteractionEnabled = NO;
    [self setVerifiedLabelHidden:self.verifiedLabelView.alpha != 0 animated:YES completion:^{
        sender.userInteractionEnabled = YES;
    }];
}

- (void)setVerifiedLabelHidden:(BOOL)verifiedLabelHidden
{
    [self setVerifiedLabelHidden:verifiedLabelHidden animated:NO completion:nil];
}

- (void)hideVerifiedLabel
{
    [self setVerifiedLabelHidden:YES animated:YES completion:nil];
}

- (void)setVerifiedLabelHidden:(BOOL)hidden animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    dispatch_block_t animations = ^{
        self.verifiedLabelView.alpha = hidden ? 0.0f : 1.0f;
    };
    
    void (^animationCompletion) (BOOL) = ^(BOOL finished) {
        if (completion) {
            completion();
        }
    };
    
    if (animated) {
        [UIView wr_animateWithEasing:RBBEasingFunctionEaseInOutExpo
                            duration:0.35
                          animations:animations
                          completion:animationCompletion];
    } else {
        animations();
        animationCompletion(YES);
    }
    
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideVerifiedLabel) object:nil];
    [self performSelector:@selector(hideVerifiedLabel) withObject:nil afterDelay:3.0f];
}

@end


@implementation ConversationInputBarViewController (Giphy)

- (void)giphyButtonPressed:(id)sender
{
    
    [[ZMUserSession sharedSession] checkNetworkAndFlashIndicatorIfNecessary];
    
    if ([ZMUserSession sharedSession].networkState != ZMNetworkStateOffline) {
        
        [Analytics.shared tagMediaAction:ConversationMediaActionGif inConversation:self.conversation];
    
        NSString *searchTerm = [self.inputBar.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        GiphyViewController *giphyViewController = [[GiphyViewController alloc] initWithSearchTerm:searchTerm];
        giphyViewController.conversation = self.conversation;
        giphyViewController.analyticsTracker = self.analyticsTracker;
        
        giphyViewController.onCancel = ^{
            [self dismissViewControllerAnimated:YES completion:^{
                [self.inputBar.textView becomeFirstResponder];
            }];
        };
        
        @weakify(giphyViewController,self)
        
        giphyViewController.onConfirm = ^{
            
            @strongify(giphyViewController,self)
            
            [self clearInputBar];
            [self dismissViewControllerAnimated:YES completion:nil];
            [self.sendController sendTextMessage:[self messageFromSearchTerm:giphyViewController.searchTerm] withImageData:giphyViewController.imageData];
        };
        
        [[ZClientViewController sharedZClientViewController] presentViewController:giphyViewController animated:YES completion:nil];
        
    }
}

- (NSString *)messageFromSearchTerm:(NSString *)searchTerm
{
    NSString *messageText = nil;
    
    if ([searchTerm isEqualToString:@""]) {
        messageText = [NSString stringWithFormat:NSLocalizedString(@"giphy.conversation.random_message", nil), searchTerm];
    }
    else {
        
        messageText = [NSString stringWithFormat:NSLocalizedString(@"giphy.conversation.message", nil), searchTerm];
    }
    
    return messageText;
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
            Analytics.shared.sessionSummary.pingsSent++;
            
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
    if (change.messagesChanged) {
        
        if (self.conversation.messages.count != 0) {
            id<ZMConversationMessage>lastMessage = self.conversation.messages.lastObject;
            
            if (! [lastMessage.sender isSelfUser] && ([NSDate timeIntervalSinceReferenceDate] - [lastMessage.serverTimestamp timeIntervalSinceReferenceDate]) < 5.0f) {
                NSMutableSet *currentTyping = [NSMutableSet setWithSet:self.typingUsers];
                
                [currentTyping removeObject:lastMessage.sender];
                
                self.typingUsers = currentTyping;
            }
        }
    }
    
    if (change.participantsChanged || change.connectionStateChanged) {
        [self updateInputBarVisibility];
    }
    
    if (change.securityLevelChanged) {
        [self updateRightAccessoryView];
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

- (void)typingDidChange:(ZMTypingChangeNotification *)note
{
    NSPredicate *filterSelfUserPredicate = [NSPredicate predicateWithFormat:@"SELF != %@", [ZMUser selfUser]];
    NSSet *filteredSet = [note.typingUsers filteredSetUsingPredicate:filterSelfUserPredicate];
    
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