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

import Foundation

struct TransferApplockKeychain {
    
    static func migrateKeychainItems(in moc: NSManagedObjectContext) {
        migrateIsAppLockActiveState(in: moc)
        migrateAppLockPasscode(in: moc)
    }
    
    /// Save the enable state of the applock feature in the managedObjectContext instead of the keychain.

    static func migrateIsAppLockActiveState(in moc: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: moc)
        
        guard
            let data = ZMKeychain.data(forAccount: "lockApp"),
            data.count != 0
        else {
            selfUser.isAppLockActive = false
            return
        }
        
        selfUser.isAppLockActive = String(data: data, encoding: .utf8) == "YES"
    }

    /// Migrate the single legacy passcode (account agnostic) to potentially several (account specific)
    /// keychain entries.

    static func migrateAppLockPasscode(in moc: NSManagedObjectContext) {
        guard let selfUserId = ZMUser.selfUser(in: moc).remoteIdentifier else { return }

        let legacyKeychainItem = AppLockController.PasscodeKeychainItem.legacyItem

        guard
            let passcode = try? Keychain.fetchItem(legacyKeychainItem),
            !passcode.isEmpty
        else {
            return
        }

        let item = AppLockController.PasscodeKeychainItem(userId: selfUserId)
        try? Keychain.storeItem(item, value: passcode)
    }

}

private extension Bundle {

    var sharedContainerURL: URL? {
        return appGroupIdentifier.map(FileManager.sharedContainerDirectory)
    }

    var appGroupIdentifier: String? {
        return bundleIdentifier.map { "group." + $0 }
    }

}
