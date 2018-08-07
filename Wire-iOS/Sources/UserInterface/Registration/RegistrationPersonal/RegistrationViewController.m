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
#import "RegistrationStepViewController.h"
#import "RegistrationPhoneFlowViewController.h"
#import "AddEmailPasswordViewController.h"
#import "AddPhoneNumberViewController.h"
#import "RegistrationEmailFlowViewController.h"
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
#import "KeyboardAvoidingViewController.h"

#import "PhoneSignInViewController.h"
#import "EmailSignInViewController.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface RegistrationViewController (UserSessionObserver) <SessionManagerCreatedSessionObserver, PostLoginAuthenticationObserver>

@end

@interface RegistrationViewController () <UINavigationControllerDelegate, FormStepDelegate>

@property (nonatomic) BOOL registeredInThisSession;

@property (nonatomic) RegistrationRootViewController *registrationRootViewController;
@property (nonatomic) PopTransition *popTransition;
@property (nonatomic) PushTransition *pushTransition;
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) BOOL hasPushedPostRegistrationStep;
@property (nonatomic) NSArray<UserClient *>* userClients;
@property (nonatomic) AuthenticationFlowType flowType;

@end



@implementation RegistrationViewController

@synthesize authenticationCoordinator;

- (instancetype)init
{
    return [self initWithAuthenticationFlow:AuthenticationFlowRegular];
}

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
    
    self.popTransition = [[PopTransition alloc] init];
    self.pushTransition = [[PushTransition alloc] init];

    self.unregisteredUser = [ZMIncompleteRegistrationUser new];
    self.unregisteredUser.accentColorValue = [UIColor indexedAccentColor];

    [self setupBackgroundViewController];
    [self setupNavigationController];
    
    [self updateViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication.sharedApplication wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupBackgroundViewController
{
    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage"]];
    [self.view addSubview:self.backgroundImageView];
}

- (void)setupNavigationController
{
    ZMUserSessionErrorCode userSessionErrorCode = self.signInError.userSessionErrorCode;
    
    BOOL addingAdditionalAccount = userSessionErrorCode == ZMUserSessionAddAccountRequested;
    
    BOOL needsToReauthenticate = userSessionErrorCode == ZMUserSessionClientDeletedRemotely ||
                                 userSessionErrorCode == ZMUserSessionAccessTokenExpired ||
                                userSessionErrorCode == ZMUserSessionNeedsPasswordToRegisterClient;

    RegistrationRootViewController *registrationRootViewController = [[RegistrationRootViewController alloc] initWithUnregisteredUser:self.unregisteredUser authenticationFlow:self.flowType];
    registrationRootViewController.formStepDelegate = self;
    registrationRootViewController.authenticationCoordinator = self.authenticationCoordinator;
    registrationRootViewController.hasSignInError = self.signInError != nil && !addingAdditionalAccount;
    registrationRootViewController.showLogin = needsToReauthenticate || addingAdditionalAccount;
    registrationRootViewController.loginCredentials = [[LoginCredentials alloc] initWithError:self.signInError];
    registrationRootViewController.shouldHideCancelButton = self.shouldHideCancelButton;
    self.registrationRootViewController = registrationRootViewController;
    
    UIViewController *rootViewController = registrationRootViewController;

    if (userSessionErrorCode == ZMUserSessionNeedsToRegisterEmailToRegisterClient) {
        AddEmailPasswordViewController *addEmailPasswordViewController = [[AddEmailPasswordViewController alloc] init];
//        addEmailPasswordViewController.formStepDelegate = self;
        rootViewController = addEmailPasswordViewController;
    }

    [self addChildViewController:self.registrationRootViewController];
    [self.view addSubview:self.registrationRootViewController.view];
    [self.registrationRootViewController didMoveToParentViewController:self];
    
    if (userSessionErrorCode == ZMUserSessionNeedsPasswordToRegisterClient) {
        UIViewController *alertController = [UIAlertController passwordVerificationNeededControllerWithCompletion:nil];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.backgroundImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.registrationRootViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
}

+ (RegistrationFlow)registrationFlow
{
    return IS_IPAD ? RegistrationFlowEmail : RegistrationFlowPhone;
}

#pragma mark - FormStepProtocol

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    BOOL isNoHistoryViewController = [viewController isKindOfClass:[NoHistoryViewController class]];
    BOOL isEmailRegistration = [viewController isKindOfClass:[RegistrationEmailFlowViewController class]];
    
    if (isEmailRegistration) {
//        [self.delegate registrationViewControllerDidCompleteRegistration];
    }
    else if (isNoHistoryViewController) {
        [[UnauthenticatedSession sharedSession] continueAfterBackupImportStep];
    }
}

#pragma mark - NavigationControllerDelegate

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    id <UIViewControllerAnimatedTransitioning> transition = nil;
    
    switch (operation) {
        case UINavigationControllerOperationPop:
            transition = self.popTransition;
            break;
        case UINavigationControllerOperationPush:
            transition = self.pushTransition;
        default:
            break;
    }
    return transition;
}

#pragma mark - AuthenticationCoordinatedViewController

- (void)executeErrorFeedbackAction:(AuthenticationErrorFeedbackAction)feedbackAction
{
    [self.registrationRootViewController executeErrorFeedbackAction:feedbackAction];
}

@end
