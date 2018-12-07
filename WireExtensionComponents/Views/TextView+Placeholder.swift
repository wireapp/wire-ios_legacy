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

    @objc
    var placeholderTextContainerInset: UIEdgeInsets {
        set {
            _placeholderTextContainerInset = newValue
//            let linePadding = textContainer.lineFragmentPadding

//            let linePadding = textContainer.lineFragmentPadding

            placeholderLabelLeftAnchor?.constant = newValue.left// + linePadding
            placeholderLabelRightAnchor?.constant = newValue.right// - linePadding
//            placeholderLabelTopAnchor?.constant = newValue.top
//            placeholderLabelBottomAnchor?.constant = newValue.bottom
        }

        get {
            return _placeholderTextContainerInset
        }
    }


    @objc func createPlaceholderLabel() {
        let linePadding = textContainer.lineFragmentPadding
        placeholderLabel = UILabel()
        addSubview(placeholderLabel)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        placeholderLabelLeftAnchor = placeholderLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: placeholderTextContainerInset.left + linePadding)
//        placeholderLabelTopAnchor = placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: placeholderTextContainerInset.top)
        placeholderLabelRightAnchor = placeholderLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: placeholderTextContainerInset.right - linePadding)
//        placeholderLabelBottomAnchor = placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: placeholderTextContainerInset.bottom)

        NSLayoutConstraint.activate([
            placeholderLabelLeftAnchor!,
            placeholderLabelRightAnchor!,
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
//            placeholderLabelTopAnchor!,
//            placeholderLabelBottomAnchor!
            ])

        placeholderLabel.font = placeholderFont
        placeholderLabel.textColor = placeholderTextColor
        placeholderLabel.textTransform = placeholderTextTransform
        placeholderLabel.textAlignment = placeholderTextAlignment
        placeholderLabel.isAccessibilityElement = false
    }
}
