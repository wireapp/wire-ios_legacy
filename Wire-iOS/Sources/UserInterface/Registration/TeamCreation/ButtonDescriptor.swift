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
        button.contentEdgeInsets = UIEdgeInsetsMake(4, 12, 4, 12)
        button.tintColor = .black
        button.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        button.backgroundColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.accessibilityIdentifier = self.accessibilityIdentifier
        button.addTarget(self, action: #selector(ButtonDescription.buttonTapped(_:)), for: .touchUpInside)
        return button
    }

    dynamic func buttonTapped(_ sender: UIButton) {
        buttonTapped?()
    }
}
