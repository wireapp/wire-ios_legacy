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
#import "AccentColorProvider.h"


@import PureLayout;

#import "Constants.h"
#import "UIColor+WAZExtensions.h"
#import "Wire-Swift.h"

#import "ContactsDataSource.h"
#import "ProfileDevicesViewController.h"


typedef NS_ENUM(NSUInteger, ProfileViewControllerTabBarIndex) {
    ProfileViewControllerTabBarIndexDetails = 0,
    ProfileViewControllerTabBarIndexDevices
};



@interface ProfileViewController (ProfileViewControllerDelegate) <ProfileViewControllerDelegate>
@end

@interface ProfileViewController (DevicesListDelegate) <ProfileDevicesViewControllerDelegate>
@end

@interface ProfileViewController (TabBarControllerDelegate) <TabBarControllerDelegate>
@end

@interface ProfileViewController (ConversationCreationDelegate) <ConversationCreationControllerDelegate>
@end


@interface ProfileViewController () <ZMUserObserver>

@property (nonatomic) id observerToken;
@property (nonatomic) UserNameDetailView *usernameDetailsView;
@property (nonatomic) ProfileTitleView *profileTitleView;
@property (nonatomic) TabBarController *tabsController;

@end



@implementation ProfileViewController

- (id)initWithUser:(id<UserType, AccentColorProvider>)user viewer:(id<UserType, AccentColorProvider>)viewer context:(ProfileViewControllerContext)context
{
    return [self initWithUser:user viewer:viewer conversation:nil context:context];
}

- (id)initWithUser:(id<UserType, AccentColorProvider>)user viewer:(id<UserType, AccentColorProvider>)viewer conversation:(ZMConversation *)conversation
{
    if (conversation.conversationType == ZMConversationTypeGroup) {
        return [self initWithUser:user viewer:viewer conversation:conversation context:ProfileViewControllerContextGroupConversation];
    }
    else {
        return [self initWithUser:user viewer:viewer conversation:conversation context:ProfileViewControllerContextOneToOneConversation];
    }
}

- (id)initWithUser:(id<UserType, AccentColorProvider>)user viewer:(id<UserType, AccentColorProvider>)viewer conversation:(ZMConversation *)conversation context:(ProfileViewControllerContext)context
{
    if (self = [super init]) {
        _bareUser = user;
        _viewer = viewer;
        _conversation = conversation;
        _context = context;

        [self setupKeyboardFrameNotification];
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

    self.profileFooterView = [[ProfileFooterView alloc] init];
    [self.view addSubview:self.profileFooterView];

    self.incomingRequestFooter = [[IncomingRequestFooterView alloc] init];
    [self.view addSubview:self.incomingRequestFooter];

    self.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorBarBackground];
    
    if (nil != self.fullUser && nil != [ZMUserSession sharedSession]) {
        self.observerToken = [UserChangeInfo addObserver:self forUser:self.fullUser userSession:[ZMUserSession sharedSession]];
    }
    
    [self setupNavigationItems];
    [self setupHeader];
    [self setupTabsController];
    [self setupConstraints];
    [self updateFooterViews];
    [self updateShowVerifiedShield];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication.sharedApplication wr_updateStatusBarForCurrentControllerAnimated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIApplication.sharedApplication wr_updateStatusBarForCurrentControllerAnimated:animated];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.navigationItem.titleView);
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
        ProfileDetailsViewController *profileDetailsViewController = [self setupProfileDetailsViewController];
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
    [self.tabsController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.usernameDetailsView];
    [self.tabsController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.profileFooterView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];

    self.incomingRequestFooter.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:
  @[
    [self.incomingRequestFooter.bottomAnchor constraintEqualToAnchor:self.profileFooterView.topAnchor],
    [self.incomingRequestFooter.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.incomingRequestFooter.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]
     ];
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

#pragma mark - Actions

- (void)bringUpConversationCreationFlow
{
    NSSet<ZMUser *> *users = [[NSSet alloc] initWithObjects:[self fullUser], nil];
    ConversationCreationController *controller = [[ConversationCreationController alloc] initWithPreSelectedParticipants:users];
    controller.delegate = self;
    UINavigationController *wrappedController = [controller wrapInNavigationController];
    wrappedController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:wrappedController animated:true completion:nil];
}

- (void)bringUpCancelConnectionRequestSheetFromView:(UIView *)targetView
{
    UIAlertController *controller = [UIAlertController cancelConnectionRequestControllerForUser:self.fullUser completion:^(BOOL canceled) {
        if (!canceled) {
            [self cancelConnectionRequest];
        }
    }];

    [self presentAlert:controller fromTargetView:targetView];
}

- (void)cancelConnectionRequest
{
    ZMUser *user = [self fullUser];
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [user cancelConnectionRequest];
        [self returnToPreviousScreen];
    }];
}

- (void)openOneToOneConversation
{
    if (self.fullUser == nil) {
        ZMLogError(@"No user to open conversation with");
        return;
    }
    ZMConversation __block *conversation = nil;
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        conversation = self.fullUser.oneToOneConversation;
    } completionHandler:^{
        [self.delegate profileViewController:self wantsToNavigateToConversation:conversation];
    }];
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
