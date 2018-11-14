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

@import PureLayout;

#import "Settings.h"

#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"

// helpers
#import "Analytics.h"


// model
#import "WireSyncEngine+iOS.h"
#import "Message+UI.h"

// ui
#import "ConversationContentViewController.h"
#import "ConversationContentViewController+Scrolling.h"
#import "TextView.h"

#import "ZClientViewController.h"
#import "ConversationViewController+ParticipantsPopover.h"
#import "MediaBar.h"
#import "MediaPlayer.h"
#import "MediaBarViewController.h"
#import "InvisibleInputAccessoryView.h"
#import "UIView+Zeta.h"
#import "ConversationInputBarViewController.h"
#import "ProfileViewController.h"
#import "MediaPlaybackManager.h"
#import "ContactsDataSource.h"
#import "VerticalTransition.h"

#import "UIColor+WAZExtensions.h"
#import "UIViewController+Errors.h"
#import "SplitViewController.h"
#import "UIResponder+FirstResponder.h"

#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface ConversationViewController (Keyboard) <InvisibleInputAccessoryViewDelegate>

- (void)keyboardFrameWillChange:(NSNotification *)notification;

@end

@interface ConversationViewController (InputBar) <ConversationInputBarViewControllerDelegate>
@end

@interface ConversationViewController (Content) <ConversationContentViewControllerDelegate>
@end

@interface ConversationViewController (ProfileViewController) <ProfileViewControllerDelegate>
@end

@interface ConversationViewController (ViewControllerDismisser) <ViewControllerDismisser>
@end

@interface ConversationViewController (ZMConversationObserver) <ZMConversationObserver>
@end

@interface ConversationViewController (ConversationListObserver) <ZMConversationListObserver>
@end

@interface ConversationViewController ()

@property (nonatomic) BarController *conversationBarController;
@property (nonatomic) MediaBarViewController *mediaBarViewController;

@property (nonatomic) ConversationContentViewController *contentViewController;
@property (nonatomic) UIViewController *participantsController;

@property (nonatomic) ConversationInputBarViewController *inputBarController;
@property (nonatomic) OutgoingConnectionViewController *outgoingConnectionViewController;

@property (nonatomic) NSLayoutConstraint *inputBarBottomMargin;
@property (nonatomic) NSLayoutConstraint *inputBarZeroHeight;
@property (nonatomic) InvisibleInputAccessoryView *invisibleInputAccessoryView;

@property (nonatomic) GuestsBarController *guestsBarController;
    
@property (nonatomic) id voiceChannelStateObserverToken;
@property (nonatomic) id conversationObserverToken;

@property (nonatomic) BOOL isAppearing;
@property (nonatomic) ConversationTitleView *titleView;
@property (nonatomic) CollectionsViewController *collectionController;
@property (nonatomic) id conversationListObserverToken;
@property (nonatomic, readwrite) ConversationCallController *startCallController;
    
@end



@implementation ConversationViewController

- (void)dealloc
{
    [self dismissCollectionIfNecessary];
    
    [self hideAndDestroyParticipantsPopoverController];
    self.contentViewController.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.conversationListObserverToken = [ConversationListChangeInfo addObserver:self
                                                                         forList:[ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]]
                                                                     userSession:[ZMUserSession sharedSession]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [UIView performWithoutAnimation:^{
        self.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextBackground];
    }];
    
    [self createInputBarController];
    [self createContentViewController];

    self.contentViewController.tableView.pannableView = self.inputBarController.view;

    [self createConversationBarController];
    [self createMediaBarViewController];
    [self createGuestsBarController];

    [self addChildViewController:self.contentViewController];
    [self.view addSubview:self.contentViewController.view];
    [self.contentViewController didMoveToParentViewController:self];

    [self addChildViewController:self.inputBarController];
    [self.view addSubview:self.inputBarController.view];
    [self.inputBarController didMoveToParentViewController:self];

    [self addChildViewController:self.conversationBarController];
    [self.view addSubview:self.conversationBarController.view];
    [self.conversationBarController didMoveToParentViewController:self];

    [self updateOutgoingConnectionVisibility];
    self.isAppearing = NO;

    [self createConstraints];
    [self updateInputBarVisibility];
    
    if (self.conversation.draftMessage.quote != nil && !self.conversation.draftMessage.quote.hasBeenDeleted) {
        [self.inputBarController addReplyComposingView:[self.contentViewController createReplyComposingViewForMessage:self.conversation.draftMessage.quote]];
    }
}

- (void)createInputBarController
{
    self.inputBarController = [[ConversationInputBarViewController alloc] initWithConversation:self.conversation];
    self.inputBarController.delegate = self;
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
    self.contentViewController = [[ConversationContentViewController alloc] initWithConversation:self.conversation message:self.visibleMessage];
    self.contentViewController.delegate = self;
    self.contentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentViewController.bottomMargin = 16;
    self.inputBarController.mentionsView = self.contentViewController.mentionsSearchResultsViewController;
    self.contentViewController.mentionsSearchResultsViewController.delegate = self.inputBarController;
}

- (void)createOutgoingConnectionViewController
{
    self.outgoingConnectionViewController = [[OutgoingConnectionViewController alloc] init];
    @weakify(self);
    self.outgoingConnectionViewController.buttonCallback = ^(OutgoingConnectionBottomBarAction action) {
        @strongify(self);
        [ZMUserSession.sharedSession enqueueChanges:^{
            switch (action) {
                case OutgoingConnectionBottomBarActionCancel:
                    [self.conversation.firstActiveParticipantOtherThanSelf cancelConnectionRequest];
                    break;
                case OutgoingConnectionBottomBarActionArchive:
                    self.conversation.isArchived = YES;
                    break;
            }
        }];

        [self openConversationList];
    };

    self.outgoingConnectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)updateOutgoingConnectionVisibility
{
    if (nil == self.conversation) {
        return;
    }

    BOOL outgoingConnection = self.conversation.relatedConnectionState == ZMConnectionStatusSent;
    self.contentViewController.tableView.scrollEnabled = !outgoingConnection;

    if (outgoingConnection) {
        if (nil != self.outgoingConnectionViewController) {
            return;
        }
        [self createOutgoingConnectionViewController];
        [self.outgoingConnectionViewController willMoveToParentViewController:self];
        [self.view addSubview:self.outgoingConnectionViewController.view];
        [self addChildViewController:self.outgoingConnectionViewController];
        [self.outgoingConnectionViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero
                                                                             excludingEdge:ALEdgeTop];
    } else {
        [self.outgoingConnectionViewController willMoveToParentViewController:nil];
        [self.outgoingConnectionViewController.view removeFromSuperview];
        [self.outgoingConnectionViewController removeFromParentViewController];
        self.outgoingConnectionViewController = nil;
    }
}

- (void)createConversationBarController
{
    self.conversationBarController = [[BarController alloc] init];
}

- (void)createMediaBarViewController
{
    self.mediaBarViewController = [[MediaBarViewController alloc] initWithMediaPlaybackManager:[ZClientViewController sharedZClientViewController].mediaPlaybackManager];
    [self.mediaBarViewController.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMediaBar:)]];
}
    
- (void)createGuestsBarController
{
    self.guestsBarController = [[GuestsBarController alloc] init];
}

- (void)updateGuestsBarVisibilityAndShowIfNeeded:(BOOL)showIfNeeded
{
    GuestBarState state = self.conversation.guestBarState;
    if (state != GuestBarStateHidden) {
        BOOL isPresented = nil != self.guestsBarController.parentViewController;
        if (!isPresented || showIfNeeded) {
            [self.conversationBarController presentBar:self.guestsBarController];
            [self.guestsBarController setState:state animated:NO];
        }
    }
    else {
        [self.conversationBarController dismissBar:self.guestsBarController];
    }
}

- (void)createConstraints
{
    [self.conversationBarController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    [self.contentViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.contentViewController.view autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.inputBarController.view];
    [self.inputBarController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.inputBarController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    self.inputBarBottomMargin = [self.inputBarController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    self.inputBarZeroHeight = [[NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
        [self.inputBarController.view autoSetDimension:ALDimensionHeight toSize:0];
    }] firstObject];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isAppearing = YES;
    [self updateGuestsBarVisibilityAndShowIfNeeded:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateLeftNavigationBarItems];

    if (IS_IPAD_FULLSCREEN) {
        [self becomeFirstResponder];
    }
    else if (self.isFocused) {
        // We are presenting the conversation screen so mark it as the last viewed screen,
        // but only if we are acutally focused (otherwise we would be shown on the next launch)
        [Settings sharedSettings].lastViewedScreen = SettingsLastScreenConversation;
        Account *currentAccount = SessionManager.shared.accountManager.selectedAccount;
        [[Settings sharedSettings] setLastViewedWithConversation:self.conversation for:currentAccount];
    }

    self.contentViewController.searchQueries = self.collectionController.currentTextSearchQuery;

    [[ZMUserSession sharedSession] didOpenWithConversation:self.conversation];
    
    self.isAppearing = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self updateLeftNavigationBarItems];
    [[ZMUserSession sharedSession] didCloseWithConversation:self.conversation];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self updateLeftNavigationBarItems];
}

- (void)scrollToMessage:(id<ZMConversationMessage>)message
{
    [self.contentViewController scrollToMessage:message animated:YES];
}

#pragma mark - Device orientation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateLeftNavigationBarItems];
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
    if (self.collectionController.view.window == nil) {
        self.collectionController = nil;
    }
}

- (void)openConversationList
{
    BOOL leftControllerRevealed = self.wr_splitViewController.leftViewControllerRevealed;
    [self.wr_splitViewController setLeftViewControllerRevealed:!leftControllerRevealed animated:YES completion:nil];
}

#pragma mark - Getters, setters

- (void)setConversation:(ZMConversation *)conversation
{
    if (_conversation == conversation) {
        return;
    }

    _conversation = conversation;
    [self setupNavigatiomItem];
    [self updateOutgoingConnectionVisibility];
    
    if (self.conversation != nil) {
        self.voiceChannelStateObserverToken = [self addCallStateObserver];
        self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
        self.startCallController = [[ConversationCallController alloc] initWithConversation:self.conversation target: self];
    }
}

- (void)setupNavigatiomItem
{
    self.titleView = [[ConversationTitleView alloc] initWithConversation:self.conversation interactive:YES];
    
    ZM_WEAK(self);
    self.titleView.tapHandler = ^(UIButton * _Nonnull button) {
        ZM_STRONG(self);
        [self presentParticipantsViewController:self.participantsController fromView:self.titleView.superview];
    };
    [self.titleView configure];
    
    self.navigationItem.titleView = self.titleView;
    self.navigationItem.leftItemsSupplementBackButton = NO;

    [self updateRightNavigationItemsButtons];
}
    
- (void)presentParticipantsViewController:(UIViewController *)viewController fromView:(UIView *)sourceView
{
    [ConversationInputBarViewController endEditingMessage];
    [self.inputBarController.inputBar.textView resignFirstResponder];

    [self createAndPresentParticipantsPopoverControllerWithRect:sourceView.bounds
                                                       fromView:sourceView
                                          contentViewController:viewController];
}

- (void)updateInputBarVisibility
{
    if (self.conversation.isReadOnly) {
        [self.inputBarController.inputBar.textView resignFirstResponder];
        [self.inputBarController dismissMentionsIfNeeded];
        [self.inputBarController removeReplyComposingView];
    }

    self.inputBarZeroHeight.active = self.conversation.isReadOnly;
    [self.view setNeedsLayout];
}

- (UIViewController *)participantsController
{
    UIViewController *viewController = nil;

    switch (self.conversation.conversationType) {
        case ZMConversationTypeGroup: {
            GroupDetailsViewController *groupDetailsViewController = [[GroupDetailsViewController alloc] initWithConversation:self.conversation];
            viewController = groupDetailsViewController;
            break;
        }
        case ZMConversationTypeSelf:
        case ZMConversationTypeOneOnOne:
        case ZMConversationTypeConnection:
        {
            viewController = [UserDetailViewControllerFactory createUserDetailViewControllerWithUser:self.conversation.firstActiveParticipantOtherThanSelf
                                          conversation:self.conversation
                         profileViewControllerDelegate:self
                               viewControllerDismisser:self];

            break;
        }
        case ZMConversationTypeInvalid:
            RequireString(false, "Trying to open invalid conversation");
            break;
    }

    _participantsController = viewController.wrapInNavigationController;

    return _participantsController;
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
        newConversation = [self.conversation addParticipantsOrCreateConversation:participants];
    } completionHandler:^{
        @strongify(self);
        [self.zClientViewController selectConversation:newConversation focusOnView:YES animated:YES];
    }];
}

- (void)setCollectionController:(CollectionsViewController *)collectionController
{
    _collectionController = collectionController;
    
    [self updateLeftNavigationBarItems];
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

- (BOOL)accessibilityPerformEscape
{
    [self openConversationList];
    return YES;
}

- (void)onBackButtonPressed:(UIButton *)backButton
{
    [self openConversationList];
}

- (void)menuDidHide:(NSNotification *)notification
{
    self.inputBarController.inputBar.textView.overrideNextResponder = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

@end


#pragma mark - Categories

@implementation ConversationViewController (Content)

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
            didScrollWithOffsetFromBottom:(CGFloat)offset
                        withLatestMessage:(id<ZMConversationMessage>)message
{
    self.inputBarController.inputBarOverlapsContent = ! contentViewController.isScrolledToBottom;
}

- (void)didTapOnUserAvatar:(id<UserType>)user view:(UIView *)view frame:(CGRect)frame
{
    if (! user || ! view) {
        return;
    }

    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithUser:(id)user
                                                                      conversation:self.conversation];
    profileViewController.delegate = self;
    [self createAndPresentParticipantsPopoverControllerWithRect:frame
                                                       fromView:view
                                          contentViewController:profileViewController.wrapInNavigationController];
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController willDisplayActiveMediaPlayerForMessage:(id<ZMConversationMessage>)message
{
    [self.conversationBarController dismissBar:self.mediaBarViewController];
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didEndDisplayingActiveMediaPlayerForMessage:(id<ZMConversationMessage>)message
{
    [self.conversationBarController presentBar:self.mediaBarViewController];
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerResendingMessage:(id <ZMConversationMessage>)message
{
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [message resend];
    }];
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerEditingMessage:(id <ZMConversationMessage>)message
{
    NSString *text = message.textMessageData.messageText;
    
    if (nil != text) {
        [self.inputBarController editMessage:message];
    }
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerReplyingToMessage:(id<ZMConversationMessage>)message
{
    ReplyComposingView *replyComposingView = [contentViewController createReplyComposingViewForMessage:message];
    [self.inputBarController replyToMessage:message composingView:replyComposingView];
}

- (BOOL)conversationContentViewController:(ConversationContentViewController *)controller shouldBecomeFirstResponderWhenShowMenuFromCell:(UIView *)cell
{
    if ([self.inputBarController.inputBar.textView isFirstResponder]) {
        self.inputBarController.inputBar.textView.overrideNextResponder = cell;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuDidHide:)
                                                     name:UIMenuControllerDidHideMenuNotification
                                                   object:nil];
        
        return NO;
    }
    else {
        return YES;
    }
}

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController
                performImageSaveAnimation:(UIView *)snapshotView
                               sourceRect:(CGRect)sourceRect
{
    [self.view addSubview:snapshotView];
    snapshotView.frame = [self.view convertRect:sourceRect fromView:contentViewController.view];

    UIView *targetView = self.inputBarController.photoButton;
    CGPoint targetCenter = [self.view convertPoint:targetView.center fromView:targetView.superview];
    
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        snapshotView.center = targetCenter;
        snapshotView.alpha = 0;
        snapshotView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(__unused BOOL finished) {
        [snapshotView removeFromSuperview];
        [self.inputBarController bounceCameraIcon];
    }];
}

- (void)conversationContentViewControllerWantsToDismiss:(ConversationContentViewController *)controller
{
    [self openConversationList];
}
    
- (void)conversationContentViewController:(ConversationContentViewController *)controller presentGuestOptionsFromView:(UIView *)sourceView
{
    if (self.conversation.conversationType != ZMConversationTypeGroup) {
        ZMLogError(@"Illegal Operation: Trying to show guest options for non-group conversation");
        return;
    }
    GroupDetailsViewController *groupDetailsViewController = [[GroupDetailsViewController alloc] initWithConversation:self.conversation];
    UINavigationController *navigationController = groupDetailsViewController.wrapInNavigationController;
    [groupDetailsViewController presentGuestOptionsAnimated:NO];
    [self presentParticipantsViewController:navigationController fromView:sourceView];
}

- (void)conversationContentViewController:(ConversationContentViewController *)controller presentParticipantsDetailsWithSelectedUsers:(NSArray<ZMUser *> *)selectedUsers fromView:(UIView *)sourceView
{
    UIViewController *participantsController = self.participantsController;
    if ([participantsController isKindOfClass:UINavigationController.class]) {
        UINavigationController *navigationController = (UINavigationController *)participantsController;
        if ([navigationController.topViewController isKindOfClass:GroupDetailsViewController.class]) {
            [(GroupDetailsViewController *)navigationController.topViewController presentParticipantsDetailsWithUsers:self.conversation.sortedOtherParticipants
                                                                                                        selectedUsers:selectedUsers
                                                                                                             animated:NO];
        }
    }
    [self presentParticipantsViewController:participantsController fromView:sourceView];
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
            CGSize keyboardSize = CGSizeMake(screenRect.size.width, currentFirstResponder.inputAccessoryView.bounds.size.height);
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

- (void)conversationInputBarViewControllerDidComposeText:(NSString *)text mentions:(NSArray<Mention *> *)mentions replyingToMessage:(nullable id<ZMConversationMessage>)message
{
    [self.inputBarController.sendController sendTextMessage:text mentions:mentions replyingToMessage:message];
}

- (BOOL)conversationInputBarViewControllerShouldBeginEditing:(ConversationInputBarViewController *)controller
{
    if (! self.contentViewController.isScrolledToBottom && !controller.isEditingMessage && !controller.isReplyingToMessage) {
        [self.contentViewController scrollToBottomAnimated:NO];
    }
    
    [self.guestsBarController setState:GuestBarStateHidden animated:YES];
    return YES;
}

- (BOOL)conversationInputBarViewControllerShouldEndEditing:(ConversationInputBarViewController *)controller
{
    return YES;
}

- (void)conversationInputBarViewControllerDidFinishEditingMessage:(id<ZMConversationMessage>)message
                                                         withText:(NSString *)newText
                                                         mentions:(NSArray <Mention *> *)mentions
{
    [self.contentViewController didFinishEditingMessage:message];
    [[ZMUserSession sharedSession] enqueueChanges:^{
        if (newText == nil || [newText isEqualToString:@""]) {
            [ZMMessage deleteForEveryone:message];
        } else {
            BOOL fetchLinkPreview = ![[Settings sharedSettings] disableLinkPreviews];
            [message.textMessageData editText:newText mentions:mentions fetchLinkPreview:fetchLinkPreview];
        }
    }];
}

- (void)conversationInputBarViewControllerDidCancelEditingMessage:(id<ZMConversationMessage>)message
{
    [self.contentViewController didFinishEditingMessage:message];
}

- (void)conversationInputBarViewControllerWantsToShowMessage:(id<ZMConversationMessage>)message
{
    [self.contentViewController scrollTo:message completion:^(UIView * cell) {
        [self.contentViewController highlightMessage:message];
    }];
}

- (void)conversationInputBarViewControllerEditLastMessage
{
    [self.contentViewController editLastMessage];
}

@end

@implementation ConversationViewController (ViewControllerDismisser)

- (void)dismissViewController:(UIViewController *)profileViewController completion:(dispatch_block_t)completion
{
    [self dismissViewControllerAnimated:YES completion:completion];
}

@end

@implementation ConversationViewController (ProfileViewController)

- (void)profileViewController:(ProfileViewController *)controller wantsToNavigateToConversation:(ZMConversation *)conversation
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.zClientViewController selectConversation:conversation
                                           focusOnView:YES
                                              animated:YES];
    }];
}

- (void)profileViewController:(ProfileViewController *)controller wantsToCreateConversationWithName:(NSString *)name users:(NSSet *)users
{
    dispatch_block_t conversationCreation = ^{
        __block  ZMConversation *newConversation = nil;
        
        @weakify(self);
        [ZMUserSession.sharedSession enqueueChanges:^{
            newConversation = [ZMConversation insertGroupConversationIntoUserSession:ZMUserSession.sharedSession withParticipants:users.allObjects name:name inTeam:ZMUser.selfUser.team];
        } completionHandler:^{
            @strongify(self);
            [self.zClientViewController selectConversation:newConversation focusOnView:YES animated:YES];
        }];
    };
    
    if (nil != self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:conversationCreation];
    }
    else {
        conversationCreation();
    }
}

@end


@implementation ConversationViewController (ZMConversationObserver)

- (void)conversationDidChange:(ConversationChangeInfo *)note
{
    if (note.didNotSendMessagesBecauseOfConversationSecurityLevel) {
        [self presentConversationDegradedActionSheetControllerForUsers:note.usersThatCausedConversationToDegrade];
    }
    
    if (note.participantsChanged || note.connectionStateChanged) {
        [self updateRightNavigationItemsButtons];
        [self updateLeftNavigationBarItems];
        [self updateOutgoingConnectionVisibility];
        [self.contentViewController updateTableViewHeaderView];
        [self updateInputBarVisibility];
    }

    [self updateGuestsBarVisibilityAndShowIfNeeded:NO];

    if (note.nameChanged || note.securityLevelChanged || note.connectionStateChanged) {
        [self setupNavigatiomItem];
    }
}

- (void)presentConversationDegradedActionSheetControllerForUsers:(NSSet<ZMUser *> *)users
{
    UIAlertController *controller = [UIAlertController controllerForUnknownClientsForUsers:users completion:^(ConversationDegradedResult result) {
        switch (result) {
            case ConversationDegradedResultCancel:
                [self.conversation doNotResendMessagesThatCausedDegradation];
                break;
            case ConversationDegradedResultSendAnyway:
                [self.conversation resendMessagesThatCausedConversationSecurityDegradation];
                break;
            case ConversationDegradedResultShowDetails:
                [self.conversation doNotResendMessagesThatCausedDegradation];

                if ([[ZMUser selfUser] hasUntrustedClients]) {
                    [[ZClientViewController sharedZClientViewController] openClientListScreenForUser:[ZMUser selfUser]];
                }
                else {
                    if (self.conversation.conversationType == ZMConversationTypeOneOnOne) {
                        ZMUser *user = self.conversation.connectedUser;
                        if (user.clients.count == 1) {
                            ProfileClientViewController *userClientController = [[ProfileClientViewController alloc] initWithClient:user.clients.anyObject fromConversation:YES];
                            userClientController.showBackButton = NO;
                            UINavigationController *navigationController = userClientController.wrapInNavigationController;
                            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                            userClientController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithIcon:ZetaIconTypeX style:UIBarButtonItemStylePlain target:self action:@selector(dismissProfileClientViewController:)];
                            [self presentViewController:navigationController animated:YES completion:nil];
                        } else {
                            ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithUser:user context:ProfileViewControllerContextDeviceList];
                            profileViewController.delegate = self;
                            profileViewController.viewControllerDismisser = self;
                            UINavigationController *navigationController = profileViewController.wrapInNavigationController;
                            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                            [self presentViewController:navigationController animated:YES completion:nil];
                        }
                    } else if (self.conversation.conversationType == ZMConversationTypeGroup) {
                        UIViewController *participantsController = [self participantsController];
                        [self presentViewController:participantsController animated:YES completion:nil];
                    }
                }
                
                break;
        }
    }];

    [self presentViewController:controller animated:YES completion:nil];
}

- (void)dismissProfileClientViewController:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end


@implementation ConversationViewController (ConversationListObserver)

- (void)conversationListDidChange:(ConversationListChangeInfo *)changeInfo
{
    [self updateLeftNavigationBarItems];
}

- (void)conversationInsideList:(ZMConversationList * _Nonnull)list didChange:(ConversationChangeInfo * _Nonnull)changeInfo
{
    [self updateLeftNavigationBarItems];
}

@end

