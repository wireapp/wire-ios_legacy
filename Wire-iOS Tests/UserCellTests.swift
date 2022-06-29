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

import XCTest
@testable import Wire

final class UserCellTests: ZMSnapshotTestCase {

    var sut: UserCell!
    var teamID = UUID()
    var conversation: MockGroupDetailsConversation!
    var mockUser: MockUserType!

    override func setUp() {
        super.setUp()

        SelfUser.setupMockSelfUser(inTeam: teamID)

        mockUser = MockUserType.createUser(name: "James Hetfield", inTeam: teamID)
        mockUser.handle = "james_hetfield_1"

        conversation = MockGroupDetailsConversation()
    }

    override func tearDown() {
        conversation = nil
        sut = nil
        super.tearDown()
    }

    private func verify(mockUser: UserType,
                        conversation: GroupDetailsConversationType,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {

        sut = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        sut.configure(with: mockUser,
                      selfUser: SelfUser.current,
                      conversation: conversation)
        sut.accessoryIconView.isHidden = false

        verifyInAllColorSchemes(matching: sut, file: file, testName: testName, line: line)
    }

    func testExternalUser() {
        mockUser.teamRole = .partner

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testServiceUser() {
        mockUser.mockedIsServiceUser = true

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testNonTeamUser() {
        mockUser.teamIdentifier = nil
        mockUser.isConnected = true

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testTrustedNonTeamUser() {
        mockUser.isVerified = true

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testFederatedUser() {
        mockUser.isFederated = true
        mockUser.domain = "foo.com"

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testGuestUser() {
        mockUser.isGuestInConversation = true

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testGuestUser_Wireless() {
        mockUser.isGuestInConversation = true
        mockUser.expiresAfter = 5_200
        mockUser.handle = nil

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testTrustedGuestUser() {
        mockUser.isVerified = true

        mockUser.isGuestInConversation = true

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testNonTeamUserWithoutHandle() {
        mockUser = MockUserType.createUser(name: "Tarja Turunen")
        mockUser.accentColorValue = .vividRed
        mockUser.isConnected = true
        mockUser.handle = nil

        verify(mockUser: mockUser, conversation: conversation)
    }

    func testUserInsideOngoingVideoCall() {
        let config = CallParticipantsListCellConfiguration.callParticipant(user: HashBox(value: mockUser), videoState: .started, microphoneState: .unmuted, activeSpeakerState: .inactive)

        sut = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        sut.configure(with: config, variant: .dark, selfUser: SelfUser.current)

        verifyInAllColorSchemes(matching: sut)
    }

    func testUserScreenSharingInsideOngoingVideoCall() {
        let config = CallParticipantsListCellConfiguration.callParticipant(user: HashBox(value: mockUser), videoState: .screenSharing, microphoneState: .unmuted, activeSpeakerState: .inactive)
        sut = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        sut.configure(with: config, variant: .dark, selfUser: SelfUser.current)

        verifyInAllColorSchemes(matching: sut)
    }

    // MARK: unit test
    func testThatAccessIDIsGenerated() {
        let user = SwiftMockLoader.mockUsers().map(ParticipantsRowType.init)[0]

        let cell = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        cell.sectionName = "Members"
        cell.cellIdentifier = "participants.section.participants.cell"
        cell.configure(with: user, conversation: conversation, showSeparator: true)
        XCTAssertEqual(cell.accessibilityIdentifier, "Members - participants.section.participants.cell")
    }

}
