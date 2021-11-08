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
        separatorLine.backgroundColor = UIColor.from(scheme: .separator)

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
        backgroundColor = UIColor.from(scheme: .background)
        addSubview(containerView)
        centerButtons.forEach(centerButtonContainer.addSubview)
        [leftButton, centerButtonContainer, rightButton, separatorLine].forEach(containerView.addSubview)
    }

    func createButtonContraints(buttons: [UIButton]) {
        for button in buttons {
            [<#views#>].prepareForLayout()
            NSLayoutConstraint.activate([
              button.widthAnchor.constraint(equalToConstant: 32),
              button.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }

    private func createConstraints() {
        let buttonSpacing: CGFloat = 8

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          container.leftAnchor.constraint(equalTo: parentView.leftAnchor),
          container.rightAnchor.constraint(equalTo: parentView.rightAnchor),
          container.topAnchor.constraint(equalTo: parentView.topAnchor),
          container.bottomAnchor.constraint(equalToConstant: parentView.bottom - UIScreen.safeArea.bottom)
        ])

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          container.heightAnchor.constraint(equalToConstant: 56),

          leftButton.leftAnchor.constraint(equalTo: container.leftAnchor, constant: buttonSpacing),
          leftButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

          rightButton.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -buttonSpacing),
          rightButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

          centerButtonContainer.centerXAnchor.constraint(equalTo: container.centerXAnchor),
          centerButtonContainer.topAnchor.constraint(equalTo: container.topAnchor),
          centerButtonContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),

          separatorLine.topAnchor.constraint(equalTo: container.topAnchor),
          separatorLine.leftAnchor.constraint(equalTo: container.leftAnchor),
          separatorLine.rightAnchor.constraint(equalTo: container.rightAnchor),
          separatorLine.heightAnchor.constraint(equalTo: .hairlineAnchor)
        ])

        createCenterButtonConstraints()
    }

    func createCenterButtonConstraints() {
        guard !centerButtons.isEmpty else { return }

        let buttonSpacing: CGFloat = 32
        let leftButton = centerButtons.first!
        let rightButton = centerButtons.last!

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          leftButton.leftAnchor.constraint(equalTo: container.leftAnchor, constant: buttonSpacing),
          leftButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

          rightButton.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -buttonSpacing),
          rightButton.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        for i in 1..<centerButtons.count {
            let previousButton = centerButtons[i-1]
            let button = centerButtons[i]

            [<#views#>].prepareForLayout()
            NSLayoutConstraint.activate([
              button.leftAnchor.constraint(equalTo: previousButton.rightAnchor, constant: buttonSpacing),
              button.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        }
    }

}
