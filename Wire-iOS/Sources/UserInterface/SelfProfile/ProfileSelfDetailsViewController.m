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


#import "ProfileSelfDetailsViewController.h"

#import <PureLayout/PureLayout.h>

#import "AddEmailPasswordViewController.h"
#import "AddPhoneNumberViewController.h"
#import "KeyboardAvoidingViewController.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"
#import "zmessaging+iOS.h"
#import "Wire-Swift.h"

#import "AnalyticsTracker+Navigation.h"



@interface ProfileSelfDetailsViewController () <FormStepDelegate>

@property (nonatomic) UILabel *verifiedUserDetailsLabel;
@property (nonatomic) UIButton *verifyUserDetailsButton;

@end



@implementation ProfileSelfDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createVerifiedUserDetailsLabel];
    [self createVerifyUserDetailsButton];
    [self createInitialConstraints];
    [self updateVerifiedUserDetails];
}

- (void)createVerifiedUserDetailsLabel
{
    self.verifiedUserDetailsLabel = [[UILabel alloc] initForAutoLayout];
    self.verifiedUserDetailsLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
    self.verifiedUserDetailsLabel.textColor = [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"];
    self.verifiedUserDetailsLabel.numberOfLines = 0;
    
    [self.view addSubview:self.verifiedUserDetailsLabel];
}

- (void)createVerifyUserDetailsButton
{
    self.verifyUserDetailsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.verifyUserDetailsButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.verifyUserDetailsButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    [self updateAccentColor:UIColor.accentColor animated:NO];
    
    [self.view addSubview:self.verifyUserDetailsButton];
}

- (void)updateAccentColor:(UIColor *)color
{
    [self updateAccentColor:color animated:YES];
}

- (void)updateAccentColor:(UIColor *)color animated:(BOOL)animated
{
    dispatch_block_t changes = ^{
        [self.verifyUserDetailsButton setTitleColor:color forState:UIControlStateNormal];
        [self.verifyUserDetailsButton setTitleColor:[color colorWithAlphaComponent:0.4] forState:UIControlStateHighlighted];
    };
    
    if (animated) {
        [UIView transitionWithView:self.verifyUserDetailsButton
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:changes
                        completion:nil];
    } else {
        changes();
    }
}

- (void)updateVerifiedUserDetails
{
    NSMutableArray *verifiedUserDetails = [NSMutableArray array];
    ZMUser *selfUser = [ZMUser selfUser];
    
    if (selfUser.phoneNumber.length > 0) {
        [verifiedUserDetails addObject:selfUser.phoneNumber];
    }
    
    if (selfUser.emailAddress.length > 0) {
        [verifiedUserDetails addObject:selfUser.emailAddress];
    }

    NSString *verifiedDetails = [verifiedUserDetails componentsJoinedByString:@"\n"];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.paragraphSpacing = 6;
    
    self.verifiedUserDetailsLabel.attributedText = [[NSAttributedString alloc] initWithString:verifiedDetails attributes:@{NSParagraphStyleAttributeName: paragraph}];
    
    
    if (selfUser.phoneNumber.length == 0) {
        [self.verifyUserDetailsButton setTitle:[NSLocalizedString(@"self.add_phone_number", nil) uppercaseStringWithCurrentLocale] forState:UIControlStateNormal];
        [self.verifyUserDetailsButton addTarget:self action:@selector(addPhoneNumber:) forControlEvents:UIControlEventTouchUpInside];
        self.verifyUserDetailsButton.hidden = NO;
    }
    else if (selfUser.emailAddress.length == 0) {
        [self.verifyUserDetailsButton setTitle:[NSLocalizedString(@"self.add_email_password", nil) uppercaseStringWithCurrentLocale] forState:UIControlStateNormal];
        [self.verifyUserDetailsButton addTarget:self action:@selector(addEmailAndPassword:) forControlEvents:UIControlEventTouchUpInside];
        self.verifyUserDetailsButton.hidden = NO;
    } else {
        self.verifyUserDetailsButton.hidden = YES;
    }
}

- (void)createInitialConstraints
{
    [self.verifiedUserDetailsLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.verifyUserDetailsButton autoSetDimension:ALDimensionHeight toSize:28];
    [self.verifyUserDetailsButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.verifiedUserDetailsLabel withOffset:7];
    [self.verifyUserDetailsButton autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.verifyUserDetailsButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
}

#pragma mark - Actions

- (IBAction)addPhoneNumber:(id)sender
{
    [self.delegate profileSelfDetailsViewControllerWillEditDetails];
    
    AddPhoneNumberViewController *addPhoneNumberViewController = [[AddPhoneNumberViewController alloc] init];
    addPhoneNumberViewController.skipButtonType = AddPhoneNumberViewControllerSkipButtonTypeClose;
    addPhoneNumberViewController.analyticsTracker = self.analyticsTracker;
    addPhoneNumberViewController.formStepDelegate = self;
    
    KeyboardAvoidingViewController *keyboardAvoidingViewController = [[KeyboardAvoidingViewController alloc] initWithViewController:addPhoneNumberViewController];
    keyboardAvoidingViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self presentViewController:keyboardAvoidingViewController animated:YES completion:nil];
}

- (IBAction)addEmailAndPassword:(id)sender
{
    [self.delegate profileSelfDetailsViewControllerWillEditDetails];
    
    AddEmailPasswordViewController *addEmailPasswordViewController = [[AddEmailPasswordViewController alloc] init];
    addEmailPasswordViewController.skipButtonType = AddEmailPasswordViewControllerSkipButtonTypeClose;
    addEmailPasswordViewController.analyticsTracker = self.analyticsTracker;
    addEmailPasswordViewController.formStepDelegate = self;
    
    KeyboardAvoidingViewController *keyboardAvoidingViewController = [[KeyboardAvoidingViewController alloc] initWithViewController:addEmailPasswordViewController];
    keyboardAvoidingViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self presentViewController:keyboardAvoidingViewController animated:YES completion:nil];
}

#pragma mark - FormStepDelegate

- (void)didSkipFormStep:(UIViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate profileSelfDetailsViewControllerDidStopEditingDetails];
    }];
}

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    [self updateVerifiedUserDetails];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate profileSelfDetailsViewControllerDidStopEditingDetails];
    }];
}

@end
