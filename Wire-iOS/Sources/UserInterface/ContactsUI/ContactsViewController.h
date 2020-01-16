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

@class ContactsDataSource;
@class ContactsViewController;
@class ContactsCell;
@class ZMSearchUser;
@class ZMAddressBookContact;
@class Button;

@protocol ContactsViewControllerDelegate;
@protocol ContactsViewControllerContentDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ContactsViewController : UIViewController

@property (nonatomic) ContactsDataSource *__nullable dataSource;
@property (nonatomic, weak, nullable) id<ContactsViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) id<ContactsViewControllerContentDelegate> contentDelegate;

/// Button displayed at the bottom of the screen. If nil a default button is displayed.
@property (nonatomic, nullable) Button * bottomButton;
@property (nonatomic) BOOL shouldShowShareContactsViewController;

- (UIAlertController * _Nullable)inviteContact:(ZMAddressBookContact *)contact fromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
