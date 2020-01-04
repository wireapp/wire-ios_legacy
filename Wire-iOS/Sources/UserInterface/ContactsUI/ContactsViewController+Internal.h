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


@class IconButton;
@class SearchHeaderViewController;
@class TransformLabel;
@class ContactsEmptyResultView;

NS_ASSUME_NONNULL_BEGIN

static NSString * const ContactsViewControllerCellID = @"ContactsCell";
static NSString * const ContactsViewControllerSectionHeaderID = @"ContactsSectionHeaderView";

@interface ContactsViewController ()

@property (nonatomic) BOOL searchResultsReceived;

@property (nonatomic) TransformLabel *titleLabel;
@property (nonatomic) UIView *bottomContainerView;
@property (nonatomic) UIView *bottomContainerSeparatorView;
@property (nonatomic) UILabel *noContactsLabel;
@property (nonatomic) IconButton *cancelButton;
@property (nonatomic) SearchHeaderViewController *searchHeaderViewController;
@property (nonatomic) UIView *topContainerView;
@property (nonatomic) UIView *separatorView;
@property (nonatomic) UITableView *tableView;

@property (nonatomic) Button *inviteOthersButton;
@property (nonatomic) ContactsEmptyResultView *emptyResultsView;

@property (nonatomic) NSLayoutConstraint *closeButtonHeightConstraint;
@property (nonatomic) NSLayoutConstraint *titleLabelHeightConstraint;
@property (nonatomic) NSLayoutConstraint *titleLabelTopConstraint;
@property (nonatomic) NSLayoutConstraint *titleLabelBottomConstraint;
@property (nonatomic) NSLayoutConstraint *closeButtonTopConstraint;
@property (nonatomic) NSLayoutConstraint *closeButtonBottomConstraint;
@property (nonatomic) NSLayoutConstraint *topContainerHeightConstraint;
@property (nonatomic) NSLayoutConstraint *searchHeaderTopConstraint;
@property (nonatomic) NSLayoutConstraint *searchHeaderWithNavigatorBarTopConstraint;

@property (nonatomic) NSLayoutConstraint *bottomEdgeConstraint;

// Containers, ect.
@property (nonatomic) NSLayoutConstraint *bottomContainerBottomConstraint;
@property (nonatomic) NSLayoutConstraint *emptyResultsBottomConstraint;

/// If sharingContactsRequired is true the user will be prompted to share his address book
/// if he/she hasn't already done so. Override this property in subclasses to override
/// the default behaviour which is false.
@property (nonatomic, readonly) BOOL sharingContactsRequired;
@property (nonatomic, nullable) NSArray *actionButtonTitles;

- (void)setEmptyResultsHidden:(BOOL)hidden animated:(BOOL)animated;
- (NSArray *) actionButtonTitles;
- (void)dismissChildViewController:(UIViewController *)viewController;

@end


NS_ASSUME_NONNULL_END
