//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

final class UnderlineButtonDescription {

    var buttonTapped: (() -> Void)?
    let title: String
    let accessibilityIdentifier: String

    init(title: String, accessibilityIdentifier: String) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

extension UnderlineButtonDescription: ViewDescriptor {
    func create() -> UIView {
        let button = DynamicFontButton(fontSpec: .smallSemiboldFont)
        let yourAttributes: [NSAttributedString.Key: Any] = [
            .font: FontSpec.smallSemiboldFont.font!,
            .foregroundColor: SemanticColors.Button.textUnderlineEnabled,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let attributeString = NSMutableAttributedString(
            string: title,
            attributes: yourAttributes
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(attributeString, for: .normal)
        button.accessibilityIdentifier = self.accessibilityIdentifier
        button.addTarget(self, action: #selector(UnderlineButtonDescription.buttonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc dynamic func buttonTapped(_ sender: UIButton) {
        buttonTapped?()
    }
}

