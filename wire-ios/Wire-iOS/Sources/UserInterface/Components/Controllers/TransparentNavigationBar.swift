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

protocol TransparentBackgroundNavigationBar {
    func configureTransparentBackground()
}

extension TransparentBackgroundNavigationBar where Self: DefaultNavigationBar {
    func configureTransparentBackground() {
        isTranslucent = true
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
    }
}

final class TransparentNavigationBar: DefaultNavigationBar, TransparentBackgroundNavigationBar {

    override var colorSchemeVariant: ColorSchemeVariant {
        return ColorScheme.default.variant
    }

    override func configureBackground() {
        configureTransparentBackground()
    }
}

final class DarkBarItemTransparentNavigationBar: DefaultNavigationBar, TransparentBackgroundNavigationBar {

    override var colorSchemeVariant: ColorSchemeVariant {
        return .light
    }

    override func configureBackground() {
        configureTransparentBackground()
    }

}
