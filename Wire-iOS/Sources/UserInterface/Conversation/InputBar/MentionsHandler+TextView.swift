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

        let prefix = needsSpace(text: text, position: cursorPosition - 1) ? " " : ""
        let suffix = needsSpace(text: text, position: cursorPosition) ? " " : ""

        let result = prefix + "@" + suffix

        // We need to change the selection depending if we insert only '@' or ' @'
        let cursorOffset = prefix.isEmpty ? 1 : 2
        return (result, cursorOffset)
    }

    fileprivate static func needsSpace(text: NSAttributedString, position: Int) -> Bool {
        guard text.wholeRange.contains(position) else { return false }
        return !text.hasSpaceAt(position: position)
    }
}
