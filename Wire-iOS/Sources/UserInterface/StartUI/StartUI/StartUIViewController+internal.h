////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

static NSUInteger const StartUIInitiallyShowsKeyboardConversationThreshold = 10;

@class SearchHeaderViewController;
@class SearchGroupSelector;
@class SearchResultsViewController;
@protocol UserType;
@protocol AddressBookHelperProtocol;



@interface StartUIViewController ()

NS_ASSUME_NONNULL_BEGIN
@property (nonatomic) SearchHeaderViewController *searchHeaderViewController;
@property (nonatomic) SearchGroupSelector *groupSelector;
@property (nonatomic) SearchResultsViewController *searchResultsViewController;
@property (nonatomic) BOOL addressBookUploadLogicHandled;
@property (nonatomic, null_unspecified) id<AddressBookHelperProtocol> addressBookHelper;

-(instancetype) init;

- (void)presentProfileViewControllerForUser:(id<UserType>)bareUser atIndexPath:(NSIndexPath *)indexPath;
NS_ASSUME_NONNULL_END

@end

