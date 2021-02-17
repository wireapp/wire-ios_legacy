//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
@testable import Wire

extension AppLockModule {

    final class MockSession: Session {

        var methodCalls = MethodCalls()

        struct MethodCalls {
            var setEncryptionAtRest: [(enabled: Bool, skipMigration: Bool)] = []
            var unlockDatabase: [LAContext] = []
            var registerDatabaseLockedHandler: [(Bool) -> Void] = []
        }

        // MARK: - Properties

        var appLockController: AppLockType = MockAppLockController()

        var lock: SessionLock? = .screen

        var encryptMessagesAtRest = false

        var isDatabaseLocked: Bool {
            return lock == .database
        }

        // MARK: - Methods

        func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws {
            methodCalls.setEncryptionAtRest.append((enabled, skipMigration))
        }

        func unlockDatabase(with context: LAContext) throws {
            methodCalls.unlockDatabase.append(context)
        }

        func registerDatabaseLockedHandler(_ handler: @escaping (Bool) -> Void) -> Any {
            methodCalls.registerDatabaseLockedHandler.append(handler)
        }

    }
    
}
