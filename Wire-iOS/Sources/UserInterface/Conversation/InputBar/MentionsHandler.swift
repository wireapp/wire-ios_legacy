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

@objc public class MentionsHandler: NSObject {

    let atSymbolIndex: Int

    init(atSymbolRange: NSRange) {
        self.atSymbolIndex = atSymbolRange.lowerBound
    }

    func shouldReplaceMention(in text: String) -> Bool {
        return text.hasSuffix(" ")
    }

    func mentionRange(in text: String, includingAtSymbol: Bool) -> Range<String.UTF16View.Index> {
        let extraOffset = includingAtSymbol ? 0 : 1
        let start = text.utf16.index(text.utf16.startIndex, offsetBy: atSymbolIndex + extraOffset)
        let range = start..<text.utf16.endIndex
        return range
    }

    func searchString(in text: String) -> String {
        let range = mentionRange(in: text, includingAtSymbol: false)
        let searchString = text[range]
        return String(searchString)
    }

    func replace(mention: MentionTextAttachment, in attributedString: NSAttributedString) -> NSAttributedString {
        let mentionString = NSAttributedString(attachment: mention)
        let range = mentionRange(in: attributedString.string, includingAtSymbol: true)
        let nsRange = NSRange(range, in: attributedString.string)
        let mut = NSMutableAttributedString(attributedString: attributedString)
        mut.replaceCharacters(in: nsRange, with: mentionString)
        return mut
    }
}
