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

    private(set) var normalStateColors: (background: UIColor, title: UIColor, border: UIColor)
    private(set) var highlightedStateColors: (background: UIColor, title: UIColor, border: UIColor)

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
                                                         border: .clear),
                                                        highlightedStateColors: (
                                                         background: UIColor.accentDarken,
                                                         title: ButtonColors.textPrimaryEnabled,
                                                         border: .clear))

    static let primaryTextButtonStyle = ButtonStyle(normalStateColors: (
                                                         background: ButtonColors.backgroundPrimaryEnabled,
                                                         title: ButtonColors.textPrimaryEnabled,
                                                         border: .clear),
                                                        highlightedStateColors: (
                                                         background: ButtonColors.backgroundPrimaryHighlighted,
                                                         title: ButtonColors.textPrimaryEnabled,
                                                         border: .clear))

    static let emptyTextButtonStyle = ButtonStyle(normalStateColors: (
                                                         background: .clear,
                                                         title: ButtonColors.textEmptyEnabled,
                                                         border: .clear),
                                                        highlightedStateColors: (
                                                         background: .clear,
                                                         title: ButtonColors.textEmptyEnabled,
                                                         border: .clear))

}
