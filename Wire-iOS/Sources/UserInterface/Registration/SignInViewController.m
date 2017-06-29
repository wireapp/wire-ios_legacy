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


#import "SignInViewController.h"

@import PureLayout;

#import "WAZUIMagicIOS.h"

#import "Constants.h"
#import "PhoneSignInViewController.h"
#import "EmailSignInViewController.h"
#import "RegistrationFormController.h"
#import "NavigationController.h"
#import "UIResponder+FirstResponder.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

#import "AnalyticsTracker+Navigation.h"



@interface SignInViewController () <PhoneSignInViewControllerDelegate>

@property (nonatomic) PhoneSignInViewController *phoneSignInViewController;
@property (nonatomic) EmailSignInViewController *emailSignInViewController;
@property (nonatomic) UIViewController *presentedSignInViewController;
@property (nonatomic) UIViewController *emailSignInViewControllerContainer;
@property (nonatomic) UIViewController *phoneSignInViewControllerContainer;
@property (nonatomic) UIView *viewControllerContainer;
@property (nonatomic) UIView *buttonContainer;
@property (nonatomic) Button *emailSignInButton;
@property (nonatomic) Button *phoneSignInButton;

@end



@implementation SignInViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.title = NSLocalizedString(@"registration.signin.title", nil);
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewControllerContainer = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.viewControllerContainer];
    
    self.buttonContainer = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.buttonContainer];
    
    self.emailSignInButton = [[Button alloc] initForAutoLayout];
    self.emailSignInButton.contentEdgeInsets = UIEdgeInsetsMake(4, 16, 4, 16);
    self.emailSignInButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    [self.emailSignInButton setBorderColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.emailSignInButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.emailSignInButton.circular = YES;
    [self.emailSignInButton addTarget:self action:@selector(signInByEmail:) forControlEvents:UIControlEventTouchUpInside];
    [self.emailSignInButton setTitle:NSLocalizedString(@"registration.signin.email_button.title", nil).uppercasedWithCurrentLocale forState:UIControlStateNormal];
    [self.buttonContainer addSubview:self.emailSignInButton];
    
    self.phoneSignInButton = [[Button alloc] initForAutoLayout];
    self.phoneSignInButton.contentEdgeInsets = UIEdgeInsetsMake(4, 16, 4, 16);
    self.phoneSignInButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    [self.phoneSignInButton setBorderColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.phoneSignInButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.phoneSignInButton.circular = YES;
    [self.phoneSignInButton addTarget:self action:@selector(signInByPhone:) forControlEvents:UIControlEventTouchUpInside];
    [self.phoneSignInButton setTitle:NSLocalizedString(@"registration.signin.phone_button.title", nil).uppercasedWithCurrentLocale forState:UIControlStateNormal];
    [self.buttonContainer addSubview:self.phoneSignInButton];
    
    [self setupEmailSignInViewController];
    [self setupPhoneFlowViewController];
    
    BOOL hasAddedPhoneNumber = [AccountManager shared].currentUser.phoneNumber.length > 0;
    BOOL hasAddedEmailAddress = [AccountManager shared].currentUser.emailAddress.length > 0;

    if (hasAddedEmailAddress || ! hasAddedPhoneNumber) {
        [self presentSignInViewController:self.emailSignInViewControllerContainer];
    } else {
        [self presentSignInViewController:self.phoneSignInViewController];
    }
    
    self.buttonContainer.hidden = hasAddedEmailAddress || hasAddedPhoneNumber;
    self.view.opaque = NO;
    
    [self setupConstraints];
}

- (void)setupConstraints
{
    [self.buttonContainer autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.buttonContainer autoSetDimension:ALDimensionHeight toSize:IS_IPAD ? 80 : 64];
    [self.buttonContainer autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    [self.emailSignInButton autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.emailSignInButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.emailSignInButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.phoneSignInButton withOffset:-16];
    
    [self.phoneSignInButton autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.phoneSignInButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    [self.buttonContainer autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.viewControllerContainer];
    [self.viewControllerContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
}

- (void)takeFirstResponder
{
    if (self.presentedSignInViewController == self.emailSignInViewControllerContainer) {
        [self.emailSignInViewController takeFirstResponder];
    } else {
        [self.phoneSignInViewController takeFirstResponder];
    }
}

- (void)setupEmailSignInViewController
{
    EmailSignInViewController *emailSignInViewController = [[EmailSignInViewController alloc] init];
    emailSignInViewController.view.frame = self.viewControllerContainer.frame;
    emailSignInViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    emailSignInViewController.analyticsTracker = self.analyticsTracker;
    self.emailSignInViewController = emailSignInViewController;
    self.emailSignInViewControllerContainer = emailSignInViewController.registrationFormViewController;
}

- (void)setupPhoneFlowViewController
{
    PhoneSignInViewController *phoneFlowViewController = [[PhoneSignInViewController alloc] init];
    phoneFlowViewController.formStepDelegate = self.formStepDelegate;
    phoneFlowViewController.view.frame = self.viewControllerContainer.frame;
    phoneFlowViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    phoneFlowViewController.delegate = self;
    phoneFlowViewController.analyticsTracker = self.analyticsTracker;
    self.phoneSignInViewController = phoneFlowViewController;
    self.phoneSignInViewControllerContainer = phoneFlowViewController.registrationFormViewController;
}

- (void)presentSignInViewController:(UIViewController *)viewController
{
    [self updateSignInButtonsForPresentedViewController:viewController];
    
    if (self.presentedSignInViewController) {
        [self.presentedSignInViewController willMoveToParentViewController:nil];
        [self.presentedSignInViewController.view removeFromSuperview];
        [self.presentedSignInViewController removeFromParentViewController];
    }
    
    self.presentedSignInViewController = viewController;
    [self addChildViewController:viewController];
    [self.viewControllerContainer addSubview:viewController.view];
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewController.view autoPinEdgesToSuperviewEdges];
    [viewController didMoveToParentViewController:self];
}

- (void)swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController
{
    if ([self.childViewControllers containsObject:toViewController]) {
        return; // Return if transition is done or already in progress
    }
    
    [self updateSignInButtonsForPresentedViewController:toViewController];
    self.presentedSignInViewController = toViewController;
    
    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];
    
    toViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
    toViewController.view.frame = fromViewController.view.frame;
    [toViewController.view layoutIfNeeded];
    
    [self transitionFromViewController:fromViewController
                      toViewController:toViewController
                              duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                if (toViewController == self.emailSignInViewControllerContainer) {
                                    [self.emailSignInViewController takeFirstResponder];
                                } else {
                                    [self.phoneSignInViewController takeFirstResponder];
                                }
                            }
                            completion:^(BOOL finished) {
                                [toViewController didMoveToParentViewController:self];
                                [fromViewController removeFromParentViewController];
                                
                                if (fromViewController == self.emailSignInViewControllerContainer) {
                                    [self.emailSignInViewController removeObservers];
                                } else {
                                    [self.phoneSignInViewController removeObservers];
                                }
                            }];
}

#pragma mark - Actions

- (void)signInByPhone:(id)sender
{
    [self swapFromViewController:self.emailSignInViewControllerContainer toViewController:self.phoneSignInViewControllerContainer];
}

- (void)signInByEmail:(id)sender
{
    [self swapFromViewController:self.phoneSignInViewControllerContainer toViewController:self.emailSignInViewControllerContainer];
}

- (void)updateSignInButtonsForPresentedViewController:(UIViewController *)viewController
{
    Button *selectedButton;
    Button *deselectedButton;
    
    if (viewController == self.phoneSignInViewControllerContainer) {
        selectedButton = self.phoneSignInButton;
        deselectedButton= self.emailSignInButton;
    } else {
        selectedButton = self.emailSignInButton;
        deselectedButton= self.phoneSignInButton;
    }
    
    deselectedButton.layer.borderWidth = 0;
    deselectedButton.alpha = 0.5;
    
    selectedButton.layer.borderWidth = 1;
    selectedButton.alpha = 1;
}

- (void)presentEmailSignInViewControllerToEnterPassword
{
    self.buttonContainer.hidden = YES;
    self.wr_tabBarController.enabled = NO;
    [self setupEmailSignInViewController];
    [self presentSignInViewController:self.emailSignInViewControllerContainer];
}

#pragma mark - PhoneSignInViewControllerDelegate

- (void)phoneSignInViewControllerNeedsPasswordToRegisterClient
{
    [self presentEmailSignInViewControllerToEnterPassword];
}

@end
