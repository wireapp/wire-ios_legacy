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

/**
 * A pending legal hold client.
 */

public class MockPendingLegalHoldClient: NSManagedObject {

    /// The user that received a legal hold request.
    @NSManaged public var user: MockUser?

    /// The identifier of the future client.
    @NSManaged public var identifier: String?

    /// Prekeys registered for this client
    @NSManaged public var prekeys : Set<MockPreKey>

    /// Last prekeys registered for this client
    @NSManaged public var lastPrekey : MockPreKey

}

extension MockUser {

    /// Requests a legal hold for the user.
    public func requestLegalHold() -> Bool {
        guard let managedObjectContext = self.managedObjectContext else {
            return false
        }

        guard memberships?.any(\.team.hasLegalHoldService) == true else {
            return false
        }

        let pendingClient = NSEntityDescription.insertNewObject(forEntityName: "PendingLegalHoldClient", into: managedObjectContext) as! MockPendingLegalHoldClient

        pendingClient.user = self

        let identifier = NSString.createAlphanumerical() as String
        pendingClient.identifier = identifier

        // Generate the prekeys
        let encryptionContext = MockUserClient.encryptionContext(for: self, clientId: identifier)

        var generatedPrekeys : [[String: Any]]?
        var generatedLastPrekey : String?

        encryptionContext.perform { (session) in
            generatedPrekeys = try? session.generatePrekeys(NSMakeRange(0, 5))
            generatedLastPrekey = try? session.generateLastPrekey()
        }

        guard let prekeys = generatedPrekeys, !prekeys.isEmpty, let lastPrekey = generatedLastPrekey else {
            return false
        }

        let mockPrekey = MockPreKey.insertNewKeys(withPayload: prekeys.map { $0["prekey"] as! String }, context: managedObjectContext)
        pendingClient.prekeys = Set(mockPrekey)

        let mockLastPrekey = NSEntityDescription.insertNewObject(forEntityName: "PreKey", into: managedObjectContext) as! MockPreKey
        mockLastPrekey.identifier = Int(CBOX_LAST_PREKEY_ID)
        mockLastPrekey.value = lastPrekey

        pendingClient.lastPrekey = mockLastPrekey
        return true
    }

    /// Accepts the legal hold for the user.
    public func acceptLegalHold(with pendingClient: MockPendingLegalHoldClient) -> Bool {
        guard pendingClient == pendingLegalHoldClient else {
            return false
        }

        guard let managedObjectContext = managedObjectContext else {
            return false
        }

        let newClient = NSEntityDescription.insertNewObject(forEntityName: "UserClient", into: managedObjectContext) as! MockUserClient

        newClient.user = self
        newClient.identifier = pendingClient.identifier
        newClient.label = "legalhold"
        newClient.type = "legalhold"
        newClient.deviceClass = "legalhold"
        newClient.time = Date()

        newClient.prekeys = pendingClient.prekeys
        newClient.lastPrekey = pendingClient.lastPrekey

        managedObjectContext.delete(pendingClient)
        return true
    }

}
