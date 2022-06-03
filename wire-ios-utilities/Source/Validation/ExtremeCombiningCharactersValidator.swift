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
import WireSystem

public enum ExtremeCombiningCharactersValidationError: Error {
    case containsExtremeCombiningCharacters
    case notAString
}

@objc public class ExtremeCombiningCharactersValidator: NSObject, ZMPropertyValidator {
    
    @objc(validateValue:error:)
    public static func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {
        guard let pointee = ioValue.pointee else {
            return
        }
        
        var anyPointee: Any? = pointee as Any?
        defer { ioValue.pointee = anyPointee as AnyObject? }
        try validateCharactersValue(&anyPointee)
    }
    
    @discardableResult public static func validateCharactersValue(_ ioValue: inout Any?) throws -> Bool {
        
        guard let string = ioValue as? String else {
            throw ExtremeCombiningCharactersValidationError.notAString
        }
        
        let stringByRemovingExtremeCombiningCharacters = string.removingExtremeCombiningCharacters
        
        if string.unicodeScalars.count != stringByRemovingExtremeCombiningCharacters.unicodeScalars.count {
            ioValue = stringByRemovingExtremeCombiningCharacters as AnyObject?
            throw ExtremeCombiningCharactersValidationError.containsExtremeCombiningCharacters
        }
        return true
    }
}
