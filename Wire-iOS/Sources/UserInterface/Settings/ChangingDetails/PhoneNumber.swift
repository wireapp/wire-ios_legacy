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

struct PhoneNumber: Equatable {
    enum ValidationResult {
        case valid
        case tooLong
        case tooShort
        case containsInvalidCharacters
        case invalid

        init(error: Error) {
            let code = (error as NSError).code
            guard let errorCode = ZMManagedObjectValidationErrorCode(rawValue: UInt(code)) else {
                self = .invalid
                return
            }

            switch errorCode {
            case .objectValidationErrorCodeStringTooLong:
                self = .tooLong
            case .objectValidationErrorCodeStringTooShort:
                self = .tooShort
            case .objectValidationErrorCodePhoneNumberContainsInvalidCharacters:
                self = .containsInvalidCharacters
            default:
                self = .invalid
            }
        }
    }

    let countryCode: UInt
    let fullNumber: String
    let numberWithoutCode: String

    init(countryCode: UInt, numberWithoutCode: String) {
        self.countryCode = countryCode
        self.numberWithoutCode = numberWithoutCode
        fullNumber = NSString.phoneNumber(withE164: countryCode as NSNumber , number: numberWithoutCode)
    }

    init?(fullNumber: String) {
        guard let country = Country.detect(forPhoneNumber: fullNumber) else { return nil }
        countryCode = country.e164.uintValue
        let prefix = country.e164PrefixString
        numberWithoutCode = String(fullNumber[prefix.endIndex...])
        self.fullNumber = fullNumber

    }

    func validate() -> ValidationResult {
        var validatedNumber = fullNumber as NSString?
        let pointer = AutoreleasingUnsafeMutablePointer<NSString?>(&validatedNumber)
        do {
            try ZMUser.validatePhoneNumber(pointer)
        } catch let error {
            return ValidationResult(error: error)
        }

        return .valid
    }
}
