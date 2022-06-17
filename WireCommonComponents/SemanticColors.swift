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

    static let buttonBackground = UIColor(light: Asset.red200Light.color, dark: Asset.green500Dark.color)

}

extension UIColor {

    convenience init(light: UIColor, dark: UIColor) {
        if #available(iOS 13.0, *) {
            self.init { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            // TODO: [Katerina] we should remove this when we stop supporting iOS 12.
            switch ColorScheme.default.variant {
            case .light:
                self.init(cgColor: light.cgColor)
            case .dark:
                self.init(cgColor: dark.cgColor)
            }
        }
    }

}
