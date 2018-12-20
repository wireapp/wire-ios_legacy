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

import WireTesting
import XCTest


/// This class provides a `NSManagedObjectContext` in order to test views with real data instead
/// of mock objects.
open class CoreDataSnapshotTestCase: ZMSnapshotTestCase {

    var selfUserInTeam: Bool = false
    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var otherUserConversation: ZMConversation!
    var team: Team?
    var teamMember: Member?
    let usernames = ["Anna", "Claire", "Dean", "Erik", "Frank", "Gregor", "Hanna", "Inge", "James", "Laura", "Klaus", "Lena", "Linea", "Lara", "Elliot", "Francois", "Felix", "Brian", "Brett", "Hannah", "Ana", "Paula"]

    override open func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        setupTestObjects()

        MockUser.setMockSelf(selfUser)

    }

    override open func tearDown() {
        selfUser = nil
        otherUser = nil
        otherUserConversation = nil
        teamMember = nil
        team = nil

        MockUser.setMockSelf(nil)

        super.tearDown()
    }

    // MARK: – Setup

    private func setupTestObjects() {
        selfUser = ZMUser.insertNewObject(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.name = "selfUser"
        selfUser.accentColorValue = .vividRed

        ZMUser.boxSelfUser(selfUser, inContextUserInfo: uiMOC)
        if selfUserInTeam {
            let selfUser = ZMUser.selfUser(in: self.uiMOC)
            let team = Team.insertNewObject(in: uiMOC)
            team.remoteIdentifier = UUID()
            let member = Member.insertNewObject(in: uiMOC)
            member.user = selfUser
            member.team = team
        }

        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"
        otherUser.setHandle("bruno")
        otherUser.accentColorValue = .brightOrange

        otherUserConversation = ZMConversation.insertNewObject(in: uiMOC)
        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.remoteIdentifier = UUID.create()
        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = otherUser
        connection.status = .accepted
        connection.conversation = otherUserConversation

        uiMOC.saveOrRollback()
    }

    private func updateTeamStatus(wasInTeam: Bool) {
        guard wasInTeam != selfUserInTeam else {
            return
        }

        if selfUserInTeam {
            let selfUser = ZMUser.selfUser(in: self.uiMOC)
            let team = Team.insertNewObject(in: uiMOC)
            team.remoteIdentifier = UUID()
            let member = Member.insertNewObject(in: uiMOC)
            member.user = selfUser
            member.team = team
        } else {
            teamMember = nil
            team = nil
        }
    }

    func createGroupConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.conversationType = .group
        conversation.internalAddParticipants([selfUser, otherUser])
        return conversation
    }
    
    func createTeamGroupConversation() -> ZMConversation {
        let conversation = createGroupConversation()
        conversation.teamRemoteIdentifier = UUID.create()
        conversation.userDefinedName = "Group conversation"
        return conversation
    }
    
    func createUser(name: String) -> ZMUser {
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = name
        user.remoteIdentifier = UUID()
        return user
    }
    
    func createService(name: String) -> ZMUser {
        let user = createUser(name: name)
        user.serviceIdentifier = UUID.create().transportString()
        user.providerIdentifier = UUID.create().transportString()
        return user
    }

    func nonTeamTest(_ block: () -> Void) {
        let wasInTeam = selfUserInTeam
        selfUserInTeam = false
        updateTeamStatus(wasInTeam: wasInTeam)
        block()
    }

    func teamTest(_ block: () -> Void) {
        let wasInTeam = selfUserInTeam
        selfUserInTeam = true
        updateTeamStatus(wasInTeam: wasInTeam)
        block()
    }

}
