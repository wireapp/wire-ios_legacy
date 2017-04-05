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

#import "UIView+Borders.h"

#import <PureLayout/PureLayout.h>

#import "NotificationWindowRootViewController.h"
#import "NetworkStatusViewController.h"
#import "PassthroughTouchesView.h"
#import "NetworkActivityViewController.h"
#import "InvitationStatusController.h"
#import "AppDelegate.h"
#import "UIView+Borders.h"
#import "VoiceChannelController.h"
#import "WAZUIMagicIOS.h"
#import "UIView+Borders.h"
#import "Constants.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Orientation.h"
#import "BarController.h"
#import "Wire-Swift.h"



@interface NotificationWindowRootViewController (InitialSync) <ZMNetworkAvailabilityObserver>
- (void)updateAppearanceForNetworkState;
@end



@interface NotificationWindowRootViewController ()

@property (nonatomic) NetworkStatusViewController *networkStatusViewController;
@property (nonatomic) NetworkActivityViewController *networkActivityViewController;
@property (nonatomic) InvitationStatusController *invitationStatusController;
@property (nonatomic) BarController *notificationBarController;
@property (nonatomic) AppLockViewController *appLockViewController;

@property (nonatomic, strong) NSLayoutConstraint *overlayContainerLeftMargin;
@property (nonatomic, strong) NSLayoutConstraint *networkStatusRightMargin;
@property (nonatomic, strong) NSLayoutConstraint *networkActivityRightMargin;
@property (nonatomic, strong) NSLayoutConstraint *notificationRightMargin;

@end



@implementation NotificationWindowRootViewController

- (void)loadView
{
    self.view = [PassthroughTouchesView new];
    
    _voiceChannelController = [[VoiceChannelController alloc] init];
    self.voiceChannelController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.voiceChannelController toView:self.view];
    
    _notificationBarController = [[BarController alloc] init];
    self.notificationBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.notificationBarController toView:self.view];
    
    self.networkActivityViewController = [[NetworkActivityViewController alloc] init];
    self.networkActivityViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.networkActivityViewController toView:self.view];
    
    self.networkStatusViewController = [[NetworkStatusViewController alloc] init];
    self.networkStatusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.networkStatusViewController toView:self.view];
    
    self.invitationStatusController = [[InvitationStatusController alloc] initWithBarController:self.notificationBarController];
       
    self.appLockViewController = [[AppLockViewController alloc] init];
    self.appLockViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.appLockViewController toView:self.view];
    
    [self setupConstraints];
    [self updateAppearanceForOrientation:[UIApplication sharedApplication].statusBarOrientation];
    [self updateAppearanceForNetworkState];
    [ZMNetworkAvailabilityChangeNotification addNetworkAvailabilityObserver:self userSession:[ZMUserSession sharedSession]];
}

- (void)dealloc
{
    [ZMNetworkAvailabilityChangeNotification removeNetworkAvailabilityObserver:self];
}

- (void)setupConstraints
{
    [self.voiceChannelController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.networkActivityViewController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.networkActivityViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    self.networkActivityRightMargin = [self.networkActivityViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.networkActivityViewController.view autoSetDimension:ALDimensionHeight toSize:2.0f];
    
    [self.networkStatusViewController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.networkStatusViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    self.networkStatusRightMargin = [self.networkStatusViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    [self.notificationBarController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.notificationBarController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    self.notificationRightMargin = [self.notificationBarController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    [self.appLockViewController.view autoPinEdgesToSuperviewEdges];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)addViewController:(UIViewController *)viewController toView:(UIView *)view
{
    if (viewController == nil) {
        return;
    }
    [self addChildViewController:viewController];
    [view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)setShowLoadMessages:(BOOL)showLoadingMessages
{
    _showLoadMessages = showLoadingMessages;
    self.networkActivityViewController.isLoadingMessages = showLoadingMessages;
}

- (void)setHideNetworkActivityView:(BOOL)hideNetworkActivityView
{
    _hideNetworkActivityView = hideNetworkActivityView;
    self.networkActivityViewController.view.hidden = hideNetworkActivityView;
}

#pragma mark - Rotation handling (should match up with roort)

- (BOOL)shouldAutorotate
{
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    return [appDelegate.window.rootViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.class wr_supportedInterfaceOrientations];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self updateAppearanceForOrientation:orientation];

    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)updateAppearanceForOrientation:(UIInterfaceOrientation)orientation
{
    UITraitCollection *traits = [UIScreen mainScreen].traitCollection;
    if (traits.userInterfaceIdiom == UIUserInterfaceIdiomPad && UIInterfaceOrientationIsLandscape(orientation)) {
        CGFloat sidebarWidth = [WAZUIMagic cgFloatForIdentifier:@"framework.sidebar_width"];
        CGFloat rightMargin =  -([UIScreen mainScreen].bounds.size.width - sidebarWidth);
        self.networkStatusRightMargin.constant = rightMargin;
        self.networkActivityRightMargin.constant = rightMargin;
        self.notificationRightMargin.constant = rightMargin;
    }
    else {
        self.networkStatusRightMargin.constant = 0;
        self.networkActivityRightMargin.constant = 0;
        self.notificationRightMargin.constant = 0;
    }
}

@end



@implementation NotificationWindowRootViewController (InitialSync)

- (void)didChangeAvailability:(ZMNetworkAvailabilityChangeNotification *)note
{
    [self updateAppearanceForNetworkState:note.networkState];
}

- (void)updateAppearanceForNetworkState
{
    [self updateAppearanceForNetworkState:[ZMUserSession sharedSession].networkState];
}

- (void)updateAppearanceForNetworkState:(ZMNetworkState)networkState
{
    [[ZMUserSession sharedSession] checkIfLoggedInWithCallback:^(BOOL isLoggedIn) {
        if (networkState == ZMNetworkStateOnlineSynchronizing && [SessionObjectCache sharedCache].conversationList.count == 0 && isLoggedIn) {
            self.networkActivityViewController.view.hidden = YES;
        } else {
            self.networkActivityViewController.view.hidden = NO;
        }
    }];
}

@end
