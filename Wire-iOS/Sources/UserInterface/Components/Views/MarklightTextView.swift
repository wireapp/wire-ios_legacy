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
    
    fileprivate let marklightTextStorage = MarklightTextStorage()
    
    public override var selectedTextRange: UITextRange? {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: MarklightTextViewDidChangeSelectionNotification), object: self)
        }
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        
        MarklightTextView.configure(textStorage: marklightTextStorage, hideSyntax: false)
        
        let marklightLayoutManager = NSLayoutManager()
        marklightTextStorage.addLayoutManager(marklightLayoutManager)
        
        let marklightTextContainer = NSTextContainer()
        marklightLayoutManager.addTextContainer(marklightTextContainer)
        
        super.init(frame: frame, textContainer: marklightTextContainer)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func configure(textStorage: MarklightTextStorage, hideSyntax: Bool) {
        
        let colorScheme = ColorScheme.default()
        textStorage.syntaxColor = colorScheme.color(withName: ColorSchemeColorAccent)
        textStorage.quoteColor = colorScheme.color(withName: ColorSchemeColorTextForeground)
        textStorage.codeColor = colorScheme.color(withName: ColorSchemeColorTextForeground)
        textStorage.codeFontName = "Menlo"
        textStorage.fontTextStyle = UIFontTextStyle.subheadline.rawValue
        textStorage.hideSyntax = hideSyntax
        
        textStorage.defaultAttributes = [
            NSForegroundColorAttributeName: colorScheme.color(withName: ColorSchemeColorTextForeground),
            NSFontAttributeName: FontSpec(.normal, .none).font!
        ]
    }
    
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
            
        case .numberList:   insertPrefixSyntax("1. ", forSelection: selection)
        case .bulletList:   insertPrefixSyntax("- ", forSelection: selection)
        case .bold:         insertWrapSyntax("**", forSelection: selection)
        case .italic:       insertWrapSyntax("_", forSelection: selection)
        case .code:         insertWrapSyntax("`", forSelection: selection)
        }
    }
    
    private func insertPrefixSyntax(_ syntax: String, forSelection selection: UITextRange) {
        
        // original start
        let start = selection.start
        // insert syntax at start of line
        let lineStart = lineStartForCurrentSelection()
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
    
    private func lineStartForCurrentSelection() -> UITextPosition {
        
        // no selection
        guard let caretPos = selectedTextRange?.start else {
            return beginningOfDocument
        }
        
        // check if last char is newline
        if let prevPos = position(from: caretPos, offset: -1) {
            if text(in: textRange(from: prevPos, to: caretPos)!) == "\n" {
                return caretPos
            }
        }
        
        // if caret is at document beginning, position() returns nil
        return tokenizer.position(from: caretPos,
                                  toBoundary: .paragraph,
                                  inDirection: UITextStorageDirection.backward.rawValue) ?? beginningOfDocument
    }
    
    public func markdownElementsForRange(_ range: NSRange?) -> [MarkdownElementType] {
        
        let groupStyler = (textStorage as! MarklightTextStorage).groupStyler
        let selection = range ?? selectedRange
        var types = [MarkdownElementType]()
        
        // TODO: different header types
        let elementTypes: [MarkdownElementType] = [.header(.h1), .italic, .bold, .numberList, .bulletList, .code]
        
        for type in elementTypes {
            for range in groupStyler.rangesForElementType(type) {
                // selection is contained in range
                if NSEqualRanges(range, NSUnionRange(selection, range)) {
                    types.append(type)
                    break
                }
            }
        }
        
        return types
    }
}
