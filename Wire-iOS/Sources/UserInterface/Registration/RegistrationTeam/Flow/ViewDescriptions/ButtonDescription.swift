//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

final class ButtonDescription {
    var buttonTapped: (() -> ())? = nil
    let title: String
    let accessibilityIdentifier: String

    init(title: String, accessibilityIdentifier: String) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

extension ButtonDescription: ViewDescriptor {
    func create() -> UIView {
        let button = UIButton()
        button.titleLabel?.font = TeamCreationStepController.textButtonFont
        let color = UIColor.Team.textColor
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(color.withAlphaComponent(0.6), for: .highlighted)

        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        button.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title.uppercased(), for: .normal)
        button.accessibilityIdentifier = self.accessibilityIdentifier
        button.addTarget(self, action: #selector(ButtonDescription.buttonTapped(_:)), for: .touchUpInside)
        return button
    }

    dynamic func buttonTapped(_ sender: UIButton) {
        buttonTapped?()
    }
}
