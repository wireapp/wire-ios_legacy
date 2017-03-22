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
#import "ConversationListViewController+StartUI.h"

#import <PureLayout/PureLayout.h>
@import WireExtensionComponents;

#import "Settings.h"
#import "UIScrollView+Zeta.h"

#import "ZClientViewController.h"
#import "ZClientViewController+Internal.h"
#import "SearchViewController.h"
#import "PeopleInputController.h"

#import "Constants.h"
#import "PermissionDeniedViewController.h"
#import "AnalyticsTracker.h"

#import "zmessaging+iOS.h"

#import "ConversationListContentController.h"
#import "ConversationListInteractiveItem.h"
#import "StartUIViewController.h"
#import "KeyboardAvoidingViewController.h"

// helpers

#import "WAZUIMagicIOS.h"
#import "Analytics+iOS.h"
#import "UIView+MTAnimation.h"
#import "UIView+Borders.h"
#import "NSAttributedString+Wire.h"

// Transitions
#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"
#import "PassthroughTouchesView.h"

#import "UIViewController+Orientation.h"

#import "ActionSheetController.h"
#import "ActionSheetController+Conversation.h"

#import "InviteBannerViewController.h"

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

@interface ConversationListViewController (PermissionDenied) <PermissionDeniedViewControllerDelegate>
@end

@interface ConversationListViewController (ConversationListObserver) <ZMConversationListObserver>

- (void)updateArchiveButtonVisibility;

@end

@interface ConversationListViewController (InitialSyncObserver) <ZMInitialSyncCompletionObserver>
@end



@interface ConversationListViewController ()

@property (nonatomic) ZMConversation *selectedConversation;
@property (nonatomic) ConversationListState state;

@property (nonatomic, weak) id<UserProfile> userProfile;
@property (nonatomic) NSObject *userProfileObserverToken;
@property (nonatomic) id userObserverToken;
@property (nonatomic) id allConversationsObserverToken;

@property (nonatomic) ConversationListContentController *listContentController;
@property (nonatomic) InviteBannerViewController *invitationBannerViewController;
@property (nonatomic) ConversationListBottomBarController *bottomBarController;
@property (nonatomic) ToolTipViewController *tooltipViewController;

@property (nonatomic) ConversationListTopBar *topBar;
@property (nonatomic) UIView *contentContainer;
@property (nonatomic) UIView *conversationListContainer;
@property (nonatomic) UILabel *noConversationLabel;

@property (nonatomic) PermissionDeniedViewController *pushPermissionDeniedViewController;

@property (nonatomic) NSLayoutConstraint *bottomBarBottomOffset;
@property (nonatomic) NSLayoutConstraint *bottomBarToolTipConstraint;

@property (nonatomic) CGFloat contentControllerBottomInset;

@property (nonatomic) BOOL initialSyncCompleted;


- (void)setState:(ConversationListState)state animated:(BOOL)animated;

@end



@implementation ConversationListViewController
@synthesize startUISelectedUsers;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeUserProfileObserver];
    [ZMUserSession removeInitalSyncCompletionObserver:self];
}

- (void)removeUserProfileObserver
{
    [self.userProfile removeObserverWithToken:self.userProfileObserverToken];
}

- (void)loadView
{
    self.view = [[PassthroughTouchesView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentControllerBottomInset = 16;
    
    self.contentContainer = [[UIView alloc] initForAutoLayout];
    self.contentContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentContainer];

    self.userProfile = ZMUserSession.sharedSession.userProfile;
    self.userObserverToken = [UserChangeInfo addUserObserver:self forUser:[ZMUser selfUser]];

    self.conversationListContainer = [[UIView alloc] initForAutoLayout];
    self.conversationListContainer.backgroundColor = [UIColor clearColor];
    [self.contentContainer addSubview:self.conversationListContainer];

    [ZMUserSession addInitalSyncCompletionObserver:self];
    self.initialSyncCompleted = ZMUserSession.sharedSession.initialSyncOnceCompleted.boolValue;

    [self createTopBar];
    [self createNoConversationLabel];
    [self createListContentController];
    [self createBottomBarController];
    
    [self createViewConstraints];
    if (![Settings.sharedSettings contactTipWasDisplayed]) {
        [self showTooltipView];
    }
    [self.listContentController.collectionView scrollRectToVisible:CGRectMake(0, 0, self.view.bounds.size.width, 1) animated:NO];
    
    [self updateNoConversationVisibility];
    [self updateArchiveButtonVisibility];
    
    self.allConversationsObserverToken = [ConversationListChangeInfo addObserver:self forList:[SessionObjectCache sharedCache].allConversations];

    [self showPushPermissionDeniedDialogIfNeeded];
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

    if (! IS_IPAD) {
        [Settings sharedSettings].lastViewedScreen = SettingsLastScreenList;
    }
    
    [self updateBottomBarSeparatorVisibilityWithContentController:self.listContentController];
    [self closePushPermissionDialogIfNotNeeded];
}

- (void)requestSuggestedHandlesIfNeeded
{
    if (nil == ZMUser.selfUser.handle && self.initialSyncCompleted && !ZMUserSession.sharedSession.isPendingHotFixChanges) {
        self.userProfileObserverToken = [self.userProfile addObserver:self];
        [self.userProfile suggestHandles];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)createNoConversationLabel;
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *titleAttributes = @{
                                      NSForegroundColorAttributeName : [UIColor whiteColor],
                                      NSFontAttributeName : [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"],
                                      NSParagraphStyleAttributeName : paragraphStyle
                                      };
    
    paragraphStyle.paragraphSpacing = 4;
    NSDictionary *textAttributes = @{
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSFontAttributeName : [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"],
                                     NSParagraphStyleAttributeName : paragraphStyle
                                     };
   
    NSString *titleString = NSLocalizedString(@"contacts_ui.no_contact.title", nil);
    NSString *messageString = NSLocalizedString(@"contacts_ui.no_contact.message", nil);
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[titleString uppercaseString]
                                                                                         attributes:titleAttributes];
    [attributedString appendString:[messageString uppercaseString]
                        attributes:textAttributes];
    
    self.noConversationLabel = [[UILabel alloc] initForAutoLayout];
    self.noConversationLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:attributedString];
    self.noConversationLabel.numberOfLines = 0;
    [self.contentContainer addSubview:self.noConversationLabel];
}

- (void)createBottomBarController
{
    self.bottomBarController = [[ConversationListBottomBarController alloc] initWithDelegate:self user:ZMUser.selfUser];
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
    StartUIViewController *startUIViewController = [StartUIViewController new];
    startUIViewController.delegate = self;
    return startUIViewController;
}

- (SettingsNavigationController *)createSettingsViewController
{
    SettingsNavigationController *settingsViewController = [SettingsNavigationController settingsNavigationController];

    return settingsViewController;
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
            [self.presentedViewController dismissViewControllerAnimated:YES completion:completion];
        }
            break;
        case ConversationListStatePeoplePicker: {
            StartUIViewController *startUIViewController = self.createPeoplePickerController;
            [self showViewController:startUIViewController animated:YES completion:^{
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
    [self.conversationListContainer autoPinEdgesToSuperviewEdges];
    
    [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    self.bottomBarBottomOffset = [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [self.topBar autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(IS_IPAD ? 0 : 20, 0, 0, 0) excludingEdge:ALEdgeBottom];
    [self.topBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.contentContainer];
    [self.contentContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    
    [self.noConversationLabel autoCenterInSuperview];
    [self.noConversationLabel autoSetDimension:ALDimensionHeight toSize:120.0f];
    [self.noConversationLabel autoSetDimension:ALDimensionWidth toSize:240.0f];

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

#pragma mark - ToolTipView

- (void)createToolTipController;
{
    @weakify(self)
    ToolTip *toolTip = [[ToolTip alloc] initWithTitle:NSLocalizedString(@"tool_tip.contacts.title", nil)
                                          description:NSLocalizedString(@"tool_tip.contacts.message", nil)
                                              handler:^{
                                                  [Settings.sharedSettings setContactTipWasDisplayed:YES];
                                                  @strongify(self)
                                                  [self setState:ConversationListStatePeoplePicker animated:YES completion:^{
                                                      @strongify(self)
                                                      [self removeTooltipView];
                                                  }];
                                              }];
    
    self.tooltipViewController = [[ToolTipViewController alloc] initWithToolTip:toolTip];
    self.tooltipViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.tooltipViewController.toolTip = toolTip;
    [self.conversationListContainer addSubview:self.tooltipViewController.view];
    [self addChildViewController:self.tooltipViewController];
    [self.tooltipViewController didMoveToParentViewController:self];
}

- (void)updateConstraintWithToolTip;
{
    [self.tooltipViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.tooltipViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.tooltipViewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    self.bottomBarBottomOffset.active = NO;
    self.bottomBarToolTipConstraint = [self.bottomBarController.view autoPinEdge:ALEdgeBottom
                                                                          toEdge:ALEdgeTop
                                                                          ofView:self.tooltipViewController.view
                                                                      withOffset:self.tooltipViewController.padding];
}

- (void)showTooltipView;
{
    self.bottomBarController.showTooltip = YES;
    [self createToolTipController];
    [self updateConstraintWithToolTip];
    [self.tooltipViewController makeTipPointToView:self.bottomBarController.contactsButton.imageView];
}

- (void)removeTooltipView;
{
    self.bottomBarController.showTooltip = NO;
    if (self.tooltipViewController.parentViewController) {
        self.bottomBarToolTipConstraint.active = NO;
        self.bottomBarBottomOffset.active = YES;
        
        [self.tooltipViewController.view removeFromSuperview];
        [self.tooltipViewController removeFromParentViewController];
    }
}

#pragma mark - Selection

- (void)selectConversation:(ZMConversation *)conversation
{
    [self selectConversation:conversation focusOnView:NO animated:NO];
}

- (void)selectConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus animated:(BOOL)animated
{
    [self selectConversation:conversation focusOnView:focus animated:animated completion:nil];
}

- (void)selectConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    self.selectedConversation = conversation;
    
    @weakify(self);
    [self dismissPeoplePickerWithCompletionBlock:^{
        @strongify(self);
        [self.listContentController selectConversation:self.selectedConversation focusOnView:focus animated:animated completion:completion];
    }];
}

- (BOOL)selectInboxAndFocusOnView:(BOOL)focus
{
    [self setState:ConversationListStateConversationList animated:NO];
    return [self.listContentController selectInboxAndFocusOnView:focus];
}

- (void)scrollToCurrentSelectionAnimated:(BOOL)animated
{
    [self.listContentController scrollToCurrentSelectionAnimated:animated];
}

- (void)showActionMenuForConversation:(ZMConversation *)conversation
{
    ActionSheetController *controller = [ActionSheetController dialogForConversationDetails:conversation style:ActionSheetControllerStyleDark];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Push permissions

- (void)showPushPermissionDeniedDialogIfNeeded
{
    // We only want to present the notification takeover when the user already has a handle
    // and is not coming from the registration flow (where we alreday ask for permissions).
    if (! self.isComingFromRegistration || nil == ZMUser.selfUser.handle) {
        return;
    }

    if (AutomationHelper.sharedHelper.skipFirstLoginAlerts || self.usernameTakeoverViewController != nil) {
        return;
    }
    
    BOOL pushAlertHappenedMoreThan1DayBefore = [[Settings sharedSettings] lastPushAlertDate] == nil ||
    fabs([[[Settings sharedSettings] lastPushAlertDate] timeIntervalSinceNow]) > 60 * 60 * 24;
    
    BOOL pushNotificationsDisabled = ! [[UIApplication sharedApplication] isRegisteredForRemoteNotifications] ||
    [[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone;
    
    if (pushNotificationsDisabled && pushAlertHappenedMoreThan1DayBefore) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[Settings sharedSettings] setLastPushAlertDate:[NSDate date]];
        PermissionDeniedViewController *permissions = [PermissionDeniedViewController pushDeniedViewController];
        permissions.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextPostLogin];
        permissions.delegate = self;
        
        [self addChildViewController:permissions];
        [self.view addSubview:permissions.view];
        [permissions didMoveToParentViewController:self];
        
        [permissions.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        self.pushPermissionDeniedViewController = permissions;
        
        self.contentContainer.alpha = 0.0f;
    }
}

- (void)closePushPermissionDialogIfNotNeeded
{
    BOOL pushNotificationsDisabled = ! [[UIApplication sharedApplication] isRegisteredForRemoteNotifications] ||
    [[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone;
    
    if (self.pushPermissionDeniedViewController != nil && ! pushNotificationsDisabled) {
        [self closePushPermissionDeniedDialog];
    }
}

- (void)closePushPermissionDeniedDialog
{
    [self.pushPermissionDeniedViewController willMoveToParentViewController:nil];
    [self.pushPermissionDeniedViewController.view removeFromSuperview];
    [self.pushPermissionDeniedViewController removeFromParentViewController];
    self.pushPermissionDeniedViewController = nil;
    
    self.contentContainer.alpha = 1.0f;
}

- (void)applicationDidBecomeActive:(NSNotification *)notif
{
    [self closePushPermissionDialogIfNotNeeded];
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
    SettingsNavigationController *settingsViewController = [self createSettingsViewController];
    KeyboardAvoidingViewController *keyboardAvoidingWrapperController = [[KeyboardAvoidingViewController alloc] initWithViewController:settingsViewController];
    
    if (self.wr_splitViewController.layoutSize == SplitViewControllerLayoutSizeCompact) {
        keyboardAvoidingWrapperController.topInset = 20;
        @weakify(keyboardAvoidingWrapperController);
        settingsViewController.dismissAction = ^(SettingsNavigationController *controller) {
            @strongify(keyboardAvoidingWrapperController);
            [keyboardAvoidingWrapperController dismissViewControllerAnimated:YES completion:nil];
        };
        
        keyboardAvoidingWrapperController.modalPresentationStyle = UIModalPresentationCurrentContext;
        keyboardAvoidingWrapperController.transitioningDelegate = self;
        [self presentViewController:keyboardAvoidingWrapperController animated:YES completion:nil];
    }
    else {
        settingsViewController.dismissAction = ^(SettingsNavigationController *controller) {
            [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        };
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
                             self.noConversationLabel.alpha = 1.0f;
                         }];
    }
}

- (void)hideNoContactLabel;
{
    [UIView animateWithDuration:0.20
                     animations:^{
                         self.noConversationLabel.alpha = 0.0f;
                     }];
}

- (void)updateNoConversationVisibility;
{
    NSUInteger conversationsCount = [SessionObjectCache sharedCache].conversationList.count;
    BOOL shouldDisplayNoContact = conversationsCount == 0;
    
    if (shouldDisplayNoContact) {
        [self showNoContactLabel];
    } else {
        [self hideNoContactLabel];
    }
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
    [self.topBar.separatorLineView scrollViewDidScrollWithScrollView:controller.collectionView];
}

- (void)conversationList:(ConversationListViewController *)controller didSelectConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus
{
    _selectedConversation = conversation;
}

- (void)conversationList:(ConversationListViewController *)controller didSelectInteractiveItem:(ConversationListInteractiveItem *)interactiveItem focusOnView:(BOOL)focus
{
    
}

- (void)conversationList:(ConversationListContentController *)controller willSelectIndexPathAfterSelectionDeleted:(NSIndexPath *)conv
{
    if (IS_IPAD_PORTRAIT_LAYOUT) {
        [[ZClientViewController sharedZClientViewController] transitionToListAnimated:YES completion:nil];
    }
}

- (void)conversationListContentController:(ConversationListContentController *)controller wantsActionMenuForConversation:(ZMConversation *)conversation
{
    [self showActionMenuForConversation:conversation];
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
        case ConversationListButtonTypeContacts: {
            [Settings.sharedSettings setContactTipWasDisplayed:YES];
            @weakify(self)
            [self setState:ConversationListStatePeoplePicker animated:YES completion:^{
                @strongify(self)
                [self removeTooltipView];
            }];
        }
            break;
            
        case ConversationListButtonTypeArchive:
            [self setState:ConversationListStateArchived animated:YES];
            [Analytics.shared tagArchiveOpened];
            break;
            
        default:
            break;
    }
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
        [Analytics.shared tagUnarchivedConversation];
        [self setState:ConversationListStateConversationList animated:YES completion:^{
            @strongify(self)
            [self.listContentController selectConversation:conversation focusOnView:YES animated:YES];
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
    [UIView transitionWithView:self.bottomBarController.view
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.bottomBarController.showArchived = [SessionObjectCache.sharedCache archivedConversations].count > 0;
    } completion:nil];
}

@end

@implementation ConversationListViewController (InitialSyncObserver)

- (void)initialSyncCompleted:(NSNotification *)notification
{
    self.initialSyncCompleted = YES;
    [self requestSuggestedHandlesIfNeeded];
}

@end
