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
@property (nonatomic, weak) SignInViewController *signInViewController;

@end

@implementation RegistrationRootViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.unregisteredUser = unregisteredUser;
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
    
    self.registrationTabBarController = [[TabBarController alloc] initWithViewControllers:@[flowViewController, signInViewController]];
    self.signInViewController = signInViewController;
    
    if (self.forceLogin) {
        [self.registrationTabBarController selectIndex:1 animated:NO];
        self.registrationTabBarController.enabled = ! self.forceLogin;
    }
    
    self.registrationTabBarController.style = TabBarStyleColored;
    self.registrationTabBarController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    [self addChildViewController:self.registrationTabBarController];
    [self.view addSubview:self.registrationTabBarController.view];
    [self.registrationTabBarController didMoveToParentViewController:self];
    
    [self createConstraints];
}

- (void)createConstraints
{
    [self.registrationTabBarController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.registrationTabBarController.view autoSetDimension:ALDimensionHeight toSize:IS_IPAD ? 262 : 244];
}

- (void)presentLoginTab
{
    [self.registrationTabBarController selectIndex:1 animated:YES];
}

- (void)presentRegistrationTab
{
    [self.registrationTabBarController selectIndex:0 animated:YES];
}

#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    [self.formStepDelegate didCompleteFormStep:viewController];
}

- (void)registrationPhoneFlowViewControllerNeedsSignIn:(RegistrationPhoneFlowViewController *)viewController
{
    [self presentLoginTab];
    [self.signInViewController presentEmailSignInViewControllerToEnterPassword];
}

@end
