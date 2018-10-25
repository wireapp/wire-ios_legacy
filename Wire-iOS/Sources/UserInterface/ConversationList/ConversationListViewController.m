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


#import "ConversationListViewController.h"
#import "ConversationListViewController+Private.h"
#import "ConversationListViewController+Internal.h"
#import "ConversationListViewController+StartUI.h"

@import PureLayout;
@import WireExtensionComponents;

#import "Settings.h"
#import "UIScrollView+Zeta.h"

#import "ZClientViewController.h"
#import "ZClientViewController+Internal.h"

#import "Constants.h"
#import "PermissionDeniedViewController.h"

#import "WireSyncEngine+iOS.h"

#import "ConversationListContentController.h"
#import "StartUIViewController.h"
#import "KeyboardAvoidingViewController.h"

// helpers

#import "Analytics.h"
#import "NSAttributedString+Wire.h"

// Transitions
#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"
#import "PassthroughTouchesView.h"

#import "Wire-Swift.h"

@interface ConversationListViewController (Content) <ConversationListContentDelegate>

- (void)updateBottomBarSeparatorVisibilityWithContentController:(ConversationListContentController *)controller;

@end

@interface ConversationListViewController (BottomBarDelegate) <ConversationListBottomBarControllerDelegate>
@end

@interface ConversationListViewController (StartUI) <StartUIDelegate>
@end

@interface ConversationListViewController (Archive) <ArchivedListViewControllerDelegate>
@end

@interface ConversationListViewController (InitialSyncObserver) <ZMInitialSyncCompletionObserver>
@end

@interface ConversationListViewController (ConversationListObserver) <ZMConversationListObserver>

- (void)updateArchiveButtonVisibility;

@end


@interface ConversationListViewController ()

@property (nonatomic) ZMConversation *selectedConversation;
@property (nonatomic) ConversationListState state;

@property (nonatomic, weak) id<UserProfile> userProfile;
@property (nonatomic) NSObject *userProfileObserverToken;
@property (nonatomic) id userObserverToken;
@property (nonatomic) id allConversationsObserverToken;
@property (nonatomic) id connectionRequestsObserverToken;
@property (nonatomic) id initialSyncObserverToken;

@property (nonatomic) ConversationListContentController *listContentController;
@property (nonatomic) ConversationListBottomBarController *bottomBarController;

@property (nonatomic) ConversationListTopBar *topBar;
@property (nonatomic) NetworkStatusViewController *networkStatusViewController;

/// for NetworkStatusViewDelegate
@property (nonatomic) BOOL shouldAnimateNetworkStatusView;

@property (nonatomic) UIView *contentContainer;
@property (nonatomic) UIView *conversationListContainer;
@property (nonatomic) ConversationListOnboardingHint *onboardingHint;

@property (nonatomic) NSLayoutConstraint *bottomBarBottomOffset;
@property (nonatomic) NSLayoutConstraint *bottomBarToolTipConstraint;

@property (nonatomic) CGFloat contentControllerBottomInset;

/// for data usage dialog
@property (nonatomic) BOOL viewDidAppearCalled;

@property (nonatomic) BOOL dataUsagePermissionDialogDisplayed;

- (void)setState:(ConversationListState)state animated:(BOOL)animated;

@end



@implementation ConversationListViewController

- (void)dealloc
{
    [self removeUserProfileObserver];
}

- (void)removeUserProfileObserver
{
    self.userProfileObserverToken = nil;
}

- (void)loadView
{
    self.view = [[PassthroughTouchesView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.viewDidAppearCalled = NO;
    self.dataUsagePermissionDialogDisplayed = NO;

    self.contentControllerBottomInset = 16;
    self.shouldAnimateNetworkStatusView = NO;
    
    self.contentContainer = [[UIView alloc] initForAutoLayout];
    self.contentContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentContainer];

    self.userProfile = ZMUserSession.sharedSession.userProfile;
    if ([ZMUserSession sharedSession] != nil) {
        self.userObserverToken = [UserChangeInfo addObserver:self forUser:[ZMUser selfUser] userSession:[ZMUserSession sharedSession]];
        self.initialSyncObserverToken = [ZMUserSession addInitialSyncCompletionObserver:self userSession:[ZMUserSession sharedSession]];
    }
    
    self.onboardingHint = [[ConversationListOnboardingHint alloc] init];
    [self.contentContainer addSubview:self.onboardingHint];

    self.conversationListContainer = [[UIView alloc] initForAutoLayout];
    self.conversationListContainer.backgroundColor = [UIColor clearColor];
    [self.contentContainer addSubview:self.conversationListContainer];

    [self createNoConversationLabel];
    [self createListContentController];
    [self createBottomBarController];
    [self createTopBar];
    [self createNetworkStatusBar];

    [self createViewConstraints];
    [self.listContentController.collectionView scrollRectToVisible:CGRectMake(0, 0, self.view.bounds.size.width, 1) animated:NO];
    
    [self hideNoContactLabelAnimated:NO];
    [self updateNoConversationVisibility];
    [self updateArchiveButtonVisibility];
    
    [self updateObserverTokensForActiveTeam];
    [self showPushPermissionDeniedDialogIfNeeded];

    [self setupStyle];
}

- (void)updateObserverTokensForActiveTeam
{
    if ([ZMUserSession sharedSession] != nil) {
        self.allConversationsObserverToken = [ConversationListChangeInfo addObserver:self
                                                                             forList:[ZMConversationList conversationsIncludingArchivedInUserSession:[ZMUserSession sharedSession]]
                                                                         userSession:[ZMUserSession sharedSession]];
        self.connectionRequestsObserverToken = [ConversationListChangeInfo addObserver:self
                                                                               forList:[ZMConversationList pendingConnectionConversationsInUserSession:[ZMUserSession sharedSession]]
                                                                           userSession:[ZMUserSession sharedSession]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [self.selectedConversation savePendingLastRead];
    }];

    [self requestSuggestedHandlesIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (! IS_IPAD_FULLSCREEN) {
        [Settings sharedSettings].lastViewedScreen = SettingsLastScreenList;
    }
    
    _state = ConversationListStateConversationList;
    
    [self updateBottomBarSeparatorVisibilityWithContentController:self.listContentController];
    [self closePushPermissionDialogIfNotNeeded];

    self.shouldAnimateNetworkStatusView = YES;

    if (! self.viewDidAppearCalled) {
        self.viewDidAppearCalled = YES;

        [self showDataUsagePermissionDialogIfNeeded];
    }
}

- (void)requestSuggestedHandlesIfNeeded
{
    if (nil == ZMUser.selfUser.handle &&
        ZMUserSession.sharedSession.hasCompletedInitialSync &&
        !ZMUserSession.sharedSession.isPendingHotFixChanges) {
        
        self.userProfileObserverToken = [self.userProfile addObserver:self];
        [self.userProfile suggestHandles];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.presentedViewController != nil) {
        if (![self.presentedViewController isKindOfClass:UIAlertController.class]) {
            return self.presentedViewController.preferredStatusBarStyle;
        }
    }

    return UIStatusBarStyleLightContent;
}

- (void)createNoConversationLabel;
{
    self.noConversationLabel = [[UILabel alloc] initForAutoLayout];
    self.noConversationLabel.attributedText = self.attributedTextForNoConversationLabel;
    self.noConversationLabel.numberOfLines = 0;
    [self.contentContainer addSubview:self.noConversationLabel];
}

- (NSAttributedString *)attributedTextForNoConversationLabel
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *titleAttributes = @{
                                      NSForegroundColorAttributeName : [UIColor whiteColor],
                                      NSFontAttributeName : UIFont.smallMediumFont,
                                      NSParagraphStyleAttributeName : paragraphStyle
                                      };

    paragraphStyle.paragraphSpacing = 4;

    NSString *titleLocalizationKey = @"conversation_list.empty.all_archived.message";
    NSString *titleString = NSLocalizedString(titleLocalizationKey, nil);

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[titleString uppercaseString]
                                                                                         attributes:titleAttributes];
    
    return attributedString;
}

- (void)createBottomBarController
{
    self.bottomBarController = [[ConversationListBottomBarController alloc] initWithDelegate:self];
    self.bottomBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBarController.showArchived = YES;
    [self addChildViewController:self.bottomBarController];
    [self.conversationListContainer addSubview:self.bottomBarController.view];
    [self.bottomBarController didMoveToParentViewController:self];
}

- (ArchivedListViewController *)createArchivedListViewController
{
    ArchivedListViewController *archivedViewController = [ArchivedListViewController new];
    archivedViewController.delegate = self;
    return archivedViewController;
}

- (StartUIViewController *)createPeoplePickerController
{
    StartUIViewController *startUIViewController = [[StartUIViewController alloc] init];
    startUIViewController.delegate = self;
    return startUIViewController;
}

- (UIViewController *)createSettingsViewController
{
    SelfProfileViewController *selfProfileViewController = [[SelfProfileViewController alloc] init];
    return [selfProfileViewController wrapInNavigationController:ClearBackgroundNavigationController.class];
}

- (void)createListContentController
{
    self.listContentController = [[ConversationListContentController alloc] init];
    self.listContentController.collectionView.contentInset = UIEdgeInsetsMake(0, 0, self.contentControllerBottomInset, 0);
    self.listContentController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.listContentController.contentDelegate = self;

    [self addChildViewController:self.listContentController];
    [self.conversationListContainer addSubview:self.listContentController.view];
    [self.listContentController didMoveToParentViewController:self];
}

- (void)setState:(ConversationListState)state animated:(BOOL)animated
{
    [self setState:state animated:animated completion:nil];
}

- (void)setState:(ConversationListState)state animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    if (_state == state) {
        if (completion) {
            completion();
        }
        return;
    }
    self.state = state;

    switch (state) {
        case ConversationListStateConversationList: {
            self.view.alpha = 1;
            
            if (self.presentedViewController != nil) {
                [self.presentedViewController dismissViewControllerAnimated:YES completion:completion];
            }
            else {
                if (completion) {
                    completion();
                }
            }
        }
            break;
        case ConversationListStatePeoplePicker: {
            StartUIViewController *startUIViewController = self.createPeoplePickerController;
            UINavigationController *navigationWrapper = [startUIViewController wrapInNavigationController:[ClearBackgroundNavigationController class]];
            
            [self showViewController:navigationWrapper animated:YES completion:^{
                [startUIViewController showKeyboardIfNeeded];
                if (completion) {
                    completion();
                }
            }];
        }
            break;
        case ConversationListStateArchived: {
            [self showViewController:self.createArchivedListViewController animated:animated completion:^{
                if (completion) {
                    completion();
                }
            }];
        }
            break;
        default:
            break;
    }
}

- (void)showViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    viewController.transitioningDelegate = self;
    viewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self presentViewController:viewController animated:animated completion:^{
        if (completion) {
            completion();
        }
    }];
}

- (void)createViewConstraints
{
    [self.conversationListContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    
    [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    self.bottomBarBottomOffset = [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    [self.networkStatusViewController createConstraintsInParentControllerWithBottomView:self.topBar controller:self];
    
    [self.topBar autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.topBar autoPinEdgeToSuperviewEdge:ALEdgeRight];

    [self.topBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.conversationListContainer];
    
    [[self.contentContainer.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor] setActive:YES];
    [[self.contentContainer.topAnchor constraintEqualToAnchor:self.safeTopAnchor] setActive:YES];
    [[self.contentContainer.leadingAnchor constraintEqualToAnchor:self.view.safeLeadingAnchor] setActive:YES];
    [[self.contentContainer.trailingAnchor constraintEqualToAnchor:self.view.safeTrailingAnchor] setActive:YES];
    
    [self.noConversationLabel autoCenterInSuperview];
    [self.noConversationLabel autoSetDimension:ALDimensionHeight toSize:120.0f];
    [self.noConversationLabel autoSetDimension:ALDimensionWidth toSize:240.0f];
    
    [self.onboardingHint autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomBarController.view];
    [self.onboardingHint autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [self.onboardingHint autoPinEdgeToSuperviewMargin:ALEdgeRight];

    [self.listContentController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.listContentController.view autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomBarController.view];
    [self.listContentController.view autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.listContentController.view autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
        // orientation
        [self.listContentController reload];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)definesPresentationContext
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)setBackgroundColorPreference:(UIColor *)color
{
    [UIView animateWithDuration:0.4 animations:^{
        self.view.backgroundColor = color;
        self.listContentController.view.backgroundColor = color;
    }];
}

- (void)hideArchivedConversations
{
    [self setState:ConversationListStateConversationList animated:YES];
}

#pragma mark - Selection

- (void)selectConversation:(ZMConversation *)conversation
{
    [self selectConversation:conversation scrollToMessage:nil focusOnView:NO animated:NO];
}

- (void)selectConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated
{
    [self selectConversation:conversation scrollToMessage:message focusOnView:focus animated:animated completion:nil];
}

- (void)selectConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    self.selectedConversation = conversation;
    
    @weakify(self);
    [self dismissPeoplePickerWithCompletionBlock:^{
        @strongify(self);
        [self.listContentController selectConversation:self.selectedConversation scrollToMessage:message focusOnView:focus animated:animated completion:completion];
    }];
}

- (void)selectInboxAndFocusOnView:(BOOL)focus
{
    [self setState:ConversationListStateConversationList animated:NO];
    [self.listContentController selectInboxAndFocusOnView:focus];
}

- (void)scrollToCurrentSelectionAnimated:(BOOL)animated
{
    [self.listContentController scrollToCurrentSelectionAnimated:animated];
}

#pragma mark - Conversation Collection Vertical Pan Gesture Handling

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)presentPeoplePickerAnimated:(BOOL)animated
{
    [self setState:ConversationListStatePeoplePicker animated:animated];
}

- (void)presentSettings
{
    UIViewController *settingsViewController = [self createSettingsViewController];
    KeyboardAvoidingViewController *keyboardAvoidingWrapperController = [[KeyboardAvoidingViewController alloc] initWithViewController:settingsViewController];
    
    if (self.wr_splitViewController.layoutSize == SplitViewControllerLayoutSizeCompact) {
        keyboardAvoidingWrapperController.modalPresentationStyle = UIModalPresentationCurrentContext;
        keyboardAvoidingWrapperController.transitioningDelegate = self;
        [self presentViewController:keyboardAvoidingWrapperController animated:YES completion:nil];
    } else {
        keyboardAvoidingWrapperController.modalPresentationStyle = UIModalPresentationFormSheet;
        keyboardAvoidingWrapperController.view.backgroundColor = [UIColor blackColor];
        [self.parentViewController presentViewController:keyboardAvoidingWrapperController animated:YES completion:nil];
    }
}

- (void)dismissPeoplePickerWithCompletionBlock:(dispatch_block_t)block
{
    [self setState:ConversationListStateConversationList animated:YES completion:block];
}

- (void)showNoContactLabel;
{
    if (self.state == ConversationListStateConversationList) {
        [UIView animateWithDuration:0.20
                         animations:^{
                             self.noConversationLabel.alpha = self.hasArchivedConversations ? 1.0f : 0.0f;
                             self.onboardingHint.alpha = self.hasArchivedConversations ? 0.0f : 1.0f;
                         }];
    }
}

- (void)hideNoContactLabelAnimated:(BOOL)animated;
{
    [UIView animateWithDuration:animated ? 0.20 : 0.0
                     animations:^{
                         self.noConversationLabel.alpha = 0.0f;
                         self.onboardingHint.alpha = 0.0f;
                     }];
}

- (void)updateNoConversationVisibility;
{
    if (!self.hasConversations) {
        [self showNoContactLabel];
    } else {
        [self hideNoContactLabelAnimated:YES];
    }
}

- (BOOL)hasConversations
{
    ZMUserSession *session = ZMUserSession.sharedSession;
    NSUInteger conversationsCount = [ZMConversationList conversationsInUserSession:session].count +
    [ZMConversationList pendingConnectionConversationsInUserSession:session].count;
    return conversationsCount > 0;
}

- (BOOL)hasArchivedConversations
{
    return [ZMConversationList archivedConversationsInUserSession:ZMUserSession.sharedSession].count > 0;
}

@end



@implementation ConversationListViewController (Content)

- (void)updateBottomBarSeparatorVisibilityWithContentController:(ConversationListContentController *)controller
{
    CGFloat controllerHeight = CGRectGetHeight(controller.view.bounds);
    CGFloat contentHeight = controller.collectionView.contentSize.height;
    CGFloat offsetY = controller.collectionView.contentOffset.y;
    BOOL showSeparator = contentHeight - offsetY + self.contentControllerBottomInset > controllerHeight;
    
    if (self.bottomBarController.showSeparator != showSeparator) {
        self.bottomBarController.showSeparator = showSeparator;
    }
}

- (void)conversationListDidScroll:(ConversationListContentController *)controller
{
    [self updateBottomBarSeparatorVisibilityWithContentController:controller];
    
    [self.topBar scrollViewDidScroll:controller.collectionView];
}

- (void)conversationList:(ConversationListViewController *)controller didSelectConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus
{
    _selectedConversation = conversation;
}

- (void)conversationList:(ConversationListContentController *)controller willSelectIndexPathAfterSelectionDeleted:(NSIndexPath *)conv
{
    if (IS_IPAD_PORTRAIT_LAYOUT) {
        [[ZClientViewController sharedZClientViewController] transitionToListAnimated:YES completion:nil];
    }
}

- (void)conversationListContentController:(ConversationListContentController *)controller wantsActionMenuForConversation:(ZMConversation *)conversation fromSourceView:(UIView *)sourceView
{
    [self showActionMenuForConversation:conversation fromView:sourceView];
}

@end


@implementation ConversationListViewController (PermissionDenied)

- (void)continueWithoutPermission:(PermissionDeniedViewController *)viewController
{
    [self closePushPermissionDeniedDialog];
}

@end

#pragma mark - ConversationListBottomBarDelegate

@implementation ConversationListViewController (BottomBarDelegate)

- (void)conversationListBottomBar:(ConversationListBottomBarController *)bar didTapButtonWithType:(enum ConversationListButtonType)buttonType
{
    switch (buttonType) {
        case ConversationListButtonTypeArchive:
            [self setState:ConversationListStateArchived animated:YES];
            break;

        case ConversationListButtonTypeStartUI:
            [self presentPeoplePicker];
            break;

        case ConversationListButtonTypeCompose:
            [self presentDraftsViewController];
            break;
            
        case ConversationListButtonTypeCamera:
            [self showCameraPicker];
            break;
    }
}

- (void)presentDraftsViewController
{
    DraftsRootViewController *draftsController = [[DraftsRootViewController alloc] init];
    [ZClientViewController.sharedZClientViewController presentViewController:draftsController animated:YES completion:nil];
}

- (void)presentPeoplePicker
{
    [self setState:ConversationListStatePeoplePicker animated:YES completion:nil];
}

@end

@implementation ConversationListViewController (Archive)

- (void)archivedListViewControllerWantsToDismiss:(ArchivedListViewController *)controller
{
    [self setState:ConversationListStateConversationList animated:YES];
}

- (void)archivedListViewController:(ArchivedListViewController *)controller didSelectConversation:(ZMConversation *)conversation
{
    @weakify(self)
    [ZMUserSession.sharedSession enqueueChanges:^{
        conversation.isArchived = NO;
    } completionHandler:^{
        [self setState:ConversationListStateConversationList animated:YES completion:^{
            @strongify(self)
            [self.listContentController selectConversation:conversation scrollToMessage:nil focusOnView:YES animated:YES];
        }];
    }];
}

@end

@implementation ConversationListViewController (ConversationListObserver)

- (void)conversationListDidChange:(ConversationListChangeInfo *)changeInfo
{
    [self updateNoConversationVisibility];
    [self updateArchiveButtonVisibility];
}

- (void)updateArchiveButtonVisibility
{
    BOOL showArchived = self.hasArchivedConversations;
    if (showArchived == self.bottomBarController.showArchived) {
        return;
    }

    [UIView transitionWithView:self.bottomBarController.view
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.bottomBarController.showArchived = showArchived;
                    } completion:nil];
}

@end


@implementation ConversationListViewController (InitialSyncObserver)

- (void)initialSyncCompleted
{
    [self requestSuggestedHandlesIfNeeded];
}

@end
