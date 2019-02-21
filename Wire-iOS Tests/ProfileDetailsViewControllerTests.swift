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

import XCTest
@testable import Wire

class ProfileDetailsViewControllerTests: ZMSnapshotTestCase {

    var selfUserTeam: UUID!
    var selfUser: MockUser!
    var defaultExtendedMetadata: [[String: String]]!
    
    override func setUp() {
        super.setUp()
        selfUserTeam = UUID()
        selfUser = MockUser.createSelfUser(name: "George Johnson", inTeam: selfUserTeam)
        
        defaultExtendedMetadata = [
            ["key": "Title", "value": "Chief Design Officer"],
            ["key": "Entity", "value": "ACME/OBS/EQUANT/CSO/IBO/OEC/SERVICE OP/CS MGT/CSM EEMEA"],
        ]
    }
    
    override func tearDown() {
        selfUser = nil
        selfUserTeam = nil
        defaultExtendedMetadata = nil
        super.tearDown()
    }
    
    // MARK: - 1:1 Conversation

    // MARK: Viewer is a team member

    func test_OneToOne_OtherUser_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata

        selfUser.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUser_NoSCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = []

        selfUser.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserIsPartner_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata
        otherUser.teamRole = .partner

        selfUser.readReceiptsEnabled = false

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata),
            .readReceiptsStatus(enabled: false)
        ])
    }

    func test_OneToOne_OtherUserIsPartner_NoSCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = []
        otherUser.teamRole = .partner

        selfUser.readReceiptsEnabled = false

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: false)
        ])
    }

    func test_OneToOne_SelfUser_SCIM() {
        // GIVEN
        selfUser.availability = .busy
        selfUser.readReceiptsEnabled = true
        selfUser.extendedMetadata = defaultExtendedMetadata

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser]

        // THEN
        verifyProfile(user: selfUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: selfUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_SelfUser_NoSCIM() {
        // GIVEN
        selfUser.availability = .busy
        selfUser.readReceiptsEnabled = false
        selfUser.extendedMetadata = nil

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser]

        // THEN
        verifyProfile(user: selfUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: selfUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: false)
        ])
    }

    func test_OneToOne_OtherUserIsGuest_SCIM() {
        // GIVEN
        selfUser.readReceiptsEnabled = true

        let guest = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        guest.isGuestInConversation = true
        guest.extendedMetadata = defaultExtendedMetadata
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, guest]

        // THEN
        verifyProfile(user: guest, viewer: selfUser, conversation: conversation)
        verifyContents(user: guest, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
        ])
    }

    // MARK: Viewer is a partner

    func test_OneToOne_OtherUserInTeam_ViewerIsPartner_SCIM() {
        // GIVEM
        selfUser.teamRole = .partner
        selfUser.readReceiptsEnabled = true

        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserIsPartner_ViewerIsPartner_SCIM() {
        // GIVEM
        selfUser.teamRole = .partner
        selfUser.readReceiptsEnabled = true

        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata
        otherUser.teamRole = .partner

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserIsGuest_ViewerIsPartner_SCIM() {
        // GIVEM
        selfUser.teamRole = .partner
        selfUser.readReceiptsEnabled = true

        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
        ])
    }

    // MARK: Viewer is a guest

    func test_OneToOne_OtherUserInTeam_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.extendedMetadata = defaultExtendedMetadata

        let guest = MockUser.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserIsPartner_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.extendedMetadata = defaultExtendedMetadata
        otherUser.teamRole = .partner

        let guest = MockUser.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserIsGuest_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.extendedMetadata = defaultExtendedMetadata
        otherUser.isGuestInConversation = true

        let guest = MockUser.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
        ])
    }

    // MARK: - Group Conversation

    // MARK: Viewer is a team member
    
    func test_Group_OtherUser_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata
        
        selfUser.readReceiptsEnabled = true
        
        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]
        
        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata)
        ])
    }

    func test_Group_OtherUser_NoSCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = []
        
        selfUser.readReceiptsEnabled = true
        
        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]
        
        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsPartner_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata
        otherUser.teamRole = .partner

        selfUser.readReceiptsEnabled = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata)
        ])
    }

    func test_Group_OtherUserIsPartner_NoSCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = []
        otherUser.teamRole = .partner

        selfUser.readReceiptsEnabled = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [])
    }
    
    func test_Group_SelfUser_SCIM() {
        // GIVEN
        selfUser.availability = .busy
        selfUser.readReceiptsEnabled = true
        selfUser.extendedMetadata = defaultExtendedMetadata

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser]

        // THEN
        verifyProfile(user: selfUser, viewer: selfUser, conversation: group)
        verifyContents(user: selfUser, viewer: selfUser, conversation: group, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata)
        ])
    }

    func test_Group_SelfUser_NoSCIM() {
        // GIVEN
        selfUser.availability = .busy
        selfUser.readReceiptsEnabled = false
        selfUser.extendedMetadata = nil

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser]

        // THEN
        verifyProfile(user: selfUser, viewer: selfUser, conversation: group)
        verifyContents(user: selfUser, viewer: selfUser, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsGuest_SCIM() {
        // GIVEN
        let guest = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        guest.isGuestInConversation = true
        guest.extendedMetadata = defaultExtendedMetadata

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, guest]

        // THEN
        verifyProfile(user: guest, viewer: selfUser, conversation: group)
        verifyContents(user: guest, viewer: selfUser, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsExpiringGuest_SCIM() {
        // GIVEN
        let guest = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        guest.isGuestInConversation = true
        guest.expiresAfter = 3600
        guest.extendedMetadata = defaultExtendedMetadata

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, guest]

        // THEN
        verifyProfile(user: guest, viewer: selfUser, conversation: group)
        verifyContents(user: guest, viewer: selfUser, conversation: group, expectedContents: [])
    }

    // MARK: Viewer is a partner

    func test_Group_OtherUserInTeam_ViewerIsPartner_SCIM() {
        // GIVEM
        selfUser.teamRole = .partner

        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]
        
        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata)
        ])
    }

    func test_Group_OtherUserIsPartner_ViewerIsPartner_SCIM() {
        // GIVEM
        selfUser.teamRole = .partner

        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata
        otherUser.teamRole = .partner

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata)
        ])
    }

    func test_Group_OtherUserIsGuest_ViewerIsPartner_SCIM() {
        // GIVEM
        selfUser.teamRole = .partner

        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true
        otherUser.availability = .busy
        otherUser.extendedMetadata = defaultExtendedMetadata

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [])
    }

    // MARK: Viewer is a guest

    func test_Group_OtherUserInTeam_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.extendedMetadata = defaultExtendedMetadata
        
        let guest = MockUser.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        
        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]
        
        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsPartner_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.extendedMetadata = defaultExtendedMetadata
        otherUser.teamRole = .partner

        let guest = MockUser.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsGuest_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.extendedMetadata = defaultExtendedMetadata
        otherUser.isGuestInConversation = true

        let guest = MockUser.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [])
    }
    
    func test_Group_OtherUserInTeam_ViewerIsGuestFromOtherTeam_SCIM() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.extendedMetadata = defaultExtendedMetadata

        let guest = MockUser.createConnectedUser(name: "Bob the Guest", inTeam: UUID())
        guest.isGuestInConversation = true
        
        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [])
    }

    func test_Group_UserAndViewerAreGuestsFromSameTeam_SCIM() {
        // GIVEN
        let otherTeamID = UUID()
        
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: otherTeamID)
        otherUser.isGuestInConversation = true

        let guest = MockUser.createConnectedUser(name: "Bob the Guest", inTeam: otherTeamID)
        guest.isGuestInConversation = true
        guest.extendedMetadata = defaultExtendedMetadata
        
        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]
        
        // THEN
        verifyProfile(user: guest, viewer: otherUser, conversation: group)
        verifyContents(user: guest, viewer: otherUser, conversation: group, expectedContents: [
            .extendedMetadata(defaultExtendedMetadata)
        ])
    }

    // MARK: - Pending Connection

    func test_Group_ConnectionRequest() {
        // GIVEN
        let otherUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isConnected = false
        otherUser.readReceiptsEnabled = true
        otherUser.isGuestInConversation = true
        otherUser.extendedMetadata = defaultExtendedMetadata

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [])
    }

    // MARK: - Helpers
    
    private func verifyProfile(user: GenericUser, viewer: GenericUser, conversation: MockConversation, file: StaticString = #file, line: UInt = #line) {
        let details = ProfileDetailsViewController(user: user, viewer: viewer,
                                                      conversation: conversation.convertToRegularConversation())

        verify(view: details.view, file: file, line: line)
    }

    private func verifyContents(user: GenericUser, viewer: GenericUser, conversation: MockConversation, expectedContents: [ProfileDetailsContentController.Content], file: StaticString = #file, line: UInt = #line) {
        let controller = ProfileDetailsContentController(user: user, viewer: viewer,
                                                         conversation: conversation.convertToRegularConversation())

        XCTAssertEqual(controller.contents, expectedContents, file: file, line: line)
    }

}
