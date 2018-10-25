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

public extension String {
    
    var containsURL: Bool {
        return URLMatchesInString.count > 0
    }
    
    var URLsInString: [URL?] {
        return URLMatchesInString.map(\.url)
    }
    
    private var URLMatchesInString: [NSTextCheckingResult] {
        do {
            let urlDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = urlDetector.matches(in: self, options: [], range: NSMakeRange(0, self.count))
            return matches
        } catch _ as NSError {
            return []
        }
    }
}
