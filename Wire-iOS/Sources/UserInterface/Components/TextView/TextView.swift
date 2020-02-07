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

// Inspired by https://github.com/samsoffes/sstoolkit/blob/master/SSToolkit/SSTextView.m
// and by http://derpturkey.com/placeholder-in-uitextview/

@objc class TextView {
    
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
    
    private var shouldDrawPlaceholder = false

    var lineFragmentPadding: CGFloat {
        didSet {
            textContainer.lineFragmentPadding = lineFragmentPadding
        }
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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    // MARK: Setup
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: UITextView.textDidChangeNotification, object: self)
        placeholderTextColor = UIColor.lightGray
        placeholderTextContainerInset = textContainerInset
        placeholderTextAlignment = NSTextAlignment.natural
        
        createPlaceholderLabel()
        
        if AutomationHelper.sharedHelper.disableAutocorrection() {
            autocorrectionType = .no
        }
    }
    
    func setPlaceholder(_ placeholder: String?) {
        self.placeholder = placeholder
        placeholderLabel.text = placeholder
        placeholderLabel.sizeToFit()
        showOrHidePlaceholder()
    }
    
    var attributedPlaceholder: NSAttributedString? {
        get {
            return super.attributedPlaceholder
        }
        set(attributedPlaceholder) {
            var mutableCopy = attributedPlaceholder as? NSMutableAttributedString
            mutableCopy?.addAttribute(.foregroundColor, value: placeholderTextColor, range: NSRange(location: 0, length: mutableCopy?.length ?? 0))
            self.attributedPlaceholder = mutableCopy
            placeholderLabel.attributedText = mutableCopy
            placeholderLabel.sizeToFit()
            showOrHidePlaceholder()
        }
    }
    
    func setPlaceholderTextAlignment(_ placeholderTextAlignment: NSTextAlignment) {
        self.placeholderTextAlignment = placeholderTextAlignment
        placeholderLabel.textAlignment = placeholderTextAlignment
    }
    
    func setPlaceholderTextColor(_ placeholderTextColor: UIColor?) {
        self.placeholderTextColor = placeholderTextColor
        if let placeholderTextColor = placeholderTextColor {
            placeholderLabel.textColor = placeholderTextColor
        }
    }
    
    func setPlaceholderFont(_ placeholderFont: UIFont?) {
        self.placeholderFont = placeholderFont
        placeholderLabel.font = self.placeholderFont
    }
    
    func setPlaceholderTextTransform(_ placeholderTextTransform: TextTransform) {
        self.placeholderTextTransform = placeholderTextTransform
        placeholderLabel.textTransform = self.placeholderTextTransform
    }
    
    func textChanged(_ note: Notification?) {
        showOrHidePlaceholder()
    }
    
    
    private func showOrHidePlaceholder() {
            placeholderLabel.alpha = text.isEmpty ? 1 : 0
    }
    
    // MARK: - Copy/Pasting
    @objc func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        ZMLogDebug("types available: %@", pasteboard.types)
        
        if (pasteboard.hasImages) && delegate.responds(to: #selector(textView(_:hasImageToPaste:))) {
            weak var image = UIPasteboard.general.mediaAsset()
            //#pragma clang diagnostic push
            //#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            delegate.perform(#selector(textView(_:hasImageToPaste:)), with: self, with: image)
            //#pragma clang diagnostic pop
        } else if pasteboard.hasStrings {
            super.paste(sender)
        } else if pasteboard.hasURLs {
            if (pasteboard.string?.count ?? 0) != 0 {
                super.paste(sender)
            } else if pasteboard.url != nil {
                super.paste(sender)
            }
        }
    }
    
    func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) {
            let pasteboard = UIPasteboard.general
            return pasteboard.hasImages || pasteboard.hasStrings
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if delegate.responds(to: #selector(textView(_:firstResponderChanged:))) {
            //#pragma clang diagnostic push
            //#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            delegate.perform(#selector(textView(_:firstResponderChanged:)), with: self, with: NSNumber(value: resigned))
            //#pragma clang diagnostic pop
        }
        return resigned
    }
    
    // MARK: Language
    var textInputMode: UITextInputMode? {
        return overriddenTextInputMode()
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
