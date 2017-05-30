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


#import <PureLayout/PureLayout.h>

@import WireExtensionComponents;

#import "StartUIViewController.h"
#import "StartUIView.h"
#import "ProfilePresenter.h"
#import "ShareContactsViewController.h"
#import "ZClientViewController.h"
#import "ConversationListViewController.h"
#import "SearchResultCell.h"
#import "TopPeopleCell.h"
#import "StartUIQuickActionsBar.h"
#import "Button.h"
#import "IconButton.h"

#import "ShareItemProvider.h"
#import "ActionSheetController.h"
#import "PeoplePickerEmptyResultsView.h"
#import "InviteContactsViewController.h"

#import "SearchViewController.h"
#import "PeopleInputController.h"
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


@interface StartUIViewController () <FormStepDelegate, UIPopoverControllerDelegate, ContactsViewControllerDelegate, UserSelectionObserver, SearchResultsControllerDelegate, SearchHeaderViewControllerDelegate>

@property (nonatomic) StartUIView *startUIView;
@property (nonatomic) ProfilePresenter *profilePresenter;

@property (nonatomic) SearchHeaderViewController *searchHeaderViewController;
@property (nonatomic) SearchResultsController *searchResultsController;
@property (nonatomic) UserSelection *userSelection;
@property (nonatomic) AnalyticsTracker *analyticsTracker;

@property (nonatomic) UIPopoverController *presentedPopover;
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
    
    Team *team = [[ZMUser selfUser] activeTeam];
    
    self.userSelection = [[UserSelection alloc] init];
    [self.userSelection addObserver:self];
    
    self.startUIView = [[StartUIView alloc] initForAutoLayout];
    [self.view addSubview:self.startUIView];
    
    self.searchHeaderViewController = [[SearchHeaderViewController alloc] initWithUserSelection:self.userSelection variant:ColorSchemeVariantDark];
    self.searchHeaderViewController.title = team != nil ? team.name : ZMUser.selfUser.displayName;
    self.searchHeaderViewController.delegate = self;
    [self addChildViewController:self.searchHeaderViewController];
    [self.view addSubview:self.searchHeaderViewController.view];
    [self.searchHeaderViewController didMoveToParentViewController:self];
    
    self.searchResultsController = [[SearchResultsController alloc] initWithCollectionView:self.startUIView.collectionView userSelection:self.userSelection team:[[ZMUser selfUser] activeTeam] variant:ColorSchemeVariantDark isAddingParticipants:NO];
    self.searchResultsController.mode = SearchResultsControllerModeList;
    self.searchResultsController.delegate = self;
    [self.searchResultsController searchContactList];

    [self.startUIView.quickActionsBar.inviteButton addTarget:self action:@selector(inviteMoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.startUIView.quickActionsBar.conversationButton addTarget:self action:@selector(createConversationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.startUIView.quickActionsBar.callButton addTarget:self action:@selector(callButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.startUIView.quickActionsBar.videoCallButton addTarget:self action:@selector(videoCallButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.startUIView.quickActionsBar.cameraButton addTarget:self action:@selector(cameraButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.startUIView.sendInviteActionView setTarget:self action:@selector(sendInvitation:)];
    [self.startUIView.shareContactsActionView setTarget:self action:@selector(shareContacts:)];
    
    self.profilePresenter = [ProfilePresenter new];

    self.view.backgroundColor = [UIColor clearColor];
    
    [self createConstraints];
    [self updateActionBar];
    [self handleUploadAddressBookLogicIfNeeded];
}

- (void)createConstraints
{
    [self.searchHeaderViewController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.searchHeaderViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.searchHeaderViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    
    [self.startUIView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.startUIView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.startUIView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.startUIView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchHeaderViewController.view];
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
    NSUInteger conversationCount = [ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession] team:[[ZMUser selfUser] activeTeam]].count;
    if (conversationCount > StartUIInitiallyShowsKeyboardConversationThreshold) {
        [self.searchHeaderViewController.tokenField becomeFirstResponder];
    }
    
}

- (void)updateActionBar
{
    if (self.userSelection.users.count == 0) {
        if (self.searchHeaderViewController.query.length != 0 ||
            [[ZMUser selfUser] activeTeam] != nil) {
            self.startUIView.quickActionsBar.hidden = YES;
        } else {
            self.startUIView.quickActionsBar.hidden = NO;
            self.startUIView.quickActionsBar.mode = StartUIQuickActionBarModeInvite;
        }
    }
    else if (self.userSelection.users.count == 1) {
        self.startUIView.quickActionsBar.hidden = NO;
        self.startUIView.quickActionsBar.mode = StartUIQuickActionBarModeOpenConversation;
    }
    else {
        self.startUIView.quickActionsBar.hidden = NO;
        self.startUIView.quickActionsBar.mode = StartUIQuickActionBarModeCreateConversation;
    }
    
    [self.view setNeedsLayout];
}

- (BOOL)shouldShowShareContacts
{
    AddressBookHelper *helper = [AddressBookHelper sharedHelper];
    return (! helper.isAddressBookAccessDisabled && ! helper.addressBookSearchPerformedAtLeastOnce);
}

- (UIScrollView *)scrollView
{
    return self.startUIView.collectionView;
}

#pragma mark - Instance methods

- (void)performSearch
{
    NSString *searchString = self.searchHeaderViewController.query;
    DDLogInfo(@"Search for %@", searchString);
    
    if (searchString.length == 0) {
        self.searchResultsController.mode = SearchResultsControllerModeList;
        [self.searchResultsController searchContactList];
    } else {
        BOOL leadingAt = [[searchString substringToIndex:1] isEqualToString:@"@"];
        BOOL hasSelection = self.userSelection.users.count > 0;
        [Analytics.shared tagEnteredSearchWithLeadingAtSign:leadingAt context:SearchContextStartUI];
        self.searchResultsController.mode = hasSelection ? SearchResultsControllerModeSelection : SearchResultsControllerModeSearch;
        [self.searchResultsController searchWithQuery:searchString local:hasSelection];
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

#pragma mark - Empty results actions

- (void)sendInvitation:(id)sender
{
    [self wr_presentInviteActivityViewControllerWithSourceView:sender logicalContext:GenericInviteContextInvitesSearch];
}

- (void)shareContacts:(id)sender
{
    [self presentAddressBookUploadDialogue];
}

- (void)presentProfileViewControllerForUser:(id<ZMSearchableUser>)bareUser atIndexPath:(NSIndexPath *)indexPath
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];

    UICollectionViewCell *cell = [self.startUIView.collectionView cellForItemAtIndexPath:indexPath];
    
    [self.profilePresenter presentProfileViewControllerForUser:bareUser
                                                  inController:self
                                                      fromRect:[self.view convertRect:cell.bounds fromView:cell]
                                                     onDismiss:^{
        if (IS_IPAD) {
            [self.startUIView.collectionView reloadItemsAtIndexPaths:self.startUIView.collectionView.indexPathsForVisibleItems];
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

- (void)presentAddressBookUploadDialogue
{
    [self.searchHeaderViewController.tokenField resignFirstResponder];
    
    ShareContactsViewController *shareContactsViewController = [[ShareContactsViewController alloc] init];
    shareContactsViewController.formStepDelegate = self;
    // After the registration directly we enforce the AB upload
    shareContactsViewController.uploadAddressBookImmediately = [ZClientViewController sharedZClientViewController].isComingFromRegistration;
    shareContactsViewController.analyticsTracker = self.analyticsTracker;
    shareContactsViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    shareContactsViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.85f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *controllerToPresentOn = [ZClientViewController sharedZClientViewController].conversationListViewController;
        [controllerToPresentOn presentViewController:shareContactsViewController animated:YES completion:nil];
    });
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

#pragma mark - SearchResultsControllerDelegate

- (void)searchResultsController:(SearchResultsController *)searchResultsController didTapOnUser:(id<ZMSearchableUser>)user indexPath:(NSIndexPath *)indexPath section:(enum SearchResultsControllerSection)section
{
    if ([user conformsToProtocol:@protocol(AnalyticsConnectionStateProvider)]) {
        [Analytics.shared tagSelectedSearchResultWithConnectionStateProvider:(id<AnalyticsConnectionStateProvider>)user
                                                                     context:SearchContextStartUI];
    }
    
    switch (section) {
        case SearchResultsControllerSectionTopPeople:
            [[Analytics shared] tagSelectedTopContact];
            break;
        case SearchResultsControllerSectionContacts:
            [[Analytics shared] tagSelectedSearchResultUserWithIndex:indexPath.row];
            break;
        case SearchResultsControllerSectionDirectory:
            [[Analytics shared] tagSelectedSuggestedUserWithIndex:indexPath.row];
            break;
        default:
            break;
    }
    
    if (! user.isConnected && section != SearchResultsControllerSectionTeamMembers) {
        [self presentProfileViewControllerForUser:user atIndexPath:indexPath];
    }
}

- (void)searchResultsController:(SearchResultsController *)searchResultsController didDoubleTapOnUser:(id<ZMSearchableUser>)user indexPath:(NSIndexPath *)indexPath
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

- (void)searchResultsController:(SearchResultsController *)searchResultsController didTapOnConversation:(ZMConversation *)conversation
{
    if (conversation.conversationType == ZMConversationTypeGroup) {
        if ([self.delegate respondsToSelector:@selector(startUI:didSelectConversation:)]) {
            [self.delegate startUI:self didSelectConversation:conversation];
        }
    }
}

- (void)searchResultsController:(SearchResultsController *)searchResultsController didReceiveEmptyResult:(BOOL)empty mode:(enum SearchResultsControllerMode)mode
{
    if (empty && mode == SearchResultsControllerModeList) {
        [self.startUIView showEmptySearchResultsViewForSuggestedUsersShowingShareContacts:self.shouldShowShareContacts];
    } else {
        [self.startUIView hideEmptyResutsView];
    }
}

#pragma mark - SearchHeaderViewControllerDelegate

- (void)searchHeaderViewControllerDidCancelAction:(SearchHeaderViewController *)searchHeaderViewController
{
    [self.searchHeaderViewController resignFirstResponder]; // FIXME jacob
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
    [self.searchResultsController cancelPreviousSearch];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch) object:nil];
    [self performSelector:@selector(performSearch) withObject:nil afterDelay:0.2f];
}

#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSkipFormStep:(UIViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == self.presentedPopover) {
        self.presentedPopover = nil;
    }
}
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    
    if (popoverController == self.presentedPopover) {
        self.presentedPopover = nil;
    }
    
    [popoverController dismissPopoverAnimated:NO];
    [self.startUIView.collectionView reloadItemsAtIndexPaths:self.startUIView.collectionView.indexPathsForVisibleItems];
    
    return NO;
}

#pragma mark - ContactsViewControllerDelegate

- (void)contactsViewControllerDidCancel:(ContactsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactsViewControllerDidNotShareContacts:(ContactsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self wr_presentInviteActivityViewControllerWithSourceView:self.startUIView.quickActionsBar logicalContext:GenericInviteContextStartUIBanner];
    }];
}

@end
