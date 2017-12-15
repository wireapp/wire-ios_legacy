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

#import "WAZUIMagicIOS.h"

#import "ParticipantsViewController.h"
#import "ConversationListViewController.h"
#import "ConversationViewController.h"
#import "ConnectRequestsViewController.h"
#import "ColorSchemeController.h"
#import "ProfileViewController.h"

#import "WireSyncEngine+iOS.h"
#import "ZMConversation+Additions.h"

#import "AppDelegate.h"

#import "Constants.h"
#import "Analytics.h"
#import "AnalyticsTracker.h"
#import "Settings.h"
#import "StopWatch.h"

#import "Wire-Swift.h"

#import "NSLayoutConstraint+Helpers.h"

@interface ZClientViewController (InitialState) <SplitViewControllerDelegate>

- (void)restoreStartupState;
- (BOOL)attemptToLoadLastViewedConversationWithFocus:(BOOL)focus animated:(BOOL)animated;

@end


@interface ZClientViewController (ZMRequestsToOpenViewsDelegate) <ZMRequestsToOpenViewsDelegate>

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
@property (nonatomic) LegacyMessageTracker *messageCountTracker;

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.proximityMonitorManager = [ProximityMonitorManager new];
        self.mediaPlaybackManager = [[MediaPlaybackManager alloc] initWithName:@"conversationMedia"];
        self.messageCountTracker = [[LegacyMessageTracker alloc] initWithManagedObjectContext:ZMUserSession.sharedSession.syncManagedObjectContext];

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.colorSchemeController = [[ColorSchemeController alloc] init];

    self.pendingInitialStateRestore = YES;
    
    self.view.backgroundColor = [UIColor blackColor];

    [self setupConversationListViewController];
    
    self.splitViewController = [[SplitViewController alloc] init];
    self.splitViewController.delegate = self;
    [self addChildViewController:self.splitViewController];
    
    self.splitViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.splitViewController.view];
    
    [self.splitViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.splitViewController didMoveToParentViewController:self];
    
    self.splitViewController.view.backgroundColor = [UIColor clearColor];
    
    [self createBackgroundViewController];
    
    if (self.pendingInitialStateRestore) {
        [self restoreStartupState];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorSchemeControllerDidApplyChanges:) name:ColorSchemeControllerDidApplyColorSchemeChangeNotification object:nil];
    
    if ([DeveloperMenuState developerMenuEnabled]) { //better way of dealing with this?
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLoopNotification:) name:ZMTransportRequestLoopNotificationName object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(potentialErrorNotification:) name:ZMPotentialErrorDetectedNotificationName object:nil]; // TODO enable
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
    if (self.splitViewController.layoutSize == SplitViewControllerLayoutSizeCompact) {
        if (self.presentedViewController) {
            return self.presentedViewController.preferredStatusBarStyle;
        }
        else {
            return self.splitViewController.preferredStatusBarStyle;
        }
    }
    else {
        return UIStatusBarStyleDefault;
    }
}

- (BOOL)prefersStatusBarHidden {
    if (self.splitViewController.layoutSize == SplitViewControllerLayoutSizeCompact) {
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
    
    [self.view setNeedsLayout];
}

#pragma mark - Setup methods

- (void)setupConversationListViewController
{
    self.conversationListViewController = [[ConversationListViewController alloc] init];
    self.conversationListViewController.isComingFromRegistration = self.isComingFromRegistration;
    [self.conversationListViewController view];
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
                                                focusOnView:NO
                                                   animated:NO];
}

- (void)selectConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus animated:(BOOL)animated
{
    [self selectConversation:conversation focusOnView:focus animated:animated completion:nil];
}

- (void)selectConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    StopWatch *stopWatch = [StopWatch stopWatch];
    [stopWatch restartEvent:[NSString stringWithFormat:@"ConversationSelect%@", conversation.displayName]];
    
    [self dismissAllModalControllersWithCallback:^{
        [self.conversationListViewController selectConversation:conversation focusOnView:focus animated:animated completion:completion];
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
    PlaceholderConversationViewController *vc = [[PlaceholderConversationViewController alloc] init];
    self.currentConversation = nil;
    [self pushContentViewController:vc focusOnView:NO animated:animated completion:completion];
}

- (BOOL)loadConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus animated:(BOOL)animated
{
    return [self loadConversation:conversation focusOnView:focus animated:animated completion:nil];
}

- (BOOL)loadConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    ConversationRootViewController *conversationRootController = nil;
    if ([conversation isEqual:self.currentConversation]) {
        conversationRootController = (ConversationRootViewController *)self.conversationRootViewController;
    } else {
        conversationRootController = [self conversationRootControllerForConversation:conversation];
    }
    
    self.currentConversation = conversation;
    conversationRootController.conversationViewController.focused = focus;
    
    [self.conversationListViewController hideArchivedConversations];
    [self pushContentViewController:conversationRootController focusOnView:focus animated:animated completion:completion];
    
    return NO;
}

- (ConversationRootViewController *)conversationRootControllerForConversation:(ZMConversation *)conversation
{
    return [[ConversationRootViewController alloc] initWithConversation:conversation clientViewController:self];
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

- (void)openDetailScreenForUserClient:(UserClient *)client
{
    if (client.user.isSelfUser) {
        SettingsClientViewController *userClientViewController = [[SettingsClientViewController alloc] initWithUserClient:client credentials:nil];
        UINavigationController *navWrapperController = [[SettingsStyleNavigationController alloc] initWithRootViewController:userClientViewController];

        navWrapperController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navWrapperController animated:YES completion:nil];
    }
    else {
        ProfileClientViewController* userClientViewController = [[ProfileClientViewController alloc] initWithClient:client];
        userClientViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:userClientViewController animated:YES completion:nil];
    }
}

- (void)openDetailScreenForConversation:(ZMConversation *)conversation
{
    ParticipantsViewController *controller = [[ParticipantsViewController alloc] initWithConversation:conversation];
    RotationAwareNavigationController *navController = [[RotationAwareNavigationController alloc] initWithRootViewController:controller];
    [navController setNavigationBarHidden:YES animated:NO];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)openClientListScreenForUser:(ZMUser *)user
{
    if (user.isSelfUser) {
        ClientListViewController *clientListViewController = [[ClientListViewController alloc] initWithClientsList:user.clients.allObjects credentials:nil detailedView:YES showTemporary:YES];
        clientListViewController.view.backgroundColor = [UIColor blackColor];
        clientListViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissClientListController:)];
        UINavigationController *navWrapperController = [[SettingsStyleNavigationController alloc] initWithRootViewController:clientListViewController];
        navWrapperController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navWrapperController animated:YES completion:nil];
        
    } else {
        ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithUser:user context:ProfileViewControllerContextDeviceList];
        if ([self.conversationRootViewController isKindOfClass:ConversationRootViewController.class]) {
            profileViewController.delegate = (id <ProfileViewControllerDelegate>)[(ConversationRootViewController *)self.conversationRootViewController conversationViewController];
        }
        UINavigationController *navWrapperController = [[UINavigationController alloc] initWithRootViewController:profileViewController];
        navWrapperController.modalPresentationStyle = UIModalPresentationFormSheet;
        navWrapperController.navigationBarHidden = YES;
        [self presentViewController:navWrapperController animated:YES completion:nil];
    }

}

- (void)dismissClientListController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Animated conversation switch

- (void)dismissAllModalControllersWithCallback:(dispatch_block_t)callback
{
    if (self.splitViewController.rightViewController.presentedViewController != nil) {
        [self.splitViewController.rightViewController dismissViewControllerAnimated:NO completion:callback];
    }
    else if (self.conversationListViewController.presentedViewController != nil) {
        [self.conversationListViewController dismissViewControllerAnimated:NO completion:callback];
    }
    else if (self.presentedViewController != nil) {
        [self dismissViewControllerAnimated:NO completion:callback];
    }
    else if (callback) {
        callback();
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

- (BOOL)isConversationViewVisible
{
    return IS_IPAD_LANDSCAPE_LAYOUT || !self.splitViewController.leftViewControllerRevealed;
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
    [self.messageCountTracker trackLegacyMessageCount];
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
        ConversationRootViewController *currentConversationViewController = [self conversationRootControllerForConversation:self.currentConversation];
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

#pragma mark - Network Loop notification

- (void)requestLoopNotification:(NSNotification *)notification;
{
    NSString *path = notification.userInfo[@"path"];
    [DebugAlert showWithMessage:[NSString stringWithFormat:@"A request loop is going on at %@", path] sendLogs:YES];
}

#pragma mark - SE inconsistency notification

- (void)potentialErrorNotification:(NSNotification *)notification;
{
    [DebugAlert showWithMessage:[NSString stringWithFormat:@"We detected a potential error, please send logs"] sendLogs:YES];
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

@implementation ZClientViewController (ZMRequestsToOpenViewsDelegate)

- (void)showConversationListForUserSession:(ZMUserSession *)userSession
{
    [self transitionToListAnimated:YES completion:nil];
}

- (void)userSession:(ZMUserSession *)userSession showConversation:(ZMConversation *)conversation
{
    if (conversation.conversationType == ZMConversationTypeConnection) {
        [self selectIncomingContactRequestsAndFocusOnView:YES];
    }
    else {
        [self selectConversation:conversation focusOnView:YES animated:YES];
    }
}

- (void)userSession:(ZMUserSession *)userSession showMessage:(ZMMessage *)message inConversation:(ZMConversation *)conversation
{
    [self selectConversation:conversation focusOnView:YES animated:YES];
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
