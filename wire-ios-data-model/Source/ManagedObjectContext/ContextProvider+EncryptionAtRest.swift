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

public extension ContextProvider {

    /// Retrieve or create the encryption keys necessary for enabling / disabling encryption at rest.
    ///
    /// This method should only be called on the main thread.

    func encryptionKeysForSettingEncryptionAtRest(enabled: Bool) throws -> EncryptionKeys {
        var encryptionKeys: EncryptionKeys

        if enabled {
            try EncryptionKeys.deleteKeys(for: account)
            encryptionKeys = try EncryptionKeys.createKeys(for: account)
            storeEncryptionKeysInAllContexts(encryptionKeys: encryptionKeys)
        } else {
            encryptionKeys = try viewContext.getEncryptionKeys()
            clearEncryptionKeysInAllContexts()
        }

        return encryptionKeys
    }

    /// Synchronously stores the given encryption keys in each managed object context.

    func storeEncryptionKeysInAllContexts(encryptionKeys: EncryptionKeys) {
        for context in [viewContext, syncContext, searchContext] {
            context.performAndWait { context.encryptionKeys = encryptionKeys }
        }
    }

    /// Synchronously clears the encryption keys in each managed object context.

    func clearEncryptionKeysInAllContexts() {
        for context in [viewContext, syncContext, searchContext] {
            context.performAndWait { context.encryptionKeys = nil }
        }
    }

}
