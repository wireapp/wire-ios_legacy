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

final class ProfileActionsFactoryTests: XCTestCase {

    var selfUserTeam: UUID!
    var selfUser: MockUserType!
    var defaultExtendedMetadata: [[String: String]]!

    override func setUp() {
        super.setUp()
        selfUserTeam = UUID()
        selfUser = MockUserType.createSelfUser(name: "George Johnson", inTeam: selfUserTeam)
    }

    override func tearDown() {
        selfUser = nil
        selfUserTeam = nil
        defaultExtendedMetadata = nil
        super.tearDown()
    }

    // MARK: - 1:1

    // MARK: Viewer is team member

    func test_OneToOne_TeamToTeam() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .createGroup,
            .manageNotifications,
            .archive,
            .deleteContents
        ])
    }

    func test_OneToOne_TeamToPartner() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.teamRole = .partner

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .createGroup,
            .manageNotifications,
            .archive,
            .deleteContents
        ])
    }

    func test_OneToOne_TeamToGuest() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .createGroup,
            .manageNotifications,
            .archive,
            .deleteContents,
            .block(isBlocked: false)
        ])
    }

    func test_OneToOne_TeamToGuestFromOtherTeam() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .createGroup,
            .manageNotifications,
            .archive,
            .deleteContents,
            .block(isBlocked: false)
        ])
    }

    // MARK: Viewer is partner

    func test_OneToOne_PartnerToTeam() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canCreateConversation = false
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .manageNotifications,
            .archive,
            .deleteContents
        ])
    }

    func test_OneToOne_PartnerToPartner() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canCreateConversation = false
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.teamRole = .partner

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .manageNotifications,
            .archive,
            .deleteContents
        ])
    }

    func test_OneToOne_PartnerToGuest() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canCreateConversation = false
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .manageNotifications,
            .archive,
            .deleteContents,
            .block(isBlocked: false)
        ])
    }

    func test_OneToOne_PartnerToGuestFromOtherTeam() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canCreateConversation = false
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .manageNotifications,
            .archive,
            .deleteContents,
            .block(isBlocked: false)
        ])
    }

    // MARK: Viewer is guest

    func test_OneToOne_GuestToTeam() {
        // GIVEN
        let guest = MockUserType.createUser(name: "Bob", inTeam: nil)
        guest.isGuestInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .createGroup,
            .mute(isMuted: false),
            .archive,
            .deleteContents,
            .block(isBlocked: false)
        ])
    }

    func test_OneToOne_GuestToPartner() {
        // GIVEN
        let guest = MockUserType.createUser(name: "Bob", inTeam: nil)
        guest.isGuestInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.teamRole = .partner

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .createGroup,
            .mute(isMuted: false),
            .archive,
            .deleteContents,
            .block(isBlocked: false)
        ])
    }

    func test_OneToOne_GuestToGuest() {
        // GIVEN
        let guest = MockUserType.createUser(name: "Bob", inTeam: nil)
        guest.isGuestInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .createGroup,
            .mute(isMuted: false),
            .archive,
            .deleteContents,
            .block(isBlocked: false)
        ])
    }

    func test_OneToOne_GuestToGuest_Blocked() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true
        otherUser.isBlocked = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .block(isBlocked: true)
        ])
    }

    func test_OneToOne_GuestToGuestFromOtherTeam() {
        // GIVEN
        let guest = MockUserType.createUser(name: "Bob", inTeam: nil)
        guest.isGuestInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .createGroup,
            .mute(isMuted: false),
            .archive,
            .deleteContents,
            .block(isBlocked: false)
        ])
    }

    // MARK: - Groups

    // MARK: Viewer is team member

    func test_Group_TeamToTeam() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .openOneToOne,
            .removeFromGroup
        ])
    }

    func test_Group_TeamToPartner() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.teamRole = .partner

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .openOneToOne,
            .removeFromGroup
        ])
    }

    func test_Group_TeamToGuest_Connected() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .openOneToOne,
            .removeFromGroup,
            .block(isBlocked: false)
        ])
    }

    func test_Group_TeamToGuestFromOtherTeam_Connected() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .openOneToOne,
            .removeFromGroup,
            .block(isBlocked: false)
        ])
    }

    func test_Group_TeamToGuest_NotConnected() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true
        otherUser.isConnected = false
        otherUser.canBeConnected = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .connect,
            .removeFromGroup
        ])
    }

    func test_Group_TeamToGuest_PendingRequestFromSelf() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true
        otherUser.isConnected = false
        otherUser.isPendingApprovalByOtherUser = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .cancelConnectionRequest,
            .removeFromGroup
        ])
    }

    func test_Group_TeamToGuest_Wireless() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true
        otherUser.isWirelessUser = true
        otherUser.isConnected = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .removeFromGroup
        ])
    }

    func test_Group_TeamToGuest_UserDeleted() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isAccountDeleted = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [])
    }

    // MARK: Viewer is partner

    func test_Group_PartnerToTeam() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .openOneToOne
        ])
    }

    func test_Group_PartnerToPartner() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.teamRole = .partner

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .openOneToOne
        ])
    }

    func test_Group_PartnerToGuest_Connected() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .openOneToOne,
            .block(isBlocked: false)
        ])
    }

    func test_Group_PartnerToGuestFromOtherTeam_Connected() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .openOneToOne,
            .block(isBlocked: false)
        ])
    }

    func test_Group_PartnerToGuest_NotConnected() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true
        otherUser.isConnected = false
        otherUser.canBeConnected = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .connect
        ])
    }

    func test_Group_PartnerToGuest_PendingRequestFromSelf() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true
        otherUser.isConnected = false
        otherUser.isPendingApprovalByOtherUser = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [
            .cancelConnectionRequest
        ])
    }

    func test_Group_PartnerToGuest_Wireless() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.canRemoveUserFromConversation = false
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true
        otherUser.isWirelessUser = true
        otherUser.isConnected = false
        otherUser.canBeConnected = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: selfUser, conversation: conversation, expectedActions: [])
    }

    // MARK: Viewer is guest

    func test_Group_GuestToTeam_Connected() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.canRemoveUserFromConversation = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .openOneToOne,
            .block(isBlocked: false)
        ])
    }

    func test_Group_GuestToTeam_NotConnected() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.isConnected = false
        otherUser.canBeConnected = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.canRemoveUserFromConversation = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .connect
        ])
    }

    func test_Group_GuestToPartner_Connected() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.teamRole = .partner

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.canRemoveUserFromConversation = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .openOneToOne,
            .block(isBlocked: false)
        ])
    }

    func test_Group_GuestToGuest() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.canRemoveUserFromConversation = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .openOneToOne,
            .block(isBlocked: false)
        ])
    }

    func test_Group_GuestToGuest_Blocked() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true
        otherUser.isBlocked = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .block(isBlocked: true)
        ])
    }

    func test_Group_GuestToGuestFromOtherTeam() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.canRemoveUserFromConversation = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .openOneToOne,
            .block(isBlocked: false)
        ])
    }

    func test_Group_GuestToGuest_NotConnected() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isConnected = false
        otherUser.canBeConnected = true
        otherUser.isGuestInConversation = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.canRemoveUserFromConversation = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .connect
        ])
    }

    func test_Group_GuestToGuest_PendingRequestFromSelf() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: UUID())
        otherUser.isGuestInConversation = true
        otherUser.isConnected = false
        otherUser.isPendingApprovalByOtherUser = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.canRemoveUserFromConversation = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .cancelConnectionRequest
        ])
    }

    func test_Group_GuestToGuest_BothInSameTeam_PendingRequestFromSelf() {
        // GIVEN
        let otherTeam = UUID()
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: otherTeam)
        otherUser.isGuestInConversation = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: otherTeam)
        guest.isGuestInConversation = true
        guest.canRemoveUserFromConversation = false

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, guest, otherUser]

        // THEN
        verifyActions(user: otherUser, viewer: guest, conversation: conversation, expectedActions: [
            .openOneToOne
        ])
    }

    // MARK: - Helpers

    func verifyActions(user: UserType,
                       viewer: UserType,
                       conversation: MockConversation,
                       expectedActions: [ProfileAction],
                       context: ProfileViewControllerContext = .oneToOneConversation,
                       file: StaticString = #file,
                       line: UInt = #line) {
        let factory = ProfileActionsFactory(user: user, viewer: viewer, conversation: conversation.convertToRegularConversation(), context: context)
        let actions = factory.makeActionsList()
        XCTAssertEqual(actions, expectedActions, file: file, line: line)
    }

}
