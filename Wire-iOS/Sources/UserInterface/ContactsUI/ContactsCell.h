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



@class ZMSearchUser;
@class Button;



typedef void (^ContactsCellActionButtonHandler)(ZMSearchUser * __nullable user);



NS_ASSUME_NONNULL_BEGIN
@interface ContactsCell : UITableViewCell
@property (nonatomic, nullable) ZMSearchUser *searchUser;
@property (nonatomic, getter=isSectionIndexShown) BOOL sectionIndexShown;
@property (nonatomic, readonly) Button *actionButton;
@property (nonatomic) NSArray *allActionButtonTitles;   // needed to calculate button width
@property (nonatomic, copy, nullable) ContactsCellActionButtonHandler actionButtonHandler;

@end
NS_ASSUME_NONNULL_END
