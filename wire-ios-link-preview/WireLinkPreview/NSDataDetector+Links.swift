//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

/// A URL and its range in the parent text.
public typealias URLWithRange = (URL: URL, range: NSRange)

extension NSDataDetector {

    /// A data detector configured to detect only links.
    @objc public static var linkDetector: NSDataDetector? {
        return try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }

    /**
     * Detects whether the text contains at least one link.
     * - parameter text: The text to check.
     * - returns: Whether the text contains any links.
     */

    @objc(containsLinkInText:)
    public func containsLink(in text: String) -> Bool {
        return !detectLinks(in: text).isEmpty
    }

    /**
     * Returns a list of URLs in the specified text message.
     * - parameter text: The text to check.
     * - returns: The list of detected URLs, or an empty array if detection failed.
     */

    @objc(detectLinksInText:)
    public func detectLinks(in text: String) -> [URL] {
        let textRange = NSRange(text.startIndex ..< text.endIndex, in: text)
        return matches(in: text, options: [], range: textRange).compactMap(\.url)
    }

    /**
     * Returns URLs found in text together with their range in within the text.
     * - parameter text: The text in which to search for URLs.
     * - parameter excludedRanges: Ranges within the text which should we excluded from the search.
     * - returns: The list of URLs in the text.
     */

    public func detectLinksAndRanges(in text: String, excluding excludedRanges: [NSRange] = []) -> [URLWithRange] {
        let wholeTextRange = NSRange(text.startIndex ..< text.endIndex, in: text)
        let validRangeIndexSet = NSMutableIndexSet(indexesIn: wholeTextRange)
        excludedRanges.forEach(validRangeIndexSet.remove)

        return matches(in: text, options: [], range: wholeTextRange).compactMap {
            let range = $0.range
            guard let url = $0.url, validRangeIndexSet.contains(in: range) else { return nil }
            return (url, range)
        }
    }

}
