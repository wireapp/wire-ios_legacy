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
        static let backgroundOnStateEnabled = UIColor(light: Asset.Colors.green600Light, dark: Asset.Colors.green700Dark)
        static let backgroundOffStateEnabled = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray70)
        static let borderOnStateEnabled = UIColor(light: Asset.Colors.green600Light, dark: Asset.Colors.green500Dark)
        static let borderOffStateEnabled = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray60)
    }

    public enum Label {
        static let textDefault = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
        static let textDefaultWhite = UIColor(light: Asset.Colors.white, dark: Asset.Colors.black)
        static let textWhite = UIColor(light: Asset.Colors.white, dark: Asset.Colors.white)
        static let textSectionFooter = UIColor(light: Asset.Colors.gray90, dark: Asset.Colors.gray20)
        static let textSectionHeader = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray50)
        static let textCellSubtitle = UIColor(light: Asset.Colors.gray90, dark: Asset.Colors.white)
        static let textNoResults = UIColor(light: Asset.Colors.black, dark: Asset.Colors.gray20)
        static let textSettingsPasswordPlaceholder = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray60)
        static let textLinkHeaderCellTitle = UIColor(light: Asset.Colors.gray100, dark: Asset.Colors.white)
        static let textUserPropertyCellName = UIColor(light: Asset.Colors.gray80, dark: Asset.Colors.gray40)
        static let textConversationQuestOptionInfo = UIColor(light: Asset.Colors.gray90, dark: Asset.Colors.gray20)
        static let textConversationListItemSubtitleField = UIColor(light: Asset.Colors.gray90, dark: Asset.Colors.gray20)
        static let textMessageDetails = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray40)
        static let textCollectionSecondary = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray60)
        static let textErrorDefault = UIColor(light: Asset.Colors.red500Light, dark: Asset.Colors.red500Dark)
        static let textPasswordRulesCheck = UIColor(light: Asset.Colors.gray80, dark: Asset.Colors.gray20)
        static let textTabBar = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray60)
    }

    public enum SearchBar {
        static let textInputView = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
        static let textInputViewPlaceholder = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray60)
        static let backgroundInputView = UIColor(light: Asset.Colors.white, dark: Asset.Colors.black)
        static let borderInputView = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray80)
        static let backgroundButton = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
    }

    public enum Icon {
        static let backgroundDefault = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray60)
        static let foregroundPlainCheckMark = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
        static let foregroundCheckMarkSelected = UIColor(light: Asset.Colors.white, dark: Asset.Colors.black)
        static let borderCheckMark = UIColor(light: Asset.Colors.gray80, dark: Asset.Colors.gray60)
        static let backgroundCheckMark = UIColor(light: Asset.Colors.gray20, dark: Asset.Colors.gray90)
        static let backgroundCheckMarkSelected = UIColor(light: Asset.Colors.blue500Light, dark: Asset.Colors.blue500Dark)
        static let foregroundDefault = UIColor(light: Asset.Colors.gray90, dark: Asset.Colors.white)
        static let foregroundDefaultBlack = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
        static let foregroundDefaultWhite = UIColor(light: Asset.Colors.white, dark: Asset.Colors.black)
        static let foregroundDefaultRed = UIColor(light: Asset.Colors.red500Light, dark: Asset.Colors.red500Dark)
        static let foregroundPlainDownArrow = UIColor(light: Asset.Colors.gray90, dark: Asset.Colors.gray20)
        static let backgroundJoinCall = UIColor(light: Asset.Colors.green500Light, dark: Asset.Colors.green500Dark)
        static let foregroundAvailabilityAvailable = UIColor(light: Asset.Colors.green500Light, dark: Asset.Colors.green500Dark)
        static let foregroundAvailabilityBusy = UIColor(light: Asset.Colors.amber500Light, dark: Asset.Colors.amber500Dark)
        static let foregroundAvailabilityAway = UIColor(light: Asset.Colors.red500Light, dark: Asset.Colors.red500Dark)
        static let backgroundPasswordRuleCheck = UIColor(light: Asset.Colors.gray80, dark: Asset.Colors.gray20)
        static let backgroundPhoneCall = UIColor(light: Asset.Colors.green500Light, dark: Asset.Colors.green500Dark)
        static let backgroundMissedPhoneCall = UIColor(light: Asset.Colors.red500Light, dark: Asset.Colors.red500Dark)
    }

    public enum View {
        static let backgroundDefault = UIColor(light: Asset.Colors.gray20, dark: Asset.Colors.gray100)
        static let backgroundDefaultBlack = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
        static let backgroundDefaultWhite = UIColor(light: Asset.Colors.white, dark: Asset.Colors.black)
        static let backgroundConversationView = UIColor(light: Asset.Colors.gray10, dark: Asset.Colors.gray95)
        static let backgroundUserCell = UIColor(light: Asset.Colors.white, dark: Asset.Colors.gray95)
        static let backgroundUserCellHightLighted = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray100)
        static let backgroundSeparatorCell = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray90)
        static let backgroundSeparatorEditView = UIColor(light: Asset.Colors.gray60, dark: Asset.Colors.gray70)
        static let backgroundConversationList = UIColor(light: Asset.Colors.gray20, dark: Asset.Colors.gray100)
        static let backgroundConversationListTableViewCell = UIColor(light: Asset.Colors.white, dark: Asset.Colors.gray95)
        static let borderConversationListTableViewCell = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray90)
        static let borderConversationListTableViewCellBadgeReverted = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray70)
        static let backgroundCollectionCell = UIColor(light: Asset.Colors.white, dark: Asset.Colors.gray90)
        static let borderCollectionCell = UIColor(light: Asset.Colors.gray30, dark: Asset.Colors.gray80)
        static let backgroundSecurityLevel = UIColor(light: Asset.Colors.gray20, dark: Asset.Colors.gray95)
        static let backgroundSeparatorConversationView = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray60)
        static let backgroundReplyMessageViewHighlighted = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray80)
        static let borderAvailabilityIcon = UIColor(light: Asset.Colors.gray10, dark: Asset.Colors.gray90)
        static let borderCharacterInputField = UIColor(light: Asset.Colors.gray80, dark: Asset.Colors.gray40)
        static let borderCharacterInputFieldEnabled = UIColor(light: Asset.Colors.blue500Light, dark: Asset.Colors.blue500Dark)
        static let borderInputBar = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray100)
        static let backgroundBlue = UIColor(light: Asset.Colors.blue100Light, dark: Asset.Colors.blue900Dark)
        static let backgroundGreen = UIColor(light: Asset.Colors.green100Light, dark: Asset.Colors.green900Dark)
        static let backgroundAmber = UIColor(light: Asset.Colors.amber100Light, dark: Asset.Colors.amber900Dark)
        static let backgroundRed = UIColor(light: Asset.Colors.red100Light, dark: Asset.Colors.red900Dark)
        static let backgroundPurple = UIColor(light: Asset.Colors.purple100Light, dark: Asset.Colors.purple900Dark)
        static let backgroundTurqoise = UIColor(light: Asset.Colors.turquoise100Light, dark: Asset.Colors.turquoise900Dark)
    }

    public enum TabBar {
        static let backgroundSeperatorSelected = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
    }

    public enum Button {
        static let backgroundBarItem = UIColor(light: Asset.Colors.white, dark: Asset.Colors.gray90)
        static let backgroundSecondaryEnabled = UIColor(light: Asset.Colors.white, dark: Asset.Colors.gray95)
        static let backgroundSecondaryInConversationViewEnabled = UIColor(light: Asset.Colors.white, dark: Asset.Colors.gray100)
        static let backgroundSecondaryHighlighted = UIColor(light: Asset.Colors.white, dark: Asset.Colors.gray80)
        static let textSecondaryEnabled = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
        static let borderSecondaryEnabled = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray80)
        static let borderSecondaryHighlighted = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray60)
        static let backgroundPrimaryEnabled = UIColor(light: Asset.Colors.blue500Light, dark: Asset.Colors.blue500Dark)
        static let backgroundPrimaryHighlighted = UIColor(light: Asset.Colors.blue500Light, dark: Asset.Colors.blue400Light)
        static let backgroundPrimaryDisabled = UIColor(light: Asset.Colors.gray50, dark: Asset.Colors.gray70)
        static let textPrimaryEnabled = UIColor(light: Asset.Colors.white, dark: Asset.Colors.black)
        static let textPrimaryDisabled = UIColor(light: Asset.Colors.gray80, dark: Asset.Colors.black)
        static let textEmptyEnabled = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
        static let textBottomBarNormal = UIColor(light: Asset.Colors.gray90, dark: Asset.Colors.gray50)
        static let textBottomBarSelected = UIColor(light: Asset.Colors.white, dark: Asset.Colors.black)
        static let textUnderlineEnabled = UIColor(light: Asset.Colors.blue500Light, dark: Asset.Colors.blue500Dark)
        static let borderBarItem = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray100)
        static let backgroundLikeEnabled = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray60)
        static let backgroundLikeHighlighted = UIColor(light: Asset.Colors.red500Light, dark: Asset.Colors.red500Dark)
        static let backgroundSendDisabled = UIColor(light: Asset.Colors.gray70, dark: Asset.Colors.gray70)
        static let backgroundInputBarItemEnabled = UIColor(light: Asset.Colors.white, dark: Asset.Colors.gray90)
        static let backgroundInputBarItemHighlighted = UIColor(light: Asset.Colors.blue50Light, dark: Asset.Colors.blue800Dark)
        static let borderInputBarItemEnabled = UIColor(light: Asset.Colors.gray40, dark: Asset.Colors.gray100)
        static let borderInputBarItemHighlighted = UIColor(light: Asset.Colors.blue300Light, dark: Asset.Colors.blue700Dark)
        static let textInputBarItemEnabled = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
        static let textInputBarItemHighlighted = UIColor(light: Asset.Colors.blue500Light, dark: Asset.Colors.white)
        static let textUnderlineEnabledDefault = UIColor(light: Asset.Colors.black, dark: Asset.Colors.white)
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
            self.init(light: Asset.Colors.blue500Light, dark: Asset.Colors.blue500Dark)
        case .green:
            self.init(light: Asset.Colors.green500Light, dark: Asset.Colors.green500Dark)
        case .yellow: // Deprecated
            self.init(red: 0.996, green: 0.749, blue: 0.007, alpha: 1)
        case .red:
            self.init(light: Asset.Colors.red500Light, dark: Asset.Colors.red500Dark)
        case .amber:
            self.init(light: Asset.Colors.amber500Light, dark: Asset.Colors.amber500Dark)
        case .turquoise:
            self.init(light: Asset.Colors.turquoise500Light, dark: Asset.Colors.turquoise500Dark)
        case .purple:
            self.init(light: Asset.Colors.purple500Light, dark: Asset.Colors.purple500Dark)
        }
    }
    convenience init(fromZMAccentColor accentColor: ZMAccentColor) {
        let safeAccentColor = AccentColor(ZMAccentColor: accentColor) ?? .blue
        self.init(for: safeAccentColor)
    }
}
