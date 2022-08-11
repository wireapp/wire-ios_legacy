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

    public enum Switch {
        static let backgroundOnStateEnabled = UIColor(light: Asset.green600Light, dark: Asset.green700Dark)
        static let backgroundOffStateEnabled = UIColor(light: Asset.gray70, dark: Asset.gray70)
        static let borderOnStateEnabled = UIColor(light: Asset.green600Light, dark: Asset.green500Dark)
        static let borderOffStateEnabled = UIColor(light: Asset.gray70, dark: Asset.gray60)
    }

    public enum Label {
        static let textDefault = UIColor(light: Asset.black, dark: Asset.white)
        static let textSectionFooter = UIColor(light: Asset.gray90, dark: Asset.gray20)
        static let textSectionHeader = UIColor(light: Asset.gray70, dark: Asset.gray50)
        static let textCellTitle = UIColor(light: Asset.black, dark: Asset.white)
        static let textCellSubtitle = UIColor(light: Asset.gray90, dark: Asset.white)
        static let textNoResults = UIColor(light: Asset.black, dark: Asset.gray20)
        static let textMessageDetails = UIColor(light: Asset.gray70, dark: Asset.gray40)
    }

    public enum SearchBar {
        static let textInputView = UIColor(light: Asset.black, dark: Asset.white)
        static let textInputViewPlaceholder = UIColor(light: Asset.gray70, dark: Asset.gray60)
        static let backgroundInputView = UIColor(light: Asset.white, dark: Asset.black)
        static let borderInputView = UIColor(light: Asset.gray40, dark: Asset.gray80)
        static let backgroundButton = UIColor(light: Asset.black, dark: Asset.white)
    }

    public enum View {
        static let backgroundDefault = UIColor(light: Asset.gray20, dark: Asset.gray100)
        static let backgroundConversationView = UIColor(light: Asset.gray10, dark: Asset.gray95)
        static let backgroundUserCell = UIColor(light: Asset.white, dark: Asset.gray95)
        static let backgroundUserCellHightLighted = UIColor(light: Asset.gray40, dark: Asset.gray100)
        static let backgroundSeparatorCell = UIColor(light: Asset.gray40, dark: Asset.gray90)
    }

    public enum Icon {
        static let foregroundPlainCheckMark = UIColor(light: Asset.black, dark: Asset.white)
        static let foregroundCheckMarkSelected = UIColor(light: Asset.white, dark: Asset.black)
        static let borderCheckMark = UIColor(light: Asset.gray80, dark: Asset.gray60)
        static let backgroundCheckMark = UIColor(light: Asset.gray20, dark: Asset.gray90)
        static let backgroundCheckMarkSelected = UIColor(light: Asset.blue500Light, dark: Asset.blue500Dark)
        static let foregroundDefault = UIColor(light: Asset.gray90, dark: Asset.white)
    }

    public enum TabBar {
        static let backgroundSeperatorSelected = UIColor(light: Asset.black, dark: Asset.white)
    }

    public enum Button {
        static let backgroundSecondaryEnabled = UIColor(light: Asset.white, dark: Asset.gray95)
        static let backgroundSecondaryHighlighted = UIColor(light: Asset.white, dark: Asset.gray80)
        static let textSecondaryEnabled = UIColor(light: Asset.black, dark: Asset.white)
        static let borderSecondaryEnabled = UIColor(light: Asset.gray40, dark: Asset.gray80)
        static let borderSecondaryHighlighted = UIColor(light: Asset.gray40, dark: Asset.gray60)

        static let backgroundPrimaryEnabled = UIColor(light: Asset.blue500Light, dark: Asset.blue500Dark)
        static let backgroundPrimaryHighlighted = UIColor(light: Asset.blue500Light, dark: Asset.blue400Light)
        static let textPrimaryEnabled = UIColor(light: Asset.white, dark: Asset.black)
    }

}

extension UIColor {
    convenience init(light: ColorAsset, dark: ColorAsset) {
        self.init { traits in
            return traits.userInterfaceStyle == .dark ? dark.color : light.color
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
