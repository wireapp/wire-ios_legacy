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

enum SemanticColors {

    static let buttonBackground = UIColor(light: Asset.red200Light, dark: Asset.green500Dark)

}

private extension UIColor {

    convenience init(light: ColorAsset, dark: ColorAsset) {
        if #available(iOS 13.0, *) {
            self.init { traits in
                return traits.userInterfaceStyle == .dark ? dark.color : light.color
            }
        } else {
            switch ColorScheme.default.variant {
            case .light:
                self.init(asset: light)!
            case .dark:
                self.init(asset: dark)!
            }
        }
    }

}
