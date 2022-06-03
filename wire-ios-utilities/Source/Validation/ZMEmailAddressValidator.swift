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

@objc public class ZMEmailAddressValidator: NSObject, ZMPropertyValidator {
    
    static func normalizeEmailAddress(_ emailAddress: inout NSString?) -> Bool {
        var normalizedAddress = emailAddress?.lowercased as NSString?
        var charactersToTrim = CharacterSet.whitespaces
        charactersToTrim.formUnion(CharacterSet.controlCharacters)
        normalizedAddress?.trimmingCharacters(in: charactersToTrim)
        
        let bracketsScanner = Scanner(string: normalizedAddress as String? ?? "")
        bracketsScanner.charactersToBeSkipped = CharacterSet()
        bracketsScanner.locale = Locale(identifier: "en_US_POSIX")
        
        if bracketsScanner.scanUpTo("<", into: nil) && bracketsScanner.scanString("<", into: nil) {
            bracketsScanner.scanUpTo(">", into: &normalizedAddress)
            if !bracketsScanner.scanString(">", into: nil) {
                //if there is no > than it's not valid email, we do not need to change input value
                normalizedAddress = nil
            }
        }
        
        if let normalizedAddress = normalizedAddress, normalizedAddress != emailAddress {
            emailAddress = normalizedAddress
            return true
        }
        
        return false
    }

    @objc(validateValue:error:)
    public static func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {
        var pointee = ioValue.pointee as Any?
        defer { ioValue.pointee = pointee as AnyObject? }
        try validateValue(&pointee)
    }
    
    @discardableResult public static func validateValue(_ ioValue: inout Any?) throws -> Bool {
        
        if ioValue == nil {
            return true
        }
        
        let setInvalid = {
            let description = "The email address is invalid."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: ZMObjectValidationErrorDomain, code: ZMManagedObjectValidationErrorCode.emailAddressIsInvalid.rawValue, userInfo: userInfo)
            throw error
        }
        
        do {
            try StringLengthValidator.validateStringValue(&ioValue,
                                                    minimumStringLength: 0,
                                                    maximumStringLength: 120,
                                                    maximumByteLength: 120)
        } catch {
            try setInvalid()
            return false
        }
        
        
        var emailAddress = ioValue as? NSString
        _ = normalizeEmailAddress(&emailAddress)
        
        if emailAddress?.rangeOfCharacter(from: .whitespaces, options: .literal).location != NSNotFound ||
            emailAddress?.rangeOfCharacter(from: .controlCharacters, options: .literal).location != NSNotFound {
            try setInvalid()
            return false
        }
        
        let emailScanner = Scanner(string: emailAddress! as String)
        emailScanner.charactersToBeSkipped = CharacterSet()
        emailScanner.locale = Locale(identifier: "en_US_POSIX")
        
        var local: NSString?
        var domain: NSString?
        
        let validParts = emailScanner.scanUpTo("@", into: &local)
        && emailScanner.scanString("@", into: nil)
        && emailScanner.scanUpTo("@", into: &domain)
        && !emailScanner.scanString("@", into: nil)
        
        if !validParts {
            try setInvalid()
            return false
        }
        
        // domain part:
        do {
            let validSet = NSMutableCharacterSet.alphanumeric()
            validSet.addCharacters(in: "-")
            let invalidSet = validSet.inverted
            
            let components = domain?.components(separatedBy: ".")
            if components?.count < 2 || components?.last?.hasSuffix("-") == true {
                try setInvalid()
                return false
            }
            
            for case let c as NSString in components ?? [] {
                if c.length < 1 || c.rangeOfCharacter(from: invalidSet, options: .literal).location != NSNotFound {
                    try setInvalid()
                    return false
                }
            }
        }
        
        // local part:
        do {
            var validSet = CharacterSet.alphanumerics
            validSet.insert(charactersIn: "!#$%&'*+-/=?^_`{|}~")
            let invalidSet = validSet.inverted
            var validQuoted = validSet
            validQuoted.insert(charactersIn: "(),:;<>@[]")
            let invalidQuotedSet = validQuoted.inverted
            
            let components = local?.components(separatedBy: ".")
            if components?.count < 1 {
                try setInvalid()
                return false
            }
            
            for case let c as NSString in components ?? [] {
                if c.length < 1 || c.rangeOfCharacter(from: invalidSet, options: .literal).location != NSNotFound {
                    // Check if it's a quoted part:
                    if c.hasPrefix("\"") && c.hasSuffix("\"") {
                        // Allow this regardless of what
                        let quoted = c.substring(with: NSMakeRange(1, c.length - 2)) as NSString
                        if quoted.length < 1 || quoted.rangeOfCharacter(from: invalidQuotedSet, options: .literal).location != NSNotFound {
                            try setInvalid()
                            return false
                        }
                    } else {
                        try setInvalid()
                        return false
                    }
                
                }
            }
        }
        
        if emailAddress != ioValue as? NSString? {
            ioValue = emailAddress
        }
        
        return true
    }
    
    @objc(isValidEmailAddress:)
    public static func isValidEmailAddress(_ emailAddress: String) -> Bool {
        var emailAddress: Any? = emailAddress
        do {
            return try validateValue(&emailAddress)
        } catch {
            return false
        }
    }
    
}
