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
    override open func updateViewConstraints() {
        updateViewConstraints(device: UIDevice.current)
    }


    /// updateViewConstraints with arugument for mocking UIDevice for testing
    ///
    /// - Parameter device: this value is only for testing
    func updateViewConstraints(device: DeviceProtocol = UIDevice.current) {
        super.updateViewConstraints()

        guard false == self.initialConstraintsCreated else { return }

        self.initialConstraintsCreated = true

        let horizontalInset: CGFloat = 28

        constrain(titleLabel, termsOfUseText, agreeButton, containerView) { titleLabel, termsOfUseText, agreeButton, containerView in
            titleLabel.right == containerView.right - horizontalInset
            titleLabel.left == containerView.left + horizontalInset

            termsOfUseText.top == titleLabel.bottom + 5

            agreeButton.top == termsOfUseText.bottom + 24
            agreeButton.bottom == containerView.bottom - horizontalInset
            agreeButton.height == 40

            align(right: titleLabel, termsOfUseText, agreeButton)
            align(left: titleLabel, termsOfUseText, agreeButton)
        }

        if self.isIPadRegular(device: device) {
            constrain(containerView, self.view) { containerView, selfView in
                containerView.width == self.registrationForm().maximumFormSize.width
                containerView.height == self.registrationForm().maximumFormSize.height

                containerView.center == selfView.center
            }
        } else {
            constrain(containerView, self.view) { containerView, selfView in
                containerView.edges == selfView.edges
            }
        }
    }
}
