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
import WireDataModel
import LocalAuthentication

public protocol SharingSessionEncryptionAtRestInterface {
    var encryptMessagesAtRest: Bool { get }
    var isDatabaseLocked: Bool { get }
    func unlockDatabase(with context: LAContext) throws
}

extension SharingSession: SharingSessionEncryptionAtRestInterface {

    public var encryptMessagesAtRest: Bool {
        return userInterfaceContext.encryptMessagesAtRest
    }

    public var isDatabaseLocked: Bool {
        userInterfaceContext.encryptMessagesAtRest && userInterfaceContext.encryptionKeys == nil
    }

    public func unlockDatabase(with context: LAContext) throws {
        let userIdentifier = ZMUser.selfUser(in: userInterfaceContext).remoteIdentifier!
        let account = Account(userName: "", userIdentifier: userIdentifier)
        let keys = try EncryptionKeys.init(account: account, context: context)

        coreDataStack.storeEncryptionKeysInAllContexts(encryptionKeys: keys)
    }

}
