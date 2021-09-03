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
import SnapshotTesting

final class CallInfoRootViewControllerTests: XCTestCase {

    var sut: CallInfoRootViewController!
    var mockSelfUser: MockUserType!
    var mockOtherUser: MockUserType!
    var mockUsers: [MockUserType]!

    override func setUp() {
        super.setUp()

        mockOtherUser = MockUserType.createConnectedUser(name: "Bruno", inTeam: nil)
        mockSelfUser = MockUserType.createSelfUser(name: "Alice")
        mockUsers = SwiftMockLoader.mockUsers()
        CallingConfiguration.config = .largeConferenceCalls
    }

    override func tearDown() {
        sut = nil
        mockSelfUser = nil
        mockOtherUser = nil
        mockUsers = nil
        CallingConfiguration.resetDefaultConfig()

        super.tearDown()
    }

    // MARK: - OneToOne Audio

    func testOneToOneOutgoingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedCBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedVBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedPhoneX() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablished, selfUser: mockSelfUser)

        // then
        _ = verifySnapshot(matching: sut, as: .image(on: SnapshotTesting.ViewImageConfig.iPhoneX))
    }

    func testOneToOneAudioEstablishedPoorConnection() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedPoorNetwork, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - OneToOne Video

    func testOneToOneIncomingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneVideoConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneVideoEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - Group Audio

    func testGroupOutgoingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_SmallGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, groupSize: .small, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished(mockUsers: SwiftMockLoader.mockUsers()), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_LargeGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser,
                                          groupSize: .large, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished(mockUsers: SwiftMockLoader.mockUsers()), selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    // MARK: - Group Video

    func testGroupIncomingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupOutgoingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupOutgoingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablished(mockUsers: mockUsers), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedScreenSharing() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedScreenSharing, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedPoorConnection() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedPoorConnection, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedCBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedVBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - Missing Video Permissions

    func testGroupVideoUndeterminedVideoPermissions() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoIncomingUndeterminedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    func testGroupVideoDeniedVideoPermissions() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoIncomingDeniedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

}
