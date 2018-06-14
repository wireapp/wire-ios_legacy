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

    if (!UIAccessibilityIsVoiceOverRunning()) {
        [self.phoneVerificationField becomeFirstResponder];
    }
}

- (void)createInstructionLabel
{
    self.instructionLabel = [[UILabel alloc] init];
    self.instructionLabel.font = UIFont.largeThinFont;
    self.instructionLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.instructionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"registration.verify_phone_number.instructions", nil), self.phoneNumber];
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.accessibilityTraits |= UIAccessibilityTraitHeader;

    [self.view addSubview:self.instructionLabel];
}

- (void)createResendLabel
{
    self.resendLabel = [[UILabel alloc] initForAutoLayout];
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

    [self.resendButton addTarget:self action:@selector(requestCode:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.resendButton];
}

- (void)createPhoneVerificationField
{
    self.phoneVerificationField = [[RegistrationTextField alloc] initForAutoLayout];
    self.phoneVerificationField.leftAccessoryView = RegistrationTextFieldLeftAccessoryViewNone;
    self.phoneVerificationField.textAlignment = NSTextAlignmentCenter;
    self.phoneVerificationField.accessibilityIdentifier = @"verificationField";
    self.phoneVerificationField.keyboardType = UIKeyboardTypeNumberPad;
    self.phoneVerificationField.delegate = self;
    [self.phoneVerificationField.confirmButton addTarget:self action:@selector(verifyCode:) forControlEvents:UIControlEventTouchUpInside];
    self.phoneVerificationField.confirmButton.accessibilityLabel = NSLocalizedString(@"registration.phone.verify.label", @"");
    self.phoneVerificationField.accessibilityLabel = NSLocalizedString(@"registration.phone.verify_field.label", @"");

    [self.view addSubview:self.phoneVerificationField];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        CGFloat inset = 28.0;
        [self.instructionLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
        [self.instructionLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
        
        [self.phoneVerificationField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.instructionLabel withOffset:24];
        [self.phoneVerificationField autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
        [self.phoneVerificationField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
        [self.phoneVerificationField autoSetDimension:ALDimensionHeight toSize:40];
        
        [self.resendButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.phoneVerificationField withOffset:24];
        [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
        [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
        [[self.resendButton.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor constant:-24] setActive:YES];
        
        
        [self.resendLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.phoneVerificationField withOffset:24];
        [self.resendLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
        [self.resendLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
        [[self.resendLabel.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor constant:-24] setActive:YES];
        
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
