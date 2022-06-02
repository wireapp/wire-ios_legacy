//
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

extension AppLockController {

    struct PasscodeKeychainItem: KeychainItem {

        // MARK: - Properties

        private let itemIdentifier: String

        // MARK: - Life cycle

        init(userId: UUID) {
            self.init(itemIdentifier: "\(Self.legacyIdentifier)-\(userId.uuidString)")
        }

        private init(itemIdentifier: String) {
            self.itemIdentifier = itemIdentifier
        }

        // MARK: - Methods

        var queryForGettingValue: [CFString: Any] {
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: itemIdentifier,
                kSecReturnData: true
            ]
        }

        func queryForSetting(value: Data) -> [CFString: Any] {
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: itemIdentifier,
                kSecValueData: value
            ]
        }

    }

}

// MARK: - Legacy

extension AppLockController.PasscodeKeychainItem {

    static let legacyItem = Self(itemIdentifier: legacyIdentifier)
    static let legacyIdentifier = "com.wire.passcode"

}
