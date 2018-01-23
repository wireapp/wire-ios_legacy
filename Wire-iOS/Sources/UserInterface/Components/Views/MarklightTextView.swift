//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Marklight

let MarklightTextViewDidChangeSelectionNotification = "MarklightTextViewDidChangeSelectionNotification"

public class MarklightTextView: NextResponderTextView {
    
    public let style: MarklightStyle
    fileprivate let marklightTextStorage: MarklightTextStorage
    
    fileprivate var needsNewNumberListItem = false
    fileprivate var needsNewBulletListItem = false
    
    fileprivate let defaultAttributes: [String: Any] = [
        NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground),
        NSFontAttributeName: FontSpec(.normal, .none).font!,
        NSParagraphStyleAttributeName: NSMutableParagraphStyle.default,
        NSKernAttributeName: 0.295
    ]

    public override var selectedTextRange: UITextRange? {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: MarklightTextViewDidChangeSelectionNotification), object: self)
        }
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        
        style = MarklightTextView.defaultMarkdownStyle()
        marklightTextStorage = MarklightTextStorage(style: style)
        
        marklightTextStorage.defaultAttributes = defaultAttributes
        let marklightLayoutManager = NSLayoutManager()
        marklightTextStorage.addLayoutManager(marklightLayoutManager)
        
        let marklightTextContainer = NSTextContainer()
        marklightLayoutManager.addTextContainer(marklightTextContainer)
        
        super.init(frame: frame, textContainer: marklightTextContainer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(textChangedHandler), name: NSNotification.Name.UITextViewTextDidChange, object: self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    class func defaultMarkdownStyle() -> MarklightStyle {
        
        let defaultFont = FontSpec(.normal, .light).font!
        let colorScheme = ColorScheme.default()
        let style = MarklightStyle()
        
        style.syntaxAttributes = [NSForegroundColorAttributeName: colorScheme.accentColor]
        style.italicAttributes = [NSFontAttributeName: defaultFont.italicFont()]
        style.codeAttributes[NSForegroundColorAttributeName] = colorScheme.color(withName: ColorSchemeColorTextForeground)
        style.blockQuoteAttributes[NSForegroundColorAttributeName] = colorScheme.color(withName: ColorSchemeColorTextForeground)
        style.fontTextStyle = UIFontTextStyle.subheadline.rawValue
        style.hideSyntax = false
        
        return style
    }
}


// MARK: - Text Stripping

extension MarklightTextView {
    
    /// Returns the current text buffer sans empty markdown elements and
    /// leading/trailing whitespace within non empty markdown elements.
    ///
    public var preparedText: String {
        get {
            var text = self.text!
            var rangesToDelete = rangesOfEmptyMarkdownElements()
            rangesToDelete += rangesOfMarkdownWhitespace()
            rangesToDelete += rangesOfSyntaxForMarkdownEmoji()
            
            // discard nested ranges, sort by location descending
            rangesToDelete = flattenRanges(rangesToDelete).sorted {
                return $0.location >= $1.location
            }
            
            // strip empty markdown
            rangesToDelete.forEach {
                text.deleteCharactersIn(range: $0)
            }
            
            // strip empty list items
            let numberListPrefix = "(^\\d+)(?:[.][\\t ]*$)"
            let bulletListPrefix = "(^[*+-])([\\t ]*$)"
            let listPrefixPattern = "(\(numberListPrefix))|(\(bulletListPrefix))"
            let regex = try! NSRegularExpression(pattern: listPrefixPattern, options: [.anchorsMatchLines])
            let wholeRange = NSMakeRange(0, text.count)
            text = regex.stringByReplacingMatches(in: text, options: [], range: wholeRange, withTemplate: "")
            
            return text
        }
    }
}

// MARK: - Markdown Insertion

extension MarklightTextView {
    
    public func insertSyntaxForMarkdownElement(type: MarkdownElementType) {
        
        guard let selection = selectedTextRange else { return }
        
        switch type {
        case .header(let size):
            
            let syntax: String
            switch size {
            case .h1: syntax = "# "
            case .h2: syntax = "## "
            case .h3: syntax = "### "
            }
            
            insertPrefixSyntax(syntax, forSelection: selection)
            
        case .numberList:
            insertPrefixSyntax("\(nextListNumber). ", forSelection: selection)
            renumberLists()
            
        case .bulletList:   insertPrefixSyntax("\(nextListBullet) ", forSelection: selection)
        case .bold:         insertWrapSyntax("**", forSelection: selection)
        case .italic:       insertWrapSyntax("_", forSelection: selection)
        case .code:         insertWrapSyntax("`", forSelection: selection)
        default: return
        }
    }
    
    fileprivate func insertPrefixSyntax(_ syntax: String, forSelection selection: UITextRange) {
        
        // original start
        let start = selection.start
        // insert syntax at start of line
        let lineStart = lineStartForTextAtPosition(start)
        replace(textRange(from: lineStart, to: lineStart)!, withText: syntax)
        // preserve relative caret position
        let newPos = position(from: start, offset: syntax.count)!
        selectedTextRange = textRange(from: newPos, to: newPos)
    }
    
    fileprivate func insertWrapSyntax(_ syntax: String, forSelection selection: UITextRange) {
        
        // original start
        let start = selection.start
        
        // wrap syntax around selection
        if !selection.isEmpty {
            let preRange = textRange(from: start, to: start)!
            replace(preRange, withText: syntax)
            
            // offset acounts for first insertion
            let end = position(from: selection.end, offset: syntax.count)!
            let postRange = textRange(from: end, to: end)!
            replace(postRange, withText: syntax)
        }
        else {
            // insert syntax & move caret inside
            replace(selection, withText: syntax + syntax)
            let newPos = position(from: start, offset: syntax.count)!
            selectedTextRange = textRange(from: newPos, to: newPos)
        }
    }
}

// MARK: - Markdown Deletion
    
extension MarklightTextView {
    
    public func deleteSyntaxForMarkdownElement(type: MarkdownElementType) {
        
        switch type {
        case .header(_), .numberList, .bulletList:
            removePrefixSyntaxForElement(type: type, forSelection: selectedRange)
        case .italic, .bold, .code:
            removeWrapSyntaxForElement(type: type, forSelection: selectedRange)
        default: return
        }
    }

    fileprivate func removePrefixSyntaxForElement(type: MarkdownElementType, forSelection selection: NSRange) {
        
        guard
            let range = rangeForMarkdownElement(type: type, enclosingSelection: selection),
            let preRange = range.preRange
            else { return }
        
        let lineRange = (text as NSString).lineRange(for: selection)
        text.deleteCharactersIn(range: preRange)
        
        // shift selection location to account for removal, but don't exceed line start
        let location = max(lineRange.location, selection.location - preRange.length)
        
        // how much of selection was part of syntax
        let length = NSIntersectionRange(preRange, selection).length
        
        // preserve relative selection
        selectedRange = NSMakeRange(location, selection.length - length)
    }
    
    fileprivate func removeWrapSyntaxForElement(type: MarkdownElementType, forSelection selection: NSRange) {
        
        guard
            let range = rangeForMarkdownElement(type: type, enclosingSelection: selection),
            let preRange = range.preRange,
            let postRange = range.postRange
            else { return }
        
        // remove postRange first so preRange is still valid
        text.deleteCharactersIn(range: postRange)
        text.deleteCharactersIn(range: preRange)
        
        // reposition caret:
        // if non zero selection or caret pos was within postRange
        if selection.length > 0 || NSEqualRanges(postRange, NSUnionRange(selection, postRange)) {
            // move caret to end of token
            selectedRange = NSMakeRange(postRange.location - preRange.length, 0)
        }
        else if NSEqualRanges(preRange, NSUnionRange(selection, preRange)) {
            // caret was within preRange, move caret to start of token
            selectedRange = NSMakeRange(preRange.location, 0)
        }
        else {
            // caret pos was between syntax, preserve relative position
            selectedRange = NSMakeRange(selection.location - preRange.length, 0)
        }
    }
}

// MARK: - Range Calculations

extension MarklightTextView {
    
    /// Returns the text position indicating the start of the line containin the given
    /// position.
    ///
    fileprivate func lineStartForTextAtPosition(_ pos: UITextPosition) -> UITextPosition {
        
        guard let caretPos = selectedTextRange?.start, caretPos != beginningOfDocument else {
            return beginningOfDocument
        }
        
        // if prev char is new line, then caret is at start of current line
        if let prevPos = position(from: caretPos, offset: -1), text(in: textRange(from: prevPos, to: caretPos)!) == "\n" {
            return caretPos
        } else {
            return tokenizer.position(from: caretPos, toBoundary: .paragraph, inDirection: UITextStorageDirection.backward.rawValue)!
        }
    }
    
    /// Returns the range of the line previous to the current selection if it exists, else nil.
    ///
    fileprivate func rangeOfPreviousLine() -> NSRange? {
        
        guard let caretPos = selectedTextRange?.start, caretPos != beginningOfDocument else { return nil }
        
        let currLineStart = lineStartForTextAtPosition(caretPos)
        
        // move back one char
        if let prevPos = position(from: currLineStart, offset: -1) {
            if let prevLineStart = tokenizer.position(from: prevPos, toBoundary: .paragraph, inDirection: UITextStorageDirection.backward.rawValue) {
                return NSMakeRange(offset(from: beginningOfDocument, to: prevLineStart),
                                   offset(from: prevLineStart, to: prevPos)
                )
            }
        }
        
        return nil
    }
    
    /// Returns all ranges of all markdown elements.
    ///
    fileprivate func allMarkdownRanges() -> [MarkdownRange] {
        
        let types: [MarkdownElementType] = [
            .header(.h1), .header(.h2), .header(.h3), .bold,
            .italic, .numberList, .bulletList, .code, .quote
        ]
        
        var ranges = [MarkdownRange]()
        let groupStyler = marklightTextStorage.groupStyler
        types.forEach { ranges += groupStyler.rangesForElementType($0) }
        return ranges
    }
    
    fileprivate func rangeForMarkdownElement(type: MarkdownElementType, enclosingSelection selection: NSRange) -> MarkdownRange? {
        
        let groupStyler = marklightTextStorage.groupStyler
        
        for range in groupStyler.rangesForElementType(type) {
            // selection is contained in range
            if NSEqualRanges(range.wholeRange, NSUnionRange(selection, range.wholeRange)) {
                return range
            }
        }
        return nil
    }
    
    /// Returns all ranges of leading/trailing whitespace exclusively contained
    /// within markdown elements.
    ///
    fileprivate func rangesOfMarkdownWhitespace() -> [NSRange] {
        
        let text = self.text as NSString
        var rangesToDelete = [NSRange]()
        let charSet = CharacterSet.whitespacesAndNewlines.inverted
        
        for range in allMarkdownRanges() {
            
            let contentRange = range.contentRange
            
            // range start of first non whitespace char in content range
            let rangeOfFirstChar = text.rangeOfCharacter(from: charSet, options: [], range: contentRange)
            
            // if not found, then content range contains only whitespace
            if rangeOfFirstChar.location == NSNotFound {
                rangesToDelete.append(contentRange)
                continue
            } else {
                let spaces = rangeOfFirstChar.location - contentRange.location
                if spaces > 0 {
                    rangesToDelete.append(NSMakeRange(contentRange.location, spaces))
                }
            }
            
            // as above, but starting from end of content range
            let rangeOfLastChar = text.rangeOfCharacter(from: charSet, options: .backwards, range: range.contentRange)
            if rangeOfLastChar.location != NSNotFound{
                let spaces = NSMaxRange(contentRange) - NSMaxRange(rangeOfLastChar)
                if spaces > 0 {
                    rangesToDelete.append(NSMakeRange(NSMaxRange(rangeOfLastChar), spaces))
                }
            }
        }
        
        return rangesToDelete
    }
    
    /// Returns all ranges of markdown elements that have zero content or contain
    /// containing only whitespace.
    ///
    fileprivate func rangesOfEmptyMarkdownElements() -> [NSRange] {
        
        var result = [NSRange]()
        
        allMarkdownRanges().forEach {
            if isEmptyMarkdownElement($0) {
                result.append($0.wholeRange)
            }
        }
        
        return result
    }
    
    /// Returns all syntax ranges of markdown elements that contain only whitespace and
    /// at least one emoji.
    ///
    fileprivate func rangesOfSyntaxForMarkdownEmoji() -> [NSRange] {
        
        var result = [NSRange]()
        
        allMarkdownRanges().forEach {
            if isMarkdownEmoji($0) {
                if let preRange = $0.preRange { result.append(preRange) }
                if let postRange = $0.postRange { result.append(postRange) }
            }
        }
        
        return result
    }
    
    /// Filters the given array of ranges by discarding all ranges that are
    /// nested within at least one other range.
    /// - parameter ranges: an array of ranges to filter
    ///
    fileprivate func flattenRanges(_ ranges: [NSRange]) -> [NSRange] {
        
        // sort by length ascending
        var ranges = ranges.sorted { return $0.length <= $1.length }
        var result = [NSRange]()
        
        // take the largest range
        if let next = ranges.popLast() {
            result.append(next)
        }
        
        // check each remaining range
        outer: while let next = ranges.popLast() {
            for range in result {
                // if it is nested
                if NSEqualRanges(range, NSUnionRange(range, next)) {
                    continue outer
                }
            }
            // non nested range
            result.append(next)
        }
        
        return result
    }
    
    // MARK: - Determining Markdown
    
    public func markdownElementsForRange(_ range: NSRange?) -> [MarkdownElementType] {
        
        let selection = range ?? selectedRange
        
        let elementTypes: [MarkdownElementType] = [
            .header(.h1), .header(.h2), .header(.h3),
            .italic, .bold, .numberList, .bulletList,
            .code, .quote
        ]
        
        return elementTypes.filter { type -> Bool in
            return self.isMarkdownElement(type: type, activeForSelection: selection)
        }
    }
    
    fileprivate func isMarkdownElement(type: MarkdownElementType, activeForSelection selection: NSRange) -> Bool {
        return rangeForMarkdownElement(type: type, enclosingSelection: selection) != nil
    }
    
    /// Returns true if the markdown element specified by the given range has a
    /// zero content range or the content text contains only whitespace and/or
    /// other markdown syntax.
    /// - parameter range: the range specifying a markdown element
    ///
    fileprivate func isEmptyMarkdownElement(_ range: MarkdownRange) -> Bool {
        
        return  range.contentRange.length == 0 || markdown(range, containsOnlyCharactersIn: CharacterSet.whitespacesAndNewlines)
    }
    
    /// Returns true if the markdown element specified by the given range contains
    /// only emojis, whitespace and other markdown syntax.
    /// - parameter range: the range specifying a markdown element
    ///
    fileprivate func isMarkdownEmoji(_ range: MarkdownRange) -> Bool {
        
        var emojisAndSpaces = CharacterSet.symbols.union(CharacterSet.whitespaces)
        
        // the zero-width joiner is used to combine multiple emojis into new ones
        emojisAndSpaces.insert("\u{200D}")
        // '+' is used for list items
        emojisAndSpaces.remove("+")
        
        return markdown(range, containsOnlyCharactersIn: emojisAndSpaces)
    }
    
    /// Returns true if the markdown element specified by the given range contains
    /// only characters in the given set, other markdown syntax, or if the content is empty.
    /// - parameter range: the range specifying a markdown element
    /// - parameter set: the set of permissible characters
    ///
    fileprivate func markdown(_ range: MarkdownRange, containsOnlyCharactersIn set: CharacterSet) -> Bool {
        
        // we ignore markdown syntax to allow for nested markdown
        let syntaxColor = style.syntaxAttributes[NSForegroundColorAttributeName] as! UIColor
        let markdown = attributedText.attributedSubstring(from: range.wholeRange)
        var violation = false
        
        markdown.enumerateAttribute(NSForegroundColorAttributeName, in: NSMakeRange(0, markdown.length)) { value, range, stop in
            // not syntax and contains non permissable char
            if value as? UIColor != syntaxColor && markdown.string.substring(with: range).containsCharacters(from: set.inverted) {
                violation = true
                stop.pointee = true
            }
        }

        return !violation
    }
}


// MARK: - Automatic List Insertion

extension MarklightTextView {
    
    fileprivate var nextListNumber: Int {
        // if the line before the caret is a list item, return the next number
        if let range = rangeOfPreviousLine() {
            let regex = try! NSRegularExpression(pattern: "^\\d+", options: .anchorsMatchLines)
            if let match = regex.firstMatch(in: text, range: range) {
                return (text.substring(with: match.range) as NSString).integerValue + 1
            }
        }
        
        return 1
    }
    
    fileprivate var nextListBullet: String {
        // if line before the caret is a bullet item, return the same bullet
        if let range = rangeOfPreviousLine() {
            let regex = try! NSRegularExpression(pattern: "^[-+*]", options: .anchorsMatchLines)
            if let match = regex.firstMatch(in: text, range: range) {
                return text.substring(with: match.range)
            }
        }
        
        return "-"
    }
    
    /// Checks if the caret is currently on a list item, if so, determines whether
    /// the next item should be inserted or the current item should be deleted.
    /// Note: this method should be called after the user enters a new line, but
    /// before the new line is inserted.
    ///
    public func handleNewLine() {
        
        if let markdownRange = rangeForMarkdownElement(type: .numberList, enclosingSelection: selectedRange) {
            
            if isEmptyMarkdownElement(markdownRange) {
                text.deleteCharactersIn(range: markdownRange.wholeRange)
            } else {
                needsNewNumberListItem = true
            }
            
        } else if let markdownRange = rangeForMarkdownElement(type: .bulletList, enclosingSelection: selectedRange) {
            
            if isEmptyMarkdownElement(markdownRange) {
                text.deleteCharactersIn(range: markdownRange.wholeRange)
            } else {
                needsNewBulletListItem = true
            }
        }
        
    }
    
    // Invoked when the text changes
    @objc fileprivate func textChangedHandler() {
        if needsNewNumberListItem {
            needsNewNumberListItem = false
            insertSyntaxForMarkdownElement(type: .numberList)
        } else if needsNewBulletListItem {
            needsNewBulletListItem = false
            insertSyntaxForMarkdownElement(type: .bulletList)
        }
    }
    
    /// Ensures each sequential numbered list item from the current caret
    /// position is correctly numbered.
    ///
    fileprivate func renumberLists() {
        
        let listPrefix = "(?:(\\d+)[.][\\t ]+)"
        let listItemPattern = "(?:^\(listPrefix))(.)*"
        let wholeListPattern = "(?:\(listItemPattern))(\\n\(listItemPattern))*"
        let wholeRange = NSMakeRange(0, (text as NSString).length)
        
        let wholeListRegex = try! NSRegularExpression(pattern: wholeListPattern, options: .anchorsMatchLines)
        let itemRegex = try! NSRegularExpression(pattern: listItemPattern, options: .anchorsMatchLines)
        
        let previousSelection = selectedRange
        var index = self.nextListNumber
        
        wholeListRegex.enumerateMatches(in: text, options: [], range: wholeRange) { result, _, stop in
            
            // the range of the whole list enclosing the cursor
            if let listRange = result?.range, NSEqualRanges(NSIntersectionRange(listRange, selectedRange), selectedRange) {
                
                let currentItemRange = (text as NSString).paragraphRange(for: previousSelection)
                let itemsBelow = NSMakeRange(currentItemRange.location, listRange.length - (currentItemRange.location - listRange.location))
                
                // for each list item at or below cursor position
                itemRegex.enumerateMatches(in: text, options: [], range: itemsBelow) { innerResult, _, _ in
                    if let itemNumber = innerResult?.rangeAt(1) {
                        text = (text as NSString).replacingCharacters(in: itemNumber, with: "\(index)")
                        index += 1
                    }
                }
                
                // no need to reformat other lists
                stop.pointee = true
            }
        }
        
        selectedRange = previousSelection
        scrollRangeToVisible(selectedRange)
    }
    
    @objc public func resetTypingAttributes() {
        typingAttributes = defaultAttributes
    }
}

// MARK: - MarkdownBarViewDelegate

extension MarklightTextView: MarkdownBarViewDelegate {
    
    public func markdownBarView(_ markdownBarView: MarkdownBarView, didSelectElementType type: MarkdownElementType, with sender: IconButton) {
        
        switch type {
        case .header, .numberList, .bulletList:  removeExistingPrefixSyntax()
        default: break
        }
        
        insertSyntaxForMarkdownElement(type: type)
    }
    
    public func markdownBarView(_ markdownBarView: MarkdownBarView, didDeselectElementType type: MarkdownElementType, with sender: IconButton) {
        deleteSyntaxForMarkdownElement(type: type)
    }
    
    private func removeExistingPrefixSyntax() {
        removeExistingHeader()
        removeExistingListItem()
    }
    
    private func removeExistingHeader() {
        
        var currentHeader: MarkdownElementType?
        for header in [MarkdownElementType.header(.h1), .header(.h2), .header(.h3)] {
            if isMarkdownElement(type: header, activeForSelection: selectedRange) {
                currentHeader = header
            }
        }
        
        if let header = currentHeader {
            deleteSyntaxForMarkdownElement(type: header)
        }
    }
    
    private func removeExistingListItem() {
        
        var currentListType: MarkdownElementType?
        if isMarkdownElement(type: .numberList, activeForSelection: selectedRange) {
            currentListType = .numberList
        } else if isMarkdownElement(type: .bulletList, activeForSelection: selectedRange) {
            currentListType = .bulletList
        }
        
        if let type = currentListType {
            deleteSyntaxForMarkdownElement(type: type)
        }
    }
}

extension String {
    
    mutating fileprivate func deleteCharactersIn(range: NSRange) {
        self = (self as NSString).replacingCharacters(in: range, with: "")
    }
    
    fileprivate func substring(with range: NSRange) -> String {
        return (self as NSString).substring(with: range)
    }
}
