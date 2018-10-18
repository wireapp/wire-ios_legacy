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
@import WireSyncEngine;
#import "RegistrationFormController.h"
#import "Button.h"
#import "Wire-Swift.h"

@interface NoHistoryViewController ()
@property (nonatomic) UILabel *heroLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIStackView *stackView;
@property (nonatomic) UIImageView *backgroundImageView;
@end

@implementation NoHistoryViewController

@synthesize authenticationCoordinator;

- (instancetype)initWithContextType:(ContextType)contextType
{
    self = [super initWithNibName:nil bundle:nil];
    if (nil != self) {
        _contextType = contextType;
    }
    return self;
}
    
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createBackgroundImageView];
    [self createContentView];
    [self createHeroLabel];
    [self createSubtitleLabel];
    
    [self createContentViewConstraints];
    
    [self createButtons];
    
    // Layout first to avoid the initial layout animation during the presentation. 
    [self.view layoutIfNeeded];
}

- (void)createBackgroundImageView
{
    UIImage *backgroundImage = [UIImage imageNamed:@"LaunchImage"];
    self.backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backgroundImageView];

    [NSLayoutConstraint activateConstraints:
    @[
          [self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
          [self.backgroundImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
          [self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
          [self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)createContentView
{
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.contentView];
 
    self.stackView = [[UIStackView alloc] init];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.spacing = 12;
    self.stackView.distribution = UIStackViewDistributionFill;
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.alignment = UIStackViewAlignmentFill;
    self.stackView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.stackView];
}

- (void)createHeroLabel
{
    self.heroLabel = [[UILabel alloc] init];
    self.heroLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.heroLabel.numberOfLines = 0;
    self.heroLabel.textColor = [[ColorScheme defaultColorScheme] colorWithName:ColorSchemeColorTextForeground
                                                                       variant:ColorSchemeVariantDark];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    NSString *heroText = [self localizableStringForPart:@"hero"];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(heroText, nil)
                                                                                       attributes:@{ NSParagraphStyleAttributeName : paragraphStyle,
                                                                                                     NSFontAttributeName: UIFont.largeSemiboldFont }];
    self.heroLabel.attributedText = attributedText;
    [self.stackView addArrangedSubview:self.heroLabel];
}

- (void)createSubtitleLabel
{
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.numberOfLines = 0;
    self.subtitleLabel.textColor = [[ColorScheme defaultColorScheme] colorWithName:ColorSchemeColorTextForeground
                                                                           variant:ColorSchemeVariantDark];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    NSString *subtitleText = [self localizableStringForPart:@"subtitle"];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(subtitleText, nil)
                                                                                       attributes:@{ NSParagraphStyleAttributeName : paragraphStyle,
                                                                                                     NSFontAttributeName: UIFont.largeThinFont}];
    self.subtitleLabel.attributedText = attributedText;
    [self.stackView addArrangedSubview:self.subtitleLabel];
    
    UIView *placeholder = [[UIView alloc] init];
    placeholder.backgroundColor = [UIColor clearColor];
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    [placeholder.heightAnchor constraintEqualToConstant:24];
    [self.stackView addArrangedSubview:placeholder];
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
