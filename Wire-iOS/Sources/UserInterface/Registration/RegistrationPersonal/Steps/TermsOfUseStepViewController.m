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

@import PureLayout;
@import SafariServices;

#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"
#import "Analytics.h"
#import "WebLinkTextView.h"

#import "NSURL+WireLocale.h"
#import "NSURL+WireURLs.h"
#import "Button.h"


@interface TermsOfUseStepViewController () <UITextViewDelegate>

@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UITextView *termsOfUseText;
@property (nonatomic) Button *agreeButton;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;

@end

@implementation TermsOfUseStepViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.unregisteredUser = unregisteredUser;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createTitleLabel];
    [self createTermsOfUseText];
    [self createAgreeButton];
    
    [self updateViewConstraints];
}

- (void)createTitleLabel
{
    self.titleLabel = [[UILabel alloc] initForAutoLayout];
    self.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_medium"];
    self.titleLabel.textColor = [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"];
    self.titleLabel.text = NSLocalizedString(@"registration.terms_of_use.title", nil);
    
    [self.view addSubview:self.titleLabel];
}

- (void)createTermsOfUseText
{
    NSString *termsOfUse = NSLocalizedString(@"registration.terms_of_use.terms", nil);
    NSString *termsOfUseLink = NSLocalizedString(@"registration.terms_of_use.terms.link", nil);
    NSRange termsOfUseLinkRange = [termsOfUse rangeOfString:termsOfUseLink];
    
    NSMutableAttributedString *attributedTerms =
    [[NSMutableAttributedString alloc] initWithString:termsOfUse
                                           attributes:@{ NSFontAttributeName : [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_light"],
                                                         NSForegroundColorAttributeName: [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"] }];
    
    [attributedTerms addAttributes:@{ NSFontAttributeName : [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_medium"],
                                      NSForegroundColorAttributeName : UIColor.accentColor,
                                      NSLinkAttributeName : NSURL.wr_termsOfServicesURL } range:termsOfUseLinkRange];
    
    self.termsOfUseText = [[WebLinkTextView alloc] initForAutoLayout];
    self.termsOfUseText.delegate = self;
    self.termsOfUseText.attributedText = [[NSAttributedString alloc] initWithAttributedString:attributedTerms];
    [self.view addSubview:self.termsOfUseText];
    
    UITapGestureRecognizer *openURLGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(openTOS:)];
    [self.termsOfUseText addGestureRecognizer:openURLGestureRecognizer];
}

- (void)createAgreeButton
{
    self.agreeButton = [Button buttonWithStyle:ButtonStyleFullMonochrome];
    self.agreeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.agreeButton setTitle:NSLocalizedString(@"registration.terms_of_use.agree", nil) forState:UIControlStateNormal];
    [self.agreeButton addTarget:self action:@selector(agreeToTerms:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.agreeButton];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        
        [self.termsOfUseText autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:5];
        [self.termsOfUseText autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.termsOfUseText autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        
        [self.agreeButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.termsOfUseText withOffset:24];
        [self.agreeButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 28, 28, 28) excludingEdge:ALEdgeTop];
        [self.agreeButton autoSetDimension:ALDimensionHeight toSize:40];
    }
}

#pragma mark - Actions

- (void)openTOS:(id)sender
{
    SFSafariViewController *webViewController = [[SFSafariViewController alloc] initWithURL:[NSURL.wr_termsOfServicesURL wr_URLByAppendingLocaleParameter]];
    [self presentViewController:webViewController animated:YES completion:nil];
}

- (void)agreeToTerms:(id)sender
{
    [self.formStepDelegate didCompleteFormStep:self];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    return [self textView:textView shouldInteractWithURL:URL inRange:characterRange interaction:0];
}

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
