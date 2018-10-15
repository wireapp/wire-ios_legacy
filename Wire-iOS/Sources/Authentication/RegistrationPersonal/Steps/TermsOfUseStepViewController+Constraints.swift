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
import Cartography

extension TermsOfUseStepViewController {

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateConstraintsForSizeClass()
    }

    @objc func updateConstraintsForSizeClass() {
        guard isiPad else { return }

        switch self.traitCollection.horizontalSizeClass {
        case .compact:
            containerViewWidth.isActive = false
            containerViewHeight.isActive = false
            containerViewCenter.forEach {
                $0.isActive = false
            }

            containerViewEdges.forEach {
                $0.isActive = true
            }
        default:
            containerViewEdges.forEach {
                $0.isActive = false
            }

            containerViewWidth.isActive = true
            containerViewHeight.isActive = true
            containerViewCenter.forEach {
                $0.isActive = true
            }
        }
    }

    override open func updateViewConstraints() {
        super.updateViewConstraints()

        guard false == self.initialConstraintsCreated else { return }

        self.initialConstraintsCreated = true

        let horizontalInset: CGFloat = 28

        constrain(titleLabel, termsOfUseText, agreeButton, containerView) { titleLabel, termsOfUseText, agreeButton, containerView in
            titleLabel.right == containerView.right - horizontalInset
            titleLabel.left == containerView.left + horizontalInset

            termsOfUseText.top == titleLabel.bottom + 5

            agreeButton.top == termsOfUseText.bottom + 24
            agreeButton.bottom == containerView.bottom - 24
            agreeButton.height == 40

            align(right: titleLabel, termsOfUseText, agreeButton)
            align(left: titleLabel, termsOfUseText, agreeButton)
        }

        constrain(containerView, self.view) { containerView, selfView in
            self.containerViewWidth = containerView.width == self.registrationForm().maximumFormSize.width
            self.containerViewHeight = containerView.height == self.registrationForm().maximumFormSize.height

            self.containerViewCenter = containerView.center == selfView.center
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerViewEdges = [
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.topAnchor.constraint(equalTo: safeTopAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeBottomAnchor)
        ]

        NSLayoutConstraint.activate(containerViewEdges)
    }

    var isiPad: Bool {
        guard let device = (self.device as? DeviceProtocol) else { return false }

        return device.userInterfaceIdiom == .pad
    }
}
