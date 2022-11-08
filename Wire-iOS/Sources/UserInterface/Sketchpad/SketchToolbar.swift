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
        separatorLine.backgroundColor = SemanticColors.View.backgroundSeparatorCell

        super.init(frame: CGRect.zero)

        setupSubviews()
        createButtonContraints(buttons: buttons)
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        backgroundColor = SemanticColors.View.backgroundDefaultWhite
        addSubview(containerView)
        centerButtons.forEach(centerButtonContainer.addSubview)
        [leftButton, centerButtonContainer, rightButton, separatorLine].forEach(containerView.addSubview)
    }

    private func createButtonContraints(buttons: [UIButton]) {
        for button in buttons {
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
              button.widthAnchor.constraint(equalToConstant: 32),
              button.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }

    private func createConstraints() {
        let buttonSpacing: CGFloat = 8

        [containerView, leftButton, rightButton, centerButtonContainer, separatorLine].prepareForLayout()
        NSLayoutConstraint.activate([
            containerView.leftAnchor.constraint(equalTo: leftAnchor),
            containerView.rightAnchor.constraint(equalTo: rightAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UIScreen.safeArea.bottom),

            containerView.heightAnchor.constraint(equalToConstant: 56),

          leftButton.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: buttonSpacing),
          leftButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

          rightButton.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -buttonSpacing),
          rightButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

          centerButtonContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
          centerButtonContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
          centerButtonContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

          separatorLine.topAnchor.constraint(equalTo: containerView.topAnchor),
          separatorLine.leftAnchor.constraint(equalTo: containerView.leftAnchor),
          separatorLine.rightAnchor.constraint(equalTo: containerView.rightAnchor),
          separatorLine.heightAnchor.constraint(equalToConstant: .hairline)
        ])

        createCenterButtonConstraints()
    }

    private func createCenterButtonConstraints() {
        guard !centerButtons.isEmpty,
        let leftButton = centerButtons.first,
        let rightButton = centerButtons.last else { return }

        let buttonSpacing: CGFloat = 32

        [centerButtonContainer, leftButton, rightButton].prepareForLayout()

        var constraints = [
          leftButton.leftAnchor.constraint(equalTo: centerButtonContainer.leftAnchor, constant: buttonSpacing),
          leftButton.centerYAnchor.constraint(equalTo: centerButtonContainer.centerYAnchor),

          rightButton.rightAnchor.constraint(equalTo: centerButtonContainer.rightAnchor, constant: -buttonSpacing),
          rightButton.centerYAnchor.constraint(equalTo: centerButtonContainer.centerYAnchor)
        ]

        for i in 1..<centerButtons.count {
            let previousButton = centerButtons[i-1]
            let button = centerButtons[i]

            [button, previousButton].prepareForLayout()
            constraints.append(contentsOf: [
              button.leftAnchor.constraint(equalTo: previousButton.rightAnchor, constant: buttonSpacing),
              button.centerYAnchor.constraint(equalTo: centerButtonContainer.centerYAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }

}
