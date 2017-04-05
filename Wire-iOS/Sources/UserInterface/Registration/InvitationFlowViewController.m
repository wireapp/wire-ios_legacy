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


#import "InvitationFlowViewController.h"

#import <PureLayout/PureLayout.h>

#import "PopTransition.h"
#import "PushTransition.h"
#import "NavigationController.h"
#import "RegistrationFormController.h"
#import "EmailInvitationStepViewController.h"
#import "PhoneInvitationStepViewController.h"
#import "TermsOfUseStepViewController.h"
#import "ProfilePictureStepViewController.h"
#import "UIViewController+Errors.h"
#import "ZMUserSession+Additions.h"
#import "RegistrationViewController.h"
#import "WireSyncEngine+iOS.h"
#import "Constants.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker+Registration.h"


typedef NS_ENUM(NSUInteger, InvitationFlow) {
    InvitationFlowEmail,
    InvitationFlowPhone
};



@interface InvitationFlowViewController () <FormStepDelegate, ZMRegistrationObserver, ZMAuthenticationObserver>

@property (nonatomic) RegistrationStepViewController *registrationStepViewController;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) id<ZMRegistrationObserverToken> registrationToken;
@property (nonatomic) id<ZMAuthenticationObserverToken> authenticationToken;
@property (nonatomic, readonly) InvitationFlow invitationFlow;

@end

@implementation InvitationFlowViewController

- (void)dealloc
{
    [self removeObservers];
}

- (void)removeObservers
{
    [[ZMUserSession sharedSession] removeRegistrationObserverForToken:self.registrationToken];
    [[ZMUserSession sharedSession] removeAuthenticationObserverForToken:self.authenticationToken];
    
    self.registrationToken = nil;
    self.authenticationToken = nil;
}

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.unregisteredUser = unregisteredUser;
        NSString *context = (self.invitationFlow == InvitationFlowEmail) ? AnalyticsContextRegistrationPersonalInviteEmail : AnalyticsContextRegistrationPersonalInvitePhone;
        self.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:context];
        self.registrationToken = [[ZMUserSession sharedSession] addRegistrationObserver:self];
        self.authenticationToken = [[ZMUserSession sharedSession] addAuthenticationObserver:self];
        
        if (self.invitationFlow == InvitationFlowEmail) {
            [self.analyticsTracker tagOpenedEmailRegistration];
        } else {
            [self.analyticsTracker tagOpenedPhoneRegistration];
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self createInvitationStepViewController];
    [self createInitialConstraints];
    
    self.view.opaque = NO;
    self.formStepDelegate = self;
    self.title = NSLocalizedString(@"registration.email_flow.title", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.wr_navigationController updateRightButtonWithTitle:[self closeInvitationButtonTitle] target:self action:@selector(closeInvitation) animated:animated];
}

- (void)createInvitationStepViewController
{
    self.registrationStepViewController = [self invitationStepViewController];
    
    [self addChildViewController:self.registrationStepViewController];
    [self.view addSubview:self.registrationStepViewController.view];
    [self.registrationStepViewController didMoveToParentViewController:self];
}

- (RegistrationStepViewController *)invitationStepViewController
{
    if (self.invitationFlow == InvitationFlowEmail) {
        EmailInvitationStepViewController *emailInvitationStepViewController = [[EmailInvitationStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
        emailInvitationStepViewController.formStepDelegate = self;
        emailInvitationStepViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        return emailInvitationStepViewController;
    } else {
        PhoneInvitationStepViewController *phoneInvitationStepViewController = [[PhoneInvitationStepViewController alloc ] initWithUnregisteredUser:self.unregisteredUser];
        phoneInvitationStepViewController.formStepDelegate = self;
        phoneInvitationStepViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        return phoneInvitationStepViewController;
    }
}

- (void)presentProfilePictureStep
{
    ProfilePictureStepViewController *pictureStepViewController = [[ProfilePictureStepViewController alloc] initWithEditableUser:[ZMUser editableSelfUser]];
    pictureStepViewController.analyticsTracker = self.analyticsTracker;
    pictureStepViewController.formStepDelegate = self;
    
    [self.navigationController pushViewController:pictureStepViewController animated:YES];
}

- (InvitationFlow)invitationFlow
{
    return self.unregisteredUser.emailAddress.length > 0 ? InvitationFlowEmail : InvitationFlowPhone;
}

- (void)createInitialConstraints
{
    [self.registrationStepViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (NSString *)closeInvitationButtonTitle
{
    NSString *buttonTitle = nil;
    
    if (self.invitationFlow == InvitationFlowEmail) {
        if ([RegistrationViewController registrationFlow] == RegistrationFlowEmail) {
            buttonTitle = NSLocalizedString(@"registration.close_email_invitation_button.email_title", nil);
        } else {
            buttonTitle = NSLocalizedString(@"registration.close_email_invitation_button.phone_title", nil);
        }
    } else {
        if ([RegistrationViewController registrationFlow] == RegistrationFlowPhone) {
            buttonTitle = NSLocalizedString(@"registration.close_phone_invitation_button.phone_title", nil);
        } else {
            buttonTitle = NSLocalizedString(@"registration.close_phone_invitation_button.email_title", nil);
        }
    }
    
    return buttonTitle;
}

#pragma mark - Actions

- (void)closeInvitation
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self.analyticsTracker tagRegistrationCancelledPersonalInvite];
}

#pragma mark - FormStepDelegate

- (void)formStep:(UIViewController *)formStep willMoveToStep:(UIViewController *)viewController
{
    BOOL isEmailInvitationStep = [viewController isKindOfClass:[EmailInvitationStepViewController class]];
    BOOL isPhoneInvitationStep = [viewController isKindOfClass:[PhoneInvitationStepViewController class]];
    BOOL isFirstStep = isEmailInvitationStep || isPhoneInvitationStep;
    
    [self.wr_navigationController setRightButtonEnabled:isFirstStep];
}

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[EmailInvitationStepViewController class]] || [viewController isKindOfClass:[PhoneInvitationStepViewController class]]) {
        TermsOfUseStepViewController *tosController = [[TermsOfUseStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
        tosController.formStepDelegate = self;
        [self.navigationController pushViewController:tosController.registrationFormViewController animated:YES];
        
        [self.analyticsTracker tagRegistrationConfirmedPersonalInvite];
    }
    else if ([viewController isKindOfClass:[TermsOfUseStepViewController class]])
    {
        [[ZMUserSession sharedSession] checkNetworkAndFlashIndicatorIfNecessary];
        
        if ([ZMUserSession sharedSession].networkState != ZMNetworkStateOffline) {
            [[ZMUserSession sharedSession] registerSelfUser:self.unregisteredUser.completeRegistrationUser];
        }
    }
    else if ([viewController isKindOfClass:[ProfilePictureStepViewController class]]) {
        [self.formStepDelegate didCompleteFormStep:self];
    }
}

#pragma mark - ZMRegistrationObserver

- (void)registrationDidFail:(NSError *)error
{
    [self showAlertForError:error];
}

#pragma mark - ZMAuthenticationObserver

- (void)authenticationDidSucceed
{
    [self presentProfilePictureStep];
}

@end
