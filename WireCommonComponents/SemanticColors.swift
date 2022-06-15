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
    case buttonBackground
    
    var colorValue: UIColor {
        switch self {
        case .buttonBackground:
            return colorHelper(
                light: Asset.red50Dark.color,
                dark: Asset.blue500Light.color)
        }
    }
    
    private func colorHelper(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return dark
                } else {
                    /// Return the color for Light Mode
                    return light
                }
            }
        } else {
            // Fallback on earlier versions (it there is 12 verion in app this must be specified. Otherwise it won't compile
            return light
        }
    }
    
    
}
