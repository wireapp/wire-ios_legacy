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

@import PureLayout;
@import WireExtensionComponents;

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
@property (nonatomic, assign) BOOL initialConstraintsCreated;

@end

@implementation AddEmailStepViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"registration.email_flow.email_step.title", nil);
    
    [self createHeroLabel];
    [self createEmailFormViewController];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.emailFormViewController.emailField becomeFirstResponder];
}

- (void)createHeroLabel
{
    self.heroLabel = [[UILabel alloc] initForAutoLayout];
    self.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.heroLabel.font = UIFont.largeSemiboldFont;
    self.heroLabel.numberOfLines = 0;
    self.heroLabel.attributedText = [self attributedHeroText];
    
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

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;

        CGFloat inset = 28.0;
        [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
        [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
        
        [self.emailFormViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.heroLabel withOffset:24];
        [self.emailFormViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:inset];
        [self.emailFormViewController.view autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:inset];
        [[self.emailFormViewController.view.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor constant:-10] setActive:YES];
    }
}

- (NSString *)password
{
    return self.emailFormViewController.passwordField.text;
}

- (NSString *)emailAddress
{
    return self.emailFormViewController.emailField.text;
}

#pragma mark - Actions

- (IBAction)clearFields:(id)sender
{
    [self.emailFormViewController resetAllFields];
    [self.emailFormViewController.emailField becomeFirstResponder];
}

- (IBAction)verifyFieldsAndContinue:(id)sender
{
    if ([self.emailFormViewController validateAllFields]) {
        
        [self.formStepDelegate didCompleteFormStep:self];
    }
}

@end
