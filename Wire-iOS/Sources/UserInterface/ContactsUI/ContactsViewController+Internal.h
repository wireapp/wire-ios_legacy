//
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

static NSString * const _Nonnull ContactsViewControllerCellID = @"ContactsCell";
static NSString * const _Nonnull ContactsViewControllerSectionHeaderID = @"ContactsSectionHeaderView";

@class IconButton;
@class SearchHeaderViewController;
@class TransformLabel;

@interface ContactsViewController ()

@property (nonatomic) BOOL searchResultsReceived;

@property (nonatomic, nullable) TransformLabel *titleLabel;
@property (nonatomic, nullable) UIView *bottomContainerView;
@property (nonatomic, nullable) UIView *bottomContainerSeparatorView;
@property (nonatomic, nullable) UILabel *noContactsLabel;
@property (nonatomic, nullable) NSArray *actionButtonTitles;
@property (nonatomic, nullable) IconButton *cancelButton;
@property (nonatomic, nullable) SearchHeaderViewController *searchHeaderViewController;
@property (nonatomic, nullable) UIView *topContainerView;
@property (nonatomic, nullable) UIView *separatorView;
@property (nonatomic, readwrite, nullable) UITableView *tableView;

@property (nonatomic, nullable) NSLayoutConstraint *closeButtonHeightConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *titleLabelHeightConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *titleLabelTopConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *titleLabelBottomConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *closeButtonTopConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *closeButtonBottomConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *topContainerHeightConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *searchHeaderTopConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *searchHeaderWithNavigatorBarTopConstraint;

@property (nonatomic, nullable) NSLayoutConstraint *bottomEdgeConstraint;

- (void)setEmptyResultsHidden:(BOOL)hidden animated:(BOOL)animated;

@end
