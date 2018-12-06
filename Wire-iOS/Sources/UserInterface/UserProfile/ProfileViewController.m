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
#import "ProfileViewController+internal.h"

#import "WireSyncEngine+iOS.h"
#import "avs+iOS.h"


@import WireExtensionComponents;
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>
@import PureLayout;

#import "Constants.h"
#import "UIColor+WAZExtensions.h"
#import "Wire-Swift.h"

#import "ContactsDataSource.h"
#import "ProfileDevicesViewController.h"
#import "ProfileDetailsViewController.h"


typedef NS_ENUM(NSUInteger, ProfileViewControllerTabBarIndex) {
    ProfileViewControllerTabBarIndexDetails = 0,
    ProfileViewControllerTabBarIndexDevices
};



@interface ProfileViewController (ProfileViewControllerDelegate) <ProfileViewControllerDelegate>
@end

@interface ProfileViewController (ViewControllerDismisser) <ViewControllerDismisser>
@end

@interface ProfileViewController (ProfileDetailsViewControllerDelegate) <ProfileDetailsViewControllerDelegate>
@end

@interface ProfileViewController (DevicesListDelegate) <ProfileDevicesViewControllerDelegate>
@end

@interface ProfileViewController (TabBarControllerDelegate) <TabBarControllerDelegate>
@end

@interface ProfileViewController (ConversationCreationDelegate) <ConversationCreationControllerDelegate>
@end



@interface ProfileViewController () <ZMUserObserver>

@property (nonatomic, readonly) ZMConversation *conversation;
@property (nonatomic) id observerToken;
@property (nonatomic) UserNameDetailView *usernameDetailsView;
@property (nonatomic) ProfileTitleView *profileTitleView;
@property (nonatomic) TabBarController *tabsController;

@end



@implementation ProfileViewController

- (id)initWithUser:(id<UserType, AccentColorProvider>)user context:(ProfileViewControllerContext)context
{
    return [self initWithUser:user conversation:nil context:context];
}

- (id)initWithUser:(id<UserType, AccentColorProvider>)user conversation:(ZMConversation *)conversation
{
    if (conversation.conversationType == ZMConversationTypeGroup) {
        return [self initWithUser:user conversation:conversation context:ProfileViewControllerContextGroupConversation];
    }
    else {
        return [self initWithUser:user conversation:conversation context:ProfileViewControllerContextOneToOneConversation];
    }
}

- (id)initWithUser:(id<UserType, AccentColorProvider>)user conversation:(ZMConversation *)conversation context:(ProfileViewControllerContext)context
{
    if (self = [super init]) {
        _bareUser = user;
        _conversation = conversation;
        _context = context;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [[ColorScheme defaultColorScheme] statusBarStyle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.delegate = self.navigationControllerDelegate;
    self.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorBarBackground];
    
    if (nil != self.fullUser && nil != [ZMUserSession sharedSession]) {
        self.observerToken = [UserChangeInfo addObserver:self forUser:self.fullUser userSession:[ZMUserSession sharedSession]];
    }
    
    [self setupNavigationItems];
    [self setupHeader];
    [self setupTabsController];
    [self setupConstraints];
    [self updateShowVerifiedShield];
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
    if ([self.delegate respondsToSelector:@selector(dismissViewController:completion:)]) {
        [self.viewControllerDismisser dismissViewController:self completion:completion];
    }
}

- (void)setupNavigationItems
{
    if (self.navigationController.viewControllers.count == 1) {
        self.navigationItem.rightBarButtonItem = [self.navigationController closeItem];
    }
}

- (void)setupTabsController
{
    NSMutableArray *viewControllers = [NSMutableArray array];
    
    if (self.context != ProfileViewControllerContextDeviceList) {
        ProfileDetailsViewController *profileDetailsViewController = [[ProfileDetailsViewController alloc] initWithUser:self.bareUser conversation:self.conversation context:self.context];
        profileDetailsViewController.delegate = self;
        profileDetailsViewController.viewControllerDismisser = self;
        profileDetailsViewController.title = NSLocalizedString(@"profile.details.title", nil);
        [viewControllers addObject:profileDetailsViewController];
    }
    
    if (self.fullUser.isConnected || self.fullUser.isTeamMember || self.fullUser.isWirelessUser) {
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
    [self.usernameDetailsView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.tabsController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.tabsController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.usernameDetailsView];
}

#pragma mark - Header

- (void)setupHeader
{
    id<UserType> user = self.bareUser;
    
    UserNameDetailViewModel *viewModel = [[UserNameDetailViewModel alloc] initWithUser:user fallbackName:user.displayName addressBookName:BareUserToUser(user).addressBookEntry.cachedName];
    UserNameDetailView *usernameDetailsView = [[UserNameDetailView alloc] init];
    usernameDetailsView.translatesAutoresizingMaskIntoConstraints = NO;
    [usernameDetailsView configureWith:viewModel];
    [self.view addSubview:usernameDetailsView];
    self.usernameDetailsView = usernameDetailsView;
    
    ProfileTitleView *titleView = [[ProfileTitleView alloc] init];
    [titleView configureWithViewModel:viewModel];
    
    if (@available(iOS 11, *)) {
        titleView.translatesAutoresizingMaskIntoConstraints = NO;
        self.navigationItem.titleView = titleView;
    } else {
        titleView.translatesAutoresizingMaskIntoConstraints = NO;
        [titleView setNeedsLayout];
        [titleView layoutIfNeeded];
        titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        titleView.translatesAutoresizingMaskIntoConstraints = YES;
    }
    
    self.navigationItem.titleView = titleView;
    self.profileTitleView = titleView;
}

#pragma mark - User observation

- (void)updateShowVerifiedShield
{
    ZMUser *user = [self fullUser];
    if (nil != user) {
        BOOL showShield = user.trusted && user.clients.count > 0
                       && self.context != ProfileViewControllerContextDeviceList
                       && self.tabsController.selectedIndex != ProfileViewControllerTabBarIndexDevices
                       && ZMUser.selfUser.trusted;

        self.profileTitleView.showVerifiedShield = showShield;
    }
    else {
        self.profileTitleView.showVerifiedShield = NO;
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


@implementation ProfileViewController (ViewControllerDismisser)

- (void)dismissViewController:(UIViewController *)controller completion:(dispatch_block_t)completion
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation ProfileViewController (ProfileViewControllerDelegate)

- (void)profileViewController:(ProfileViewController *)controller wantsToNavigateToConversation:(ZMConversation *)conversation
{
    if ([self.delegate respondsToSelector:@selector(profileViewController:wantsToNavigateToConversation:)]) {
        [self.delegate profileViewController:controller wantsToNavigateToConversation:conversation];
    }
}

- (NSString *)suggestedBackButtonTitleForProfileViewController:(id)controller
{
    return [self.bareUser.displayName uppercasedWithCurrentLocale];
}

@end


@implementation ProfileViewController (ProfileDetailsViewControllerDelegate)

- (void)profileDetailsViewController:(ProfileDetailsViewController *)profileDetailsViewController didSelectConversation:(ZMConversation *)conversation
{
    if ([self.delegate respondsToSelector:@selector(profileViewController:wantsToNavigateToConversation:)]) {
        [self.delegate profileViewController:self wantsToNavigateToConversation:conversation];
    }
}

- (void)profileDetailsViewController:(ProfileDetailsViewController *)profileDetailsViewController didPresentConversationCreationController:(ConversationCreationController *)conversationCreationController
{
    conversationCreationController.delegate = self;
}

- (void)profileDetailsViewController:(ProfileDetailsViewController *)profileDetailsViewController wantsToBeDismissedWithCompletion:(dispatch_block_t)completion
{
    if ([self.delegate respondsToSelector:@selector(dismissViewController:completion:)]) {
        [self.viewControllerDismisser dismissViewController:self completion:completion];
    } else if (completion != nil) {
        completion();
    }
}

@end


@implementation ProfileViewController (ConversationCreationDelegate)

- (void)conversationCreationController:(ConversationCreationController *)controller didSelectName:(NSString *)name participants:(NSSet<ZMUser *> *)participants allowGuests:(BOOL)allowGuests enableReceipts:(BOOL)enableReceipts
{
    [controller dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(profileViewController:wantsToCreateConversationWithName:users:)]) {
            [self.delegate profileViewController:self wantsToCreateConversationWithName:name users:participants];
        }
    }];
}

@end


@implementation ProfileViewController (DevicesListDelegate)

- (void)profileDevicesViewController:(ProfileDevicesViewController *)profileDevicesViewController didTapDetailForClient:(UserClient *)client
{
    ProfileClientViewController *userClientDetailController = [[ProfileClientViewController alloc] initWithClient:client fromConversation:YES];
    userClientDetailController.showBackButton = NO;
    [self.navigationController pushViewController:userClientDetailController animated:YES];
}

@end


@implementation ProfileViewController (TabBarControllerDelegate)

- (void)tabBarController:(TabBarController *)controller tabBarDidSelectIndex:(NSInteger)index
{
    [self updateShowVerifiedShield];
}

@end
