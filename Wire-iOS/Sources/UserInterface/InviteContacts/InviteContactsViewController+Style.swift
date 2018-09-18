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

extension InviteContactsViewController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        ///hide titleLabel and cancel cross button, which is duplicated in the navi bar

        let subViewConstraints = [titleLabelHeightConstraint, titleLabelTopConstraint, titleLabelBottomConstraint, closeButtonTopConstraint, closeButtonBottomConstraint]

        if navigationController != nil {
            titleLabel.isHidden = true

            cancelButton.isHidden = true
            closeButtonHeightConstraint.constant = 0
            subViewConstraints.forEach(){ $0?.isActive = false }

            topContainerHeightConstraint.isActive = true
        } else {
            titleLabel.isHidden = false

            cancelButton.isHidden = false

            closeButtonHeightConstraint.constant = 16
            topContainerHeightConstraint.isActive = false

            subViewConstraints.forEach(){ $0?.isActive = true }
        }

        view.layoutIfNeeded()
    }

    @objc override func setupStyle() {
        super.setupStyle()

        view.backgroundColor = .clear

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = .accent()

        bottomContainerSeparatorView.backgroundColor = UIColor(scheme: .separator, variant: .dark)
        bottomContainerView.backgroundColor = .clear

        titleLabel?.textColor = UIColor(scheme: .textForeground, variant: .dark)
    }
}
