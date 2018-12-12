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

@import PureLayout;
@import WireExtensionComponents;

#import "ContactsViewController.h"
#import "ContactsViewController+Internal.h"
#import "ContactsDataSource.h"
#import "ContactsViewController+ShareContacts.h"
#import "UIView+Zeta.h"
#import "Constants.h"
#import "ColorScheme.h"
#import "UITableView+RowCount.h"
#import "ContactsEmptyResultView.h"
#import "Analytics.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+WR_Invite.h"
#import "UIViewController+WR_Additions.h"

#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";


@interface ContactsViewController ()
@property (nonatomic) Button *inviteOthersButton;
@property (nonatomic) ContactsEmptyResultView *emptyResultsView;

// Containers, ect.
@property (nonatomic) NSLayoutConstraint *bottomContainerBottomConstraint;
@property (nonatomic) NSLayoutConstraint *emptyResultsBottomConstraint;
@end



@implementation ContactsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        _colorSchemeVariant = [ColorScheme defaultColorScheme].variant;

        self.shouldShowShareContactsViewController = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardFrameWillChange:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupViews];
    [self setupLayout];

    BOOL shouldSkip = AutomationHelper.sharedHelper.skipFirstLoginAlerts || ZMUser.selfUser.hasTeam;
    if (self.sharingContactsRequired && ! [[AddressBookHelper sharedHelper] isAddressBookAccessGranted] && !shouldSkip && self.shouldShowShareContactsViewController) {
        [self presentShareContactsViewController];
    }

    [self setupStyle];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)dealloc
{
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
    
    self.titleLabel = [[TransformLabel alloc] initForAutoLayout];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.text = self.title;
    self.titleLabel.textColor = [colorScheme colorWithName:ColorSchemeColorTextForeground];
    [self.topContainerView addSubview:self.titleLabel];

    [self createSearchHeader];

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
    
    [self updateEmptyResults];
}

- (void)setupLayout
{
    [self createTopContainerConstraints];

    CGFloat standardOffset = 24.0f;

    self.titleLabelTopConstraint = [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:UIScreen.safeArea.top];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:standardOffset];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:standardOffset];
    self.titleLabelBottomConstraint = [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:standardOffset];

    self.titleLabelHeightConstraint = [self.titleLabel autoSetDimension:ALDimensionHeight toSize:44.0f];
    self.titleLabelHeightConstraint.active = (self.titleLabel.text.length > 0);

    [self createSearchHeaderConstraints];

    [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:standardOffset];
    [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:standardOffset];
    [self.separatorView autoSetDimension:ALDimensionHeight toSize:0.5f];
    [self.separatorView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.tableView];

    [self.separatorView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.emptyResultsView];

    [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.tableView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomContainerView withOffset:0];

    [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    self.emptyResultsBottomConstraint = [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    [self.noContactsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchHeaderViewController.view withOffset:standardOffset];
    [self.noContactsLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:standardOffset];
    [self.noContactsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];

    CGFloat bottomContainerHeight = 56.0f + UIScreen.safeArea.bottom;
    [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    self.bottomContainerBottomConstraint = [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [self.bottomContainerSeparatorView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.bottomContainerSeparatorView autoSetDimension:ALDimensionHeight toSize:0.5];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, bottomContainerHeight, 0);

    self.closeButtonTopConstraint = [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16 + UIScreen.safeArea.top];
    self.closeButtonTopConstraint.active = (self.titleLabel.text.length > 0);
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        self.closeButtonBottomConstraint = [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:8];
    }];

    [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:16];
    [self.cancelButton autoSetDimension:ALDimensionWidth toSize:16];
    self.closeButtonHeightConstraint = [self.cancelButton autoSetDimension:ALDimensionHeight toSize:16];
    
    [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:standardOffset];
    [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:standardOffset];
    [self.inviteOthersButton autoSetDimension:ALDimensionHeight toSize:28];
    [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:standardOffset / 2.0];
    self.bottomEdgeConstraint = [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset: standardOffset / 2.0 + UIScreen.safeArea.bottom];

    
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

- (void)dataSource:(ContactsDataSource * __nonnull)dataSource didReceiveSearchResult:(NSArray * __nonnull)newUsers
{
    self.searchResultsReceived = YES;
    [self.tableView reloadData];
    
    [self updateEmptyResults];
}

- (void)dataSource:(ContactsDataSource * __nonnull)dataSource didSelectUser:(ZMSearchUser *)user
{
    [self.searchHeaderViewController.tokenField addToken:[[Token alloc] initWithTitle:user.displayName representedObject:user]];
    [UIView performWithoutAnimation:^{
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)dataSource:(ContactsDataSource * __nonnull)dataSource didDeselectUser:(ZMSearchUser *)user
{
    Token *token = [self.searchHeaderViewController.tokenField tokenForRepresentedObject:user];
    
    if (token != nil) {
        [self.searchHeaderViewController.tokenField removeToken:token];
    }
    [UIView performWithoutAnimation:^{
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - Send Invite


/**
 return a UIAlertController depends contact has email or phone number

 @param contact a ZMAddressBookContact object
 @param view the source view
 @return a UIAlertController which let the user to choose invite via email or phone number or no email client is set
 */
- (UIAlertController *)inviteContact:(ZMAddressBookContact *)contact fromView:(UIView *)view
{
    UIAlertController * alertController;

    if (contact.contactDetails.count == 1) {
        if (contact.emailAddresses.count == 1 && [ZMAddressBookContact canInviteLocallyWithEmail]) {
            [contact inviteLocallyWithEmail:contact.emailAddresses[0]];
        }
        else if (contact.rawPhoneNumbers.count == 1 && [ZMAddressBookContact canInviteLocallyWithPhoneNumber]) {
            [contact inviteLocallyWithPhoneNumber:contact.rawPhoneNumbers[0]];
        }
        else {
            // Cannot invite
            if (contact.emailAddresses.count == 1 && ![ZMAddressBookContact canInviteLocallyWithEmail]) {
                ZMLogError(@"Cannot invite person: email is not configured");
                
                UIAlertController *unableToSendController = [UIAlertController alertControllerWithTitle:@""
                                                                                                message:NSLocalizedString(@"error.invite.no_email_provider", @"")
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"general.ok", @"") style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                                                                     [unableToSendController dismissViewControllerAnimated:YES completion:nil];
                                                                 }];
                [unableToSendController addAction:okAction];

                return unableToSendController;
            }
            else if (contact.rawPhoneNumbers.count == 1 && ![ZMAddressBookContact canInviteLocallyWithPhoneNumber]) {
                ZMLogError(@"Cannot invite person: email is not configured");
                
                UIAlertController *unableToSendController = [UIAlertController alertControllerWithTitle:@""
                                                                                                message:NSLocalizedString(@"error.invite.no_messaging_provider", @"")
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"general.ok", @"") style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                                                                     [unableToSendController dismissViewControllerAnimated:YES completion:nil];
                                                                 }];
                [unableToSendController addAction:okAction];

                alertController = unableToSendController;
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

            return unableToSendController;
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

                    [chooseContactDetailController dismissViewControllerAnimated:YES completion:nil];
                }];
                [chooseContactDetailController addAction:action];
            }
        }
        
        if ([ZMAddressBookContact canInviteLocallyWithPhoneNumber]) {
            for (NSString *contactPhone in contact.rawPhoneNumbers) {
                UIAlertAction *action = [UIAlertAction actionWithTitle:contactPhone style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [contact inviteLocallyWithPhoneNumber:contactPhone];

                    [chooseContactDetailController dismissViewControllerAnimated:YES completion:nil];
                }];
                [chooseContactDetailController addAction:action];
            }
        }
        [chooseContactDetailController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"contacts_ui.invite_sheet.cancel_button_title", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [chooseContactDetailController dismissViewControllerAnimated:YES completion:nil];
        }]];

        alertController = chooseContactDetailController;
    }

    return alertController;
}

@end
