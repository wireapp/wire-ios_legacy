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


#import "RegistrationPhoneFlowViewController.h"

@import PureLayout;

#import "NavigationController.h"
#import "PhoneNumberStepViewController.h"
#import "PhoneVerificationStepViewController.h"
#import "PopTransition.h"
#import "PushTransition.h"
#import "RegistrationFormController.h"
#import "NavigationController.h"
#import "WireSyncEngine+iOS.h"
#import "UIFont+MagicAccess.h"
#import "UIViewController+Errors.h"
#import <WireExtensionComponents/UIViewController+LoadingView.h>
#import "CheckmarkViewController.h"
#import "TermsOfUseStepViewController.h"
#import "NameStepViewController.h"
#import "ProfilePictureStepViewController.h"
#import "AppDelegate.h"
#import "AddEmailPasswordViewController.h"
#import "AnalyticsTracker+Registration.h"
#import "Wire-Swift.h"

@import WireExtensionComponents;

@interface RegistrationPhoneFlowViewController () <UINavigationControllerDelegate, FormStepDelegate, PhoneVerificationStepViewControllerDelegate, ZMRegistrationObserver, PreLoginAuthenticationObserver>

@property (nonatomic) PhoneNumberStepViewController *phoneNumberStepViewController;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) id authToken;
@property (nonatomic) id<ZMRegistrationObserverToken> registrationToken;

@end

@implementation RegistrationPhoneFlowViewController

- (void)dealloc
{
    [self removeObservers];
}

- (void)removeObservers
{
    self.authToken = nil;
    self.registrationToken = nil;
}

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.title = NSLocalizedString(@"registration.title", @"");
        self.unregisteredUser = unregisteredUser;
   
        self.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextRegistrationPhone];
    }

    return self;
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    if (parent && self.authToken == nil && self.registrationToken == nil) {
        self.authToken = [PreLoginAuthenticationNotification registerObserver:self
                                                    forUnauthenticatedSession:[SessionManager shared].unauthenticatedSession];
        self.registrationToken = [[UnauthenticatedSession sharedSession] addRegistrationObserver:self];
    } else {
        [self removeObservers];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createNavigationController];
    
    self.view.opaque = NO;
}

- (void)takeFirstResponder
{
    [self.phoneNumberStepViewController takeFirstResponder];
}

- (void)createNavigationController
{
    PhoneNumberStepViewController *phoneNumberStepViewController = [[PhoneNumberStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
    phoneNumberStepViewController.formStepDelegate = self;
    phoneNumberStepViewController.invitationButtonDisplayed = NO;
    phoneNumberStepViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addChildViewController:phoneNumberStepViewController];
    [self.view addSubview:phoneNumberStepViewController.view];
    [phoneNumberStepViewController didMoveToParentViewController:self];
    [phoneNumberStepViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    self.phoneNumberStepViewController = phoneNumberStepViewController;
}

- (void)presentTermsOfUseStepController
{
    // Dismiss keyboard and delay presentation for a smoother transition
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TermsOfUseStepViewController * termsOfUseViewController = [[TermsOfUseStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
        termsOfUseViewController.formStepDelegate = self;
        [self.navigationController pushViewController:[[RegistrationFormController alloc] initWithViewController:termsOfUseViewController] animated:YES];
    });
}

- (void)presentNameStepController
{
    NameStepViewController *nameStepViewController = [[NameStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
    nameStepViewController.formStepDelegate = self;
    
    [self.navigationController pushViewController:nameStepViewController animated:YES];
}

- (void)presentPictureStepController
{
    // Dismiss keyboard and delay presentation for a smoother transition
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ProfilePictureStepViewController *profilePictureStepViewController = [[ProfilePictureStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
        profilePictureStepViewController.formStepDelegate = self;
        profilePictureStepViewController.analyticsTracker = self.analyticsTracker;
        
        [self.navigationController pushViewController:profilePictureStepViewController animated:YES];
    });
}

#pragma mark - FormStepProtocol

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[PhoneNumberStepViewController class]]) {
        self.navigationController.showLoadingView = YES;
        [self.analyticsTracker tagEnteredPhone];
        
        [[UnauthenticatedSession sharedSession] requestPhoneVerificationCodeForRegistration:self.unregisteredUser.phoneNumber];
        
    }
    else if ([viewController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        
        PhoneVerificationStepViewController *phoneVerificationStepViewController = (PhoneVerificationStepViewController *)viewController;
        
        self.unregisteredUser.phoneVerificationCode = phoneVerificationStepViewController.verificationCode;
        
        self.navigationController.showLoadingView = YES;

        [[UnauthenticatedSession sharedSession] verifyPhoneNumberForRegistration:phoneVerificationStepViewController.phoneNumber
                                                       verificationCode:phoneVerificationStepViewController.verificationCode];
    }
    else if ([viewController isKindOfClass:[TermsOfUseStepViewController class]]) {
        [self.analyticsTracker tagAcceptedTermsOfUse];
        [self presentNameStepController];
    }
    else if ([viewController isKindOfClass:[NameStepViewController class]]) {
        [self.analyticsTracker tagEnteredName];
        [self presentPictureStepController];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else if ([viewController isKindOfClass:[ProfilePictureStepViewController class]]) {
        ProfilePictureStepViewController *step = (ProfilePictureStepViewController *)viewController;
        [self.analyticsTracker tagAddedPhotoFromSource:step.photoSource];
        
        ZMCompleteRegistrationUser *completeUser = [self.unregisteredUser completeRegistrationUser];
        [[UnauthenticatedSession sharedSession] registerUser:completeUser];
        
        self.navigationController.showLoadingView = YES;
    }
    else {
        [self.formStepDelegate didCompleteFormStep:self];
    }
}

- (void)didSkipFormStep:(UIViewController *)viewController
{
    [self.formStepDelegate didCompleteFormStep:self];
}

#pragma mark - PhoneVerificationStepViewControllerDelegate

- (void)phoneVerificationStepDidRequestVerificationCode
{
    [[UnauthenticatedSession sharedSession] requestPhoneVerificationCodeForRegistration:self.unregisteredUser.phoneNumber];
}

#pragma mark - ZMAuthenticationObserver

- (void)authenticationDidSucceed
{
    self.showLoadingView = NO;
    [self.analyticsTracker tagRegistrationSucceded];
    
    [self.formStepDelegate didCompleteFormStep:self];
}

- (void)authenticationDidFail:(NSError *)error
{
    DDLogDebug(@"authenticationDidFail: error.code = %li", (long)error.code);
    
    [self.analyticsTracker tagPhoneLoginFailedWithError:error];
    self.navigationController.showLoadingView = NO;
    
    if (error.code == ZMUserSessionNeedsToRegisterEmailToRegisterClient) {
        if (![self.navigationController.topViewController isKindOfClass:[AddEmailPasswordViewController class]]) {
            AddEmailPasswordViewController *addEmailPasswordViewController = [[AddEmailPasswordViewController alloc] init];
            addEmailPasswordViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextPostLogin];
            addEmailPasswordViewController.formStepDelegate = self;
            [self.wr_navigationController setBackButtonEnabled:NO];
            [self.navigationController pushViewController:addEmailPasswordViewController animated:YES];
        }
    }
    else if (error.code == ZMUserSessionNeedsPasswordToRegisterClient) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.registrationDelegate registrationPhoneFlowViewController:self needsToSignInWith:[[LoginCredentials alloc] initWithError:error]];
    }
    else {
        [self showAlertForError:error];
    }

}

- (void)loginCodeRequestDidFail:(NSError *)error
{
    if (self.navigationController.view.window) {
        
        self.navigationController.showLoadingView = NO;
        
        if (error.code != ZMUserSessionCodeRequestIsAlreadyPending) {
            
            [self showAlertForError:error];
        }
        else {
            
            if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
                
                [self proceedToCodeVerificationForLogin:YES];
            }
            else {
                
                [self showAlertForError:error];
            }
        }
        
    }
}

- (void)loginCodeRequestDidSucceed
{
    if (self.navigationController.view.window) {
        
        if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
            [self proceedToCodeVerificationForLogin:YES];
        }
        else {
            [self presentViewController:[[CheckmarkViewController alloc] init] animated:YES completion:nil];
        }
    }
}

#pragma mark - ZMRegistrationObserver

- (void)registrationDidFail:(NSError *)error
{
    self.navigationController.showLoadingView = NO;
    [self showAlertForError:error];
}

- (void)proceedToCodeVerificationForLogin:(BOOL)login
{
    self.navigationController.showLoadingView = NO;
    
    PhoneVerificationStepViewController *phoneVerificationStepViewController = [[PhoneVerificationStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
    phoneVerificationStepViewController.analyticsTracker = self.analyticsTracker;
    phoneVerificationStepViewController.formStepDelegate = self;
    phoneVerificationStepViewController.delegate = self;
    phoneVerificationStepViewController.isLoggingIn = login;
    
    [self.navigationController pushViewController:phoneVerificationStepViewController.registrationFormViewController animated:YES];
}

- (void)phoneVerificationCodeRequestDidSucceed
{
    
    if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        [self proceedToCodeVerificationForLogin:NO];
    } else {
        [self.analyticsTracker tagResentPhoneVerification];
        [self presentViewController:[[CheckmarkViewController alloc] init] animated:YES completion:nil];
    }
}

- (void)phoneVerificationCodeRequestDidFail:(NSError *)error
{
    if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        [self.analyticsTracker tagEnteredPhoneFailedWithError:error];
    } else {
        [self.analyticsTracker tagResentPhoneVerificationFailedWithError:error];
    }
    
    self.navigationController.showLoadingView = NO;
    [self showAlertForError:error];
}

- (void)phoneVerificationDidSucceed
{
    [self.analyticsTracker tagVerifiedPhone];
    self.navigationController.showLoadingView = NO;
    [self presentTermsOfUseStepController];
}

- (void)phoneVerificationDidFail:(NSError *)error
{
    [self.analyticsTracker tagVerifiedPhoneFailedWithError:error];
    self.navigationController.showLoadingView = NO;
    [self showAlertForError:error];
}

@end
