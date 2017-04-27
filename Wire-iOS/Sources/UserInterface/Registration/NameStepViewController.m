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

#import <PureLayout/PureLayout.h>

#import "RegistrationTextField.h"
#import "WAZUIMagicIOS.h"
#import "Constants.h"

#import "WireSyncEngine+iOS.h"

@import WireExtensionComponents;


@interface NameStepViewController () <RegistrationTextFieldDelegate>

@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) RegistrationTextField *nameField;
@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;

@end



@implementation NameStepViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.unregisteredUser = unregisteredUser;
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
    
    [self updateViewConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.nameField becomeFirstResponder];
}

- (void)createHeroLabel
{
    self.heroLabel = [[UILabel alloc] initForAutoLayout];
    self.heroLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_light"];
    self.heroLabel.textColor = [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"];
    self.heroLabel.numberOfLines = 0;
    self.heroLabel.text = NSLocalizedString(@"registration.enter_name.hero", nil);
    
    [self.view addSubview:self.heroLabel];
}

- (void)createNameField
{
    self.nameField = [[RegistrationTextField alloc] initForAutoLayout];
    self.nameField.keyboardType = UIKeyboardTypeDefault;
    self.nameField.delegate = self;
    
    [self.nameField.confirmButton addTarget:self action:@selector(confirmName:) forControlEvents:UIControlEventTouchUpInside];
    self.nameField.placeholder = NSLocalizedString(@"registration.enter_name.placeholder", nil);
        
    [self.view addSubview:self.nameField];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        
        [self.nameField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.heroLabel withOffset:24];
        [self.nameField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 28, 28, 28) excludingEdge:ALEdgeTop];
        [self.nameField autoSetDimension:ALDimensionHeight toSize:40];
    }
}

#pragma mark - Actions

- (IBAction)confirmName:(id)sender
{
    self.unregisteredUser.name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.formStepDelegate didCompleteFormStep:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSError *error = nil;
    BOOL valid = [self.unregisteredUser validateValue:&newString forKey:@"name" error:&error];
    
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
