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
#import <PureLayout/PureLayout.h>

#import "ZClientViewController+Internal.h"

#import "SplitViewController.h"

#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"
#import "RootViewController.h"
#import "UIViewController+Orientation.h"

#import "WAZUIMagicIOS.h"

#import "ParticipantsViewController.h"
#import "ConversationListViewController.h"
#import "ConversationViewController.h"
#import "ConnectRequestsViewController.h"
#import "SoundEventListener.h"
#import "ProximityMonitorManager.h"
#import "ColorSchemeController.h"
#import "ProfileViewController.h"

#import "zmessaging+iOS.h"
#import "ZMConversation+Additions.h"
#import "VoiceChannelV2+Additions.h"

#import "AppDelegate.h"
#import "VoiceChannelController.h"

#import "Constants.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker.h"
#import "Settings.h"
#import "StopWatch.h"
#import "UIView+MTAnimation.h"

#import "Wire-Swift.h"

#import "NSLayoutConstraint+Helpers.h"

@interface ZClientViewController (InitialState) <SplitViewControllerDelegate>

- (void)restoreStartupState;

@end


@interface ZClientViewController (ZMRequestsToOpenViewsDelegate) <ZMRequestsToOpenViewsDelegate>

@end


@interface ZClientViewController ()

@property (nonatomic, readwrite) SoundEventListener *soundEventListener;

@property (nonatomic) ColorSchemeController *colorSchemeController;
@property (nonatomic, readwrite) BackgroundViewController *backgroundViewController;
@property (nonatomic, readwrite) ConversationListViewController *conversationListViewController;
@property (nonatomic, readwrite) UIViewController *conversationRootViewController;
@property (nonatomic, readwrite) ZMConversation *currentConversation;

@property (nonatomic) id incomingApnsObserver;

@property (nonatomic) ProximityMonitorManager *proximityMonitorManager;

@property (nonatomic) BOOL pendingInitialStateRestore;
@property (nonatomic) SplitViewController *splitViewController;

- (void)setupChildViewControllers;

@end



@implementation ZClientViewController

#pragma mark - Overloaded methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.soundEventListener = [SoundEventListener new];
        self.proximityMonitorManager = [ProximityMonitorManager new];
        [[ZMUserSession sharedSession] setRequestToOpenViewDelegate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentSizeCategoryDidChange:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.colorSchemeController = [[ColorSchemeController alloc] init];

    self.pendingInitialStateRestore = YES;
    
    self.view.backgroundColor = [UIColor blackColor];

    self.backgroundViewController = [[BackgroundViewController alloc] init];
    self.backgroundViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.backgroundViewController];
    [self.view addSubview:self.backgroundViewController.view];
    [self.backgroundViewController didMoveToParentViewController:self];

    [self.backgroundViewController.view addConstraintsFittingToView:self.view];

    [self.backgroundViewController setUser:[ZMUser selfUser] animated:YES];

    [self setupChildViewControllers];
    
    self.splitViewController = [[SplitViewController alloc] init];
    self.splitViewController.delegate = self;
    [self addChildViewController:self.splitViewController];
    
    self.splitViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.splitViewController.view];
    
    CGFloat topInset = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ? 20 : 0;
    [self.splitViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(topInset, 0, 0, 0)];
    [self.splitViewController didMoveToParentViewController:self];
    
    self.splitViewController.view.backgroundColor = [UIColor clearColor];
    
    if (self.conversationListViewController != nil) {
        self.splitViewController.leftViewController = self.conversationListViewController;
    }
    
    if (self.pendingInitialStateRestore) {
        [self restoreStartupState];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorSchemeControllerDidApplyChanges:) name:ColorSchemeControllerDidApplyColorSchemeChangeNotification object:nil];
    
    if ([DeveloperMenuState developerMenuEnabled]) { //better way of dealing with this?
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLoopNotification:) name:ZMTransportRequestLoopNotificationName object:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Analytics shared] tagScreen:@"MAIN"];
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
    return [self.class wr_supportedInterfaceOrientations];
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
        return UIStatusBarStyleLightContent;
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

#pragma mark - Setup methods

- (void)setupChildViewControllers
{
    self.conversationListViewController = [[ConversationListViewController alloc] init];
    self.conversationListViewController.isComingFromRegistration = self.isComingFromRegistration;
    [self.conversationListViewController view];
    self.conversationListViewController.enableExtras = [Settings sharedSettings].enableExtras;
}

#pragma mark - Public API

+ (instancetype)sharedZClientViewController
{
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    RootViewController *rootViewController = (RootViewController *) appDelegate.window.rootViewController;
    if ([rootViewController respondsToSelector:@selector(zClientViewController)]) {
        return rootViewController.zClientViewController;
    } else {
        return nil;
    }
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
    
    @weakify(self);
    [self.splitViewController setLeftViewController:self.conversationListViewController animated:animated completion:^{
        @strongify(self);
        [self.conversationListViewController selectConversation:conversation focusOnView:focus animated:animated completion:completion];
    }];
}

- (BOOL)selectIncomingContactRequestsAndFocusOnView:(BOOL)focus
{
    return [self.conversationListViewController selectInboxAndFocusOnView:focus];
}

- (void)hideIncomingContactRequestsWithCompletion:(dispatch_block_t)completion
{
    NSArray *conversationsList = [SessionObjectCache sharedCache].conversationList;
    if (conversationsList.count == 0) {
        return;
    } else {
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
    
    self.splitViewController.leftViewController = self.conversationListViewController;
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

- (void)dismissModalControllersAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    
    if (animated) {
        UIGraphicsBeginImageContextWithOptions(self.view.window.bounds.size, NO, self.view.window.screen.scale);
        [self.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage* screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        UIImageView *screenshotView = [[UIImageView alloc] initWithImage:screenshot];
        
        screenshotView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self dismissAllModalControllersWithCallback:^{
            
            [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
            
            [self.splitViewController setLeftViewControllerRevealed:YES animated:animated completion:nil];

            NSArray *fadedViews = [self.splitViewController.leftViewController.view.subviews copy];
            for (UIView *v in fadedViews) {
                v.hidden = YES;
            }
            
            [self.splitViewController.leftViewController.view addSubview:screenshotView];
            [screenshotView addConstraintsForSize:self.view.bounds.size];
            
            [UIView mt_animateWithViews:@[screenshotView]
                               duration:0.35f
                                  delay:0.0f
                         timingFunction:MTTimingFunctionEaseOutQuad
                             animations:^{
                                 screenshotView.alpha = 0.0f;
                             }
                             completion:^{
                                 [screenshotView removeFromSuperview];
                                 for (UIView *v in fadedViews) {
                                     v.hidden = NO;
                                 }
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }];
    }
    else {
        [self dismissAllModalControllersWithCallback:^{
            
            [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
            
            [self.splitViewController setLeftViewControllerRevealed:YES animated:NO completion:nil];

            
            if (completion) {
                completion();
            }
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

- (BOOL)isConversationViewVisible
{
    if (IS_IPAD_LANDSCAPE_LAYOUT) {
        return [self.splitViewController.rightViewController isKindOfClass:[ConversationViewController class]];
    }
    else if (self.splitViewController.leftViewControllerRevealed) {
        return NO;
    }
    else {
        return YES;
    }
}

- (ZMUserSession *)context
{
    return [ZMUserSession sharedSession];
}

#pragma mark - ColorSchemeControllerDidApplyChangesNotification

- (void)reloadCurrentConversation
{
    // Need to reload conversation to apply color scheme changes
    ConversationRootViewController *currentConversationViewController = [self conversationRootControllerForConversation:self.currentConversation];
    [self pushContentViewController:currentConversationViewController focusOnView:NO animated:NO completion:nil];
}

- (void)colorSchemeControllerDidApplyChanges:(NSNotification *)notification
{
    if (self.currentConversation) {
        [self reloadCurrentConversation];
    }
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self reloadCurrentConversation];
}

#pragma mark - Network Loop notification

- (void)requestLoopNotification:(NSNotification *)notification;
{
    NSString *path = notification.userInfo[@"path"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oh noes!" message:[NSString stringWithFormat:@"A request loop is going on at %@", path] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    
    [alert addAction:action];
    [self.conversationRootViewController presentViewController:alert animated:YES completion:nil];
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
            ZMConversation *conversation = [Settings sharedSettings].lastViewedConversation;
            if (conversation != nil) {
                // Select the last viewed conversation without giving it focus
                [self selectConversation:conversation];
                
                // dispatch async here because it has to happen after the collection view has finished
                // laying out for the first time
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.conversationListViewController scrollToCurrentSelectionAnimated:NO];
                });
                stateRestored = YES;
            }
            else {
                [self selectListItemWhenNoPreviousItemSelected];
            }
            break;
        }
        case SettingsLastScreenConversation: {
            
            ZMConversation *conversation = [Settings sharedSettings].lastViewedConversation;
            if (conversation != nil) {
                [self selectConversation:conversation
                             focusOnView:YES 
                                animated:NO];
                
                // dispatch async here because it has to happen after the collection view has finished
                // laying out for the first time
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.conversationListViewController scrollToCurrentSelectionAnimated:NO];
                });
                stateRestored = YES;
            }
            break;
        }
        default: {
            // If there's no previously selected screen,
            [self selectListItemWhenNoPreviousItemSelected];
            break;
        }
    }
    return stateRestored;
}

/**
 * This handles the case where we have to select a list item on startup but there is no previous item saved
 */
- (void)selectListItemWhenNoPreviousItemSelected
{
    // check for conversations and pick the first one.. this can be tricky if there are pending updates and
    // we haven't synced yet, but for now we just pick the current first item
    NSArray *list = [SessionObjectCache sharedCache].conversationList;
    
    if (list.count > 0) {
        // select the first conversation and don't focus on it
        [self selectConversation:list[0]];
    }
}

#pragma mark - SplitViewControllerDelegate

- (BOOL)splitViewControllerShouldMoveLeftViewController:(SplitViewController *)splitViewController
{
    return splitViewController.rightViewController != nil &&
           splitViewController.leftViewController == self.conversationListViewController &&
           self.conversationListViewController.state == ConversationListStateConversationList &&
           (self.conversationListViewController.presentedViewController == nil || splitViewController.isLeftViewControllerRevealed == NO);
}

@end

@implementation ZClientViewController (ZMRequestsToOpenViewsDelegate)

- (void)showConversationList
{
    [self transitionToListAnimated:YES completion:nil];
}

- (void)showConversation:(ZMConversation *)conversation
{
    [self selectConversation:conversation focusOnView:YES animated:YES];
}

- (void)showMessage:(id<ZMConversationMessage>)message inConversation:(ZMConversation *)conversation
{
    [self selectConversation:conversation focusOnView:YES animated:YES];
}

@end

