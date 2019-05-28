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

extension ShareContactsViewController {

    // MARK: - Constraints
    @objc
    func createConstraints() {
        [backgroundBlurView,
         shareContactsContainerView,
         addressBookAccessDeniedViewController.view,
         heroLabel,
         shareContactsButton].forEach(){ $0.translatesAutoresizingMaskIntoConstraints = false }

        let constraints: [NSLayoutConstraint] = [shareContactsContainerView.topAnchor.constraint(equalTo: shareContactsContainerView.superview!.topAnchor),
                                                 shareContactsContainerView.bottomAnchor.constraint(equalTo: shareContactsContainerView.superview!.bottomAnchor),
                                                 shareContactsContainerView.leadingAnchor.constraint(equalTo: shareContactsContainerView.superview!.leadingAnchor),
                                                 shareContactsContainerView.trailingAnchor.constraint(equalTo: shareContactsContainerView.superview!.trailingAnchor),

                                                 backgroundBlurView.topAnchor.constraint(equalTo: backgroundBlurView.superview!.topAnchor),
                                                 backgroundBlurView.bottomAnchor.constraint(equalTo: backgroundBlurView.superview!.bottomAnchor),
                                                 backgroundBlurView.leadingAnchor.constraint(equalTo: backgroundBlurView.superview!.leadingAnchor),
                                                 backgroundBlurView.trailingAnchor.constraint(equalTo: backgroundBlurView.superview!.trailingAnchor),

                                                 addressBookAccessDeniedViewController.view.topAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.topAnchor),
                                                 addressBookAccessDeniedViewController.view.bottomAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.bottomAnchor),
                                                 addressBookAccessDeniedViewController.view.leadingAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.leadingAnchor),
                                                 addressBookAccessDeniedViewController.view.trailingAnchor.constraint(equalTo: addressBookAccessDeniedViewController.view.superview!.trailingAnchor),

                                                 heroLabel.leadingAnchor.constraint(equalTo: heroLabel.superview!.leadingAnchor, constant: 28),
                                                 heroLabel.trailingAnchor.constraint(equalTo: heroLabel.superview!.trailingAnchor, constant: -28),

                                                 shareContactsButton.topAnchor.constraint(equalTo: heroLabel.bottomAnchor, constant: 24),
                                                 shareContactsButton.heightAnchor.constraint(equalToConstant: 40),

                                                 shareContactsButton.bottomAnchor.constraint(equalTo: shareContactsButton.superview!.bottomAnchor, constant: -28),
                                                 shareContactsButton.leadingAnchor.constraint(equalTo: shareContactsButton.superview!.leadingAnchor, constant: 28),
                                                 shareContactsButton.trailingAnchor.constraint(equalTo: shareContactsButton.superview!.trailingAnchor, constant: -28)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - AddressBook Access Denied ViewController

    @objc(displayContactsAccessDeniedMessageAnimated:)
    func displayContactsAccessDeniedMessage(animated: Bool) {
        endEditing()

        showingAddressBookAccessDeniedViewController = true

        if animated {
            UIView.transition(from: shareContactsContainerView,
                              to: addressBookAccessDeniedViewController.view,
                              duration: 0.35,
                              options: [.showHideTransitionViews, .transitionCrossDissolve])
        } else {
            shareContactsContainerView.isHidden = true
            addressBookAccessDeniedViewController.view.isHidden = false
        }
    }
}


