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
    
    let markdownTextStorage: MarkdownTextStorage

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
        
        markdownTextStorage.currentMarkdown = .none
        currentAttributes = attributes(for: activeMarkdown)
        updateTypingAttributes()
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
        guard let range = selectedTextRange, range.isEmpty else { return .none }
        let caret = range.start
        let location = offset(from: beginningOfDocument, to: caret)
        // in order to allow continuity of typing, the markdown at the caret
        // should actually be markdown at the position behind the caret
        return markdown(at: max(0, location - 1))
    }
    
    /// Returns the markdown at the given location.
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
    
    /// Returns the range of the line enclosing the current selection if it
    /// exists, else nil.
    fileprivate func rangeOfCurrentLine() -> NSRange? {
        guard selectedRange.location != NSNotFound else { return nil }
        return (text as NSString).lineRange(for: selectedRange)
    }
    
    /// Adds the given markdown (and the associated attributes) to the given
    /// range.
    fileprivate func add(_ markdown: Markdown, to range: NSRange) {
        updateAttributes(in: range) { $0.union(markdown) }
    }
    
    /// Removes the given markdown (and the associated attributes) from the given
    /// range.
    fileprivate func remove(_ markdown: Markdown, to range: NSRange) {
        updateAttributes(in: range) { $0.subtracting(markdown) }
    }
    
    /// Updates all attributes in the given range by transforming markdown tags
    /// using the given transformation function, then refetching the attributes
    /// for the transformed values and setting the new attributes.
    private func updateAttributes(in range: NSRange, using markdownTransform: (Markdown) -> Markdown) {
        var exisitngMarkdownRanges = [(Markdown, NSRange)]()
        markdownTextStorage.enumerateAttribute(MarkdownIDAttributeName, in: range, options: []) { md, mdRange, _ in
            if let md = md as? Markdown { exisitngMarkdownRanges.append((md, mdRange)) }
        }
        
        for (md, mdRange) in exisitngMarkdownRanges {
            // updated attributes depends on how md is transformed
            let updatedAttributes = attributes(for: markdownTransform(md))
            markdownTextStorage.setAttributes(updatedAttributes, range: mdRange)
        }
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
        // selecting header will apply header to the whole line
        if markdown.isHeader, let range = rangeOfCurrentLine() {
            add(markdown, to: range)
        }
        
        activeMarkdown.insert(markdown)
    }
    
    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton) {
        // deselecting header will remove header from the whole line
        if markdown.isHeader, let range = rangeOfCurrentLine() {
            remove(markdown, to: range)
        }
        
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
