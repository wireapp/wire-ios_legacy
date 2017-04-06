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


#import "PhoneNumberViewController.h"
#import "Analytics+iOS.h"

#import <PureLayout/PureLayout.h>

#import "RegistrationTextField.h"
#import "CountryCodeTableViewController.h"
#import "Country.h"
#import "Constants.h"
#import "WAZUIMagicIOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

#import "AnalyticsTracker+Navigation.h"



static CGFloat SelectCountryButtonHeight = 28;
static CGFloat PhoneNumberFieldTopMargin = 16;



@interface PhoneNumberViewController () <CountryCodeTableViewControllerDelegate, RegistrationTextFieldDelegate>

@property (nonatomic, readwrite) Country *country;
@property (nonatomic, readwrite) UIButton *selectCountryButton;
@property (nonatomic) UIImageView *selectCountryButtonIcon;
@property (nonatomic, readwrite) RegistrationTextField *phoneNumberField;
@property (nonatomic) BOOL initialConstraintsCreated;

@property (nonatomic) NSLayoutConstraint *selectCountryButtonHeightConstraint;
@property (nonatomic) NSLayoutConstraint *phoneNumberFieldTopMarginConstraint;

@end



@implementation PhoneNumberViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _editable = YES;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createSelectCountryButton];
    [self createPhoneNumberField];
    [self updateViewConstraints];
    [self selectInitialCountry];
}

- (void)createSelectCountryButton
{
    self.selectCountryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.selectCountryButton.contentHorizontalAlignment = [UIApplication isLeftToRightLayout] ? UIControlContentHorizontalAlignmentLeft : UIControlContentHorizontalAlignmentRight;
    
    self.selectCountryButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
    [self.selectCountryButton setTitleColor:[UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"] forState:UIControlStateNormal];
    [self.selectCountryButton setTitleColor:[UIColor colorWithMagicIdentifier:@"style.color.static_foreground.faded"] forState:UIControlStateHighlighted];
    
    ZetaIconType iconType = [UIApplication isLeftToRightLayout] ? ZetaIconTypeChevronRight : ZetaIconTypeChevronLeft;
    UIImage *icon = [UIImage imageForIcon:iconType iconSize:ZetaIconSizeSmall color:UIColor.whiteColor];
    self.selectCountryButtonIcon = [[UIImageView alloc] initWithImage:icon];
    self.selectCountryButtonIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectCountryButton addSubview:self.selectCountryButtonIcon];
    
    self.selectCountryButton.accessibilityIdentifier = @"CountryPickerButton";
    
    [self.selectCountryButton addTarget:self action:@selector(selectCountry:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.selectCountryButton];
}

- (void)createPhoneNumberField
{
    self.phoneNumberField = [[RegistrationTextField alloc] initForAutoLayout];
    self.phoneNumberField.leftAccessoryView = RegistrationTextFieldLeftAccessoryViewCountryCode;
    self.phoneNumberField.keyboardType = UIKeyboardTypeNumberPad;
    self.phoneNumberField.placeholder = NSLocalizedString(@"registration.enter_phone_number.placeholder", nil);
    self.phoneNumberField.delegate = self;
    
    [self.phoneNumberField.countryCodeButton addTarget:self action:@selector(selectCountry:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.phoneNumberField];
    
    self.phoneNumberField.accessibilityIdentifier = @"PhoneNumberField";
}

- (void)selectInitialCountry
{
    Country *initialCountry = nil;

#if WIRESTAN
    NSString *backendEnvironment = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZMBackendEnvironmentType"];
    if ([backendEnvironment isEqualToString:@"edge"]) {
            initialCountry = [Country countryWirestan];
    }
    
#endif
    if (! initialCountry) {
        initialCountry = [Country countryFromDevice];
    }

    self.country = initialCountry;
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        
        self.initialConstraintsCreated = YES;
        
        [self.selectCountryButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0];
        [self.selectCountryButtonIcon autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.selectCountryButton.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.selectCountryButtonIcon withOffset:0 relation:NSLayoutRelationLessThanOrEqual];
        
        [self.selectCountryButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.selectCountryButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        
        [self.selectCountryButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];

        self.selectCountryButtonHeightConstraint = [self.selectCountryButton autoSetDimension:ALDimensionHeight toSize:SelectCountryButtonHeight];
        
        self.phoneNumberFieldTopMarginConstraint = [self.phoneNumberField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.selectCountryButton withOffset:PhoneNumberFieldTopMargin];
        [self.phoneNumberField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0) excludingEdge:ALEdgeTop];
        [self.phoneNumberField autoSetDimension:ALDimensionHeight toSize:40];
    }
}

- (void)updateRightAccessoryForPhoneNumber:(NSString *)phoneNumber
{
    NSError *error = nil;
    BOOL valid = [ZMUser validatePhoneNumber:&phoneNumber error:&error];
    
    if (valid) {
        self.phoneNumberField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
    } else {
        self.phoneNumberField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    }
}

- (void)setCountry:(Country *)country
{
    _country = country;
    
    self.phoneNumberField.countryCode = country.e164.unsignedIntegerValue;
    [self.selectCountryButton setTitle:country.displayName forState:UIControlStateNormal];
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    self.selectCountryButton.hidden = ! editable;
    self.selectCountryButtonIcon.hidden = ! editable;
    self.selectCountryButtonHeightConstraint.constant = editable ? SelectCountryButtonHeight : 0;
    self.phoneNumberFieldTopMarginConstraint.constant = editable ? PhoneNumberFieldTopMargin : 0;
    self.phoneNumberField.textColor = editable ? [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"] : [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.faded"];
}

#pragma mark - Field Validation


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return self.editable;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString *phoneNumber = [NSString phoneNumberStringWithE164:self.country.e164 number:newString];
    
    NSError *error = nil;
    [ZMUser validatePhoneNumber:&phoneNumber error:&error];
    
    if (error.code == ZMObjectValidationErrorCodeStringTooLong ||
        error.code == ZMObjectValidationErrorCodePhoneNumberContainsInvalidCharacters) {
        return NO;
    }
    
    [self updateRightAccessoryForPhoneNumber:phoneNumber];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldPasteCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *phoneNumber = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // Auto detect country for phone numbers beginning with "+"
    
    // When pastedString is copied from phone app (self phone number section), it contains right/left handling symbols: \u202A\u202B\u202C\u202D
    // @"\U0000202d+380 (00) 123 45 67\U0000202c"
    NSMutableCharacterSet *illegalCharacters = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [illegalCharacters formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    [illegalCharacters formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"+-()"]];
    [illegalCharacters invert];
    
    phoneNumber = [phoneNumber stringByTrimmingCharactersInSet:illegalCharacters];
    
    if ([[phoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] hasPrefix:@"+"]) {
        Country *country = [Country detectCountryForPhoneNumber:phoneNumber];
        if (country) {
            self.country = country;
        
            NSString *phoneNumberWithoutCountryCode = [phoneNumber stringByReplacingOccurrencesOfString:self.country.e164PrefixString
                                                                                             withString:@""];
            
            self.phoneNumberField.text = phoneNumberWithoutCountryCode;
            [self updateRightAccessoryForPhoneNumber:phoneNumber];
            return NO;
        }
    }
    
    // Just paste (if valid) for phone numbers not beginning with "+", or phones where country is not detected.
    phoneNumber = [NSString phoneNumberStringWithE164:self.country.e164 number:phoneNumber];
    if ([ZMUser validatePhoneNumber:&phoneNumber error:NULL]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Actions

- (IBAction)selectCountry:(id)sender
{
    CountryCodeTableViewController *countryCodeTableViewController = [[CountryCodeTableViewController alloc] init];
    countryCodeTableViewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:countryCodeTableViewController];
    
    if (IS_IPAD) {
        countryCodeTableViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self.phoneNumberField resignFirstResponder]; // NOTE workaround for rdar://22616683
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - CountryCodeTableViewControllerDelegate

- (void)countryCodeTableViewController:(UIViewController *)viewController didSelectCountry:(Country *)country
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
    self.country = country;
}

@end
