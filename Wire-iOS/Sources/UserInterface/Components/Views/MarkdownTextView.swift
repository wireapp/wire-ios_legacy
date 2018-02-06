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
    var style: DownStyle
    
    /// The parser used to convert attributed text into markdown syntax.
    private let parser = AttributedStringParser()

    /// The string containing markdown syntax for the corresponding
    /// attributed text.
    var preparedText: String {
        return self.parser.parse(attributedString: self.attributedText)
    }
    
    /// The current attributes to be applied when typing.
    fileprivate var currentAttributes: [String : Any] = [:]

    /// The currently active markdown. This determines which attribtues
    /// are applied when typing.
    fileprivate(set) var activeMarkdown = Markdown.none {
        didSet {
            if oldValue != activeMarkdown {
                currentAttributes = attributes(for: activeMarkdown)
                markdownTextStorage.currentMarkdown = activeMarkdown
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
    
    private var wholeRange: NSRange {
        return NSMakeRange(0, attributedText.length)
    }
    
    let markdownTextStorage: MarkdownTextStorage
    
    // MARK: - Init
    
    convenience init() {
        self.init(with: DownStyle.normal)
    }
    
    init(with style: DownStyle) {
        self.style = style

        self.markdownTextStorage = MarkdownTextStorage()
        let layoutManager = NSLayoutManager()
        self.markdownTextStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        super.init(frame: .zero, textContainer: textContainer)
        
        currentAttributes = attributes(for: activeMarkdown)
        markdownTextStorage.currentMarkdown = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Interface
    
    /// Resets the active markdown to none and the current attributes.
    func resetMarkdown() {
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
        if activeMarkdown.containsHeader {
            resetMarkdown()
        }
        // TODO: automatic list item generation
    }
    
    // MARK: Query Methods
    
    /// Returns the markdown at the current caret position.
    ///
    func markdownAtCaret() -> Markdown {
        let caret = selectedRange.location
        if caret == 0 { return markdown(at: caret) }
        // in order to allow continuity of typing, the markdown at the caret
        // should be the same as the previous position.
        return markdown(at: caret - 1)
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
    
    /// Returns the attributes for the given markdown.
    private func attributes(for markdown: Markdown) -> [String : Any] {
        
        // the idea is to query for specific markdown & adjust the attributes
        // incrementally
        
        var font = style.baseFont
        var color = style.baseFontColor
        let paragraphyStyle = style.baseParagraphStyle
        
        // add code attributes first, since it uses different font
        if markdown.contains(.code) {
            font = style.codeFont
            if let codeColor = style.codeColor {
                color = codeColor
            }
        }
        
        // if header
        if let header = markdown.headerValue {
            if let headerSize = style.headerSize(for: header) {
                font = font.withSize(headerSize).bold
            }
            if let headerColor = style.headerColor(for: header) {
                color = headerColor
            }
        }
        
        // TODO: Quote, List
        
        if markdown.contains(.bold) {
            font = font.bold
        }
        
        if markdown.contains(.italic) {
            font = font.italic
        }
        
        return [
            MarkdownIDAttributeName: markdown,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: color,
            NSParagraphStyleAttributeName: paragraphyStyle
        ]
    }
    
//    fileprivate func insertListItem() {
//
//        // maybe better way is to find the last newline from caret, or start of document
//        // if none
//
//        if let caret = selectedTextRange?.start {
//            let lineStart = tokenizer.position(from: caret, toBoundary: .paragraph, inDirection: UITextStorageDirection.backward.rawValue)
//            let lineEnd = tokenizer.position(from: caret, toBoundary: .paragraph, inDirection: UITextStorageDirection.forward.rawValue)
//
//            if let lineStart = lineStart, let lineEnd = lineEnd {
//                let lineRange = textRange(from: lineStart, to: lineEnd)!
//                let loc = offset(from: beginningOfDocument, to: lineRange.start)
//                let len = offset(from: lineRange.start, to: lineRange.end)
//                let nsRange = NSMakeRange(loc, len)
//
//                // need to insert list markdown id to all ranges within line range
//
//            }
//
//            if let lineStart = lineStart {
//                if let range = textRange(from: lineStart, to: lineStart) {
//                    replace(range, withText: "1.\t")
//                }
//            }
//            else if caret == beginningOfDocument || caret == endOfDocument {
//
//                if let range = textRange(from: caret, to: caret) {
//                    replace(range, withText: "1.\t")
//                }
//            }
//        }
//    }
    
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
//        if markdown == .list { insertListItem() }
        activeMarkdown.insert(markdown)
    }
    
    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton) {
        activeMarkdown.subtract(markdown)
    }
}

// MARK: - DownStyle Presets

extension DownStyle {
    /// The style used within the conversation message cells.
    static var normal: DownStyle = {
        let style = DownStyle()
        style.baseFont = FontSpec(.normal, .regular).font!
        style.baseFontColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        return style
    }()
    
    /// The style used within the input bar.
    static var compact: DownStyle = {
        let style = normal
        style.baseParagraphStyle = NSParagraphStyle.default
        
        // headers all same size
        style.h1Size = style.baseFont.pointSize
        style.h2Size = style.h1Size
        style.h3Size = style.h1Size
        return style
    }()
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
    
    private func contains(_ trait: UIFontDescriptorSymbolicTraits) -> Bool {
        return fontDescriptor.symbolicTraits.contains(trait)
    }
    
    // MARK: - Set Traits
    
    var bold: UIFont {
        return self.with(.traitBold)
    }
    
    var italic: UIFont {
        return self.with(.traitItalic)
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
}

