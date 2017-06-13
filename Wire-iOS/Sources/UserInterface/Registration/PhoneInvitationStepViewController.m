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
#import "PhoneInvitationStepViewController.h"

@import PureLayout;
@import WireExtensionComponents;

#import "RegistrationTextField.h"
#import "Button.h"
#import "Constants.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIFont+MagicAccess.h"
#import "WireSyncEngine+iOS.h"



@interface PhoneInvitationStepViewController () <RegistrationTextFieldDelegate>

@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) RegistrationTextField *phoneNumberField;
@property (nonatomic) Button *continueButton;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;

@end

@implementation PhoneInvitationStepViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _unregisteredUser = unregisteredUser;
        self.title = NSLocalizedString(@"registration.phone_invitation.title", nil);
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createHeroLabel];
    [self createPhoneNumberField];
    
    [self createInitialConstraints];
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
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"registration.phone_invitation.hero.title", nil), self.unregisteredUser.name];
    NSString *paragraph = NSLocalizedString(@"registration.phone_invitation.hero.paragraph", nil);
    
    NSString * text = [@[title, paragraph] componentsJoinedByString:@"\u2029"];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName : paragraphStyle }];
    [attributedText addAttributes:@{ NSForegroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark],
                                     NSFontAttributeName : [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_thin"] }
                            range:[text rangeOfString:paragraph]];
    
    return attributedText;
}

- (void)createPhoneNumberField
{
    self.phoneNumberField = [[RegistrationTextField alloc] initForAutoLayout];
    
    self.phoneNumberField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.phoneNumberField.minimumFontSize = 15.0f;
    self.phoneNumberField.accessibilityIdentifier = @"PhoneNumberField";
    self.phoneNumberField.text = self.unregisteredUser.phoneNumber;
    self.phoneNumberField.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextPlaceholder variant:ColorSchemeVariantDark];
    self.phoneNumberField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
    [self.phoneNumberField.confirmButton addTarget:self action:@selector(confirmInput) forControlEvents:UIControlEventTouchUpInside];
    self.phoneNumberField.delegate = self;
    
    [self.view addSubview:self.phoneNumberField];
}

- (void)createInitialConstraints
{
    UIEdgeInsets marginInsets = UIEdgeInsetsMake(28, 28, 28, 28);
    
    [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:marginInsets.left];
    [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:marginInsets.right];
    
    [self.phoneNumberField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.heroLabel withOffset:24];
    [self.phoneNumberField autoPinEdgesToSuperviewEdgesWithInsets:marginInsets excludingEdge:ALEdgeTop];
    [self.phoneNumberField autoSetDimension:ALDimensionHeight toSize:40];
}

- (void)confirmInput
{
    [self.formStepDelegate didCompleteFormStep:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return NO;
}

@end
