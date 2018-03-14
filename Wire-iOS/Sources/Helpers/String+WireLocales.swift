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

extension String {
    func capitalizingFirstLetter() -> String {
        let first = String(prefix(1)).capitalized
        let other = String(dropFirst())
        return first + other
    }
}

extension NSString {
    
    var uppercasedWithCurrentLocale: String {
        return uppercased(with: NSLocale.current)
    }
    
    var lowercasedWithCurrentLocale: String {
        return lowercased(with: NSLocale.current)
    }
    
    private var slashCommandMatcher: NSRegularExpression? {
        struct Singleton {
            static let sharedInstance = try? NSRegularExpression(pattern: "^\\/", options: [])
        }
        return Singleton.sharedInstance
    }
    
    var matchesSlashCommand: Bool {
        let range = NSMakeRange(0, length)
        return slashCommandMatcher?.matches(in: self as String, options: [], range: range).count > 0
    }
    
    var args: [String]? {
        guard self.matchesSlashCommand else {
            return []
        }
        
        let slashlessString = replacingCharacters(in: NSMakeRange(0, 1), with: "")
        return slashlessString.components(separatedBy: CharacterSet.whitespaces)
    }
}
