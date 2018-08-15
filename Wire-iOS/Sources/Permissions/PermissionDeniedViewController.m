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


#import "PermissionDeniedViewController.h"

@import PureLayout;

#import "UIColor+WAZExtensions.h"
#import "Analytics.h"
#import "WebLinkTextView.h"
#import "Wire-Swift.h"
#import "Button.h"


@interface PermissionDeniedViewController ()
@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) Button *settingsButton;
@property (nonatomic) UIButton *laterButton;
@property (nonatomic) UIVisualEffectView *backgroundBlurView;
@property (nonatomic )BOOL monochromeStyle;
@end

@implementation PermissionDeniedViewController

+ (instancetype)addressBookAccessDeniedViewControllerWithMonochromeStyle:(BOOL)monochromeStyle
{
    PermissionDeniedViewController *vc = [[PermissionDeniedViewController alloc] init];
    vc.monochromeStyle = monochromeStyle;
    (void)vc.view;
    NSString *title = NSLocalizedString(@"registration.address_book_access_denied.hero.title", nil);
    NSString *paragraph1 = NSLocalizedString(@"registration.address_book_access_denied.hero.paragraph1", nil);
    NSString *paragraph2 = NSLocalizedString(@"registration.address_book_access_denied.hero.paragraph2", nil);
    
    NSString *text = [@[title, paragraph1, paragraph2] componentsJoinedByString:@"\u2029"];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName : paragraphStyle }];
    [attributedText addAttributes:@{ NSFontAttributeName : UIFont.largeThinFont } range:[text rangeOfString:[@[paragraph1, paragraph2] componentsJoinedByString:@"\u2029"]]];
    [attributedText addAttributes:@{ NSFontAttributeName : UIFont.largeSemiboldFont } range:[text rangeOfString:title]];
    vc.heroLabel.attributedText = attributedText;
    
    [vc.settingsButton setTitle:[NSLocalizedString(@"registration.address_book_access_denied.settings_button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];

    [vc.laterButton setTitle:[NSLocalizedString(@"registration.address_book_access_denied.maybe_later_button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    
    return vc;
}

+ (instancetype)pushDeniedViewController
{
    PermissionDeniedViewController *vc = [[PermissionDeniedViewController alloc] init];
    (void)vc.view;
    NSString *title = NSLocalizedString(@"registration.push_access_denied.hero.title", nil);
    NSString *paragraph1 = NSLocalizedString(@"registration.push_access_denied.hero.paragraph1", nil);
    
    NSString *text = [@[title, paragraph1] componentsJoinedByString:@"\u2029"];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName : paragraphStyle }];
    [attributedText addAttributes:@{ NSFontAttributeName : UIFont.largeThinFont } range:[text rangeOfString:paragraph1]];
    [attributedText addAttributes:@{ NSFontAttributeName : UIFont.largeSemiboldFont } range:[text rangeOfString:title]];
    vc.heroLabel.attributedText = attributedText;
    
    [vc.settingsButton setTitle:[NSLocalizedString(@"registration.push_access_denied.settings_button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    
    [vc.laterButton setTitle:[NSLocalizedString(@"registration.push_access_denied.maybe_later_button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    
    return vc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.backgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.backgroundBlurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backgroundBlurView];
    [self.backgroundBlurView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    self.backgroundBlurView.hidden = self.backgroundBlurDisabled;

    [self createHeroLabel];
    [self createSettingsButton];
    [self createLaterButton];
    
    [self updateViewConstraints];
}

- (void)createHeroLabel
{    
    self.heroLabel = [[UILabel alloc] initForAutoLayout];
    self.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.heroLabel.numberOfLines = 0;
   
    [self.view addSubview:self.heroLabel];
}

- (void)createSettingsButton
{
    self.settingsButton = [Button buttonWithStyle:self.monochromeStyle ? ButtonStyleFullMonochrome : ButtonStyleFull];
    [self.settingsButton addTarget:self action:@selector(openSettings:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.settingsButton];
}

- (void)createLaterButton
{
    self.laterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.laterButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.laterButton.titleLabel.font = UIFont.smallLightFont;
    [self.laterButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
    [self.laterButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorButtonFaded variant:ColorSchemeVariantDark] forState:UIControlStateHighlighted];
    [self.laterButton addTarget:self action:@selector(continueWithoutAccess:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.laterButton];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.heroLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        
        [self.settingsButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.heroLabel withOffset:28];
        [self.settingsButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:28];
        [self.settingsButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        [self.settingsButton autoSetDimension:ALDimensionHeight toSize:40];
        
        [self.laterButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.settingsButton withOffset:28];
        [self.laterButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:28];
        [self.laterButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    }
}

- (void)setBackgroundBlurDisabled:(BOOL)backgroundBlurDisabled
{
    _backgroundBlurDisabled = backgroundBlurDisabled;
    self.backgroundBlurView.hidden = self.backgroundBlurDisabled;
}

#pragma mark - Actions

- (IBAction)openSettings:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                       options:@{}
                             completionHandler:NULL];
}

- (IBAction)continueWithoutAccess:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(continueWithoutPermission:)]) {
        [self.delegate continueWithoutPermission:self];
    }
}


@end
