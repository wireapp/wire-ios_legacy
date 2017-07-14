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


#import "RootViewController.h"

#import "MagicConfig.h"
#import "WireSyncEngine+iOS.h"

// Other UI
#import <AddressBookUI/AddressBookUI.h>

// Helpers
#import "WAZUIMagicIOS.h"
#import "Analytics+iOS.h"
#import "KeyboardFrameObserver.h"

#import "UIColor+WAZExtensions.h"
#import "ZMUser+Additions.h"
#import "Constants.h"

#import "AnalyticsConversationListObserver.h"
#import "ZClientViewController.h"
#import "RegistrationViewController.h"
#import "AnalyticsTracker.h"
#import "ConversationListViewController.h"
#import "StopWatch.h"
#import "UIViewController+Orientation.h"
#import "Wire-Swift.h"


@interface RootViewController (Registration) <RegistrationViewControllerDelegate>

@end



@interface RootViewController ()  <ZMUserObserver>

@property (nonatomic, strong, readwrite) KeyboardFrameObserver *keyboardFrameObserver;


@property (nonatomic) UIViewController *visibleViewController;

@property (nonatomic) RegistrationViewController *registrationViewController;

@property (nonatomic, strong) id convContentChangedObserver;
@property (nonatomic, assign) UIInterfaceOrientation lastVisibleInterfaceOrientation;

@property (nonatomic) id<ZMAuthenticationObserverToken> authToken;
@property (nonatomic) id userObserverToken;

@end


@interface RootViewController (AuthObserver) <ZMAuthenticationObserver>

@end


@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.convContentChangedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [[ZMUserSession sharedSession] removeAuthenticationObserverForToken:self.authToken];
}

- (void)setup
{
    self.keyboardFrameObserver = [[KeyboardFrameObserver alloc] init];

    self.authToken = [[ZMUserSession sharedSession] addAuthenticationObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // observe future accent color changes
    self.userObserverToken = [UserChangeInfo addUserObserver:self forUser:[ZMUser selfUser]];
    
    if (self.isLoggedIn) {
        [self presentFrameworkFromRegistration:NO];
    } else {
        [self presentRegistration];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.lastVisibleInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

#pragma mark - View controller rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.class wr_supportedInterfaceOrientations];
}

- (BOOL)prefersStatusBarHidden
{
    return self.visibleViewController.prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.visibleViewController.preferredStatusBarStyle;
}

- (void)presentRegistration
{
    if (self.registrationViewController) {
        return;
    }
    
    [UIColor setAccentOverrideColor:[ZMUser pickRandomAcceptableAccentColor]];
    [UIApplication sharedApplication].keyWindow.tintColor = [UIColor accentColor];

    self.registrationViewController = [[RegistrationViewController alloc] init];
    self.registrationViewController.delegate = self;
    self.registrationViewController.signInErrorCode = self.signInErrorCode;
    
    [self switchToViewController:self.registrationViewController animated:YES];
    
    self.zClientViewController = nil;
}

- (void)presentFrameworkFromRegistration:(BOOL)fromRegistration
{
    if (self.zClientViewController) {
        return;
    }
    
    self.registrationViewController = nil;
    [UIColor setAccentOverrideColor:ZMAccentColorUndefined];
    [UIApplication sharedApplication].keyWindow.tintColor = [UIColor accentColor];
    self.zClientViewController = [[ZClientViewController alloc] init];
    self.zClientViewController.isComingFromRegistration = fromRegistration;
    [self switchToViewController:self.zClientViewController animated:YES];
}

- (void)switchToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (animated && self.visibleViewController != nil) {

        [self.visibleViewController dismissViewControllerAnimated:NO completion:nil];
        [self.visibleViewController willMoveToParentViewController:nil];
        [self addChildViewController:viewController];

        [self transitionFromViewController:self.visibleViewController
                          toViewController:viewController
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:nil
                                completion:^(BOOL finished) {
                                    [viewController didMoveToParentViewController:self];
                                    [self.visibleViewController removeFromParentViewController];
                                    self.visibleViewController = viewController;
                                    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
                                }];
    }
    else {
        [UIView performWithoutAnimation:^{
            [self addChildViewController:viewController];
            viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
            self.visibleViewController = viewController;
            [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
        }];
    }
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

@end



@implementation RootViewController (Registration)

#pragma mark - RegistrationViewControllerDelegate

- (void)registrationViewControllerDidCompleteRegistration
{
    [self presentFrameworkFromRegistration:YES];
}

- (void)registrationViewControllerDidSignIn
{
    [self presentFrameworkFromRegistration:NO];
}


@end



@implementation RootViewController (AuthObserver)

- (void)authenticationDidSucceed
{
    DDLogDebug(@"Authentication succeded");
    StopWatch *stopWatch = [StopWatch stopWatch];
    StopWatchEvent *loginEvent = [stopWatch stopEvent:@"Login"];
    if (loginEvent) {
        DDLogDebug(@"Login success after %lums", (unsigned long)loginEvent.elapsedTime);
    }
    [stopWatch startEvent:@"LoadContactList"];

    // delay listening to the conversation list to speed up startup
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [Analytics shared].observingConversationList = YES;
    });
}

- (void)authenticationDidFail:(NSError *)error
{
    [self presentRegistration];
    
    self.signInErrorCode = error.code;
}

@end
