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
import LocalAuthentication
import WireDataModel

public protocol UserSessionEncryptionAtRestInterface {
    var encryptMessagesAtRest: Bool { get }
    var isDatabaseLocked: Bool { get }

    func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws
    func unlockDatabase(with context: LAContext) throws
    func registerDatabaseLockedHandler(_ handler: @escaping (_ isDatabaseLocked: Bool) -> Void) -> Any
}

protocol UserSessionEncryptionAtRestDelegate: AnyObject {

    func setEncryptionAtRest(enabled: Bool, account: Account, encryptionKeys: EncryptionKeys)

}

extension ZMUserSession: UserSessionEncryptionAtRestInterface {

    /// Enable or disable encryption at rest.
    ///
    /// When toggling encryption at rest the existing database needs to be migrated. The migration happens
    /// asynchronously on the sync context and only after a successful migration is the feature toggled. In
    /// the case that the migration fails, the sync context is reset to a clean state.
    ///
    /// - Parameters:
    ///     - enabled: When **true**, messages will be encrypted at rest.
    ///     - skipMigration: When **true**, existing messsages will not be migrated to be under encryption at rest. Defaults to **false**.
    ///
    /// - Throws: `MigrationError` if it's not possible to start the migration.

    public func setEncryptionAtRest(enabled: Bool, skipMigration: Bool = false) throws {
        guard enabled != encryptMessagesAtRest else { return }

        let encryptionKeys = try coreDataStack.encryptionKeysForSettingEncryptionAtRest(enabled: enabled)

        if skipMigration {
            try managedObjectContext.enableEncryptionAtRest(encryptionKeys: encryptionKeys, skipMigration: true)
        } else {
            delegate?.setEncryptionAtRest(enabled: enabled,
                                          account: coreDataStack.account,
                                          encryptionKeys: encryptionKeys)
        }
    }

    public var encryptMessagesAtRest: Bool {
        return managedObjectContext.encryptMessagesAtRest
    }

    public var isDatabaseLocked: Bool {
        managedObjectContext.encryptMessagesAtRest && managedObjectContext.encryptionKeys == nil
    }

    public func registerDatabaseLockedHandler(_ handler: @escaping (_ isDatabaseLocked: Bool) -> Void) -> Any {
        return NotificationInContext.addObserver(name: DatabaseEncryptionLockNotification.notificationName,
                                                 context: managedObjectContext.notificationContext,
                                                 queue: .main) { note in
            guard let note = note.userInfo[DatabaseEncryptionLockNotification.userInfoKey] as? DatabaseEncryptionLockNotification else { return }

            handler(note.databaseIsEncrypted)
        }
    }

    func lockDatabase() {
        guard managedObjectContext.encryptMessagesAtRest else { return }

        BackgroundActivityFactory.shared.notifyWhenAllBackgroundActivitiesEnd { [weak self] in
            self?.coreDataStack.clearEncryptionKeysInAllContexts()

            if let notificationContext = self?.managedObjectContext.notificationContext {
                DatabaseEncryptionLockNotification(databaseIsEncrypted: true).post(in: notificationContext)
            }
        }
    }

    public func unlockDatabase(with context: LAContext) throws {
        let keys = try EncryptionKeys.init(account: coreDataStack.account, context: context)

        coreDataStack.storeEncryptionKeysInAllContexts(encryptionKeys: keys)

        DatabaseEncryptionLockNotification(databaseIsEncrypted: false).post(in: managedObjectContext.notificationContext)

        syncManagedObjectContext.performGroupedBlock {
            self.processEvents()
        }
    }

}
