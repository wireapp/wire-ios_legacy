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


#import "TermsOfUseStepViewController.h"

@import SafariServices;

#import "UIColor+WAZExtensions.h"
#import "Analytics.h"
#import "WebLinkTextView.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"
#import "NSURL+WireLocale.h"
#import "Button.h"


@interface TermsOfUseStepViewController () <UITextViewDelegate>

@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;

@end

@implementation TermsOfUseStepViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.device = UIDevice.currentDevice;

        self.unregisteredUser = unregisteredUser;

        [self createContainerView];
        [self createTitleLabel];
        [self createTermsOfUseText];
        [self createAgreeButton];

        [self updateViewConstraints];

        [self updateConstraintsForSizeClass];
    }

    return self;
}

- (void)createContainerView {
    self.containerView = [UIView new];
    self.containerView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.containerView];
}

- (void)createTitleLabel
{
    self.titleLabel = [UILabel new];
    self.titleLabel.font = UIFont.largeSemiboldFont;
    self.titleLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.titleLabel.text = NSLocalizedString(@"registration.terms_of_use.title", nil);
    self.titleLabel.accessibilityTraits |= UIAccessibilityTraitHeader;

    [self.containerView addSubview:self.titleLabel];
}

- (void)createTermsOfUseText
{
    NSString *termsOfUse = NSLocalizedString(@"registration.terms_of_use.terms", nil);
    NSString *termsOfUseLink = NSLocalizedString(@"registration.terms_of_use.terms.link", nil);
    NSRange termsOfUseLinkRange = [termsOfUse rangeOfString:termsOfUseLink];
    
    NSMutableAttributedString *attributedTerms =
    [[NSMutableAttributedString alloc] initWithString:termsOfUse
                                           attributes:@{ NSFontAttributeName : UIFont.largeLightFont,
                                                         NSForegroundColorAttributeName: [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] }];
    
    [attributedTerms addAttributes:@{ NSFontAttributeName : UIFont.largeSemiboldFont,
                                      NSForegroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark],
                                      NSLinkAttributeName : self.termsOfServiceURL } range:termsOfUseLinkRange];
    
    self.termsOfUseText = [WebLinkTextView new];
    self.termsOfUseText.linkTextAttributes = @{};
    self.termsOfUseText.delegate = self;
    self.termsOfUseText.attributedText = [[NSAttributedString alloc] initWithAttributedString:attributedTerms];
    [self.containerView addSubview:self.termsOfUseText];
    
    UITapGestureRecognizer *openURLGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(openTOS:)];
    [self.termsOfUseText addGestureRecognizer:openURLGestureRecognizer];
    [self.wr_navigationController.backButton addTarget:self action:@selector(onBackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)onBackButtonPressed:(UIButton*)sender {
    [[UnauthenticatedSession sharedSession] cancelWaitForEmailVerification];
}

- (void)createAgreeButton
{
    self.agreeButton = [Button buttonWithStyle:ButtonStyleFullMonochrome];
    self.agreeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.agreeButton setTitle:NSLocalizedString(@"registration.terms_of_use.agree", nil) forState:UIControlStateNormal];
    [self.agreeButton addTarget:self action:@selector(agreeToTerms:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.containerView addSubview:self.agreeButton];
}

#pragma mark - Actions

- (void)openTOS:(id)sender
{
    BrowserViewController *webViewController = [[BrowserViewController alloc] initWithURL:self.termsOfServiceURL];
    [self presentViewController:webViewController animated:YES completion:nil];
}

- (NSURL *)termsOfServiceURL
{
    BOOL isTeamAccount = ZMUser.selfUser.team != nil;
    NSURL *url = [NSURL wr_termsOfServicesURLForTeamAccount:isTeamAccount];
    return url.wr_URLByAppendingLocaleParameter;
}

- (void)agreeToTerms:(id)sender
{
    [self.formStepDelegate didCompleteFormStep:self];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if (! URL) {
        return NO;
    }
    [self openTOS:nil];
    
    return NO;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    // Prevent selection of the 'Terms of use'
    if (! NSEqualRanges(textView.selectedRange, NSMakeRange(0, 0))) {
        textView.selectedRange = NSMakeRange(0, 0);
    }
}

@end
