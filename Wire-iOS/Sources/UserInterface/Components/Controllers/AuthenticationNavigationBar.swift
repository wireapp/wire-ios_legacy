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

final class AuthenticationNavigationBar: DefaultNavigationBar {

    override var colorSchemeVariant: ColorSchemeVariant {
        return .light
    }

    override func configureBackground() {
        isTranslucent = true
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
    }

}

extension AuthenticationNavigationBar {

    static func makeBackButton(isLegacy: Bool = true) -> IconButton {
        let button = IconButton(style: .default)
        button.setIcon(UIApplication.isLeftToRightLayout ? .backArrow : .forwardArrow, size: .tiny, for: .normal)

        if !isLegacy {
            button.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
            button.setIconColor(SemanticColors.Icon.foregroundDefault.withAlphaComponent(0.4), for: .highlighted)
        } else {
            button.setIconColor(.graphite, for: .normal)
            button.setIconColor(.graphiteAlpha40, for: .highlighted)
        }

        button.contentHorizontalAlignment = UIApplication.isLeftToRightLayout ? .left : .right
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 20)
        button.accessibilityIdentifier = "back"
        button.accessibilityLabel = "general.back".localized
        return button
    }

}
