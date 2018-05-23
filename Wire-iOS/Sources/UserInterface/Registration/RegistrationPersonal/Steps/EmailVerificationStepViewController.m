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

@import PureLayout;

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

    [self updateViewConstraints];
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

- (void)createContainerView
{
    self.containerView = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.containerView];
}

- (void)createMailIconView
{
    self.mailIconView = [[UIImageView alloc] initWithImage:[UIImage imageForIcon:ZetaIconTypeEnvelope iconSize:ZetaIconSizeLarge color:[UIColor whiteColor]]];
    self.mailIconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.mailIconView];
}

- (void)createInstructionsLabel
{
    self.instructionsLabel = [[UILabel alloc] initForAutoLayout];
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
    self.resendInstructionsLabel = [[UILabel alloc] initForAutoLayout];
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

- (void)updateViewConstraints
{
    [super updateViewConstraints];

    if (!self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.containerView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.containerView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.containerView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        
        [self.mailIconView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.mailIconView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        [self.instructionsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.mailIconView withOffset:32];
        [self.instructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.instructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeRight];
        
        [self.resendInstructionsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.instructionsLabel withOffset:32];
        [self.resendInstructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.resendInstructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.resendInstructionsLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
        [self.resendButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.resendInstructionsLabel withOffset:0];
        [self.resendButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.resendButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    }
}

#pragma mark - Actions

- (IBAction)resendVerificationEmail:(id)sender
{
    [self.delegate emailVerificationStepDidRequestVerificationEmail];
    
    [self presentViewController:[[CheckmarkViewController alloc] init] animated:YES completion:nil];
}

@end
