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

extension KeyboardAvoidingViewController {
    @objc
    func createInitialConstraints() {

        let constraints = viewController.view.fitInSuperview(exclude: [.bottom])

        topEdgeConstraint = constraints[.top]
        topEdgeConstraint?.constant = topInset

        if #available(iOS 11.0, *) {
            bottomEdgeConstraint = viewController.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        } else {
            bottomEdgeConstraint = viewController.bottomLayoutGuide.bottomAnchor.constraint(equalTo: bottomLayoutGuide.bottomAnchor, constant: 0)
        }

        bottomEdgeConstraint?.isActive = true
    }
}

