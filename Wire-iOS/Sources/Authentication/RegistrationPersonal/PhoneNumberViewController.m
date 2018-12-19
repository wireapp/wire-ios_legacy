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
#import "Analytics.h"

@import PureLayout;

#import "RegistrationTextField.h"
#import "CountryCodeTableViewController.h"
#import "Country.h"
#import "Constants.h"
#import "UIImage+ZetaIconsNeue.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"



static CGFloat SelectCountryButtonHeight = 28;
static CGFloat PhoneNumberFieldTopMargin = 16;



@interface PhoneNumberViewController () <CountryCodeTableViewControllerDelegate>

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.view layoutIfNeeded];
}

- (void)createSelectCountryButton
{
    self.selectCountryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.selectCountryButton.contentHorizontalAlignment = [UIApplication isLeftToRightLayout] ? UIControlContentHorizontalAlignmentLeft : UIControlContentHorizontalAlignmentRight;
    
    self.selectCountryButton.titleLabel.font = UIFont.normalLightFont;
    [self.selectCountryButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
    [self.selectCountryButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorButtonFaded variant:ColorSchemeVariantDark] forState:UIControlStateHighlighted];
    
    ZetaIconType iconType = [UIApplication isLeftToRightLayout] ? ZetaIconTypeChevronRight : ZetaIconTypeChevronLeft;
    UIImage *icon = [UIImage imageForIcon:iconType iconSize:ZetaIconSizeSmall color:UIColor.whiteColor];
    self.selectCountryButtonIcon = [[UIImageView alloc] initWithImage:icon];
    self.selectCountryButtonIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectCountryButton addSubview:self.selectCountryButtonIcon];
    
    self.selectCountryButton.accessibilityIdentifier = @"CountryPickerButton";
    
    [self.selectCountryButton addTarget:self action:@selector(selectCountry:) forControlEvents:UIControlEventTouchUpInside];

    self.selectCountryButton.accessibilityLabel = NSLocalizedString(@"registration.phone_country", @"");
    self.selectCountryButton.accessibilityHint = NSLocalizedString(@"registration.phone_country.hint", @"");
    [self.view addSubview:self.selectCountryButton];
}

- (void)createPhoneNumberField
{
    self.phoneNumberField = [[RegistrationTextField alloc] initForAutoLayout];
    self.phoneNumberField.leftAccessoryView = RegistrationTextFieldLeftAccessoryViewCountryCode;

    self.phoneNumberField.isPhoneNumberMode = YES;

    self.phoneNumberField.placeholder = NSLocalizedString(@"registration.enter_phone_number.placeholder", nil);
    self.phoneNumberField.accessibilityLabel = NSLocalizedString(@"registration.enter_phone_number.placeholder", nil);
    self.phoneNumberField.delegate = self;
    
    [self.phoneNumberField.countryCodeButton addTarget:self action:@selector(selectCountry:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.phoneNumberField];
    
    self.phoneNumberField.accessibilityIdentifier = @"PhoneNumberField";
}

- (void)selectInitialCountry
{
    self.country = [Country defaultCountry];
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
    self.selectCountryButton.accessibilityValue = country.displayName;
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
    self.phoneNumberField.textColor = editable ? [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] : [UIColor wr_colorFromColorScheme:ColorSchemeColorButtonFaded variant:ColorSchemeVariantDark];
}

-(void)setPhoneNumber:(NSString *)phoneNumber
{
    _phoneNumber = [phoneNumber copy];
    
    if(phoneNumber == nil) {
        [self selectInitialCountry];
        self.phoneNumberField.text = nil;
    } else {
        [self insertWithPhoneNumber:phoneNumber];
    }
}


#pragma mark - Field Validation


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return self.editable;
}

#pragma mark - Actions

- (IBAction)selectCountry:(id)sender
{
    CountryCodeTableViewController *countryCodeTableViewController = [[CountryCodeTableViewController alloc] init];
    countryCodeTableViewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:countryCodeTableViewController];
    
    if (IS_IPAD_FULLSCREEN) {
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
