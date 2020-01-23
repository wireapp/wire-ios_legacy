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


// helpers
#import "Analytics.h"


// model


// ui
#import "ConversationContentViewController.h"
#import "TextView.h"

#import "ConversationViewController+ParticipantsPopover.h"
#import "MediaPlayer.h"
#import "UIView+Zeta.h"
#import "ConversationInputBarViewController.h"
#import "ContactsDataSource.h"
#import "VerticalTransition.h"

#import "UIViewController+Errors.h"
#import "SplitViewController.h"

#import "Wire-Swift.h"
/*
static NSString* ZMLogTag ZM_UNUSED = @"UI";


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
                    [self.conversation.connectedUser cancelConnectionRequest];
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
            viewController = [self createUserDetailViewController];
            break;
        }
        case ZMConversationTypeInvalid:
            RequireString(false, "Trying to open invalid conversation");
            break;
    }

    _participantsController = viewController.wrapInNavigationController;

    return _participantsController;
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

@end
*/
