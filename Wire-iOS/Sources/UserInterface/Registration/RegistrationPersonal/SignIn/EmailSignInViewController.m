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


#import "EmailSignInViewController.h"

@import WireExtensionComponents;

#import "WireSyncEngine+iOS.h"
@import OnePasswordExtension;
#import "RegistrationTextField.h"

#import "GuidanceLabel.h"
#import "WebLinkTextView.h"
#import <WireExtensionComponents/ProgressSpinner.h>
#import "UIImage+ImageUtilities.h"
#import "UIColor+WAZExtensions.h"
#import "UIViewController+Errors.h"
#import "Constants.h"
#import "NSURL+WireLocale.h"
#import "Wire-Swift.h"

#import "Analytics.h"
#import "NSLayoutConstraint+Helpers.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface EmailSignInViewController () <RegistrationTextFieldDelegate, ClientUnregisterViewControllerDelegate>

@property (nonatomic) RegistrationTextField *emailField;
@property (nonatomic) RegistrationTextField *passwordField;
@property (nonatomic) ButtonWithLargerHitArea *forgotPasswordButton;
@property (nonatomic) ButtonWithLargerHitArea *companyLoginButton;
@property (nonatomic) UIStackView *buttonsStackView;

@property (nonatomic) id preLoginAuthenticationToken;
@property (nonatomic) id postLoginAuthenticationToken;

/// After a login try we set this property to @c YES to reset both field accessories after a field change on any of those
@property (nonatomic) BOOL needsToResetBothFieldAccessories;

@property (nonatomic, readonly) BOOL shouldLockPrefilledEmail;
@property (nonatomic, readonly) BOOL hasCompanyLoginCredentials;
@property (nonatomic, readonly) BOOL canStartCompanyLoginFlow;

@end



@interface EmailSignInViewController (AuthenticationObserver) <PreLoginAuthenticationObserver, PostLoginAuthenticationObserver>

@end



@implementation EmailSignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self createEmailField];
    [self createPasswordField];
    [self createButtons];

    [self createConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (nil == self.preLoginAuthenticationToken) {
    
        self.preLoginAuthenticationToken = [PreLoginAuthenticationNotification registerObserver:self
                                                                      forUnauthenticatedSession:[SessionManager shared].unauthenticatedSession];
    }
    
    if (nil == self.postLoginAuthenticationToken) {
        self.postLoginAuthenticationToken = [PostLoginAuthenticationNotification addObserver:self];
    }
    
    if (AutomationHelper.sharedHelper.automationEmailCredentials != nil) {
        ZMEmailCredentials *emailCredentials = AutomationHelper.sharedHelper.automationEmailCredentials;
        self.emailField.text = emailCredentials.email;
        self.passwordField.text = emailCredentials.password;
        [self.passwordField.confirmButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    [self takeFirstResponder];
}

- (void)removeObservers
{
    self.preLoginAuthenticationToken = nil;
    self.postLoginAuthenticationToken = nil;
}

- (void)createEmailField
{
    self.emailField = [RegistrationTextField new];

    if (@available(iOS 11, *)) {
        self.emailField.textContentType = UITextContentTypeUsername;
    }
    self.emailField.placeholder = NSLocalizedString(@"email.placeholder", nil);
    self.emailField.accessibilityLabel = NSLocalizedString(@"email.placeholder", nil);
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.returnKeyType = UIReturnKeyNext;
    self.emailField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailField.minimumFontSize = 15.0f;
    self.emailField.accessibilityIdentifier = @"EmailField";
    self.emailField.delegate = self;
    
    if (self.loginCredentials.emailAddress != nil) {
        // User was previously signed in so we prefill the credentials
        self.emailField.text = self.loginCredentials.emailAddress;
    }

    if (self.shouldLockPrefilledEmail) {
        self.emailField.enabled = NO;
        self.emailField.alpha = 0.75;
    }

    [self.emailField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.view addSubview:self.emailField];
}

- (void)createPasswordField
{
    self.passwordField = [RegistrationTextField new];

    if (@available(iOS 11, *)) {
        self.passwordField.textContentType = UITextContentTypePassword;
    }
    self.passwordField.placeholder = NSLocalizedString(@"password.placeholder", nil);
    self.passwordField.accessibilityLabel = NSLocalizedString(@"password.placeholder", nil);
    self.passwordField.secureTextEntry = YES;
    self.passwordField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.passwordField.accessibilityIdentifier = @"PasswordField";
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.delegate = self;
    
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordField.confirmButton addTarget:self action:@selector(signIn:) forControlEvents:UIControlEventTouchUpInside];
    self.passwordField.confirmButton.accessibilityLabel = NSLocalizedString(@"signin.confirm", @"");
    
    if (self.loginCredentials.password != nil) {
        // User was previously signed in so we prefill the credentials
        self.passwordField.text = self.loginCredentials.password;
        [self checkPasswordFieldAccessoryView];
    }
    
    if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
        UIButton *onePasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        NSBundle *frameworkBundle = [NSBundle bundleForClass:[OnePasswordExtension class]];
        UIImage *image = [UIImage imageNamed:@"onepassword-button" inBundle:frameworkBundle compatibleWithTraitCollection:nil];
        UIImage *onePasswordImage = [image imageWithColor:[UIColor lightGrayColor]];
        onePasswordButton.contentEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 7);
        [onePasswordButton setImage:onePasswordImage forState:UIControlStateNormal];
        [onePasswordButton addTarget:self action:@selector(open1PasswordExtension:) forControlEvents:UIControlEventTouchUpInside];
        onePasswordButton.accessibilityLabel = NSLocalizedString(@"signin.use_one_password.label", @"");
        onePasswordButton.accessibilityHint = NSLocalizedString(@"signin.use_one_password.hint", @"");

        self.passwordField.customRightView = onePasswordButton;
        self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewCustom;
    }
    
    [self.view addSubview:self.passwordField];
}

- (void)createForgotPasswordButton
{
    self.forgotPasswordButton = [ButtonWithLargerHitArea buttonWithType:UIButtonTypeCustom];
    self.forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.forgotPasswordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.4] forState:UIControlStateHighlighted];
    [self.forgotPasswordButton setTitle:[NSLocalizedString(@"signin.forgot_password", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    self.forgotPasswordButton.titleLabel.font = UIFont.smallLightFont;
    [self.forgotPasswordButton addTarget:self action:@selector(resetPassword:) forControlEvents:UIControlEventTouchUpInside];

    self.forgotPasswordButton.accessibilityTraits |= UIAccessibilityTraitLink;
}

- (void)createCompanyLoginButton
{
    self.companyLoginButton = [ButtonWithLargerHitArea buttonWithType:UIButtonTypeCustom];
    self.companyLoginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.companyLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.companyLoginButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.4] forState:UIControlStateHighlighted];
    self.companyLoginButton.accessibilityIdentifier = @"companyLoginButton";
    [self.companyLoginButton setTitle:[NSLocalizedString(@"signin.company_idp.button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    self.companyLoginButton.titleLabel.font = UIFont.smallLightFont;
    [self.companyLoginButton addTarget:self action:@selector(companyLoginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.companyLoginButton.accessibilityTraits |= UIAccessibilityTraitLink;
}

- (void)createButtons
{
    [self createForgotPasswordButton];

    NSArray<__kindof UIView *> *buttons;

    if (self.canStartCompanyLoginFlow) {
        [self createCompanyLoginButton];
        buttons = @[self.forgotPasswordButton, self.companyLoginButton];
    } else {
        buttons = @[self.forgotPasswordButton];
    }

    // Stack View
    self.buttonsStackView = [[UIStackView alloc] initWithArrangedSubviews:buttons];
    self.buttonsStackView.axis = UILayoutConstraintAxisHorizontal;
    self.buttonsStackView.alignment = UIStackViewAlignmentFill;
    self.buttonsStackView.distribution = UIStackViewDistributionEqualSpacing;

    [self.view addSubview:self.buttonsStackView];
}


- (void)createConstraints
{
    self.emailField.translatesAutoresizingMaskIntoConstraints = NO;
    self.passwordField.translatesAutoresizingMaskIntoConstraints = NO;
    self.buttonsStackView.translatesAutoresizingMaskIntoConstraints = NO;

    NSArray<NSLayoutConstraint *> *constraints =
    @[
      // emailField
      [self.emailField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28],
      [self.emailField.topAnchor constraintEqualToAnchor:self.view.topAnchor],
      [self.emailField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28],
      [self.emailField.heightAnchor constraintEqualToConstant:40],

      // passwordField
      [self.passwordField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28],
      [self.passwordField.topAnchor constraintEqualToAnchor:self.emailField.bottomAnchor constant:8],
      [self.passwordField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28],
      [self.passwordField.heightAnchor constraintEqualToConstant:40],

      // buttonsStackView
      [self.buttonsStackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28],
      [self.buttonsStackView.topAnchor constraintEqualToAnchor:self.passwordField.bottomAnchor constant:13],
      [self.buttonsStackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28],
      [self.buttonsStackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-13],
      ];

    [NSLayoutConstraint activateConstraints:constraints];
}

- (ZMEmailCredentials *)credentials
{
    return [ZMEmailCredentials credentialsWithEmail:self.emailField.text
                                           password:self.passwordField.text];
}

- (BOOL)shouldLockPrefilledEmail
{
    if (CompanyLoginController.companyLoginEnabled) {
        return self.hasCompanyLoginCredentials;
    } else {
        return NO;
    }
}

- (BOOL)hasCompanyLoginCredentials
{
    return self.loginCredentials.usesCompanyLogin && self.loginCredentials.emailAddress != nil;
}

- (BOOL)canStartCompanyLoginFlow
{
    return CompanyLoginController.companyLoginEnabled && !self.hasCompanyLoginCredentials;
}

- (void)takeFirstResponder
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    if (@available(iOS 11, *)) {
        // A workaround for iOS11 not autofilling the password textfield (https://wearezeta.atlassian.net/browse/ZIOS-9080).
        // We need to put focus on the textfield as it seems to force iOS to "see" this texfield
        [self.passwordField becomeFirstResponder];
    }

    if (self.emailField.isEnabled) {
        [self.emailField becomeFirstResponder];
    } else {
        [self.passwordField becomeFirstResponder];
    }
}

- (void)presentClientManagementForUserClientIds:(NSArray<NSManagedObjectID *> *)clientIds credentials:(ZMEmailCredentials *)credentials
{    
    NSArray *userClients = [clientIds mapWithBlock:^id(NSManagedObjectID *objId) {
        return [ZMUserSession.sharedSession.managedObjectContext existingObjectWithID:objId error:NULL];
    }];
    
    ClientUnregisterFlowViewController *unregisterClientFlowController = [[ClientUnregisterFlowViewController alloc] initWithClientsList:userClients delegate:self credentials:credentials];
    
    NavigationController *navigationController = self.wr_navigationController;
    navigationController.logoEnabled = NO;
    [navigationController setViewControllers:@[unregisterClientFlowController]];
}

#pragma mark - Actions

- (IBAction)signIn:(id)sender
{
    self.needsToResetBothFieldAccessories = YES;
    
    ZMCredentials *credentials = self.credentials;
    
    self.navigationController.showLoadingView = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{                
        [[UnauthenticatedSession sharedSession] loginWithCredentials:credentials];
    });
}

- (IBAction)resetPassword:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL.wr_passwordResetURL wr_URLByAppendingLocaleParameter]
                                       options:@{}
                             completionHandler:NULL];
}

- (void)companyLoginButtonTapped:(ButtonWithLargerHitArea *)button
{
    if (self.canStartCompanyLoginFlow) {
        [self.delegate emailSignInViewControllerDidTapCompanyLoginButton:self];
    }
}

- (IBAction)open1PasswordExtension:(id)sender
{
    @weakify(self);
    
    [[OnePasswordExtension sharedExtension] findLoginForURLString:NSURL.wr_websiteURL.absoluteString
                                                forViewController:self
                                                           sender:self.passwordField
                                                       completion:^(NSDictionary *loginDict, NSError *error)
     {
         @strongify(self);
         
         if (loginDict) {
             self.emailField.text = loginDict[AppExtensionUsernameKey];
             self.passwordField.text = loginDict[AppExtensionPasswordKey];
             [self checkPasswordFieldAccessoryView];
         }
     }];
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
        return NO;
    }
    else if (textField == self.passwordField && self.passwordField.rightAccessoryView == RegistrationTextFieldRightAccessoryViewConfirmButton) {
        [self.passwordField.confirmButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.emailField) {
        return !self.shouldLockPrefilledEmail;
    } else {
        return YES;
    }
}

#pragma mark - Field Validation

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.emailField) {
        return !self.shouldLockPrefilledEmail;
    } else {
        return YES;
    }
}

- (void)textFieldDidChange:(UITextField *)textField
{
    // Special case: After a sign in try and text change we need to reset both accessory views
    if (self.needsToResetBothFieldAccessories && (textField == self.emailField || textField == self.passwordField)) {
        self.needsToResetBothFieldAccessories = NO;
        
        self.emailField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
        [self checkPasswordFieldAccessoryView];
    }
    else if (textField == self.emailField) {
        self.emailField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
    else if (textField == self.passwordField) {
        [self checkPasswordFieldAccessoryView];
    }
}

- (void)checkPasswordFieldAccessoryView
{
    if (self.passwordField.text.length > 0) {
        self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
    }
    else if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
        self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewCustom;
    }
    else {
        self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
}

#pragma mark - ClientUnregisterViewControllerDelegate

- (void)clientDeletionSucceeded
{
    // nop
}

@end



@implementation EmailSignInViewController (AuthenticationObserver)

- (void)authenticationDidSucceed
{
    // Not necessary to remove the loading view, since the controller would not be used any more.
}

- (void)authenticationReadyToImportBackupWithExistingAccount:(BOOL)existingAccount
{
    self.navigationController.showLoadingView = NO;
}

- (void)authenticationDidFail:(NSError *)error
{
    ZMLogDebug(@"authenticationDidFail: error.code = %li", (long)error.code);
    
    self.navigationController.showLoadingView = NO;
    
    if (error.code != ZMUserSessionNetworkError) {
        self.emailField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewGuidanceDot;
        self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewGuidanceDot;
    }
    
    if (error.code == ZMUserSessionUnknownError) {
        NSString *email = self.emailField.text;
        NSString *password = self.passwordField.text;
        
        if (![ZMUser validateEmailAddress:&email error:nil]) {
            [self showAlertForError:[NSError errorWithDomain:NSError.ZMUserSessionErrorDomain code:ZMUserSessionInvalidEmail userInfo:nil]];
        } else if (![ZMUser validatePassword:&password error:nil]) {
            [self showAlertForError:[NSError errorWithDomain:NSError.ZMUserSessionErrorDomain code:ZMUserSessionInvalidCredentials userInfo:nil]];
        } else {
            [self showAlertForError:error];
        }
    } else if (error.code != ZMUserSessionNeedsPasswordToRegisterClient &&
               error.code != ZMUserSessionCanNotRegisterMoreClients &&
               error.code != ZMUserSessionNeedsToRegisterEmailToRegisterClient) {

        [self showAlertForError:error];
    }
    
    if (error.code == ZMUserSessionCanNotRegisterMoreClients) {
        [self presentClientManagementForUserClientIds:error.userInfo[ZMClientsKey] credentials:[self credentials]];
    }
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
