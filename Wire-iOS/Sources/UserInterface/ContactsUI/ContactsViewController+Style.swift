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

        [titleLabel,
         separatorView,
         tableView,
         emptyResultsView,
         inviteOthersButton,
         noContactsLabel,
         cancelButton,
         bottomContainerSeparatorView,
         bottomContainerView].forEach(){$0.translatesAutoresizingMaskIntoConstraints = false}

        let standardOffset: CGFloat = 24.0
        let titleLabelConstraints = titleLabel.fitInSuperview(with: EdgeInsets(top: UIScreen.safeArea.top, leading: standardOffset, bottom: standardOffset, trailing: standardOffset), activate: false)

        var constraints = titleLabelConstraints.values.map{$0}

        titleLabelTopConstraint = titleLabelConstraints[.top]
        titleLabelBottomConstraint = titleLabelConstraints[.bottom]

//        titleLabelTopConstraint = titleLabel?.autoPinEdge(toSuperviewEdge: ALEdgeTop, withInset: UIScreen.safeArea.top)
//        titleLabel?.autoPinEdge(toSuperviewEdge: ALEdgeLeft, withInset: standardOffset)
//        titleLabel?.autoPinEdge(toSuperviewEdge: ALEdgeRight, withInset: standardOffset)
//        titleLabelBottomConstraint = titleLabel?.autoPinEdge(toSuperviewEdge: ALEdgeBottom, withInset: standardOffset)

        titleLabelHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: 44)
        titleLabelHeightConstraint.isActive = (titleLabel.text?.count ?? 0) > 0

        createSearchHeaderConstraints()

        constraints += separatorView.fitInSuperview(with: EdgeInsets(margin: standardOffset), exclude: [.top, .bottom], activate: false).values.map{$0}
        constraints += [separatorView.heightAnchor.constraint(equalToConstant: 0.5),
                        separatorView.bottomAnchor.constraint(equalTo: tableView.topAnchor),
                        separatorView.bottomAnchor.constraint(equalTo: emptyResultsView.topAnchor)]
//        separatorView.autoPinEdge(toSuperviewEdge: ALEdgeLeading, withInset: standardOffset)
//        separatorView.autoPinEdge(toSuperviewEdge: ALEdgeTrailing, withInset: standardOffset)
//        separatorView.autoSetDimension(ALDimensionHeight, toSize: 0.5)
//        separatorView.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, of: tableView)

//        separatorView.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, ofView: emptyResultsView)

        constraints += tableView.fitInSuperview(exclude: [.top, .bottom], activate: false).values
//        tableView.autoPinEdge(toSuperviewEdge: ALEdgeLeading)
//        tableView.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)
        constraints += [tableView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor)]
//        tableView.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, ofView: bottomContainerView, withOffset: 0)

        let emptyResultsViewConstraints = emptyResultsView.fitInSuperview(exclude: [.top], activate: false)
        emptyResultsBottomConstraint = emptyResultsViewConstraints[.bottom]
        constraints += emptyResultsViewConstraints.values.map{$0}
//        emptyResultsView.autoPinEdge(toSuperviewEdge: ALEdgeLeading)
//        emptyResultsView.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)
//        emptyResultsBottomConstraint = emptyResultsView.autoPinEdge(toSuperviewEdge: ALEdgeBottom)

        constraints += [noContactsLabel.topAnchor.constraint(equalTo: searchHeaderViewController.view.bottomAnchor, constant: standardOffset),

        noContactsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardOffset),
        noContactsLabel.pinToSuperview(anchor: .trailing, activate: false)]
//        noContactsLabel.autoPinEdge(ALEdgeTop, toEdge: ALEdgeBottom, ofView: searchHeaderViewController.view, withOffset: standardOffset)
//        noContactsLabel.autoPinEdge(ALEdgeLeading, toEdge: ALEdgeLeading, ofView: view, withOffset: standardOffset)
//        noContactsLabel.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)

        let bottomContainerHeight: CGFloat = 56.0 + UIScreen.safeArea.bottom

        let bottomContainerViewConstraints = bottomContainerView.fitInSuperview(exclude: [.top], activate: false)
        bottomContainerBottomConstraint = bottomContainerViewConstraints[.bottom]

        constraints += bottomContainerViewConstraints.values.map{$0}

//        bottomContainerView.autoPinEdge(toSuperviewEdge: ALEdgeLeading)
//        bottomContainerView.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)
//        bottomContainerBottomConstraint = bottomContainerView.autoPinEdge(toSuperviewEdge: ALEdgeBottom)

        constraints += bottomContainerSeparatorView.fitInSuperview(exclude: [.bottom], activate: false).values.map{$0}
        constraints += [bottomContainerSeparatorView.heightAnchor.constraint(equalToConstant: 0.5)]
//        bottomContainerSeparatorView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: ALEdgeBottom)
//        bottomContainerSeparatorView.autoSetDimension(ALDimensionHeight, toSize: 0.5)

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomContainerHeight, right: 0)

        closeButtonTopConstraint = cancelButton.pinToSuperview(anchor: .top, inset: 16 + UIScreen.safeArea.top, activate: (titleLabel?.text?.count ?? 0) > 0)
//        closeButtonTopConstraint.active =

        closeButtonBottomConstraint = cancelButton.pinToSuperview(anchor: .bottom, inset: 8, activate: false)
        closeButtonBottomConstraint.priority = .defaultLow
//        NSLayoutConstraint.autoSetPriority(UILayoutPriority.defaultLow, forConstraints: {
//            self.closeButtonBottomConstraint = self.cancelButton.autoPinEdge(toSuperviewEdge: ALEdgeBottom, withInset: 8)
//        })

        closeButtonHeightConstraint = cancelButton.heightAnchor.constraint(equalToConstant: 16)
            //cancelButton.autoSetDimension(ALDimensionHeight, toSize: 16)

        constraints += [closeButtonBottomConstraint,
                        cancelButton.pinToSuperview(anchor: .trailing, inset: 16, activate: false),
                        cancelButton.widthAnchor.constraint(equalToConstant: 16),
                        closeButtonHeightConstraint]

//        cancelButton.autoPinEdge(toSuperviewEdge: ALEdgeTrailing, withInset: 16)
//        cancelButton.autoSetDimension(ALDimensionWidth, toSize: 16)

        let inviteOthersButtonConstraints = inviteOthersButton.fitInSuperview(with: EdgeInsets(top: standardOffset / 2.0, leading: standardOffset, bottom: standardOffset / 2.0 + UIScreen.safeArea.bottom, trailing: standardOffset), exclude: [.bottom], activate: false)

        constraints += inviteOthersButtonConstraints.values.map{$0}

        constraints += [inviteOthersButton.heightAnchor.constraint(equalToConstant: 28)]

//        inviteOthersButton.autoPinEdge(toSuperviewEdge: ALEdgeLeading, withInset: standardOffset)
//        inviteOthersButton.autoPinEdge(toSuperviewEdge: ALEdgeTrailing, withInset: standardOffset)
//        inviteOthersButton.autoSetDimension(ALDimensionHeight, toSize: 28)
//        inviteOthersButton.autoPinEdge(toSuperviewEdge: ALEdgeTop, withInset: standardOffset / 2.0)
//        bottomEdgeConstraint = inviteOthersButton.autoPinEdge(toSuperviewEdge: ALEdgeBottom, withInset: standardOffset / 2.0 + UIScreen.safeArea.bottom)


        NSLayoutConstraint.activate(constraints)
    }

    @objc
    func createBottomButtonConstraints() {
        bottomButton.translatesAutoresizingMaskIntoConstraints = false
        bottomButton.fitInSuperview(with: EdgeInsets(margin: 24), exclude:[.top, .bottom])
        bottomButton.pinToSuperview(axisAnchor: .centerY)
    }
//    [bottomButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:24];
//    [bottomButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:24];
//    [bottomButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];

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

 }
 */
