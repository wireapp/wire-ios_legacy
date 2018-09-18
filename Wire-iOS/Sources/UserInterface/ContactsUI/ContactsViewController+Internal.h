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

static NSString * const ContactsViewControllerCellID = @"ContactsCell";
static NSString * const ContactsViewControllerSectionHeaderID = @"ContactsSectionHeaderView";

@class IconButton;
@class SearchHeaderViewController;

@interface ContactsViewController ()

@property (nonatomic) BOOL searchResultsReceived;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *bottomContainerView;
@property (nonatomic) UIView *bottomContainerSeparatorView;
@property (nonatomic) UILabel *noContactsLabel;
@property (nonatomic) NSArray *actionButtonTitles;
@property (nonatomic) IconButton *cancelButton;
@property (nonatomic) SearchHeaderViewController *searchHeaderViewController;
@property (nonatomic) UIView *topContainerView;
@property (nonatomic) UIView *separatorView;
@property (nonatomic, readwrite) UITableView *tableView;

@property (nonatomic) NSLayoutConstraint *closeButtonHeightConstraint;
@property (nonatomic) NSLayoutConstraint *titleLabelHeightConstraint;
@property (nonatomic) NSLayoutConstraint *titleLabelTopConstraint;
@property (nonatomic) NSLayoutConstraint *titleLabelBottomConstraint;
@property (nonatomic) NSLayoutConstraint *closeButtonTopConstraint;
@property (nonatomic) NSLayoutConstraint *closeButtonBottomConstraint;
@property (nonatomic) NSLayoutConstraint *topContainerHeightConstraint;

- (void)setEmptyResultsHidden:(BOOL)hidden animated:(BOOL)animated;

@end
