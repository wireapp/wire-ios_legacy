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

    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var otherUserConversation: ZMConversation!
    let usernames = ["Anna", "Claire", "Dean", "Erik", "Frank", "Gregor", "Hanna", "Inge", "James", "Laura", "Klaus"]

    override open func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        setupTestObjects()
    }

    override open func tearDown() {
        selfUser = nil
        otherUser = nil
        otherUserConversation = nil
        super.tearDown()
    }

    // MARK: – Setup

    private func setupTestObjects() {
        selfUser = ZMUser.insertNewObject(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.name = "selfUser"
        ZMUser.boxSelfUser(selfUser, inContextUserInfo: uiMOC)

        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"
        otherUser.setHandle("bruno")
        otherUser.accentColorValue = .brightOrange

        otherUserConversation = ZMConversation.insertNewObject(in: uiMOC)
        otherUserConversation.conversationType = .oneOnOne
        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = otherUser
        connection.status = .accepted
        connection.conversation = otherUserConversation

        uiMOC.saveOrRollback()
    }

    func createGroupConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.internalAddParticipants([selfUser, otherUser], isAuthoritative: true)
        return conversation
    }
    
    func createUser(name: String) -> ZMUser {
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = name
        user.remoteIdentifier = UUID()
        return user
    }

}
