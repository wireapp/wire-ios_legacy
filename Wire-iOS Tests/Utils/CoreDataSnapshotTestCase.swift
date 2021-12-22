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

struct SelfProvider: SelfUserProvider {
    let selfUser: UserType & ZMEditableUser
}

/// This class provides a `NSManagedObjectContext` in order to test views with real data instead
/// of mock objects.
class CoreDataSnapshotTestCase: ZMSnapshotTestCase {

    var selfUserInTeam: Bool = false
    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var otherUserConversation: ZMConversation!
    var team: Team?
    var teamMember: Member?

    let usernames = MockUserType.usernames

    // The provider to use when configuring `SelfUser.provider`, needed only when tested code
    // invokes `SelfUser.current`. As we slowly migrate to `UserType`, we will use this more
    // and the `var selfUser: ZMUser!` less.
    //
    var selfUserProvider: SelfUserProvider!

    override open func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        setupTestObjects()

        MockUser.setMockSelf(selfUser)
        selfUserProvider = SelfProvider(selfUser: selfUser)
    }

    override open func tearDown() {
        selfUser = nil
        otherUser = nil
        otherUserConversation = nil
        teamMember = nil
        team = nil

        MockUser.setMockSelf(nil)
        selfUserProvider = nil

        super.tearDown()
    }

    // MARK: – Setup

    private func setupMember() {
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        team = Team.insertNewObject(in: uiMOC)
        team!.remoteIdentifier = UUID()

        teamMember = Member.insertNewObject(in: uiMOC)
        teamMember!.user = selfUser
        teamMember!.team = team
        teamMember!.setTeamRole(.member)
    }

    private func setupTestObjects() {
        selfUser = ZMUser.insertNewObject(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.name = "selfUser"
        selfUser.accentColorValue = .vividRed
        selfUser.emailAddress = "test@email.com"
        selfUser.phoneNumber = "+123456789"

        ZMUser.boxSelfUser(selfUser, inContextUserInfo: uiMOC)
        if selfUserInTeam {
            setupMember()
        }

        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"
        otherUser.handle = "bruno"
        otherUser.accentColorValue = .brightOrange

        otherUserConversation = ZMConversation.createOtherUserConversation(moc: uiMOC, otherUser: otherUser)

        uiMOC.saveOrRollback()
    }

    private func updateTeamStatus(wasInTeam: Bool) {
        guard wasInTeam != selfUserInTeam else {
            return
        }

        if selfUserInTeam {
            setupMember()
        } else {
            teamMember = nil
            team = nil
        }
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

    func markAllMessagesAsUnread(in conversation: ZMConversation) {
        conversation.lastReadServerTimeStamp = Date.distantPast
        conversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
    }

// MARK: - mock conversation

    func createGroupConversation() -> ZMConversation {
        return ZMConversation.createGroupConversation(moc: uiMOC, otherUser: otherUser, selfUser: selfUser)
    }

    func createTeamGroupConversation() -> ZMConversation {
        return ZMConversation.createTeamGroupConversation(moc: uiMOC, otherUser: otherUser, selfUser: selfUser)
    }

    func createGroupConversationOnlyAdmin() -> ZMConversation {
        return ZMConversation.createGroupConversationOnlyAdmin(moc: uiMOC, selfUser: selfUser)
    }

// MARK: - mock service user

    func createServiceUser() -> ZMUser {
        let serviceUser = ZMUser.insertNewObject(in: uiMOC)
        serviceUser.remoteIdentifier = UUID()
        serviceUser.name = "ServiceUser"
        serviceUser.handle = serviceUser.name!.lowercased()
        serviceUser.accentColorValue = .brightOrange
        serviceUser.serviceIdentifier = UUID.create().transportString()
        serviceUser.providerIdentifier = UUID.create().transportString()
        uiMOC.saveOrRollback()

        return serviceUser
    }
}
