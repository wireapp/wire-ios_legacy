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

/// Naming convention:
///
/// The names of all SemanticColors should follow the format:
///
///  "<usage>.<context/role>.<state?>"
/// The last part is optional
public enum SemanticColors {

    public enum LegacyColors {
        // Legacy accent colors
        static let strongBlue = UIColor(red: 0.141, green: 0.552, blue: 0.827, alpha: 1)
        static let strongLimeGreen = UIColor(red: 0, green: 0.784, blue: 0, alpha: 1)
        static let brightYellow = UIColor(red: 0.996, green: 0.749, blue: 0.007, alpha: 1)
        static let vividRed = UIColor(red: 1, green: 0.152, blue: 0, alpha: 1)
        static let brightOrange = UIColor(red: 1, green: 0.537, blue: 0, alpha: 1)
        static let softPink = UIColor(red: 0.996, green: 0.368, blue: 0.741, alpha: 1)
        static let violet = UIColor(red: 0.615, green: 0, blue: 1, alpha: 1)
    }

    public enum Switch {
        static let backgroundOnStateEnabled = UIColor(light: Asset.green600Light, dark: Asset.green700Dark)
        static let backgroundOffStateEnabled = UIColor(light: Asset.gray70, dark: Asset.gray70)
        static let borderOnStateEnabled = UIColor(light: Asset.green600Light, dark: Asset.green500Dark)
        static let borderOffStateEnabled = UIColor(light: Asset.gray70, dark: Asset.gray60)
    }

    public enum Label {
        static let textDefault = UIColor(light: Asset.black, dark: Asset.white)
        static let textDefaultWhite = UIColor(light: Asset.white, dark: Asset.black)
        static let textWhite = UIColor(light: Asset.white, dark: Asset.white)
        static let textSectionFooter = UIColor(light: Asset.gray90, dark: Asset.gray20)
        static let textSectionHeader = UIColor(light: Asset.gray70, dark: Asset.gray50)
        static let textCellSubtitle = UIColor(light: Asset.gray90, dark: Asset.white)
        static let textNoResults = UIColor(light: Asset.black, dark: Asset.gray20)
        static let textSettingsPasswordPlaceholder = UIColor(light: Asset.gray70, dark: Asset.gray60)
        static let textLinkHeaderCellTitle = UIColor(light: Asset.gray100, dark: Asset.white)
        static let textUserPropertyCellName = UIColor(light: Asset.gray80, dark: Asset.gray40)
        static let textConversationQuestOptionInfo = UIColor(light: Asset.gray90, dark: Asset.gray20)
        static let textConversationListItemSubtitleField = UIColor(light: Asset.gray90, dark: Asset.gray20)
        static let textMessageDetails = UIColor(light: Asset.gray70, dark: Asset.gray40)
        static let textErrorDefault = UIColor(light: Asset.red500Light, dark: Asset.red500Dark)
        static let textPasswordRulesCheck = UIColor(light: Asset.gray80, dark: Asset.gray20)

    }

    public enum SearchBar {
        static let textInputView = UIColor(light: Asset.black, dark: Asset.white)
        static let textInputViewPlaceholder = UIColor(light: Asset.gray70, dark: Asset.gray60)
        static let backgroundInputView = UIColor(light: Asset.white, dark: Asset.black)
        static let borderInputView = UIColor(light: Asset.gray40, dark: Asset.gray80)
        static let backgroundButton = UIColor(light: Asset.black, dark: Asset.white)
    }

    public enum Icon {
        static let backgroundIconDefaultConversationView = UIColor(light: Asset.gray70, dark: Asset.gray60)
        static let foregroundPlainCheckMark = UIColor(light: Asset.black, dark: Asset.white)
        static let foregroundCheckMarkSelected = UIColor(light: Asset.white, dark: Asset.black)
        static let borderCheckMark = UIColor(light: Asset.gray80, dark: Asset.gray60)
        static let backgroundCheckMark = UIColor(light: Asset.gray20, dark: Asset.gray90)
        static let backgroundCheckMarkSelected = UIColor(light: Asset.blue500Light, dark: Asset.blue500Dark)
        static let foregroundDefault = UIColor(light: Asset.gray90, dark: Asset.white)
        static let foregroundDefaultBlack = UIColor(light: Asset.black, dark: Asset.white)
        static let foregroundDefaultWhite = UIColor(light: Asset.white, dark: Asset.black)
        static let foregroundPlainDownArrow = UIColor(light: Asset.gray90, dark: Asset.gray20)
        static let backgroundJoinCall = UIColor(light: Asset.green500Light, dark: Asset.green500Dark)
        static let foregroundAvailabilityAvailable = UIColor(light: Asset.green500Light, dark: Asset.green500Dark)
        static let foregroundAvailabilityBusy = UIColor(light: Asset.amber500Light, dark: Asset.amber500Dark)
        static let foregroundAvailabilityAway = UIColor(light: Asset.red500Light, dark: Asset.red500Dark)
        static let backgroundPasswordRuleCheck = UIColor(light: Asset.gray80, dark: Asset.gray20)
        static let backgroundPhoneCall = UIColor(light: Asset.green500Light, dark: Asset.green500Dark)
        static let backgroundMissedPhoneCall = UIColor(light: Asset.red500Light, dark: Asset.red500Dark)
    }

    public enum View {
        static let backgroundDefault = UIColor(light: Asset.gray20, dark: Asset.gray100)
        static let backgroundDefaultBlack = UIColor(light: Asset.black, dark: Asset.white)
        static let backgroundDefaultWhite = UIColor(light: Asset.white, dark: Asset.black)
        static let backgroundConversationView = UIColor(light: Asset.gray10, dark: Asset.gray95)
        static let backgroundUserCell = UIColor(light: Asset.white, dark: Asset.gray95)
        static let backgroundUserCellHightLighted = UIColor(light: Asset.gray40, dark: Asset.gray100)
        static let backgroundSeparatorCell = UIColor(light: Asset.gray40, dark: Asset.gray90)
        static let backgroundSeparatorEditView = UIColor(light: Asset.gray60, dark: Asset.gray70)
        static let backgroundConversationList = UIColor(light: Asset.gray20, dark: Asset.gray100)
        static let backgroundConversationListTableViewCell = UIColor(light: Asset.white, dark: Asset.gray95)
        static let borderConversationListTableViewCell = UIColor(light: Asset.gray40, dark: Asset.gray90)
        static let borderConversationListTableViewCellBadgeReverted = UIColor(light: Asset.gray40, dark: Asset.gray70)
        static let backgroundSecurityLevel = UIColor(light: Asset.gray20, dark: Asset.gray95)
        static let backgroundSeparatorConversationView = UIColor(light: Asset.gray70, dark: Asset.gray60)
        static let borderAvailabilityIcon = UIColor(light: Asset.gray10, dark: Asset.gray90)
        static let borderCharacterInputField = UIColor(light: Asset.gray80, dark: Asset.gray40)
        static let borderCharacterInputFieldEnabled = UIColor(light: Asset.blue500Light, dark: Asset.blue500Dark)
        static let borderInputBar = UIColor(light: Asset.gray40, dark: Asset.gray100)
        static let backgroundBlue = UIColor(light: Asset.blue100Light, dark: Asset.blue900Dark)
        static let backgroundGreen = UIColor(light: Asset.green100Light, dark: Asset.green900Dark)
        static let backgroundAmber = UIColor(light: Asset.amber100Light, dark: Asset.amber900Dark)
        static let backgroundRed = UIColor(light: Asset.red100Light, dark: Asset.red900Dark)
        static let backgroundPurple = UIColor(light: Asset.purple100Light, dark: Asset.purple900Dark)
        static let backgroundTurqoise = UIColor(light: Asset.turquoise100Light, dark: Asset.turquoise900Dark)
    }

    public enum TabBar {
        static let backgroundSeperatorSelected = UIColor(light: Asset.black, dark: Asset.white)
    }

    public enum Button {
        static let backgroundBarItem = UIColor(light: Asset.white, dark: Asset.gray90)
        static let backgroundSecondaryEnabled = UIColor(light: Asset.white, dark: Asset.gray95)
        static let backgroundSecondaryInConversationViewEnabled = UIColor(light: Asset.white, dark: Asset.gray100)
        static let backgroundSecondaryHighlighted = UIColor(light: Asset.white, dark: Asset.gray80)
        static let textSecondaryEnabled = UIColor(light: Asset.black, dark: Asset.white)
        static let borderSecondaryEnabled = UIColor(light: Asset.gray40, dark: Asset.gray80)
        static let borderSecondaryHighlighted = UIColor(light: Asset.gray40, dark: Asset.gray60)
        static let backgroundPrimaryEnabled = UIColor(light: Asset.blue500Light, dark: Asset.blue500Dark)
        static let backgroundPrimaryHighlighted = UIColor(light: Asset.blue500Light, dark: Asset.blue400Light)
        static let backgroundPrimaryDisabled = UIColor(light: Asset.gray50, dark: Asset.gray70)
        static let textPrimaryEnabled = UIColor(light: Asset.white, dark: Asset.black)
        static let textPrimaryDisabled = UIColor(light: Asset.gray80, dark: Asset.black)
        static let textEmptyEnabled = UIColor(light: Asset.black, dark: Asset.white)
        static let textBottomBarNormal = UIColor(light: Asset.gray90, dark: Asset.gray50)
        static let textBottomBarSelected = UIColor(light: Asset.white, dark: Asset.black)
        static let textUnderlineEnabled = UIColor(light: Asset.blue500Light, dark: Asset.blue500Dark)
        static let borderBarItem = UIColor(light: Asset.gray40, dark: Asset.gray100)
        static let backgroundLikeEnabled = UIColor(light: Asset.gray70, dark: Asset.gray60)
        static let backgroundLikeHighlighted = UIColor(light: Asset.red500Light, dark: Asset.red500Dark)
        static let backgroundSendDisabled = UIColor(light: Asset.gray70, dark: Asset.gray70)
        static let backgroundInputBarItemEnabled = UIColor(light: Asset.white, dark: Asset.gray90)
        static let backgroundInputBarItemHighlighted = UIColor(light: Asset.blue50Light, dark: Asset.blue800Dark)
        static let borderInputBarItemEnabled = UIColor(light: Asset.gray40, dark: Asset.gray100)
        static let borderInputBarItemHighlighted = UIColor(light: Asset.blue300Light, dark: Asset.blue700Dark)
        static let textInputBarItemEnabled = UIColor(light: Asset.black, dark: Asset.white)
        static let textInputBarItemHighlighted = UIColor(light: Asset.blue500Light, dark: Asset.white)
        static let textUnderlineEnabledDefault = UIColor(light: Asset.black, dark: Asset.white)
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
        case .turquoise:
            self.init(light: Asset.turquoise500Light, dark: Asset.turquoise500Dark)
        case .purple:
            self.init(light: Asset.purple500Light, dark: Asset.purple500Dark)
        }
    }
    convenience init(fromZMAccentColor accentColor: ZMAccentColor) {
        let safeAccentColor = AccentColor(ZMAccentColor: accentColor) ?? .blue
        self.init(for: safeAccentColor)
    }
}
