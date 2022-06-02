//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

extension ZMContextChangeTrackerSource {
    func notifyChangeTrackers(_ client: UserClient) {
        let clientSet: Set<NSManagedObject> = [client]
        contextChangeTrackers.forEach {
            $0.objectsDidChange(clientSet)}
    }
}

class RequestStrategyTestBase: MessagingTest {

    func createRemoteClient() -> UserClient {

        var mockUserIdentifier: String!
        var mockClientIdentifier: String!

        self.mockTransportSession.performRemoteChanges { (session) -> Void in
            let mockUser = session.insertUser(withName: "foo")
            let mockClient = session.registerClient(for: mockUser, label: mockUser.name!, type: "permanent", deviceClass: "phone")
            mockClientIdentifier = mockClient.identifier
            mockUserIdentifier = mockUser.identifier
        }

        let client = UserClient.insertNewObject(in: self.syncMOC)
        client.remoteIdentifier = mockClientIdentifier
        let user = ZMUser.insertNewObject(in: self.syncMOC)
        user.remoteIdentifier = UUID(uuidString: mockUserIdentifier)
        client.user = user

        return client
    }
}
