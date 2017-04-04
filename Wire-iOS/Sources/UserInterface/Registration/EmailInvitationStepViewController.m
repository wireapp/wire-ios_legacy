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


@import WireExtensionComponents;

#import "EmailInvitationStepViewController.h"

#import <PureLayout/PureLayout.h>
@import WireExtensionComponents;

#import "RegistrationTextField.h"
#import "Button.h"
#import "UIViewController+Errors.h"
#import "Constants.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIFont+MagicAccess.h"
#import "WireSyncEngine+iOS.h"
#import "GuidanceLabel.h"
#import "Wire-Swift.h"



@interface EmailInvitationStepViewController () <RegistrationTextFieldDelegate>

@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) RegistrationTextField *emailField;
@property (nonatomic) RegistrationTextField *passwordField;
@property (nonatomic) GuidanceLabel *guidanceLabel;
@property (nonatomic) Button *continueButton;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;

@end


@implementation EmailInvitationStepViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _unregisteredUser = unregisteredUser;
        self.title = NSLocalizedString(@"registration.email_invitation.title", nil);
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createHeroLabel];
    [self createEmailField];
    [self createPasswordField];
    [self createGuidanceLabel];
    
    [self createInitialConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.passwordField becomeFirstResponder];
}

- (void)createHeroLabel
{
    self.heroLabel = [[UILabel alloc] initForAutoLayout];
    self.heroLabel.numberOfLines = 0;
    self.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.heroLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_light"];
    self.heroLabel.attributedText = [self attributedHeroText];
    
    [self.view addSubview:self.heroLabel];
}

- (NSAttributedString *)attributedHeroText
{
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"registration.email_invitation.hero.title", nil), self.unregisteredUser.name];
    NSString *paragraph = NSLocalizedString(@"registration.email_invitation.hero.paragraph", nil);
    
    NSString * text = [@[title, paragraph] componentsJoinedByString:@"\u2029"];
    
    if (IS_IPHONE_4) {
        text = paragraph;
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName : paragraphStyle }];
    [attributedText addAttributes:@{ NSForegroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark],
                                     NSFontAttributeName : [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_thin"] }
                            range:[text rangeOfString:paragraph]];
    
    return [[NSAttributedString alloc] initWithAttributedString: attributedText];
}

- (void)createEmailField
{
    self.emailField = [[RegistrationTextField alloc] initForAutoLayout];
    
    self.emailField.placeholder = NSLocalizedString(@"email.placeholder", nil);
    self.emailField.minimumFontSize = 15.0f;
    self.emailField.accessibilityIdentifier = @"EmailField";
    self.emailField.enabled = NO;
    self.emailField.text = self.unregisteredUser.emailAddress;
    
    [self.view addSubview:self.emailField];
}

- (void)createPasswordField
{
    self.passwordField = [[RegistrationTextField alloc] initForAutoLayout];
    
    self.passwordField.placeholder = NSLocalizedString(@"password.placeholder", nil);
    self.passwordField.secureTextEntry = YES;
    self.passwordField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.passwordField.accessibilityIdentifier = @"PasswordField";
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.delegate = self;
    
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordField.confirmButton addTarget:self action:@selector(confirmInput) forControlEvents:UIControlEventTouchUpInside];
        
    [self.view addSubview:self.passwordField];
}

- (void)createGuidanceLabel
{
    self.guidanceLabel = [[GuidanceLabel alloc] initForAutoLayout];
    [self.view addSubview:self.guidanceLabel];
}

- (void)createInitialConstraints
{
    UIEdgeInsets marginInsets = UIEdgeInsetsMake(28, 28, 28, 28);
    
    [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:marginInsets.left];
    [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:marginInsets.right];
    
    [self.emailField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.heroLabel withOffset:24];
    [self.emailField autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:marginInsets.left];
    [self.emailField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:marginInsets.right];
    [self.emailField autoSetDimension:ALDimensionHeight toSize:40];
    
    [self.passwordField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.emailField withOffset:8];
    [self.passwordField autoPinEdgesToSuperviewEdgesWithInsets:marginInsets excludingEdge:ALEdgeTop];
    [self.passwordField autoSetDimension:ALDimensionHeight toSize:40];
    
    [self.guidanceLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.passwordField withOffset:8];
    [self.guidanceLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:marginInsets.left];
    [self.guidanceLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:marginInsets.right];
    [self.guidanceLabel autoSetDimension:ALDimensionHeight toSize:10];
}

- (void)confirmInput
{
    self.unregisteredUser.password = self.passwordField.text;
    [self.formStepDelegate didCompleteFormStep:self];
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.passwordField && [self updatePasswordGuidance]) {
        [self.passwordField.confirmButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return NO;
    }
    
    return YES;
}

#pragma mark - Field Validation

- (void)textFieldDidChange:(UITextField *)textField
{
    self.continueButton.enabled = [self updatePasswordGuidance];
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
