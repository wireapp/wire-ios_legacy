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
import WireDataModel
import WireCommonComponents

public enum SemanticColors {

    public enum LegacyColors {

        // Legacy accent colors
        public static let strongBlue = UIColor(red: 0.141, green: 0.552, blue: 0.827, alpha: 1)
        public static let strongLimeGreen = UIColor(red: 0, green: 0.784, blue: 0, alpha: 1)
        public static let brightYellow = UIColor(red: 0.996, green: 0.749, blue: 0.007, alpha: 1)
        public static let vividRed = UIColor(red: 1, green: 0.152, blue: 0, alpha: 1)
        public static let brightOrange = UIColor(red: 1, green: 0.537, blue: 0, alpha: 1)
        public static let softPink = UIColor(red: 0.996, green: 0.368, blue: 0.741, alpha: 1)
        public static let violet = UIColor(red: 0.615, green: 0, blue: 1, alpha: 1)
    }
    public enum SwitchColors {
        public static let backgroundSwitchOnStateEnabled = UIColor(light: Asset.green600Light, dark: Asset.green600Light)
        public static let backgroundSwitchOffStateEnabled = UIColor(light: Asset.gray70, dark: Asset.gray70)
    }
    public enum SearchBarColor {
        public static let textSearchBarUserInput = UIColor(light: Asset.black, dark: Asset.white)
    }

        static let textFooterLabelConversationDetails = UIColor(light: Asset.gray90, dark: Asset.gray20)
        static let textHeaderLabelConversationDetails = UIColor(light: Asset.gray70, dark: Asset.gray50)
        static let textLabelCellTitleActive = UIColor(light: Asset.black, dark: Asset.white)
        static let textLabelCellSubtitleActive = UIColor(light: Asset.gray90, dark: Asset.white)
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

public extension UIColor {

    convenience init(for accentColor: AccentColor) {
        switch accentColor {
        case .blue:
            self.init(light: Asset.blue500Light, dark: Asset.blue500Dark)
        case .green:
            self.init(light: Asset.green500Light, dark: Asset.green500Dark)
        case .yellow: // Deprecated
            self.init(red: 0.996, green: 0.749, blue: 0.007, alpha: 1)
        case .red:
            self.init(light: Asset.red500Light, dark: Asset.red500Dark)
        case .amber:
            self.init(light: Asset.amber500Light, dark: Asset.amber500Dark)
        case .petrol:
            self.init(light: Asset.petrol500Light, dark: Asset.petrol500Dark)
        case .purple:
            self.init(light: Asset.purple500Light, dark: Asset.purple500Dark)
        }
    }

    convenience init(fromZMAccentColor accentColor: ZMAccentColor) {
        let safeAccentColor = AccentColor(ZMAccentColor: accentColor) ?? .blue
        self.init(for: safeAccentColor)
    }

}
