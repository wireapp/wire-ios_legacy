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

public extension String {
    static private let transforms = [kCFStringTransformToLatin, kCFStringTransformStripCombiningMarks, kCFStringTransformToUnicodeName]
    
    /// Convert to a POSIX "Fully portable filenames" (only allow A–Z a–z 0–9 . _ -)
    /// Space will be converted to underscore first.
    var normalizedFilename: String {
        let ref = NSMutableString(string: self) as CFMutableString
        type(of: self).transforms.forEach { CFStringTransform(ref, nil, $0, false) }
        
        let retString = (ref as String).replacingOccurrences(of: " ", with: "-")
        
        let characterSet = NSMutableCharacterSet() //create an empty mutable set
        characterSet.formUnion(with: CharacterSet.alphanumerics)
        characterSet.addCharacters(in: "_-.")
        
        let unsafeChars = characterSet.inverted
        let strippedString = retString.components(separatedBy: unsafeChars).joined(separator: "")
        
        return strippedString
    }
    
    
    /// return a filename with length <= 255 characters with additional number of characters to reserve
    ///
    /// - Parameter numReservedChar: number for characters to reserve. It should < 255 and >= 0.
    /// - Returns: trimmed filename with length <= (255 - 5 - 37 - numReservedChar)
    func trimmedFilename(numReservedChar: Int) -> String {
        // reserve 5 characters for dash and file extension, 37 char for UUID prefix
        let offset = -(normalizedFilename.count - 255 + numReservedChar + 4 + 37)
        
        if offset > 0 {
            return String(self)
        }
        
        let start = normalizedFilename.startIndex
        
        let end = normalizedFilename.index(normalizedFilename.endIndex, offsetBy: offset)
        let result = normalizedFilename[start..<end]
        return String(result)
    }
}
