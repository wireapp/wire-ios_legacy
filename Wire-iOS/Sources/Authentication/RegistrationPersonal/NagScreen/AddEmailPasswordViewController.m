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

#import "AddEmailPasswordViewController.h"

#import <WireExtensionComponents/UIViewController+LoadingView.h>

#import "AddEmailStepViewController.h"
#import "VerificationCodeStepViewController.h"
#import "RegistrationFormController.h"
#import "PopTransition.h"
#import "PushTransition.h"
#import "NavigationController.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
#import "UIImage+ZetaIconsNeue.h"
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface AddEmailPasswordViewController () <AddEmailStepViewControllerDelegate>

@property (nonatomic) IconButton *closeButton;
@property (nonatomic) AddEmailStepViewController *addEmailStepViewController;

@end


@implementation AddEmailPasswordViewController

@synthesize authenticationCoordinator;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createEmailStepController];
    [self createCloseButton];

    if (self.canSkipStep) {
        self.closeButton.hidden = NO;
    }

    [self configureConstraints];
}

#pragma mark - Interface Configuration

- (void)createEmailStepController
{
    self.addEmailStepViewController = [[AddEmailStepViewController alloc] init];
    self.addEmailStepViewController.delegate = self;
    self.addEmailStepViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:self.addEmailStepViewController];
    [self.view addSubview:self.addEmailStepViewController.view];
    [self.addEmailStepViewController didMoveToParentViewController:self];
}

- (void)createCloseButton
{
    self.closeButton = [[IconButton alloc] init];
    [self.closeButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    [self.closeButton setIconColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.closeButton.hidden = YES;
    self.closeButton.adjustsImageWhenHighlighted = YES;
    [self.closeButton addTarget:self action:@selector(skip) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
}

- (void)configureConstraints
{
    NSArray<NSLayoutConstraint *> *constraints =
    @[
      // Add e-mail step
      [self.addEmailStepViewController.view.leadingAnchor constraintEqualToAnchor:self.view.safeLeadingAnchor],
      [self.addEmailStepViewController.view.topAnchor constraintEqualToAnchor:self.safeTopAnchor],
      [self.addEmailStepViewController.view.trailingAnchor constraintEqualToAnchor:self.view.safeTrailingAnchor],
      [self.addEmailStepViewController.view.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor],

      // Close button
      [self.closeButton.topAnchor constraintEqualToAnchor:self.safeTopAnchor constant:32],
      [self.closeButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28]
      ];

    [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark - Actions

- (void)setCanSkipStep:(BOOL)canSkipStep
{
    _canSkipStep = canSkipStep;
    self.closeButton.hidden = !canSkipStep;
}

- (void)skip
{
    // TODO: Dismiss the view controller
}

- (void)addEmailStepDidFinishWithEmailCredentials:(ZMEmailCredentials *)credentials
{
    [self.authenticationCoordinator setEmailCredentialsForCurrentUser:credentials];
}

- (void)executeErrorFeedbackAction:(AuthenticationErrorFeedbackAction)feedbackAction
{
    if (feedbackAction == AuthenticationErrorFeedbackActionClearInputFields) {
        [self.addEmailStepViewController clearFields];
    }
}

@end
