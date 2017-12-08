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
@import PureLayout;

#import "Settings.h"

#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"

// helpers
#import "WAZUIMagicIOS.h"
#import "Analytics.h"


// model
#import "WireSyncEngine+iOS.h"
#import "Message+UI.h"

// ui
#import "ConversationContentViewController.h"
#import "ConversationContentViewController+Scrolling.h"
#import "TextView.h"
#import "TextMessageCell.h"

#import "ZClientViewController.h"
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
#import "MediaPlaybackManager.h"
#import "BarController.h"
#import "ContactsDataSource.h"
#import "VerticalTransition.h"

#import "UIColor+WAZExtensions.h"
#import "AnalyticsTracker.h"
#import "AnalyticsTracker+Invitations.h"
#import "UIViewController+Errors.h"
#import "SplitViewController.h"
#import "UIColor+WR_ColorScheme.h"
#import "ActionSheetController+Conversation.h"
#import "UIResponder+FirstResponder.h"

#import "Wire-Swift.h"



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

@interface ConversationViewController (AddParticipants) <AddParticipantsViewControllerDelegate>
@end

@interface ConversationViewController (ZMConversationObserver) <ZMConversationObserver>
@end

@interface ConversationViewController (UINavigationControllerDelegate) <UINavigationControllerDelegate>
@end

@interface ConversationViewController (VerticalTransitionDataSource) <VerticalTransitionDataSource>
@end

@interface ConversationViewController (ConversationListObserver) <ZMConversationListObserver>
@end

@interface ConversationViewController ()

@property (nonatomic) ConversationDetailsTransitioningDelegate *conversationDetailsTransitioningDelegate;
@property (nonatomic) BarController *conversationBarController;
@property (nonatomic) MediaBarViewController *mediaBarViewController;

@property (nonatomic) ConversationContentViewController *contentViewController;
@property (nonatomic) UIViewController *participantsController;

@property (nonatomic) BOOL mediaBarAnimationInFlight;

@property (nonatomic) ConversationInputBarViewController *inputBarController;
@property (nonatomic) OutgoingConnectionViewController *outgoingConnectionViewController;

@property (nonatomic) NSLayoutConstraint *inputBarBottomMargin;
@property (nonatomic) NSLayoutConstraint *inputBarZeroHeight;
@property (nonatomic) InvisibleInputAccessoryView *invisibleInputAccessoryView;

@property (nonatomic) id voiceChannelStateObserverToken;
@property (nonatomic) id conversationObserverToken;

@property (nonatomic) AnalyticsTracker *analyticsTracker;

@property (nonatomic) BOOL isAppearing;
@property (nonatomic) ConversationTitleView *titleView;
@property (nonatomic) CollectionsViewController *collectionController;
@property (nonatomic) id conversationListObserverToken;
@end



@implementation ConversationViewController

- (void)dealloc
{
    [self dismissCollectionIfNecessary];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

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

    self.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextConversation];
    self.conversationDetailsTransitioningDelegate = [[ConversationDetailsTransitioningDelegate alloc] init];
    self.conversationDetailsTransitioningDelegate.dataSource = self;
    
    [self createInputBarController];
    [self createContentViewController];
    [self createConversationBarController];
    [self createMediaBarViewController];

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
    self.mediaBarViewController = [[MediaBarViewController alloc] initWithMediaPlaybackManager:[AppDelegate sharedAppDelegate].mediaPlaybackManager];
    [self.mediaBarViewController.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMediaBar:)]];
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
    
    self.isAppearing = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self updateLeftNavigationBarItems];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self updateLeftNavigationBarItems];
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
    }
}

- (void)setupNavigatiomItem
{
    self.titleView = [[ConversationTitleView alloc] initWithConversation:self.conversation interactive:YES];
    
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
    self.navigationItem.leftItemsSupplementBackButton = NO;

    [self updateRightNavigationItemsButtons];
}

- (void)updateInputBarVisibility
{
    self.inputBarZeroHeight.active = self.conversation.isReadOnly;
    [self.view setNeedsLayout];
}

- (UIViewController *)participantsController
{
    UIViewController *viewController = nil;

    switch (self.conversation.conversationType) {
        case ZMConversationTypeGroup: {
            ParticipantsViewController *participantsViewController = [[ParticipantsViewController alloc] initWithConversation:self.conversation];
            participantsViewController.delegate = self;
            participantsViewController.zClientViewController = [ZClientViewController sharedZClientViewController];
            participantsViewController.shouldDrawTopSeparatorLineDuringPresentation = YES;
            viewController = participantsViewController;
            break;
        }
        case ZMConversationTypeSelf:
        case ZMConversationTypeOneOnOne:
        case ZMConversationTypeConnection:
        {
            ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithUser:self.conversation.firstActiveParticipantOtherThanSelf
                                                                                          conversation:self.conversation];
            profileViewController.delegate = self;
            profileViewController.shouldDrawTopSeparatorLineDuringPresentation = YES;
            viewController = profileViewController;
            break;
        }
        case ZMConversationTypeInvalid:
            RequireString(false, "Trying to open invalid conversation");
            break;
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

- (void)conversationContentViewController:(ConversationContentViewController *)contentViewController didTriggerAddContactsButton:(UIButton *)button
{
    AddParticipantsViewController *addParticipantsViewController = [[AddParticipantsViewController alloc] initWithConversation:self.conversation];
    addParticipantsViewController.delegate = self;
    addParticipantsViewController.modalPresentationStyle = UIModalPresentationPopover;
    addParticipantsViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    UIPopoverPresentationController *popoverPresentationController = addParticipantsViewController.popoverPresentationController;
    popoverPresentationController.sourceView = button;
    popoverPresentationController.sourceRect = button.bounds;
    popoverPresentationController.delegate = addParticipantsViewController;

    [self presentViewController:addParticipantsViewController animated:YES completion:nil];
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

- (BOOL)conversationContentViewController:(ConversationContentViewController *)controller shouldBecomeFirstResponderWhenShowMenuFromCell:(UITableViewCell *)cell
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

- (BOOL)conversationInputBarViewControllerShouldBeginEditing:(ConversationInputBarViewController *)controller isEditingMessage:(BOOL)isEditing
{
    if (! self.contentViewController.isScrolledToBottom && !isEditing) {
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
    ConversationType conversationType = (self.conversation.conversationType == ZMConversationTypeGroup) ? ConversationTypeGroup : ConversationTypeOneToOne;
    MessageType messageType = [Message messageType:message];
    NSTimeInterval elapsedTime = 0 - [message.serverTimestamp timeIntervalSinceNow];
    [[ZMUserSession sharedSession] enqueueChanges:^{
        if (newText == nil || [newText isEqualToString:@""]) {
            [[Analytics shared] tagDeletedMessage:messageType messageDeletionType:MessageDeletionTypeEverywhere conversationType:conversationType timeElapsed:elapsedTime];
            [ZMMessage deleteForEveryone:message];
        } else {
            [[Analytics shared] tagEditedMessageConversationType:conversationType timeElapsed:elapsedTime];
            BOOL fetchLinkPreview = ![[Settings sharedSettings] disableLinkPreviews];
            (void)[ZMMessage edit:message newText:newText fetchLinkPreview:fetchLinkPreview];
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
    [self dismissViewControllerAnimated:YES completion:completion];
}

- (void)profileViewController:(ProfileViewController *)controller wantsToNavigateToConversation:(ZMConversation *)conversation
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.zClientViewController selectConversation:conversation
                                           focusOnView:YES
                                              animated:YES];
    }];
}

- (void)profileViewController:(ProfileViewController *)controller wantsToAddUsers:(NSSet *)users toConversation:(ZMConversation *)conversation
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self addParticipants:users];
    }];
}

@end


@implementation ConversationViewController (AddParticipants)

- (void)addParticipantsViewControllerDidCancel:(AddParticipantsViewController *)addParticipantsViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addParticipantsViewController:(AddParticipantsViewController *)addParticipantsViewController didSelectUsers:(NSSet<ZMUser *> *)users
{
    [addParticipantsViewController dismissViewControllerAnimated:YES completion:^{
        [self addParticipants:users];
    }];
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
    
    if (note.nameChanged || note.securityLevelChanged || note.connectionStateChanged) {
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
                                                      [self.conversation resendMessagesThatCausedConversationSecurityDegradation];
                                                      [self dismissViewControllerAnimated:YES completion:nil];
                                                  } else if (showDetailsPressed) {
                                                      [self.conversation doNotResendMessagesThatCausedDegradation];
                                                      if (self.conversation.conversationType == ZMConversationTypeOneOnOne) {
                                                          ZMUser *user = self.conversation.connectedUser;
                                                          if (user.clients.count == 1) {
                                                              ProfileClientViewController *userClientController = [[ProfileClientViewController alloc] initWithClient:user.clients.anyObject fromConversation:YES];
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
    [self.conversation doNotResendMessagesThatCausedDegradation];
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

@implementation ConversationViewController (VerticalTransitionDataSource)

- (NSArray<UIView *> *)viewsToHideDuringVerticalTransition:(VerticalTransition *)transition
{
    NSMutableArray<UIView *> *viewsToHide = [[NSMutableArray alloc] init];
    
    if ([self.parentViewController isKindOfClass:[ConversationRootViewController class]]) {
        ConversationRootViewController *convRootViewController = (ConversationRootViewController *)self.parentViewController;
        [viewsToHide addObject:convRootViewController.customNavBar];
    }
    
    [viewsToHide addObject:self.inputBarController.view];
    
    return viewsToHide;
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

