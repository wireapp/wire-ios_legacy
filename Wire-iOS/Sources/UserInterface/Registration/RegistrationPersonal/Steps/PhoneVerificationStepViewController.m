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


#import "PhoneVerificationStepViewController.h"

@import PureLayout;

#import "RegistrationTextField.h"
#import "WAZUIMagicIOS.h"
#import "UIView+Borders.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WR_ColorScheme.h"
#import "Constants.h"
#import "Wire-Swift.h"

#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
@import WireExtensionComponents;
@import WireUtilities;


const NSTimeInterval PhoneVerificationResendInterval = 30.0f;

@interface PhoneVerificationStepViewController () <RegistrationTextFieldDelegate, ZMTimerClient>

@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) RegistrationTextField *phoneVerificationField;
@property (nonatomic) UILabel *instructionLabel;
@property (nonatomic) UILabel *resendLabel;
@property (nonatomic) UIButton *resendButton;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;

@property (nonatomic) NSDate *lastSentDate;
@property (nonatomic) ZMTimer *timer;
@end



@implementation PhoneVerificationStepViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timer cancel];
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationLaunchedWithPhoneVerificationCode:) name:ZMLaunchedWithPhoneVerificationCodeNotificationName object:nil];
    }
    
    return self;
}

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [self init];
    if (self) {
        self.unregisteredUser = unregisteredUser;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.unregisteredUser != nil) {
        self.phoneNumber = self.unregisteredUser.phoneNumber;
    }
    
    [self createInstructionLabel];
    [self createPhoneVerificationField];
    [self createResendButton];
    [self createResendLabel];

    self.view.opaque = NO;
    [self updateViewConstraints];
    
    self.lastSentDate = [NSDate date];
    [self updateResendArea];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.phoneVerificationField becomeFirstResponder];
}

- (void)createInstructionLabel
{
    self.instructionLabel = [[UILabel alloc] init];
    self.instructionLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_thin"];
    self.instructionLabel.textColor = [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"];
    self.instructionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"registration.verify_phone_number.instructions", nil), self.phoneNumber];
    self.instructionLabel.numberOfLines = 0;
    
    [self.view addSubview:self.instructionLabel];
}

- (void)createResendLabel
{
    self.resendLabel = [[UILabel alloc] initForAutoLayout];
    self.resendLabel.backgroundColor = [UIColor clearColor];
    self.resendLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.resendLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.resendLabel.numberOfLines = 0;
    [self.view addSubview:self.resendLabel];
}

- (void)createResendButton
{
    self.resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resendButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    [self.resendButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
    [self.resendButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:ColorSchemeVariantDark] forState:UIControlStateHighlighted];
    [self.resendButton setTitle:[NSLocalizedString(@"registration.verify_phone_number.resend", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];

    [self.resendButton addTarget:self action:@selector(requestCode:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.resendButton];
}

- (void)createPhoneVerificationField
{
    self.phoneVerificationField = [[RegistrationTextField alloc] initForAutoLayout];
    self.phoneVerificationField.leftAccessoryView = RegistrationTextFieldLeftAccessoryViewNone;
    self.phoneVerificationField.textAlignment = NSTextAlignmentCenter;
    self.phoneVerificationField.accessibilityLabel = @"verificationField";
    self.phoneVerificationField.keyboardType = UIKeyboardTypeNumberPad;
    self.phoneVerificationField.delegate = self;
    [self.phoneVerificationField.confirmButton addTarget:self action:@selector(verifyCode:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.phoneVerificationField];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.instructionLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.instructionLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        
        [self.phoneVerificationField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.instructionLabel withOffset:24];
        [self.phoneVerificationField autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.phoneVerificationField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        [self.phoneVerificationField autoSetDimension:ALDimensionHeight toSize:40];
        
        [self.resendButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.phoneVerificationField withOffset:24];
        [self.resendButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 28, 24, 28) excludingEdge:ALEdgeTop];
        
        [self.resendLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.phoneVerificationField withOffset:24];
        [self.resendLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 28, 24, 28) excludingEdge:ALEdgeTop];
    }
}

- (void)updateResendArea
{
    NSTimeInterval timeSinceLastResend = [self.lastSentDate timeIntervalSinceNow];
    
    if (fabs(timeSinceLastResend) > PhoneVerificationResendInterval || self.isLoggingIn) {
        self.resendLabel.hidden = YES;
        self.resendButton.hidden = NO;
    }
    else {
        self.resendLabel.hidden = NO;
        self.resendButton.hidden = YES;

        self.resendLabel.text = [[NSString stringWithFormat:NSLocalizedString(@"registration.verify_phone_number.resend_placeholder", @""), PhoneVerificationResendInterval - fabs(timeSinceLastResend)] uppercaseString];
        
        self.timer = [ZMTimer timerWithTarget:self operationQueue:[NSOperationQueue mainQueue]];
        [self.timer fireAfterTimeInterval:1.0f];
    }
}

- (NSString *)verificationCode
{
    return self.phoneVerificationField.text;
}

#pragma mark - Actions

- (IBAction)verifyCode:(id)sender
{
    [self.formStepDelegate didCompleteFormStep:self];
}

- (IBAction)requestCode:(id)sender
{
    // Reset the code field
    self.phoneVerificationField.text = @"";
    self.phoneVerificationField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
        
    [self.delegate phoneVerificationStepDidRequestVerificationCode];
    self.lastSentDate = [NSDate date];
    [self updateResendArea];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSError *error = nil;
    BOOL valid = [ZMUser validatePhoneVerificationCode:&newString error:&error];

    if (error.code == ZMObjectValidationErrorCodeStringTooLong) {
        return NO;
    }
    
    if (valid) {
        self.phoneVerificationField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
    } else {
        self.phoneVerificationField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
    
    return YES;
}

#pragma mark - ZMLaunchedWithPhoneVerificationCodeNotificationName

- (void)applicationLaunchedWithPhoneVerificationCode:(NSNotification *)notification
{
    NSString *verficationCode = notification.userInfo[ZMPhoneVerificationCodeKey];
    
    if (verficationCode.length == 0) {
        return;
    }
    
    BOOL valid = [ZMUser validatePhoneVerificationCode:&verficationCode error:nil];
    
    if (valid) {
        self.phoneVerificationField.text = verficationCode;
        self.phoneVerificationField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
        [self verifyCode:nil];
    }
}

#pragma mark - ZMTimerClient

- (void)timerDidFire:(ZMTimer *)timer
{
    [self updateResendArea];
}

@end
