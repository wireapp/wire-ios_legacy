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
}

extension UILabel: Stylable {

    public func applyStyle(_ style: LabelStyle) {
        backgroundColor = style.backgroundColor
        textColor = style.textColor
    }

}
