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

import UIKit

protocol TokenizedTextViewDelegate: class {
    func tokenizedTextView(_ textView: TokenizedTextView, didTapTextRange range: NSRange, fraction: CGFloat)
    func tokenizedTextView(_ textView: TokenizedTextView, textContainerInsetChanged textContainerInset: UIEdgeInsets)
}

// ! Custom UITextView subclass to be used in TokenField.
// ! Shouldn't be used anywhere else.
// TODO: as a inner class of TokenField

final class TokenizedTextView: TextView {

    weak var tokenizedTextViewDelegate: TokenizedTextViewDelegate?

    private lazy var tapSelectionGestureRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(didTapText(_:)))
    }()

    convenience init() {
        self.init(frame: .zero)
        setupGestureRecognizer()
    }

    private func setupGestureRecognizer() {
        tapSelectionGestureRecognizer.delegate = self
        addGestureRecognizer(tapSelectionGestureRecognizer)
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
        didSet {
            tokenizedTextViewDelegate?.tokenizedTextView(self, textContainerInsetChanged: textContainerInset)
        }
    }

    @objc
    private func didTapText(_ recognizer: UITapGestureRecognizer) {
        var location = recognizer.location(in: self)
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top

        // Find the character that's been tapped on
        var characterIndex: Int = 0
        var fraction: CGFloat = 0

        withUnsafePointer(to: &fraction) {
            characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: UnsafeMutablePointer<CGFloat>(mutating: $0))
        }

        tokenizedTextViewDelegate?.tokenizedTextView(self, didTapTextRange: NSRange(location: characterIndex, length: 1), fraction: fraction)
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
            guard let nsstring = attributedText?.string as NSString? else {
                continue
            }

            if nsstring.character(at: i) == NSTextAttachment.character {

                if let tokenAttachemnt = attributedText?.attribute(.attachment, at: i, effectiveRange: nil) as? TokenTextAttachment {
                    string += tokenAttachemnt.token.title
                    if i < NSMaxRange(range) - 1 {
                        string += ", "
                    }
                }
            } else {
                string += nsstring.substring(with: NSRange(location: i, length: 1))
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
