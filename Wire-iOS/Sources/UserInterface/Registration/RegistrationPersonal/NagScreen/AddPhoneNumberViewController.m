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


#import "AddPhoneNumberViewController.h"

@import PureLayout;

#import "NavigationController.h"
#import "PhoneNumberStepViewController.h"
#import "PhoneVerificationStepViewController.h"
#import "PopTransition.h"
#import "PushTransition.h"
#import "RegistrationFormController.h"
#import "WireSyncEngine+iOS.h"
#import "UIColor+MagicAccess.h"
#import "UIFont+MagicAccess.h"
#import "UIViewController+Errors.h"
#import "UIImage+ZetaIconsNeue.h"
@import WireExtensionComponents;
#import "Wire-Swift.h"

#import "RegistrationFormController.h"
#import "CheckmarkViewController.h"

#import "AnalyticsTracker+Registration.h"



@interface AddPhoneNumberViewController () <UINavigationControllerDelegate, FormStepDelegate, PhoneVerificationStepViewControllerDelegate, UserProfileUpdateObserver, ZMUserObserver>

@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) NavigationController *rootNavigationController;
@property (nonatomic) PhoneNumberStepViewController *phoneNumberStepViewController;
@property (nonatomic) PopTransition *popTransition;
@property (nonatomic) PushTransition *pushTransition;
@property (nonatomic) id userEditingToken;
@property (nonatomic) id userObserverToken;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UIButton *skipButton;
@property (nonatomic, weak) id<UserProfile> userProfile;

@end

@implementation AddPhoneNumberViewController

- (void)dealloc
{
    self.userEditingToken = nil;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.userProfile = ZMUserSession.sharedSession.userProfile;
        self.userEditingToken = [self.userProfile addObserver:self];
        self.userObserverToken = [UserChangeInfo addObserver:self forUser:[ZMUser selfUser] userSession:[ZMUserSession sharedSession]];
    }
    
    return self;
}

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
    self.phoneNumberStepViewController.formStepDelegate = self;
    self.phoneNumberStepViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.phoneNumberStepViewController.heroLabel.textColor = [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"];
    self.phoneNumberStepViewController.heroLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_medium"];
    self.phoneNumberStepViewController.heroLabel.attributedText = [self attributedHeroText];
    
    self.rootNavigationController = [[NavigationController alloc] initWithRootViewController:self.phoneNumberStepViewController.registrationFormViewController];
    self.rootNavigationController.delegate = self;
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
    self.skipButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    [self.skipButton setTitleColor:[UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"] forState:UIControlStateNormal];
    [self.skipButton setTitleColor:[[UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"] colorWithAlphaComponent:0.2] forState:UIControlStateHighlighted];
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
    [attributedText addAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"],
                                     NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_light"] }
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
    [self.analyticsTracker tagSkippedAddingPhone];
    
    if ([self.formStepDelegate respondsToSelector:@selector(didSkipFormStep:)]) {
        [self.view endEditing:NO];
        [self.formStepDelegate didSkipFormStep:self];
    }
}

#pragma mark - FormStepProtocol

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[PhoneNumberStepViewController class]]) {
        
        [self.analyticsTracker tagEnteredPhone];

        self.showLoadingView = YES;

        [self.userProfile requestPhoneVerificationCodeWithPhoneNumber:self.phoneNumberStepViewController.phoneNumber];
    }
    else if ([viewController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        PhoneVerificationStepViewController *phoneVerificationStepViewController = (PhoneVerificationStepViewController *)viewController;
        ZMPhoneCredentials *credentials = [ZMPhoneCredentials credentialsWithPhoneNumber:phoneVerificationStepViewController.phoneNumber
                                                                        verificationCode:phoneVerificationStepViewController.verificationCode];
        
        self.showLoadingView = YES;
        [self.userProfile requestPhoneNumberChangeWithCredentials:credentials];
    }
}

#pragma mark - PhoneVerificationStepViewControllerDelegate

- (void)phoneVerificationStepDidRequestVerificationCode
{
    [self.userProfile requestPhoneVerificationCodeWithPhoneNumber:self.phoneNumberStepViewController.phoneNumber];
}

#pragma mark - NavigationControllerDelegate

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    id <UIViewControllerAnimatedTransitioning> transition = nil;
    
    switch (operation) {
        case UINavigationControllerOperationPop:
            transition = self.popTransition;
            break;
        case UINavigationControllerOperationPush:
            transition = self.pushTransition;
        default:
            break;
    }
    return transition;
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)note
{
    if (note.profileInformationChanged && ZMUser.selfUser.phoneNumber.length > 0) {
        self.showLoadingView = NO;
        
        [self.analyticsTracker tagVerifiedPhone];
        
        [self.formStepDelegate didCompleteFormStep:self];
    }
}

#pragma mark - UserProfileUpdateObserver


- (void)phoneNumberVerificationCodeRequestDidSucceed
{
    self.showLoadingView = NO;
    
    if (! [self.rootNavigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        [self proceedToCodeVerification];
    }
    else {
        [self.analyticsTracker tagResentPhoneVerification];
        [self presentViewController:[[CheckmarkViewController alloc] init] animated:YES completion:nil];
    }
}

- (void)proceedToCodeVerification
{
    PhoneVerificationStepViewController *phoneVerificationStepViewController = [[PhoneVerificationStepViewController alloc] init];
    phoneVerificationStepViewController.phoneNumber = self.phoneNumberStepViewController.phoneNumber;
    phoneVerificationStepViewController.formStepDelegate = self;
    phoneVerificationStepViewController.delegate = self;
    phoneVerificationStepViewController.isLoggingIn = NO;
    
    [self.rootNavigationController pushViewController:phoneVerificationStepViewController.registrationFormViewController animated:YES];
}

- (void)phoneNumberVerificationCodeRequestDidFail:(NSError *)error
{
    self.showLoadingView = NO;
    
    if (! [self.rootNavigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
        [self.analyticsTracker tagEnteredPhoneFailedWithError:error];
    } else {
        [self.analyticsTracker tagResentPhoneVerificationFailedWithError:error];
    }
    
    [self showAlertForError:error];
}

- (void)phoneNumberChangeDidFail:(NSError *)error
{
    self.showLoadingView = NO;
    [self.analyticsTracker tagVerifiedPhoneFailedWithError:error];
    [self showAlertForError:error];
}

@end
