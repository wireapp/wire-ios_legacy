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


#import "ProfileViewController.h"

#import "zmessaging+iOS.h"
#import "avs+iOS.h"


#import <WireExtensionComponents/WireExtensionComponents.h>
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>
#import <PureLayout/PureLayout.h>

#import "WAZUIMagicIOS.h"
#import "Constants.h"
#import "UIColor+WAZExtensions.h"
#import "UIColor+WR_ColorScheme.h"
#import "Wire-Swift.h"

#import "AddContactsViewController.h"
#import "ContactsDataSource.h"
#import "ProfileHeaderView.h"
#import "ProfileNavigationControllerDelegate.h"
#import "ProfileDevicesViewController.h"
#import "ProfileDetailsViewController.h"


typedef NS_ENUM(NSUInteger, ProfileViewControllerTabBarIndex) {
    ProfileViewControllerTabBarIndexDetails = 0,
    ProfileViewControllerTabBarIndexDevices
};


@interface ProfileViewController (AddContacts) <ContactsViewControllerDelegate>
@end


@interface ProfileViewController (ProfileViewControllerDelegate) <ProfileViewControllerDelegate>
@end


@interface ProfileViewController (ProfileDetailsViewControllerDelegate) <ProfileDetailsViewControllerDelegate>
@end


@interface ProfileViewController (DevicesListDelegate) <ProfileDevicesViewControllerDelegate>
@end


@interface ProfileViewController (TabBarControllerDelegate) <TabBarControllerDelegate>
@end



@interface ProfileViewController () <ZMUserObserver>

@property (nonatomic, readonly) ProfileViewControllerContext context;
@property (nonatomic, readonly) ZMConversation *conversation;

@property (nonatomic) id <ZMUserObserverOpaqueToken> observerToken;
@property (nonatomic) ProfileHeaderView *headerView;
@property (nonatomic) TabBarController *tabsController;

@end



@implementation ProfileViewController

- (id)initWithUser:(id<ZMBareUser>)user context:(ProfileViewControllerContext)context
{
    return [self initWithUser:user conversation:nil context:context];
}

- (id)initWithUser:(id<ZMBareUser>)user conversation:(ZMConversation *)conversation
{
    if (conversation.conversationType == ZMConversationTypeGroup) {
        return [self initWithUser:user conversation:conversation context:ProfileViewControllerContextGroupConversation];
    }
    else {
        return [self initWithUser:user conversation:conversation context:ProfileViewControllerContextOneToOneConversation];
    }
}

- (id)initWithUser:(id<ZMBareUser>)user conversation:(ZMConversation *)conversation context:(ProfileViewControllerContext)context
{
    if (self = [super init]) {
        _bareUser = user;
        _conversation = conversation;
        _context = context;
        _navigationControllerDelegate = [[ProfileNavigationControllerDelegate alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.delegate = self.navigationControllerDelegate;
    
    if (nil != self.fullUser) {
        self.observerToken = [ZMUser addUserObserver:self forUsers:@[self.fullUser] inUserSession:[ZMUserSession sharedSession]];
    }
    
    [self setupHeader];
    [self setupTabsController];
    [self setupConstraints];
    [self updateShowVerifiedShield];
}

- (void)dealloc
{
    [ZMUser removeUserObserverForToken:self.observerToken];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dismissButtonClicked
{
    [self requestDismissalWithCompletion:nil];
}

- (void)requestDismissalWithCompletion:(dispatch_block_t)completion
{
    if ([self.delegate respondsToSelector:@selector(profileViewControllerWantsToBeDismissed:completion:)]) {
        [self.delegate profileViewControllerWantsToBeDismissed:self completion:completion];
    }
}

- (void)setupTabsController
{
    NSMutableArray *viewControllers = [NSMutableArray array];
    
    if (self.context != ProfileViewControllerContextDeviceList) {
        ProfileDetailsViewController *profileDetailsViewController = [[ProfileDetailsViewController alloc] initWithUser:self.bareUser conversation:self.conversation context:self.context];
        profileDetailsViewController.delegate = self;
        profileDetailsViewController.title = NSLocalizedString(@"profile.details.title", nil);
        [viewControllers addObject:profileDetailsViewController];
    }
    
    if (self.fullUser.isConnected) {
        ProfileDevicesViewController *profileDevicesViewController = [[ProfileDevicesViewController alloc] initWithUser:self.fullUser];
        profileDevicesViewController.title = NSLocalizedString(@"profile.devices.title", nil);
        profileDevicesViewController.delegate = self;
        [viewControllers addObject:profileDevicesViewController];
    }

    self.tabsController = [[TabBarController alloc] initWithViewControllers:viewControllers];
    self.tabsController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabsController.delegate = self;
    [self addChildViewController:self.tabsController];
    [self.view addSubview:self.tabsController.view];
    [self.tabsController didMoveToParentViewController:self];
}

- (void)setupConstraints
{
    [self.headerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.tabsController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.tabsController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.headerView];
}

#pragma mark - Header

- (void)setupHeader
{
    ZMUser *user = [self fullUser];
    
    ProfileHeaderStyle headerStyle = ProfileHeaderStyleCancelButton;
    if (IS_IPAD) {
        if (self.navigationController.viewControllers.count > 1) {
            headerStyle = ProfileHeaderStyleBackButton;
        } else if (self.context != ProfileViewControllerContextDeviceList) {
            headerStyle = ProfileHeaderStyleNoButton; // no button in 1:1 profile popover
        }
    }
        
    ProfileHeaderView *headerView = [[ProfileHeaderView alloc] initWithHeaderStyle:headerStyle];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [headerView.dismissButton addTarget:self action:@selector(dismissButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    if (user != nil) {
        headerView.titleLabel.attributedText = [self attributedStringForTitle:user.name];
        NSString *akaForUser = user.contact.name;
        if ([akaForUser caseInsensitiveCompare:user.name] == NSOrderedSame) {
            akaForUser = nil;
        }
        NSString *akaString = akaForUser;
        headerView.akaLabel.attributedText = akaForUser ? [self attributedStringForAka:akaString] : nil;
    }
    else {
        headerView.titleLabel.attributedText = [self attributedStringForTitle:self.bareUser.displayName];
    }
    
    if ((user.isConnected || user.isPendingApprovalBySelfUser || user.isSelfUser || user.isBlocked) && user.emailAddress.length != 0) {
        headerView.subtitleLabel.attributedText = [self attributedStringForSubtitle:[user.emailAddress uppercasedWithCurrentLocale]];
    }
    
    [self.view addSubview:headerView];
    self.headerView = headerView;
}

- (NSAttributedString *)attributedStringForTitle:(NSString *)title
{
    if (title == nil) {
        return nil;
    }
    return [[NSAttributedString alloc] initWithString:title
                                           attributes:@{ NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_bold"]}];
}

- (NSAttributedString *)attributedStringForAka:(NSString *)aka
{
    if (aka == nil) {
        return nil;
    }
    
    return [[NSAttributedString alloc] initWithString:aka
                                           attributes:@{ NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"],
                                                         NSForegroundColorAttributeName: [UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed] }];
}

- (NSAttributedString *)attributedStringForSubtitle:(NSString *)subtitle
{
    if (subtitle == nil) {
        return nil;
    }
    
    return [[NSAttributedString alloc] initWithString:subtitle
                                           attributes:@{ NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"],
                                                         NSForegroundColorAttributeName: [UIColor accentColor] }];
}

#pragma mark - User observation

- (void)updateShowVerifiedShield
{
    ZMUser *user = [self fullUser];
    if (nil != user) {
        BOOL showShield = user.trusted && user.clients.count > 0 &&
                        self.context != ProfileViewControllerContextDeviceList &&
                        self.tabsController.selectedIndex != ProfileViewControllerTabBarIndexDevices;

        self.headerView.showVerifiedShield = showShield;
    }
}

- (void)userDidChange:(UserChangeInfo *)note
{
    if (note.trustLevelChanged) {
        [self updateShowVerifiedShield];
    }
}

#pragma mark - Utilities

- (ZMUser *)fullUser
{
    if ([self.bareUser isKindOfClass:[ZMUser class]]) {
        return (ZMUser *)self.bareUser;
    }
    else if ([self.bareUser isKindOfClass:[ZMSearchUser class]]) {
        ZMSearchUser *searchUser = (ZMSearchUser *)self.bareUser;
        return [searchUser user];
    }
    return nil;
}

@end



@implementation ProfileViewController (AddContacts)

- (void)contactsViewControllerDidCancel:(ContactsViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactsViewControllerDidConfirmSelection:(ContactsViewController *)controller
{
    NSOrderedSet *selectedUsers = [controller.dataSource.selection valueForKey:@"user"];
    
    [controller dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(profileViewController:wantsToAddUsers:toConversation:)]) {
            [self.delegate profileViewController:self wantsToAddUsers:selectedUsers.set toConversation:self.conversation];
        }
    }];
}

@end


@implementation ProfileViewController (ProfileViewControllerDelegate)

- (void)profileViewController:(ProfileViewController *)controller wantsToNavigateToConversation:(ZMConversation *)conversation
{
    if ([self.delegate respondsToSelector:@selector(profileViewController:wantsToNavigateToConversation:)]) {
        [self.delegate profileViewController:controller wantsToNavigateToConversation:conversation];
    }
}

- (void)profileViewControllerWantsToBeDismissed:(ProfileViewController *)controller completion:(dispatch_block_t)completion
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)suggestedBackButtonTitleForProfileViewController:(id)controller
{
    return [self.bareUser.displayName uppercasedWithCurrentLocale];
}

@end


@implementation ProfileViewController (ProfileDetailsViewControllerDelegate)

- (void)profileDetailsViewController:(ProfileDetailsViewController *)profileDetailsViewController didTapOnCommonConnection:(ZMUser *)connection
{
    ProfileViewController *commonProfileController = [[ProfileViewController alloc] initWithUser:connection context:ProfileViewControllerContextCommonConnection];
    commonProfileController.delegate = self;
    commonProfileController.navigationControllerDelegate = self.navigationControllerDelegate;
    self.navigationControllerDelegate.tapLocation = self.view.center;
    [self.navigationController pushViewController:commonProfileController animated:YES];
}

- (void)profileDetailsViewController:(ProfileDetailsViewController *)profileDetailsViewController didSelectConversation:(ZMConversation *)conversation
{
    if ([self.delegate respondsToSelector:@selector(profileViewController:wantsToNavigateToConversation:)]) {
        [self.delegate profileViewController:self wantsToNavigateToConversation:conversation];
    }
}

- (void)profileDetailsViewController:(ProfileDetailsViewController *)profileDetailsViewController didPresentAddContactsViewController:(AddContactsViewController *)addContactsViewController
{
    addContactsViewController.delegate = self;
}

- (void)profileDetailsViewController:(ProfileDetailsViewController *)profileDetailsViewController wantsToBeDismissedWithCompletion:(dispatch_block_t)completion
{
    if ([self.delegate respondsToSelector:@selector(profileViewControllerWantsToBeDismissed:completion:)]) {
        [self.delegate profileViewControllerWantsToBeDismissed:self completion:completion];
    } else if (completion != nil) {
        completion();
    }
}

@end

@implementation ProfileViewController (DevicesListDelegate)

- (void)profileDevicesViewController:(ProfileDevicesViewController *)profileDevicesViewController didTapDetailForClient:(UserClient *)client
{
    ProfileClientViewController *userClientDetailController = [[ProfileClientViewController alloc] initWithClient:client fromConversation:YES];
    [self presentViewController:userClientDetailController animated:YES completion:nil];
}

@end

@implementation ProfileViewController (TabBarControllerDelegate)

- (void)tabBarController:(TabBarController *)controller tabBarDidSelectIndex:(NSInteger)index
{
    if ([controller.viewControllers[index] isKindOfClass:[ProfileDevicesViewController  class]]) {
        [[Analytics shared] tagOtherDeviceList];
    }
    [self updateShowVerifiedShield];
}

@end
