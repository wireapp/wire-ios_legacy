//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension TextView {


    /// custom inset for placeholder, only left and right inset value is applied (The placeholder is align center vertically)
    @objc
    var placeholderTextContainerInset: UIEdgeInsets {
        set {
            _placeholderTextContainerInset = newValue

            placeholderLabelLeftConstraint?.constant = newValue.left
            placeholderLabelRightConstraint?.constant = newValue.right
        }

        get {
            return _placeholderTextContainerInset
        }
    }


    @objc func createPlaceholderLabel() {
        let linePadding = textContainer.lineFragmentPadding
        placeholderLabel = TransformLabel()
        placeholderLabel.font = placeholderFont
        placeholderLabel.textColor = placeholderTextColor
        placeholderLabel.textTransform = placeholderTextTransform
        placeholderLabel.textAlignment = placeholderTextAlignment
        placeholderLabel.isAccessibilityElement = false

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(placeholderLabel)

        placeholderLabelLeftConstraint = placeholderLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: placeholderTextContainerInset.left + linePadding)
        placeholderLabelRightConstraint = placeholderLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: placeholderTextContainerInset.right - linePadding)

        NSLayoutConstraint.activate([
            placeholderLabelLeftConstraint!,
            placeholderLabelRightConstraint!,
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }
}
