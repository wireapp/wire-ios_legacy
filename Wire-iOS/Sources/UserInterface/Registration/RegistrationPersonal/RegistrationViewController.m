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
#import "WAZUIMagicIOS.h"

#import "UIColor+WAZExtensions.h"
#import "UIViewController+Errors.h"

#import "Wire-Swift.h"

#import "RegistrationFormController.h"
#import "KeyboardAvoidingViewController.h"

#import "PhoneSignInViewController.h"

#import "AnalyticsTracker+Registration.h"

@interface RegistrationViewController (UserSessionObserver) <SessionManagerCreatedSessionObserver, PostLoginAuthenticationObserver>
@end

@interface RegistrationViewController () <UINavigationControllerDelegate, FormStepDelegate, ZMInitialSyncCompletionObserver>

@property (nonatomic) BOOL registeredInThisSession;

@property (nonatomic) RegistrationRootViewController *registrationRootViewController;
@property (nonatomic) KeyboardAvoidingViewController *keyboardAvoidingViewController;
@property (nonatomic) NavigationController *rootNavigationController;
@property (nonatomic) PopTransition *popTransition;
@property (nonatomic) PushTransition *pushTransition;
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) BOOL hasPushedPostRegistrationStep;
@property (nonatomic) NSArray<UserClient *>* userClients;
@property (nonatomic) id initialSyncObserverToken;
@property (nonatomic) id postLoginToken;
@property (nonatomic) id sessionCreationObserverToken;
@property (nonatomic) AuthenticationFlowType flowType;

@end



@implementation RegistrationViewController

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
    self.postLoginToken = [PostLoginAuthenticationNotification addObserver:self];
    self.sessionCreationObserverToken = [[SessionManager shared] addSessionManagerCreatedSessionObserver:self];
    
    [self setupBackgroundViewController];
    [self setupNavigationController];
    
    [self updateViewConstraints];
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
                                 userSessionErrorCode == ZMUserSessionNeedsPasswordToRegisterClient ||
                                 userSessionErrorCode == ZMUserSessionCanNotRegisterMoreClients;
    
    RegistrationRootViewController *registrationRootViewController = [[RegistrationRootViewController alloc] initWithUnregisteredUser:self.unregisteredUser authenticationFlow:self.flowType];
    registrationRootViewController.formStepDelegate = self;
    registrationRootViewController.hasSignInError = self.signInError != nil && !addingAdditionalAccount;
    registrationRootViewController.showLogin = needsToReauthenticate || addingAdditionalAccount;
    registrationRootViewController.loginCredentials = [[LoginCredentials alloc] initWithError:self.signInError];
    registrationRootViewController.shouldHideCancelButton = self.shouldHideCancelButton;
    self.registrationRootViewController = registrationRootViewController;
    
    UIViewController *rootViewController = registrationRootViewController;

    if (userSessionErrorCode == ZMUserSessionNeedsToRegisterEmailToRegisterClient) {
        AddEmailPasswordViewController *addEmailPasswordViewController = [[AddEmailPasswordViewController alloc] init];
        addEmailPasswordViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextPostLogin];
        addEmailPasswordViewController.formStepDelegate = self;
        rootViewController = addEmailPasswordViewController;
    }

    self.rootNavigationController = [[NavigationController alloc] initWithRootViewController:rootViewController];
    self.rootNavigationController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.rootNavigationController.view.opaque = NO;
    self.rootNavigationController.delegate = self;
    self.rootNavigationController.navigationBarHidden = YES;
    self.rootNavigationController.logoEnabled = !IS_IPHONE_4 && (self.signInError != nil);
    
    self.keyboardAvoidingViewController = [[KeyboardAvoidingViewController alloc] initWithViewController:self.rootNavigationController];
    self.keyboardAvoidingViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addChildViewController:self.keyboardAvoidingViewController];
    [self.view addSubview:self.keyboardAvoidingViewController.view];
    [self.keyboardAvoidingViewController didMoveToParentViewController:self];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.backgroundImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.keyboardAvoidingViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
}

+ (RegistrationFlow)registrationFlow
{
    return IS_IPAD ? RegistrationFlowEmail : RegistrationFlowPhone;
}

- (void)presentNoHistoryViewController:(ContextType)type
{
    if ([self.rootNavigationController.topViewController isKindOfClass:[NoHistoryViewController class]]) {
        return;
    }
    NoHistoryViewController *noHistoryViewController = [[NoHistoryViewController alloc] init];
    noHistoryViewController.formStepDelegate = self;
    noHistoryViewController.contextType = type;
    
    self.rootNavigationController.backButtonEnabled = NO;
    [self.rootNavigationController pushViewController:noHistoryViewController animated:YES];
}

#pragma mark - FormStepProtocol

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    BOOL isAddPhoneNumber = [viewController isKindOfClass:[AddPhoneNumberViewController class]];
    BOOL isAddEmailPassword = [viewController isKindOfClass:[AddEmailPasswordViewController class]];
    BOOL isNoHistoryViewController = [viewController isKindOfClass:[NoHistoryViewController class]];
    BOOL isEmailRegistration = [viewController isKindOfClass:[RegistrationEmailFlowViewController class]];
    
    if (isEmailRegistration) {
        [self.delegate registrationViewControllerDidCompleteRegistration];
    }
    else if (isAddPhoneNumber || isAddEmailPassword) {
        [self presentNoHistoryViewController:ContextTypeNewDevice];
    }
    else if (isNoHistoryViewController) {
        [self.delegate registrationViewControllerDidSignIn];
    }
}

- (void)didSkipFormStep:(UIViewController *)viewController
{
    BOOL isAddPhoneNumber = [viewController isKindOfClass:[AddPhoneNumberViewController class]];
    
    if (isAddPhoneNumber) {
        ContextType type =  [[ZMUserSession sharedSession] hadHistoryAtLastLogin] ? ContextTypeLoggedOut : ContextTypeNewDevice;
        [self presentNoHistoryViewController:type];
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

#pragma mark - ZMIncomingPersonalInvitationObserver

- (void)didNotFindPersonalInvitation
{
    // nop
}

- (void)willFetchPersonalInvitation
{
    // nop
}

- (void)didFailToFetchPersonalInvitationWithError:(NSError *)error
{
    DDLogDebug(@"Failed to fetch invitation with error: %@", error);
}

#pragma mark - ZMInitialSyncCompletionObserver

- (void)initialSyncCompleted
{
    self.rootNavigationController.showLoadingView = NO;
    
    if (AutomationHelper.sharedHelper.skipFirstLoginAlerts) {
        [self.delegate registrationViewControllerDidSignIn];
        return;
    }
    
    if (! [[ZMUserSession sharedSession] registeredOnThisDevice] && [[[ZMUser selfUser] emailAddress] length] == 0) {
        self.rootNavigationController.logoEnabled = NO;
        self.rootNavigationController.backButtonEnabled = NO;
        
        if (self.hasPushedPostRegistrationStep) {
            // Just do nothing. We been here already and pushed the AddPhoneNumberViewController before.		
            // This case can happen if the user jumps out of the app to get the code an comes back to the app again.
            return;
        } else {
            self.hasPushedPostRegistrationStep = YES;
        }
        
        AddEmailPasswordViewController *addEmailPasswordViewController = [[AddEmailPasswordViewController alloc] init];
        addEmailPasswordViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextPostLogin];
        addEmailPasswordViewController.formStepDelegate = self;
        addEmailPasswordViewController.skipButtonType = AddEmailPasswordViewControllerSkipButtonTypeNone;
        
        [self.rootNavigationController pushViewController:addEmailPasswordViewController animated:YES];
    }
    else if (! [[ZMUserSession sharedSession] registeredOnThisDevice]) {
        ContextType type = [[ZMUserSession sharedSession] hadHistoryAtLastLogin] ? ContextTypeLoggedOut : ContextTypeNewDevice;
        [self presentNoHistoryViewController:type];
    }
    else if ([self.class registrationFlow] == RegistrationFlowPhone) {
        [self.delegate registrationViewControllerDidCompleteRegistration];
    }
}

#pragma mark - ClientUnregisterViewController

- (void)clientDeletionSucceeded
{
    // nop
}

@end

#pragma mark - Session observer

@implementation RegistrationViewController (UserSessionObserver)

- (void)sessionManagerCreatedWithUserSession:(ZMUserSession *)userSession {
    // this method is called when a ZMUserSession is created, including background
    // sessions. In this latter case, the active user session is not set, and may be nil.
    if ([ZMUserSession sharedSession] != nil) {
        self.initialSyncObserverToken = [ZMUserSession addInitialSyncCompletionObserver:self userSession:[ZMUserSession sharedSession]];
    }
}

- (void)clientRegistrationDidSucceedWithAccountId:(NSUUID * _Nonnull)accountId
{
    self.initialSyncObserverToken = [ZMUserSession addInitialSyncCompletionObserver:self userSession:[ZMUserSession sharedSession]];
}

@end
