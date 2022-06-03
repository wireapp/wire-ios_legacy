//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

public extension CharacterSet {
    // http://www.unicode.org/charts/PDF/U0300.pdf
    private static let diacriticsCombiningCodes              = CharacterSet(charactersIn: UnicodeScalar(0x0300 as UInt16)!...UnicodeScalar(0x036f as UInt16)!)
    // http://www.unicode.org/charts/PDF/U1AB0.pdf
    private static let diacriticsCombiningCodesExtended      = CharacterSet(charactersIn: UnicodeScalar(0x1ab0 as UInt16)!...UnicodeScalar(0x1aff as UInt16)!)
    // http://www.unicode.org/charts/PDF/U1DC0.pdf
    private static let diacriticsCombiningCodesSupplementary = CharacterSet(charactersIn: UnicodeScalar(0x1dc0 as UInt16)!...UnicodeScalar(0x1dff as UInt16)!)
    // http://www.unicode.org/charts/PDF/U20D0.pdf
    private static let diacriticsCombiningCodesForSymbols    = CharacterSet(charactersIn: UnicodeScalar(0x20d0 as UInt16)!...UnicodeScalar(0x20ff as UInt16)!)
    // http://www.unicode.org/charts/PDF/UFE20.pdf
    private static let diacriticsCombiningCodesHalfMarks     = CharacterSet(charactersIn: UnicodeScalar(0xfe20 as UInt16)!...UnicodeScalar(0xfe2f as UInt16)!)

    static var diacriticsCombining: CharacterSet = {
        return  [diacriticsCombiningCodes,
                 diacriticsCombiningCodesExtended,
                 diacriticsCombiningCodesSupplementary,
                 diacriticsCombiningCodesForSymbols,
                 diacriticsCombiningCodesHalfMarks].reduce(CharacterSet()) { (current: CharacterSet, new: CharacterSet) -> CharacterSet in
            return current.union(new)
        }
    }()
}

public extension UnicodeScalar {
    var isDiacritics: Bool {
        return CharacterSet.diacriticsCombining.contains(self)
    }
}

private let extremeDiacriticsViewWindowSize: Int = 10
private let extremeDiacriticsViewMinWindowSize: Int = 3
private let diacriticsPerCharMaxRatio: Float = 0.5


public extension String {
    
    // Sanitizes the string from excessive use of diacritic combining characters.
    // @warning the return value would still contain some amount of diacritic combining characters. The algorithm
    // implemented in the way that the text with valid diacritics should not be sanitized.
    var removingExtremeCombiningCharacters: String {
        
        if self.unicodeScalars.count < extremeDiacriticsViewWindowSize {
            return self
        }
        
        let isDiacriticsMap = self.unicodeScalars.map {
            $0.isDiacritics
        }
        
        var newUnicodeScalars = "".unicodeScalars
        
        // With moving window from the end to the start
        var currentWindowPosition: Int = -1
        for scalar in unicodeScalars {
            currentWindowPosition = currentWindowPosition + 1
            
            let endOfRange = min(isDiacriticsMap.endIndex, currentWindowPosition + extremeDiacriticsViewWindowSize)
            let range = currentWindowPosition..<endOfRange
            
            // If the character coming into the window is not diacritic one the ratio is not affected
            // Or if the window is smaller than desired extremeDiacriticsViewMinWindowSize
            if !isDiacriticsMap[currentWindowPosition] ||
                (range.endIndex - range.startIndex) < extremeDiacriticsViewMinWindowSize {
                newUnicodeScalars.append(scalar)
                continue
            }
        
            let diacriticsCount = isDiacriticsMap[range].filter { $0 }.count
            let regularCharactersCount = extremeDiacriticsViewWindowSize - diacriticsCount
            
            // verify current diacritics to characters ratio
            // if ratio is not satisfying (higher than @c diacriticsPerCharMaxRatio) the character has to be removed
            if regularCharactersCount != 0 &&
                Float(diacriticsCount) / Float(regularCharactersCount) < diacriticsPerCharMaxRatio {
                newUnicodeScalars.append(scalar)
            }
        }
        
        return String(newUnicodeScalars)
    }
}

public extension NSString {
    @objc(stringByRemovingExtremeCombiningCharacters)
    var removingExtremeCombiningCharacters: NSString {
        let selfString = (self as String)
        let result = selfString.removingExtremeCombiningCharacters
        return result as NSString
    }
}
