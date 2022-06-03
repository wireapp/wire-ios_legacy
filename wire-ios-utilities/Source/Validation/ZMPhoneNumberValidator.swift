//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@objc public class ZMPhoneNumberValidator: NSObject, ZMPropertyValidator {

    @objc(validateValue:error:)
    public static func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {
        var pointee = ioValue.pointee as Any?
        defer { ioValue.pointee = pointee as AnyObject? }
        try validateValue(&pointee)
    }
    
    @discardableResult public static func validateValue(_ ioValue: inout Any?) throws -> Bool {
        
        guard let phoneNumber = ioValue as? NSString,
            phoneNumber.length >= 1 else {
                return true
        }
        
        var validSet = CharacterSet.decimalDigits
        validSet.insert(charactersIn: "+-. ()")
        let invalidSet = validSet.inverted
        
        if phoneNumber.rangeOfCharacter(from: invalidSet, options: .literal).location != NSNotFound {
            let description = "The phone number is invalid."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: ZMObjectValidationErrorDomain,
                                code: ZMManagedObjectValidationErrorCode.phoneNumberContainsInvalidCharacters.rawValue,
                                userInfo: userInfo)
            throw error
        }
        
        var finalPhoneNumber: Any? = "+".appending((phoneNumber as NSString).stringByRemovingCharacters("+-. ()") as String)
            
        
        
        do {
            _ = try StringLengthValidator.validateStringValue(&finalPhoneNumber,
                                                minimumStringLength: 9,
                                                maximumStringLength: 24,
                                                maximumByteLength: 24)
        } catch let error {
            throw error
        }
        
        if finalPhoneNumber as! NSString != phoneNumber {
            ioValue = finalPhoneNumber
        }

        return true
    }
    
    @objc(isValidPhoneNumber:)
    public static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        var phoneNumber: Any? = phoneNumber
        do {
            return try validateValue(&phoneNumber)
        } catch {
            return false
        }
    }
    
    @objc(validatePhoneNumber:)
    public static func validate(phoneNumber: String) -> String? {
        var phoneNumber: Any? = phoneNumber
        _ = try? validateValue(&phoneNumber)
        return phoneNumber as? String
    }
    
}

extension NSString {
    
    func stringByRemovingCharacters(_ characters:NSString) -> NSString {
        var finalString = self
        for i in 0..<characters.length {
            let toRemove = characters.substring(with: NSMakeRange(i, 1))
            finalString = finalString.replacingOccurrences(of: toRemove,
                                             with: "",
                                             options: [],
                                             range: NSMakeRange(0, finalString.length)) as NSString
        }
        return finalString
    }
}
