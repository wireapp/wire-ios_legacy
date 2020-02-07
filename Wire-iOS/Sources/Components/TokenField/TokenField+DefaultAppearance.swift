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

import UIKit

extension TokenField {
    
    @objc
    func setupSubviews() {
        // this prevents accessoryButton to be visible sometimes on scrolling
        clipsToBounds = true
        
        textView = TokenizedTextView()
        textView.tokenizedTextViewDelegate = self
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = UIColor.clear
        if #available(iOS 11, *) {
            textView.textDragInteraction?.isEnabled = false
        }
        addSubview(textView)
        
        toLabel = UILabel()
        toLabel.translatesAutoresizingMaskIntoConstraints = false
        toLabel.font = font
        toLabel.text = toLabelText
        toLabel.backgroundColor = UIColor.clear
        textView.addSubview(toLabel)
        
        // Accessory button could be a subview of textView,
        // but there are bugs with setting constraints from subview to UITextView trailing.
        // So we add button as subview of self, and update its position on scrolling.
        accessoryButton = IconButton()
        accessoryButton.translatesAutoresizingMaskIntoConstraints = false
        accessoryButton.isHidden = !hasAccessoryButton
        addSubview(accessoryButton)
    }
    
    @objc func setupStyle() {
        tokenOffset = 4
        
        textView.tintColor = .accent()
        textView.autocorrectionType = .no
        textView.returnKeyType = .go
        textView.placeholderFont = .smallRegularFont
        textView.placeholderTextContainerInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        textView.placeholderTextTransform = .upper
        textView.lineFragmentPadding = 0
    }
    
    @objc func setupFonts() {
        // Dynamic Type is disabled for now until the separator dots
        // vertical alignment has been fixed for larger fonts.
        let schema = FontScheme(contentSizeCategory: .medium)
        font = schema.font(for: .init(.normal, .regular))
        tokenTitleFont = schema.font(for: .init(.small, .regular))
    }
}

// MARK: - TokenizedTextViewDelegate

extension TokenField: TokenizedTextViewDelegate {
    func tokenizedTextView(_ textView: TokenizedTextView?, didTapTextRange range: NSRange, fraction: CGFloat) {
        if isCollapsed {
            setCollapsed(false, animated: true)
            return
        }
        
        
        if fraction >= 1 && range.location == self.textView.textStorage.length - 1 {
            return
        }
        
        if range.location < self.textView.textStorage.length {
            self.textView.attributedText.enumerateAttribute(.attachment, in: range, options: [], using: { tokenAttachemnt, range, stop in
                if (tokenAttachemnt is TokenTextAttachment) {
                    self.textView.selectedRange = range
                }
            })
        }
    }
    
    func tokenizedTextView(_ textView: TokenizedTextView?, textContainerInsetChanged textContainerInset: UIEdgeInsets) {
        invalidateIntrinsicContentSize()
        updateExcludePath()
        updateLayout()
    }
    
}
