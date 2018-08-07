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


#import "AddEmailPasswordViewController.h"

@import PureLayout;
#import <WireExtensionComponents/UIViewController+LoadingView.h>


#import "AddEmailStepViewController.h"
#import "EmailVerificationStepViewController.h"
#import "RegistrationFormController.h"
#import "PopTransition.h"
#import "PushTransition.h"
#import "NavigationController.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
#import "UIImage+ZetaIconsNeue.h"
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface AddEmailPasswordViewController () <FormStepDelegate, UINavigationControllerDelegate, EmailVerificationStepViewControllerDelegate, UserProfileUpdateObserver, ZMUserObserver>

@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) AddEmailStepViewController *addEmailStepViewController;
@property (nonatomic) PopTransition *popTransition;
@property (nonatomic) PushTransition *pushTransition;
@property (nonatomic) id userEditingToken;
@property (nonatomic) id userObserverToken;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) ZMEmailCredentials *credentials;
@property (nonatomic, weak) id<UserProfile> userProfile;

@end

@interface AddEmailStepViewController (RegistrationObserver) <ZMRegistrationObserver>
@end

@implementation AddEmailPasswordViewController

@synthesize authenticationCoordinator;

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

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.popTransition = [[PopTransition alloc] init];
    self.pushTransition = [[PushTransition alloc] init];

    [self createNavigationController];
    [self createCloseButton];
    
    if (self.skipButtonType == AddEmailPasswordViewControllerSkipButtonTypeClose) {
        self.closeButton.hidden = NO;
    }
    
    [self updateViewConstraints];
    
    self.view.opaque = NO;
}

- (void)createNavigationController
{
    self.addEmailStepViewController = [[AddEmailStepViewController alloc] init];
    self.addEmailStepViewController.formStepDelegate = self;
    self.addEmailStepViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self addChildViewController:self.addEmailStepViewController];
    [self.view addSubview:self.addEmailStepViewController.view];
    [self.addEmailStepViewController didMoveToParentViewController:self];
}

- (void)setShowsNavigationBar:(BOOL)showsNavigationBar
{
    _showsNavigationBar = showsNavigationBar;
    self.wr_navigationController.backButtonEnabled = self.showsNavigationBar;
    self.wr_navigationController.rightButtonEnabled = self.showsNavigationBar;
    self.wr_navigationController.logoEnabled = self.showsNavigationBar;
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


- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.addEmailStepViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        
        [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:32];
        [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:28];
    }
}

#pragma mark - Actions

- (IBAction)skip:(id)sender
{
    if ([self.formStepDelegate respondsToSelector:@selector(didSkipFormStep:)]) {
        [self.formStepDelegate didSkipFormStep:self];
    }
}

#pragma mark - RegistrationStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[AddEmailStepViewController class]]) {
        AddEmailStepViewController *addEmailStepViewController = (AddEmailStepViewController *)viewController;
        
        self.credentials = [ZMEmailCredentials credentialsWithEmail:addEmailStepViewController.emailAddress
                                                           password:addEmailStepViewController.password];

        NSError *error;
        [self.userProfile requestSettingEmailAndPasswordWithCredentials:self.credentials error:&error];
        BOOL result = [[SessionManager shared] updateWithCredentials:self.credentials];

        if (nil != error || result == NO) {
            ZMLogError(@"Error requesting to set email and password: %@", error);
        } else {
            self.showLoadingView = YES;
        }
    }
}

#pragma mark - EmailVerificationStepViewControllerDelegate

- (void)emailVerificationStepDidRequestVerificationEmail
{
    NSError *error;
    [self.userProfile requestSettingEmailAndPasswordWithCredentials:self.credentials error:&error];

    if (nil != error) {
        ZMLogError(@"Error requesting to set email and password: %@", error);
    }
}

#pragma mark ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)note
{
    if (note.profileInformationChanged && ZMUser.selfUser.emailAddress.length > 0) {
        [self.formStepDelegate didCompleteFormStep:self];
    }
}

#pragma mark - UserProfileUpdateObserver

- (void)didSentVerificationEmail
{
    self.showLoadingView = NO;
    
    // Credentials can be nil if you requested a verification e-mail and then closed and re-opened the add-email view controller.
    if (self.credentials != nil) {
        EmailVerificationStepViewController *emailVerificationStepViewController = [[EmailVerificationStepViewController alloc] initWithEmailAddress:self.credentials.email];
        emailVerificationStepViewController.formStepDelegate = self;
        emailVerificationStepViewController.registrationNavigationController = self.wr_navigationController;
        emailVerificationStepViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.wr_navigationController pushViewController:emailVerificationStepViewController.registrationFormViewController animated:YES];
    }
}

- (void)emailUpdateDidFail:(NSError *)error
{
    self.showLoadingView = NO;
    
    @weakify(self);
    
    [self showAlertForError:error handler:^(UIAlertAction *action) {
        @strongify(self);
        if ([error.domain isEqualToString:NSError.ZMUserSessionErrorDomain] && error.code == ZMUserSessionEmailIsAlreadyRegistered) {
            [self.addEmailStepViewController clearFields:nil];
        }
    }];
}

- (void)passwordUpdateRequestDidFail
{
    self.showLoadingView = NO;
    
    [self showAlertForMessage:NSLocalizedString(@"error.updating_password", nil)];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
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

@end
