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
    static let MarkdownTextViewDidChangeActiveMarkdown = Notification.Name("MarkdownTextViewDidChangeActiveMarkdown")
}

class MarkdownTextView: NextResponderTextView {
    
    enum KeyEvent { case none, newline, backspace }
    
    enum ListType {
        case number, bullet
        var prefix: String { return self == .number ? "1. " : "- " }
    }
    
    // MARK: - Properties
    
    /// The style used to apply attributes.
    var style: DownStyle
    
    /// The parser used to convert attributed text into markdown syntax.
    private let parser = AttributedStringParser()
    
    /// The main backing store
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
        didSet { activeMarkdown = self.markdownAtSelection() }
    }
    
    /// Describes the last key event entered by the user.
    private var lastKeyEvent = KeyEvent.none
    
    // MARK: - Range Helpers
    
    private var wholeRange: NSRange {
        return NSMakeRange(0, markdownTextStorage.length)
    }
    
    fileprivate var currentLineRange: NSRange? {
        guard selectedRange.location != NSNotFound else { return nil }
        return (text as NSString).lineRange(for: selectedRange)
    }
    
    private var currentLineTextRange: UITextRange? {
        return currentLineRange?.textRange(in: self)
    }
    
    private var previousLineRange: NSRange? {
        guard let range = currentLineRange, range.location > 0 else { return nil }
        return (text as NSString).lineRange(for: NSMakeRange(range.location - 1, 0))
    }
    
    private var previousLineTextRange: UITextRange? {
        return previousLineRange?.textRange(in: self)
    }
    
    // MARK: - Init
    
    convenience init() {
        self.init(with: DownStyle.normal)
    }
    
    init(with style: DownStyle) {
        self.style = style
        // create the storage stack
        self.markdownTextStorage = MarkdownTextStorage()
        let layoutManager = NSLayoutManager()
        self.markdownTextStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        super.init(frame: .zero, textContainer: textContainer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: .UITextViewTextDidChange, object: nil)
        
        markdownTextStorage.currentMarkdown = .none
        currentAttributes = attributes(for: activeMarkdown)
        updateTypingAttributes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Interface
    
    /// Resets the active markdown to none and the sets the default
    /// typing attributes.
    func resetMarkdown() {
        activeMarkdown = .none
    }
    
    /// Call this method before the text view changes to give it a chance
    /// to perform any work.
    func respondToChange(_ text: String, inRange range: NSRange) {
        if text == "\n" || text == "\r" {
            lastKeyEvent = .newline
            handleNewLine()
        }
        else if text.isEmpty && range.length > 0 {
            lastKeyEvent = .backspace
            handleBackspace()
        }
        else {
            lastKeyEvent = .none
        }
        
        updateTypingAttributes()
    }
    
    // MARK: - Private Interface
    
    /// Calling this method ensures that the current attributes are applied
    /// to newly typed text.
    private func updateTypingAttributes() {
        // typing attributes are automatically cleared after each change,
        // so we have to keep setting it to provide continuity.
        typingAttributes = currentAttributes
    }
    
    @objc private func textViewDidChange() {
        // it's important to reset lastKeyEvent as soon as we use it
        // so that the event is only processed once
        switch lastKeyEvent {
        case .newline:
            lastKeyEvent = .none
            
            guard
                let prevlineRange = previousLineRange,
                let prevLineTextRange = previousLineTextRange,
                let selection = selectedTextRange
                else { return }
            
            if isEmptyListItem(at: prevlineRange) {
                // the delete last line
                restore(selection, afterReplacingRange: prevLineTextRange, withText: "")
            }
            else if isListItem(at: prevlineRange) {
                // insert list item at current line
                let type = isNumberItem(at: prevlineRange) ? ListType.number : .bullet
                insertListItem(type: type)
            }
        case .backspace:
            lastKeyEvent = .none
        // TODO: if the space after list prefix was deleted, remove the remaining prefix
        default:
            break
        }
    }
    
    /// Responding to newlines involves helpful behaviour such as exiting
    /// header mode or inserting new list items.
    private func handleNewLine() {
        if activeMarkdown.containsHeader {
            resetMarkdown()
        }
    }
    
    private func handleBackspace() {
        
    }
    
    // MARK: Markdown Querying
    
    /// Returns the markdown at the current selected range. If this is a position
    /// or the selected range contains only a single type of markdown, this
    /// markdown is returned. Otherwise none is returned.
    private func markdownAtSelection() -> Markdown {
        guard selectedRange.length > 0 else { return markdownAtCaret() }
        let markdownInSelection = markdown(in: selectedRange)
        if markdownInSelection.count == 1 {
            return markdownInSelection.first!
        }
        return .none
    }
    
    /// Returns the markdown at the current caret position.
    private func markdownAtCaret() -> Markdown {
        // in order to allow continuity of typing, the markdown at the caret
        // should actually be markdown at the position behind the caret
        return markdown(at: max(0, selectedRange.location - 1))
    }
    
    /// Returns the markdown at the given location.
    private func markdown(at location: Int) -> Markdown {
        guard location >= 0 && markdownTextStorage.length > location else { return .none }
        let markdown = markdownTextStorage.attribute(MarkdownIDAttributeName, at: location, effectiveRange: nil) as? Markdown
        return markdown ?? .none
    }
    
    /// Returns a set containing all markdown combinations present in the given
    /// range.
    fileprivate func markdown(in range: NSRange) -> Set<Markdown> {
        var result = Set<Markdown>()
        markdownTextStorage.enumerateAttribute(MarkdownIDAttributeName, in: range, options: []) { md, _, _ in
            result.insert(md as? Markdown ?? .none)
        }
        return result
    }

    // MARK: - Attribute Manipulation
    
    /// Returns the attributes for the given markdown.
    private func attributes(for markdown: Markdown) -> [String : Any] {
        
        // the idea is to query for specific markdown & adjust the attributes
        // incrementally
        
        var font = style.baseFont
        var color = style.baseFontColor
        let paragraphyStyle = style.baseParagraphStyle
        
        if markdown.contains(.code) {
            font = style.codeFont
            if let codeColor = style.codeColor { color = codeColor }
        }
        
        if markdown.contains(.bold) {
            font = font.bold
        }
        
        if markdown.contains(.italic) {
            font = font.italic
        }
        
        if let header = markdown.headerValue {
            if let headerSize = style.headerSize(for: header) {
                font = font.withSize(headerSize).bold
            }
            if let headerColor = style.headerColor(for: header) {
                color = headerColor
            }
        }
        
        // TODO: Quote, List
        
        return [
            MarkdownIDAttributeName: markdown,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: color,
            NSParagraphStyleAttributeName: paragraphyStyle
        ]
    }
    
    /// Adds the given markdown (and the associated attributes) to the given
    /// range.
    fileprivate func add(_ markdown: Markdown, to range: NSRange) {
        updateAttributes(in: range) { $0.union(markdown) }
    }
    
    /// Removes the given markdown (and the associated attributes) from the given
    /// range.
    fileprivate func remove(_ markdown: Markdown, from range: NSRange) {
        updateAttributes(in: range) { $0.subtracting(markdown) }
    }
    
    /// Updates all attributes in the given range by transforming markdown tags
    /// using the transformation function, then refetching the attributes for
    /// the transformed values and setting the new attributes.
    private func updateAttributes(in range: NSRange, using transform: (Markdown) -> Markdown) {
        var exisitngMarkdownRanges = [(Markdown, NSRange)]()
        markdownTextStorage.enumerateAttribute(MarkdownIDAttributeName, in: range, options: []) { md, mdRange, _ in
            if let md = md as? Markdown { exisitngMarkdownRanges.append((md, mdRange)) }
        }
        
        for (md, mdRange) in exisitngMarkdownRanges {
            let updatedAttributes = attributes(for: transform(md))
            markdownTextStorage.setAttributes(updatedAttributes, range: mdRange)
        }
    }
    
    // MARK: - List Regex
    
    private lazy var emptyListItemRegex: NSRegularExpression = {
        let pattern = "^((\\d+\\.)|[*+-])[\\t ]*$"
        return try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    }()
    
    private lazy var listItemRegex: NSRegularExpression = {
        let pattern = "^((?:(?:\\d+\\.)|[*+-])\\ ).*$"
        return try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    }()
    
    private lazy var numberPrefixRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "^(\\d+)\\.\\ ", options: .anchorsMatchLines)
    }()
    
    private lazy var bulletPrefixRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "^([*+-])\\ ", options: .anchorsMatchLines)
    }()
    
    // MARK: - List Methods

    private func isEmptyListItem(at range: NSRange) -> Bool {
        return emptyListItemRegex.numberOfMatches(in: text, options: [], range: range) != 0
    }
    
    private func isListItem(at range: NSRange) -> Bool {
        return rangeOfListPrefix(at: range) != nil
    }
    
    private func rangeOfListPrefix(at range: NSRange) -> NSRange? {
        let match = listItemRegex.firstMatch(in: text, options: [], range: range)
        return match?.rangeAt(1)
    }
    
    private func numberPrefix(at range: NSRange) -> (Int, NSRange)? {
        if let match = numberPrefixRegex.firstMatch(in: text, options: [], range: range) {
            let num = markdownTextStorage.attributedSubstring(from: match.rangeAt(1)).string
            return (Int(num) ?? 0, match.range)
        }
        return nil
    }
    
    private func bulletPrefix(at range: NSRange) -> (String, NSRange)? {
        if let match = bulletPrefixRegex.firstMatch(in: text, options: [], range: range) {
            let bullet = markdownTextStorage.attributedSubstring(from: match.rangeAt(1)).string
            return (bullet, match.range)
        }
        return nil
    }
    
    private func isNumberItem(at range: NSRange) -> Bool {
        return numberPrefix(at: range) != nil
    }
    
    private func isBulletItem(at range: NSRange) -> Bool {
        return bulletPrefix(at: range) != nil
    }
    
    /// Returns the next list prefix by first trying to match a previous
    /// list item, otherwise returns the default prefix.
    private func nextListPrefix(type: ListType) -> String {
        guard let previousLine = previousLineRange else { return type.prefix }
        switch type {
        case .number:
            if let num = numberPrefix(at: previousLine)?.0 {
                return "\(num + 1). "
            }
        case .bullet:
            if let bullet = bulletPrefix(at: previousLine)?.0 {
                return "\(bullet) "
            }
        }
        return type.prefix
    }
    
    /// Inserts/removes/converts the list prefix on the current line.
    fileprivate func processList(type: ListType) {
        guard let lineRange = currentLineRange else { return }
        
        // check for existing prefix
        if numberPrefix(at: lineRange) != nil {
            switch type {
            case .number:
                removeListItem()
            case .bullet:
                removeListItem()
                insertListItem(type: type)
            }
        }
        else if bulletPrefix(at: lineRange) != nil {
            switch type {
            case .number:
                removeListItem()
                insertListItem(type: type)
            case .bullet:
                removeListItem()
            }
        }
        else {
            insertListItem(type: type)
        }
    }
    
    /// Inserts a list prefix with the given type on the current line.
    fileprivate func insertListItem(type: ListType) {
        guard
            let lineRange = currentLineRange, !isListItem(at: lineRange),
            let selection = selectedTextRange,
            let lineStart = NSMakeRange(lineRange.location, 0).textRange(in: self)
            else { return }

        let prefix = nextListPrefix(type: type)
        
        // insert prefix with no md
        typingAttributes = attributes(for: .none)
        restore(selection, afterReplacingRange: lineStart, withText: prefix)
        updateTypingAttributes()
    }

    /// Removes the list prefix from the current line.
    fileprivate func removeListItem() {
        guard
            let lineRange = currentLineRange,
            let prefixRange = rangeOfListPrefix(at: lineRange)?.textRange(in: self),
            let selection = selectedTextRange
            else { return }
        
        restore(selection, afterReplacingRange: prefixRange, withText: "")
    }
    
    /// Replaces the range with the text and attempts to restore the selection.
    private func restore(_ selection: UITextRange, afterReplacingRange range: UITextRange, withText text: String) {
        replace(range, withText: text)
        let oldLength = offset(from: range.start, to: range.end)
        let newLength = (text as NSString).length
        let delta = newLength - oldLength
        
        guard
            let start = position(from: selection.start, offset: delta),
            let end = position(from: selection.end, offset: delta),
            let restoredSelection = textRange(from: start, to: end)
            else { return }
        
        selectedTextRange = restoredSelection
    }
    
}


// MARK: - MarkdownBarViewDelegate

extension MarkdownTextView: MarkdownBarViewDelegate {
    
    func markdownBarView(_ view: MarkdownBarView, didSelectMarkdown markdown: Markdown, with sender: IconButton) {
        guard selectedRange.location != NSNotFound else { return }
        
        // apply header to the whole line
        if markdown.isHeader, let range = currentLineRange {
            // remove any existing header styles before adding new header
            let otherHeaders = ([.h1, .h2, .h3] as Markdown).subtracting(markdown)
            activeMarkdown.subtract(otherHeaders)
            remove(otherHeaders, from: range)
            add(markdown, to: range)
        }
        
        // prevent combination of code with bold or italic
        if markdown == .code {
            remove([.bold, .italic], from: selectedRange)
            activeMarkdown.subtract([.bold, .italic])
        }
        else if markdown == .bold || markdown == .italic {
            remove(.code, from: selectedRange)
            activeMarkdown.subtract(.code)
        }

        if selectedRange.length > 0 {
            // if multiple md in selection, remove all inline md before
            // applying the new md
            if self.markdown(in: selectedRange).count > 1 {
                remove([.bold, .italic, .code], from: selectedRange)
            }
            
            add(markdown, to: selectedRange)
        }
        
        activeMarkdown.insert(markdown)
    }
    
    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton) {
        guard selectedRange.location != NSNotFound else { return }
        
        // remove header from the whole line
        if markdown.isHeader, let range = currentLineRange {
            remove(markdown, from: range)
        }

        if selectedRange.length > 0 {
            remove(markdown, from: selectedRange)
        }
        
        activeMarkdown.subtract(markdown)
    }
    
    func markdownBarView(_ view: MarkdownBarView, didSelectListType type: MarkdownTextView.ListType) {
        processList(type: type)
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
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listIndentation = 0
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


// MARK: - Helper Extensions

private extension NSRange {

    func textRange(in textInput: UITextInput) -> UITextRange? {
        guard
            let start = textInput.position(from: textInput.beginningOfDocument, offset: location),
            let end = textInput.position(from: start, offset: length),
            let range = textInput.textRange(from: start, to: end)
            else { return nil }
        
        return range
    }
}
