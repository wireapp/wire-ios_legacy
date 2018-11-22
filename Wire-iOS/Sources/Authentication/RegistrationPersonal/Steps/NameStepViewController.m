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


#import "NameStepViewController.h"

#import "RegistrationTextField.h"
#import "Constants.h"
#import "Wire-Swift.h"
#import "WireSyncEngine+iOS.h"

@import WireExtensionComponents;

@interface NameStepViewController () <UITextFieldDelegate>

@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) RegistrationTextField *nameField;

@end


@implementation NameStepViewController

@synthesize authenticationCoordinator;

- (instancetype)init
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.title = NSLocalizedString(@"registration.enter_name.title", nil);
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    
    [self createHeroLabel];
    [self createNameField];
    
    [self configureConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.nameField becomeFirstResponder];
}

- (void)createHeroLabel
{
    self.heroLabel = [UILabel new];
    self.heroLabel.font = UIFont.largeLightFont;
    self.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.heroLabel.numberOfLines = 0;
    self.heroLabel.text = NSLocalizedString(@"registration.enter_name.hero", nil);
    
    [self.view addSubview:self.heroLabel];
}

- (void)createNameField
{
    self.nameField = [RegistrationTextField new];
    self.nameField.keyboardType = UIKeyboardTypeDefault;
    self.nameField.delegate = self;
    
    [self.nameField.confirmButton addTarget:self action:@selector(confirmName:) forControlEvents:UIControlEventTouchUpInside];
    self.nameField.placeholder = NSLocalizedString(@"registration.enter_name.placeholder", nil);
        
    [self.view addSubview:self.nameField];
}

- (void)configureConstraints
{
    self.heroLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameField.translatesAutoresizingMaskIntoConstraints = NO;

    CGFloat inset = 28.0;

    NSArray<NSLayoutConstraint *> *constraints =
    @[
      // heroLabel
      [self.heroLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:inset],
      [self.heroLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-inset],

      // nameField
      [self.nameField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:inset],
      [self.nameField.topAnchor constraintEqualToAnchor:self.heroLabel.bottomAnchor constant:24],
      [self.nameField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-inset],
      [self.nameField.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor constant:-inset],
      [self.nameField.heightAnchor constraintEqualToConstant:40],
      ];

    [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark - Actions

- (void)confirmName:(id)sender
{
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.authenticationCoordinator setUserName:name];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSError *error = nil;
    BOOL valid = [ZMUser validateName:&newString error:&error];
    
    if (error.code == ZMObjectValidationErrorCodeStringTooLong) {
        return NO;
    }
    
    if (error.code == ZMObjectValidationErrorCodeStringTooShort) {
        self.nameField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewNone;
    } else if (valid) {
        self.nameField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewConfirmButton;
    }

    return YES;
}

@end
