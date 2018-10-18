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

@import PureLayout;
@import WireExtensionComponents;

#import "AddPhoneNumberViewController.h"

#import "NavigationController.h"
#import "PhoneNumberStepViewController.h"
#import "VerificationCodeStepViewController.h"
#import "PopTransition.h"
#import "PushTransition.h"
#import "RegistrationFormController.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
#import "UIImage+ZetaIconsNeue.h"

#import "RegistrationFormController.h"
#import "CheckmarkViewController.h"

#import "Wire-Swift.h"


@interface AddPhoneNumberViewController ()

@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) NavigationController *rootNavigationController;
@property (nonatomic) PhoneNumberStepViewController *phoneNumberStepViewController;
@property (nonatomic) PopTransition *popTransition;
@property (nonatomic) PushTransition *pushTransition;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UIButton *skipButton;

@end

@implementation AddPhoneNumberViewController

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.wr_supportedInterfaceOrientations;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.popTransition = [[PopTransition alloc] init];
    self.pushTransition = [[PushTransition alloc] init];
    
    [self createNavigationController];
    [self createCloseButton];
    [self createSkipButton];
    
    if (self.skipButtonType == AddPhoneNumberViewControllerSkipButtonTypeSkip) {
        self.skipButton.hidden = NO;
    }
    else if (self.skipButtonType == AddPhoneNumberViewControllerSkipButtonTypeClose) {
        self.closeButton.hidden = NO;
    }
    
    self.view.opaque = NO;
    
    [self updateViewConstraints];
}

- (void)setShowsNavigationBar:(BOOL)showsNavigationBar
{
    _showsNavigationBar = showsNavigationBar;
    self.rootNavigationController.backButtonEnabled = self.showsNavigationBar;
    self.rootNavigationController.rightButtonEnabled = self.showsNavigationBar;
    self.rootNavigationController.logoEnabled = self.showsNavigationBar;

}

- (void)createNavigationController
{
    self.phoneNumberStepViewController = [[PhoneNumberStepViewController alloc] init];
    self.phoneNumberStepViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.phoneNumberStepViewController.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.phoneNumberStepViewController.heroLabel.font = UIFont.largeSemiboldFont;
    self.phoneNumberStepViewController.heroLabel.attributedText = [self attributedHeroText];
    
    self.rootNavigationController = [[NavigationController alloc] initWithRootViewController:self.phoneNumberStepViewController.registrationFormViewController];
    self.rootNavigationController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.rootNavigationController.view.opaque = NO;
    self.rootNavigationController.backButtonEnabled = self.showsNavigationBar;
    self.rootNavigationController.rightButtonEnabled = self.showsNavigationBar;
    self.rootNavigationController.logoEnabled = self.showsNavigationBar;
    
    [self addChildViewController:self.rootNavigationController];
    [self.view addSubview:self.rootNavigationController.view];
    [self.rootNavigationController didMoveToParentViewController:self];
}

- (void)createCloseButton
{
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.hidden = YES;
    self.closeButton.adjustsImageWhenHighlighted = YES;
    [self.closeButton setImage:[UIImage imageForIcon:ZetaIconTypeX
                                            iconSize:ZetaIconSizeSmall
                                               color:[UIColor whiteColor]]
                      forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(skip:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
}

- (void)createSkipButton
{
    self.skipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.skipButton.hidden = YES;
    self.skipButton.titleLabel.font = UIFont.smallLightFont;
    [self.skipButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
    [self.skipButton setTitleColor:[[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] colorWithAlphaComponent:0.2] forState:UIControlStateHighlighted];
    [self.skipButton setTitle:[NSLocalizedString(@"registration.add_phone_number.skip_button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    [self.skipButton addTarget:self action:@selector(skip:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.skipButton];
}

- (NSAttributedString *)attributedHeroText
{
    NSString *title = NSLocalizedString(@"registration.add_phone_number.hero.title", nil);
    NSString *paragraph = NSLocalizedString(@"registration.add_phone_number.hero.paragraph", nil);
    
    NSString * text = [@[title, paragraph] componentsJoinedByString:@"\u2029"];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName : paragraphStyle }];
    [attributedText addAttributes:@{ NSForegroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark],
                                     NSFontAttributeName: UIFont.largeLightFont }
                            range:[text rangeOfString:paragraph]];
    
    return attributedText;
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        
        self.initialConstraintsCreated = YES;
        [self.rootNavigationController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        
        [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:32];
        [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        
        [self.skipButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:32];
        [self.skipButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
        [self.skipButton autoSetDimension:ALDimensionHeight toSize:28];
    }
}

#pragma mark - Actions

- (IBAction)skip:(id)sender
{
    // TODO: Remove
//    if ([self.formStepDelegate respondsToSelector:@selector(didSkipFormStep:)]) {
//        [self.view endEditing:NO];
//        [self.formStepDelegate didSkipFormStep:self];
//    }
}

@end
