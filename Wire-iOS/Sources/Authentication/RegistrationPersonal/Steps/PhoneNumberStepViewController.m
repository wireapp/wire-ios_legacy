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

@end

@implementation PhoneNumberStepViewController

@synthesize authenticationCoordinator;

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.view.opaque = NO;
    
    [self createHeroLabel];
    [self createPhoneNumberViewController];
    
    [self configureConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self takeFirstResponder];
}

- (void)createHeroLabel
{
    self.heroLabel = [UILabel new];
    self.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.heroLabel.numberOfLines = 0;
    
    [self.view addSubview:self.heroLabel];
}

- (void)createPhoneNumberViewController
{
    self.phoneNumberViewController = [PhoneNumberViewController new];
    [self.phoneNumberViewController willMoveToParentViewController:self];
    [self.view addSubview:self.phoneNumberViewController.view];
    [self addChildViewController:self.phoneNumberViewController];
    
    self.phoneNumberViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.phoneNumberViewController.phoneNumberField.confirmButton addTarget:self action:@selector(validatePhoneNumberAndContinue) forControlEvents:UIControlEventTouchUpInside];
    
    self.phoneNumberViewController.phoneNumber = self.phoneNumber;
}

- (void)configureConstraints
{
    self.heroLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.phoneNumberViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    NSLayoutConstraint *heroTop = [self.heroLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.topAnchor constant:75];
    heroTop.priority = UILayoutPriorityDefaultLow;

    NSArray<NSLayoutConstraint *> *constraints =
    @[
      // heroLabel
      [self.heroLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28],
      heroTop,
      [self.heroLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28],

      // phoneNumberViewController
      [self.phoneNumberViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28],
      [self.phoneNumberViewController.view.topAnchor constraintEqualToAnchor:self.heroLabel.bottomAnchor constant:24],
      [self.phoneNumberViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28],
      [self.phoneNumberViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-51],
      ];

    [NSLayoutConstraint activateConstraints:constraints];
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

- (void)validatePhoneNumberAndContinue
{
    self.phoneNumber = [NSString phoneNumberStringWithE164:self.phoneNumberViewController.country.e164 number:self.phoneNumberViewController.phoneNumberField.text];
    [self.delegate phoneNumberStepViewControllerDidPickPhoneNumber:self.phoneNumber];
}

- (void)executeErrorFeedbackAction:(AuthenticationErrorFeedbackAction)feedbackAction
{
    if (feedbackAction == AuthenticationErrorFeedbackActionShowGuidanceDot) {
        self.phoneNumberViewController.phoneNumberField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewGuidanceDot;
    } else if (feedbackAction == AuthenticationErrorFeedbackActionClearInputFields) {
        self.phoneNumberViewController.phoneNumberField.text = @"";
    }
}

@end
