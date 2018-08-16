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


#import "RegistrationPhoneFlowViewController.h"

@import PureLayout;

#import "NavigationController.h"
#import "PhoneNumberStepViewController.h"
#import "PhoneVerificationStepViewController.h"
#import "PopTransition.h"
#import "PushTransition.h"
#import "RegistrationFormController.h"
#import "NavigationController.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
#import <WireExtensionComponents/UIViewController+LoadingView.h>
#import "CheckmarkViewController.h"
#import "TermsOfUseStepViewController.h"
#import "NameStepViewController.h"
#import "ProfilePictureStepViewController.h"
#import "AppDelegate.h"
#import "AddEmailPasswordViewController.h"
#import "Wire-Swift.h"


@import WireExtensionComponents;
@import WireSyncEngine;

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface RegistrationPhoneFlowViewController () <PhoneNumberStepViewControllerDelegate>

@property (nonatomic) PhoneNumberStepViewController *phoneNumberStepViewController;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) BOOL marketingConsent;

@end

@implementation RegistrationPhoneFlowViewController

@synthesize authenticationCoordinator;

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.title = NSLocalizedString(@"registration.title", @"");
        self.unregisteredUser = unregisteredUser;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createNavigationController];

    self.phoneNumberStepViewController.phoneNumberViewController.phoneNumberField.confirmButton.accessibilityLabel = NSLocalizedString(@"registration.confirm", @"");
    self.view.opaque = NO;
}

- (void)takeFirstResponder
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    [self.phoneNumberStepViewController takeFirstResponder];
}

- (void)createNavigationController
{
    PhoneNumberStepViewController *phoneNumberStepViewController = [[PhoneNumberStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
    phoneNumberStepViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    phoneNumberStepViewController.delegate = self;

    [self addChildViewController:phoneNumberStepViewController];
    [self.view addSubview:phoneNumberStepViewController.view];
    [phoneNumberStepViewController didMoveToParentViewController:self];
    [phoneNumberStepViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    self.phoneNumberStepViewController = phoneNumberStepViewController;
}

#pragma mark - PhoneNumberStepViewControllerDelegate

- (void)phoneNumberStepDidPickPhoneNumber:(NSString *)phoneNumber
{
    [self.authenticationCoordinator startPhoneNumberValidationWithPhoneNumber:phoneNumber];
}

@end
