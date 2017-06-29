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


#import "PhoneSignInViewController.h"

@import PureLayout;

#import "NavigationController.h"
#import "PhoneNumberStepViewController.h"
#import "PhoneVerificationStepViewController.h"
#import "AddEmailPasswordViewController.h"
#import "RegistrationFormController.h"
#import "FormStepDelegate.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
#import "UIFont+MagicAccess.h"
#import <WireExtensionComponents/UIViewController+LoadingView.h>
#import "CheckmarkViewController.h"
#import "StopWatch.h"
#import "AnalyticsTracker+Registration.h"
#import "Wire-Swift.h"


@interface PhoneSignInViewController () <FormStepDelegate, ZMAuthenticationObserver, PhoneVerificationStepViewControllerDelegate>

@property (nonatomic) PhoneNumberStepViewController *phoneNumberStepViewController;
@property (nonatomic) id<ZMAuthenticationObserverToken> authenticationToken;

@property (nonatomic, copy) NSString *phoneNumber;

@end

@implementation PhoneSignInViewController

- (void)dealloc
{
    [self removeObservers];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createPhoneNumberStepViewController];
    
    self.view.opaque = NO;
    self.title = NSLocalizedString(@"registration.title", @"");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.isMovingToParentViewController || self.isBeingPresented || self.authenticationToken == nil) {
        self.authenticationToken = [ZMUserSessionAuthenticationNotification addObserverWithObserver:self];
    }
}

- (void)removeObservers
{
    [ZMUserSessionAuthenticationNotification removeObserver:self.authenticationToken];
    self.authenticationToken = nil;
}

- (void)createPhoneNumberStepViewController
{
    PhoneNumberStepViewController *phoneNumberStepViewController;
    
    if ([ZMUser selfUser].phoneNumber.length > 0) {
        // User was previously signed in so we must force him to sign in with the same credentials
        phoneNumberStepViewController = [[PhoneNumberStepViewController alloc] initWithUneditablePhoneNumber:[ZMUser selfUser].phoneNumber];
    } else {
        phoneNumberStepViewController = [[PhoneNumberStepViewController alloc] init];
    }
    
    phoneNumberStepViewController.formStepDelegate = self;
    phoneNumberStepViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.phoneNumberStepViewController = phoneNumberStepViewController;
    
    
    [self addChildViewController:phoneNumberStepViewController];
    [self.view addSubview:phoneNumberStepViewController.view];
    [phoneNumberStepViewController didMoveToParentViewController:self];
    [phoneNumberStepViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (void)takeFirstResponder
{
    [self.phoneNumberStepViewController takeFirstResponder];
}

- (void)presentAddEmailPasswordViewController
{
    if ([self.navigationController.topViewController isKindOfClass:[AddEmailPasswordViewController class]]) {
        return;
    }
    
    AddEmailPasswordViewController *addEmailPasswordViewController = [[AddEmailPasswordViewController alloc] init];
    addEmailPasswordViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextPostLogin];
    addEmailPasswordViewController.formStepDelegate = self;
    
    [self.wr_navigationController setBackButtonEnabled:NO];
    [self.navigationController pushViewController:addEmailPasswordViewController animated:YES];
}

#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[PhoneNumberStepViewController class]]) {
        self.navigationController.showLoadingView  = YES;
        [self.analyticsTracker tagRequestedPhoneLogin];
        
        PhoneNumberStepViewController *phoneNumberStepViewController = (PhoneNumberStepViewController *)viewController;
        self.phoneNumber = phoneNumberStepViewController.phoneNumber;
        [[ZMUserSession sharedSession] requestPhoneVerificationCodeForLogin:self.phoneNumber];
    }
    else if ([viewController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        self.navigationController.showLoadingView = YES;
        
        PhoneVerificationStepViewController *phoneVerificationStepViewController = (PhoneVerificationStepViewController *)viewController;
        ZMPhoneCredentials *credentials = [ZMPhoneCredentials credentialsWithPhoneNumber:phoneVerificationStepViewController.phoneNumber
                                                                        verificationCode:phoneVerificationStepViewController.verificationCode];
        
        StopWatch *stopWatch = [StopWatch stopWatch];
        [stopWatch restartEvent:@"Login"];
        
        [[UnauthenticatedSession sharedSession] loginWithCredentials:credentials];
    }
}

#pragma mark - PhoneVerificationStepViewControllerDelegate

- (void)phoneVerificationStepDidRequestVerificationCode
{
    [[ZMUserSession sharedSession] requestPhoneVerificationCodeForLogin:self.phoneNumberStepViewController.phoneNumber];
}

#pragma mark - ZMAuthenticationObserver

- (void)loginCodeRequestDidSucceed
{
    if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        [self proceedToCodeVerification];
    }
    else {
        [self.analyticsTracker tagResentPhoneLoginVerification];
        [self presentViewController:[[CheckmarkViewController alloc] init] animated:YES completion:nil];
    }
}

- (void)proceedToCodeVerification
{
    self.navigationController.showLoadingView = NO;
    
    PhoneVerificationStepViewController *phoneVerificationStepViewController = [[PhoneVerificationStepViewController alloc] init];
    phoneVerificationStepViewController.phoneNumber = self.phoneNumber;
    phoneVerificationStepViewController.formStepDelegate = self;
    phoneVerificationStepViewController.delegate = self;
    phoneVerificationStepViewController.isLoggingIn = YES;
    
    [self.navigationController pushViewController:phoneVerificationStepViewController.registrationFormViewController animated:YES];
}

- (void)loginCodeRequestDidFail:(NSError *)error
{
    self.navigationController.showLoadingView = NO;
    
    if (error.code != ZMUserSessionCodeRequestIsAlreadyPending) {
        if ([self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
            [self.analyticsTracker tagResentPhoneLoginVerificationFailedWithError:error];
        } else {
            [self.analyticsTracker tagPhoneLoginFailedWithError:error];
        }

        [self showAlertForError:error];
    }
    else {
        if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
            [self proceedToCodeVerification];
        } else {
            [self showAlertForError:error];
        }   
    }
}

- (void)authenticationDidFail:(NSError *)error
{
    DDLogDebug(@"authenticationDidFail: error.code = %li", (long)error.code);
    
    [self.analyticsTracker tagPhoneLoginFailedWithError:error];
    self.navigationController.showLoadingView = NO;
    
    if (error.code == ZMUserSessionNeedsToRegisterEmailToRegisterClient) {        
        [self presentAddEmailPasswordViewController];
    }
    else if (error.code == ZMUserSessionNeedsPasswordToRegisterClient) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self.delegate phoneSignInViewControllerNeedsPasswordToRegisterClient];
    }
    else {
        [self showAlertForError:error];
    }
}

- (void)authenticationDidSucceed
{
    [self.analyticsTracker tagPhoneLogin];
    self.navigationController.showLoadingView = NO;
}

@end
