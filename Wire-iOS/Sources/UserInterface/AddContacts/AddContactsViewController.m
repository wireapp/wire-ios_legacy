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

#import "AddContactsViewController.h"
#import "ContactsViewController+Private.h"
#import "ContactsDataSource.h"
#import "WireSyncEngine+iOS.h"
#import "Button.h"
#import "ContactsCell.h"

#import "Wire-Swift.h"


@interface AddContactsViewController () <ContactsViewControllerContentDelegate>

@property (nonatomic) Button *confirmButton;
@property (nonatomic) ZMConversation *conversation;
@property (nonatomic) NSObject *selectionObserver;
@property (nonatomic) BOOL initialSelectionDone;
@end



@implementation AddContactsViewController

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _conversation = conversation;
        
        ZMSearchRequest *searchRequest = [[ZMSearchRequest alloc] init];
        if (self.conversation.conversationType == ZMConversationTypeOneOnOne) {
            self.title = NSLocalizedString(@"peoplepicker.title.create_conversation", @"");
        }
        else {
            self.title = NSLocalizedString(@"peoplepicker.title.add_to_conversation", @"");
            searchRequest.filteredConversation = self.conversation;
        }
        searchRequest.includeContacts = YES;
        
        self.dataSource = [[ContactsDataSource alloc] initWithSearchRequest:searchRequest];
        self.contentDelegate = self;
        self.selectionObserver = [KeyValueObserver observeObject:self.dataSource keyPath:@"selection" target:self selector:@selector(selectionDidChange:)];

    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.confirmButton = [Button buttonWithStyle:ButtonStyleFull];
    self.confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.confirmButton addTarget:self action:@selector(confirmSelection:) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.conversation.conversationType == ZMConversationTypeOneOnOne) {
        [self.confirmButton setTitle:NSLocalizedString(@"peoplepicker.button.create_conversation", @"") forState:UIControlStateNormal];
    }
    else {
        [self.confirmButton setTitle:NSLocalizedString(@"peoplepicker.button.add_to_conversation", @"") forState:UIControlStateNormal];
    }
    
    [self.confirmButton autoSetDimension:ALDimensionHeight toSize:28];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.view layoutIfNeeded];
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    switch ([ColorScheme defaultColorScheme].variant) {
        case ColorSchemeVariantLight:
            return UIStatusBarStyleDefault;
            break;
            
        case ColorSchemeVariantDark:
            return UIStatusBarStyleLightContent;
            break;
    }
}

#pragma mark - Actions

- (void)confirmSelection:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contactsViewControllerDidConfirmSelection:)]) {
        [self.delegate contactsViewControllerDidConfirmSelection:self];
    }
}

#pragma mark - ContactsDataSource Observer

- (void)dataSource:(ContactsDataSource *)dataSource didReceiveSearchResult:(NSArray *)newUsers
{
    [super dataSource:dataSource didReceiveSearchResult:newUsers];
    if (self.conversation.conversationType == ZMConversationTypeOneOnOne && !self.initialSelectionDone) {
        ZMUser *connectedUser = self.conversation.connectedUser;
        
        for (ZMSearchUser *searchUser in newUsers) {
            if ([searchUser.user isEqual:connectedUser]) {
                [self.dataSource setSelection:[NSOrderedSet orderedSetWithObject:searchUser]];
                self.initialSelectionDone = YES;
                return;
            }
        }
    }
}

- (void)selectionDidChange:(NSNotification *)change
{
    NSUInteger const minSelectionCount = (self.conversation.conversationType == ZMConversationTypeOneOnOne) ? 1 : 0;
    
    if (self.dataSource.selection.count > minSelectionCount) {
        self.bottomButton = self.confirmButton;
    } else {
        self.bottomButton = nil;
    }
}

#pragma mark - ContactsViewControllerContentDelegate

- (BOOL)contactsViewController:(ContactsViewController *)controller shouldDisplayActionButtonForUser:(ZMSearchUser *)user
{
    return NO;
}

- (void)contactsViewController:(ContactsViewController *)controller actionButton:(UIButton *)actionButton pressedForUser:(ZMSearchUser *)user
{
    if (user.user) {
        [self.dataSource selectUser:user];
    } else {
        [self inviteContact:user.contact fromView:actionButton];
    }
}

- (NSArray *)actionButtonTitlesForContactsViewController:(ContactsViewController *)controller
{
    return @[];
}

- (NSUInteger)contactsViewController:(ContactsViewController *)controller actionButtonTitleIndexForUser:(ZMSearchUser *)user;
{
    if (user.user) {
        return 0;
    } else {
        return 1;
    }
}

- (BOOL)contactsViewController:(ContactsViewController *)controller shouldSelectUser:(ZMSearchUser *)user
{
    return user.user != nil;
}

- (void)contactsViewController:(ContactsViewController *)controller didSelectCell:(ContactsCell *)cell forUser:(ZMSearchUser *)user
{
    if (! user.isConnected) {
        [self inviteContact:user.contact fromView:cell.contentView];
    }
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationOverFullScreen;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationOverFullScreen;
}

@end
