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

public struct SearchBarStyle {

    typealias SearchBarColors = SemanticColors.SearchBar

    var borderColorSelected: UIColor {
        return .accent()
    }
    var borderColorNotSelected: UIColor
    var textColor: UIColor
    var backgroundColor: UIColor

    var cornerRadius: CGFloat = 12
    var borderWidth: CGFloat = 1

    static let `default` = SearchBarStyle(borderColorNotSelected: SearchBarColors.borderInputView,
                                          textColor: SearchBarColors.textInputView,
                                          backgroundColor: SearchBarColors.backgroundInputView)

}

extension UITextView: Stylable {

    public func applyStyle(_ style: SearchBarStyle) {

        textColor = style.textColor
        backgroundColor = style.backgroundColor

        layer.borderWidth = style.borderWidth
        layer.cornerRadius = style.cornerRadius
        layer.borderColor = style.borderColorNotSelected.cgColor

    }

}
