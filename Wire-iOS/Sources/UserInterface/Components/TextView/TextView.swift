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

@objc protocol TextViewProtocol: NSObjectProtocol {
    func textView(_ textView: UITextView, hasImageToPaste image: MediaAsset)
    
    @objc optional func textView(_ textView: UITextView, firstResponderChanged resigned: NSNumber)
}

extension TextView {
    
    var placeholder: String?
    var attributedPlaceholder: NSAttributedString?
    var placeholderTextColor: UIColor?
    var placeholderFont: UIFont?
    var placeholderTextTransform: TextTransform?
    var lineFragmentPadding: CGFloat = 0.0
    var placeholderTextAlignment: NSTextAlignment!
    var language: String?
    
    private var placeholderLabel: TransformLabel!
    private var placeholderLabelLeftConstraint: NSLayoutConstraint?
    private var placeholderLabelRightConstraint: NSLayoutConstraint?
    private var _placeholderTextContainerInset: UIEdgeInsets!
    
    func showOrHidePlaceholder() {
    }

    override open var text: String! {
        didSet {
            showOrHidePlaceholder()
        }
    }
    
    override open var attributedText: NSAttributedString! {
        didSet {
            showOrHidePlaceholder()
        }
    }

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
