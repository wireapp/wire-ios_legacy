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

extension PhoneNumberViewController {
    @objc
    @discardableResult
    func pastePhoneNumber(_ phoneNumber: NSString?) -> Bool {
        guard let phoneNumber = phoneNumber else { return false }

        return phoneNumber.shouldPasteAsPhoneNumber(presetCountry: self.country){country, phoneNumber in
            if let _ /*country*/ = country, let phoneNumber = phoneNumber {

                self.phoneNumberField.text = phoneNumber;
                ///TODO: update country name and county code after a phone number with prefix is pasted
                self.updateRightAccessory(forPhoneNumber: phoneNumber)
            }
        }
    }
}
