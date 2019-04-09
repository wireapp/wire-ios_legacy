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

    @objc
    func createConstraints() {
        [backgroundBlurView,
         shareContactsContainerView,
         addressBookAccessDeniedViewController.view,
         heroLabel,
         shareContactsButton].forEach(){ $0.translatesAutoresizingMaskIntoConstraints = false }

        var constraints = shareContactsContainerView.fitInSuperview(activate: false).map{$0.value}

        constraints += backgroundBlurView.fitInSuperview(activate: false).map{$0.value}

        constraints += addressBookAccessDeniedViewController.view.fitInSuperview(activate: false).values

        constraints += heroLabel.fitInSuperview(with: EdgeInsets(margin: 28), exclude: [.top, .bottom], activate: false).values

        constraints += [shareContactsButton.topAnchor.constraint(equalTo: heroLabel.bottomAnchor, constant: 24),
                        shareContactsButton.heightAnchor.constraint(equalToConstant: 40)]

        constraints += shareContactsButton.fitInSuperview(with: EdgeInsets(top: 0, leading: 28, bottom: 28, trailing: 28), exclude: [.top], activate: false).values

        NSLayoutConstraint.activate(constraints)
    }
}


