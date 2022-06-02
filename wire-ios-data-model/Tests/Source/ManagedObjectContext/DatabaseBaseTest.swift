//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireTesting
@testable import WireDataModel

@objcMembers public class DatabaseBaseTest: ZMTBaseTest {

    var accountID: UUID = UUID.create()

    public var applicationContainer: URL {
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("StorageStackTests")
    }

    override public func setUp() {
        super.setUp()
        self.clearStorageFolder()
        try! FileManager.default.createDirectory(at: self.applicationContainer, withIntermediateDirectories: true)
    }

    override public func tearDown() {
        self.clearStorageFolder()
        super.tearDown()
    }

    /// Create storage stack
    func createStorageStackAndWaitForCompletion(userID: UUID = UUID()) -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: userID)
        let stack = CoreDataStack(account: account,
                                  applicationContainer: applicationContainer,
                                  inMemoryStore: false,
                                  dispatchGroup: dispatchGroup)

        stack.loadStores { (error) in
            XCTAssertNil(error)
        }

        return stack
    }

    /// Create a session in the keystore directory for the given account
    public func createSessionInKeyStore(accountDirectory: URL, applicationContainer: URL, sessionId: EncryptionSessionIdentifier) {
        let preKey = "pQABAQICoQBYICHHDV4Zh6yJzJSPhQmtxah8N4kVE+XSCmTVfIsvgm5UA6EAoQBYIJeiWi5TfAWBrYSOtM5nKk5isfRYX5pFqRk13jVenPz6BPY="
        let keyStore = UserClientKeysStore(accountDirectory: accountDirectory, applicationContainer: applicationContainer)
        keyStore.encryptionContext.perform { sessionsDirectory in
            try! sessionsDirectory.createClientSession(sessionId, base64PreKeyString: preKey)
        }
    }

    /// Returns true if the given session exists in the keystore for the given account
    public func doesSessionExistInKeyStore(accountDirectory: URL, applicationContainer: URL, sessionId: EncryptionSessionIdentifier) -> Bool {

        var hasSession = false

        let keyStore = UserClientKeysStore(accountDirectory: accountDirectory, applicationContainer: applicationContainer)
        keyStore.encryptionContext.perform { sessionsDirectory in
            hasSession = sessionsDirectory.hasSession(for: sessionId)
        }

        return hasSession
    }

    /// Clears the current storage folder and the legacy locations
    public func clearStorageFolder() {
        let url = self.applicationContainer
        try? FileManager.default.removeItem(at: url)
    }

    /// Creates some dummy Core Data store support file
    func createDummyExternalSupportFileForDatabase(storeFile: URL) {
        let storeName = storeFile.deletingPathExtension().lastPathComponent
        let supportPath = storeFile.deletingLastPathComponent().appendingPathComponent(".\(storeName)_SUPPORT")
        try! FileManager.default.createDirectory(at: supportPath, withIntermediateDirectories: true)
        try! self.mediumJPEGData().write(to: supportPath.appendingPathComponent("image.dat"))
    }

}
