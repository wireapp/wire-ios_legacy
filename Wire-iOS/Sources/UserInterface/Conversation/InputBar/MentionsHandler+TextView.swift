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

fileprivate extension NSAttributedString {
    func hasSpaceAt(position: Int) -> Bool {
        guard wholeRange.contains(position) else { return false }
        return attributedSubstring(from: NSRange(location: position, length: 1)).string == " "
    }
}

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

        let prefix = text.hasSpaceAt(position: cursorPosition - 1) ? "" : " "
        let suffix = text.hasSpaceAt(position: cursorPosition) ? "" : " "

        let result = prefix + "@" + suffix

        // We need to change the selection depending if we insert only '@' or ' @'
        let cursorOffset = prefix.isEmpty ? 1 : 2
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
