//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import UIKit
import Cartography

class SketchToolbar: UIView {

    let containerView = UIView()
    let leftButton: UIButton!
    let rightButton: UIButton!
    let centerButtons: [UIButton]
    let centerButtonContainer = UIView()
    let separatorLine = UIView()

    public init(buttons: [UIButton]) {

        guard buttons.count >= 2 else {  fatalError("SketchToolbar needs to be initialized with at least two buttons") }

        var unassignedButtons = buttons

        leftButton = unassignedButtons.removeFirst()
        rightButton = unassignedButtons.removeLast()
        centerButtons = unassignedButtons
        separatorLine.backgroundColor = UIColor.from(scheme: .separator)

        super.init(frame: CGRect.zero)

        setupSubviews()
        createButtonContraints(buttons: buttons)
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        backgroundColor = UIColor.from(scheme: .background)
        addSubview(containerView)
        centerButtons.forEach(centerButtonContainer.addSubview)
        [leftButton, centerButtonContainer, rightButton, separatorLine].forEach(containerView.addSubview)
    }

    func createButtonContraints(buttons: [UIButton]) {
        for button in buttons {
            constrain(button) { button in
                button.width == 32
                button.height == 32
            }
        }
    }

    func createConstraints() {
        let buttonSpacing: CGFloat = 8

        constrain(self, containerView) { parentView, container in
            container.left == parentView.left
            container.right == parentView.right
            container.top == parentView.top
            container.bottom == parentView.bottom - UIScreen.safeArea.bottom
        }

        constrain(containerView, leftButton, rightButton, centerButtonContainer, separatorLine) { container, leftButton, rightButton, centerButtonContainer, separatorLine in
            container.height == 56

            leftButton.left == container.left + buttonSpacing
            leftButton.centerY == container.centerY

            rightButton.right == container.right - buttonSpacing
            rightButton.centerY == container.centerY

            centerButtonContainer.centerX == container.centerX
            centerButtonContainer.top == container.top
            centerButtonContainer.bottom == container.bottom

            separatorLine.top == container.top
            separatorLine.left == container.left
            separatorLine.right == container.right
            separatorLine.height == .hairline
        }

        createCenterButtonConstraints()
    }

    func createCenterButtonConstraints() {
        guard !centerButtons.isEmpty else { return }

        let buttonSpacing: CGFloat = 32
        let leftButton = centerButtons.first!
        let rightButton = centerButtons.last!

        constrain(centerButtonContainer, leftButton, rightButton) { container, leftButton, rightButton in
            leftButton.left == container.left + buttonSpacing
            leftButton.centerY == container.centerY

            rightButton.right == container.right - buttonSpacing
            rightButton.centerY == container.centerY
        }

        for i in 1..<centerButtons.count {
            let previousButton = centerButtons[i-1]
            let button = centerButtons[i]

            constrain(centerButtonContainer, button, previousButton) { container, button, previousButton in
                button.left == previousButton.right + buttonSpacing
                button.centerY == container.centerY
            }
        }
    }

}
