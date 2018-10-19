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

extension SplitViewController {
    @objc func setupInitialConstraints() {
        guard let leftView = leftView,
            let rightView = rightView else { return }

        leftViewOffsetConstraint = leftView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leftViewOffsetConstraint.priority = UILayoutPriority.defaultHigh
        rightViewOffsetConstraint = rightView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        rightViewOffsetConstraint.priority = UILayoutPriority.defaultHigh

        leftViewWidthConstraint = leftView.widthAnchor.constraint(equalToConstant: 0)
        rightViewWidthConstraint = rightView.widthAnchor.constraint(equalToConstant: 0)

        pinLeftViewOffsetConstraint = leftView.leftAnchor.constraint(equalTo: view.leftAnchor)
        sideBySideConstraint = rightView.leftAnchor.constraint(equalTo: leftView.rightAnchor)
        sideBySideConstraint.isActive = false

        let constraints: [NSLayoutConstraint] =
            [leftView.topAnchor.constraint(equalTo: view.topAnchor), leftView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
             rightView.topAnchor.constraint(equalTo: view.topAnchor), rightView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
             leftViewOffsetConstraint,
             rightViewOffsetConstraint,
             leftViewWidthConstraint,
             rightViewWidthConstraint,
             pinLeftViewOffsetConstraint]

        NSLayoutConstraint.activate(constraints)
    }

    @objc func updateActiveConstraints() {
        guard let constraintsInactiveForCurrentLayout = constraintsInactiveForCurrentLayout() as? [NSLayoutConstraint],
        let constraintsActiveForCurrentLayout = constraintsActiveForCurrentLayout() as? [NSLayoutConstraint] else { return }
        NSLayoutConstraint.deactivate(constraintsInactiveForCurrentLayout)
        NSLayoutConstraint.activate(constraintsActiveForCurrentLayout)
    }
}

