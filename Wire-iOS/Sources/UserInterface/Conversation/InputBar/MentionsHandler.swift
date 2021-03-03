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
import WireDataModel

extension String {
    var wholeRange: NSRange {
        return NSRange(location: 0, length: endIndex.utf16Offset(in: self))
    }
}

final class MentionsHandler: NSObject {

    fileprivate var mentionRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "([\\s]|^)(@(\\S*))", options: [.anchorsMatchLines])
    }()

    let mentionMatchRange: NSRange
    let searchQueryMatchRange: NSRange

    init?(text: String?, cursorPosition: Int) {
        guard let text = text, !text.isEmpty else { return nil }

        let matches = mentionRegex.matches(in: text, range: text.wholeRange)
        // Cursor is a separator between characters, we are interested in the character before the cursor
        let characterPosition = max(0, cursorPosition - 1)
        guard let match = matches.first(where: { result in result.range.contains(characterPosition) }) else { return nil }
        // Should be 4 matches:
        // 0. whole string
        // 1. space or start of string
        // 2. whole mention
        // 3. only the search string without @
        guard match.numberOfRanges == 4 else { return nil }
        mentionMatchRange = match.range(at: 2)
        searchQueryMatchRange = match.range(at: 3)
        // Character to the left of the cursor position should be inside the mention
        guard mentionMatchRange.contains(characterPosition) else { return nil }
    }

    func searchString(in text: String?) -> String? {
        guard let text = text else { return nil }
        guard let range = Range(searchQueryMatchRange, in: text) else { return nil }
        return String(text[range])
    }

    func replacement(forMention mention: UserType, in attributedString: NSAttributedString) -> (NSRange, NSAttributedString) {
        let mentionString = NSAttributedString(attachment: MentionTextAttachment(user: mention))
        let characterAfterMention = mentionMatchRange.upperBound

        // Add space after mention if it's not there
        let endOfString = !attributedString.wholeRange.contains(characterAfterMention)
        let suffix = endOfString || !attributedString.hasSpaceAt(position: characterAfterMention) ? " " : ""

        return (mentionMatchRange, (mentionString + suffix))
    }

}
