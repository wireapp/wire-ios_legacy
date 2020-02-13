// 
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension String {
    func split(every: Int) -> [String] {
        var result = [String]()
        
        for i in stride(from: 0, to: count, by: every) {
            let start = index(startIndex, offsetBy: i)
            let end = index(start, offsetBy: every, limitedBy: endIndex) ?? endIndex
            result.append(String(self[start..<end]))
        }
        
        return result
    }

    var fingerprintStringWithSpaces: String {
        return split(every:2).joined(separator: " ")
    }
    
    func fingerprintString(attributes: [NSAttributedString.Key : Any], boldAttributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
        let mutableFingerprintString = NSMutableAttributedString(string: self as String)
        var bold = true
        
        (self as NSString).enumerateSubstrings(in: NSRange(location: 0, length: count), options: .byWords, using: { substring, substringRange, enclosingRange, stop in
            mutableFingerprintString.addAttributes(bold ? boldAttributes : attributes, range: substringRange)
            bold = !bold
        })
        
        return NSAttributedString(attributedString: mutableFingerprintString)
    }
}
