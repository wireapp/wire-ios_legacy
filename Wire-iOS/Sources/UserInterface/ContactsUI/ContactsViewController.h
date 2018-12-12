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


@import UIKit;
@import WireExtensionComponents;

#import "ColorScheme.h"

@class ContactsDataSource;
@class ContactsViewController;
@class ContactsCell;
@class ZMSearchUser;
@class ZMAddressBookContact;
@class Button;

NS_ASSUME_NONNULL_BEGIN


@protocol ContactsViewControllerDelegate <NSObject>
@optional
- (void)contactsViewControllerDidCancel:(ContactsViewController * )controller;
- (void)contactsViewControllerDidNotShareContacts:(ContactsViewController * )controller;
- (void)contactsViewControllerDidConfirmSelection:(ContactsViewController *)controller;
@end


@protocol ContactsViewControllerContentDelegate <NSObject>
@optional
- (BOOL)contactsViewController:(ContactsViewController *)controller shouldDisplayActionButtonForUser:(ZMSearchUser *)user;
- (void)contactsViewController:(ContactsViewController *)controller actionButton:(UIButton *)actionButton pressedForUser:(ZMSearchUser *)user;
- (void)contactsViewController:(ContactsViewController *)controller didSelectCell:(ContactsCell *)cell forUser:(ZMSearchUser *)user;
- (BOOL)contactsViewController:(ContactsViewController *)controller shouldSelectUser:(ZMSearchUser *)user;

// This API might look strange, but we need it for making all the buttons to have same width
- (NSArray *)actionButtonTitlesForContactsViewController:(ContactsViewController *)controller;
- (NSUInteger)contactsViewController:(ContactsViewController *)controller actionButtonTitleIndexForUser:(ZMSearchUser *)user;
@end



@interface ContactsViewController : UIViewController

@property (nonatomic) ContactsDataSource *__nullable dataSource;
@property (nonatomic, weak) id<ContactsViewControllerDelegate> __nullable delegate;
@property (nonatomic, weak) id<ContactsViewControllerContentDelegate> __nullable contentDelegate;
@property (nonatomic) ColorSchemeVariant colorSchemeVariant;

/// Button displayed at the bottom of the screen. If nil a default button is displayed.
@property (nonatomic) Button *__nullable bottomButton;
@property (nonatomic) BOOL shouldShowShareContactsViewController;

- (UIAlertController *)inviteContact:(ZMAddressBookContact *)contact fromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
