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


/// This class provides a `NSManagedObjectContext` in order to test views with real data instead
/// of mock objects.
open class CoreDataSnapshotTestCase: ZMSnapshotTestCase {

    var testSession: ZMTestSession!
    var moc: NSManagedObjectContext!
    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var otherUserConversation: ZMConversation!
    let usernames = ["Anna", "Claire", "Dean", "Erik", "Frank", "Gregor", "Hanna", "Inge", "James", "Laura", "Klaus"]

    override open func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        testSession = ZMTestSession(dispatchGroup: ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: name))
        testSession.prepare(forTestNamed: name)
        moc = testSession.uiMOC
        setupTestObjects()
    }

    override open func tearDown() {
        super.tearDown()
        testSession.tearDown()
    }

    // MARK: – Setup

    private func setupTestObjects() {
        selfUser = ZMUser.insertNewObject(in: moc)
        selfUser.remoteIdentifier = UUID()
        selfUser.name = "selfUser"
        ZMUser.boxSelfUser(selfUser, inContextUserInfo: moc)

        otherUser = ZMUser.insertNewObject(in: moc)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"
        otherUser.accentColorValue = .brightOrange

        otherUserConversation = ZMConversation.insertNewObject(in: moc)

        let connection = ZMConnection.insertNewObject(in: moc)
        connection.to = otherUser
        connection.status = .accepted
        connection.conversation = otherUserConversation

        moc.saveOrRollback()
    }

    func createUser(name: String) -> ZMUser {
        let user = ZMUser.insertNewObject(in: moc)
        user.name = name
        user.remoteIdentifier = UUID()
        return user
    }

}
