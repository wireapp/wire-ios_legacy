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

public enum SemanticColors {

    public enum LegacyColors {

        // Legacy accent colors
        public static let strongBlue = UIColor(red: 0.141, green: 0.552, blue: 0.827, alpha: 1)
        public static let strongLimeGreen = UIColor(red: 0, green: 0.784, blue: 0, alpha: 1)
        public static let brightYellow = UIColor(red: 0.996, green: 0.749, blue: 0.007, alpha: 1)
        public static let vividRed = UIColor(red: 1, green: 0.152, blue: 0, alpha: 1)
        public static let brightOrange = UIColor(red: 1, green: 0.537, blue: 0, alpha: 1)
        public static let softPink = UIColor(red: 0.996, green: 0.368, blue: 0.741, alpha:1)
        public static let violet = UIColor(red: 0.615, green: 0, blue: 1, alpha: 1)
    }

}

extension UIColor {

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
