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

public struct ButtonStyle {

    typealias ButtonColors = SemanticColors.Button

    private(set) var normalStateColors: (background: UIColor, title: UIColor, border: UIColor?)
    private(set) var highlightedStateColors: (background: UIColor, title: UIColor, border: UIColor?)
    private(set) var selectedStateColors: (background: UIColor, title: UIColor, border: UIColor)?

    static let secondaryTextButtonStyle = ButtonStyle(normalStateColors: (
                                                        background: ButtonColors.backgroundSecondaryEnabled,
                                                        title: ButtonColors.textSecondaryEnabled,
                                                        border: ButtonColors.borderSecondaryEnabled),
                                                      highlightedStateColors: (
                                                        background: ButtonColors.backgroundSecondaryHighlighted,
                                                        title: ButtonColors.textSecondaryEnabled,
                                                        border: ButtonColors.borderSecondaryHighlighted))

    static let secondaryTextButtonStyleInConversationView = ButtonStyle(normalStateColors: (
                                                        background: ButtonColors.backgroundSecondaryInConversationViewEnabled,
                                                        title: ButtonColors.textSecondaryEnabled,
                                                        border: ButtonColors.borderSecondaryEnabled),
                                                      highlightedStateColors: (
                                                        background: ButtonColors.backgroundSecondaryHighlighted,
                                                        title: ButtonColors.textSecondaryEnabled,
                                                        border: ButtonColors.borderSecondaryHighlighted))

    static let accentColorTextButtonStyle = ButtonStyle(normalStateColors: (
                                                         background: UIColor.accent(),
                                                         title: ButtonColors.textPrimaryEnabled,
                                                         border: nil),
                                                        highlightedStateColors: (
                                                         background: UIColor.accentDarken,
                                                         title: ButtonColors.textPrimaryEnabled,
                                                         border: nil))

    static let addParticipantsButtonStyle = ButtonStyle(normalStateColors: (
                                                         background: UIColor.accent(),
                                                         title: SemanticColors.Label.textDefaultWhite,
                                                         border: nil),
                                                        highlightedStateColors: (
                                                         background: UIColor.accentDarken,
                                                         title: SemanticColors.Label.textDefaultWhite,
                                                         border: nil))

    static let addParticipantsDisabledButtonStyle = ButtonStyle(normalStateColors: (
                                                         background: SemanticColors.Button.backgroundPrimaryDisabled,
                                                         title: SemanticColors.Button.textPrimaryDisabled,
                                                         border: nil),
                                                        highlightedStateColors: (
                                                         background: SemanticColors.Button.backgroundPrimaryDisabled,
                                                         title: SemanticColors.Button.textPrimaryDisabled,
                                                         border: nil))

    static let primaryTextButtonStyle = ButtonStyle(normalStateColors: (
                                                         background: ButtonColors.backgroundPrimaryEnabled,
                                                         title: ButtonColors.textPrimaryEnabled,
                                                         border: nil),
                                                        highlightedStateColors: (
                                                         background: ButtonColors.backgroundPrimaryHighlighted,
                                                         title: ButtonColors.textPrimaryEnabled,
                                                         border: nil))

    static let emptyTextButtonStyle = ButtonStyle(normalStateColors: (
                                                         background: .clear,
                                                         title: ButtonColors.textEmptyEnabled,
                                                         border: nil),
                                                        highlightedStateColors: (
                                                         background: .clear,
                                                         title: ButtonColors.textEmptyEnabled,
                                                         border: nil))

    static let iconButtonStyle = ButtonStyle(normalStateColors: (
                                                         background: ButtonColors.backgroundInputBarItemEnabled,
                                                         title: ButtonColors.textInputBarItemEnabled,
                                                         border: ButtonColors.borderInputBarItemEnabled),
                                                        highlightedStateColors: (
                                                         background: ButtonColors.backgroundInputBarItemHighlighted,
                                                         title: ButtonColors.textInputBarItemHighlighted,
                                                         border: ButtonColors.borderInputBarItemHighlighted),
                                                       selectedStateColors: (
                                                         background: ButtonColors.backgroundInputBarItemHighlighted,
                                                         title: ButtonColors.textInputBarItemHighlighted,
                                                         border: ButtonColors.borderInputBarItemHighlighted))
}
