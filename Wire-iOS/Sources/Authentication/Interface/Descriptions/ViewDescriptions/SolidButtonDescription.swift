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

import UIKit
import WireCommonComponents

/**
 * A view that displays a solid button.
 */

class SolidButtonDescription: ValueSubmission {
    let title: String
    let accessibilityIdentifier: String

    var valueSubmitted: ValueSubmitted?
    var valueValidated: ValueValidated?
    var acceptsInput: Bool = true

    init(title: String, accessibilityIdentifier: String) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

extension SolidButtonDescription: ViewDescriptor {
    func create() -> UIView {
        let button = IconButton(fontSpec: .normalSemiboldFont)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(UIColor(white: 1, alpha: 0.6), for: .highlighted)
        button.setBackgroundImageColor(UIColor.Team.activeButton, for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        button.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title.localizedUppercase, for: .normal)
        button.accessibilityIdentifier = self.accessibilityIdentifier
        button.addTarget(self, action: #selector(ButtonDescription.buttonTapped(_:)), for: .touchUpInside)

        let buttonContainer = UIView()
        buttonContainer.addSubview(button)
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 200),
            button.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            button.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            button.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor)
        ])

        return buttonContainer
    }

    @objc dynamic func buttonTapped(_ sender: UIButton) {
        valueSubmitted?(())
    }
}
