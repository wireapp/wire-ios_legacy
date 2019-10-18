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

#import "StartUIViewController.h"
#import "StartUIViewController+internal.h"
#import "ProfilePresenter.h"
#import "ShareContactsViewController.h"
#import "ZClientViewController.h"
#import "TopPeopleCell.h"
#import "Button.h"
#import "IconButton.h"

#import "ShareItemProvider.h"
#import "InviteContactsViewController.h"
#import "Analytics.h"
#import "WireSyncEngine+iOS.h"
#import "ZMConversation+Additions.h"

#import "Wire-Swift.h"


static NSString* ZMLogTag ZM_UNUSED = @"UI";


@implementation StartUIViewController

#pragma mark - Overloaded methods

-(void)loadView
{
    self.view = [[StartUIView alloc] initWithFrame:CGRectZero];
}

-(instancetype) init
{
    self = [super init];

    self.addressBookHelper = [AddressBookHelper sharedHelper];

    [self setupViews];

    return self;
}

-(void)setupViews
{
    Team *team = ZMUser.selfUser.team;

    self.profilePresenter = [[ProfilePresenter alloc] init];

    self.emptyResultView = [[EmptySearchResultsView alloc] initWithVariant:ColorSchemeVariantDark
                                                           isSelfUserAdmin:[[ZMUser selfUser] canManageTeam]];
    self.emptyResultView.delegate = self;

    self.searchHeaderViewController = [[SearchHeaderViewController alloc] initWithUserSelection:[[UserSelection alloc] init] variant:ColorSchemeVariantDark];
    self.title = (team != nil ? team.name : ZMUser.selfUser.displayName).localizedUppercaseString;
    self.searchHeaderViewController.delegate = self;
    self.searchHeaderViewController.allowsMultipleSelection = NO;
    self.searchHeaderViewController.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSearchBarBackground variant:ColorSchemeVariantDark];
    [self addChildViewController:self.searchHeaderViewController];
    [self.view addSubview:self.searchHeaderViewController.view];
    [self.searchHeaderViewController didMoveToParentViewController:self];

    self.groupSelector = [[SearchGroupSelector alloc] initWithStyle:ColorSchemeVariantDark];
    self.groupSelector.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupSelector.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSearchBarBackground variant:ColorSchemeVariantDark];
    ZM_WEAK(self);
    self.groupSelector.onGroupSelected = ^(SearchGroup group) {
        ZM_STRONG(self);
        if (SearchGroupServices == group) {
            // Remove selected users when switching to services tab to avoid the user confusion: users in the field are
            // not going to be added to the new conversation with the bot.
            [self.searchHeaderViewController clearInput];
        }

        self.searchResultsViewController.searchGroup = group;
        [self performSearch];
    };

    if ([self showsGroupSelector]) {
        [self.view addSubview:self.groupSelector];
    }

    self.searchResultsViewController = [[SearchResultsViewController alloc] initWithUserSelection:[[UserSelection alloc] init]
                                                                             isAddingParticipants:NO
                                                                              shouldIncludeGuests:YES];
    self.searchResultsViewController.mode = SearchResultsViewControllerModeList;
    self.searchResultsViewController.delegate = self;
    [self addChildViewController:self.searchResultsViewController];
    [self.view addSubview:self.searchResultsViewController.view];
    [self.searchResultsViewController didMoveToParentViewController:self];
    self.searchResultsViewController.searchResultsView.emptyResultView = self.emptyResultView;
    self.searchResultsViewController.searchResultsView.collectionView.accessibilityIdentifier = @"search.list";

    self.quickActionsBar = [[StartUIInviteActionBar alloc] init];
    [self.quickActionsBar.inviteButton addTarget:self action:@selector(inviteMoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    self.view.backgroundColor = [UIColor clearColor];

    [self createConstraints];
    [self updateActionBar];
    [self.searchResultsViewController searchContactList];

    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithIcon:WRStyleKitIconCross
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(onDismissPressed)];

    closeButton.accessibilityLabel = NSLocalizedString(@"general.close", @"");
    closeButton.accessibilityIdentifier = @"close";

    self.navigationItem.rightBarButtonItem = closeButton;
    self.view.accessibilityViewIsModal = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication.sharedApplication wr_updateStatusBarForCurrentControllerAnimated:animated];
    [self handleUploadAddressBookLogicIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    [self.navigationController.navigationBar setTranslucent:YES];
    self.navigationController.navigationBar.tintColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.navigationController.navigationBar.titleTextAttributes = [DefaultNavigationBar titleTextAttributesFor:ColorSchemeVariantDark];

    [UIApplication.sharedApplication wr_updateStatusBarForCurrentControllerAnimated:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)showKeyboardIfNeeded
{
    NSUInteger conversationCount = [ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]].count;
    if (conversationCount > StartUIInitiallyShowsKeyboardConversationThreshold) {
        [self.searchHeaderViewController.tokenField becomeFirstResponder];
    }
    
}

- (void)updateActionBar
{
    if (self.searchHeaderViewController.query.length != 0 || ZMUser.selfUser.hasTeam) {
        self.searchResultsViewController.searchResultsView.accessoryView = nil;
    } else {
        self.searchResultsViewController.searchResultsView.accessoryView = self.quickActionsBar;
    }
    
    [self.view setNeedsLayout];
}

- (void)onDismissPressed
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)accessibilityPerformEscape
{
    [self onDismissPressed];
    return YES;
}

#pragma mark - Instance methods

- (void)performSearch
{
    NSString *searchString = self.searchHeaderViewController.query;
    ZMLogInfo(@"Search for %@", searchString);
    
    if (self.groupSelector.group == SearchGroupPeople) {
        if (searchString.length == 0) {
            self.searchResultsViewController.mode = SearchResultsViewControllerModeList;
            [self.searchResultsViewController searchContactList];
        } else {
            self.searchResultsViewController.mode = SearchResultsViewControllerModeSearch;
            [self.searchResultsViewController searchForUsersWithQuery:searchString];
        }
    }
    else {
        [self.searchResultsViewController searchForServicesWithQuery:searchString];
    }
    
    [self.emptyResultView updateStatusWithSearchingForServices:self.groupSelector.group == SearchGroupServices
                                                     hasFilter:searchString.length != 0];
}

#pragma mark - Action bar

- (void)inviteMoreButtonTapped:(UIButton *)sender
{
    InviteContactsViewController *inviteContactsViewController = [[InviteContactsViewController alloc] init];
    inviteContactsViewController.delegate = self;
    [self.navigationController pushViewController:inviteContactsViewController animated:true];
}

#pragma mark - SearchHeaderViewControllerDelegate

- (void)searchHeaderViewControllerDidConfirmAction:(SearchHeaderViewController *)searchHeaderViewController
{
    [self.searchHeaderViewController resetQuery];
}

- (void)searchHeaderViewController:(SearchHeaderViewController *)searchHeaderViewController updatedSearchQuery:(NSString *)query
{
    [self.searchResultsViewController cancelPreviousSearch];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch) object:nil];
    [self performSelector:@selector(performSearch) withObject:nil afterDelay:0.2f];
}

@end
