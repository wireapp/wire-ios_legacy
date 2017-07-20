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

#import "StartUIViewController.h"
#import "ProfilePresenter.h"
#import "ShareContactsViewController.h"
#import "ZClientViewController.h"
#import "SearchResultCell.h"
#import "TopPeopleCell.h"
#import "StartUIQuickActionsBar.h"
#import "Button.h"
#import "IconButton.h"

#import "ShareItemProvider.h"
#import "ActionSheetController.h"
#import "InviteContactsViewController.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker+Invitations.h"
#import "WireSyncEngine+iOS.h"
#import "ZMConversation+Additions.h"
#import "ZMUser+Additions.h"
#import "AnalyticsTracker.h"
#import "Constants.h"
#import "UIView+PopoverBorder.h"
#import "UIViewController+WR_Invite.h"
#import "Wire-Swift.h"


static NSUInteger const StartUIInitiallyShowsKeyboardConversationThreshold = 10;


@interface StartUIViewController () <ContactsViewControllerDelegate, UserSelectionObserver, SearchResultsViewControllerDelegate, SearchHeaderViewControllerDelegate>

@property (nonatomic) ProfilePresenter *profilePresenter;
@property (nonatomic) StartUIQuickActionsBar *quickActionsBar;
@property (nonatomic) UILabel *emptyResultLabel;

@property (nonatomic) SearchHeaderViewController *searchHeaderViewController;
@property (nonatomic) SearchResultsViewController *searchResultsViewController;
@property (nonatomic) UserSelection *userSelection;
@property (nonatomic) AnalyticsTracker *analyticsTracker;

@property (nonatomic) BOOL addressBookUploadLogicHandled;
@end

@implementation StartUIViewController

#pragma mark - Overloaded methods

- (void)dealloc
{
    [self.userSelection removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:@"people_picker"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Team *team = ZMUser.selfUser.team;
    
    self.userSelection = [[UserSelection alloc] init];
    [self.userSelection addObserver:self];
    
    self.profilePresenter = [[ProfilePresenter alloc] init];
    
    self.emptyResultLabel = [[UILabel alloc] init];
    self.emptyResultLabel.text = NSLocalizedString(@"peoplepicker.no_matching_results_after_address_book_upload_title", nil);
    self.emptyResultLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.emptyResultLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
    
    self.searchHeaderViewController = [[SearchHeaderViewController alloc] initWithUserSelection:self.userSelection variant:ColorSchemeVariantDark];
    self.searchHeaderViewController.title = team != nil ? team.name : ZMUser.selfUser.displayName;
    self.searchHeaderViewController.delegate = self;
    [self addChildViewController:self.searchHeaderViewController];
    [self.view addSubview:self.searchHeaderViewController.view];
    [self.searchHeaderViewController didMoveToParentViewController:self];
    
    self.searchResultsViewController = [[SearchResultsViewController alloc] initWithUserSelection:self.userSelection team:team variant:ColorSchemeVariantDark isAddingParticipants:NO];
    self.searchResultsViewController.mode = SearchResultsViewControllerModeList;
    self.searchResultsViewController.delegate = self;
    [self addChildViewController:self.searchResultsViewController];
    [self.view addSubview:self.searchResultsViewController.view];
    [self.searchResultsViewController didMoveToParentViewController:self];
    self.searchResultsViewController.searchResultsView.emptyResultView = self.emptyResultLabel;
    
    self.quickActionsBar = [[StartUIQuickActionsBar alloc] init];
    [self.quickActionsBar.inviteButton addTarget:self action:@selector(inviteMoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.quickActionsBar.conversationButton addTarget:self action:@selector(createConversationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.quickActionsBar.callButton addTarget:self action:@selector(callButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.quickActionsBar.videoCallButton addTarget:self action:@selector(videoCallButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.quickActionsBar.cameraButton addTarget:self action:@selector(cameraButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    self.view.backgroundColor = [UIColor clearColor];
    
    [self createConstraints];
    [self updateActionBar];
    [self handleUploadAddressBookLogicIfNeeded];
    [self.searchResultsViewController searchContactList];
}

- (void)createConstraints
{
    [self.searchHeaderViewController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.searchHeaderViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.searchHeaderViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    
    [self.searchResultsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.searchResultsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.searchResultsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.searchResultsViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchHeaderViewController.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[Analytics shared] tagScreen:@"PEOPLE_PICKER"];
}

- (void)handleUploadAddressBookLogicIfNeeded
{
    if (self.addressBookUploadLogicHandled) {
        return;
    }
    
    self.addressBookUploadLogicHandled = YES;
    
    // We should not even try to access address book when in a team
    if (ZMUser.selfUser.hasTeam) {
        return;
    }
    
    if ([[AddressBookHelper sharedHelper] isAddressBookAccessGranted]) {
        // Re-check if we need to start AB search
        [[AddressBookHelper sharedHelper] startRemoteSearchWithCheckingIfEnoughTimeSinceLast:YES];
    }
    else if ([[AddressBookHelper sharedHelper] isAddressBookAccessUnknown]) {
        [[AddressBookHelper sharedHelper] requestPermissions:^(BOOL success) {
            [self.analyticsTracker tagAddressBookSystemPermissions:success];
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[AddressBookHelper sharedHelper] startRemoteSearchWithCheckingIfEnoughTimeSinceLast:YES];
                });
            }
        }];
    }
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
    if (self.userSelection.users.count == 0) {
        if (self.searchHeaderViewController.query.length != 0 ||
            ZMUser.selfUser.hasTeam) {
            self.searchResultsViewController.searchResultsView.accessoryView = nil;
        } else {
            self.searchResultsViewController.searchResultsView.accessoryView = self.quickActionsBar;
            self.quickActionsBar.mode = StartUIQuickActionBarModeInvite;
        }
    }
    else if (self.userSelection.users.count == 1) {
        self.searchResultsViewController.searchResultsView.accessoryView = self.quickActionsBar;
        if (ZMUser.selfUser.hasTeam) { // When in a team we always open group conversations
            self.quickActionsBar.mode = StartUIQuickActionBarModeOpenGroupConversation;
        } else {
            self.quickActionsBar.mode = StartUIQuickActionBarModeOpenConversation;
        }
    }
    else {
        self.searchResultsViewController.searchResultsView.accessoryView = self.quickActionsBar;
        self.quickActionsBar.mode = StartUIQuickActionBarModeCreateConversation;
    }
    
    [self.view setNeedsLayout];
}

#pragma mark - Instance methods

- (void)performSearch
{
    NSString *searchString = self.searchHeaderViewController.query;
    DDLogInfo(@"Search for %@", searchString);
    
    if (searchString.length == 0) {
        self.searchResultsViewController.mode = SearchResultsViewControllerModeList;
        [self.searchResultsViewController searchContactList];
    } else {
        BOOL leadingAt = [[searchString substringToIndex:1] isEqualToString:@"@"];
        BOOL hasSelection = self.userSelection.users.count > 0;
        [Analytics.shared tagEnteredSearchWithLeadingAtSign:leadingAt context:SearchContextStartUI];
        self.searchResultsViewController.mode = hasSelection ? SearchResultsViewControllerModeSelection : SearchResultsViewControllerModeSearch;
        [self.searchResultsViewController searchWithQuery:searchString local:hasSelection];
    }
}

#pragma mark - Action bar

- (void)inviteMoreButtonTapped:(UIButton *)sender
{
    InviteContactsViewController *inviteContactsViewController = [[InviteContactsViewController alloc] init];
    inviteContactsViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:NSStringFromInviteContext(InviteContextStartUI)];
    inviteContactsViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    inviteContactsViewController.delegate = self;
    [self presentViewController:inviteContactsViewController animated:YES completion:^() {
        [[Analytics shared] tagScreenInviteContactList];
        [inviteContactsViewController.analyticsTracker tagEvent:AnalyticsEventInviteContactListOpened];
    }];
}

- (void)createConversationButtonTapped:(id)sender
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];
    [self.delegate startUI:self didSelectUsers:self.userSelection.users forAction:StartUIActionCreateOrOpenConversation];
}

- (void)callButtonTapped:(id)sender
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];
    [self.delegate startUI:self didSelectUsers:self.userSelection.users forAction:StartUIActionCall];
}

- (void)videoCallButtonTapped:(id)sender
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];
    [self.delegate startUI:self didSelectUsers:self.userSelection.users forAction:StartUIActionVideoCall];
}

- (void)cameraButtonTapped:(id)sender
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];
    [self.delegate startUI:self didSelectUsers:self.userSelection.users forAction:StartUIActionPostPicture];
}

- (void)presentProfileViewControllerForUser:(id<ZMSearchableUser>)bareUser atIndexPath:(NSIndexPath *)indexPath
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];

    UICollectionViewCell *cell = [self.searchResultsViewController.searchResultsView.collectionView cellForItemAtIndexPath:indexPath];
    
    [self.profilePresenter presentProfileViewControllerForUser:bareUser
                                                  inController:self
                                                      fromRect:[self.view convertRect:cell.bounds fromView:cell]
                                                     onDismiss:^{
        if (IS_IPAD) {
            [self.searchResultsViewController.searchResultsView.collectionView reloadItemsAtIndexPaths:self.searchResultsViewController.searchResultsView.collectionView.indexPathsForVisibleItems];
        }
        else {
            if (self.profilePresenter.keyboardPersistedAfterOpeningProfile) {
                [self.searchHeaderViewController.tokenField becomeFirstResponder];
                self.profilePresenter.keyboardPersistedAfterOpeningProfile = NO;
            }
        }
                                                     }
                                                arrowDirection:UIPopoverArrowDirectionLeft];
}

#pragma mark - UserSelectionObserver

- (void)userSelection:(UserSelection *)userSelection didAddUser:(ZMUser *)user
{
    [self updateActionBar];
}

- (void)userSelection:(UserSelection *)userSelection didRemoveUser:(ZMUser * _Nonnull)user
{
    [self updateActionBar];
}

- (void)userSelection:(UserSelection *)userSelection wasReplacedBy:(NSArray<ZMUser *> *)users
{
    [self updateActionBar];
}

#pragma mark - SearchResultsViewControllerDelegate

- (void)searchResultsViewController:(SearchResultsViewController *)searchResultsViewController didTapOnUser:(id<ZMSearchableUser>)user indexPath:(NSIndexPath *)indexPath section:(enum SearchResultsViewControllerSection)section
{
    if ([user conformsToProtocol:@protocol(AnalyticsConnectionStateProvider)]) {
        [Analytics.shared tagSelectedSearchResultWithConnectionStateProvider:(id<AnalyticsConnectionStateProvider>)user
                                                                     context:SearchContextStartUI];
    }
    
    switch (section) {
        case SearchResultsViewControllerSectionTopPeople:
            [[Analytics shared] tagSelectedTopContact];
            break;
        case SearchResultsViewControllerSectionContacts:
            [[Analytics shared] tagSelectedSearchResultUserWithIndex:indexPath.row];
            break;
        case SearchResultsViewControllerSectionDirectory:
            [[Analytics shared] tagSelectedSuggestedUserWithIndex:indexPath.row];
            break;
        default:
            break;
    }
    
    if (! user.isConnected && section != SearchResultsViewControllerSectionTeamMembers) {
        [self presentProfileViewControllerForUser:user atIndexPath:indexPath];
    }
}

- (void)searchResultsViewController:(SearchResultsViewController *)searchResultsViewController didDoubleTapOnUser:(id<ZMSearchableUser>)user indexPath:(NSIndexPath *)indexPath
{
    ZMUser *unboxedUser = BareUserToUser(user);
    
    if (unboxedUser != nil && unboxedUser.isConnected && ! unboxedUser.isBlocked) {
        if (user != nil && [self.delegate respondsToSelector:@selector(startUI:didSelectUsers:forAction:)]) {
            if (self.userSelection.users.count == 1 && ![self.userSelection.users containsObject:unboxedUser]) {
                return;
            }
            [self.delegate startUI:self didSelectUsers:[NSSet setWithObject:user] forAction:StartUIActionCreateOrOpenConversation];
        }
    }
}

- (void)searchResultsViewController:(SearchResultsViewController *)searchResultsViewController didTapOnConversation:(ZMConversation *)conversation
{
    if (conversation.conversationType == ZMConversationTypeGroup) {
        if ([self.delegate respondsToSelector:@selector(startUI:didSelectConversation:)]) {
            [self.delegate startUI:self didSelectConversation:conversation];
        }
    }
}

#pragma mark - SearchHeaderViewControllerDelegate

- (void)searchHeaderViewControllerDidCancelAction:(SearchHeaderViewController *)searchHeaderViewController
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];
    [self.delegate startUIDidCancel:self];
}

- (void)searchHeaderViewControllerDidConfirmAction:(SearchHeaderViewController *)searchHeaderViewController
{
    if (self.userSelection.users.count > 0) {
        [self.delegate startUI:self didSelectUsers:self.userSelection.users forAction:StartUIActionCreateOrOpenConversation];
    }
    else {
        [self.searchHeaderViewController resetQuery];
    }
}

- (void)searchHeaderViewController:(SearchHeaderViewController *)searchHeaderViewController updatedSearchQuery:(NSString *)query
{
    [self.searchResultsViewController cancelPreviousSearch];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch) object:nil];
    [self performSelector:@selector(performSearch) withObject:nil afterDelay:0.2f];
}

#pragma mark - ContactsViewControllerDelegate

- (void)contactsViewControllerDidCancel:(ContactsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactsViewControllerDidNotShareContacts:(ContactsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self wr_presentInviteActivityViewControllerWithSourceView:self.quickActionsBar logicalContext:GenericInviteContextStartUIBanner];
    }];
}

@end
