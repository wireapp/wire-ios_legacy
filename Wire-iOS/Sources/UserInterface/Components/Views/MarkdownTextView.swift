////
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
import Down

extension Notification.Name {
    static let MarkdownTextViewDidChangeSelection = Notification.Name("MarkdownTextViewDidChangeSelection")
    static let MarkdownTextViewDidChangeActiveMarkdown = Notification.Name("MarkdownTextViewDidChangeActiveMarkdown")
}

class MarkdownTextView: NextResponderTextView {
    
    // MARK: - Properties
    
    /// The style used to apply attributes.
    var style = DownStyle()
    
    /// The string containing markdown syntax for the corresponding
    /// attributed text.
    var preparedText: String {
        return self.parser.parse(attributedString: self.attributedText)
    }
    
    /// The parser used to convert attributed text into markdown syntax.
    private let parser = AttributedStringParser()

    /// The currently active markdown. This determines which attribtues
    /// are applied when typing.
    fileprivate(set) var activeMarkdown = Markdown.none {
        didSet {
            if oldValue != activeMarkdown {
                updateTypingAttributes()
                NotificationCenter.default.post(name: .MarkdownTextViewDidChangeActiveMarkdown, object: self)
            }
        }
    }
    
    public override var selectedTextRange: UITextRange? {
        didSet {
            activeMarkdown = self.markdownAtCaret()
        }
    }
    
    /// The current attributes to be applied when typing.
    fileprivate var currentAttributes: [String : Any] = [
        NSFontAttributeName: FontSpec(.normal, .regular).font!,
        NSForegroundColorAttributeName: UIColor.black
    ]

    private var wholeRange: NSRange {
        return NSMakeRange(0, attributedText.length)
    }
    
    // MARK: - Public Interface
    
    /// Resets the active markdown to none and the current attributes.
    func resetMarkdown() {
        currentAttributes = [
            NSFontAttributeName: FontSpec(.normal, .regular).font!,
            NSForegroundColorAttributeName: UIColor.black
        ]
        activeMarkdown = .none
    }
    
    /// Calling this method ensures that the current attributes are applied
    /// to newly typed text.
    func updateTypingAttributes() {
        // typing attributes are automatically cleared after each change,
        // so we have to keep setting it to provide continuity.
        typingAttributes = currentAttributes
    }
    
    /// Responding to newlines involves helpful behaviour such as exiting
    /// header mode or inserting new list items.
    func handleNewLine() {
        if let header = activeMarkdown.headerValue {
            updateTypingAttributesSubtracting(header)
        }
        // TODO: automatic list item generation
    }
    
    // MARK: Query Methods
    
    /// Returns the markdown bitmask at the current caret position.
    ///
    func markdownAtCaret() -> Markdown {
        return markdown(at: selectedRange.location)
    }
    
    /// Returns the markdown bitmask at the given location if it exists, else
    /// returns the `none` bitmask.
    ///
    func markdown(at location: Int) -> Markdown {
        guard location >= 0 && attributedText.length > location else { return .none }
        let type = attributedText.attribute(MarkdownIDAttributeName, at: location, effectiveRange: nil) as? Markdown
        return type ?? .none
    }

    // MARK: - Private Interface
    
    /// Updates the current attributes incrementally by inserting the given
    /// markdown.
    fileprivate func updateTypingAttribtuesAdding(_ markdown: Markdown) {
        
        // don't forget to subtract old header first
        if markdown.isHeader {
            activeMarkdown.subtract([.h1, .h2, .h3])
        }
        
        switch markdown {
        // TODO: handle different header sizes
        case .h1, .h2, .h3, .bold:
            // TODO: refactor this
            if let currentFont = currentAttributes[NSFontAttributeName] as? UIFont {
                currentAttributes[NSFontAttributeName] = currentFont.bold
            }
        case .italic:
            if let currentFont = currentAttributes[NSFontAttributeName] as? UIFont {
                currentAttributes[NSFontAttributeName] = currentFont.italic
            }
        default:
            break
        }
        
        // do this last to trigger adding typing attributes
        activeMarkdown.insert(markdown)
        currentAttributes[MarkdownIDAttributeName] = activeMarkdown
    }
    
    /// Updates the current attributes incrementally by subtracting the given
    /// markdown.
    fileprivate func updateTypingAttributesSubtracting(_ markdown: Markdown) {
        
        switch markdown {
        // TODO: handle different header sizes
        case .h1, .h2, .h3, .bold:
            // TODO: refactor this
            if let currentFont = currentAttributes[NSFontAttributeName] as? UIFont {
                currentAttributes[NSFontAttributeName] = currentFont.unBold
            }
        case .italic:
            if let currentFont = currentAttributes[NSFontAttributeName] as? UIFont {
                currentAttributes[NSFontAttributeName] = currentFont.unItalic
            }
        default:
            break
        }
        
        // do this last to trigger adding typing attributes
        activeMarkdown.remove(markdown)
        currentAttributes[MarkdownIDAttributeName] = activeMarkdown
    }
    
    /// Temporary helper
    fileprivate func printAttributes() {
        attributedText.enumerateAttribute(MarkdownIDAttributeName, in: wholeRange, options: []) { (val, range, _) in
            let markdown = val as? Markdown
            print("Markdown: \(markdown ?? .none)")
        }
    }
    
}


// MARK: - MarkdownBarViewDelegate

extension MarkdownTextView: MarkdownBarViewDelegate {
    
    func markdownBarView(_ view: MarkdownBarView, didSelectMarkdown markdown: Markdown, with sender: IconButton) {
        updateTypingAttribtuesAdding(markdown)
    }
    
    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton) {
        updateTypingAttributesSubtracting(markdown)
    }
}

// TODO: this is temporary, maybe refactor out to Down
private extension UIFont {
    
    // MARK: - Trait Querying
    
    var isBold: Bool {
        return contains(.traitBold)
    }
    
    var isItalic: Bool {
        return contains(.traitItalic)
    }
    
    var isMonospace: Bool {
        return contains(.traitMonoSpace)
    }
    
    private func contains(_ trait: UIFontDescriptorSymbolicTraits) -> Bool {
        return fontDescriptor.symbolicTraits.contains(trait)
    }
    
    // MARK: - Set Traits
    
    var bold: UIFont {
        return self.with(.traitBold)
    }
    
    var unBold: UIFont {
        return self.without(.traitBold)
    }
    
    var italic: UIFont {
        return self.with(.traitItalic)
    }
    
    var unItalic: UIFont {
        return self.without(.traitItalic)
    }
    
    var monospace: UIFont {
        return self.with(.traitMonoSpace)
    }
    
    /// Returns a copy of the font with the added symbolic trait.
    private func with(_ trait: UIFontDescriptorSymbolicTraits) -> UIFont {
        guard !contains(trait) else { return self }
        var traits = fontDescriptor.symbolicTraits
        traits.insert(trait)
        // FIXME: perhaps no good!
        guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        // size 0 means the size remains the same as before
        return UIFont(descriptor: newDescriptor, size: 0)
    }
    
    private func without(_ trait: UIFontDescriptorSymbolicTraits) -> UIFont {
        guard contains(trait) else { return self }
        var traits = fontDescriptor.symbolicTraits
        traits.subtract(trait)
        // FIXME: perhaps no good!
        guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        // size 0 means the size remains the same as before
        return UIFont(descriptor: newDescriptor, size: 0)
    }
}

