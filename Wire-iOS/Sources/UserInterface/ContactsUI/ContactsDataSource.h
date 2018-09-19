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



@class ZMSearchRequest;
@class ZMSearchUser;
@class ZMAddressBookContact;
@class ContactsDataSource;
@class SearchDirectory;

extern const NSUInteger MinimumNumberOfContactsToDisplaySections;



NS_ASSUME_NONNULL_BEGIN

@protocol ContactsDataSourceDelegate <NSObject>

@required
- (UITableViewCell *)dataSource:(ContactsDataSource *)dataSource cellForUser:(ZMSearchUser *)user atIndexPath:(NSIndexPath *)indexPath;
@optional
- (void)dataSource:(ContactsDataSource *)dataSource didReceiveSearchResult:(NSArray *)newUsers;
- (void)dataSource:(ContactsDataSource *)dataSource didSelectUser:(ZMSearchUser *)user;
- (void)dataSource:(ContactsDataSource *)dataSource didDeselectUser:(ZMSearchUser *)user;

@end



@interface ContactsDataSource : NSObject<UITableViewDataSource>

@property (nonatomic, readonly, nullable) SearchDirectory *searchDirectory;
@property (nonatomic, nullable) NSArray *ungroupedSearchResults;
@property (nonatomic, copy, nonnull) NSString *searchQuery;
@property (nonatomic) NSOrderedSet *selection;

@property (nonatomic, readonly, assign) BOOL shouldShowSectionIndex;
@property (nonatomic, weak, nullable) id<ContactsDataSourceDelegate> delegate;

- (instancetype)init;
- (instancetype)initWithSearchDirectory:(SearchDirectory * _Nullable)searchDirectory NS_DESIGNATED_INITIALIZER;

- (NSArray *)sectionAtIndex:(NSUInteger)index;
- (ZMSearchUser *)userAtIndexPath:(NSIndexPath *)indexPath;

- (void)selectUser:(ZMSearchUser *)user;
- (void)deselectUser:(ZMSearchUser *)user;

@end

NS_ASSUME_NONNULL_END
