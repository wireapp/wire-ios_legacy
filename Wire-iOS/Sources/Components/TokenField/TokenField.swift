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

private let zmLog = ZMSLog(tag: "TokenField")

extension TokenField {
    
    @objc
    func setupSubviews() {
        // this prevents accessoryButton to be visible sometimes on scrolling
        clipsToBounds = true
        
        let textView = TokenizedTextView()
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
        
        self.textView = textView

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
    
    // MARK: - Utility
    
    @objc
    func updateTokenAttachments() { ///TODO: test
        textView?.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.attributedText.length), options: [], using: { tokenAttachment, _, _ in
            (tokenAttachment as? TokenTextAttachment)?.refreshImage()
        })
    }
    
    
    @objc
    func string(forTokens tokens: [Token]) -> NSAttributedString {
        let string = NSMutableAttributedString()
        for token in tokens {
            let tokenAttachment = TokenTextAttachment(token: token, tokenField: self)
            let tokenString = NSAttributedString(attachment: tokenAttachment)
            
            string.append(tokenString)
            
            let separatorAttachment = TokenSeparatorAttachment(token: token, tokenField: self)
            let separatorString = NSAttributedString(attachment: separatorAttachment)
            
            string.append(separatorString)
        }
        
        return string && (textAttributes as? [NSAttributedString.Key : Any]) ?? [:]
    }
    
    func filterUnwantedAttachments() { ///TODO: test
        var updatedCurrentTokens: Set<Token> = []
        
        textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.text.count), options: [], using: { textAttachment, range, stop in
            
            if let token = (textAttachment as? TokenContainer)?.token,
                !updatedCurrentTokens.contains(token) {
                updatedCurrentTokens.insert(token)
            }
        })
        
        ///TODO: Change currentTokens type to [Token]
        if let currentTokens = self.currentTokens as? [Token] {
            var deletedTokens = Set<Token>(currentTokens)
            deletedTokens.subtract(updatedCurrentTokens)
            
            if !deletedTokens.isEmpty {
                removeTokens(Array(deletedTokens))
            }
            
            self.currentTokens.removeObjects(in: Array(deletedTokens))
            delegate?.tokenField(self, changedTokensTo: currentTokens)
        }
    }
    
    // MARK: - remove token
    
    func removeAllTokens() {
        removeTokens(currentTokens as! [Token])
        textView.showOrHidePlaceholder()
    }

    func removeToken(_ token: Token) {
        removeTokens([token])
    }
    
    private func removeTokens(_ tokensToRemove: [Token]) {
        var rangesToRemove: [NSRange] = []
        
        textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.attributedText.length), options: [], using: { textAttachment, range, stop in
            if let token = (textAttachment as? TokenContainer)?.token,
                tokensToRemove.contains(token) {
                rangesToRemove.append(range)
            }
        })
        
        // Delete ranges from the end of string till the beginning: this keeps range locations valid.
        rangesToRemove.sort(by: { rangeValue1, rangeValue2 in
            rangeValue1.location > rangeValue2.location
        })
        
        textView.textStorage.beginEditing()
        for rangeValue in rangesToRemove {
            textView.textStorage.deleteCharacters(in: rangeValue)
        }
        textView.textStorage.endEditing()
        
        currentTokens?.removeObjects(in: tokensToRemove)
        
        invalidateIntrinsicContentSize()
        updateTextAttributes()
        
        textView.showOrHidePlaceholder()
    }
    
    private func rangeIncludesRange(_ range: NSRange, _ includedRange: NSRange) -> Bool {
        return NSEqualRanges(range, NSUnionRange(range, includedRange))
    }
    
    private func notifyIfFilterTextChanged() {
        var indexOfFilterText = 0
        textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.text.count), options: [], using: { tokenAttachment, range, stop in
            if tokenAttachment is TokenTextAttachment {
                indexOfFilterText = NSMaxRange(range)
            }
        })
        
        let oldFilterText = filterText
        self.filterText = ((textView.text as NSString).substring(from: indexOfFilterText)).replacingOccurrences(of: "\u{FFFC}", with: "")
        if oldFilterText != filterText {
            delegate?.tokenField(self, changedFilterTextTo: filterText)
        }
    }
    
    
}

// MARK: - TokenizedTextViewDelegate

extension TokenField: TokenizedTextViewDelegate {
    func tokenizedTextView(_ textView: TokenizedTextView, didTapTextRange range: NSRange, fraction: CGFloat) {
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
    
    func tokenizedTextView(_ textView: TokenizedTextView, textContainerInsetChanged textContainerInset: UIEdgeInsets) {
        invalidateIntrinsicContentSize()
        updateExcludePath()
        updateLayout()
    }
    
}

// MARK: - UITextViewDelegate

extension TokenField : UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return !(textAttachment is TokenSeparatorAttachment)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        userDidConfirmInput = false
        
        filterUnwantedAttachments()
        notifyIfFilterTextChanged()
        invalidateIntrinsicContentSize()
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        zmLog.debug("Selection changed: NSStringFromRange(textView.selectedRange)")
        
        var modifiedSelectionRange = NSRange(location: 0, length: 0)
        var hasModifiedSelection = false
        
        textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.attributedText.length), options: [], using: { tokenAttachment, range, stop in
            if let tokenAttachment = tokenAttachment as? TokenTextAttachment {
                tokenAttachment.isSelected = rangeIncludesRange(textView.selectedRange, range)
                textView.layoutManager.invalidateDisplay(forCharacterRange: range)
                
                if rangeIncludesRange(textView.selectedRange, range) {
                    modifiedSelectionRange = NSUnionRange(hasModifiedSelection ? modifiedSelectionRange : range, range)
                    hasModifiedSelection = true
                }
                zmLog.info("    person attachement: \(tokenAttachment.token.title) at range: \(range) selected: \(tokenAttachment.isSelected)")
            }
        })
        
        
        if hasModifiedSelection && !NSEqualRanges(textView.selectedRange, modifiedSelectionRange) {
            textView.selectedRange = modifiedSelectionRange
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            userDidConfirmInput = true
            delegate?.tokenFieldDidConfirmSelection(self)
            
            return false
        }
        
        if range.length == 1 && text.isEmpty {
            // backspace
            var cancelBackspace = false
            textView.attributedText.enumerateAttribute(.attachment, in: range, options: [], using: { tokenAttachment, range, stop in
                if let tokenAttachment = tokenAttachment as? TokenTextAttachment {
                    if !tokenAttachment.isSelected {
                        textView.selectedRange = range
                        cancelBackspace = true
                    }
                    stop.pointee = true
                }
            }
            )
            if cancelBackspace {
                return false
            }
        }
        
        
        // Inserting text between tokens does not make sense for this control.
        // If there are any tokens after the insertion point, move the cursor to the end instead, but only for insertions
        // If the range length is >0, we are trying to replace something instead, and that’s a bit more complex,
        // so don’t do any magic in that case
        if !text.isEmpty {
            (textView.text as NSString).enumerateSubstrings(in: NSRange(location: range.location, length: textView.text.count - range.location), options: .byComposedCharacterSequences, using: { substring, substringRange, enclosingRange, stop in
                
                if substring?.isEmpty == false,
                    let nsString: NSString = substring as NSString?,
                    nsString.character(at: 0) == NSTextAttachment.character {
                    textView.selectedRange = NSRange(location: textView.text.count, length: 0)
                    stop.pointee = true
                }
            })
        }
        
        updateTextAttributes()
        
        return true
        
    }
    
}
