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

import SnapshotTesting
import XCTest
@testable import Wire

final class ProfileDetailsViewControllerTests: XCTestCase {

    var selfUserTeam: UUID!
    var selfUser: MockUserType!
    var defaultRichProfile: [UserRichProfileField]!

    override func setUp() {
        super.setUp()
        selfUserTeam = UUID()
        selfUser = MockUserType.createSelfUser(name: "George Johnson", inTeam: selfUserTeam)

        defaultRichProfile = [
            UserRichProfileField(type: "Title", value: "Chief Design Officer"),
            UserRichProfileField(type: "Entity", value: "ACME/OBS/EQUANT/CSO/IBO/OEC/SERVICE OP/CS MGT/CSM EEMEA")
        ]
    }

    override func tearDown() {
        selfUser = nil
        selfUserTeam = nil
        defaultRichProfile = nil
        super.tearDown()
    }

    // MARK: - 1:1 Conversation

    // MARK: Viewer is a team member

    func test_OneToOne_OtherUser_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        selfUser.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            richProfileItemWithEmailAndDefaultData(for: otherUser),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUser_NoSCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = []

        selfUser.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)]),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUser_NoSCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = []
        otherUser.emailAddress = nil

        selfUser.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
            ])
    }

    func test_OneToOne_OtherUserIsPartner_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner

        selfUser.readReceiptsEnabled = false

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            richProfileItemWithEmailAndDefaultData(for: otherUser),
            .readReceiptsStatus(enabled: false)
        ])
    }

    func test_OneToOne_OtherUserIsPartner_NoSCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = []
        otherUser.teamRole = .partner

        selfUser.readReceiptsEnabled = false

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)]),
            .readReceiptsStatus(enabled: false)
        ])
    }

    func test_OneToOne_OtherUserIsPartner_NoSCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = []
        otherUser.teamRole = .partner
        otherUser.emailAddress = nil

        selfUser.readReceiptsEnabled = false

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: false)
            ])
    }

    func test_OneToOne_SelfUser_SCIM() {
        // GIVEN
        selfUser.availability = .busy
        selfUser.readReceiptsEnabled = true
        selfUser.richProfile = defaultRichProfile

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser]

        // THEN
        verifyProfile(user: selfUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: selfUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .richProfile(defaultRichProfile),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_SelfUser_NoSCIM() {
        // GIVEN
        selfUser.availability = .busy
        selfUser.readReceiptsEnabled = false
        selfUser.richProfile = []

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser]

        // THEN
        verifyProfile(user: selfUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: selfUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: false)
        ])
    }

    func test_OneToOne_OtherUserIsGuest_SCIM() {
        // GIVEN
        selfUser.readReceiptsEnabled = true

        let guest = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        guest.isGuestInConversation = true
        guest.richProfile = defaultRichProfile
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, guest]

        // THEN
        verifyProfile(user: guest, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: guest, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
        ])
    }

    // MARK: Viewer is a partner

    func test_OneToOne_OtherUserInTeam_ViewerIsPartner_SCIM() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.readReceiptsEnabled = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            richProfileItemWithEmailAndDefaultData(for: otherUser),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserInTeam_ViewerIsPartner_SCIM_NoEmail() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.readReceiptsEnabled = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile
        otherUser.emailAddress = nil

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .richProfile(defaultRichProfile),
            .readReceiptsStatus(enabled: true)
            ])
    }

    func test_OneToOne_OtherUserIsPartner_ViewerIsPartner_SCIM() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.readReceiptsEnabled = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            richProfileItemWithEmailAndDefaultData(for: otherUser),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserIsPartner_ViewerIsPartner_SCIM_NoEmail() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.readReceiptsEnabled = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner
        otherUser.emailAddress = nil

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .richProfile(defaultRichProfile),
            .readReceiptsStatus(enabled: true)
            ])
    }

    func test_OneToOne_OtherUserIsGuest_ViewerIsPartner_SCIM() {
        // GIVEN
        selfUser.teamRole = .partner
        selfUser.readReceiptsEnabled = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
        ])
    }

    // MARK: Viewer is a guest

    func test_OneToOne_OtherUserInTeam_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)]),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserInTeam_ViewerIsGuest_SCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.emailAddress = nil

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
            ])
    }

    func test_OneToOne_OtherUserIsPartner_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)]),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserIsPartner_ViewerIsGuest_SCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner
        otherUser.emailAddress = nil

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
            ])
    }

    func test_OneToOne_OtherUserIsGuest_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.isGuestInConversation = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)]),
            .readReceiptsStatus(enabled: true)
        ])
    }

    func test_OneToOne_OtherUserIsGuest_ViewerIsGuest_SCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.isGuestInConversation = true
        otherUser.emailAddress = nil

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.readReceiptsEnabled = true

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: conversation, context: .oneToOneConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: conversation, expectedContents: [
            .readReceiptsStatus(enabled: true)
            ])
    }

    // MARK: - Group Conversation

    // MARK: Viewer is a team member

    func test_Group_OtherUser_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        selfUser.readReceiptsEnabled = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser,
                       viewer: selfUser,
                       conversation: group,
                       expectedContents: [richProfileItemWithEmailAndDefaultData(for: otherUser)])
    }

    func test_Group_OtherUser_NoSCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = []

        selfUser.readReceiptsEnabled = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)])
            ])
    }

    func test_Group_OtherUser_NoSCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = []
        otherUser.emailAddress = nil

        selfUser.readReceiptsEnabled = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsPartner_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner

        selfUser.readReceiptsEnabled = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            richProfileItemWithEmailAndDefaultData(for: otherUser)
        ])
    }

    func test_Group_OtherUserIsPartner_NoSCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = []
        otherUser.teamRole = .partner

        selfUser.readReceiptsEnabled = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)])
            ])
    }

    func test_Group_OtherUserIsPartner_NoSCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = []
        otherUser.teamRole = .partner
        otherUser.emailAddress = nil

        selfUser.readReceiptsEnabled = true

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [])
    }

    func test_Group_SelfUser_SCIM() {/// FIXME: can self user disable myself as admin? In this test since self user.isConnected == false we do not show it.
        // GIVEN
        selfUser.availability = .busy
        selfUser.readReceiptsEnabled = true
        selfUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser]

        // THEN
        verifyProfile(user: selfUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: selfUser, viewer: selfUser, conversation: group, expectedContents: [
            .richProfile(defaultRichProfile)
        ])
    }

    /// FIXME: can self user disable myself as admin? In this test since self user.isConnected == false we do not show it.
    func test_Group_SelfUser_NoSCIM() {
        // GIVEN
        selfUser.availability = .busy
        selfUser.readReceiptsEnabled = false
        selfUser.richProfile = []

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser]

        // THEN
        verifyProfile(user: selfUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: selfUser, viewer: selfUser, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsGuest_SCIM() {
        // GIVEN
        let guest = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        guest.isGuestInConversation = true
        guest.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, guest]

        // THEN
        verifyProfile(user: guest, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: guest, viewer: selfUser, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsExpiringGuest_SCIM() {
        // GIVEN
        let guest = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        guest.isGuestInConversation = true
        guest.expiresAfter = 3600
        guest.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, guest]

        // THEN
        verifyProfile(user: guest, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: guest, viewer: selfUser, conversation: group, expectedContents: [])
    }

    // MARK: Viewer is a partner

    func test_Group_OtherUserInTeam_ViewerIsPartner_SCIM() {
        // GIVEN
        selfUser.teamRole = .partner

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            richProfileItemWithEmailAndDefaultData(for: otherUser)
        ])
    }

    func test_Group_OtherUserInTeam_ViewerIsPartner_SCIM_NoEmail() {
        // GIVEN
        selfUser.teamRole = .partner

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile
        otherUser.emailAddress = nil

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            .richProfile(defaultRichProfile)
            ])
    }

    func test_Group_OtherUserIsPartner_ViewerIsPartner_SCIM() {
        // GIVEN
        selfUser.teamRole = .partner

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            richProfileItemWithEmailAndDefaultData(for: otherUser)
        ])
    }

    func test_Group_OtherUserIsPartner_ViewerIsPartner_SCIM_NoEmail() {
        // GIVEN
        selfUser.teamRole = .partner

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner
        otherUser.emailAddress = nil

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [
            .richProfile(defaultRichProfile)
            ])
    }

    func test_Group_OtherUserIsGuest_ViewerIsPartner_SCIM() {
        // GIVEN
        selfUser.teamRole = .partner

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isGuestInConversation = true
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [])
    }

    // MARK: Viewer is a guest

    func test_Group_OtherUserInTeam_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.teamRole = .admin

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)])
        ])
    }

    func test_Group_OtherUserInTeam_ViewerIsGuest_SCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.emailAddress = nil

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.teamRole = .admin

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsPartner_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.teamRole = .admin

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)])]
        )
    }

    func test_Group_OtherUserIsAdmin_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .admin

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.teamRole = .admin

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [
            .richProfile([richProfileFieldWithEmail(for: otherUser)])]
        )
    }

    func test_Group_OtherUserIsPartner_ViewerIsGuest_SCIM_NoEmail() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.teamRole = .partner
        otherUser.emailAddress = nil

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.teamRole = .admin

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserIsGuest_ViewerIsGuest_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile
        otherUser.isGuestInConversation = true

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: nil)
        guest.isGuestInConversation = true
        guest.teamRole = .admin

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [])
    }

    func test_Group_OtherUserInTeam_ViewerIsGuestFromOtherTeam_SCIM() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.availability = .busy
        otherUser.readReceiptsEnabled = true
        otherUser.richProfile = defaultRichProfile

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: UUID())
        guest.isGuestInConversation = true
        guest.teamRole = .admin

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser, guest]

        // THEN
        verifyProfile(user: otherUser, viewer: guest, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: guest, conversation: group, expectedContents: [])
    }

    func test_Group_UserAndViewerAreGuestsFromSameTeam_SCIM() {
        // GIVEN
        let otherTeamID = UUID()

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: otherTeamID)
        otherUser.isGuestInConversation = true
        otherUser.teamRole = .admin

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: otherTeamID)
        guest.isGuestInConversation = true
        guest.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: guest, viewer: otherUser, conversation: group, context: .groupConversation)
        verifyContents(user: guest, viewer: otherUser, conversation: group, expectedContents: [
            richProfileItemWithEmailAndDefaultData(for: otherUser)
        ])
    }

    func test_Group_UserAndViewerAreGuestsFromSameTeam_SCIM_NoEmail() {
        // GIVEN
        let otherTeamID = UUID()

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: otherTeamID)
        otherUser.isGuestInConversation = true
        otherUser.teamRole = .admin

        let guest = MockUserType.createConnectedUser(name: "Bob the Guest", inTeam: otherTeamID)
        guest.isGuestInConversation = true
        guest.richProfile = defaultRichProfile
        guest.emailAddress = nil

        let group = MockConversation.groupConversation()
        group.activeParticipants = [otherUser, guest]

        // THEN
        verifyProfile(user: guest, viewer: otherUser, conversation: group, context: .groupConversation)
        verifyContents(user: guest, viewer: otherUser, conversation: group, expectedContents: [
            .richProfile(defaultRichProfile)
            ])
    }

    // MARK: Conversation Roles

    func test_Group_ViewerIsAdmin_OtherIsAdmin() {
        // GIVEN
        selfUser.isGroupAdminInConversation = true
        selfUser.canModifyOtherMemberInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.isGroupAdminInConversation = true
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser,
                       viewer: selfUser,
                       conversation: group,
                       expectedContents: [.groupAdminStatus(enabled: true), richProfileItemWithEmailAndDefaultData(for: otherUser)])
    }

    func test_Group_ViewerIsAdmin_OtherIsNotAdmin() {
        // GIVEN
        selfUser.isGroupAdminInConversation = true
        selfUser.canModifyOtherMemberInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.isGroupAdminInConversation = false
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser,
                       viewer: selfUser,
                       conversation: group,
                       expectedContents: [.groupAdminStatus(enabled: false), richProfileItemWithEmailAndDefaultData(for: otherUser)])
    }

    func test_Group_ViewerIsAdmin_OtherIsExternalAdmin() {
        // GIVEN
        selfUser.isGroupAdminInConversation = true
        selfUser.canModifyOtherMemberInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.isGroupAdminInConversation = true
        otherUser.isGuestInConversation = true
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser,
                       viewer: selfUser,
                       conversation: group,
                       expectedContents: [.groupAdminStatus(enabled: true), richProfileItemWithEmailAndDefaultData(for: otherUser)])
    }

    func test_Group_ViewerIsAdmin_OtherIsWirelessAdmin() {
        // GIVEN
        selfUser.isGroupAdminInConversation = true
        selfUser.canModifyOtherMemberInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.isGroupAdminInConversation = true
        otherUser.isWirelessUser = true
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser,
                       viewer: selfUser,
                       conversation: group,
                       expectedContents: [richProfileItemWithEmailAndDefaultData(for: otherUser)])
    }

    func test_Group_ViewerIsMember_OtherIsAdmin() {
        // GIVEN
        selfUser.isGroupAdminInConversation = false
        selfUser.canModifyOtherMemberInConversation = false

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.isGroupAdminInConversation = true
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser,
                       viewer: selfUser,
                       conversation: group,
                       expectedContents: [richProfileItemWithEmailAndDefaultData(for: otherUser)])
    }

    func test_Group_ViewIsNotAdmin_OtherIsFederated() {
        // GIVEN
        selfUser.isGroupAdminInConversation = true
        selfUser.canModifyOtherMemberInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.isGroupAdminInConversation = false
        otherUser.isFederated = true
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [richProfileItemWithEmailAndDefaultData(for: otherUser)])
    }

    func test_Group_ViewIsAdmin_OtherIsFederated() {
        // GIVEN
        selfUser.isGroupAdminInConversation = true
        selfUser.canModifyOtherMemberInConversation = true

        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: selfUserTeam)
        otherUser.isGroupAdminInConversation = true
        otherUser.isFederated = true
        otherUser.availability = .busy
        otherUser.richProfile = defaultRichProfile

        let group = MockConversation.groupConversation()
        group.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: group, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: group, expectedContents: [richProfileItemWithEmailAndDefaultData(for: otherUser)])
    }

    // MARK: - Pending Connection

    func test_Group_ConnectionRequest() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isConnected = false
        otherUser.readReceiptsEnabled = true
        otherUser.isGuestInConversation = true
        otherUser.richProfile = defaultRichProfile

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [])
    }

    // MARK: - Blocking Connection

    func test_Group_BlockingConnectionRequest_MissingLegalHoldConsent1() {
        // GIVEN
        let otherUser = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        otherUser.isConnected = false
        otherUser.readReceiptsEnabled = true
        otherUser.isGuestInConversation = true
        otherUser.richProfile = defaultRichProfile
        otherUser.isBlocked = true
        otherUser.blockState = .blockedMissingLegalholdConsent

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, otherUser]

        // THEN
        verifyProfile(user: otherUser, viewer: selfUser, conversation: conversation, context: .groupConversation)
        verifyContents(user: otherUser, viewer: selfUser, conversation: conversation, expectedContents: [.blockingReason])
    }

    // MARK: Deep Link

    func test_ProfileViewer_OtherUserIsGuest() {
        // GIVEN
        let guest = MockUserType.createConnectedUser(name: "Catherine Jackson", inTeam: nil)
        /// Notice: rich profile is not visible in this case
        guest.richProfile = defaultRichProfile

        // THEN
        verifyProfile(user: guest, viewer: selfUser, conversation: nil, context: .profileViewer)
    }

    // MARK: - Helpers

    private func verifyProfile(user: UserType,
                               viewer: UserType,
                               conversation: MockConversation?,
                               context: ProfileViewControllerContext,
                               file: StaticString = #file,
                               testName: String = #function,
                               line: UInt = #line) {
        let details = ProfileDetailsViewController(user: user,
                                                   viewer: viewer,
                                                   conversation: conversation?.convertToRegularConversation(),
                                                   context: context)

        verify(matching: details,
               file: file,
               testName: testName,
               line: line)
    }

    private func richProfileFieldWithEmail(for user: UserType) -> UserRichProfileField {
        return UserRichProfileField(type: "Email", value: user.emailAddress!)
    }

    private func richProfileItemWithEmailAndDefaultData(for user: UserType) -> ProfileDetailsContentController.Content {
        var items = [richProfileFieldWithEmail(for: user)]
        items.append(contentsOf: defaultRichProfile)
        return .richProfile(items)
    }

    private func verifyContents(user: UserType,
                                viewer: UserType,
                                conversation: MockConversation,
                                expectedContents: [ProfileDetailsContentController.Content],
                                file: StaticString = #file,
                                line: UInt = #line) {
        let controller = ProfileDetailsContentController(user: user,
                                                         viewer: viewer,
                                                         conversation: conversation.convertToRegularConversation())

        XCTAssertEqual(controller.contents, expectedContents, file: file, line: line)
    }

}
