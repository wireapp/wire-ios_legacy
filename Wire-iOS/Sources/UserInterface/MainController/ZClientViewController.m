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

@import QuartzCore;
@import PureLayout;

#import "ZClientViewController+Internal.h"

#import "SplitViewController.h"

#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"

#import "ConversationListViewController.h"
#import "ConversationViewController.h"
#import "ConnectRequestsViewController.h"
#import "ProfileViewController.h"

#import "WireSyncEngine+iOS.h"
#import "ZMConversation+Additions.h"

#import "AppDelegate.h"

#import "Constants.h"
#import "Analytics.h"
#import "Settings.h"

#import "Wire-Swift.h"

#import "NSLayoutConstraint+Helpers.h"
#import "StartUIViewController.h"

@interface ZClientViewController (InitialState) <SplitViewControllerDelegate>

- (void)restoreStartupState;
- (BOOL)attemptToLoadLastViewedConversationWithFocus:(BOOL)focus animated:(BOOL)animated;

@end


@interface ZClientViewController (NetworkAvailabilityObserver) <ZMNetworkAvailabilityObserver>

@end


@interface ZClientViewController () <ZMUserObserver>

@property (nonatomic, readwrite) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic) ColorSchemeController *colorSchemeController;
@property (nonatomic) BackgroundViewController *backgroundViewController;
@property (nonatomic, readwrite) ConversationListViewController *conversationListViewController;
@property (nonatomic, readwrite) UIViewController *conversationRootViewController;
@property (nonatomic, readwrite) ZMConversation *currentConversation;
@property (nonatomic) ShareExtensionAnalyticsPersistence *analyticsEventPersistence;

@property (nonatomic) id incomingApnsObserver;
@property (nonatomic) id networkAvailabilityObserverToken;

@property (nonatomic) BOOL pendingInitialStateRestore;
@property (nonatomic) SplitViewController *splitViewController;
@property (nonatomic) id userObserverToken;

@end



@implementation ZClientViewController

#pragma mark - Overloaded methods

- (void)dealloc
{
    [AVSMediaManager.sharedInstance unregisterMedia:self.mediaPlaybackManager];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.proximityMonitorManager = [ProximityMonitorManager new];
        self.mediaPlaybackManager = [[MediaPlaybackManager alloc] initWithName:@"conversationMedia"];

        [AVSMediaManager.sharedInstance registerMedia:self.mediaPlaybackManager withOptions:@{ @"media" : @"external "}];
        
        AddressBookHelper.sharedHelper.configuration = AutomationHelper.sharedHelper;
        
        NSString *appGroupIdentifier = NSBundle.mainBundle.appGroupIdentifier;
        NSURL *sharedContainerURL = [NSFileManager sharedContainerDirectoryForAppGroupIdentifier:appGroupIdentifier];        
        NSURL *accountContainerURL = [[sharedContainerURL URLByAppendingPathComponent:@"AccountData" isDirectory:YES]
                                      URLByAppendingPathComponent:ZMUser.selfUser.remoteIdentifier.UUIDString isDirectory:YES];
        self.analyticsEventPersistence = [[ShareExtensionAnalyticsPersistence alloc] initWithAccountContainer:accountContainerURL];
        [MessageDraftStorage setupSharedStorageAtURL:accountContainerURL error:nil];
        
        self.networkAvailabilityObserverToken = [ZMNetworkAvailabilityChangeNotification addNetworkAvailabilityObserver:self userSession:[ZMUserSession sharedSession]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ZMUserSessionDidBecomeAvailableNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
                
        [self setupAppearance];

        [self setupConversationListViewController];
    }
    return self;
}

- (void)setupAppearance
{
    [[GuestIndicator appearanceWhenContainedInInstancesOfClasses:@[StartUIView.class]] setColorSchemeVariant:ColorSchemeVariantDark];
    [[UserCell appearanceWhenContainedInInstancesOfClasses:@[StartUIView.class]] setColorSchemeVariant:ColorSchemeVariantDark];
    [[UserCell appearanceWhenContainedInInstancesOfClasses:@[StartUIView.class]] setContentBackgroundColor:UIColor.clearColor];
    [[SectionHeader appearanceWhenContainedInInstancesOfClasses:@[StartUIView.class]] setColorSchemeVariant:ColorSchemeVariantDark];
    [[GroupConversationCell appearanceWhenContainedInInstancesOfClasses:@[StartUIView.class]] setColorSchemeVariant:ColorSchemeVariantDark];
    [[GroupConversationCell appearanceWhenContainedInInstancesOfClasses:@[StartUIView.class]] setContentBackgroundColor:UIColor.clearColor];
    [[OpenServicesAdminCell appearanceWhenContainedInInstancesOfClasses:@[StartUIView.class]] setColorSchemeVariant:ColorSchemeVariantDark];
    [[OpenServicesAdminCell appearanceWhenContainedInInstancesOfClasses:@[StartUIView.class]] setContentBackgroundColor:UIColor.clearColor];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[UIAlertController.class]] setTintColor:[ColorScheme.defaultColorScheme colorWithName:ColorSchemeColorTextForeground variant:ColorSchemeVariantLight]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.colorSchemeController = [[ColorSchemeController alloc] init];
    self.pendingInitialStateRestore = YES;
    
    self.view.backgroundColor = [UIColor blackColor];

    [self.conversationListViewController view];

    self.splitViewController = [[SplitViewController alloc] init];
    self.splitViewController.delegate = self;
    [self addChildViewController:self.splitViewController];
    
    self.splitViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.splitViewController.view];
    
    [self createTopViewConstraints];
    [self.splitViewController didMoveToParentViewController:self];
    [self updateSplitViewTopConstraint];

    self.splitViewController.view.backgroundColor = [UIColor clearColor];
    
    [self createBackgroundViewController];
    
    if (self.pendingInitialStateRestore) {
        [self restoreStartupState];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorSchemeControllerDidApplyChanges:) name:NSNotification.colorSchemeControllerDidApplyColorSchemeChange object:nil];
    
    if ([DeveloperMenuState developerMenuEnabled]) { //better way of dealing with this?
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLoopNotification:) name:ZMLoggingRequestLoopNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inconsistentStateNotification:) name:ZMLoggingInconsistentStateNotificationName object:nil];
    }
    
    self.userObserverToken = [UserChangeInfo addObserver:self forUser:[ZMUser selfUser] userSession:[ZMUserSession sharedSession]];
}

- (void)createBackgroundViewController
{
    self.backgroundViewController = [[BackgroundViewController alloc] initWithUser:[ZMUser selfUser]
                                                                       userSession:[ZMUserSession sharedSession]];
    
    [self.backgroundViewController addChildViewController:self.conversationListViewController];
    [self.backgroundViewController.view addSubview:self.conversationListViewController.view];
    [self.conversationListViewController didMoveToParentViewController:self.backgroundViewController];
    self.conversationListViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.conversationListViewController.view.frame = self.backgroundViewController.view.bounds;
    
    self.splitViewController.leftViewController = self.backgroundViewController;
}

- (BOOL)shouldAutorotate
{
    if (self.presentedViewController) {
        return self.presentedViewController.shouldAutorotate;
    }
    else {
        return YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.wr_supportedInterfaceOrientations;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (nil != self.topOverlayViewController) {
        return self.topOverlayViewController.preferredStatusBarStyle;
    }
    else if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        if (self.presentedViewController) {
            if (![self.presentedViewController isKindOfClass:UIAlertController.class]) {
                return self.presentedViewController.preferredStatusBarStyle;
            }
        }

        return self.splitViewController.preferredStatusBarStyle;
    }
    else {
        return UIStatusBarStyleLightContent;
    }
}

- (BOOL)prefersStatusBarHidden {
    if (nil != self.topOverlayViewController) {
        return self.topOverlayViewController.prefersStatusBarHidden;
    }
    else if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        if (self.presentedViewController) {
            return self.presentedViewController.prefersStatusBarHidden;
        }
        else {
            return self.splitViewController.prefersStatusBarHidden;
        }
    }
    else {
        return NO;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    // if changing from compact width to regular width, make sure current conversation is loaded
    if (previousTraitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact
        && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        if (self.currentConversation) {
            [self selectConversation:self.currentConversation];
        }
        else {
            [self attemptToLoadLastViewedConversationWithFocus:NO animated:NO];
        }
    }

    [self updateSplitViewTopConstraint];
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES onlyFullScreen:NO];
    [self.view setNeedsLayout];
}

#pragma mark - Setup methods

- (void)setupConversationListViewController
{
    self.conversationListViewController = [[ConversationListViewController alloc] init];
    self.conversationListViewController.account = SessionManager.shared.accountManager.selectedAccount;

    self.conversationListViewController.isComingFromRegistration = self.isComingFromRegistration;
    self.conversationListViewController.needToShowDataUsagePermissionDialog = NO;
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)change
{
    if (change.accentColorValueChanged) {
        if ([[UIApplication sharedApplication].keyWindow respondsToSelector:@selector(setTintColor:)]) {
            [UIApplication sharedApplication].keyWindow.tintColor = [UIColor accentColor];
        }
    }
}

#pragma mark - Public API

+ (instancetype)sharedZClientViewController
{
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    
    for (UIViewController *controller in appDelegate.rootViewController.childViewControllers) {
        if ([controller isKindOfClass:ZClientViewController.class]) {
            return (ZClientViewController *)controller;
        }
    }
    
    return nil;
}

- (void)selectConversation:(ZMConversation *)conversation
{
    [self.conversationListViewController selectConversation:conversation
                                            scrollToMessage:nil
                                                focusOnView:NO
                                                   animated:NO];
}

- (void)selectConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus animated:(BOOL)animated
{
    [self selectConversation:conversation scrollToMessage:nil focusOnView:focus animated:animated completion:nil];
}

- (void)selectConversation:(ZMConversation *)conversation scrollToMessage:(__nullable id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated
{
    [self selectConversation:conversation scrollToMessage:message focusOnView:focus animated:animated completion:nil];
}

- (void)selectConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    [self dismissAllModalControllersWithCallback:^{
        [self.conversationListViewController selectConversation:conversation scrollToMessage:message focusOnView:focus animated:animated completion:completion];
    }];
}

- (void)selectIncomingContactRequestsAndFocusOnView:(BOOL)focus
{
    [self.conversationListViewController selectInboxAndFocusOnView:focus];
}

- (void)hideIncomingContactRequestsWithCompletion:(dispatch_block_t)completion
{
    NSArray *conversationsList = [ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]];
    if (conversationsList.count != 0) {
        [self selectConversation:conversationsList.firstObject];
    }
    
    [self.splitViewController setLeftViewControllerRevealed:YES animated:YES completion:completion];
}

- (void)transitionToListAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    if (self.splitViewController.rightViewController.presentedViewController != nil) {
        [self.splitViewController.rightViewController.presentedViewController dismissViewControllerAnimated:animated completion:^{
            [self.splitViewController setLeftViewControllerRevealed:YES animated:animated completion:completion];
        }];
    } else {
        [self.splitViewController setLeftViewControllerRevealed:YES animated:animated completion:completion];
    }
}

- (BOOL)pushContentViewController:(UIViewController *)viewController focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    self.conversationRootViewController = viewController;
    [self.splitViewController setRightViewController:self.conversationRootViewController animated:animated completion:completion];
    
    if (focus) {
        [self.splitViewController setLeftViewControllerRevealed:NO animated:animated completion:nil];
    }
    
    return YES;
}

- (void)loadPlaceholderConversationControllerAnimated:(BOOL)animated;
{
    [self loadPlaceholderConversationControllerAnimated:animated completion:nil];
}

- (void)loadPlaceholderConversationControllerAnimated:(BOOL)animated completion:(dispatch_block_t)completion;
{
    self.currentConversation = nil;
    [self pushContentViewController: nil focusOnView:NO animated:animated completion:completion];
}

- (BOOL)loadConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated
{
    return [self loadConversation:conversation scrollToMessage:message focusOnView:focus animated:animated completion:nil];
}

- (BOOL)loadConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    ConversationRootViewController *conversationRootController = nil;
    if ([conversation isEqual:self.currentConversation]) {
        conversationRootController = (ConversationRootViewController *)self.conversationRootViewController;
        if (message) {
            [conversationRootController scrollToMessage:message];            
        }
        
    } else {
        conversationRootController = [[ConversationRootViewController alloc] initWithConversation:conversation message:message clientViewController:self];
    }
    
    self.currentConversation = conversation;
    conversationRootController.conversationViewController.focused = focus;
    
    [self.conversationListViewController hideArchivedConversations];
    [self pushContentViewController:conversationRootController focusOnView:focus animated:animated completion:completion];
    
    return NO;
}

- (void)loadIncomingContactRequestsAndFocusOnView:(BOOL)focus animated:(BOOL)animated
{
    self.currentConversation = nil;
    
    ConnectRequestsViewController *inbox = [ConnectRequestsViewController new];
    [self pushContentViewController:inbox focusOnView:focus animated:animated completion:nil];
}

- (void)setConversationListViewController:(ConversationListViewController *)conversationListViewController
{
    if (conversationListViewController == self.conversationListViewController) {
        return;
    }
    
    _conversationListViewController = conversationListViewController;

}

- (void)openDetailScreenForConversation:(ZMConversation *)conversation
{
    GroupDetailsViewController *controller = [[GroupDetailsViewController alloc] initWithConversation:conversation];
    UINavigationController *navController =  controller.wrapInNavigationController;
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)dismissClientListController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Animated conversation switch

- (void)minimizeCallOverlayWithCompletion:(dispatch_block_t)completion
{
    [AppDelegate.sharedAppDelegate.callWindowRootViewController minimizeOverlayWithCompletion:completion];
}

- (void)dismissAllModalControllersWithCallback:(dispatch_block_t)callback
{
    dispatch_block_t dismissAction = ^{
        if (self.splitViewController.rightViewController.presentedViewController != nil) {
            [self.splitViewController.rightViewController dismissViewControllerAnimated:NO completion:callback];
        }
        else if (self.conversationListViewController.presentedViewController != nil) {
            // This is a workaround around the fact that the transitioningDelegate of the settings
            // view controller is not called when the transition is not being performed animated.
            // This sounds like a bug in UIKit (Radar incoming) as I would expect the custom animator
            // being called with `transitionContext.isAnimated == false`. As this is not the case
            // we have to restore the proper pre-presentation state here.
            UIView *conversationView = self.conversationListViewController.view;
            if (!CATransform3DIsIdentity(conversationView.layer.transform) || 1 != conversationView.alpha) {
                conversationView.layer.transform = CATransform3DIdentity;
                conversationView.alpha = 1;
            }
            
            [self.conversationListViewController.presentedViewController dismissViewControllerAnimated:NO completion:callback];
        }
        else if (self.presentedViewController != nil) {
            [self dismissViewControllerAnimated:NO completion:callback];
        }
        else if (callback) {
            callback();
        }
    };

    ZMConversation *ringingCallConversation = [[ZMUserSession sharedSession] ringingCallConversation];
    
    if (ringingCallConversation != nil) {
        dismissAction();
    }
    else {
        [self minimizeCallOverlayWithCompletion:^{
            dismissAction();
        }];
    }
}

#pragma mark - Getters/Setters

- (void)setCurrentConversation:(ZMConversation *)currentConversation
{    
    if (_currentConversation != currentConversation) {
        _currentConversation = currentConversation;
    }
}

- (void)setIsComingFromRegistration:(BOOL)isComingFromRegistration
{
    _isComingFromRegistration = isComingFromRegistration;

    self.conversationListViewController.isComingFromRegistration = self.isComingFromRegistration;
}

- (BOOL)needToShowDataUsagePermissionDialog
{
    return self.conversationListViewController.needToShowDataUsagePermissionDialog;
}

- (void)setNeedToShowDataUsagePermissionDialog:(BOOL)needToShowDataUsagePermissionDialog
{
    self.conversationListViewController.needToShowDataUsagePermissionDialog = needToShowDataUsagePermissionDialog;
}

- (BOOL)isConversationViewVisible
{
    return IS_IPAD_LANDSCAPE_LAYOUT || !self.splitViewController.leftViewControllerRevealed;
}

- (BOOL)isConversationListVisible
{
    return IS_IPAD_LANDSCAPE_LAYOUT || (self.splitViewController.leftViewControllerRevealed && self.conversationListViewController.presentedViewController == NULL);
}

- (ZMUserSession *)context
{
    return [ZMUserSession sharedSession];
}

#pragma mark - Application State

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self uploadAddressBookIfNeeded];
    [self trackShareExtensionEventsIfNeeded];
}

#pragma mark - Adressbook Upload

- (void)uploadAddressBookIfNeeded
{
    // We should not even try to access address book when in a team
    if (nil == ZMUser.selfUser || ZMUser.selfUser.hasTeam) {
        return;
    }
    
    BOOL addressBookDidBecomeGranted = [AddressBookHelper.sharedHelper accessStatusDidChangeToGranted];
    [AddressBookHelper.sharedHelper startRemoteSearchWithCheckingIfEnoughTimeSinceLast:!addressBookDidBecomeGranted];
    [AddressBookHelper.sharedHelper persistCurrentAccessStatus];
}

#pragma mark - ColorSchemeControllerDidApplyChangesNotification

- (void)reloadCurrentConversation
{
    // Need to reload conversation to apply color scheme changes
    if (self.currentConversation) {
        ConversationRootViewController *currentConversationViewController = [[ConversationRootViewController alloc] initWithConversation:self.currentConversation
                                                                                                                                 message:nil
                                                                                                                    clientViewController:self];
        [self pushContentViewController:currentConversationViewController focusOnView:NO animated:NO completion:nil];
    }
}

- (void)colorSchemeControllerDidApplyChanges:(NSNotification *)notification
{
    [self reloadCurrentConversation];
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self reloadCurrentConversation];
}

#pragma mark - Debug logging notifications

- (void)requestLoopNotification:(NSNotification *)notification;
{
    NSString *path = notification.userInfo[@"path"];
    [DebugAlert showSendLogsMessageWithMessage:[NSString stringWithFormat:@"A request loop is going on at %@", path]];
}

- (void)inconsistentStateNotification:(NSNotification *)notification;
{
    [DebugAlert showSendLogsMessageWithMessage:[NSString stringWithFormat:@"We detected an inconsistent state: %@", notification.userInfo[ZMLoggingDescriptionKey]]];
}

#pragma mark -  Share extension analytics

- (void)trackShareExtensionEventsIfNeeded
{
    NSArray<StorableTrackingEvent *> *events = self.analyticsEventPersistence.storedTrackingEvents.copy;
    [self.analyticsEventPersistence clear];
    
    for (StorableTrackingEvent *event in events) {
        [Analytics.shared tagStorableEvent:event];
    }
}

@end


@implementation ZClientViewController (InitialState)

- (void)restoreStartupState
{
    self.pendingInitialStateRestore = NO;
    [self attemptToPresentInitialConversation];
}

- (BOOL)attemptToPresentInitialConversation
{
    BOOL stateRestored = NO;

    SettingsLastScreen lastViewedScreen = [Settings sharedSettings].lastViewedScreen;
    switch (lastViewedScreen) {
            
        case SettingsLastScreenList: {
            
            [self transitionToListAnimated:NO completion:nil];
            
            // only attempt to show content vc if it would be visible
            if (self.isConversationViewVisible) {
                stateRestored = [self attemptToLoadLastViewedConversationWithFocus:NO animated:NO];
            }
            
            break;
        }
        case SettingsLastScreenConversation: {
            
            stateRestored = [self attemptToLoadLastViewedConversationWithFocus:YES animated:NO];
            break;
        }
        default: {
            // If there's no previously selected screen
            if (self.isConversationViewVisible) {
                [self selectListItemWhenNoPreviousItemSelected];
            }
            
            break;
        }
    }
    return stateRestored;
}

/// Attempt to load the last viewed conversation associated with the current account.
/// If no info is available, we attempt to load the first conversation in the list.
/// In the first case, YES is returned, otherwise NO.
///
- (BOOL)attemptToLoadLastViewedConversationWithFocus:(BOOL)focus animated:(BOOL)animated
{
    Account *currentAccount = SessionManager.shared.accountManager.selectedAccount;
    ZMConversation *conversation = [[Settings sharedSettings] lastViewedConversationFor:currentAccount];
    
    if (conversation != nil) {
        [self selectConversation:conversation focusOnView:focus animated:animated];
        
        // dispatch async here because it has to happen after the collection view has finished
        // laying out for the first time
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.conversationListViewController scrollToCurrentSelectionAnimated:NO];
        });
        
        return YES;
    }
    else {
        [self selectListItemWhenNoPreviousItemSelected];
        return NO;
    }
}

/**
 * This handles the case where we have to select a list item on startup but there is no previous item saved
 */
- (void)selectListItemWhenNoPreviousItemSelected
{
    // check for conversations and pick the first one.. this can be tricky if there are pending updates and
    // we haven't synced yet, but for now we just pick the current first item
    NSArray *list = [ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]];
    
    if (list.count > 0) {
        // select the first conversation and don't focus on it
        [self selectConversation:list[0]];
    } else {
        [self loadPlaceholderConversationControllerAnimated:YES];
    }
}

#pragma mark - SplitViewControllerDelegate

- (BOOL)splitViewControllerShouldMoveLeftViewController:(SplitViewController *)splitViewController
{
    return splitViewController.rightViewController != nil &&
           splitViewController.leftViewController == self.backgroundViewController &&
           self.conversationListViewController.state == ConversationListStateConversationList &&
           (self.conversationListViewController.presentedViewController == nil || splitViewController.isLeftViewControllerRevealed == NO);
}

@end


@implementation ZClientViewController (NetworkAvailabilityObserver)

- (void)didChangeAvailabilityWithNewState:(ZMNetworkState)newState
{
    if (newState == ZMNetworkStateOnline && [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self uploadAddressBookIfNeeded];
    }
}

@end
