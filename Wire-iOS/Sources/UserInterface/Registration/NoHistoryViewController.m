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


#import "NoHistoryViewController.h"
@import PureLayout;
#import "WAZUIMagicIOS.h"
#import "UIFont+MagicAccess.h"
#import "RegistrationFormController.h"
#import "Button.h"


@interface NoHistoryViewController ()
@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UIView *contentView;
@property (nonatomic) Button *OKButton;
@end

@implementation NoHistoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self createContentView];
    [self createHeroLabel];
    [self createSubtitleLabel];
    [self createOKButton];
    
    [self createViewConstraints];
    
    // Layout first to avoid the initial layout animation during the presentation. 
    [self.view layoutIfNeeded];
}

- (void)createContentView
{
    self.contentView = [[UIView alloc] initForAutoLayout];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentView];
}

- (void)createHeroLabel
{
    self.heroLabel = [[UILabel alloc] initForAutoLayout];
    self.heroLabel.numberOfLines = 0;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    NSString *heroText = [self localizableStringForPart:@"hero"];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(heroText, nil)
                                                                                       attributes:@{ NSParagraphStyleAttributeName : paragraphStyle,
                                                                                                     NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_medium"]}];
    self.heroLabel.attributedText = attributedText;
    
    [self.contentView addSubview:self.heroLabel];
}

- (void)createSubtitleLabel
{
    self.subtitleLabel = [[UILabel alloc] initForAutoLayout];
    self.subtitleLabel.numberOfLines = 0;
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    NSString *subtitleText = [self localizableStringForPart:@"subtitle"];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(subtitleText, nil)
                                                                                       attributes:@{ NSParagraphStyleAttributeName : paragraphStyle,
                                                                                                     NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_thin"]}];
    self.subtitleLabel.attributedText = attributedText;
    [self.contentView addSubview:self.subtitleLabel];
}

- (void)createOKButton
{
    self.OKButton = [Button buttonWithStyle:ButtonStyleFullMonochrome];
    self.OKButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSString *gotItText = [self localizableStringForPart:@"got_it"];
    [self.OKButton setTitle:NSLocalizedString(gotItText, nil) forState:UIControlStateNormal];
    [self.OKButton addTarget:self action:@selector(okButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.OKButton];
}

- (void)okButtonPressed:(id)sender
{
    [self.formStepDelegate didCompleteFormStep:self];
}

- (void)createViewConstraints
{
    [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
    [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
    
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
    [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.heroLabel withOffset:12];
    
    [self.OKButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.subtitleLabel withOffset:24];
    [self.OKButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 28, 28, 28) excludingEdge:ALEdgeTop];
    [self.OKButton autoSetDimension:ALDimensionHeight toSize:40];
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.contentView autoSetDimension:ALDimensionWidth toSize:self.parentViewController.maximumFormSize.width];
        [self.contentView autoSetDimension:ALDimensionHeight toSize:self.parentViewController.maximumFormSize.height];
        [self.contentView autoCenterInSuperview];
    } else {
        [self.contentView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
}


- (NSString *)localizableStringForPart:(NSString *)part
{
    switch (self.contextType) {
        case ContextTypeNewDevice:
            return [@"registration.no_history" stringByAppendingPathExtension:part];
            break;
        case ContextTypeLoggedOut:
            return [@"registration.no_history.logged_out" stringByAppendingPathExtension:part];
            break;
    }
}

@end
