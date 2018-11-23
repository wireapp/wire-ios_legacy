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

extension NSString {

    /// Auto detect country for phone numbers beginning with "+"
    ///
    /// When pastedString is copied from phone app (self phone number section), it contains right/left handling symbols: \u202A\u202B\u202C\u202D
    /// @"\U0000202d+380 (00) 123 45 67\U0000202c"
    ///
    /// - Parameter completion: completion closure with Country object and phoneNumber extracted from self
    /// - Returns: true if should paste as Phone number(not beginning with "+"). If self is prased as a phone number, reture false (it should the be pasted, the caller use the completion's data for further actions.)
    @discardableResult
    @objc func shouldPasteAsPhoneNumber(presetCountry: Country,
                                        completion: (_ country: Country?, _ phoneNumber: String?) -> Void)
        -> Bool {

        var illegalCharacters = CharacterSet.whitespacesAndNewlines
        illegalCharacters.formUnion(CharacterSet.decimalDigits)
        illegalCharacters.formUnion(CharacterSet(charactersIn: "+-()"))
        illegalCharacters.invert()
        var phoneNumber: NSString = trimmingCharacters(in: illegalCharacters) as NSString

        if phoneNumber.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).hasPrefix("+") {
            if let country = Country.detect(forPhoneNumber: phoneNumber as String) {
                let phoneNumberWithoutCountryCode = phoneNumber.replacingOccurrences(of: country.e164PrefixString, with: "")
                completion(country, phoneNumberWithoutCountryCode)

                return false
            }
        }

        // Just paste (if valid) for phone numbers not beginning with "+", or phones where country is not detected.

        phoneNumber = NSString.phoneNumber(withE164: presetCountry.e164, number: phoneNumber as String) as NSString

        let result = UnregisteredUser.normalizedPhoneNumber(phoneNumber as String)

        if result.isValid {
            return true
        } else {
            return false
        }
    }
}
