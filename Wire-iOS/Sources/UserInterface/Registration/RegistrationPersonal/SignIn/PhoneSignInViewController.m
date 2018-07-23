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
@import WireSyncEngine;

#import "NavigationController.h"
#import "PhoneNumberStepViewController.h"
#import "PhoneVerificationStepViewController.h"
#import "AddEmailPasswordViewController.h"
#import "RegistrationFormController.h"
#import "FormStepDelegate.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
#import <WireExtensionComponents/UIViewController+LoadingView.h>
#import "CheckmarkViewController.h"
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface PhoneSignInViewController () <FormStepDelegate, PreLoginAuthenticationObserver, PostLoginAuthenticationObserver, PhoneVerificationStepViewControllerDelegate>

@property (nonatomic) PhoneNumberStepViewController *phoneNumberStepViewController;

@property (nonatomic) id preLoginAuthenticationToken;
@property (nonatomic) id postLoginAuthenticationToken;

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
    
    if (self.preLoginAuthenticationToken == nil) {
        self.preLoginAuthenticationToken = [PreLoginAuthenticationNotification registerObserver:self
                                                                      forUnauthenticatedSession:[SessionManager shared].unauthenticatedSession];
    }
    if (self.postLoginAuthenticationToken == nil) {
        self.postLoginAuthenticationToken = [PostLoginAuthenticationNotification addObserver:self];
    }
}

- (void)removeObservers
{
    self.preLoginAuthenticationToken = nil;
    self.postLoginAuthenticationToken = nil;
}

- (void)createPhoneNumberStepViewController
{
    PhoneNumberStepViewController *phoneNumberStepViewController = [[PhoneNumberStepViewController alloc] initWithPhoneNumber:self.loginCredentials.phoneNumber isEditable:YES];
    phoneNumberStepViewController.formStepDelegate = self;
    phoneNumberStepViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.phoneNumberStepViewController = phoneNumberStepViewController;
    self.phoneNumberStepViewController.phoneNumberViewController.phoneNumberField.confirmButton.accessibilityLabel = NSLocalizedString(@"signin.confirm", @"");
    
    [self addChildViewController:phoneNumberStepViewController];
    [self.view addSubview:phoneNumberStepViewController.view];
    [phoneNumberStepViewController didMoveToParentViewController:self];
    [phoneNumberStepViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (void)takeFirstResponder
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    [self.phoneNumberStepViewController takeFirstResponder];
}

- (void)presentAddEmailPasswordViewController
{
    if ([self.navigationController.topViewController isKindOfClass:[AddEmailPasswordViewController class]]) {
        return;
    }
    
    AddEmailPasswordViewController *addEmailPasswordViewController = [[AddEmailPasswordViewController alloc] init];
    addEmailPasswordViewController.formStepDelegate = self;
    
    [self.wr_navigationController setBackButtonEnabled:NO];
    [self.navigationController pushViewController:addEmailPasswordViewController animated:YES];
}

#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[PhoneNumberStepViewController class]]) {
        self.navigationController.showLoadingView  = YES;        
        PhoneNumberStepViewController *phoneNumberStepViewController = (PhoneNumberStepViewController *)viewController;
        self.phoneNumber = phoneNumberStepViewController.phoneNumber;
        [[UnauthenticatedSession sharedSession] requestPhoneVerificationCodeForLogin:self.phoneNumber];
    }
    else if ([viewController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        self.navigationController.showLoadingView = YES;
        
        PhoneVerificationStepViewController *phoneVerificationStepViewController = (PhoneVerificationStepViewController *)viewController;
        ZMPhoneCredentials *credentials = [ZMPhoneCredentials credentialsWithPhoneNumber:phoneVerificationStepViewController.phoneNumber
                                                                        verificationCode:phoneVerificationStepViewController.verificationCode];
        
        [[UnauthenticatedSession sharedSession] loginWithCredentials:credentials];
    }
}

#pragma mark - PhoneVerificationStepViewControllerDelegate

- (void)phoneVerificationStepDidRequestVerificationCode
{
    [[UnauthenticatedSession sharedSession] requestPhoneVerificationCodeForLogin:self.phoneNumberStepViewController.phoneNumber];
}

#pragma mark - ZMAuthenticationObserver

- (void)loginCodeRequestDidSucceed
{
    if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        [self proceedToCodeVerification];
    }
    else {
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
    ZMLogDebug(@"authenticationDidFail: error.code = %li", (long)error.code);
    
    self.navigationController.showLoadingView = NO;
    
    if (error.code == ZMUserSessionNeedsToRegisterEmailToRegisterClient) {        
        [self presentAddEmailPasswordViewController];
    }
    else if (error.code == ZMUserSessionNeedsPasswordToRegisterClient) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self.delegate phoneSignInViewControllerNeedsPasswordFor:[[LoginCredentials alloc] initWithError:error]];
    }
    else {
        [self showAlertForError:error];
    }
}

- (void)authenticationReadyToImportBackupWithExistingAccount:(BOOL)existingAccount
{
    self.navigationController.showLoadingView = NO;
}

- (void)authenticationDidSucceed
{
    self.navigationController.showLoadingView = NO;
}

- (void)authenticationInvalidated:(NSError * _Nonnull)error accountId:(NSUUID * _Nonnull)accountId
{
    [self authenticationDidFail:error];
}

- (void)clientRegistrationDidSucceedWithAccountId:(NSUUID * _Nonnull)accountId
{
    [self authenticationDidSucceed];
}

- (void)clientRegistrationDidFail:(NSError * _Nonnull)error accountId:(NSUUID * _Nonnull)accountId
{
    [self authenticationDidFail:error];
}

@end
