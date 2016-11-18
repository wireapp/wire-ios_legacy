// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

public extension NSString {
    func containsURL() -> Bool {
        do {
            let urlDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = urlDetector.matches(in: self as String, options: [], range: NSMakeRange(0, self.length))
            return matches.count > 0
        } catch _ as NSError {
            return false
        }
    }

    // MARK: - URL Formatting

    func removingPrefixWWW() -> String {
        return replacingOccurrences(of: "www.", with: "", options: .anchored, range: NSMakeRange(0, self.length))
    }

    func removingTrailingForwardSlash() -> String {
        return replacingOccurrences(of: "/", with: "", options: [.anchored, .backwards], range: NSMakeRange(0, self.length))
    }

    func removingURLScheme(_ scheme: String) -> String {
        return replacingOccurrences(of: scheme + "://", with: "", options: .anchored, range: NSMakeRange(0, self.length))
    }
}
