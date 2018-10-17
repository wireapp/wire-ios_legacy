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


#import "EmailVerificationStepViewController.h"

#import "NavigationController.h"
#import "CheckmarkViewController.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WAZExtensions.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"


@interface EmailVerificationStepViewController () <UITextViewDelegate>

@property (nonatomic) UIView *containerView;

@property (nonatomic) UIImageView *mailIconView;
@property (nonatomic) UILabel *instructionsLabel;
@property (nonatomic) UILabel *resendInstructionsLabel;
@property (nonatomic) UIButton *resendButton;

@property (nonatomic) BOOL initialConstraintsCreated;

@property (nonatomic) NSString *emailAddress;

@end



@implementation EmailVerificationStepViewController

- (instancetype)initWithEmailAddress:(NSString *)emailAddress
{
    self = [super initWithNibName:nil bundle:nil];
    if (nil != self) {
        self.emailAddress = emailAddress;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createContainerView];
    [self createMailIconView];
    [self createInstructionsLabel];
    [self createResendInstructions];
    [self createResendButton];

    [self createConstraints];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    self.registrationNavigationController.backButtonEnabled = YES;
    self.registrationNavigationController.wr_navigationController.logoEnabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UnauthenticatedSession sharedSession] cancelWaitForEmailVerification];
    self.registrationNavigationController.backButtonEnabled = NO;
    self.registrationNavigationController.wr_navigationController.logoEnabled = YES;
}

#pragma mark - UI Setup

- (void)createContainerView
{
    self.containerView = [UIView new];
    [self.view addSubview:self.containerView];
}

- (void)createMailIconView
{
    self.mailIconView = [[UIImageView alloc] initWithImage:[UIImage imageForIcon:ZetaIconTypeEnvelope iconSize:ZetaIconSizeLarge color:[UIColor whiteColor]]];
    [self.containerView addSubview:self.mailIconView];
}

- (void)createInstructionsLabel
{
    self.instructionsLabel = [UILabel new];
    self.instructionsLabel.numberOfLines = 0;
    self.instructionsLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionsLabel.font = UIFont.normalLightFont;
    self.instructionsLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.instructionsLabel.attributedText = [self attributedInstructionsText];
    [self.containerView addSubview:self.instructionsLabel];
}

- (NSAttributedString *)attributedInstructionsText
{
    NSString *instructions = [NSString stringWithFormat:NSLocalizedString(@"registration.verify_email.instructions", nil), self.emailAddress];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:instructions];
    
    [attributedText addAttributes:@{NSFontAttributeName : UIFont.normalMediumFont}
                            range:[instructions rangeOfString:self.emailAddress]];
    
    return [[NSAttributedString alloc] initWithAttributedString:attributedText];
}

- (void)createResendInstructions
{
    self.resendInstructionsLabel = [UILabel new];
    self.resendInstructionsLabel.numberOfLines = 0;
    self.resendInstructionsLabel.textAlignment = NSTextAlignmentCenter;
    self.resendInstructionsLabel.font = UIFont.normalLightFont;
    self.resendInstructionsLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorButtonFaded variant:ColorSchemeVariantDark];
    self.resendInstructionsLabel.text = NSLocalizedString(@"registration.verify_email.resend.instructions", nil);
    [self.containerView addSubview:self.resendInstructionsLabel];
}

- (void)createResendButton
{
    self.resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resendButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.resendButton.titleLabel.font = UIFont.normalLightFont;
    [self.resendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.resendButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.4] forState:UIControlStateHighlighted];
    [self.resendButton setTitle:NSLocalizedString(@"registration.verify_email.resend.button_title", nil) forState:UIControlStateNormal];
    [self.resendButton addTarget:self action:@selector(resendVerificationEmail:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.resendButton];
}

- (void)createConstraints
{
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mailIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.instructionsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.resendInstructionsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.resendButton.translatesAutoresizingMaskIntoConstraints = NO;

    NSArray<NSLayoutConstraint *> *constraints =
  @[
    // containerView
    [self.containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28],
    [self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28],
    [self.containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],

    // mailIconView
    [self.mailIconView.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
    [self.mailIconView.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],

    // instructionsLabel
    [self.instructionsLabel.topAnchor constraintEqualToAnchor:self.mailIconView.bottomAnchor constant:32],
    [self.instructionsLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
    [self.instructionsLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],

    // resendInstructionsLabel
    [self.resendInstructionsLabel.topAnchor constraintEqualToAnchor:self.instructionsLabel.bottomAnchor constant:32],
    [self.resendInstructionsLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
    [self.resendInstructionsLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
    [self.resendInstructionsLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],

    // resendButton
    [self.resendButton.topAnchor constraintEqualToAnchor:self.resendInstructionsLabel.bottomAnchor constant:0],
    [self.resendButton.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
    [self.resendButton.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor]
    ];

    [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark - Actions

- (IBAction)resendVerificationEmail:(id)sender
{
    [self.delegate emailVerificationStepDidRequestVerificationEmail];
    
    [self presentViewController:[[CheckmarkViewController alloc] init] animated:YES completion:nil];
}

@end
