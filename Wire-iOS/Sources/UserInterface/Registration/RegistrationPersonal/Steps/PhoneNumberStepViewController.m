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


#import "PhoneNumberStepViewController.h"

@import PureLayout;

#import "RegistrationTextField.h"
#import "UIImage+ZetaIconsNeue.h"
#import "Constants.h"
#import "GuidanceLabel.h"
#import "Country.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
#import "AppDelegate.h"
#import "Wire-Swift.h"
@import WireExtensionComponents;

@interface PhoneNumberStepViewController ()

@property (nonatomic, copy, readwrite) NSString *phoneNumber;
@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic, readonly) BOOL phoneNumberIsEditable;

@end

@implementation PhoneNumberStepViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _phoneNumberIsEditable = YES;
    }
    
    return self;
}

- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber isEditable:(BOOL)isEditable
{
    self = [super init];
    
    if (self) {
        _phoneNumberIsEditable = isEditable;
        self.phoneNumber = phoneNumber;
    }
    
    return self;
}

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super init];

    if (self) {
        _phoneNumberIsEditable = YES;
        self.unregisteredUser = unregisteredUser;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.view.opaque = NO;
    self.title = NSLocalizedString(@"registration.enter_phone_number.title", nil);
    
    [self createHeroLabel];
    [self createPhoneNumberViewController];
    
    [self updateViewConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self takeFirstResponder];
}

- (void)createHeroLabel
{
    self.heroLabel = [[UILabel alloc] initForAutoLayout];
    self.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.heroLabel.numberOfLines = 0;
    
    [self.view addSubview:self.heroLabel];
}

- (void)createPhoneNumberViewController
{
    self.phoneNumberViewController = [[PhoneNumberViewController alloc] init];
    [self.phoneNumberViewController willMoveToParentViewController:self];
    [self.view addSubview:self.phoneNumberViewController.view];
    [self addChildViewController:self.phoneNumberViewController];
    
    self.phoneNumberViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.phoneNumberViewController.phoneNumberField.confirmButton addTarget:self action:@selector(validatePhoneNumber:) forControlEvents:UIControlEventTouchUpInside];
    
    self.phoneNumberViewController.phoneNumber = self.phoneNumber;
    
    self.phoneNumberViewController.editable = self.phoneNumberIsEditable;
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{            
            [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:75 relation:NSLayoutRelationGreaterThanOrEqual];
        }];
        [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:28];
        [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:28];
        
        [self.phoneNumberViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.heroLabel withOffset:24];
        [self.phoneNumberViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:28];
        [self.phoneNumberViewController.view autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:28];
        [self.phoneNumberViewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:51];
    }
}

- (void)takeFirstResponder
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    [self.phoneNumberViewController.phoneNumberField becomeFirstResponder];
}

-(void)reset
{
    self.phoneNumberViewController.phoneNumber = nil;
}

#pragma mark - Actions

- (IBAction)validatePhoneNumber:(id)sender
{
    if (self.phoneNumberIsEditable) {
        self.phoneNumber = [NSString phoneNumberStringWithE164:self.phoneNumberViewController.country.e164 number:self.phoneNumberViewController.phoneNumberField.text];
    }
    self.unregisteredUser.phoneNumber = self.phoneNumber;

    [self.formStepDelegate didCompleteFormStep:self];
}

@end
