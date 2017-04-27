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

@import WireSyncEngine;

#import <PureLayout/PureLayout.h>
#import <Classy/UIViewController+CASAdditions.h>
@import WireExtensionComponents;

#import "ContactsViewController.h"
#import "ContactsDataSource.h"
#import "ContactsViewController+InvitationStatus.h"
#import "ContactsViewController+ShareContacts.h"
#import "ContactsCell.h"
#import "ContactsSectionHeaderView.h"
#import "UIView+Zeta.h"
#import "Constants.h"
#import "ColorScheme.h"
#import "UITableView+RowCount.h"
#import "ContactsEmptyResultView.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+WR_Invite.h"
#import "UIViewController+WR_Additions.h"

#import "Wire-Swift.h"

static NSString * const ContactsViewControllerCellID = @"ContactsCell";
static NSString * const ContactsViewControllerSectionHeaderID = @"ContactsSectionHeaderView";


@interface ContactsViewController () <TokenFieldDelegate, UITableViewDelegate, ContactsDataSourceDelegate>
@property (nonatomic) TokenField *tokenField;
@property (nonatomic, readwrite) UITableView *tableView;
@property (nonatomic) Button *inviteOthersButton;
@property (nonatomic) IconButton *cancelButton;
@property (nonatomic) NSArray *actionButtonTitles;
@property (nonatomic) UILabel *noContactsLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) ContactsEmptyResultView *emptyResultsView;

@property (nonatomic) BOOL searchResultsReceived;

// Containers, ect.
@property (nonatomic) UIView *topContainerView;
@property (nonatomic) UIView *separatorView;
@property (nonatomic) UIView *bottomContainerView;
@property (nonatomic) UIView *bottomContainerSeparatorView;
@property (nonatomic) NSLayoutConstraint *bottomContainerBottomConstraint;
@property (nonatomic) NSLayoutConstraint *emptyResultsBottomConstraint;
@property (nonatomic) NSLayoutConstraint *titleLabelHeightConstraint;
@property (nonatomic) NSLayoutConstraint *closeButtonTopConstraint;

@end



@implementation ContactsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        _colorSchemeVariant = [ColorScheme defaultColorScheme].variant;
    }
    
    return self;
}

#pragma mark - UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupViews];
    [self setupLayout];
    
    BOOL shouldSkip = AutomationHelper.sharedHelper.skipFirstLoginAlerts;
    if (self.sharingContactsRequired && ! [[AddressBookHelper sharedHelper] isAddressBookAccessGranted] && !shouldSkip) {
        [self presentShareContactsStepViewController];
    }
    
    [ZMInvitationStatusChangedNotification addInvitationStatusObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self cas_updateStylingIfNeeded];
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tokenField resignFirstResponder];
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)dealloc
{
    [ZMInvitationStatusChangedNotification removeInvitationStatusObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

#pragma mark - User Interface Setup

- (void)setupViews
{
    ColorScheme *colorScheme = [[ColorScheme alloc] init];
    colorScheme.variant = self.colorSchemeVariant;
    
    self.view.backgroundColor = [colorScheme colorWithName:ColorSchemeColorBackground];
    
    // Top Views
    self.topContainerView = [[UIView alloc] initForAutoLayout];
    self.topContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.topContainerView];
    
    self.titleLabel = [[UILabel alloc] initForAutoLayout];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.text = self.title;
    self.titleLabel.textColor = [colorScheme colorWithName:ColorSchemeColorTextForeground];
    [self.topContainerView addSubview:self.titleLabel];
    
    self.tokenField = [[TokenField alloc] initForAutoLayout];
    self.tokenField.delegate = self;
    self.tokenField.textColor = [colorScheme colorWithName:ColorSchemeColorTextForeground];
    self.tokenField.textView.accessibilityLabel = @"textViewSearch";
    self.tokenField.textView.placeholder = NSLocalizedString(@"contacts_ui.search_placeholder", @"");
    self.tokenField.textView.keyboardAppearance = [ColorScheme keyboardAppearanceForVariant:self.colorSchemeVariant];
    [self.topContainerView addSubview:self.tokenField];
    
    self.cancelButton = [[IconButton alloc] initForAutoLayout];
    [self.cancelButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeSearchBar forState:UIControlStateNormal];
    self.cancelButton.accessibilityIdentifier = @"ContactsViewCloseButton";
    [self.cancelButton addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.topContainerView addSubview:self.cancelButton];
    
    // Separator
    self.separatorView = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.separatorView];
    
    // Table View
    self.tableView = [[UITableView alloc] initForAutoLayout];
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.rowHeight = 52.0f;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.sectionIndexMinimumDisplayRowCount = MinimumNumberOfContactsToDisplaySections;
    [self.tableView registerClass:[ContactsCell class] forCellReuseIdentifier:ContactsViewControllerCellID];
    [self.tableView registerClass:[ContactsSectionHeaderView class] forHeaderFooterViewReuseIdentifier:ContactsViewControllerSectionHeaderID];
    [self.view addSubview:self.tableView];

    // Empty results view
    self.emptyResultsView = [[ContactsEmptyResultView alloc] initForAutoLayout];
    self.emptyResultsView.messageLabel.text = NSLocalizedString(@"peoplepicker.no_matching_results_after_address_book_upload_title", @"");
    [self.emptyResultsView.actionButton setTitle:NSLocalizedString(@"peoplepicker.no_matching_results.action.send_invite", @"") forState:UIControlStateNormal];
    [self.emptyResultsView.actionButton addTarget:self action:@selector(sendIndirectInvite:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.emptyResultsView];

    // No contacts label
    self.noContactsLabel = [[UILabel alloc] initForAutoLayout];
    self.noContactsLabel.text = NSLocalizedString(@"peoplepicker.no_contacts_title", @"");
    [self.view addSubview:self.noContactsLabel];
    
    // Bottom Views
    self.bottomContainerView = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.bottomContainerView];
    
    self.bottomContainerSeparatorView = [[UIView alloc] initForAutoLayout];
    [self.bottomContainerView addSubview:self.bottomContainerSeparatorView];
    
    self.inviteOthersButton = [Button buttonWithStyle:ButtonStyleEmpty variant:self.colorSchemeVariant];
    self.inviteOthersButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inviteOthersButton addTarget:self action:@selector(sendIndirectInvite:) forControlEvents:UIControlEventTouchUpInside];
    [self.inviteOthersButton setTitle:NSLocalizedString(@"contacts_ui.invite_others", @"") forState:UIControlStateNormal];
    [self.bottomContainerView addSubview:self.inviteOthersButton];
    
    [self.view cas_updateStylingIfNeeded];
    [self updateEmptyResults];
}

- (void)setupLayout
{
    [self.topContainerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(20, 0, 0, 0) excludingEdge:ALEdgeBottom];
    [self.topContainerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.separatorView];
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.topContainerView autoSetDimension:ALDimensionHeight toSize:62];
    }];
    
    CGFloat standardOffset = 24.0f;

    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:standardOffset];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:standardOffset];
        
    self.titleLabelHeightConstraint = [self.titleLabel autoSetDimension:ALDimensionHeight toSize:44.0f];
    self.titleLabelHeightConstraint.active = (self.titleLabel.text.length > 0);
    
    [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:standardOffset];
    [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:standardOffset];
    [self.separatorView autoSetDimension:ALDimensionHeight toSize:0.5f];
    [self.separatorView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.tableView];

    [self.separatorView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.emptyResultsView];
    [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0) excludingEdge:ALEdgeTop];
    
    [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    self.emptyResultsBottomConstraint = [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    [self.noContactsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.tokenField withOffset:standardOffset];
    [self.noContactsLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:standardOffset];
    [self.noContactsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    
    CGFloat bottomContainerHeight = 56.0f;
    [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.bottomContainerView autoSetDimension:ALDimensionHeight toSize:bottomContainerHeight];
    self.bottomContainerBottomConstraint = [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [self.bottomContainerSeparatorView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.bottomContainerSeparatorView autoSetDimension:ALDimensionHeight toSize:0.5];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, bottomContainerHeight, 0);
    
    [self.tokenField autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:standardOffset];
    [self.tokenField autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.tokenField autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.cancelButton withOffset:- standardOffset / 2];
    [self.tokenField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.tokenField autoSetContentHuggingPriorityForAxis:ALAxisVertical];
    }];
    
    self.closeButtonTopConstraint = [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
    self.closeButtonTopConstraint.active = (self.titleLabel.text.length > 0);
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:8];
    }];

    [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:16];
    [self.cancelButton autoSetDimension:ALDimensionWidth toSize:16];
    [self.cancelButton autoSetDimension:ALDimensionHeight toSize:16];
    
    [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:standardOffset];
    [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:standardOffset];
    [self.inviteOthersButton autoSetDimension:ALDimensionHeight toSize:28];
    [self.inviteOthersButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

#pragma mark - Properties

- (BOOL)sharingContactsRequired
{
    return NO;
}

- (void)setDataSource:(ContactsDataSource *)dataSource
{
    if (_dataSource.delegate == (id)self) {
        _dataSource.delegate = nil;
    }
    _dataSource = dataSource;
    self.dataSource.delegate = self;
}

- (void)setBottomButton:(Button *)bottomButton
{
    if (_bottomButton == bottomButton) {
        return;
    }
    
    [self.bottomButton removeFromSuperview];
    
    _bottomButton = bottomButton;
    
    [self.bottomContainerView addSubview:bottomButton];
    [bottomButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:24];
    [bottomButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:24];
    [bottomButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
}

- (void)setContentDelegate:(id<ContactsViewControllerContentDelegate>)contentDelegate
{
    _contentDelegate = contentDelegate;
    if ([_contentDelegate respondsToSelector:@selector(actionButtonTitlesForContactsViewController:)]) {
        self.actionButtonTitles = [_contentDelegate actionButtonTitlesForContactsViewController:self];
    }
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    self.titleLabel.text = self.title;
    self.titleLabelHeightConstraint.active = self.titleLabel.text.length;
    self.closeButtonTopConstraint.active = (self.titleLabel.text.length > 0);
}

#pragma mark - Actions

- (void)cancelPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contactsViewControllerDidCancel:)]) {
        [self.delegate contactsViewControllerDidCancel:self];
    }
}

- (void)sendIndirectInvite:(UIView *)sender
{
    [self wr_presentInviteActivityViewControllerWithSourceView:self.inviteOthersButton logicalContext:GenericInviteContextInvitesSearch];
}

- (void)keyboardFrameDidChange:(NSNotification *)notification
{
    [UIView animateWithKeyboardNotification:notification
                                     inView:self.view
                                 animations:^(CGRect keyboardFrameInView) {
                                     CGFloat offset = self.wr_isInsidePopoverPresentation ? 0.0f : - keyboardFrameInView.size.height;
                                     self.bottomContainerBottomConstraint.constant = offset;
                                     self.emptyResultsBottomConstraint.constant = offset;
                                     [self.view layoutIfNeeded];
                                 }
                                 completion:^(BOOL finished) {
                                 }];
}

- (void)updateEmptyResults
{
    BOOL showEmptyResults = self.searchResultsReceived && ! [self.tableView numberOfTotalRows];
    BOOL showNoContactsLabel = ! [self.tableView numberOfTotalRows] && (self.dataSource.searchQuery.length == 0) && !self.tokenField.userDidConfirmInput;
    self.noContactsLabel.hidden = ! showNoContactsLabel;
    self.bottomContainerView.hidden = (self.dataSource.searchQuery.length > 0) || showEmptyResults;
    
    [self setEmptyResultsHidden:! showEmptyResults animated:showEmptyResults];
}

- (void)setEmptyResultsHidden:(BOOL)hidden animated:(BOOL)animated
{
    void (^setHiddenBlock)(BOOL) = ^(BOOL hidden) {
        self.emptyResultsView.hidden = hidden;
        self.tableView.hidden = ! hidden;
    };
    
    if (hidden == NO) {
        setHiddenBlock(hidden);
    }
    
    dispatch_block_t animationBlock = ^{
        self.emptyResultsView.alpha = hidden ? 0.0f : 1.0f;
    };
    
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        if (hidden == YES) {
            setHiddenBlock(hidden);
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:animationBlock
                         completion:completionBlock];
    } else {
        animationBlock();
        completionBlock(YES);
    }
}

#pragma mark - TokenFieldDelegate

- (void)tokenField:(TokenField *)tokenField changedTokensTo:(NSArray *)tokens
{
    NSArray *tokenFieldSelection = [tokens valueForKey:NSStringFromSelector(@selector(representedObject))];
    [self.dataSource setSelection:[NSOrderedSet orderedSetWithArray:tokenFieldSelection]];
}

- (void)tokenField:(TokenField *)tokenField changedFilterTextTo:(NSString *)text
{
    self.dataSource.searchQuery = text ? text : @"";
    [self updateEmptyResults];
    if (text.length > 0) {
        BOOL leadingAt = [[text substringToIndex:1] isEqualToString:@"@"];
        [Analytics.shared tagEnteredSearchWithLeadingAtSign:leadingAt context:SearchContextStartUI];
    }
}

- (void)tokenFieldDidConfirmSelection:(TokenField *)controller
{
    if (self.tokenField.tokens.count == 0) {
        [self updateEmptyResults];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(contactsViewControllerDidConfirmSelection:)]) {
        [self.delegate contactsViewControllerDidConfirmSelection:self];
    }
}

#pragma mark - ContactsDataSourceDelegate

- (UITableViewCell *)dataSource:(ContactsDataSource *)dataSource cellForUser:(ZMSearchUser *)user atIndexPath:(NSIndexPath *)indexPath
{
    ContactsCell *cell = (ContactsCell *)[self.tableView dequeueReusableCellWithIdentifier:ContactsViewControllerCellID forIndexPath:indexPath];
    cell.searchUser = user;
    cell.sectionIndexShown = self.dataSource.shouldShowSectionIndex;
    
    @weakify(cell);
    @weakify(self);
    cell.actionButtonHandler = ^(ZMSearchUser * __nullable user) {
        @strongify(cell);
        @strongify(self);
        if ([self.contentDelegate respondsToSelector:@selector(contactsViewController:actionButton:pressedForUser:)]) {
            [self.contentDelegate contactsViewController:self actionButton:cell.actionButton pressedForUser:user];
        }
        if ([self.contentDelegate respondsToSelector:@selector(contactsViewController:shouldDisplayActionButtonForUser:)]) {
            cell.actionButton.hidden = ! [self.contentDelegate contactsViewController:self shouldDisplayActionButtonForUser:user];
        }
    };
    
    if ([self.contentDelegate respondsToSelector:@selector(contactsViewController:shouldDisplayActionButtonForUser:)]) {
        cell.actionButton.hidden = ! [self.contentDelegate contactsViewController:self shouldDisplayActionButtonForUser:user];
    } else {
        cell.actionButton.hidden = YES;
    }
    
    if (! cell.actionButton.hidden) {
        if ([self.contentDelegate respondsToSelector:@selector(contactsViewController:actionButtonTitleIndexForUser:)]) {
            NSUInteger index = [self.contentDelegate contactsViewController:self actionButtonTitleIndexForUser:user];
            NSString *titleString = self.actionButtonTitles[index];
            cell.allActionButtonTitles = self.actionButtonTitles;
            [cell.actionButton setTitle:titleString forState:UIControlStateNormal];
        }
    }
    
    if ([dataSource.selection containsObject:user]) {
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return cell;
}

- (void)dataSource:(ContactsDataSource * __nonnull)dataSource didReceiveSearchResult:(NSArray * __nonnull)newUsers
{
    self.searchResultsReceived = YES;
    [self.tableView reloadData];
    
    [self updateEmptyResults];
}

- (void)dataSource:(ContactsDataSource * __nonnull)dataSource didSelectUser:(ZMSearchUser *)user
{
    if ([user conformsToProtocol:@protocol(AnalyticsConnectionStateProvider)]) {
        [Analytics.shared tagSelectedSearchResultWithConnectionStateProvider:(id<AnalyticsConnectionStateProvider>)user
                                                                     context:SearchContextAddContacts];
    }

    [self.tokenField addToken:[[Token alloc] initWithTitle:user.displayName representedObject:user]];
    [UIView performWithoutAnimation:^{
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)dataSource:(ContactsDataSource * __nonnull)dataSource didDeselectUser:(ZMSearchUser *)user
{
    Token *token = [self.tokenField tokenForRepresentedObject:user];
    
    if (token != nil) {
        [self.tokenField removeToken:token];
    }
    [UIView performWithoutAnimation:^{
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ContactsSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:ContactsViewControllerSectionHeaderID];
    headerView.titleLabel.text = [self.dataSource tableView:tableView titleForHeaderInSection:section];
    return headerView;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // For some reason section header view styling is not updated in time, unless we mark it explicitly
    [view cas_setNeedsUpdateStylingForSubviews];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.dataSource selectUser:[self.dataSource userAtIndexPath:indexPath]];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZMSearchUser *user = [self.dataSource userAtIndexPath:indexPath];
    if ([self.contentDelegate respondsToSelector:@selector(contactsViewController:shouldSelectUser:)] && [self.contentDelegate contactsViewController:self shouldSelectUser:user]) {
        return indexPath;
    } else if ([self.contentDelegate respondsToSelector:@selector(contactsViewController:didSelectCell:forUser:)]) {
        [self.contentDelegate contactsViewController:self didSelectCell:[self.tableView cellForRowAtIndexPath:indexPath] forUser:user];
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.dataSource deselectUser:[self.dataSource userAtIndexPath:indexPath]];
}

#pragma mark - Send Invite

- (void)inviteContact:(ZMAddressBookContact *)contact fromView:(UIView *)view
{
    NSMutableDictionary *eventAttributes = [NSMutableDictionary dictionaryWithDictionary:@{AnalyticsEventInvitationSentToAddressBookFromSearch: self.tokenField.filterText.length != 0 ? @"true" : @"false"}];
    
    if (contact.contactDetails.count == 1) {
        if (contact.emailAddresses.count == 1 && [ZMAddressBookContact canInviteLocallyWithEmail]) {
            [contact inviteLocallyWithEmail:contact.emailAddresses[0]];
            
            [eventAttributes setObject:AnalyticsEventInvitationSentToAddressBookMethodEmail forKey:AnalyticsMethodKey];
            
            [self.analyticsTracker tagEvent:AnalyticsEventInvitationSentToAddressBook
                                 attributes:eventAttributes];
            
        }
        else if (contact.rawPhoneNumbers.count == 1 && [ZMAddressBookContact canInviteLocallyWithPhoneNumber]) {
            [contact inviteLocallyWithPhoneNumber:contact.rawPhoneNumbers[0]];

            [eventAttributes setObject:AnalyticsEventInvitationSentToAddressBookMethodPhone forKey:AnalyticsMethodKey];

            [self.analyticsTracker tagEvent:AnalyticsEventInvitationSentToAddressBook
                                 attributes:eventAttributes];
        }
        else {
            // Cannot invite
            if (contact.emailAddresses.count == 1 && ![ZMAddressBookContact canInviteLocallyWithEmail]) {
                DDLogError(@"Cannot invite person: email is not configured");
                
                UIAlertController *unableToSendController = [UIAlertController alertControllerWithTitle:@""
                                                                                                message:NSLocalizedString(@"error.invite.no_email_provider", @"")
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"general.ok", @"") style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                                                                     [unableToSendController dismissViewControllerAnimated:YES completion:nil];
                                                                 }];
                [unableToSendController addAction:okAction];
                [self presentViewController:unableToSendController animated:YES completion:nil];
                return;
            }
            else if (contact.rawPhoneNumbers.count == 1 && ![ZMAddressBookContact canInviteLocallyWithPhoneNumber]) {
                DDLogError(@"Cannot invite person: email is not configured");
                
                UIAlertController *unableToSendController = [UIAlertController alertControllerWithTitle:@""
                                                                                                message:NSLocalizedString(@"error.invite.no_messaging_provider", @"")
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"general.ok", @"") style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                                                                     [unableToSendController dismissViewControllerAnimated:YES completion:nil];
                                                                 }];
                [unableToSendController addAction:okAction];
                [self presentViewController:unableToSendController animated:YES completion:nil];
            }
        }
    }
    else {
        if (![ZMAddressBookContact canInviteLocallyWithEmail] && ![ZMAddressBookContact canInviteLocallyWithPhoneNumber]) {
            UIAlertController *unableToSendController = [UIAlertController alertControllerWithTitle:@""
                                                                                            message:NSLocalizedString(@"error.invite.no_email_provider", @"")
                                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"general.ok", @"") style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [unableToSendController dismissViewControllerAnimated:YES completion:nil];
                                                             }];
            [unableToSendController addAction:okAction];
            [self presentViewController:unableToSendController animated:YES completion:nil];
            return;
        }
        
        UIAlertController *chooseContactDetailController = [UIAlertController alertControllerWithTitle:nil
                                                                                               message:nil
                                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
        UIPopoverPresentationController *presentationController = chooseContactDetailController.popoverPresentationController;
        presentationController.sourceView = view;
        presentationController.sourceRect = view.bounds;
        
        if ([ZMAddressBookContact canInviteLocallyWithEmail]) {
            for (NSString *contactEmail in contact.emailAddresses) {
                UIAlertAction *action = [UIAlertAction actionWithTitle:contactEmail style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

                    [contact inviteLocallyWithEmail:contactEmail];

                    [eventAttributes setObject:AnalyticsEventInvitationSentToAddressBookMethodEmail forKey:AnalyticsMethodKey];

                    [self.analyticsTracker tagEvent:AnalyticsEventInvitationSentToAddressBook
                                         attributes:eventAttributes];
                    [chooseContactDetailController dismissViewControllerAnimated:YES completion:nil];
                }];
                [chooseContactDetailController addAction:action];
            }
        }
        
        if ([ZMAddressBookContact canInviteLocallyWithPhoneNumber]) {
            for (NSString *contactPhone in contact.rawPhoneNumbers) {
                UIAlertAction *action = [UIAlertAction actionWithTitle:contactPhone style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [contact inviteLocallyWithPhoneNumber:contactPhone];

                    [eventAttributes setObject:AnalyticsEventInvitationSentToAddressBookMethodPhone forKey:AnalyticsMethodKey];
                
                    [self.analyticsTracker tagEvent:AnalyticsEventInvitationSentToAddressBook
                                         attributes:eventAttributes];
                    [chooseContactDetailController dismissViewControllerAnimated:YES completion:nil];
                }];
                [chooseContactDetailController addAction:action];
            }
        }
        [chooseContactDetailController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"contacts_ui.invite_sheet.cancel_button_title", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [chooseContactDetailController dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [self presentViewController:chooseContactDetailController animated:YES completion:nil];
    }
}

@end
