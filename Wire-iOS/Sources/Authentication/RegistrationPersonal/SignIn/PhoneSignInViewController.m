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
@import WireSyncEngine;

#import "PhoneSignInViewController.h"

#import "PhoneNumberStepViewController.h"
#import "RegistrationFormController.h"
#import "Wire-Swift.h"

@interface PhoneSignInViewController () <PhoneNumberStepViewControllerDelegate>

@property (nonatomic) PhoneNumberStepViewController *phoneNumberStepViewController;
@property (nonatomic, copy) NSString *phoneNumber;

@end


@implementation PhoneSignInViewController

@synthesize authenticationCoordinator;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createPhoneNumberStepViewController];
    
    self.view.opaque = NO;
    self.title = NSLocalizedString(@"registration.title", @"");
}

#pragma mark - Interface Configuration

- (void)createPhoneNumberStepViewController
{
    PhoneNumberStepViewController *phoneNumberStepViewController = [[PhoneNumberStepViewController alloc] init];
    phoneNumberStepViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    phoneNumberStepViewController.delegate = self;

    self.phoneNumberStepViewController = phoneNumberStepViewController;
    self.phoneNumberStepViewController.phoneNumberViewController.phoneNumberField.confirmButton.accessibilityLabel = NSLocalizedString(@"signin.confirm", @"");
    
    [self addChildViewController:phoneNumberStepViewController];
    [self.view addSubview:phoneNumberStepViewController.view];
    [phoneNumberStepViewController didMoveToParentViewController:self];
    [phoneNumberStepViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (void)takeFirstResponder
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    [self.phoneNumberStepViewController takeFirstResponder];
}

#pragma mark - PhoneNumberStepViewControllerDelegate

- (void)phoneNumberStepViewControllerDidPickPhoneNumber:(NSString *)phoneNumber
{
    [self.authenticationCoordinator startLoginWithPhoneNumber:phoneNumber];
}

@end
