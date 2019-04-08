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

import Foundation

extension ContactsViewController {
    @objc func setupStyle() {
        titleLabel?.textAlignment = .center
        titleLabel?.font = .smallLightFont
        titleLabel?.textTransform = .upper

        bottomContainerView?.backgroundColor = .from(scheme: .background)

        noContactsLabel?.font = .normalLightFont
        noContactsLabel?.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc
    func setupLayout() {
        createTopContainerConstraints()

        let standardOffset: CGFloat = 24.0

        titleLabelTopConstraint = titleLabel?.autoPinEdge(toSuperviewEdge: ALEdgeTop, withInset: UIScreen.safeArea.top)
        titleLabel?.autoPinEdge(toSuperviewEdge: ALEdgeLeft, withInset: standardOffset)
        titleLabel?.autoPinEdge(toSuperviewEdge: ALEdgeRight, withInset: standardOffset)
        titleLabelBottomConstraint = titleLabel?.autoPinEdge(toSuperviewEdge: ALEdgeBottom, withInset: standardOffset)

        titleLabelHeightConstraint = titleLabel?.autoSetDimension(ALDimensionHeight, toSize: 44.0)
        titleLabelHeightConstraint.active = (titleLabel?.text?.count ?? 0) > 0

        createSearchHeaderConstraints()

        separatorView.autoPinEdge(toSuperviewEdge: ALEdgeLeading, withInset: standardOffset)
        separatorView.autoPinEdge(toSuperviewEdge: ALEdgeTrailing, withInset: standardOffset)
        separatorView.autoSetDimension(ALDimensionHeight, toSize: 0.5)
        separatorView.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, of: tableView)

        separatorView.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, ofView: emptyResultsView)

        tableView.autoPinEdge(toSuperviewEdge: ALEdgeLeading)
        tableView.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)
        tableView.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, ofView: bottomContainerView, withOffset: 0)

        emptyResultsView.autoPinEdge(toSuperviewEdge: ALEdgeLeading)
        emptyResultsView.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)
        emptyResultsBottomConstraint = emptyResultsView.autoPinEdge(toSuperviewEdge: ALEdgeBottom)

        noContactsLabel.autoPinEdge(ALEdgeTop, toEdge: ALEdgeBottom, ofView: searchHeaderViewController.view, withOffset: standardOffset)
        noContactsLabel.autoPinEdge(ALEdgeLeading, toEdge: ALEdgeLeading, ofView: view, withOffset: standardOffset)
        noContactsLabel.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)

        let bottomContainerHeight: CGFloat = 56.0 + UIScreen.safeArea.bottom
        bottomContainerView.autoPinEdge(toSuperviewEdge: ALEdgeLeading)
        bottomContainerView.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)
        bottomContainerBottomConstraint = bottomContainerView.autoPinEdge(toSuperviewEdge: ALEdgeBottom)

        bottomContainerSeparatorView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: ALEdgeBottom)
        bottomContainerSeparatorView.autoSetDimension(ALDimensionHeight, toSize: 0.5)

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomContainerHeight, right: 0)

        closeButtonTopConstraint = cancelButton.autoPinEdge(toSuperviewEdge: ALEdgeTop, withInset: 16 + UIScreen.safeArea.top)
        closeButtonTopConstraint.active = (titleLabel?.text?.count ?? 0) > 0

        NSLayoutConstraint.autoSetPriority(UILayoutPriority.defaultLow, forConstraints: {
            self.closeButtonBottomConstraint = self.cancelButton.autoPinEdge(toSuperviewEdge: ALEdgeBottom, withInset: 8)
        })

        cancelButton.autoPinEdge(toSuperviewEdge: ALEdgeTrailing, withInset: 16)
        cancelButton.autoSetDimension(ALDimensionWidth, toSize: 16)
        closeButtonHeightConstraint = cancelButton.autoSetDimension(ALDimensionHeight, toSize: 16)

        inviteOthersButton.autoPinEdge(toSuperviewEdge: ALEdgeLeading, withInset: standardOffset)
        inviteOthersButton.autoPinEdge(toSuperviewEdge: ALEdgeTrailing, withInset: standardOffset)
        inviteOthersButton.autoSetDimension(ALDimensionHeight, toSize: 28)
        inviteOthersButton.autoPinEdge(toSuperviewEdge: ALEdgeTop, withInset: standardOffset / 2.0)
        bottomEdgeConstraint = inviteOthersButton.autoPinEdge(toSuperviewEdge: ALEdgeBottom, withInset: standardOffset / 2.0 + UIScreen.safeArea.bottom)


        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardFrameDidChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

}

/*
 - (void)setupLayout
 {
 [self createTopContainerConstraints];

 CGFloat standardOffset = 24.0f;

 self.titleLabelTopConstraint = [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:UIScreen.safeArea.top];
 [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:standardOffset];
 [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:standardOffset];
 self.titleLabelBottomConstraint = [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:standardOffset];

 self.titleLabelHeightConstraint = [self.titleLabel autoSetDimension:ALDimensionHeight toSize:44.0f];
 self.titleLabelHeightConstraint.active = (self.titleLabel.text.length > 0);

 [self createSearchHeaderConstraints];

 [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:standardOffset];
 [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:standardOffset];
 [self.separatorView autoSetDimension:ALDimensionHeight toSize:0.5f];
 [self.separatorView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.tableView];

 [self.separatorView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.emptyResultsView];

 [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
 [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
 [self.tableView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomContainerView withOffset:0];

 [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
 [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
 self.emptyResultsBottomConstraint = [self.emptyResultsView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

 [self.noContactsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchHeaderViewController.view withOffset:standardOffset];
 [self.noContactsLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view withOffset:standardOffset];
 [self.noContactsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];

 CGFloat bottomContainerHeight = 56.0f + UIScreen.safeArea.bottom;
 [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
 [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
 self.bottomContainerBottomConstraint = [self.bottomContainerView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

 [self.bottomContainerSeparatorView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
 [self.bottomContainerSeparatorView autoSetDimension:ALDimensionHeight toSize:0.5];

 self.tableView.contentInset = UIEdgeInsetsMake(0, 0, bottomContainerHeight, 0);

 self.closeButtonTopConstraint = [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16 + UIScreen.safeArea.top];
 self.closeButtonTopConstraint.active = (self.titleLabel.text.length > 0);

 [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
 self.closeButtonBottomConstraint = [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:8];
 }];

 [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:16];
 [self.cancelButton autoSetDimension:ALDimensionWidth toSize:16];
 self.closeButtonHeightConstraint = [self.cancelButton autoSetDimension:ALDimensionHeight toSize:16];

 [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:standardOffset];
 [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:standardOffset];
 [self.inviteOthersButton autoSetDimension:ALDimensionHeight toSize:28];
 [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:standardOffset / 2.0];
 self.bottomEdgeConstraint = [self.inviteOthersButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset: standardOffset / 2.0 + UIScreen.safeArea.bottom];


 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
 }
 */
