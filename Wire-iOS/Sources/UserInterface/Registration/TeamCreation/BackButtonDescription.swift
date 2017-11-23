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

final class BackButtonDescription {
    var buttonTapped: (() -> ())? = nil
}

extension BackButtonDescription: ViewDescriptor {
    func create() -> UIView {
        let button = IconButton()
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        let iconType: ZetaIconType = UIApplication.isLeftToRightLayout ? .chevronLeft : .chevronRight
        button.setIcon(iconType, with: .small, for: .normal)
        button.accessibilityIdentifier = "backButton"
        button.addTarget(self, action: #selector(BackButtonDescription.backButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    dynamic func backButtonTapped(_ sender: UIButton) {
        buttonTapped?()
    }
}

