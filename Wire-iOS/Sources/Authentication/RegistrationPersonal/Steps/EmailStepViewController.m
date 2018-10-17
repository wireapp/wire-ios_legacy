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


#import "EmailStepViewController.h"

#import "IconButton.h"
#import "EmailFormViewController.h"
#import "UIImage+ZetaIconsNeue.h"
#import <WireExtensionComponents/ProgressSpinner.h>
#import "RegistrationTextField.h"
#import "WireSyncEngine+iOS.h"
#import "CheckmarkViewController.h"

#import "Wire-Swift.h"

@implementation EmailStepViewControllerInput

@end


@interface EmailStepViewController ()

@property (nonatomic) EmailFormViewController *emailFormViewController;

@end


@implementation EmailStepViewController

@synthesize authenticationCoordinator;

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self createEmailFormViewController];
    [self createInitialConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self takeFirstResponder];
}

- (void)takeFirstResponder
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    [self.emailFormViewController.nameField becomeFirstResponder];
}

- (void)createEmailFormViewController
{
    self.emailFormViewController = [[EmailFormViewController alloc] initWithNameFieldEnabled:YES];
    self.emailFormViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emailFormViewController.passwordField.confirmButton addTarget:self action:@selector(verifyFieldsAndContinue) forControlEvents:UIControlEventTouchUpInside];
    [self addChildViewController:self.emailFormViewController];
    [self.view addSubview:self.emailFormViewController.view];
    [self.emailFormViewController didMoveToParentViewController:self];
}

- (void)createInitialConstraints
{
    self.emailFormViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    NSArray<NSLayoutConstraint *> *constraints =
    @[
      [self.emailFormViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28],
      [self.emailFormViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:32],
      [self.emailFormViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28],
      [self.emailFormViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-10],
      ];

    [NSLayoutConstraint activateConstraints:constraints];
}

-(void)reset
{
    [self.emailFormViewController resetTextFields];
}

#pragma mark - Actions

- (void)verifyFieldsAndContinue
{    
    if ([self.emailFormViewController validateAllFields]) {
        EmailStepViewControllerInput *input = [EmailStepViewControllerInput new];
        input.name = self.emailFormViewController.nameField.text;
        input.emailAddress = self.emailFormViewController.emailField.text;
        input.password = self.emailFormViewController.passwordField.text;
        [self.delegate emailStepViewControllerDidFinishWithInput:input];
    }
}

- (void)executeErrorFeedbackAction:(AuthenticationErrorFeedbackAction)feedbackAction
{
    if (feedbackAction == AuthenticationErrorFeedbackActionClearInputFields) {
        [self reset];
    } else if (feedbackAction == AuthenticationErrorFeedbackActionShowGuidanceDot) {
        self.emailFormViewController.nameField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewGuidanceDot;
        self.emailFormViewController.emailField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewGuidanceDot;
        self.emailFormViewController.passwordField.rightAccessoryView = RegistrationTextFieldRightAccessoryViewGuidanceDot;
    }
}

@end
