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
    func containsMarkdownLink(in range: NSRange) -> Bool {
        guard range.location + range.length <= string.count else {
            return false
        }
        
        let linkString: NSString = (string as NSString).substring(with: range) as NSString

        var mismatchLinkFound = false

        enumerateAttribute(.link, in: range, options: []) { (value, linkRange, _) in
            print(value)
            print(value as? NSString == linkString)
            print(linkString)
            if range == linkRange,
               let value = value as? NSString,
                value != linkString {
                mismatchLinkFound = true
            }
        }

        return mismatchLinkFound
    }
}
