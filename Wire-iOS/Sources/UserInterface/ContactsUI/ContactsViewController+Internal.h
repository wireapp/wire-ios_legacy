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
@class ContactsEmptyResultView;

@interface ContactsViewController ()

@property (nonatomic) BOOL searchResultsReceived;

@property (nonatomic, null_unspecified) TransformLabel *titleLabel;
@property (nonatomic, null_unspecified) UIView *bottomContainerView;
@property (nonatomic, null_unspecified) UIView *bottomContainerSeparatorView;
@property (nonatomic, null_unspecified) UILabel *noContactsLabel;
@property (nonatomic, nullable) NSArray *actionButtonTitles;
@property (nonatomic, null_unspecified) IconButton *cancelButton;
@property (nonatomic, null_unspecified) SearchHeaderViewController *searchHeaderViewController;
@property (nonatomic, null_unspecified) UIView *topContainerView;
@property (nonatomic, null_unspecified) UIView *separatorView;
@property (nonatomic, null_unspecified) UITableView *tableView;

@property (nonatomic, null_unspecified) Button *inviteOthersButton;
@property (nonatomic, null_unspecified) ContactsEmptyResultView *emptyResultsView;

@property (nonatomic, null_unspecified) NSLayoutConstraint *closeButtonHeightConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *titleLabelHeightConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *titleLabelTopConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *titleLabelBottomConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *closeButtonTopConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *closeButtonBottomConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *topContainerHeightConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *searchHeaderTopConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *searchHeaderWithNavigatorBarTopConstraint;

@property (nonatomic, null_unspecified) NSLayoutConstraint *bottomEdgeConstraint;

// Containers, ect.
@property (nonatomic, null_unspecified) NSLayoutConstraint *bottomContainerBottomConstraint;
@property (nonatomic, null_unspecified) NSLayoutConstraint *emptyResultsBottomConstraint;

- (void)setEmptyResultsHidden:(BOOL)hidden animated:(BOOL)animated;

@end
