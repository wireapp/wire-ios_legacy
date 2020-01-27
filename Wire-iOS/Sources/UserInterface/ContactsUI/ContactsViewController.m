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

#import "ContactsViewController.h"
#import "ContactsViewController+Internal.h"
#import "ContactsDataSource.h"
#import "UIView+Zeta.h"

#import "UITableView+RowCount.h"
#import "Analytics.h"

#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@implementation ContactsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.shouldShowShareContactsViewController = YES;

        [self setupViews];
        [self setupLayout];
        [self setupStyle];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardFrameWillChange:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    
    return self;
}

#pragma mark - UIViewController overrides

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - User Interface Setup

- (void)setupViews
{
    ColorScheme *colorScheme = [[ColorScheme alloc] init];
    colorScheme.variant = [ColorScheme defaultColorScheme].variant;
    
    self.view.backgroundColor = [colorScheme colorWithName:ColorSchemeColorBackground];
    
    // Top Views
    self.topContainerView = [[UIView alloc] init];
    self.topContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.topContainerView];
    
    self.titleLabel = [[TransformLabel alloc] init];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.text = self.title;
    self.titleLabel.textColor = [colorScheme colorWithName:ColorSchemeColorTextForeground];
    [self.topContainerView addSubview:self.titleLabel];

    [self createSearchHeader];

    self.cancelButton = [[IconButton alloc] init];
    [self.cancelButton setIcon:WRStyleKitIconCross withSize:14 forState:UIControlStateNormal];
    self.cancelButton.accessibilityIdentifier = @"ContactsViewCloseButton";
    [self.cancelButton addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.topContainerView addSubview:self.cancelButton];
    
    // Separator
    self.separatorView = [[UIView alloc] init];
    [self.view addSubview:self.separatorView];
    
    // Table View
    self.tableView = [[UITableView alloc] init];
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.rowHeight = 52.0f;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.sectionIndexMinimumDisplayRowCount = MinimumNumberOfContactsToDisplaySections;
    [self.tableView registerClass:[ContactsCell class] forCellReuseIdentifier:ContactsViewControllerCellID];
    [self.tableView registerClass:[ContactsSectionHeaderView class] forHeaderFooterViewReuseIdentifier:ContactsViewControllerSectionHeaderID];
    [self.view addSubview:self.tableView];

    [self setupTableView];

    // Empty results view
    self.emptyResultsView = [[ContactsEmptyResultView alloc] init];
    self.emptyResultsView.messageLabel.text = NSLocalizedString(@"peoplepicker.no_matching_results_after_address_book_upload_title", @"");
    [self.emptyResultsView.actionButton setTitle:NSLocalizedString(@"peoplepicker.no_matching_results.action.send_invite", @"") forState:UIControlStateNormal];
    [self.emptyResultsView.actionButton addTarget:self action:@selector(sendIndirectInvite:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.emptyResultsView];

    // No contacts label
    self.noContactsLabel = [[UILabel alloc] init];
    self.noContactsLabel.text = NSLocalizedString(@"peoplepicker.no_contacts_title", @"");
    [self.view addSubview:self.noContactsLabel];
    
    // Bottom Views
    self.bottomContainerView = [[UIView alloc] init];
    [self.view addSubview:self.bottomContainerView];
    
    self.bottomContainerSeparatorView = [[UIView alloc] init];
    [self.bottomContainerView addSubview:self.bottomContainerSeparatorView];
    
    self.inviteOthersButton = [[Button alloc] initWithStyle:ButtonStyleEmpty variant:[ColorScheme defaultColorScheme].variant];
    [self.inviteOthersButton addTarget:self action:@selector(sendIndirectInvite:) forControlEvents:UIControlEventTouchUpInside];
    [self.inviteOthersButton setTitle:NSLocalizedString(@"contacts_ui.invite_others", @"") forState:UIControlStateNormal];
    [self.bottomContainerView addSubview:self.inviteOthersButton];
    
    [self updateEmptyResults];
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

    self.tableView.dataSource = self.dataSource;
}

- (void)setBottomButton:(Button *)bottomButton
{
    if (_bottomButton == bottomButton) {
        return;
    }
    
    [self.bottomButton removeFromSuperview];
    
    _bottomButton = bottomButton;
    
    [self.bottomContainerView addSubview:bottomButton];

    [self createBottomButtonConstraints];
}

- (void)setContentDelegate:(id<ContactsViewControllerContentDelegate>)contentDelegate
{
    _contentDelegate = contentDelegate;
    [self updateActionButtonTitles];
}

- (NSArray *) actionButtonTitles {
    return _actionButtonTitles;
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
    if (contact.contactDetails.count == 1) {
        if (contact.emailAddresses.count == 1 && [ZMAddressBookContact canInviteLocallyWithEmail]) {
            [contact inviteLocallyWithEmail:contact.emailAddresses[0]];
            return nil;
        }
        else if (contact.rawPhoneNumbers.count == 1 && [ZMAddressBookContact canInviteLocallyWithPhoneNumber]) {
            [contact inviteLocallyWithPhoneNumber:contact.rawPhoneNumbers[0]];
            return nil;
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

                return unableToSendController;
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

        return chooseContactDetailController;
    }

    return nil;
}

@end
