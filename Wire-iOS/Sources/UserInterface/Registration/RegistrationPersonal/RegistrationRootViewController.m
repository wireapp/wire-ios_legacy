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

#import "RegistrationRootViewController.h"
#import "RegistrationPhoneFlowViewController.h"
#import "RegistrationEmailFlowViewController.h"
#import "RegistrationViewController.h"
#import "RegistrationFormController.h"
#import "SignInViewController.h"
#import "AnalyticsTracker+Registration.h"
#import "Constants.h"

#import "Wire-Swift.h"

@interface RegistrationRootViewController () <FormStepDelegate, RegistrationPhoneFlowViewControllerDelegate>

@property (nonatomic) TabBarController *registrationTabBarController;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) AuthenticationFlowType flowType;
@property (nonatomic, weak) SignInViewController *signInViewController;
@property (nonatomic) IconButton *backButton;

@end

@implementation RegistrationRootViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser authenticationFlow:(AuthenticationFlowType)flow
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.unregisteredUser = unregisteredUser;
        self.flowType = flow;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    
    SignInViewController *signInViewController = [[SignInViewController alloc] init];
    signInViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextSignIn];
    signInViewController.loginCredentials = self.loginCredentials;
    
    UIViewController *flowViewController = nil;
    if ([RegistrationViewController registrationFlow] == RegistrationFlowEmail) {
        RegistrationEmailFlowViewController *emailFlowViewController = [[RegistrationEmailFlowViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
        emailFlowViewController.formStepDelegate = self;
        flowViewController = emailFlowViewController;
    }
    else {
        RegistrationPhoneFlowViewController *phoneFlowViewController = [[RegistrationPhoneFlowViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
        phoneFlowViewController.formStepDelegate = self;
        phoneFlowViewController.registrationDelegate = self;
        flowViewController = phoneFlowViewController;
    }

    switch (self.flowType) {
        case AuthenticationFlowRegular:
            break;
        case AuthenticationFlowOnlyLogin:
            self.showLogin = true;
            [self setupBackButton];
            break;
        case AuthenticationFlowOnlyRegistration:
            self.showLogin = false;
            [self setupBackButton];
            break;
    }
    
    self.registrationTabBarController = [[TabBarController alloc] initWithViewControllers:@[flowViewController, signInViewController]];
    self.signInViewController = signInViewController;
    
    if (self.showLogin) {
        [self.registrationTabBarController selectIndex:1 animated:NO];
    }
    
    self.registrationTabBarController.style = TabBarStyleColored;
    self.registrationTabBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addChildViewController:self.registrationTabBarController];
    [self.view addSubview:self.registrationTabBarController.view];
    [self.registrationTabBarController didMoveToParentViewController:self];
    
    [self createConstraints];
}

- (void)setupBackButton
{
    self.backButton = [[IconButton alloc] initForAutoLayout];
    self.backButton.cas_styleClass = @"navigation";

    ZetaIconType iconType = [UIApplication isLeftToRightLayout] ? ZetaIconTypeChevronLeft : ZetaIconTypeChevronRight;

    [self.backButton setIcon:iconType withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.backButton.accessibilityIdentifier = @"BackToLaunchScreenButton";
    [self.view addSubview:self.backButton];

    [self.backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
}


/**
 Setter of showLogin. When this is set to true, switch to login tab animatied. Else animates to register tab

 @param newValue showLogin's new value
 */
- (void)setShowLogin: (BOOL)newValue{
    _showLogin = newValue;
    [self.registrationTabBarController selectIndex:_showLogin ? 1 : 0 animated:YES];
}

- (void)createConstraints
{
    [self.registrationTabBarController.view autoPinEdgesToSuperviewEdgesWithInsets:UIScreen.safeArea excludingEdge:ALEdgeTop];
    [self.registrationTabBarController.view autoSetDimension:ALDimensionHeight toSize:IS_IPAD_FULLSCREEN ? 262 : 244];

    if (self.backButton) {
        CGFloat topMargin = 32 + UIScreen.safeArea.top;
        CGFloat leftMargin = 28 + UIScreen.safeArea.left;
        CGFloat buttonSize = 32;

        [self.backButton autoSetDimension:ALDimensionHeight toSize:buttonSize];
        [self.backButton autoSetDimension:ALDimensionWidth toSize:buttonSize relation:NSLayoutRelationGreaterThanOrEqual];
        [self.backButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:topMargin];
        [self.backButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:leftMargin];
    }
}

- (void)presentLoginTab
{
    [self.registrationTabBarController selectIndex:1 animated:YES];
}

- (void)presentRegistrationTab
{
    [self.registrationTabBarController selectIndex:0 animated:YES];
}

- (void)backButtonTapped
{
    [self.navigationController.navigationController popViewControllerAnimated:YES];
}


#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    [self.formStepDelegate didCompleteFormStep:viewController];
}

- (void)registrationPhoneFlowViewController:(RegistrationPhoneFlowViewController *)viewController needsToSignInWith:(LoginCredentials *)loginCredentials
{
    [self presentLoginTab];
    self.signInViewController.loginCredentials = loginCredentials;
    [self.signInViewController presentEmailSignInViewControllerToEnterPassword];
}

@end
