//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension NSAttributedString {

    /// Check this attributed string contains link that missing match the string in given range
    ///  e.g. if the string is `www.google.de`, the link is `http://www.google.de`, it is a matched link and return false
    ///  e.g. 2 if the string is `www.google.de`, the link is `http://www.evil.com`, it is not a matched link and return true
    ///
    /// - Parameter range: the range of the attributed string to check
    /// - Returns: return true if contains mismatch link, if the range is invalid, or not link in the given range, return false
    func containsMismatchedLink(in range: NSRange) -> Bool {
        guard range.location + range.length <= string.count else {
            return false
        }

        let linkString: String = (string as NSString).substring(with: range)

        var mismatchLinkFound = false

        enumerateAttribute(.link, in: range, options: []) { (value, linkRange, _) in
            if range == linkRange,
               let url = value as? URL,
               url.urlWithoutScheme != linkString,
               url.absoluteString != linkString {
                mismatchLinkFound = true
            }
        }

        return mismatchLinkFound
    }
}
