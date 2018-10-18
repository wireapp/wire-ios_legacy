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

#import "AddEmailStepViewController.h"

#import "EmailFormViewController.h"
#import "UIImage+ZetaIconsNeue.h"
#import <WireExtensionComponents/ProgressSpinner.h>
#import "RegistrationTextField.h"
#import "GuidanceLabel.h"
#import "WireSyncEngine+iOS.h"
#import "Constants.h"
#import "Wire-Swift.h"

@interface AddEmailStepViewController ()

@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) EmailFormViewController *emailFormViewController;

@property (nonatomic, readonly) ZMEmailCredentials *credentials;

@end


@implementation AddEmailStepViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"registration.email_flow.email_step.title", nil);

    [self createHeroLabel];
    [self createEmailFormViewController];
    [self configureConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.emailFormViewController.emailField becomeFirstResponder];
}

#pragma mark - Interface Configuration

- (void)createHeroLabel
{
    self.heroLabel = [[UILabel alloc] init];
    self.heroLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.heroLabel.font = UIFont.largeSemiboldFont;
    self.heroLabel.numberOfLines = 0;
    self.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground
                                                        variant:ColorSchemeVariantDark];

    self.heroLabel.attributedText = [self attributedHeroText];
    self.heroLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.heroLabel];
}

- (NSAttributedString *)attributedHeroText
{
    NSString *title = NSLocalizedString(@"registration.add_email_password.hero.title", nil);
    NSString *paragraph = NSLocalizedString(@"registration.add_email_password.hero.paragraph", nil);
    
    NSString * text = [@[title, paragraph] componentsJoinedByString:@"\u2029"];
    
    if (IS_IPHONE_4) {
        text = title; // Hide paragraph since layout overflows
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName : paragraphStyle }];
    [attributedText addAttributes:@{ NSForegroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark],
                                     NSFontAttributeName : UIFont.largeLightFont }
                            range:[text rangeOfString:paragraph]];
    
    return attributedText;
}

- (void)createEmailFormViewController
{
    self.emailFormViewController = [[EmailFormViewController alloc] initWithNameFieldEnabled:NO];
    self.emailFormViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emailFormViewController.passwordField.confirmButton addTarget:self action:@selector(verifyFieldsAndContinue:) forControlEvents:UIControlEventTouchUpInside];
    [self addChildViewController:self.emailFormViewController];
    [self.view addSubview:self.emailFormViewController.view];
    [self.emailFormViewController didMoveToParentViewController:self];
}

- (void)configureConstraints
{
    CGFloat inset = 28.0;

    NSArray<NSLayoutConstraint *> *constraints =
  @[
    [self.heroLabel.leadingAnchor constraintEqualToAnchor:self.view.safeLeadingAnchor constant:inset],
    [self.heroLabel.trailingAnchor constraintEqualToAnchor:self.view.safeTrailingAnchor constant:-inset],
    [self.emailFormViewController.view.leadingAnchor constraintEqualToAnchor:self.view.safeLeadingAnchor constant:inset],
    [self.emailFormViewController.view.trailingAnchor constraintEqualToAnchor:self.view.safeTrailingAnchor constant:-inset],
    [self.emailFormViewController.view.topAnchor constraintEqualToAnchor:self.heroLabel.bottomAnchor constant:24],
    [self.emailFormViewController.view.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor constant:-10]
    ];

    [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark - Actions

- (ZMEmailCredentials *)credentials
{
    NSString *email = self.emailFormViewController.emailField.text ?: @"";
    NSString *password = self.emailFormViewController.passwordField.text ?: @"";

    return [ZMEmailCredentials credentialsWithEmail:email password:password];
}

- (void)clearFields
{
    [self.emailFormViewController resetAllFields];
    [self.emailFormViewController.emailField becomeFirstResponder];
}

- (void)verifyFieldsAndContinue:(id)sender
{
    if ([self.emailFormViewController validateAllFields]) {
        [self.delegate addEmailStepDidFinishWithEmailCredentials:self.credentials];
    }
}

@end
