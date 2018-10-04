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


#import "RegistrationViewController.h"

@import PureLayout;
@import WireExtensionComponents;

#import "WireSyncEngine+iOS.h"
#import "AddEmailPasswordViewController.h"
#import "AddPhoneNumberViewController.h"
#import "RegistrationRootViewController.h"
#import "NoHistoryViewController.h"
#import "PopTransition.h"
#import "PushTransition.h"
#import "NavigationController.h"
#import "SignInViewController.h"
#import "Constants.h"

#import "UIColor+WAZExtensions.h"
#import "UIViewController+Errors.h"

#import "Wire-Swift.h"

#import "RegistrationFormController.h"

#import "PhoneSignInViewController.h"
#import "EmailSignInViewController.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface RegistrationViewController () <UINavigationControllerDelegate>

@property (nonatomic) BOOL registeredInThisSession;

@property (nonatomic) RegistrationRootViewController *registrationRootViewController;
@property (nonatomic) AuthenticationFlowType flowType;

@end



@implementation RegistrationViewController

@synthesize authenticationCoordinator;

ZM_EMPTY_ASSERTING_INIT()

- (instancetype)initWithAuthenticationFlow:(AuthenticationFlowType)flow
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.flowType = flow;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.tintColor = [UIColor whiteColor];
    [self setupNavigationController];
    [self setupConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication.sharedApplication wr_updateStatusBarForCurrentControllerAnimated:YES];
    [self.wr_navigationController.backButton setTintColor:UIColor.whiteColor];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.registrationRootViewController.preferredStatusBarStyle;
}

- (void)setupNavigationController
{
    RegistrationRootViewController *registrationRootViewController = [[RegistrationRootViewController alloc] initWithAuthenticationFlow:self.flowType];
    registrationRootViewController.authenticationCoordinator = self.authenticationCoordinator;
    registrationRootViewController.showLogin = self.shouldShowLogin;
    registrationRootViewController.loginCredentials = self.loginCredentials;
    registrationRootViewController.shouldHideCancelButton = self.shouldHideCancelButton;
    self.registrationRootViewController = registrationRootViewController;
    
    [self addChildViewController:self.registrationRootViewController];
    [self.view addSubview:self.registrationRootViewController.view];
    [self.registrationRootViewController didMoveToParentViewController:self];
}

- (void)setupConstraints
{
    NSArray<NSLayoutConstraint *> *constraints =
  @[
    [self.registrationRootViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.registrationRootViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.registrationRootViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ];

    [NSLayoutConstraint activateConstraints:constraints];
}

+ (RegistrationFlow)registrationFlow
{
    return IS_IPAD ? RegistrationFlowEmail : RegistrationFlowPhone;
}

#pragma mark - AuthenticationCoordinatedViewController

- (void)executeErrorFeedbackAction:(AuthenticationErrorFeedbackAction)feedbackAction
{
    [self.registrationRootViewController executeErrorFeedbackAction:feedbackAction];
}

@end
