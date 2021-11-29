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

final class ConversationViewControllerSnapshotTests: XCTestCase, CoreDataFixtureTestHelper {

    var sut: ConversationViewController!
    var mockConversation: ZMConversation!
    var serviceUser: ZMUser!
    var mockZMUserSession: MockZMUserSession!
    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()
        mockConversation = createTeamGroupConversation()
        mockZMUserSession = MockZMUserSession()
        serviceUser = coreDataFixture.createServiceUser()

        let mockAccount = Account(userName: "mock user", userIdentifier: UUID())
        let selfUser = MockUserType.createSelfUser(name: "Bob")
        let zClientViewController = ZClientViewController(account: mockAccount, selfUser: selfUser)

        sut = ConversationViewController(session: mockZMUserSession,
                                         conversation: mockConversation,
                                         visibleMessage: nil,
                                         zClientViewController: zClientViewController)
    }

    override func tearDown() {
        sut = nil
        serviceUser = nil
        coreDataFixture = nil

        super.tearDown()
    }

    func testForInitState() {
        verify(matching: sut)
    }
}

// MARK: - Disable / Enable search in conversations

extension ConversationViewControllerSnapshotTests {

    func testThatTheSearchButtonIsDisabledIfMessagesAreEncryptedInTheDataBase() {
        // given

        // when
        mockZMUserSession.encryptMessagesAtRest = true

        // then
        XCTAssertFalse(sut.shouldShowCollectionsButton)
    }

    func testThatTheSearchButtonIsEnabledIfMessagesAreNotEncryptedInTheDataBase() {
        // given

        // when
        mockZMUserSession.encryptMessagesAtRest = false

        // then
        XCTAssertTrue(sut.shouldShowCollectionsButton)
    }
}

// MARK: - Guests bar controller

extension ConversationViewControllerSnapshotTests {

    func testThatGuestsBarControllerIsVisibleIfExternalsArePresent() {
        // given
        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier

        let teamMember = Member.insertNewObject(in: uiMOC)
        teamMember.user = otherUser
        teamMember.team = team
        otherUser.membership?.setTeamRole(.partner)
        UIColor.setAccentOverride(.strongLimeGreen)

        // when
        sut.updateGuestsBarVisibility()

        // then
        verify(matching: sut)
    }

    func testThatGuestsBarControllerIsVisibleIfServicesArePresent() {
        // given
        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier
        mockConversation.add(participants: [serviceUser])

        UIColor.setAccentOverride(.strongLimeGreen)

        // when
        sut.updateGuestsBarVisibility()

        // then
        verify(matching: sut)
    }

    func testThatGuestsBarControllerIsVisibleIfExternalsAndServicesArePresent() {
        // given
        let teamMember = Member.insertNewObject(in: uiMOC)
        teamMember.user = otherUser
        teamMember.team = team
        otherUser.membership?.setTeamRole(.partner)

        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier
        mockConversation.add(participants: [serviceUser])

        UIColor.setAccentOverride(.strongLimeGreen)

        // when
        sut.updateGuestsBarVisibility()

        // then
        verify(matching: sut)
    }

}
