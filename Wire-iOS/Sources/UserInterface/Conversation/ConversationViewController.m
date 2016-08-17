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


#import "ConversationViewController.h"
#import "ConversationViewController+Private.h"

#import <Classy/Classy.h>
#import <PureLayout/PureLayout.h>

#import "Settings.h"

#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"
#import "VoiceChannelController.h"

// helpers
#import "WAZUIMagicIOS.h"
#import "Analytics+iOS.h"


// model
#import "zmessaging+iOS.h"
#import "ZMVoiceChannel+Additions.h"
#import "Message.h"

// ui
#import "ConversationContentViewController.h"
#import "ConversationContentViewController+Scrolling.h"
#import "TextView.h"
#import "TextMessageCell.h"

#import "ZClientViewController.h"
#import "ConversationListViewController.h"
#import "ParticipantsViewController.h"
#import "ConversationViewController+ParticipantsPopover.h"
#import "MediaBar.h"
#import "MediaPlayer.h"
#import "MediaBarViewController.h"
#import "TitleBar.h"
#import "TitleBarViewController.h"
#import "UIView+Borders.h"
#import "InvisibleInputAccessoryView.h"
#import "UIView+Zeta.h"
#import "ConversationInputBarViewController.h"
#import "ProfileViewController.h"
#import "ChatHeadsViewController.h"
#import "MediaPlaybackManager.h"
#import "BarController.h"
#import "AddContactsViewController.h"
#import "ContactsDataSource.h"
#import "VerticalTransition.h"

#import "UIColor+WAZExtensions.h"
#import "KeyboardFrameObserver+iOS.h"
#import "AnalyticsTracker.h"
#import "AnalyticsTracker+Invitations.h"
#import "UIViewController+Errors.h"
#import "UIViewController+Orientation.h"
#import "SplitViewController.h"
#import "UIColor+WR_ColorScheme.h"
#import "ActionSheetController+Conversation.h"
#import "UIResponder+FirstResponder.h"

#import "Wire-Swift.h"


@interface ConversationDetailsTransitioningDelegate : NSObject<UIViewControllerTransitioningDelegate>

@end


@implementation ConversationDetailsTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[VerticalTransition alloc] initWithOffset:-88];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[VerticalTransition alloc] initWithOffset:88];
}

@end

@interface ConversationViewController (Keyboard) <InvisibleInputAccessoryViewDelegate>

- (void)keyboardFrameWillChange:(NSNotification *)notification;

@end

@interface ConversationViewController (InputBar) <ConversationInputBarViewControllerDelegate>
@end

@interface ConversationViewController (Content) <ConversationContentViewControllerDelegate>
@end

@interface ConversationViewController (ParticipantsViewController) <ParticipantsViewControllerDelegate>
@end

@interface ConversationViewController (ProfileViewController) <ProfileViewControllerDelegate>
@end

@interface ConversationViewController (VoiceChannelStateObserver) <ZMVoiceChannelStateObserver>
@end

@interface ConversationViewController (ChatHeadsViewControllerDelegate) <ChatHeadsViewControllerDelegate>
@end

@interface ConversationViewController (AddContacts) <ContactsViewControllerDelegate>
@end

@interface ConversationViewController (ZMConversationObserver) <ZMConversationObserver>
@end

@interface ConversationViewController (UINavigationControllerDelegate) <UINavigationControllerDelegate>
@end


@interface ConversationViewController ()

@property (nonatomic) ConversationDetailsTransitioningDelegate *conversationDetailsTransitioningDelegate;
@property (nonatomic) BarController *conversationBarController;
@property (nonatomic) ChatHeadsViewController *chatHeadsViewController;
@property (nonatomic) MediaBarViewController *mediaBarViewController;

@property (nonatomic) ConversationContentViewController *contentViewController;
@property (nonatomic) UIViewController *participantsController;

@property (nonatomic) BOOL mediaBarAnimationInFlight;

@property (nonatomic) ConversationInputBarViewController *inputBarController;

@property (nonatomic) NSLayoutConstraint *inputBarBottomMargin;
@property (nonatomic) InvisibleInputAccessoryView *invisibleInputAccessoryView;

@property (nonatomic) id <ZMVoiceChannelStateObserverOpaqueToken> voiceChannelStateObserverToken;

@property (nonatomic) id <ZMConversationObserverOpaqueToken> conversationObserverToken;

@property (nonatomic) AnalyticsTracker *analyticsTracker;

@property (nonatomic) BOOL isAppearing;
@property (nonatomic) UIBarButtonItem *backButtonItem;
@property (nonatomic) ConversationTitleView *titleView;

@end



@implementation ConversationViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.conversation.voiceChannel removeVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken];

    [self hideAndDestroyParticipantsPopoverController];
    self.contentViewController.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [UIView performWithoutAnimation:^{
        self.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextBackground];
    }];

    self.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextConversation];
    self.conversationDetailsTransitioningDelegate = [[ConversationDetailsTransitioningDelegate alloc] init];

    [self createInputBarController];
    [self createContentViewController];
    [self createConversationBarController];
    [self createMediaBarViewController];
    [self createChatHeadsViewController];

    [self addChildViewController:self.contentViewController];
    [self.view addSubview:self.contentViewController.view];

    [self addChildViewController:self.inputBarController];
    [self.view addSubview:self.inputBarController.view];

    [self addChildViewController:self.conversationBarController];
    [self.view addSubview:self.conversationBarController.view];

    [self addChildViewController:self.chatHeadsViewController];
    [self.view addSubview:self.chatHeadsViewController.view];

    self.isAppearing = NO;

    [self createConstraints];
}

- (void)createInputBarController
{
    self.inputBarController = [[ConversationInputBarViewController alloc] initWithConversation:self.conversation];
    self.inputBarController.delegate = self;
    self.inputBarController.analyticsTracker = self.analyticsTracker;
    self.inputBarController.view.translatesAutoresizingMaskIntoConstraints = NO;

    // Create an invisible input accessory view that will allow us to take advantage of built in keyboard
    // dragging and sizing of the scrollview
    self.invisibleInputAccessoryView = [[InvisibleInputAccessoryView alloc] init];
    self.invisibleInputAccessoryView.delegate = self;
    self.invisibleInputAccessoryView.userInteractionEnabled = NO; // make it not block touch events
    self.invisibleInputAccessoryView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.inputBarController.inputBar.invisibleInputAccessoryView = self.invisibleInputAccessoryView;
}

- (void)createContentViewController
{
    self.contentViewController = [[ConversationContentViewController alloc] initWithConversation:self.conversation];
    self.contentViewController.delegate = self;
    self.contentViewController.analyticsTracker = self.analyticsTracker;
    self.contentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentViewController.bottomMargin = 16;
}

- (void)createBackButton
{
    if (self.backButtonItem != nil) {
        return;
    }
    
    IconButton *backButton = IconButton.iconButtonDefault;
    
    ZetaIconType leftButtonIcon = ZetaIconTypeNone;
    if (self.parentViewController.wr_splitViewController.layoutSize == SplitViewControllerLayoutSizeCompact) {
        leftButtonIcon = ZetaIconTypeBackArrow;
    }
    else {
        leftButtonIcon = ZetaIconTypeHamburger;
    }
    
    [backButton setIcon:leftButtonIcon withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(onBackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 16, 16);
    self.backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    self.backButtonItem.accessibilityIdentifier = @"ConversationBackButton";
    self.navigationItem.leftItemsSupplementBackButton = NO;
    [self updateBackButtonVisibility];
}

- (void)createConversationBarController
{
    self.conversationBarController = [[BarController alloc] init];
}

- (void)createMediaBarViewController
{
    self.mediaBarViewController = [[MediaBarViewController alloc] initWithMediaPlaybackManager:[AppDelegate sharedAppDelegate].mediaPlaybackManager];
    [self.mediaBarViewController.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMediaBar:)]];
}

- (void)createChatHeadsViewController
{
    self.chatHeadsViewController = [[ChatHeadsViewController alloc] init];
    self.chatHeadsViewController.delegate = self;
    self.chatHeadsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)createConstraints
{
    [self.conversationBarController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    [self.contentViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.contentViewController.view autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.inputBarController.view];
    [self.inputBarController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.inputBarController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    self.inputBarBottomMargin = [self.inputBarController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    [self.chatHeadsViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.conversationBarController.view];
    [self.chatHeadsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.chatHeadsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self createBackButton];
    [self updateBackButtonVisibility];
    self.isAppearing = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateBackButtonVisibility];

    if (IS_IPAD) {
        [self becomeFirstResponder];
    }
    else if (self.isFocused) {
        // We are presenting the conversation screen so mark it as the last viewed screen,
        // but only if we are acutally focused (otherwise we would be shown on the next launch)
        [Settings sharedSettings].lastViewedScreen = SettingsLastScreenConversation;
        [Settings sharedSettings].lastViewedConversation = self.conversation;
    }

    self.isAppearing = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self updateBackButtonVisibility];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self updateBackButtonVisibility];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateBackButtonVisibility];
    }];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self hideAndDestroyParticipantsPopoverController];
}

- (BOOL)definesPresentationContext
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)updateBackButtonVisibility
{
    if (self.parentViewController.wr_splitViewController.layoutSize == SplitViewControllerLayoutSizeRegularLandscape) {
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        self.navigationItem.leftBarButtonItem = self.backButtonItem;
    }
}

#pragma mark - Getters, setters

- (void)setConversation:(ZMConversation *)conversation
{
    if (_conversation == conversation) {
        return;
    }

    if (self.conversation != nil) {
        [self.conversation.voiceChannel removeVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken];
        [ZMConversation removeConversationObserverForToken:self.conversationObserverToken];
    }

    _conversation = conversation;
    [self setupNavigatiomItem];
    
    if (self.conversation != nil) {
        self.voiceChannelStateObserverToken = [conversation.voiceChannel addVoiceChannelStateObserver:self];
        self.conversationObserverToken = [self.conversation addConversationObserver:self];
    }
}


- (void)setupNavigatiomItem
{
    self.titleView = [[ConversationTitleView alloc] initWithConversation:self.conversation];
    
    ZM_WEAK(self);
    self.titleView.tapHandler = ^(UIButton * _Nonnull button) {
        ZM_STRONG(self);
        [ConversationInputBarViewController endEditingMessage];
        [self.inputBarController.inputBar.textView resignFirstResponder];
        
        UIViewController *participantsController = [self participantsController];
        participantsController.transitioningDelegate = self.conversationDetailsTransitioningDelegate;
        [self createAndPresentParticipantsPopoverControllerWithRect:self.titleView.superview.bounds
                                                           fromView:self.titleView.superview
                                              contentViewController:participantsController];
    };
    
    self.navigationItem.titleView = self.titleView;
    [self updateNavigationItemsButtons];
}

- (void)updateNavigationItemsButtons
{
    self.navigationItem.rightBarButtonItems = [self navigationItemsForConversation:self.conversation];
}

- (UIViewController *)participantsController
{
    UIViewController *viewController = nil;

    if (self.conversation.conversationType == ZMConversationTypeGroup) {

        ParticipantsViewController *participantsViewController = [[ParticipantsViewController alloc] initWithConversation:self.conversation];
        participantsViewController.delegate = self;
        participantsViewController.zClientViewController = [ZClientViewController sharedZClientViewController];
        participantsViewController.shouldDrawTopSeparatorLineDuringPresentation = YES;
        viewController = participantsViewController;
    }
    else if (self.conversation.conversationType == ZMConversationTypeSelf ||
             self.conversation.conversationType == ZMConversationTypeOneOnOne ||
             self.conversation.conversationType == ZMConversationTypeConnection) {

        ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithUser:self.conversation.firstActiveParticipantOtherThanSelf
                                                                                      conversation:self.conversation];
        profileViewController.delegate = self;
        profileViewController.shouldDrawTopSeparatorLineDuringPresentation = YES;
        viewController = profileViewController;
    }

    RotationAwareNavigationController *navigationController = [[RotationAwareNavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBarHidden = YES;

    _participantsController = navigationController;

    return navigationController;
}

- (void)setAnalyticsTracker:(AnalyticsTracker *)analyticsTracker
{
    _analyticsTracker = analyticsTracker;
    self.contentViewController.analyticsTracker = _analyticsTracker;
}

- (void)didTapMediaBar:(UITapGestureRecognizer *)tapGestureRecognizer
{
    MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
    id<ZMConversationMessage>mediaPlayingMessage = mediaPlaybackManager.activeMediaPlayer.sourceMessage;

    if ([self.conversation isEqual:mediaPlayingMessage.conversation]) {
        [self.contentViewController scrollToMessage:mediaPlayingMessage animated:YES];
    }
}

- (void)addParticipants:(NSSet *)participants
{
    ZMConversation __block *newConversation = nil;

    @weakify(self);
    [[ZMUserSession sharedSession] enqueueChanges:^{
        newConversation = [self.conversation addParticipants:participants];
    } completionHandler:^{
        @strongify(self);
        [self.zClientViewController selectConversation:newConversation focusOnView:YES animated:YES];
    }];
}

#pragma mark - SwipeNavigationController's panning

- (BOOL)frameworkShouldRecognizePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.view];
    if (CGRectContainsPoint([self.view convertRect:self.inputBarController.view.bounds fromView:self.inputBarController.view], location)) {
        return NO;
    }

    return YES;
}

#pragma mark - Application Events & Notifications

- (void)onBackButtonPressed:(UIButton *)backButton
{
    BOOL leftControllerRevealed = self.parentViewController.wr_splitViewController.leftViewControllerRevealed;
    [self.parentViewController.wr_splitViewController setLeftViewControllerRevealed:!leftControllerRevealed animated:YES completion:nil];
}

@end


#pragma mark - Categories

@implementation ConversationViewController (Content)

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
            didScrollWithOffsetFromBottom:(CGFloat)offset
                        withLatestMessage:(id<ZMConversationMessage>)message
{
    self.inputBarController.inputBar.separatorEnabled = ! contentViewController.isScrolledToBottom;
}

- (void)didTapOnUserAvatar:(ZMUser *)user view:(UIView *)view
{
    if (! user || ! view) {
        return;
    }

    // Edge case prevention:
    // If the keyboard (input field has focus) is up and the user is tapping directly on an avatar, we ignore this tap. This
    // solves us the problem of the repositioning the popover after the keyboard destroys the layout and the we would re-position
    // the popover again

    if (! IS_IPAD || IS_IPAD_LANDSCAPE_LAYOUT) {
        return;
    }

    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithUser:user
                                                                                  conversation:self.conversation];
    [self createAndPresentParticipantsPopoverControllerWithRect:view.bounds fromView:view contentViewController:profileViewController];
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController willDisplayActiveMediaPlayerForMessage:(id<ZMConversationMessage>)message
{
    [self.conversationBarController dismissBar:self.mediaBarViewController];
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didEndDisplayingActiveMediaPlayerForMessage:(id<ZMConversationMessage>)message
{
    [self.conversationBarController presentBar:self.mediaBarViewController];
}

- (void)conversationContentViewControllerDidFinishScrolling:(ConversationContentViewController *)contentViewController
{

}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerAddContactsButton:(UIButton *)button
{
    AddContactsViewController *addContactsViewController = [[AddContactsViewController alloc] initWithConversation:self.conversation];
    addContactsViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:NSStringFromInviteContext(InviteContextConversation)];
    addContactsViewController.delegate = self;
    addContactsViewController.modalPresentationStyle = UIModalPresentationPopover;
    addContactsViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    UIPopoverPresentationController *popoverPresentationController = addContactsViewController.popoverPresentationController;
    popoverPresentationController.sourceView = button;
    popoverPresentationController.sourceRect = button.bounds;
    popoverPresentationController.delegate = addContactsViewController;

    [self presentViewController:addContactsViewController animated:YES completion:^() {
        [[Analytics shared] tagScreenInviteContactList];
        [addContactsViewController.analyticsTracker tagEvent:AnalyticsEventInviteContactListOpened];
    }];
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerResendingMessage:(ZMMessage *)message
{
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [message resend];
    }];
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerEditingMessage:(ZMMessage *)message
{
    NSString *text = message.textMessageData.messageText;
    
    if (nil != text) {
        [self.inputBarController editMessage:message];
    }
}

@end



@implementation ConversationViewController (Keyboard)

- (void)keyboardFrameWillChange:(NSNotification *)notification
{
    // We only respond to keyboard will change frame if the first responder is not the input bar
    if (self.invisibleInputAccessoryView.window == nil) {
        [UIView animateWithKeyboardNotification:notification
                                         inView:self.view
                                     animations:^(CGRect keyboardFrameInView) {
                                         self.inputBarBottomMargin.constant = -keyboardFrameInView.size.height;
                                     }
                                     completion:nil];
    }
    else {
        CGRect screenRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        UIResponder *currentFirstResponder = [UIResponder wr_currentFirstResponder];
        if (currentFirstResponder != nil) {
            CGSize keyboardSize = CGSizeMake(screenRect.size.width, screenRect.size.height - currentFirstResponder.inputAccessoryView.bounds.size.height);
            [UIView wr_setLastKeyboardSize:keyboardSize];
        }
    }
}

- (void)invisibleInputAccessoryView:(InvisibleInputAccessoryView *)view didMoveToWindow:(UIWindow *)window
{
}

// WARNING: DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING
- (void)invisibleInputAccessoryView:(InvisibleInputAccessoryView *)view superviewFrameChanged:(CGRect)frame
{
    // Adjust the input bar distance from bottom based on the invisibleAccessoryView
    CGFloat distanceFromBottom = 0;

    // On iOS 8, the frame goes to zero when the accessory view is hidden
    if ( ! CGRectEqualToRect(frame, CGRectZero)) {

        CGRect convertedFrame = [self.view convertRect:view.superview.frame fromView:view.superview.superview];

        // We have to use intrinsicContentSize here because the frame may not have actually been updated yet
        CGFloat newViewHeight = view.intrinsicContentSize.height;

        distanceFromBottom = self.view.frame.size.height - convertedFrame.origin.y - newViewHeight;
        distanceFromBottom = MAX(0, distanceFromBottom);
    }

    if (self.isAppearing) {
        [UIView performWithoutAnimation:^{
            self.inputBarBottomMargin.constant = -distanceFromBottom;

            [self.view layoutIfNeeded];
        }];
    }
    else {
        self.inputBarBottomMargin.constant = -distanceFromBottom;

        [self.view layoutIfNeeded];
    }

}

@end


@implementation ConversationViewController (InputBar)

- (BOOL)conversationInputBarViewControllerShouldBeginEditing:(ConversationInputBarViewController *)controller
{
    if (! self.contentViewController.isScrolledToBottom) {
        [self.contentViewController scrollToBottomAnimated:YES];
    }

    return YES;
}

- (BOOL)conversationInputBarViewControllerShouldEndEditing:(ConversationInputBarViewController *)controller
{
    return YES;
}

- (void)conversationInputBarViewControllerDidFinishEditingMessage:(id<ZMConversationMessage>)message withText:(NSString *)newText
{
    [self.contentViewController didFinishEditingMessage:message];

    [[ZMUserSession sharedSession] enqueueChanges:^{
        if (newText == nil || [newText isEqualToString:@""]) {
            [ZMMessage deleteForEveryone:message];
        } else {
            [ZMMessage edit:message newText:newText];
        }
    }];
}

- (void)conversationInputBarViewControllerDidCancelEditingMessage:(id<ZMConversationMessage>)message
{
    [self.contentViewController didFinishEditingMessage:message];
}

@end

@implementation ConversationViewController (ParticipantsViewController)

- (void)participantsViewControllerWantsToBeDismissed:(ParticipantsViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)participantsViewController:(ParticipantsViewController *)controller wantsToAddUsers:(NSSet *)users toConversation:(ZMConversation *)conversation
{
    [self profileViewController:nil wantsToAddUsers:users toConversation:conversation];
}

@end

@implementation ConversationViewController (ProfileViewController)

- (void)profileViewControllerWantsToBeDismissed:(ProfileViewController *)profileViewController completion:(dispatch_block_t)completion
{
    [[Analytics shared] tagScreen:@"MAIN"];
    [self dismissViewControllerAnimated:YES completion:completion];
}

- (void)profileViewController:(ProfileViewController *)controller wantsToNavigateToConversation:(ZMConversation *)conversation
{
    [[Analytics shared] tagScreen:@"MAIN"];

    [self dismissViewControllerAnimated:YES completion:^{
        [self.zClientViewController selectConversation:conversation
                                           focusOnView:YES
                                              animated:YES];
    }];
}

- (void)profileViewController:(ProfileViewController *)controller wantsToAddUsers:(NSSet *)users toConversation:(ZMConversation *)conversation
{
    [[Analytics shared] tagScreen:@"MAIN"];

    [self dismissViewControllerAnimated:YES completion:^{
        [self addParticipants:users];
    }];
}

@end



@implementation ConversationViewController (VoiceChannelStateObserver)

- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)change
{

}

- (void)voiceChannelJoinFailedWithError:(NSError *)error
{
    [self showAlertForError:error];
}

@end



@implementation ConversationViewController (ChatHeadsViewControllerDelegate)

- (BOOL)chatHeadsViewController:(ChatHeadsViewController *)viewController isMessageInCurrentConversation:(id<ZMConversationMessage>)message
{
    return [message.conversation isEqual:self.conversation];
}

- (BOOL)chatHeadsViewController:(ChatHeadsViewController *)viewController shouldDisplayMessage:(id<ZMConversationMessage>)message
{
    if (IS_IPAD && IS_IPAD_LANDSCAPE_LAYOUT) {
        // no notifications in landscape
        return NO;
    }

    if ([AppDelegate sharedAppDelegate].notificationWindowController.voiceChannelController.voiceChannelIsActive) {
        return NO;
    }

    // in landscape no notificaitons if conversation view is not visible
    if (! [ZClientViewController sharedZClientViewController].isConversationViewVisible) {
        return NO;
    }

    BOOL isConversationCurrentConversation = [message.conversation isEqual:self.conversation];

    BOOL isScrolledToBottom = self.contentViewController.tableView.contentOffset.y < self.view.bounds.size.height / 2.0f;

    if ((! isConversationCurrentConversation || (isConversationCurrentConversation && ! isScrolledToBottom) ) &&
        [Message isPresentableAsNotification:message]) {

        return YES;
    }

    return NO;
}

- (void)chatHeadsViewController:(ChatHeadsViewController *)viewController didSelectMessage:(id<ZMConversationMessage>)message
{
    [self.zClientViewController selectConversation:message.conversation
                                       focusOnView:YES
                                          animated:YES];
}

@end


@implementation ConversationViewController (AddContacts)

- (void)contactsViewControllerDidCancel:(ContactsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactsViewControllerDidConfirmSelection:(ContactsViewController *)controller
{
    NSOrderedSet *selectedUsers = [controller.dataSource.selection valueForKey:@"user"];

    [controller dismissViewControllerAnimated:YES completion:^{
        [self addParticipants:selectedUsers.set];
    }];
}

@end


@implementation ConversationViewController (ZMConversationObserver)

- (void)conversationDidChange:(ConversationChangeInfo *)note
{
    if (note.didDegradeSecurityLevelBecauseOfMissingClients) {
        [self presentConversationDegradedActionSheetControllerForUsers:note.usersThatCausedConversationToDegrade];
    }
    
    if (note.participantsChanged || note.connectionStateChanged) {
        [self updateNavigationItemsButtons];
    }
    
    if (note.nameChanged) {
        [self setupNavigatiomItem];
    }
}

- (void)presentConversationDegradedActionSheetControllerForUsers:(NSSet<ZMUser *> *)users
{
    NavigationController *navigationController = [[NavigationController alloc] init];

    ActionSheetController *actionSheetController =
    [ActionSheetController dialogForUnknownClientsForUsers:users
                                                   style:[ActionSheetController defaultStyle]
                                              completion:^(BOOL sendAnywayPressed, BOOL showDetailsPressed) {
                                                  if (sendAnywayPressed) {
                                                      [self.conversation resendLastUnsentMessages];
                                                      [self dismissViewControllerAnimated:YES completion:nil];
                                                  } else if (showDetailsPressed) {
                                                      if (self.conversation.conversationType == ZMConversationTypeOneOnOne) {
                                                          ZMUser *user = self.conversation.connectedUser;
                                                          if (user.clients.count == 1) {
                                                              ProfileClientViewController *userClientController = [[ProfileClientViewController alloc] initWithClient:user.clients.anyObject];
                                                              userClientController.showBackButton = NO;
                                                              [navigationController pushViewController:userClientController animated:YES];
                                                          } else {
                                                              [self dismissViewControllerAnimated:YES completion:^{
                                                                  ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithUser:user context:ProfileViewControllerContextDeviceList];
                                                                  profileViewController.delegate = self;
                                                                  [self presentViewController:profileViewController animated:YES completion:nil];
                                                              }];
                                                          }
                                                      } else if (self.conversation.conversationType == ZMConversationTypeGroup) {
                                                          [self dismissViewControllerAnimated:YES completion:^{
                                                              UIViewController *participantsController = [self participantsController];
                                                              participantsController.transitioningDelegate = self.conversationDetailsTransitioningDelegate;
                                                              [self presentViewController:participantsController animated:YES completion:nil];
                                                          }];
                                                      }
                                                  }
                                              }];

    [navigationController setViewControllers:@[actionSheetController] animated:NO];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    navigationController.backButton.cas_styleClass = @"circular";
    navigationController.rightButtonEnabled = YES;
    navigationController.delegate = self;
    [navigationController updateRightButtonWithIconType:ZetaIconTypeX
                                               iconSize:ZetaIconSizeTiny
                                                 target:self
                                                 action:@selector(degradedConversationDismissed:)
                                               animated:NO];
    navigationController.view.backgroundColor = [UIColor whiteColor];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)degradedConversationDismissed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end



#pragma mark - UINavigationControllerDelegate

@implementation ConversationViewController (UINavigationControllerDelegate)

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NavigationController *navController = (NavigationController *)navigationController;
    if ([viewController isKindOfClass:[ProfileClientViewController class]] ||
        [viewController isKindOfClass:[ParticipantsViewController class]] ||
        [viewController isKindOfClass:[ProfileViewController class]]) {
        navController.rightButtonEnabled = NO;
    } else {
        navController.rightButtonEnabled = YES;
    }
}

@end

