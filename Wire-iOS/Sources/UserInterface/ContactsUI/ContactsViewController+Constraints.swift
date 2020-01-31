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
        [separatorView,
         tableView,
         emptyResultsView,
         inviteOthersButton,
         noContactsLabel,
         bottomContainerSeparatorView,
         bottomContainerView].forEach(){$0.translatesAutoresizingMaskIntoConstraints = false}

        let standardOffset: CGFloat = 24.0

        var constraints: [NSLayoutConstraint] = []

        createSearchHeaderConstraints()

        constraints += [separatorView.leadingAnchor.constraint(equalTo: separatorView.superview!.leadingAnchor, constant: standardOffset),
                        separatorView.trailingAnchor.constraint(equalTo: separatorView.superview!.trailingAnchor, constant: -standardOffset),

                        separatorView.heightAnchor.constraint(equalToConstant: 0.5),
                        separatorView.bottomAnchor.constraint(equalTo: tableView.topAnchor),
                        separatorView.bottomAnchor.constraint(equalTo: emptyResultsView.topAnchor),

                        tableView.leadingAnchor.constraint(equalTo: tableView.superview!.leadingAnchor),
                        tableView.trailingAnchor.constraint(equalTo: tableView.superview!.trailingAnchor),
                        tableView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor)]

        emptyResultsBottomConstraint = emptyResultsView.bottomAnchor.constraint(equalTo: emptyResultsView.superview!.bottomAnchor)

        constraints += [
            emptyResultsView.leadingAnchor.constraint(equalTo: emptyResultsView.superview!.leadingAnchor),
            emptyResultsView.trailingAnchor.constraint(equalTo: emptyResultsView.superview!.trailingAnchor),
            emptyResultsBottomConstraint]

        constraints += [noContactsLabel.topAnchor.constraint(equalTo: searchHeaderViewController.view.bottomAnchor, constant: standardOffset),

                        noContactsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardOffset),
                        noContactsLabel.trailingAnchor.constraint(equalTo: noContactsLabel.superview!.trailingAnchor)]


        bottomContainerBottomConstraint = bottomContainerView.bottomAnchor.constraint(equalTo: bottomContainerView.superview!.bottomAnchor)

        constraints += [bottomContainerBottomConstraint,
                        bottomContainerView.leadingAnchor.constraint(equalTo: bottomContainerView.superview!.leadingAnchor),
                        bottomContainerView.trailingAnchor.constraint(equalTo: bottomContainerView.superview!.trailingAnchor),

                        bottomContainerSeparatorView.topAnchor.constraint(equalTo: bottomContainerSeparatorView.superview!.topAnchor),
                        bottomContainerSeparatorView.leadingAnchor.constraint(equalTo: bottomContainerSeparatorView.superview!.leadingAnchor),
                        bottomContainerSeparatorView.trailingAnchor.constraint(equalTo: bottomContainerSeparatorView.superview!.trailingAnchor),

                        bottomContainerSeparatorView.heightAnchor.constraint(equalToConstant: 0.5)]

        bottomEdgeConstraint = inviteOthersButton.bottomAnchor.constraint(equalTo: inviteOthersButton.superview!.bottomAnchor, constant: -(standardOffset / 2.0 + UIScreen.safeArea.bottom))

        constraints += [bottomEdgeConstraint,
                        inviteOthersButton.topAnchor.constraint(equalTo: inviteOthersButton.superview!.topAnchor, constant: standardOffset / CGFloat(2)),
                        inviteOthersButton.leadingAnchor.constraint(equalTo: inviteOthersButton.superview!.leadingAnchor, constant: standardOffset),
                        inviteOthersButton.trailingAnchor.constraint(equalTo: inviteOthersButton.superview!.trailingAnchor, constant: -standardOffset)]

        constraints += [inviteOthersButton.heightAnchor.constraint(equalToConstant: 28)]

        NSLayoutConstraint.activate(constraints)
    }

}
