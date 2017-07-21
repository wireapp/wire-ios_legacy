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
    
    private var nextListNumber = 1
    private var nextListBullet = "-"
    private var needsNewNumberListItem = false
    private var needsNewBulletListItem = false
    
    private let defaultAttributes = [
        NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground),
        NSFontAttributeName: FontSpec(.normal, .none).font!
    ]

    public override var selectedTextRange: UITextRange? {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: MarklightTextViewDidChangeSelectionNotification), object: self)
            // invalidate list item prefixes
            nextListNumber = 1
            nextListBullet = "-"
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
        
        let colorScheme = ColorScheme.default()
        let style = MarklightStyle()
        style.syntaxAttributes = [NSForegroundColorAttributeName: colorScheme.accentColor]
        style.codeAttributes[NSForegroundColorAttributeName] = colorScheme.color(withName: ColorSchemeColorTextForeground)
        style.blockQuoteAttributes[NSForegroundColorAttributeName] = colorScheme.color(withName: ColorSchemeColorTextForeground)
        style.fontTextStyle = UIFontTextStyle.subheadline.rawValue
        style.hideSyntax = false
        return style
    }
    
    // MARK: Markdown Insertion
    
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
            
        case .numberList:   insertPrefixSyntax("\(nextListNumber). ", forSelection: selection)
        case .bulletList:   insertPrefixSyntax("\(nextListBullet) ", forSelection: selection)
        case .bold:         insertWrapSyntax("**", forSelection: selection)
        case .italic:       insertWrapSyntax("_", forSelection: selection)
        case .code:         insertWrapSyntax("`", forSelection: selection)
        }
    }
    
    private func insertPrefixSyntax(_ syntax: String, forSelection selection: UITextRange) {
        
        // original start
        let start = selection.start
        // insert syntax at start of line
        let lineStart = lineStartForTextAtPosition(start)
        replace(textRange(from: lineStart, to: lineStart)!, withText: syntax)
        // preserve relative caret position
        let newPos = position(from: start, offset: syntax.characters.count)!
        selectedTextRange = textRange(from: newPos, to: newPos)
    }
    
    private func insertWrapSyntax(_ syntax: String, forSelection selection: UITextRange) {
        
        // original start
        let start = selection.start
        
        // wrap syntax around selection
        if !selection.isEmpty {
            let preRange = textRange(from: start, to: start)!
            replace(preRange, withText: syntax)
            
            // offset acounts for first insertion
            let end = position(from: selection.end, offset: syntax.characters.count)!
            let postRange = textRange(from: end, to: end)!
            replace(postRange, withText: syntax)
        }
        else {
            // insert syntax & move caret inside
            replace(selection, withText: syntax + syntax)
            let newPos = position(from: start, offset: syntax.characters.count)!
            selectedTextRange = textRange(from: newPos, to: newPos)
        }
    }
    
    // MARK: Markdown Deletion
    
    fileprivate func deleteSyntaxForMarkdownElement(type: MarkdownElementType) {
        
        switch type {
        case .header(_), .numberList, .bulletList:
            removePrefixSyntaxForElement(type: type, forSelection: selectedRange)
        case .italic, .bold, .code:
            removeWrapSyntaxForElement(type: type, forSelection: selectedRange)
        }
    }

    private func removePrefixSyntaxForElement(type: MarkdownElementType, forSelection selection: NSRange) {
        
        let pattern: String
        
        switch type {
        case .header(_):    pattern = "\\#{1,3}\\s*"
        case .numberList:   pattern = "\\d+\\.\\s*"
        case .bulletList:   pattern = "[*+-]\\s*"
        default: return
        }
        
        let lineRange = (text as NSString).lineRange(for: selection)
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matchRange = regex.rangeOfFirstMatch(in: text, options: [], range: lineRange)
        text.removeSubrange(text.rangeFrom(range: matchRange))
        
        // shift selection location to account for removal, but don't exceed line start
        let location = max(lineRange.location, selection.location - matchRange.length)
        // how much of selection was part of syntax
        let length = NSIntersectionRange(matchRange, selection).length
        // preserve relative selection
        selectedRange = NSMakeRange(location, selection.length - length)
    }
    
    private func removeWrapSyntaxForElement(type: MarkdownElementType, forSelection selection: NSRange) {
        
        guard let range = rangeForMarkdownElement(type: type, enclosingSelection: selection) else { return }
        let preRange: NSRange
        let postRange: NSRange
        
        switch type {
        case .italic:
            // TODO: adjust italic matcher so match range fits syntax exactly, then refactor
            preRange = NSMakeRange(range.location + 1, 1)
            postRange = NSMakeRange(range.location + range.length - 1, 1)
        case .code:
            preRange = NSMakeRange(range.location, 1)
            postRange = NSMakeRange(range.location + range.length - 1, 1)
        case .bold:
            preRange = NSMakeRange(range.location, 2)
            postRange = NSMakeRange(range.location + range.length - 2, 2)
        default: return
        }
        
        // remove postRange first so preRange is still valid
        text.removeSubrange(text.rangeFrom(range: postRange))
        text.removeSubrange(text.rangeFrom(range: preRange))
        
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
    
    // MARK: Range calculations
    
    private func lineStartForTextAtPosition(_ pos: UITextPosition) -> UITextPosition {
        
        // check if last char is newline
        if let prevPos = position(from: pos, offset: -1) {
            if text(in: textRange(from: prevPos, to: pos)!) == "\n" {
                return pos
            }
        }
        
        // if caret is at document beginning, position() returns nil
        return tokenizer.position(from: pos,
                                  toBoundary: .paragraph,
                                  inDirection: UITextStorageDirection.backward.rawValue) ?? beginningOfDocument
    }
    
    private func rangeForMarkdownElement(type: MarkdownElementType, enclosingSelection selection: NSRange) -> NSRange? {
        
        let groupStyler = (textStorage as! MarklightTextStorage).groupStyler
        
        for range in groupStyler.rangesForElementType(type) {
            // selection is contained in range
            if NSEqualRanges(range, NSUnionRange(selection, range)) {
                return range
            }
        }
        return nil
    }
    
    public func markdownElementsForRange(_ range: NSRange?) -> [MarkdownElementType] {
        
        let selection = range ?? selectedRange
        
        // TODO: different header types
        let elementTypes: [MarkdownElementType] = [.header(.h1), .italic, .bold, .numberList, .bulletList, .code]
        
        
        return elementTypes.filter { type -> Bool in
            return self.isMarkdownElement(type: type, activeForSelection: selection)
        }
    }
    
    private func isMarkdownElement(type: MarkdownElementType, activeForSelection selection: NSRange) -> Bool {
        return rangeForMarkdownElement(type: type, enclosingSelection: selection) != nil
    }
    
    // MARK: Automatic List Insertion
    
    public func handleNewLine() {
        
        guard let caretPos = selectedTextRange?.start else { return }
        
        let lineStart = lineStartForTextAtPosition(caretPos)
        let lineTextRange = textRange(from: lineStart, to: caretPos)!
        let location = offset(from: beginningOfDocument, to: lineTextRange.start)
        let length = offset(from: lineTextRange.start, to: lineTextRange.end)
        let lineRange = NSMakeRange(location, length)
        
        // if line is number list element
        if isMarkdownElement(type: .numberList, activeForSelection: lineRange) {
            // non empty number list item
            let regex = try! NSRegularExpression(pattern: "(^\\d+)(?:[.][\\t ]+)(.|[\\t ])+", options: [.anchorsMatchLines])
            
            if let match = regex.firstMatch(in: text, options: [], range: lineRange) {
                
                let numberStr = text.substring(with: text.rangeFrom(range: match.rangeAt(1))) as NSString
                nextListNumber = numberStr.integerValue + 1
                needsNewNumberListItem = true

            } else {
                // replace empty list item with newline
                text.removeSubrange(text.rangeFrom(range: lineRange))
                nextListNumber = 1
            }
            
        } else if isMarkdownElement(type: .bulletList, activeForSelection: lineRange) {
            // non empty bullet list item
            let regex = try! NSRegularExpression(pattern: "(^[*+-])(?:[\\t ]+)(.|[\\t ])+", options: [.anchorsMatchLines])
            
            if let match = regex.firstMatch(in: text, options: [], range: lineRange) {
                nextListBullet = text.substring(with: text.rangeFrom(range: match.rangeAt(1)))
                needsNewBulletListItem = true
            } else {
                // replace empty list item with newline
                text.removeSubrange(text.rangeFrom(range: lineRange))
                nextListBullet = "-"
            }
        }
    }
    
    @objc private func textChangedHandler() {
        if needsNewNumberListItem {
            needsNewNumberListItem = false
            insertSyntaxForMarkdownElement(type: .numberList)
        } else if needsNewBulletListItem {
            needsNewBulletListItem = false
            insertSyntaxForMarkdownElement(type: .bulletList)
        }
    }
    
    @objc public func resetTypingAttributes() {
        typingAttributes = defaultAttributes
    }
}

// MARK: MarkdownBarViewDelegate

extension MarklightTextView: MarkdownBarViewDelegate {
    
    public func markdownBarView(_ markdownBarView: MarkdownBarView, didSelectElementType type: MarkdownElementType, with sender: IconButton) {
        insertSyntaxForMarkdownElement(type: type)
    }
    
    public func markdownBarView(_ markdownBarView: MarkdownBarView, didDeselectElementType type: MarkdownElementType, with sender: IconButton) {
        deleteSyntaxForMarkdownElement(type: type)
    }
}

extension String {
    
    func rangeFrom(range: NSRange) -> Range<String.Index> {
        let start = index(startIndex, offsetBy: range.location)
        let end = index(startIndex, offsetBy: range.location + range.length)
        return start..<end
    }
}
