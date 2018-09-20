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

    init?(text: String, range: NSRange) {
        guard text == "@" || text.hasSuffix("@") else { return nil }
        atSymbolIndex = range.location
    }

    func mentionRange(in text: String, includingAtSymbol: Bool) -> Range<String.UTF16View.Index> {
        let extraOffset = includingAtSymbol ? 0 : 1
        let start = text.utf16.index(text.utf16.startIndex, offsetBy: atSymbolIndex + extraOffset)
        let range = start..<text.utf16.endIndex
        return range
    }

    func searchString(in text: String) -> String? {
        let validIndex = (text.startIndex.encodedOffset..<text.endIndex.encodedOffset).contains(atSymbolIndex)
        guard validIndex else { return nil }
        let range = mentionRange(in: text, includingAtSymbol: false)
        return String(text[range])
    }

    func replace(mention: UserType, in attributedString: NSAttributedString) -> NSAttributedString {
        let mentionString = NSAttributedString(attachment: MentionTextAttachment(user: mention))
        let range = mentionRange(in: attributedString.string, includingAtSymbol: true)
        let nsRange = NSRange(range, in: attributedString.string)
        let mut = NSMutableAttributedString(attributedString: attributedString)
        mut.replaceCharacters(in: nsRange, with: mentionString)
        return mut
    }
}
