
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

import Foundation

enum PasscodeError: CaseIterable {
    case tooShort
    case noLowercaseChar
    case noUppercaseChar
    case noNumber
    case noSpecialChar
    
    var message: String {
        let key: String
        switch self {
            
        case .tooShort:
            key = "create_passcode.validation.too_short"
        case .noLowercaseChar:
            key = "create_passcode.validation.no_lowercase_char"
        case .noUppercaseChar:
            key = "create_passcode.validation.no_uppercase_char"
        case .noSpecialChar:
            key = "create_passcode.validation.no_special_char"
        case .noNumber:
            key = "create_passcode.validation.no_number"
        }
        
        return key.localized
    }
    
    var descriptionWithInvalidIcon: NSAttributedString {
        
        //TODO paint code icon
        let attributedString = NSAttributedString(string: "❌" + message)
        
        return attributedString
    }
    
    //TODO paint code icon
    var descriptionWithPassedIcon: NSAttributedString {
        
        let attributedString: NSAttributedString = NSAttributedString(string: "✅" + message)
        
        return attributedString
    }
}
