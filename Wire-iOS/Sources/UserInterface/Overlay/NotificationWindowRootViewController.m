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

@import PureLayout;

#import "NotificationWindowRootViewController.h"
#import "PassthroughTouchesView.h"
#import "AppDelegate.h"
#import "UIView+Borders.h"
#import "WAZUIMagicIOS.h"
#import "UIView+Borders.h"
#import "Constants.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

@interface UIViewController (Child)
- (void)wr_removeFromParentViewController;
@end

@implementation UIViewController (Child)

- (void)wr_removeFromParentViewController
{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

@end

@interface NotificationWindowRootViewController ()

@property (nonatomic) NetworkStatusViewController *networkStatusViewController;
@property (nonatomic) AppLockViewController *appLockViewController;
@property (nonatomic) ChatHeadsViewController *chatHeadsViewController;

@property (nonatomic, strong) NSLayoutConstraint *overlayContainerLeftMargin;
@property (nonatomic, strong) NSLayoutConstraint *networkActivityRightMargin;

@end

@implementation NotificationWindowRootViewController

- (void)dealloc
{
    if (self.appLockViewController.parentViewController == self) {
        [self.appLockViewController wr_removeFromParentViewController];
    }
}

- (void)loadView
{
    self.view = [PassthroughTouchesView new];

    self.appLockViewController = [AppLockViewController shared];
    if (nil != self.appLockViewController.parentViewController) {
        [self.appLockViewController wr_removeFromParentViewController];
    }

    self.appLockViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.appLockViewController toView:self.view];

    self.chatHeadsViewController = [[ChatHeadsViewController alloc] init];
    self.chatHeadsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.chatHeadsViewController toView:self.view];

    [self setupConstraints];
    [self updateAppearanceForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)setupConstraints
{
    [self.appLockViewController.view autoPinEdgesToSuperviewEdges];
    [self.chatHeadsViewController.view autoPinEdgesToSuperviewEdges];
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

- (void)transitionToLoggedInSession
{
    self.networkStatusViewController = [[NetworkStatusViewController alloc] init];
    self.networkStatusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.networkStatusViewController toView:self.view];

    [self.networkStatusViewController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.networkStatusViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    self.networkActivityRightMargin = [self.networkStatusViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.networkStatusViewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    _voiceChannelController = [[ActiveVoiceChannelViewController alloc] init];
    self.voiceChannelController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addViewController:self.voiceChannelController toView:self.view];

    [self.voiceChannelController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

#pragma mark - In app custom notifications

- (void)show:(ZMLocalNotification*)notification
{
    [self.chatHeadsViewController tryToDisplayNotification:notification];
}

#pragma mark - Rotation handling (should match up with root)

/**
 guard against a stack overflow (when calling shouldAutorotate or supportedInterfaceOrientations)

 @return nil if UIApplication.sharedApplication.wr_topmostViewController is same as self or same class as self or it is a "UIInputWindowController"
 */
-(UIViewController *)topViewController
{
    UIViewController * topViewController = UIApplication.sharedApplication.wr_topmostViewController;
    NSString *className = NSStringFromClass([topViewController class]);

    if (self != topViewController &&
        ![topViewController isKindOfClass: self.class] &&
        [className compare:@"UIInputWindowController"] != NSOrderedSame) {
        return topViewController;
    }

    return nil;
}

- (BOOL)shouldAutorotate
{
    UIViewController * topViewController = [self topViewController];
    if (topViewController != nil) {
        return topViewController.shouldAutorotate;
    } else {
        return YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIViewController * topViewController = [self topViewController];
    if (topViewController != nil) {
        return topViewController.supportedInterfaceOrientations;
    } else {
        return self.wr_supportedInterfaceOrientations;
    }
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
    if (IS_IPAD_LANDSCAPE_LAYOUT) {
        CGFloat sidebarWidth = [WAZUIMagic cgFloatForIdentifier:@"framework.sidebar_width"];
        CGFloat rightMargin =  -([UIScreen mainScreen].bounds.size.width - sidebarWidth);
        self.networkActivityRightMargin.constant = rightMargin;
    }
    else {
        self.networkActivityRightMargin.constant = 0;
    }
}

@end

