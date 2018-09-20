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

extension NSString {
    @objc func wr_containsOnlyEmojiWithSpaces() -> Bool {
        return (self as String).containsOnlyEmojiWithSpaces
    }
}

extension Unicode.Scalar {
    var isEmoji: Bool {
        switch self.value {
        case 0x200D,       // Zero width joiner
        0x2030...0x329F,   // Misc symbols
        0xFE00...0xFE0F:   // Variation Selectors
            return true
        default:
            return false
        }
    }
}

extension String {
    var containsOnlyEmojiWithSpaces: Bool {
        return components(separatedBy: .whitespaces).joined().containsOnlyEmoji
    }
    
    var containsOnlyEmoji: Bool {
        guard self.count > 0 else { return false }
        
        for scalar in unicodeScalars {
            if !CharacterSet.symbols.contains(scalar) &&
                !scalar.isEmoji
            {
                return false
            }
        }
        
        return true
    }
}
