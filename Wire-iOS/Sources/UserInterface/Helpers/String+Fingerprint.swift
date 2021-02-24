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

import UIKit

extension String {
    
    func split(every: Int) -> [String] {
        return stride(from: 0, to: count, by: every).map { i in
            let start = index(startIndex, offsetBy: i)
            let end = index(start, offsetBy: every, limitedBy: endIndex) ?? endIndex
            
            return String(self[start..<end])
        }
    }
    
    var fingerprintStringWithSpaces: String {
        return split(every: 2).joined(separator: " ")
    }
    
    func fingerprintString(attributes: [NSAttributedString.Key: Any],
                           boldAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        var bold = true
        return split{ !$0.isHexDigit }.map {
            let attributedElement = String($0) && (bold ? boldAttributes : attributes)
            
            bold = !bold
            
            return attributedElement
        }.joined(separator: NSAttributedString(string: " "))
    }
}
