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
    var defaultFixture: CallInfoTestFixture!

    override func setUp() {
        super.setUp()

        mockOtherUser = MockUserType.createConnectedUser(name: "Bruno", inTeam: nil)
        mockSelfUser = MockUserType.createSelfUser(name: "Alice")
        mockUsers = SwiftMockLoader.mockUsers()
        defaultFixture = CallInfoTestFixture(otherUser: mockOtherUser, selfUser: mockSelfUser, mockUsers: mockUsers)
        CallingConfiguration.config = .largeConferenceCalls
    }

    override func tearDown() {
        sut = nil
        mockSelfUser = nil
        mockOtherUser = nil
        mockUsers = nil
        defaultFixture = nil
        CallingConfiguration.resetDefaultConfig()

        super.tearDown()
    }

    // MARK: - OneToOne Audio

    func testOneToOneOutgoingAudioRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedCBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedVBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedPhoneX() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablished, selfUser: mockSelfUser)

        // then
        _ = verifySnapshot(matching: sut,
                           as: .image(on: SnapshotTesting.ViewImageConfig.iPhoneX),
                           snapshotDirectory: snapshotDirectory(file: #file))
    }

    func testOneToOneAudioEstablishedPoorConnection() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablishedPoorNetwork, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - OneToOne Video

    func testOneToOneIncomingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneVideoConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneVideoEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - Group Audio

    func testGroupOutgoingAudioRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_SmallGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser, selfUser: mockSelfUser, groupSize: .small, mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished(mockUsers: SwiftMockLoader.mockUsers()), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_LargeGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: mockOtherUser,
                                          selfUser: mockSelfUser,
                                          groupSize: .large,
                                          mockUsers: mockUsers)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished(mockUsers: SwiftMockLoader.mockUsers()), selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    // MARK: - Group Video

    func testGroupIncomingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupOutgoingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupOutgoingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablished(mockUsers: mockUsers), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedScreenSharing() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedScreenSharing, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedPoorConnection() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedPoorConnection, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedCBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedVBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - Missing Video Permissions

    func testGroupVideoUndeterminedVideoPermissions() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoIncomingUndeterminedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    func testGroupVideoDeniedVideoPermissions() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoIncomingDeniedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

}
