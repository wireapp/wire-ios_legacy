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

import Foundation
import UIKit

public struct LabelStyle {
    var backgroundColor: UIColor
    var textColor: UIColor
    static let footerLabel: Self = LabelStyle(
        backgroundColor: .clear,
        textColor: SemanticColors.LabelsColor.textFooterLabelConversationDetails)
    static let headerLabel: Self = LabelStyle(
        backgroundColor: .clear,
        textColor: SemanticColors.LabelsColor.textHeaderLabelConversationDetails)
    static let primaryCellLabel: Self  = LabelStyle(
        backgroundColor: .clear,
        textColor: SemanticColors.LabelsColor.textLabelCellTitleActive)
    static let secondaryCellLabel: Self  = LabelStyle(
        backgroundColor: .clear,
        textColor: SemanticColors.LabelsColor.textLabelCellSubtitleActive)
    static let searchBarPlaceholder: Self  = LabelStyle(
        backgroundColor: .clear,
        textColor: SemanticColors.LabelsColor.textSearchBarPlaceholder)
}

extension UILabel: Stylable {

    public func applyStyle(_ style: LabelStyle) {
        backgroundColor = style.backgroundColor
        textColor = style.textColor
    }

}

public struct SearchBarStyle {
    var borderColor: UIColor
    var textColor: UIColor
    var backgroundColor: UIColor
    var activeBorderColor: UIColor = UIColor.accent()
    var cornerRadius: CGFloat = 12
    var borderWidth: CGFloat = 1

    static let textViewSearchBar: Self = SearchBarStyle(
        borderColor: SemanticColors.SearchBarColor.borderDefault,
        textColor: SemanticColors.SearchBarColor.textUserInput,
        backgroundColor: .clear)
    static let tokenFieldSearchBar: Self = SearchBarStyle(
        borderColor: SemanticColors.SearchBarColor.borderDefault,
        textColor: SemanticColors.SearchBarColor.textUserInput,
        backgroundColor: SemanticColors.SearchBarColor.backgroundSearchBar)
}

extension TokenField: Stylable {
    public func applyStyle(_ style: SearchBarStyle) {
        textColor = style.textColor
        backgroundColor = style.backgroundColor
        layer.borderWidth = style.borderWidth
        layer.cornerRadius = style.cornerRadius
        layer.borderColor = style.borderColor.cgColor
    }
}

extension UITextView: Stylable {
    public func applyStyle(_ style: SearchBarStyle) {
        textColor = style.textColor
        backgroundColor = style.backgroundColor
        layer.borderWidth = style.borderWidth
        layer.cornerRadius = style.cornerRadius
        layer.borderColor = style.borderColor.cgColor
    }
}
