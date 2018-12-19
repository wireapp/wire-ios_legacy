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

extension String {
    fileprivate var withoutSpace: String {
        return components(separatedBy: .whitespaces).joined()
    }


    /// Auto detect country for phone numbers beginning with "+"
    ///
    /// Notice: When pastedString is copied from phone app (self phone number section), it contains right/left handling symbols: \u202A\u202B\u202C\u202D or \u{e2}
    /// e.g. @"\U0000202d+380 (00) 123 45 67\U0000202c"
    /// or  \u{e2}+49 123 12349999\u{e2}
    ///
    /// - Parameter presetCountry: the country preset if the phone number has no country code
    /// - Returns: If the number can be parsed, return a tuple of country and the phone number without country code. Otherwise return nil. country would be nil if self is a phone number without country
    @discardableResult
    func shouldInsertAsPhoneNumber(presetCountry: Country) -> (country: Country?, phoneNumber: String)? {

        var illegalCharacters = CharacterSet.whitespaces
        illegalCharacters.formUnion(CharacterSet.decimalDigits)
        illegalCharacters.formUnion(CharacterSet(charactersIn: "+-()"))
        illegalCharacters.invert()
        let phoneNumber = trimmingCharacters(in: illegalCharacters)

        if phoneNumber.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).hasPrefix("+") {
            if let country = Country.detect(forPhoneNumber: phoneNumber) {
                /// remove the leading space and country prefix
                var phoneNumberWithoutCountryCode = phoneNumber.replacingOccurrences(of: country.e164PrefixString, with: "").withoutSpace

                /// remove symbols -()

                phoneNumberWithoutCountryCode = String(phoneNumberWithoutCountryCode.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) })

                return (country: country, phoneNumber: phoneNumberWithoutCountryCode)
            }
        }

        // Just paste (if valid) for phone numbers not beginning with "+", or phones where country is not detected.

        let phoneNumberWithCountryCode = NSString.phoneNumber(withE164: presetCountry.e164, number: phoneNumber)

        let result = UnregisteredUser.normalizedPhoneNumber(phoneNumberWithCountryCode)

        if result.isValid {
            return (country: presetCountry, phoneNumber: phoneNumber.withoutSpace)
        } else {
            return nil
        }
    }
}
