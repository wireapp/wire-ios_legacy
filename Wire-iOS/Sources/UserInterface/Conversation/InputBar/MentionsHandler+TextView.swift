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

import Foundation

extension MentionsHandler {

    static func cursorPosition(in textView: UITextView, range: UITextRange? = nil) -> Int? {
        if let range = (range ?? textView.selectedTextRange) {
            let position = textView.offset(from: textView.beginningOfDocument, to: range.start)
            return position

        }
        return nil
    }

    static func startMentioning(in textView: UITextView) {
        let (text, cursorOffset) = mentionsTextToInsert(textView: textView)

        let selectionPosition = textView.selectedTextRange?.start ?? textView.beginningOfDocument
        let replacementRange = textView.textRange(from: selectionPosition, to: selectionPosition)!
        textView.replace(replacementRange, withText: text)

        let positionWithOffset = textView.position(from: selectionPosition, offset: cursorOffset) ?? textView.endOfDocument

        let newSelectionRange = textView.textRange(from: positionWithOffset, to: positionWithOffset)
        textView.selectedTextRange = newSelectionRange
    }

    static func mentionsTextToInsert(textView: UITextView) -> (String, Int) {
        let text = textView.attributedText ?? "".attributedString

        let selectionRange = textView.selectedRange
        let cursorPosition = selectionRange.location
        let beforeCursor = NSRange(location: 0, length: cursorPosition)
        let afterCursor = NSRange(location: cursorPosition, length: text.length - cursorPosition)

        var insertSpaceBefore = false
        var insertSpaceAfter = false
        if beforeCursor.length > 0 {
            insertSpaceBefore = (text.attributedSubstring(from: NSRange(location: cursorPosition - 1, length: 1)).string != " ")
        }
        if afterCursor.length > 0 {
            insertSpaceAfter = (text.attributedSubstring(from: NSRange(location: cursorPosition, length: 1)).string != " ")
        }

        let result =
            (insertSpaceBefore ? " " : "") +
            "@" +
            (insertSpaceAfter ? " " : "")

        let cursorOffset = insertSpaceBefore ? 2 : 1
        return (result, cursorOffset)
    }

    static func attributedStringForMentioning(with text: NSAttributedString?, at cursorPosition: Int) -> NSAttributedString {
        guard let text = text else { return "@".attributedString }
        guard text.length > 0 else { return "@".attributedString }
        guard text.wholeRange.contains(cursorPosition) else { return text }
        if cursorPosition == 0 {
            return "@ ".attributedString + text
        } else {
            let beforeCursor = NSRange(location: 0, length: cursorPosition)
            let afterCursor = NSRange(location: cursorPosition, length: text.length - cursorPosition)
            let before = text.attributedSubstring(from: beforeCursor)
            let after = text.attributedSubstring(from: afterCursor)
            return before + "@" + after
        }
    }
}
