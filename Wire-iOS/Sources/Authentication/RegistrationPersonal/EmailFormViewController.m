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


#import "EmailFormViewController.h"

@import PureLayout;
@import WireExtensionComponents;

#import "RegistrationTextField.h"
#import "GuidanceLabel.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

#import "UIViewController+Errors.h"

@interface EmailFormViewController () <UITextFieldDelegate>

@property (nonatomic) BOOL nameFieldEnabled;
@property (nonatomic) RegistrationTextField *nameField;
@property (nonatomic) RegistrationTextField *emailField;
@property (nonatomic) RegistrationTextField *passwordField;
@property (nonatomic) GuidanceLabel *guidanceLabel;

@end

@implementation EmailFormViewController

- (instancetype)initWithNameFieldEnabled:(BOOL)nameFieldEnabled
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.nameFieldEnabled = nameFieldEnabled;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.nameFieldEnabled) {
        [self createNameField];
    }
    
    [self createEmailField];
    [self createPasswordField];
    [self createGuidanceLabel];
    
    [self updateViewConstraints];
}

- (void)createNameField
{
    self.nameField = [[RegistrationTextField alloc] initForAutoLayout];
    self.nameField.placeholder = NSLocalizedString(@"name.placeholder", nil);
    self.nameField.accessibilityLabel = NSLocalizedString(@"name.placeholder", @"");
    self.nameField.returnKeyType = UIReturnKeyNext;
    self.nameField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.nameField.minimumFontSize = 15.0f;
    self.nameField.accessibilityIdentifier = @"NameField";
    self.nameField.delegate = self;

    [self.nameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.nameField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    
    [self.view addSubview:self.nameField];
}

- (void)createEmailField
{
    
    self.emailField = [[RegistrationTextField alloc] initForAutoLayout];
    
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
    
    [self.emailField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.emailField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    
    [self.view addSubview:self.emailField];
}

- (void)createPasswordField
{
    self.passwordField = [[RegistrationTextField alloc] initForAutoLayout];
    
    self.passwordField.placeholder = NSLocalizedString(@"password.placeholder", nil);
    self.passwordField.accessibilityLabel = NSLocalizedString(@"password.placeholder", nil);
    self.passwordField.secureTextEntry = YES;
    self.passwordField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.passwordField.accessibilityIdentifier = @"PasswordField";
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.delegate = self;
    self.passwordField.confirmButton.accessibilityLabel = NSLocalizedString(@"registration.confirm", @"");

    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    
    [self.view addSubview:self.passwordField];
}

- (void)createGuidanceLabel
{
    self.guidanceLabel = [[GuidanceLabel alloc] initForAutoLayout];
    [self.view addSubview:self.guidanceLabel];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (self.nameFieldEnabled) {
        [self.nameField autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.nameField autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.nameField autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.nameField autoSetDimension:ALDimensionHeight toSize:40];
        [self.emailField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameField withOffset:8];
    } else {
        [self.emailField autoPinEdgeToSuperviewEdge:ALEdgeTop];
    }
    
    [self.emailField autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.emailField autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.emailField autoSetDimension:ALDimensionHeight toSize:40];

    [self.passwordField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.emailField withOffset:8];
    [self.passwordField autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.passwordField autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.passwordField autoSetDimension:ALDimensionHeight toSize:40];
    
    [self.guidanceLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.passwordField withOffset:8];
    [self.guidanceLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
}

#pragma mark - TextField Events

- (void)textFieldDidChange:(UITextField *)field
{
    if (field == self.nameField) {
        [self updateNameGuidance];
        self.nameField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
    else if (field == self.emailField) {
        self.emailField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
    else if (field == self.passwordField) {
        BOOL valid = [self updatePasswordGuidance];
        
        if (valid) {
            self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
        } else {
            self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)field
{
    self.guidanceLabel.text = @"";
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.nameField) {
        [self.emailField becomeFirstResponder];
        return NO;
    }
    else if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
        return NO;
    }
    else if (textField == self.passwordField && self.passwordField.rightAccessoryView == RegistrationTextFieldRightAccessoryViewConfirmButton) {
        [self.passwordField.confirmButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return NO;
    }
    
    return YES;
}

#pragma mark - InputField Validation

- (void)resetAllFields
{
    [self resetTextFields];
    
    if (self.nameFieldEnabled) {
        self.nameField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
    
    self.emailField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
}

- (void)resetTextFields
{
    self.emailField.text = @"";
    self.passwordField.text = @"";
}

- (BOOL)validateAllFields
{
    BOOL validName = YES;
    if (self.nameFieldEnabled) {
        validName = [self validateName];
    }
    
    BOOL validEmail = [self validateEmail];
    
    if (! validName && ! validEmail) {
        [self showAlertForMessage:NSLocalizedString(@"error.name_and_email", @"")];
    }
    else if (! validName) {
        [self showAlertForMessage:NSLocalizedString(@"error.full_name" , @"")];
    }
    else if (! validEmail) {
        [self showAlertForMessage:NSLocalizedString(@"error.email" , @"")];
    }
    
    return validName && validEmail;
}

- (BOOL)validateName
{
    NSError *error = nil;
    NSString *newName = self.nameField.text;
    BOOL valid = [ZMUser validateValue:&newName forKey:NSStringFromSelector(@selector(name)) error:&error];
    
    if (valid) {
        self.nameField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
    else {
        self.nameField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewGuidanceDot;
    }
    
    return valid;
}

- (BOOL)validateEmail
{
    NSError *error = nil;
    NSString *newEmail = self.emailField.text;
    BOOL valid = [ZMUser validateValue:&newEmail forKey:NSStringFromSelector(@selector(emailAddress)) error:&error];
    
    if (valid) {
        self.emailField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
    else {
        self.emailField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewGuidanceDot;
    }
    
    return valid;
}

- (BOOL)updateNameGuidance
{
    NSError *error = nil;
    NSString *newName = self.nameField.text;
    BOOL valid = [ZMUser validateValue:&newName forKey:NSStringFromSelector(@selector(name)) error:&error];
    
    if (valid) {
        self.guidanceLabel.text = @"";
    }
    else if (error) {
        NSString *key = [self localizationKeyForError:error prefix:@"name"];
        self.guidanceLabel.text = [NSLocalizedString(key, nil) uppercasedWithCurrentLocale];
    }
    
    return valid;
}

- (BOOL)updatePasswordGuidance
{
    NSError *error = nil;
    NSString *newPassword = self.passwordField.text;
    BOOL valid = [ZMUser validatePassword:&newPassword error:&error];
    
    if (valid) {
        self.guidanceLabel.text = @"";
        self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
    }
    else if (error) {
        NSString *key = [self localizationKeyForError:error prefix:@"password"];
        self.guidanceLabel.text = [NSLocalizedString(key, nil) uppercasedWithCurrentLocale];
        self.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
    
    return valid;
}

- (NSString *)localizationKeyForError:(NSError *)error prefix:(NSString *)prefix
{
     NSString *key = nil;
    
    switch (error.code) {
        case ZMObjectValidationErrorCodeStringTooShort:
            key = [NSString stringWithFormat:@"%@.guidance.tooshort", prefix];
            break;
        case ZMObjectValidationErrorCodeStringTooLong:
            key = [NSString stringWithFormat:@"%@.guidance.toolong", prefix];
        default:
            break;
    }
    
    return key;
}

@end
