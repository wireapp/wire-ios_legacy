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
import libPhoneNumberiOS
import WireUtilities
import WireDataModel

struct PhoneNumber: Equatable {
    enum ValidationResult {
        case valid
        case tooLong
        case tooShort
        case containsInvalidCharacters
        case invalid

        init(error: Error) {
            let code = (error as NSError).code
            guard let errorCode = ZMManagedObjectValidationErrorCode(rawValue: code) else {
                self = .invalid
                return
            }

            switch errorCode {
            case .tooLong:
                self = .tooLong
            case .tooShort:
                self = .tooShort
            case .phoneNumberContainsInvalidCharacters:
                self = .containsInvalidCharacters
            default:
                self = .invalid
            }
        }
    }

    let countryCode: UInt
    var fullNumber: String
    let numberWithoutCode: String

    var country: Country {
        return Country.detect(fromCode: countryCode) ?? .defaultCountry
    }

    init(countryCode: UInt, numberWithoutCode: String) {
        self.countryCode = countryCode
        self.numberWithoutCode = numberWithoutCode
        fullNumber = String.phoneNumber(withE164: countryCode, number: numberWithoutCode)
    }

    init?(fullNumber: String) {
        guard let country = Country.detect(forPhoneNumber: fullNumber) else { return nil }
        countryCode = country.e164
        let prefix = country.e164PrefixString
        numberWithoutCode = String(fullNumber[prefix.endIndex...])
        self.fullNumber = fullNumber

    }

    mutating func validate() -> ValidationResult {

        var validatedNumber: String? = fullNumber

        do {
            _ = try ZMUser.validate(phoneNumber: &validatedNumber)
        } catch let error {
            return ValidationResult(error: error)
        }

        fullNumber = validatedNumber ?? fullNumber

        return .valid
    }

    static func == (lhs: PhoneNumber, rhs: PhoneNumber) -> Bool {
        if lhs.fullNumber == rhs.fullNumber { return true }

        let phoneUtil = NBPhoneNumberUtil()
        do {
            let phoneNumberLhs: NBPhoneNumber = try phoneUtil.parse(lhs.fullNumber, defaultRegion: "DE")

            let phoneNumberRhs: NBPhoneNumber = try phoneUtil.parse(rhs.fullNumber, defaultRegion: "DE")

            return phoneNumberLhs == phoneNumberRhs
        } catch {
            return false
        }
    }
}
