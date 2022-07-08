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

public struct TextViewStyle {
    var borderColor: UIColor
    var textColor: UIColor
    var cornerRadius: CGFloat = 12
    var backgroundColor: UIColor = .clear
    var borderWidth: CGFloat = 1

    static let `default`: Self = TextViewStyle(
        borderColor: SemanticColors.SearchBarColor.borderDefault,
        textColor: SemanticColors.SearchBarColor.textUserInput)
    static let active: Self = TextViewStyle(
        borderColor: UIColor.accent(),
        textColor: SemanticColors.SearchBarColor.textUserInput)
}

extension UITextView: Stylable {
    public func applyStyle(_ style: TextViewStyle) {
        textColor = style.textColor
        backgroundColor = style.backgroundColor
        layer.borderWidth = style.borderWidth
        layer.cornerRadius = style.cornerRadius
        layer.borderColor = style.borderColor.cgColor
    }
}
