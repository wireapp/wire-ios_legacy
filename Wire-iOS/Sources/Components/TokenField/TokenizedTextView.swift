// 
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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


@objc
protocol TokenizedTextViewDelegate: NSObjectProtocol {
    func tokenizedTextView(_ textView: TokenizedTextView, didTapTextRange range: NSRange, fraction: Float)
    func tokenizedTextView(_ textView: TokenizedTextView, textContainerInsetChanged textContainerInset: UIEdgeInsets)
}


//! Custom UITextView subclass to be used in TokenField.
//! Shouldn't be used anywhere else.
// TODO: as a inner class of TokenField

@objc
final class TokenizedTextView: TextView {
    @objc
    public weak var tokenizedTextViewDelegate: TokenizedTextViewDelegate?
    private var tapSelectionGestureRecognizer: UITapGestureRecognizer?
    
    // MARK: - Init
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupGestureRecognizer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGestureRecognizer()
    }
    
    private func setupGestureRecognizer() {
        if tapSelectionGestureRecognizer == nil {
            tapSelectionGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapText(_:)))
            tapSelectionGestureRecognizer?.delegate = self
            addGestureRecognizer(tapSelectionGestureRecognizer!)
        }
    }
    
    // MARK: - Actions
    override var contentOffset: CGPoint {
        get {
            return super.contentOffset
        }
        set(contentOffset) {
            // Text view require no scrolling in case the content size is not overflowing the bounds
            if contentSize.height > bounds.size.height {
                super.contentOffset = contentOffset
            } else {
                super.contentOffset = .zero
            }
            
        }
    }
    
    override var textContainerInset: UIEdgeInsets {
        get {
            return super.textContainerInset
        }
        set(textContainerInset) {///TODO: didSet
            super.textContainerInset = textContainerInset
            tokenizedTextViewDelegate?.tokenizedTextView(self, textContainerInsetChanged: textContainerInset)
        }
    }
    
    @objc
    private func didTapText(_ recognizer: UITapGestureRecognizer) {
        var location = recognizer.location(in: self)
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top
        
        // Find the character that's been tapped on
        var characterIndex: Int
        var fraction: CGFloat = 0
        characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: UnsafeMutablePointer<CGFloat>(mutating: &fraction))
        
        tokenizedTextViewDelegate?.tokenizedTextView(self, didTapTextRange: NSRange(location: characterIndex, length: 1), fraction: Float(fraction))
    }
    
    override func copy(_ sender: Any?) {
        let stringToCopy = pasteboardString(from: selectedRange)
        super.copy(sender)
        UIPasteboard.general.string = stringToCopy
    }
    
    override func cut(_ sender: Any?) {
        let stringToCopy = pasteboardString(from: selectedRange)
        super.cut(sender)
        UIPasteboard.general.string = stringToCopy
        
        // To fix the iOS bug
        delegate?.textViewDidChange?(self)
    }
    
    override func paste(_ sender: Any?) {
        super.paste(sender)
        
        // To fix the iOS bug
        delegate?.textViewDidChange?(self)
    }
    
    // MARK: - Utils
    
    private func pasteboardString(from range: NSRange) -> String? {
        // enumerate range of current text, resolving person attachents with user name.
        var string = ""
        for i in range.location..<NSMaxRange(range) {
            if (attributedText?.string as! NSString).character(at: i) == NSTextAttachment.character {
                
                if let tokenAttachemnt = attributedText?.attribute(.attachment, at: i, effectiveRange: nil) as? TokenTextAttachment {
                    string += tokenAttachemnt.token.title
                    if i < NSMaxRange(range) - 1 {
                        string += ", "
                    }
                }
            } else {
                string += (attributedText?.string as NSString?)?.substring(with: NSRange(location: i, length: 1)) ?? ""
            }
        }
        return string
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TokenizedTextView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
