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
#import "RegistrationViewController.h"
#import "RegistrationFormController.h"
#import "SignInViewController.h"
#import "Constants.h"
#import "EmailStepViewController.h"
#import "PhoneNumberStepViewController.h"

#import "Wire-Swift.h"

@interface RegistrationRootViewController () <AuthenticationCoordinatedViewController, PhoneNumberStepViewControllerDelegate, EmailStepViewControllerDelegate, TabBarControllerDelegate>

@property (nonatomic) TabBarController *registrationTabBarController;
@property (nonatomic) AuthenticationFlowType flowType;
@property (nonatomic, weak) SignInViewController *signInViewController;
@property (nonatomic, weak) UIViewController<AuthenticationCoordinatedViewController> *flowViewController;

@property (nonatomic) IconButton *cancelButton;
@property (nonatomic) UIStackView *rightButtonsStack;

@property (nonatomic) NSLayoutConstraint *contentWidthConstraint;
@property (nonatomic) NSLayoutConstraint *contentHeightConstraint;
@property (nonatomic) NSLayoutConstraint *contentCenterConstraint;

@property (nonatomic) NSLayoutConstraint *contentLeadingConstraint;
@property (nonatomic) NSLayoutConstraint *contentTrailingConstraint;

@end

@implementation RegistrationRootViewController

@synthesize authenticationCoordinator;

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

    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    
    SignInViewController *signInViewController = [[SignInViewController alloc] init];
    signInViewController.loginCredentials = self.loginCredentials;

    UIViewController<AuthenticationCoordinatedViewController> *flowViewController;
    if ([RegistrationViewController registrationFlow] == RegistrationFlowEmail) {
        EmailStepViewController *emailStepViewController = [[EmailStepViewController alloc] init];
        emailStepViewController.delegate = self;
        flowViewController = emailStepViewController;
    } else {
        PhoneNumberStepViewController *phoneNumberStepViewController = [[PhoneNumberStepViewController alloc] init];
        phoneNumberStepViewController.delegate = self;
        flowViewController = phoneNumberStepViewController;
    }

    flowViewController.title = NSLocalizedString(@"registration.title", @"");

    switch (self.flowType) {
        case AuthenticationFlowOnlyLogin:
        case AuthenticationFlowLogin:
            self.showLogin = true;
            break;
        case AuthenticationFlowRegistration:
            self.showLogin = false;
            break;
    }
    
    self.registrationTabBarController = [[TabBarController alloc] initWithViewControllers:@[flowViewController, signInViewController]];
    self.registrationTabBarController.interactive = NO;
    self.registrationTabBarController.delegate = self;

    if (self.flowType == AuthenticationFlowOnlyLogin) {
        self.registrationTabBarController.tabBarHidden = YES;
    } else {
        self.registrationTabBarController.tabBarHidden = NO;
    }

    self.signInViewController = signInViewController;
    self.flowViewController = flowViewController;
    self.signInViewController.authenticationCoordinator = self.authenticationCoordinator;
    self.flowViewController.authenticationCoordinator = self.authenticationCoordinator;

    if (self.showLogin) {
        [self.registrationTabBarController selectIndex:1 animated:NO];
    } else {
        [self.registrationTabBarController selectIndex:0 animated:NO];
    }
    
    self.registrationTabBarController.style = ColorSchemeVariantDark;
    self.registrationTabBarController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:self.registrationTabBarController];
    [self.view addSubview:self.registrationTabBarController.view];
    [self.view addSubview:self.cancelButton];
    [self.registrationTabBarController didMoveToParentViewController:self];

    [self setUpRightButtons];
    [self createConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateConstraintsForRegularLayout:self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular];
    self.wr_navigationController.backButton.tintColor = [UIColor whiteColor];
    [self.view layoutIfNeeded];
}

- (void)setUpRightButtons
{
    self.rightButtonsStack = [[UIStackView alloc] initForAutoLayout];
    self.rightButtonsStack.spacing = 16;
    self.rightButtonsStack.alignment = UIStackViewAlignmentCenter;
    self.rightButtonsStack.axis = UILayoutConstraintAxisHorizontal;

    self.cancelButton = [[IconButton alloc] init];
    [self.cancelButton setIcon:ZetaIconTypeCancel withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.cancelButton setIconColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.cancelButton.accessibilityIdentifier = @"cancelAddAccount";
    self.cancelButton.hidden = self.shouldHideCancelButton || [[SessionManager shared] firstAuthenticatedAccountExcludingCredentials:self.loginCredentials] == nil;
    self.cancelButton.accessibilityLabel = NSLocalizedString(@"registration.launch_back_button.label", @"");

    [self.cancelButton addTarget:self action:@selector(cancelAddAccount) forControlEvents:UIControlEventTouchUpInside];

    [self.rightButtonsStack addArrangedSubview:self.cancelButton];
    [self.view addSubview:self.rightButtonsStack];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/**
 Setter of showLogin. When this is set to true, switch to login tab animatied. Else animates to register tab

 @param newValue showLogin's new value
 */
- (void)setShowLogin: (BOOL)newValue {
    _showLogin = newValue;
    [self.registrationTabBarController selectIndex:_showLogin ? 1 : 0 animated:YES];
}

- (void)createConstraints
{
    self.contentWidthConstraint = [self.registrationTabBarController.view.widthAnchor constraintEqualToConstant:self.maximumFormSize.width];
    self.contentHeightConstraint = [self.registrationTabBarController.view.heightAnchor constraintEqualToConstant:[self contentHeightConstraintConstant: self.isHorizontalSizeClassRegular]];
    self.contentLeadingConstraint = [self.registrationTabBarController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
    self.contentTrailingConstraint = [self.registrationTabBarController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];
    self.contentCenterConstraint = [self.registrationTabBarController.view.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];

    self.contentHeightConstraint.active = YES;
    [self.registrationTabBarController.view.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor].active = YES;

    [self.rightButtonsStack autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:UIScreen.safeArea.top + 36];
    [self.rightButtonsStack autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
}


- (CGFloat)contentHeightConstraintConstant:(BOOL)isRegular {
    CGFloat height =  isRegular ? 262 : 244;
    return self.registrationTabBarController.tabBarHidden ? height - 48 : height;
}

- (void)updateConstraintsForRegularLayout:(BOOL)isRegular
{
    self.contentWidthConstraint.active = isRegular;
    self.contentHeightConstraint.constant = [self contentHeightConstraintConstant: isRegular];
    self.contentCenterConstraint.active = isRegular;

    self.contentLeadingConstraint.active = !isRegular;
    self.contentTrailingConstraint.active = !isRegular;
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateConstraintsForRegularLayout:newCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular];
    } completion:nil];
}

- (void)presentLoginTab
{
    [self.registrationTabBarController selectIndex:1 animated:YES];
}

- (void)presentRegistrationTab
{
    [self.registrationTabBarController selectIndex:0 animated:YES];
}

- (void)cancelAddAccount
{
    [SessionManager.shared select:[[SessionManager shared] firstAuthenticatedAccountExcludingCredentials:self.loginCredentials]
                       completion:nil
               tearDownCompletion:nil];
}

- (void)executeErrorFeedbackAction:(AuthenticationErrorFeedbackAction)feedbackAction
{
    switch (self.flowType) {
        case AuthenticationFlowOnlyLogin:
        case AuthenticationFlowLogin:
            if ([self.signInViewController respondsToSelector:@selector(executeErrorFeedbackAction:)]) {
                [self.signInViewController executeErrorFeedbackAction:feedbackAction];
            }
            break;
        case AuthenticationFlowRegistration:
            if ([self.flowViewController respondsToSelector:@selector(executeErrorFeedbackAction:)]) {
                [self.flowViewController executeErrorFeedbackAction:feedbackAction];
            }
            break;
    }
}

#pragma mark - Registration Delegates

- (void)tabBarController:(TabBarController *)controller tabBarDidSelectIndex:(NSInteger)tabBarDidSelectIndex
{
    [self.authenticationCoordinator permuteCredentialProvidingFlowType];

    if (tabBarDidSelectIndex == 0) {
        self.flowType = AuthenticationFlowRegistration;
    } else {
        self.flowType = AuthenticationFlowOnlyLogin;
    }
}

- (void)phoneNumberStepViewControllerDidPickPhoneNumber:(NSString *)phoneNumber
{
    [self.authenticationCoordinator startRegistrationWithPhoneNumber:phoneNumber];
}

- (void)emailStepViewControllerDidFinishWithInput:(EmailStepViewControllerInput *)input
{
    [self.authenticationCoordinator startRegistrationWithName:input.name email:input.emailAddress password:input.password];
}

@end
