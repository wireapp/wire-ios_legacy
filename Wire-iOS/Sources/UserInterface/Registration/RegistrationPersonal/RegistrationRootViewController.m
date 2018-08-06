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
#import "Constants.h"

#import "Wire-Swift.h"

@interface RegistrationRootViewController () <FormStepDelegate, RegistrationFlowViewControllerDelegate, CompanyLoginControllerDelegate, SignInViewControllerDelegate>

@property (nonatomic) CompanyLoginController *companyLoginController;

@property (nonatomic) TabBarController *registrationTabBarController;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) AuthenticationFlowType flowType;
@property (nonatomic, weak) SignInViewController *signInViewController;

@property (nonatomic) IconButton *cancelButton;
@property (nonatomic) IconButton *backButton;
@property (nonatomic) UIStackView *rightButtonsStack;

@property (nonatomic) NSLayoutConstraint *contentWidthConstraint;
@property (nonatomic) NSLayoutConstraint *contentHeightConstraint;
@property (nonatomic) NSLayoutConstraint *contentCenterConstraint;

@property (nonatomic) NSLayoutConstraint *contentLeadingConstraint;
@property (nonatomic) NSLayoutConstraint *contentTrailingConstraint;

@end

@implementation RegistrationRootViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser authenticationFlow:(AuthenticationFlowType)flow
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.unregisteredUser = unregisteredUser;
        self.companyLoginController = [[CompanyLoginController alloc] initWithDefaultEnvironment];
        self.flowType = flow;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.companyLoginController.delegate = self;

    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    
    SignInViewController *signInViewController = [[SignInViewController alloc] init];
    signInViewController.loginCredentials = self.loginCredentials;
    signInViewController.delegate = self;
    
    UIViewController *flowViewController = nil;
    if ([RegistrationViewController registrationFlow] == RegistrationFlowEmail) {
        RegistrationEmailFlowViewController *emailFlowViewController = [[RegistrationEmailFlowViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
        emailFlowViewController.formStepDelegate = self;
        emailFlowViewController.registrationDelegate = self;
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
    self.registrationTabBarController.interactive = NO;

    self.signInViewController = signInViewController;
    
    if (self.showLogin) {
        [self.registrationTabBarController selectIndex:1 animated:NO];
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
    self.companyLoginController.autoDetectionEnabled = YES;
    [self.companyLoginController detectLoginCode];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.companyLoginController.autoDetectionEnabled = NO;
}

- (void)setupBackButton
{
    self.backButton = [[IconButton alloc] initForAutoLayout];
    self.backButton.cas_styleClass = @"navigation";

    ZetaIconType iconType = [UIApplication isLeftToRightLayout] ? ZetaIconTypeChevronLeft : ZetaIconTypeChevronRight;

    [self.backButton setIcon:iconType withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.backButton.accessibilityIdentifier = @"BackToLaunchScreenButton";
    self.backButton.accessibilityLabel = NSLocalizedString(@"registration.launch_back_button.label", @"");
    [self.view addSubview:self.backButton];

    [self.backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
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
    self.cancelButton.hidden = self.shouldHideCancelButton || [[SessionManager shared] firstAuthenticatedAccount] == nil;
    self.cancelButton.accessibilityLabel = NSLocalizedString(@"registration.launch_back_button.label", @"");

    [self.cancelButton addTarget:self action:@selector(cancelAddAccount) forControlEvents:UIControlEventTouchUpInside];

    [self.rightButtonsStack addArrangedSubview:self.cancelButton];
    [self.view addSubview:self.rightButtonsStack];
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
    self.contentHeightConstraint = [self.registrationTabBarController.view.heightAnchor constraintEqualToConstant:0];
    self.contentLeadingConstraint = [self.registrationTabBarController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
    self.contentTrailingConstraint = [self.registrationTabBarController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];
    self.contentCenterConstraint = [self.registrationTabBarController.view.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];

    self.contentHeightConstraint.active = YES;
    [self.registrationTabBarController.view.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor].active = YES;

    [self.rightButtonsStack autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:UIScreen.safeArea.top + 36];
    [self.rightButtonsStack autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];

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

- (void)updateConstraintsForRegularLayout:(BOOL)isRegular
{
    self.contentWidthConstraint.active = isRegular;
    self.contentHeightConstraint.constant = isRegular ? 262 : 244;
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

- (void)backButtonTapped
{
    [self.navigationController.navigationController popViewControllerAnimated:YES];
}

- (void)cancelAddAccount
{
    [SessionManager.shared select:[[SessionManager shared] firstAuthenticatedAccount]
                       completion:nil
               tearDownCompletion:nil];
}

#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    [self.formStepDelegate didCompleteFormStep:viewController];
}

- (void)registrationFlowViewController:(FormFlowViewController *)viewController needsToSignInWith:(LoginCredentials *)loginCredentials
{
    [self presentLoginTab];
    [self.signInViewController presentSignInViewControllerWithCredentials:loginCredentials];
}

#pragma mark - SignInViewControllerDelegate

- (void)signInViewControllerDidTapCompanyLoginButton:(SignInViewController *)signInViewController
{
    [self.companyLoginController displayLoginCodePrompt];
}

#pragma mark - CompanyLoginControllerDelegate

- (void)controller:(CompanyLoginController * _Nonnull)controller presentAlert:(UIAlertController * _Nonnull)presentAlert
{
    [self presentViewController:presentAlert animated:YES completion:nil];
}

- (void)controller:(CompanyLoginController *)controller showLoadingView:(BOOL)showLoadingView
{
    self.showLoadingView = showLoadingView;
}

@end
