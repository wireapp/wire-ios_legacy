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

    override open var textContainerInset: UIEdgeInsets {
        didSet {
            let linePadding = textContainer.lineFragmentPadding

            placeholderLabelLeftAnchor?.constant = textContainerInset.left + linePadding
        }
    }

    @objc func createPlaceholderLabel() {
        let linePadding = textContainer.lineFragmentPadding
        placeholderLabel = UILabel()
        addSubview(placeholderLabel)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        placeholderLabelLeftAnchor = placeholderLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: placeholderTextContainerInset.left + linePadding)

        NSLayoutConstraint.activate([
            placeholderLabelLeftAnchor!,
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])

        placeholderLabel.font = placeholderFont
        placeholderLabel.textColor = placeholderTextColor
        placeholderLabel.textTransform = placeholderTextTransform
        placeholderLabel.textAlignment = placeholderTextAlignment
        placeholderLabel.isAccessibilityElement = false
    }
}
