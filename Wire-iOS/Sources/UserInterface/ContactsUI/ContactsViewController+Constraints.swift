//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

        titleLabelTopConstraint = titleLabelConstraints[.top]!
        titleLabelBottomConstraint = titleLabelConstraints[.bottom]!

        var constraints: [NSLayoutConstraint] = titleLabelConstraints.map{$0.value}

        titleLabelHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: 44)
        titleLabelHeightConstraint.isActive = (titleLabel.text?.count ?? 0) > 0

        createSearchHeaderConstraints()

        constraints += separatorView.fitInSuperview(with: EdgeInsets(margin: standardOffset), exclude: [.top, .bottom], activate: false).values
        constraints += [separatorView.heightAnchor.constraint(equalToConstant: 0.5),
                        separatorView.bottomAnchor.constraint(equalTo: tableView.topAnchor),
                        separatorView.bottomAnchor.constraint(equalTo: emptyResultsView.topAnchor)]

        constraints += tableView.fitInSuperview(exclude: [.top, .bottom], activate: false).values
        constraints += [tableView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor)]

        let emptyResultsViewConstraints = emptyResultsView.fitInSuperview(exclude: [.top], activate: false)
        emptyResultsBottomConstraint = emptyResultsViewConstraints[.bottom]!
        constraints += emptyResultsViewConstraints.values

        constraints += [noContactsLabel.topAnchor.constraint(equalTo: searchHeaderViewController.view.bottomAnchor, constant: standardOffset),

                        noContactsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardOffset),
                        noContactsLabel.pinToSuperview(anchor: .trailing, activate: false)]


        let bottomContainerViewConstraints = bottomContainerView.fitInSuperview(exclude: [.top], activate: false)
        bottomContainerBottomConstraint = bottomContainerViewConstraints[.bottom]!

        constraints += bottomContainerViewConstraints.values

        constraints += bottomContainerSeparatorView.fitInSuperview(exclude: [.bottom], activate: false).values
        constraints += [bottomContainerSeparatorView.heightAnchor.constraint(equalToConstant: 0.5)]


        closeButtonTopConstraint = cancelButton.pinToSuperview(anchor: .top, inset: 16 + UIScreen.safeArea.top, activate: (titleLabel.text?.count ?? 0) > 0)

        closeButtonBottomConstraint = cancelButton.pinToSuperview(anchor: .bottom, inset: 8, activate: false)
        closeButtonBottomConstraint.priority = .defaultLow

        closeButtonHeightConstraint = cancelButton.heightAnchor.constraint(equalToConstant: 16)

        constraints += [closeButtonBottomConstraint,
                        cancelButton.pinToSuperview(anchor: .trailing, inset: 16, activate: false),
                        cancelButton.widthAnchor.constraint(equalToConstant: 16),
                        closeButtonHeightConstraint]

        let inviteOthersButtonConstraints = inviteOthersButton.fitInSuperview(with: EdgeInsets(top: standardOffset / 2.0, leading: standardOffset, bottom: standardOffset / 2.0 + UIScreen.safeArea.bottom, trailing: standardOffset), activate: false)

        bottomEdgeConstraint = inviteOthersButtonConstraints[.bottom]!

        constraints += inviteOthersButtonConstraints.values

        constraints += [inviteOthersButton.heightAnchor.constraint(equalToConstant: 28)]

        NSLayoutConstraint.activate(constraints)
    }

    @objc
    func createBottomButtonConstraints() {
        bottomButton.translatesAutoresizingMaskIntoConstraints = false
        bottomButton.fitInSuperview(with: EdgeInsets(margin: 24), exclude:[.top, .bottom])
        bottomButton.pinToSuperview(axisAnchor: .centerY)
    }

    @objc
    func setupTableView() {
        let bottomContainerHeight: CGFloat = 56.0 + UIScreen.safeArea.bottom
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomContainerHeight, right: 0)
    }
}
