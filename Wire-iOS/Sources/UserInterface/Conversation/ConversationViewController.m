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

#import "Settings.h"

#import "AppDelegate.h"

// helpers
#import "Analytics.h"


// model
#import "Message+UI.h"

// ui
#import "ConversationContentViewController.h"
#import "TextView.h"

#import "ZClientViewController.h"
#import "ConversationViewController+ParticipantsPopover.h"
#import "MediaPlayer.h"
#import "MediaBarViewController.h"
#import "InvisibleInputAccessoryView.h"
#import "UIView+Zeta.h"
#import "ConversationInputBarViewController.h"
#import "MediaPlaybackManager.h"
#import "ContactsDataSource.h"
#import "VerticalTransition.h"

#import "UIViewController+Errors.h"
#import "SplitViewController.h"
#import "UIResponder+FirstResponder.h"

#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface ConversationViewController (Keyboard) <InvisibleInputAccessoryViewDelegate>

@end

@interface ConversationViewController (InputBar) <ConversationInputBarViewControllerDelegate>
@end

@interface ConversationViewController (Content) <ConversationContentViewControllerDelegate>
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
@property (nonatomic, readwrite) InvisibleInputAccessoryView *invisibleInputAccessoryView;
@property (nonatomic, readwrite) GuestsBarController *guestsBarController;

@property (nonatomic) id voiceChannelStateObserverToken;
@property (nonatomic) id conversationObserverToken;

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

    if ([self.session isKindOfClass:[ZMUserSession class]]) {
        self.conversationListObserverToken = [ConversationListChangeInfo addObserver:self
                                                                             forList:[ZMConversationList conversationsInUserSession:(ZMUserSession *)self.session]
                                                                         userSession:(ZMUserSession *)self.session];
    }

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
    self.contentViewController = [[ConversationContentViewController alloc] initWithConversation:self.conversation
                                                                                         message:self.visibleMessage
                                                                            mediaPlaybackManager:self.zClientViewController.mediaPlaybackManager
                                                                                         session: self.session];
    self.contentViewController.delegate = self;
    self.contentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentViewController.bottomMargin = 16;
    self.inputBarController.mentionsView = self.contentViewController.mentionsSearchResultsViewController;
    self.contentViewController.mentionsSearchResultsViewController.delegate = self.inputBarController;
}

- (void)createOutgoingConnectionViewController
{
    self.outgoingConnectionViewController = [[OutgoingConnectionViewController alloc] init];
    self.outgoingConnectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    ZM_WEAK(self);
    self.outgoingConnectionViewController.buttonCallback = ^(OutgoingConnectionBottomBarAction action) {
        ZM_STRONG(self);
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isAppearing = YES;
    [self updateGuestsBarVisibility];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    [self updateGuestsBarVisibility];
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
    [self.contentViewController scrollToMessage:message completion:nil];
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
            viewController = [self createUserDetailViewControllerWithUser];
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
        [self.contentViewController scrollToMessage:mediaPlayingMessage completion:nil];
    }
}

- (void)addParticipants:(NSSet *)participants
{
    ZMConversation __block *newConversation = nil;

    ZM_WEAK(self);
    [[ZMUserSession sharedSession] enqueueChanges:^{
        newConversation = [self.conversation addParticipantsOrCreateConversation:participants];
    } completionHandler:^{
        ZM_STRONG(self);
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
    [self.contentViewController scrollToBottom];
    [self.inputBarController.sendController sendTextMessage:text mentions:mentions replyingToMessage:message];
}

- (BOOL)conversationInputBarViewControllerShouldBeginEditing:(ConversationInputBarViewController *)controller
{
    if (! self.contentViewController.isScrolledToBottom && !controller.isEditingMessage && !controller.isReplyingToMessage) {
        self.collectionController = nil;
        self.contentViewController.searchQueries = @[];
        [self.contentViewController scrollToBottom];
    }

    [self setGuestBarForceHidden:YES];
    return YES;
}

- (BOOL)conversationInputBarViewControllerShouldEndEditing:(ConversationInputBarViewController *)controller
{
    [self setGuestBarForceHidden:NO];
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
    [self.contentViewController scrollToMessage:message completion:^(UIView * cell) {
        [self.contentViewController highlightMessage:message];
    }];
}

- (void)conversationInputBarViewControllerEditLastMessage
{
    [self.contentViewController editLastMessage];
}

@end

@implementation ConversationViewController (ZMConversationObserver)

- (void)conversationDidChange:(ConversationChangeInfo *)note
{
    if (note.causedByConversationPrivacyChange) {
        [self presentPrivacyWarningAlertForChange:note];
    }
    
    if (note.participantsChanged || note.connectionStateChanged) {
        [self updateRightNavigationItemsButtons];
        [self updateLeftNavigationBarItems];
        [self updateOutgoingConnectionVisibility];
        [self.contentViewController updateTableViewHeaderView];
        [self updateInputBarVisibility];
    }

    if (note.participantsChanged || note.externalParticipantsStateChanged) {
        [self updateGuestsBarVisibility];
    }

    if (note.nameChanged || note.securityLevelChanged || note.connectionStateChanged || note.legalHoldStatusChanged) {
        [self setupNavigatiomItem];
    }
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

