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
#import "StartUIViewController+Testing.h"
#import "StartUIView.h"
#import "PeopleSelection.h"
#import "ProfilePresenter.h"
#import "ShareContactsViewController.h"
#import "ZClientViewController.h"
#import "ConversationListViewController.h"
#import "SearchResultCell.h"
#import "TopPeopleCell.h"
#import "StartUIQuickActionsBar.h"
#import "Button.h"
#import "IconButton.h"

#import "SearchTokenStore.h"
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


@interface StartUIViewController () <UsersInDirectorySectionDelegate, ZMSearchResultObserver, PeopleSelectionDelegate, PeopleInputControllerTextDelegate, FormStepDelegate, UIPopoverControllerDelegate, ContactsViewControllerDelegate, SearchViewControllerDelegate>

@property (nonatomic) StartUIView *startUIView;
@property (nonatomic) ProfilePresenter *profilePresenter;

@property (nonatomic) SearchViewController *searchViewController;
@property (nonatomic) ZMSearchDirectory *searchDirectory;
@property (nonatomic) Class searchDirectoryClass;
@property (nonatomic) PeopleSelection *selection;
@property (nonatomic) SearchTokenStore *searchTokenStore;
@property (nonatomic) AnalyticsTracker *analyticsTracker;
@property (nonatomic) ZMSearchRequest *initialSearchRequest;

@property (nonatomic) UIPopoverController *presentedPopover;
@property (nonatomic) BOOL addressBookUploadLogicHandled;
@end

@implementation StartUIViewController

#pragma mark - Overloaded methods

- (void)dealloc
{
    [self.searchDirectory tearDown];
}

- (instancetype)initWithSearchDirectoryClass:(Class)searchDirectoryClass
{
    self = [super init];
    if (self) {
        _searchDirectoryClass = searchDirectoryClass;
        _mode = StartUIModeNotSet;
        self.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:@"people_picker"];
        
        self.initialSearchRequest = [[ZMSearchRequest alloc] init];
        self.initialSearchRequest.query = @"";
        self.initialSearchRequest.includeContacts = YES;
        
        self.topPeopleLineSection = [TopPeopleLineSection new];
        self.topPeopleLineSection.delegate = self;
        
        self.usersInDirectorySection = [UsersInDirectorySection new];
        self.usersInDirectorySection.delegate = self;
        
        self.usersInContactsSection = [UsersInContactsSection new];
        self.usersInContactsSection.delegate = self;
        
        self.groupConversationsSection = [GroupConversationsSection new];
        self.groupConversationsSection.delegate = self;

    }
    return self;
}

- (instancetype)init
{
    self = [self initWithSearchDirectoryClass:[ZMSearchDirectory class]];
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.searchViewController = [SearchViewController new];
    self.searchViewController.delegate = self;
    [self addChildViewController:self.searchViewController];
    [self.view addSubview:self.searchViewController.view];
    [self.searchViewController didMoveToParentViewController:self];
    
    [self.searchViewController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.searchViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.searchViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    
    self.startUIView = [[StartUIView alloc] initForAutoLayout];
    
    [self.view addSubview:self.startUIView];
    
    [self.startUIView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.startUIView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.startUIView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.startUIView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchViewController.view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    [self.startUIView.quickActionsBar.inviteButton addTarget:self action:@selector(inviteMoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.startUIView.quickActionsBar.conversationButton addTarget:self action:@selector(createConversationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.startUIView.quickActionsBar.callButton addTarget:self action:@selector(callButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.startUIView.quickActionsBar.videoCallButton addTarget:self action:@selector(videoCallButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.startUIView.quickActionsBar.cameraButton addTarget:self action:@selector(cameraButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.startUIView.sendInviteActionView setTarget:self action:@selector(sendInvitation:)];
    [self.startUIView.shareContactsActionView setTarget:self action:@selector(shareContacts:)];
    
    self.searchTokenStore = [SearchTokenStore new];
    
    self.selection = [PeopleSelection new];
    self.selection.peopleInputController = self.searchViewController.peopleInputController;
    self.selection.delegate = self;
    self.peopleInputController = self.searchViewController.peopleInputController;
    self.peopleInputController.selectionDelegate = self.selection;
    self.peopleInputController.delegate = self;
    
    self.sectionAggregator = [[CollectionViewSectionAggregator alloc] init];
    self.sectionAggregator.collectionView = self.startUIView.collectionView;

    self.profilePresenter = [ProfilePresenter new];

    self.view.backgroundColor = [UIColor clearColor];
    [self.view setNeedsUpdateConstraints];
    
    [self recreateSearchDirectory];
    [self doInitialSearch];
        
    [self updateActionBar];
    self.mode = StartUIModeInitial;
    
    [self handleUploadAddressBookLogicIfNeeded];
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
        [self.peopleInputController.tokenField becomeFirstResponder];
    }
    
}

- (void)recreateSearchDirectory
{
    [self.searchDirectory removeSearchResultObserver:self];
    [self.searchDirectory tearDown];
    self.searchDirectory = nil;

    self.searchDirectory = [[self.searchDirectoryClass alloc] initWithUserSession:ZMUserSession.sharedSession];
    
    [self.searchDirectory addSearchResultObserver:self];
    
    self.topPeopleLineSection.topConversationDirectory = ZMUserSession.sharedSession.topConversationsDirectory;
    self.usersInDirectorySection.searchDirectory = self.searchDirectory;
    self.usersInContactsSection.searchDirectory = self.searchDirectory;
    self.groupConversationsSection.searchDirectory = self.searchDirectory;
}

- (void)updateActionBar
{
    if (self.selection.selectedUsers.count == 0) {
        if (self.peopleInputController.plainTextContent.length != 0) {
            self.startUIView.quickActionsBar.hidden = YES;
        } else {
            self.startUIView.quickActionsBar.hidden = NO;
            self.startUIView.quickActionsBar.mode = StartUIQuickActionBarModeInvite;
        }
    }
    else if (self.selection.selectedUsers.count == 1) {
        self.startUIView.quickActionsBar.hidden = NO;
        self.startUIView.quickActionsBar.mode = StartUIQuickActionBarModeOpenConversation;
    }
    else {
        self.startUIView.quickActionsBar.hidden = NO;
        self.startUIView.quickActionsBar.mode = StartUIQuickActionBarModeCreateConversation;
    }
    
    [self.view setNeedsLayout];
}

- (void)setMode:(StartUIMode)mode
{
    if (mode == _mode) {
        return;
    }
    
    _mode = mode;
    
    switch (mode) {
        case StartUIModeInitial:
        case StartUIModeUsersSelected:
                self.sectionAggregator.sectionControllers = @[self.topPeopleLineSection, self.usersInContactsSection];
            break;
            
        case StartUIModeSearch:
                self.sectionAggregator.sectionControllers = @[self.usersInContactsSection, self.groupConversationsSection, self.usersInDirectorySection];
            break;
        default:
            break;
    }

    [self.sectionAggregator reloadData];
}

- (NSUInteger)numberOfItems
{
    NSInteger items = 0;
    for (NSInteger section = 0; section < [self.sectionAggregator numberOfSectionsInCollectionView:self.startUIView.collectionView]; section++) {
        items += [self.sectionAggregator collectionView:self.startUIView.collectionView numberOfItemsInSection:section];
    }
    
    return items;
}

- (BOOL)shouldShowShareContacts
{
    AddressBookHelper *helper = [AddressBookHelper sharedHelper];
    return (! helper.isAddressBookAccessDisabled && ! helper.addressBookSearchPerformedAtLeastOnce);
}

- (BOOL)hasSearchResults
{
    BOOL hasResults = NO;

    for (id<CollectionViewSectionController> sectionController in self.sectionAggregator.sectionControllers) {
        hasResults = hasResults || [sectionController hasSearchResults];
    }

    return hasResults;
}

- (void)updateEmptyResultsViewForSearchType:(StartUISearchType)searchType
{
    if (self.mode == StartUIModeInitial || self.mode == StartUIModeUsersSelected || (self.mode == StartUIModeSearch && [self hasSearchResults])) {
        [self.startUIView hideEmptyResutsView];
    }
    else {
        
        if (searchType == StartUISearchTypeUnknown && [AddressBookHelper sharedHelper].addressBookSearchPerformedAtLeastOnce) {
            
            [self.startUIView showEmptySearchResultsAfterAddressBookUpload];
        }
        else if (searchType == StartUISearchTypeDirectory) {
            
            [self.startUIView showEmptySearchResultsViewForSuggestedUsersShowingShareContacts:self.shouldShowShareContacts];
        }
        else {
            
            if (self.peopleInputController.userDidConfirmInput) {
                NSString *currentSearchQuery = self.peopleInputController.plainTextContent;
                
                BOOL isEmailLike = currentSearchQuery.length > 0 && [currentSearchQuery rangeOfString:@"@"].length != 0;
                
                BOOL validEmail = YES;
                NSError *emailValidationError;
                
                if (isEmailLike) {
                    NSString *possibleEmailString = currentSearchQuery;
                    ZMUser<ZMEditableUser> *fullSelfUser = [ZMUser selfUserInUserSession:[ZMUserSession sharedSession]];
                    validEmail = [fullSelfUser validateValue:&possibleEmailString forKey:@"emailAddress" error:&emailValidationError];
                }
                
                [self.startUIView showEmptySearchResultsViewForEmail:isEmailLike && validEmail showShareContacts:self.shouldShowShareContacts];
            }
        }
    }
}

- (UIScrollView *)scrollView
{
    return self.startUIView.collectionView;
}

- (void)setPeopleInputController:(PeopleInputController *)peopleInputController
{
    _peopleInputController = peopleInputController;
}

#pragma mark - Instance methods

- (void)doInitialSearch
{
    [self executeSearch:^{
        return [self.searchDirectory performRequest:self.initialSearchRequest];
    } withType:StartUISearchTypeDirectory];
}

- (void)executeSearch:(ZMSearchToken (^)(void))searchBlock withType:(StartUISearchType)searchType
{
    if (!searchBlock) {
        return;
    }

    ZMSearchToken searchToken = searchBlock();
    if (searchToken == nil) {
        return;
    }
    
    [self.searchTokenStore searchStarted:searchType withToken:searchToken];
    @weakify(self);
    
    NSInteger secondsToDelaySearchProgressViews = 2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(secondsToDelaySearchProgressViews * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        @strongify(self);
        
        BOOL isSearchForTokenLatestSeach = [self.searchTokenStore isLatestSearchOfType:searchType matchingToken:searchToken];
        if (isSearchForTokenLatestSeach) {
            NSInteger itemCount = [self numberOfItems];
            if (itemCount < 0) {
                [self.startUIView showSearchProgressView];
            }
        }
    });
}

- (void)performSearch
{
    NSString *searchString = self.peopleInputController.plainTextContent;
    DDLogInfo(@"Search for %@", searchString);
    [self.startUIView hideEmptyResutsView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch) object:nil];

    if (searchString.length == 0) {
        if (self.selection.selectedUsers.count == 0) {
            self.mode = StartUIModeInitial;
            [self doInitialSearch];
        }
        else {
            self.mode = StartUIModeUsersSelected;
            [self executeSearch:^{
                return [self.searchDirectory searchForLocalUsersAndConversationsMatchingQueryString:searchString];
            } withType:StartUISearchTypeContactsAndConverastions];
        }
    }
    else {
        self.mode = StartUIModeSearch;
        BOOL leadingAt = [[searchString substringToIndex:1] isEqualToString:@"@"];
        [Analytics.shared tagEnteredSearchWithLeadingAtSign:leadingAt context:SearchContextStartUI];
        // invoke directory search with the new text    
        [self executeSearch:^{
            return [self.searchDirectory searchForUsersAndConversationsMatchingQueryString:searchString];
        } withType:StartUISearchTypeContactsAndConverastions];
    }
}

- (void)tagAnalyticsForSelectionIndexPath:(NSIndexPath *)indexPath
{
    if (self.mode == StartUIModeInitial) {
        
        if (indexPath.section == 0) {
            [[Analytics shared] tagSelectedTopContact];
        }
        else if (indexPath.section == 1) {
            [[Analytics shared] tagSelectedSuggestedUserWithIndex:indexPath.row];
        }
    }
    else if (self.mode == StartUIModeSearch) {
        
        if (indexPath.section == 0) {
            [[Analytics shared] tagSelectedSearchResultUserWithIndex:indexPath.row isEmailSearch:NO];
        }
        else if (indexPath.section == 2) {
            [[Analytics shared] tagSelectedSuggestedUserWithIndex:indexPath.row];
        }
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
    [self.peopleInputController.tokenField resignFirstResponder];
    [self.delegate startUI:self didSelectUsers:self.selection.selectedUsers forAction:StartUIActionCreateOrOpenConversation];
}

- (void)callButtonTapped:(id)sender
{
    [self.peopleInputController.tokenField resignFirstResponder];
    [self.delegate startUI:self didSelectUsers:self.selection.selectedUsers forAction:StartUIActionCall];
}

- (void)videoCallButtonTapped:(id)sender
{
    [self.peopleInputController.tokenField resignFirstResponder];
    [self.delegate startUI:self didSelectUsers:self.selection.selectedUsers forAction:StartUIActionVideoCall];
}

- (void)cameraButtonTapped:(id)sender
{
    [self.peopleInputController.tokenField resignFirstResponder];
    [self.delegate startUI:self didSelectUsers:self.selection.selectedUsers forAction:StartUIActionPostPicture];
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
    [self.peopleInputController.tokenField resignFirstResponder];

    UICollectionViewCell *cell = [self.startUIView.collectionView cellForItemAtIndexPath:indexPath];
    
    [self.profilePresenter presentProfileViewControllerForUser:bareUser
                                                  inController:self
                                                      fromRect:[self.view convertRect:cell.bounds fromView:cell]
                                                     onDismiss:^{
        if (IS_IPAD) {
            [self.startUIView.collectionView reloadItemsAtIndexPaths:self.startUIView.collectionView.indexPathsForVisibleItems];
        }
        else {
            if (self.peopleInputController.retainSelectedState && self.profilePresenter.keyboardPersistedAfterOpeningProfile) {
                [self.peopleInputController.tokenField becomeFirstResponder];
                self.peopleInputController.retainSelectedState = NO;
                self.profilePresenter.keyboardPersistedAfterOpeningProfile = NO;
            }
        }
                                                     }
                                                arrowDirection:UIPopoverArrowDirectionLeft];
}

- (void)presentAddressBookUploadDialogue
{
    [self.peopleInputController.tokenField resignFirstResponder];
    
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

#pragma mark - ZMSearchResultsObserver

- (void)didReceiveSearchResult:(ZMSearchResult *)result forToken:(ZMSearchToken)searchToken
{   
    StartUISearchType searchType = [self.searchTokenStore searchTypeForSeachToken:searchToken];
    BOOL isLatestSearch = [self.searchTokenStore isLatestSearchMatchingToken:searchToken];
    
    [self.searchTokenStore searchEndedWithToken:searchToken];
    
    if (isLatestSearch || searchType == StartUISearchTypeUnknown) { // the search that is returned after AB upload
        [self.startUIView hideSearchProgressView];
        
        [self updateEmptyResultsViewForSearchType:searchType];
    }
    
    NSInteger items = [self numberOfItems];
    
    if (items != 0) {
        [self.startUIView hideEmptyResutsView];
    }
}

#pragma mark - UsersInDirectorySectionDelegate

- (void)usersInDirectoryWantsToLoadMoreSuggestions:(UsersInDirectorySection *)suggestions
{
    [self recreateSearchDirectory];
}

- (BOOL)usersInDirectoryIsSearchActive:(UsersInDirectorySection *)section
{
    return (self.mode == StartUIModeSearch);
}

#pragma mark - PeopleSelectionDelegate

- (void)selectedUsersUpdated:(PeopleSelection *)selection
{
    [self updateActionBar];
    
    if (selection.selectedUsers.count == 0) {
        self.mode = StartUIModeInitial;
        [self doInitialSearch];
    }
}

- (void)peopleSelection:(PeopleSelection *)selection didDeselectUsers:(NSSet *)users
{
    [[self.startUIView.collectionView visibleCells] enumerateObjectsUsingBlock:^(UICollectionViewCell* cell, NSUInteger idx, BOOL *stop) {
        
        id<ZMBareUser> user = nil;
        if ([cell isKindOfClass:[SearchResultCell class]]) {
            user = [(SearchResultCell *)cell user];
        }
        else if ([cell isKindOfClass:[TopPeopleCell class]]) {
            user = [(TopPeopleCell *)cell user];
        }
        
        if ([user isKindOfClass:[ZMSearchUser class]]) {
            user = [(ZMSearchUser *)user user];
        }
        
        if (user != nil && [users containsObject:user]) {
            cell.selected = NO;
            [self.startUIView.collectionView deselectItemAtIndexPath:[self.startUIView.collectionView indexPathForCell:cell] animated:NO];
        }
    }];
    
    [self.topPeopleLineSection peopleSelection:selection didDeselectUsers:users];
}

#pragma mark - CollectionViewSectionDelegate

- (void)collectionViewSectionController:(id<CollectionViewSectionController>)controller featureCell:(UICollectionViewCell *)cell forItem:(id)modelObject inCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath
{
    id<ZMBareUser> user = nil;
    
    // Top conversations are actual conversations, so model object can be conversation or user
    if ([modelObject isKindOfClass:[ZMUser class]]) {
        user = modelObject;
    }
    else if (BareUserToUser(modelObject) != nil) {
        user = BareUserToUser(modelObject);
    }
    else if ([modelObject conformsToProtocol:@protocol(ZMBareUser)]) {
        user = modelObject;
    }
    else if ([modelObject isKindOfClass:[ZMConversation class]]) {
        ZMConversation *conversation = modelObject;
        if (conversation.conversationType == ZMConversationTypeOneOnOne) {
            user = conversation.firstActiveParticipantOtherThanSelf;
        }
    }
    
    if ([self.selection.selectedUsers containsObject:user]) {
        cell.selected = YES;
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (NSIndexPath *)collectionViewSectionController:(id<CollectionViewSectionController>)controller indexPathForItemIndex:(NSUInteger)itemIndex
{
    NSUInteger sectionIndex = [self.sectionAggregator.visibleSectionControllers indexOfObject:controller];
    assert(sectionIndex != NSNotFound);
    return [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
}

- (void)collectionViewSectionController:(id<CollectionViewSectionController>)controller didSelectItem:(id)modelObject atIndexPath:(NSIndexPath *)indexPath
{
    if ([modelObject conformsToProtocol:@protocol(AnalyticsConnectionStateProvider)]) {
        [Analytics.shared tagSelectedSearchResultWithConnectionStateProvider:(id<AnalyticsConnectionStateProvider>)modelObject
                                                                     context:SearchContextStartUI];
    }

    if ([modelObject isKindOfClass:[ZMConversation class]]) {
        ZMConversation *conversation = modelObject;
        ZMUser *user = conversation.firstActiveParticipantOtherThanSelf;
        
        if (conversation.conversationType == ZMConversationTypeOneOnOne && user.isBlocked) {
            [self presentProfileViewControllerForUser:user atIndexPath:indexPath];
        }
        else {
            if (conversation.conversationType == ZMConversationTypeGroup) { // double tap condition
                if ([self.delegate respondsToSelector:@selector(startUI:didSelectConversation:)]) {
                    [self.delegate startUI:self didSelectConversation:modelObject];
                }
            }
            else {
                [self.selection addUserToSelectedResults:user];
            }
        }
        
    } else if ([modelObject conformsToProtocol:@protocol(ZMSearchableUser)]) {
        id<ZMSearchableUser> searchableUser = modelObject;
        ZMUser *user = BareUserToUser(searchableUser);
            
        BOOL isAlreadySelectedUser = [self.selection.selectedUsers containsObject:user];
        
        if (user &&
            ! isAlreadySelectedUser &&
            user.isConnected &&
            ! user.isBlocked) {
            [self.selection addUserToSelectedResults:user];
        }
        else {
            [self presentProfileViewControllerForUser:searchableUser atIndexPath:indexPath];
            [self.startUIView.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
    }
    
    if (self.selection.selectedUsers.count == 1) {
        self.mode = StartUIModeUsersSelected;
        [self executeSearch:^{
            return [self.searchDirectory searchForLocalUsersAndConversationsMatchingQueryString:self.peopleInputController.plainTextContent];
        } withType:StartUISearchTypeContactsAndConverastions];
    }
    else {
        [self.sectionAggregator reloadData];
    }
    
    [self tagAnalyticsForSelectionIndexPath:indexPath];
}

- (void)collectionViewSectionController:(id<CollectionViewSectionController>)controller didDeselectItem:(id)modelObject atIndexPath:(NSIndexPath *)indexPath
{
    ZMSearchUser *searchUser = nil;
    ZMUser *user = nil;
    
    if ([modelObject isKindOfClass:[ZMConversation class]]) {
        ZMConversation *conversation = modelObject;
        user = conversation.firstActiveParticipantOtherThanSelf;
    } else if ([modelObject isKindOfClass:[ZMSearchUser class]]) {
        searchUser = modelObject;
        user = searchUser.user;
    }
    
    if (user) {
        [self.selection removeUserFromSelectedResults:user];
    }
    
    [self.sectionAggregator reloadData];
}

- (void)collectionViewSectionController:(id<CollectionViewSectionController>)controller didDoubleTapItem:(id)modelObject atIndexPath:(NSIndexPath *)indexPath
{
    if ([modelObject isKindOfClass:[ZMConversation class]]) {
        ZMConversation *conversation = modelObject;

        if (conversation.conversationType == ZMConversationTypeOneOnOne) {
            ZMUser *otherUser = conversation.firstActiveParticipantOtherThanSelf;

            if (self.selection.selectedUsers.count == 1 && ![self.selection.selectedUsers containsObject:otherUser]) {
                return;
            }
        }

        if ([self.delegate respondsToSelector:@selector(startUI:didSelectConversation:)]) {
            [self.delegate startUI:self didSelectConversation:modelObject];
        }
        
    }
    else if ([modelObject isKindOfClass:[ZMSearchUser class]]) {

        id<ZMSearchableUser> searchableUser = modelObject;
        ZMUser *user = BareUserToUser(searchableUser);

        if (user.isConnected && ! user.isBlocked) {

            if (user != nil && [self.delegate respondsToSelector:@selector(startUI:didSelectUsers:forAction:)]) {
                if (self.selection.selectedUsers.count == 1 && ![self.selection.selectedUsers containsObject:user]) {
                    return;
                }

                [self.delegate startUI:self didSelectUsers:[NSSet setWithObject:user] forAction:StartUIActionCreateOrOpenConversation];
            }
        }
        else {
            [self presentProfileViewControllerForUser:searchableUser atIndexPath:indexPath];

            if (IS_IPHONE && self.peopleInputController.tokenField.isFirstResponder) {
                self.peopleInputController.retainSelectedState = YES;
                [self.peopleInputController.tokenField resignFirstResponder];
                self.profilePresenter.keyboardPersistedAfterOpeningProfile = YES;
            }

            [self.startUIView.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
    }
}


- (void)peopleInputController:(PeopleInputController *)controller changedFilterTextTo:(NSString *)text
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch) object:nil];
    [self performSelector:@selector(performSearch) withObject:nil afterDelay:0.3f];
}

- (void)peopleInputControllerDidConfirmInput:(PeopleInputController *)controller
{
    if (self.selection.selectedUsers.count > 0) {
        [self.delegate startUI:self didSelectUsers:self.selection.selectedUsers forAction:StartUIActionCreateOrOpenConversation];
    }
    else {
        [self.peopleInputController filterUnwantedAttachments];
        [self peopleInputController:controller changedFilterTextTo:controller.plainTextContent];
    }
}

#pragma mark - FormStepDelegate

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    if (self.searchTokenStore.isSearchRunning) {
        [self.startUIView showSearchProgressView];
    } else if (! [self hasSearchResults]) {
        [self.startUIView showEmptySearchResultsViewForSuggestedUsersShowingShareContacts:self.shouldShowShareContacts];
    }
    
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


#pragma mark - SearchViewControllerDelegate

- (void)searchViewControllerWantsToDismissController:(SearchViewController *)searchViewController
{
    [self.peopleInputController.tokenField resignFirstResponder];
    [self.delegate startUIDidCancel:self];
}

@end
