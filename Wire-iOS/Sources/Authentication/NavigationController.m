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


#import "NavigationController.h"

@import WireExtensionComponents;


#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WAZExtensions.h"
#import "UIResponder+FirstResponder.h"
#import "Wire-Swift.h"


@interface NavigationController ()

@property (nonatomic) UIImageView *logoImageView;
@property (nonatomic, readwrite) IconButton *backButton;
// Display either rightTitledButton or rightIconedButton
@property (nonatomic) Button *rightTitledButton;
@property (nonatomic) IconButton *rightIconedButton;
@property (nonatomic, assign) BOOL rightButtonIsTitledOne;  // YES for rightTitledButton, NO for rightIconedButton

@end

@implementation NavigationController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self view];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBackButton];
    [self setupRightButton];
    [self setupLogo];
    
    self.navigationBarHidden = YES;
    self.backButtonEnabled = YES;
    self.rightButtonEnabled = NO;
    
    [self updateLogoAnimated:NO];
    [self updateBackButtonAnimated:NO];

    [self createConstraints];
}

- (BOOL)prefersStatusBarHidden
{
    return self.topViewController.prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.topViewController.preferredStatusBarStyle;
}

- (void)setupBackButton
{
    self.backButton = [[IconButton alloc] initWithStyle:IconButtonStyleNavigation variant:ColorSchemeVariantDark];
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    ZetaIconType iconType = [UIApplication isLeftToRightLayout] ? ZetaIconTypeChevronLeft : ZetaIconTypeChevronRight;

    [self.backButton setIcon:iconType withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.backButton.accessibilityIdentifier = @"backButton";
    self.backButton.accessibilityLabel = NSLocalizedString(@"general.back", @"");
    [self.view addSubview:self.backButton];

    [self.backButton addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupRightButton
{
    self.rightTitledButton = [Button buttonWithStyle:ButtonStyleEmptyMonochrome];
    self.rightTitledButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightTitledButton.alpha = 0;
    self.rightTitledButton.accessibilityIdentifier = @"RegistrationRightButton";

    [self.view addSubview:self.rightTitledButton];
    
    self.rightIconedButton = [[IconButton alloc] initWithStyle:IconButtonStyleCircular];
    self.rightIconedButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightIconedButton.alpha = 0;
    self.rightIconedButton.accessibilityIdentifier = @"RightButton";
    
    [self.view addSubview:self.rightIconedButton];
}

- (void)setupLogo
{
    UIImage *logoImage = [WireStyleKit imageOfWireWithColor:[UIColor whiteColor]];
    self.logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.logoImageView];
}

- (void)createConstraints
{
    CGFloat topMargin = 32;
    CGFloat leftMargin = 28;
    CGFloat rightMargin = 28;
    CGFloat buttonSize = 32;

    NSArray<NSLayoutConstraint *> *constraints =
    @[
      // logoImageView
      [self.logoImageView.leadingAnchor constraintEqualToAnchor:self.view.safeLeadingAnchor constant:leftMargin],
      [self.logoImageView.topAnchor constraintEqualToAnchor:self.safeTopAnchor constant:topMargin],
      [self.logoImageView.widthAnchor constraintEqualToConstant:76],
      [self.logoImageView.heightAnchor constraintEqualToConstant:22],

      // backButton
      [self.backButton.leadingAnchor constraintEqualToAnchor:self.view.safeLeadingAnchor constant:leftMargin],
      [self.backButton.topAnchor constraintEqualToAnchor:self.safeTopAnchor constant:topMargin],

      // rightTitledButton
      [self.rightTitledButton.topAnchor constraintEqualToAnchor:self.safeTopAnchor constant:topMargin],
      [self.rightTitledButton.trailingAnchor constraintEqualToAnchor:self.view.safeTrailingAnchor constant:rightMargin],
      [self.rightTitledButton.heightAnchor constraintEqualToConstant:28],

      // rightIconedButton
      [self.rightIconedButton.topAnchor constraintEqualToAnchor:self.safeTopAnchor constant:topMargin],
      [self.rightIconedButton.trailingAnchor constraintEqualToAnchor:self.view.safeTrailingAnchor constant:rightMargin],
      [self.rightIconedButton.heightAnchor constraintEqualToConstant:buttonSize],
      [self.rightIconedButton.widthAnchor constraintEqualToConstant:buttonSize],
      ];

    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];

    if (animated) {
        [self takeFirstResponderDuringTransition];
    }
    
    [self updateBackButtonAnimated:animated];
    [self updateLogoAnimated:animated];
    [self updateRightButtonAnimated:animated];
}

- (NSArray<UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated
{
    NSArray<UIViewController *> *viewControllers = [super popToRootViewControllerAnimated:animated];
    [self updateLogoAnimated:animated];
    [self updateBackButtonAnimated:animated];
    [self updateRightButtonAnimated:animated];
    
    return viewControllers;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *poppedViewController = [super popViewControllerAnimated:animated];

    if (self.viewControllers.count > 1) {
        [self takeFirstResponderDuringTransition];
    }
    
    [self updateLogoAnimated:animated];
    [self updateBackButtonAnimated:animated];
    [self updateRightButtonAnimated:animated];
    
    return poppedViewController;
}

- (void)takeFirstResponderDuringTransition
{
    UIResponder *currentFirstResponder = [UIResponder wr_currentFirstResponder];
    
    if ([currentFirstResponder isKindOfClass:[UITextField class]]) {
        UITextField *activeTextField = (UITextField *)currentFirstResponder;
        
        UITextField *temporaryResponder = [[UITextField alloc] init];
        temporaryResponder.keyboardAppearance = activeTextField.keyboardAppearance;
        temporaryResponder.keyboardType = activeTextField.keyboardType;
        temporaryResponder.autocorrectionType = activeTextField.autocorrectionType;
        temporaryResponder.secureTextEntry = activeTextField.secureTextEntry;
        
        [self.view addSubview:temporaryResponder];
        [temporaryResponder becomeFirstResponder];
        
        if (self.transitionCoordinator) {
            
            [self.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                [temporaryResponder removeFromSuperview];
            }];
        }
        else {
            
            [temporaryResponder removeFromSuperview];
        }

    }
}

- (void)updateLogoAnimated:(BOOL)animated
{
    dispatch_block_t updateBlock = ^{
        BOOL shouldShowLogo = (self.viewControllers.count <= 1 || ! self.backButtonEnabled) && self.logoEnabled;
        self.logoImageView.alpha = shouldShowLogo ? 1 : 0;
    };
    
    if (animated && self.transitionCoordinator) {
        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            updateBlock();
        } completion:nil];
    } else {
        updateBlock();
    }
}

- (void)updateBackButtonAnimated:(BOOL)animated
{
    NSString *title = @"";
    
    if (self.viewControllers.count > 1) {
        UIViewController *previousViewController = [self.viewControllers objectAtIndex:self.viewControllers.count - 2];
        title = previousViewController.title;
    }
    
    dispatch_block_t updateBlock = ^{
        BOOL shouldHideBackButton = self.viewControllers.count <= 1 || ! self.backButtonEnabled;
        self.backButton.alpha = shouldHideBackButton ? 0 : 1;
        [self.backButton setTitle:title.uppercasedWithCurrentLocale forState:UIControlStateNormal];

        if (self.topViewController.preferredStatusBarStyle == UIStatusBarStyleDefault) {
            self.backButton.tintColor = [UIColor graphite];
        } else {
            self.backButton.tintColor = [UIColor whiteColor];
        }
    };
    
    if (animated && self.transitionCoordinator) {
        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            updateBlock();
        } completion:nil];
    } else {
        updateBlock();
    }
}

- (void)updateRightButtonAnimated:(BOOL)animated
{    
    dispatch_block_t updateBlock = ^{
        self.rightTitledButton.alpha = (self.rightButtonEnabled && self.rightButtonIsTitledOne) ? 1 : 0;
        self.rightIconedButton.alpha = (self.rightButtonEnabled && ! self.rightButtonIsTitledOne) ? 1 : 0;
        self.rightTitledButton.userInteractionEnabled = self.rightButtonIsTitledOne;
        self.rightIconedButton.userInteractionEnabled = ! self.rightButtonIsTitledOne;
    };
    
    if (animated && self.transitionCoordinator) {
        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            updateBlock();
        } completion:nil];
    } else {
        updateBlock();
    }
}

- (void)updateRightButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action animated:(BOOL)animated
{
    self.rightButtonIsTitledOne = YES;
    
    dispatch_block_t updateBlock = ^{
        self.rightTitledButton.alpha = self.rightButtonEnabled ? 1 : 0;
        [self.rightTitledButton setTitle:title forState:UIControlStateNormal];
    };
    
    [self updateRightButton:self.rightTitledButton withTarget:target action:action updateBlock:updateBlock animated:animated];
}

- (void)updateRightButtonWithIconType:(ZetaIconType)iconType
                             iconSize:(ZetaIconSize)iconSize
                               target:(id)target
                               action:(SEL)action
                             animated:(BOOL)animated
{
    self.rightButtonIsTitledOne = NO;
    
    dispatch_block_t updateBlock = ^{
        self.rightIconedButton.alpha = self.rightButtonEnabled ? 1 : 0;
        [self.rightIconedButton setIcon:iconType withSize:iconSize forState:UIControlStateNormal];
    };
    
    [self updateRightButton:self.rightIconedButton withTarget:target action:action updateBlock:updateBlock animated:animated];
}

- (void)updateRightButton:(UIButton *)button withTarget:(id)target action:(SEL)action updateBlock:(dispatch_block_t)updateBlock animated:(BOOL)animated
{
    self.rightButtonEnabled = target != nil;
    self.rightTitledButton.hidden = ! self.rightButtonIsTitledOne;
    self.rightIconedButton.hidden = self.rightButtonIsTitledOne;
    
    [button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    if (animated && self.transitionCoordinator) {
        [UIView transitionWithView:button duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            updateBlock();
        } completion:nil];
    } else {
        updateBlock();
    }
}

- (void)setBackButtonEnabled:(BOOL)backButtonEnabled
{
    _backButtonEnabled = backButtonEnabled;
    [self updateBackButtonAnimated:NO];
}

- (void)setLogoEnabled:(BOOL)enabled
{
    _logoEnabled = enabled;
    [self updateLogoAnimated:NO];
}

- (void)setRightButtonEnabled:(BOOL)rightButtonEnabled
{
    _rightButtonEnabled = rightButtonEnabled;
    [self updateRightButtonAnimated:NO];
}

#pragma mark - Actions

- (IBAction)backButtonTapped:(id)sender
{
    [self.topViewController resignFirstResponder];
    [self popViewControllerAnimated:YES];
}

@end


@implementation UIViewController (NavigationController)

- (NavigationController *)wr_navigationController
{
    if ([self.navigationController isKindOfClass:NavigationController.class]) {
        return (NavigationController *)self.navigationController;
    }
    
    return nil;
}

@end
