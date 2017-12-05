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


#import "RegistrationEmailFlowViewController.h"

@import PureLayout;

#import "EmailStepViewController.h"
#import "EmailVerificationStepViewController.h"
#import "ProfilePictureStepViewController.h"
#import "RegistrationFormController.h"
#import "TermsOfUseStepViewController.h"
#import "UIViewController+Errors.h"
#import "Analytics.h"
#import "NavigationController.h"
#import "AppDelegate.h"

#import "AnalyticsTracker+Registration.h"

#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

@interface RegistrationEmailFlowViewController () <FormStepDelegate, EmailVerificationStepViewControllerDelegate, ZMRegistrationObserver, PreLoginAuthenticationObserver>

@property (nonatomic) BOOL hasUserAcceptedTOS;

@property (nonatomic) EmailStepViewController *emailStepViewController;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) id<ZMRegistrationObserverToken> registrationToken;
@property (nonatomic) id authenticationToken;

@end

@implementation RegistrationEmailFlowViewController

- (void)dealloc
{
    [self removeObservers];
}

- (void)removeObservers
{
    self.authenticationToken = nil;
    self.registrationToken = nil;
}

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.title = NSLocalizedString(@"registration.title", @"");
        self.unregisteredUser = unregisteredUser;
        
        self.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:AnalyticsContextRegistrationEmail];
    }

    return self;
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    if (parent && self.authenticationToken == nil && self.registrationToken == nil) {
        self.authenticationToken = [PreLoginAuthenticationNotification registerObserver:self
                                                              forUnauthenticatedSession:[SessionManager shared].unauthenticatedSession];
        self.registrationToken = [[UnauthenticatedSession sharedSession] addRegistrationObserver:self];
    } else {
        [self removeObservers];
    }
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupNavigationController];

    self.view.opaque = NO;
}

- (void)takeFirstResponder
{
    [self.emailStepViewController takeFirstResponder];
}

- (void)setupNavigationController
{
    self.emailStepViewController = [[EmailStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
    self.emailStepViewController.formStepDelegate = self;
    self.emailStepViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    RegistrationFormController *formController = self.emailStepViewController.registrationFormViewController;

    [self addChildViewController:formController];
    [self.view addSubview:formController.view];
    [formController didMoveToParentViewController:self];
    [formController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (void)presentProfilePictureStep
{
    ProfilePictureStepViewController *pictureStepViewController = [[ProfilePictureStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
    pictureStepViewController.analyticsTracker = self.analyticsTracker;
    pictureStepViewController.formStepDelegate = self;
    
    self.wr_navigationController.backButtonEnabled = NO;
    [self.navigationController pushViewController:pictureStepViewController animated:YES];
}

#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[EmailStepViewController class]] ) {
        
        [self.analyticsTracker tagEnteredEmailAndPassword];

        // Dismiss keyboard and delay presentation for a smoother transition
        [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            TermsOfUseStepViewController *tosController = [[TermsOfUseStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
            tosController.formStepDelegate = self;
            [self.navigationController pushViewController:tosController.registrationFormViewController animated:YES];
        });
    }
    else if ([viewController isKindOfClass:[TermsOfUseStepViewController class]] ||
             ([viewController isKindOfClass:[EmailStepViewController class]] && [self hasUserAcceptedTOS]))
    {
        [self.analyticsTracker tagAcceptedTermsOfUse];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
        self.hasUserAcceptedTOS = YES;
        
        ZMCompleteRegistrationUser *completeUser = [self.unregisteredUser completeRegistrationUser];
        [[UnauthenticatedSession sharedSession] registerUser:completeUser];
        
        EmailVerificationStepViewController *emailVerificationStepViewController = [[EmailVerificationStepViewController alloc] initWithEmailAddress:self.unregisteredUser.emailAddress];
        emailVerificationStepViewController.formStepDelegate = self;
        emailVerificationStepViewController.delegate = self;
        emailVerificationStepViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.navigationController pushViewController:emailVerificationStepViewController.registrationFormViewController animated:YES];
    }
    else if ([viewController isKindOfClass:[ProfilePictureStepViewController class]]) {
        ProfilePictureStepViewController *step = (ProfilePictureStepViewController *)viewController;
        [self.analyticsTracker tagAddedPhotoFromSource:step.photoSource];
        [self.formStepDelegate didCompleteFormStep:self];
    }
}

- (void)didSkipFormStep:(UIViewController *)viewController
{
    [self.formStepDelegate didCompleteFormStep:self];
}

#pragma mark - EmailVerificationStepViewControllerDelegate

- (void)emailVerificationStepDidRequestVerificationEmail
{
    [[UnauthenticatedSession sharedSession] resendRegistrationVerificationEmail];
    [self.analyticsTracker tagResentEmailVerification];
}

#pragma mark - ZMRegistrationObserver

- (void)registrationDidFail:(NSError *)error
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self showAlertForError:error];
}

- (void)emailVerificationDidFail:(NSError *)error
{
    [self.analyticsTracker tagResentEmailVerificationFailedWithError:error];
    [self showAlertForError:error];
}

- (void)emailVerificationDidSucceed
{
    // nop
}

#pragma mark - ZMAuthenticationObserver

- (void)authenticationDidSucceed
{
    [self.analyticsTracker tagRegistrationSucceded];
    [self presentProfilePictureStep];
}

@end
