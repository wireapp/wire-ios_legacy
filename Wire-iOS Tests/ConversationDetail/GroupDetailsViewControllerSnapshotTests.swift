//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import XCTest
@testable import Wire

final class MockGroupDetailsConversation: GroupDetailsConversationType {
    var isUnderLegalHold: Bool = false
    var isSelfAnActiveMember: Bool = true
    var userDefinedName: String?
    
    var displayName: String = ""

    var sortedOtherParticipants: [UserType] = []
    var sortedServiceUsers: [UserType] = []
    
    var securityLevel: ZMConversationSecurityLevel = .secure
    
    var allowGuests: Bool = false
    var hasReadReceiptsEnabled: Bool = false

    var conversationType: ZMConversationType = .group
}

final class GroupDetailsViewControllerSnapshotTests: XCTestCase {

    var sut: GroupDetailsViewController!
    var groupConversation: MockGroupDetailsConversation!
    var mockSelfUser: MockUserType!
    
    override func setUp() {
        super.setUp()

        groupConversation = MockGroupDetailsConversation()
        groupConversation.displayName = "iOS Team"
        
        mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)
    }
    
    override func tearDown() {
        sut = nil
        groupConversation = nil
        mockSelfUser = nil

        super.tearDown()
    }
    
/*    func testForOptionsForTeamUserInNonTeamConversation() {
        teamTest {
            let actionAddMember = Action.insertNewObject(in: uiMOC)
            actionAddMember.name = "add_conversation_member"

            let actionModifyTimer = Action.insertNewObject(in: uiMOC)
            actionModifyTimer.name = "modify_conversation_message_timer"

            let actionModifyName = Action.insertNewObject(in: uiMOC)
            actionModifyName.name = "modify_conversation_name"

            selfUser.membership?.setTeamRole(.member)
            let groupRole = selfUser.role(in: groupConversation)
            groupRole?.actions = Set([actionAddMember, actionModifyTimer, actionModifyName])
            sut = GroupDetailsViewController(conversation: groupConversation)

            verify(matching: sut)
        }
    }

    func testForOptionsForTeamUserInNonTeamConversation_Partner() {
        teamTest {
            selfUser.membership?.setTeamRole(.partner)
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(matching: sut)
        }
    }

    func testForOptionsForTeamUserInTeamConversation() {
        // GIVEN
        let actionAddMember = Action.insertNewObject(in: uiMOC)
        actionAddMember.name = "add_conversation_member"

        let actionModifyTimer = Action.insertNewObject(in: uiMOC)
        actionModifyTimer.name = "modify_conversation_message_timer"

        let actionModifyName = Action.insertNewObject(in: uiMOC)
        actionModifyName.name = "modify_conversation_name"

        let actionModifyAccess = Action.insertNewObject(in: uiMOC)
        actionModifyAccess.name = "modify_conversation_access"

        let actionReceiptMode = Action.insertNewObject(in: uiMOC)
        actionReceiptMode.name = "modify_conversation_receipt_mode"

        teamTest {
            selfUser.membership?.setTeamRole(.member)
            groupConversation.team =  selfUser.team
            groupConversation.teamRemoteIdentifier = selfUser.team?.remoteIdentifier
            let groupRole = selfUser.role(in: groupConversation)
            groupRole?.actions = Set([actionAddMember, actionModifyTimer, actionModifyName, actionModifyAccess, actionReceiptMode])
            sut = GroupDetailsViewController(conversation: groupConversation)

            // THEN
            verify(matching: sut)
        }
    }

    func testForOptionsForTeamUserInTeamConversation_Partner() {
        teamTest {
            selfUser.membership?.setTeamRole(.partner)
            groupConversation.team =  selfUser.team
            groupConversation.teamRemoteIdentifier = selfUser.team?.remoteIdentifier
            sut = GroupDetailsViewController(conversation: groupConversation)
            verify(matching: sut)
        }
    }*/

    func testForOptionsForNonTeamUser() {
        // GIVEN
        mockSelfUser.canModifyTitleInConversation = true
        mockSelfUser.isGroupAdminInConversation = true
        mockSelfUser.canModifyEphemeralSettingsInConversation = true
        
        let otherUser = MockUserType.createUser(name: "Bruno")
        otherUser.isConnected = true
        otherUser.handle = "bruno"
        otherUser.accentColorValue = .brightOrange

        groupConversation.securityLevel = .notSecure
        groupConversation.sortedOtherParticipants = [otherUser, mockSelfUser]
        

            sut = GroupDetailsViewController(conversation: groupConversation)
            
            // THEN
            verify(matching: sut)
    }

    private func verifyConversationActionController(file: StaticString = #file,
                                            line: UInt = #line) {
        sut = GroupDetailsViewController(conversation: groupConversation)
        sut.footerView(GroupDetailsFooterView(), shouldPerformAction: .more)
        verify(matching:(sut?.actionController?.alertController)!, file: file, line: line)
    }

    func testForActionMenu() {
        mockSelfUser.hasTeam = true
        verifyConversationActionController()
    }

    func testForActionMenu_NonTeam() {
        verifyConversationActionController()
    }

    /*func testForOptionsForTeamUserInTeamConversation_Admins() {
        // GIVEN
        let groupConversationAdmin: ZMConversation = createGroupConversationOnlyAdmin()
        let actionAddMember = Action.insertNewObject(in: uiMOC)
        actionAddMember.name = "add_conversation_member"

        let actionModifyTimer = Action.insertNewObject(in: uiMOC)
        actionModifyTimer.name = "modify_conversation_message_timer"

        let actionModifyName = Action.insertNewObject(in: uiMOC)
        actionModifyName.name = "modify_conversation_name"

        teamTest {
            selfUser.membership?.setTeamRole(.admin)
            groupConversationAdmin.team =  selfUser.team
            groupConversation.teamRemoteIdentifier = selfUser.team?.remoteIdentifier
            let groupRole = selfUser.role(in: groupConversationAdmin)
            groupRole?.actions = Set([actionAddMember, actionModifyTimer, actionModifyName])
            sut = GroupDetailsViewController(conversation: groupConversationAdmin)

            // THEN
            verify(matching: sut)
        }
    }*/
}
