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

@import PureLayout;

#import "NotificationWindowRootViewController.h"
#import "PassthroughTouchesView.h"
#import "AppDelegate.h"
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

@property (nonatomic) AppLockViewController *appLockViewController;

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

    [self setupConstraints];
}

- (void)setupConstraints
{
    [self.appLockViewController.view autoPinEdgesToSuperviewEdges];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Rotation handling (should match up with root)

- (UIViewController *)topmostViewController
{
    UIViewController * topmostViewController = UIApplication.sharedApplication.wr_topmostViewController;
    
    if (topmostViewController != nil && topmostViewController != self && ![topmostViewController isKindOfClass:NotificationWindowRootViewController.class]) {
        return topmostViewController;
    } else {
        return nil;
    }
}

- (BOOL)shouldAutorotate
{
    UIViewController * topmostViewController = [self topmostViewController];
    if (topmostViewController != nil) {
        return topmostViewController.shouldAutorotate;
    } else {
        return YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIViewController * topmostViewController = [self topmostViewController];
    if (topmostViewController != nil) {
        return topmostViewController.supportedInterfaceOrientations;
    } else {
        return self.wr_supportedInterfaceOrientations;
    }
}

@end

