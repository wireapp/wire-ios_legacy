//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class ConversationMessageSenderSnapshotTests: ZMSnapshotTestCase {

    var sut: SenderCellComponent!
    var teamID = UUID()
    var groupConversation: SwiftMockConversation!
    var oneToOneConversation: SwiftMockConversation!
    var mockUser: MockUserType!
    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()
        mockUser = MockUserType.createUser(name: "Bruno", inTeam: teamID)
        mockUser.isConnected = true
        mockSelfUser = MockUserType.createSelfUser(name: "George Johnson", inTeam: teamID)
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)

        groupConversation = createGroupConversation()
        oneToOneConversation = createOneOnOneConversation()

        sut = SenderCellComponent(frame: CGRect(x: 0, y: 0, width: 320, height: 64))

        ColorScheme.default.variant = .light
        sut.overrideUserInterfaceStyle = .light
        sut.backgroundColor = UIColor.from(scheme: .contentBackground)
    }

    override func tearDown() {
        sut = nil
        groupConversation = nil
        oneToOneConversation = nil
        mockUser = nil
        mockSelfUser = nil
        super.tearDown()
    }

    // MARK: - 1:1

    func test_SenderIsExternal_OneOnOneConversation() {
        // GIVEN
        mockUser.teamRole = .partner

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    func test_SenderIsExternal_OneOnOneConversation_DarkMode() {
        // GIVEN
        ColorScheme.default.variant = .dark
        sut.overrideUserInterfaceStyle = .dark
        sut.backgroundColor = UIColor.from(scheme: .contentBackground)

        mockUser.teamRole = .partner

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    func test_SenderIsGuest_OneOnOneConversation() {
        // GIVEN
        mockUser.isGuestInConversation = true
        mockUser.teamIdentifier = nil

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    func test_SenderIsBot_OneOnOneConversation() {
        // GIVEN
        mockUser.mockedIsServiceUser = true

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    func test_SenderIsTeamMember_OneOnOneConversation() {
        // GIVEN
        mockUser.teamRole = .member
        mockUser.isGuestInConversation = false
        mockUser.mockedIsServiceUser = false

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    // MARK: - Groups

    func test_SenderIsExternal_GroupConversation() {
        // GIVEN
        mockUser.teamRole = .partner

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    func test_SenderIsGuest_GroupConversation() {
        // GIVEN
        mockUser.isGuestInConversation = true
        mockUser.teamIdentifier = nil

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    func test_SenderIsGuest_GroupConversation_DarkMode() {
        // GIVEN
        ColorScheme.default.variant = .dark
        sut.overrideUserInterfaceStyle = .dark
        sut.backgroundColor = UIColor.from(scheme: .contentBackground)
        mockUser.teamIdentifier = nil

        mockUser.isGuestInConversation = true

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    func test_SenderIsBot_GroupConversation() {
        // GIVEN
        mockUser.mockedIsServiceUser = true

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    func test_SenderIsTeamMember_GroupConversation() {
        // GIVEN
        mockUser.teamRole = .member
        mockUser.isGuestInConversation = false
        mockUser.mockedIsServiceUser = false

        // WHEN
        sut.configure(with: mockUser)

        // THEN
        verify(matching: sut)
    }

    // MARK: - Helpers

    private func createGroupConversation() -> SwiftMockConversation {
        let conversation = SwiftMockConversation()
        conversation.teamRemoteIdentifier = UUID()
        conversation.mockLocalParticipantsContain = true

        return conversation
    }

    private func createOneOnOneConversation() -> SwiftMockConversation {
        let conversation = SwiftMockConversation()
        conversation.conversationType = .oneOnOne
        conversation.mockLocalParticipantsContain = false

        return conversation
    }
}
