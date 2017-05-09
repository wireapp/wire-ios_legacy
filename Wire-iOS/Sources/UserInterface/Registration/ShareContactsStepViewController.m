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


#import "ShareContactsStepViewController.h"

#import <PureLayout/PureLayout.h>

#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"
#import "Analytics+iOS.h"

#import "RegistrationFormController.h"
#import "ShareContactsViewController.h"
#import "Wire-Swift.h"

@interface ShareContactsStepViewController () <FormStepDelegate>

@property (nonatomic) UIButton *notNowButton;
@property (nonatomic) ShareContactsViewController *shareContactsViewController;
@property (nonatomic) RegistrationFormController *shareContactsViewControllerContainer;

@end

@implementation ShareContactsStepViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.opaque = NO;
    
    [self createShareContactsViewController];
    [self createNotNowButton];
    [self createConstraints];
}

- (void)createNotNowButton
{
    self.notNowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.notNowButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    [self.notNowButton setTitleColor:[UIColor colorWithMagicIdentifier:@"style.color.static_foreground.faded"] forState:UIControlStateNormal];
    [self.notNowButton setTitleColor:[[UIColor colorWithMagicIdentifier:@"style.color.static_foreground.faded"] colorWithAlphaComponent:0.2] forState:UIControlStateHighlighted];
    [self.notNowButton setTitle:[NSLocalizedString(@"registration.share_contacts.skip_button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    [self.notNowButton addTarget:self action:@selector(shareContactsLater:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.shareContactsViewControllerContainer.view addSubview:self.notNowButton];
}

- (void)createShareContactsViewController
{
    self.shareContactsViewController = [[ShareContactsViewController alloc] init];
    self.shareContactsViewController.uploadAddressBookImmediately = YES;
    self.shareContactsViewController.formStepDelegate = self;
    self.shareContactsViewController.backgroundBlurDisabled = YES;
    self.shareContactsViewController.notNowButtonHidden = YES;
    self.shareContactsViewController.monochromeStyle = YES;
    self.shareContactsViewController.analyticsTracker = self.analyticsTracker;
    self.shareContactsViewControllerContainer = self.shareContactsViewController.registrationFormViewController;
    
    [self addChildViewController:self.shareContactsViewControllerContainer];
    [self.view addSubview:self.shareContactsViewControllerContainer.view];
    [self.shareContactsViewControllerContainer didMoveToParentViewController:self];
}

- (void)createConstraints
{
    [self.notNowButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:32];
    [self.notNowButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
    [self.notNowButton autoSetDimension:ALDimensionHeight toSize:28];
    
    [self.shareContactsViewControllerContainer.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

#pragma mark - Actions

- (IBAction)shareContactsLater:(id)sender
{
    // We use a ShareContactsViewController but our own `later` button,
    // that's why we need to track the tap manually here.
    if (!self.shareContactsViewController.showingAddressBookAccessDeniedViewController) {
        [self.analyticsTracker tagAddressBookPreflightPermissions:NO];
        [AddressBookHelper sharedHelper].addressBookSearchWasPostponed = YES;
    }
    
    [self.formStepDelegate didSkipFormStep:self];
}

#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    [self.formStepDelegate didCompleteFormStep:self];
}

- (void)didSkipFormStep:(UIViewController *)viewController
{
    [self.formStepDelegate didSkipFormStep:self];
}

@end
