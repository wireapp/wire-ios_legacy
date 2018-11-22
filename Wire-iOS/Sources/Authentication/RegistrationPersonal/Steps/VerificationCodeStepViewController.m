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
@import WireExtensionComponents;
@import WireUtilities;

#import "VerificationCodeStepViewController.h"

#import "RegistrationTextField.h"
#import "UIImage+ZetaIconsNeue.h"
#import "Constants.h"
#import "Wire-Swift.h"

#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"

const NSTimeInterval VerificationCodeResendInterval = 30.0f;

@interface VerificationCodeStepViewController () <UITextFieldDelegate, ZMTimerClient>

@property (nonatomic, copy) NSString *credential;

@property (nonatomic) RegistrationTextField *verificationField;
@property (nonatomic) UILabel *instructionLabel;
@property (nonatomic) UILabel *resendLabel;
@property (nonatomic) UIButton *resendButton;

@property (nonatomic) NSDate *lastSentDate;
@property (nonatomic) ZMTimer *timer;

@end


@implementation VerificationCodeStepViewController

@synthesize authenticationCoordinator;

- (void)dealloc
{
    [self.timer cancel];
}

- (instancetype)initWithCredential:(NSString *)credential{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationLaunchedWithPhoneVerificationCode:) name:ZMLaunchedWithPhoneVerificationCodeNotificationName object:nil];
        self.credential = credential;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createInstructionLabel];
    [self createVerificationField];
    [self createResendButton];
    [self createResendLabel];

    self.view.opaque = NO;
    [self configureConstraints];
    
    self.lastSentDate = [NSDate date];
    [self updateResendArea];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!UIAccessibilityIsVoiceOverRunning()) {
        [self.verificationField becomeFirstResponder];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)createInstructionLabel
{
    self.instructionLabel = [UILabel new];
    self.instructionLabel.font = UIFont.largeThinFont;
    self.instructionLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.instructionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"registration.verify_phone_number.instructions", nil), self.credential];
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.accessibilityTraits |= UIAccessibilityTraitHeader;

    [self.view addSubview:self.instructionLabel];
}

- (void)createResendLabel
{
    self.resendLabel = [UILabel new];
    self.resendLabel.backgroundColor = [UIColor clearColor];
    self.resendLabel.font = UIFont.smallLightFont;
    self.resendLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.resendLabel.numberOfLines = 0;
    [self.view addSubview:self.resendLabel];
}

- (void)createResendButton
{
    self.resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resendButton.titleLabel.font = UIFont.smallLightFont;
    [self.resendButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
    [self.resendButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:ColorSchemeVariantDark] forState:UIControlStateHighlighted];
    [self.resendButton setTitle:[NSLocalizedString(@"registration.verify_phone_number.resend", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];

    [self.resendButton addTarget:self action:@selector(requestCode) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.resendButton];
}

- (void)createVerificationField
{
    self.verificationField = [[RegistrationTextField alloc] initForAutoLayout];
    self.verificationField.leftAccessoryView = RegistrationTextFieldLeftAccessoryViewNone;
    self.verificationField.textAlignment = NSTextAlignmentCenter;
    self.verificationField.accessibilityIdentifier = @"verificationField";
    self.verificationField.keyboardType = UIKeyboardTypeNumberPad;
    self.verificationField.delegate = self;
    [self.verificationField.confirmButton addTarget:self action:@selector(verifyCode) forControlEvents:UIControlEventTouchUpInside];
    self.verificationField.confirmButton.accessibilityLabel = NSLocalizedString(@"registration.phone.verify.label", @"");
    self.verificationField.accessibilityLabel = NSLocalizedString(@"registration.phone.verify_field.label", @"");

    [self.view addSubview:self.verificationField];
}

- (void)configureConstraints
{
    CGFloat inset = 28.0;
    [self.instructionLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
    [self.instructionLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];

    [self.verificationField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.instructionLabel withOffset:24];
    [self.verificationField autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
    [self.verificationField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
    [self.verificationField autoSetDimension:ALDimensionHeight toSize:40];

    [self.resendButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.verificationField withOffset:24];
    [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
    [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
    [[self.resendButton.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor constant:-24] setActive:YES];


    [self.resendLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.verificationField withOffset:24];
    [self.resendLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
    [self.resendLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
    [[self.resendLabel.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor constant:-24] setActive:YES];
}

- (void)updateResendArea
{
    NSTimeInterval timeSinceLastResend = [self.lastSentDate timeIntervalSinceNow];
    
    if (fabs(timeSinceLastResend) > VerificationCodeResendInterval) {
        self.resendLabel.hidden = YES;
        self.resendButton.hidden = NO;
    }
    else {
        self.resendLabel.hidden = NO;
        self.resendButton.hidden = YES;

        self.resendLabel.text = [[NSString stringWithFormat:NSLocalizedString(@"registration.verify_phone_number.resend_placeholder", @""), VerificationCodeResendInterval - fabs(timeSinceLastResend)] uppercaseString];
        
        self.timer = [ZMTimer timerWithTarget:self operationQueue:[NSOperationQueue mainQueue]];
        [self.timer fireAfterTimeInterval:1.0f];
    }
}

- (NSString *)verificationCode
{
    return self.verificationField.text ?: @"";
}

- (void)executeErrorFeedbackAction:(AuthenticationErrorFeedbackAction)feedbackAction
{
    self.verificationField.text = @"";
}

#pragma mark - Actions

- (void)verifyCode
{
    [self.authenticationCoordinator continueFlowWithVerificationCode:self.verificationCode];
}

- (void)requestCode
{
    // Reset the code field
    self.verificationField.text = @"";
    self.verificationField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;

    [self.authenticationCoordinator resendVerificationCode];
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
        self.verificationField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
    } else {
        self.verificationField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
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
        self.verificationField.text = verficationCode;
        self.verificationField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
        [self verifyCode];
    }
}

#pragma mark - ZMTimerClient

- (void)timerDidFire:(ZMTimer *)timer
{
    [self updateResendArea];
}

@end
