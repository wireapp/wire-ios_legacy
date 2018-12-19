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

extension RegistrationTextField {
    override open func paste(_ sender: Any?) {

        var shouldPaste = true

        if let registrationTextFieldDelegate = delegate as? RegistrationTextFieldDelegate,
           let pasteboard = UIPasteboard(name: .general, create: false),
           let pastedString = pasteboard.string {

            shouldPaste = registrationTextFieldDelegate.textField(self, shouldPasteCharactersIn: selectedRange(), replacementString: pastedString)
        }

        if shouldPaste {
            super.paste(sender)
        }
    }

    /// Insert a phone number to a RegistrationTextField or return true if it is not a valide number to insert.
    ///
    /// - Parameters:
    ///   - phoneNumber: the phone number to insert
    /// - Returns: If the number can be parsed, return a tuple of country and the phone number without country code. Otherwise return nil. country would be nil if self is a phone number without country
    func insert(phoneNumber: String) -> (country: Country?, phoneNumber: String)? {
        let presetCountry = Country(iso: "", e164: NSNumber(value: countryCode))

        guard let (country, phoneNumberWithoutCountryCode) = phoneNumber.shouldInsertAsPhoneNumber(presetCountry: presetCountry) else { return nil }

        text = phoneNumberWithoutCountryCode
        if let country = country {
            countryCode = country.e164.uintValue
        }

        return (country, phoneNumberWithoutCountryCode)
    }
}
