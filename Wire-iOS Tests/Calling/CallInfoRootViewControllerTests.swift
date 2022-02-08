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

    func testOneToOneClassifiedOutgoingAudioRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedOutgoingAudioRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneClassifiedAudioConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedAudioConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneClassifiedAudioEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedAudioEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedAudioEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedAudioEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedCBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneClassifiedAudioEstablishedCBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedAudioEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedAudioEstablishedCBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedAudioEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedVBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneAudioEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneClassifiedAudioEstablishedVBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedAudioEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedAudioEstablishedVBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedAudioEstablishedVBR, selfUser: mockSelfUser)

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

    func testOneToOneClassifiedAudioEstablishedPoorConnection() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedAudioEstablishedPoorNetwork, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedAudioEstablishedPoorConnection() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedAudioEstablishedPoorNetwork, selfUser: mockSelfUser)

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

    func testOneToOneClassifiedIncomingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedIncomingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneVideoConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneClassifiedVideoConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedVideoConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedVideoConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedVideoConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneVideoEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneClassifiedVideoEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneClassifiedVideoEstablished, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneNotClassifiedVideoEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.oneToOneNotClassifiedVideoEstablished, selfUser: mockSelfUser)

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

    func testGroupClassifiedOutgoingAudioRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedOutgoingAudioRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedOutgoingAudioRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupClassifiedAudioConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedAudioConnecting, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedAudioConnecting() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedAudioConnecting, selfUser: mockSelfUser)

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

    func testGroupClassifiedIncomingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedIncomingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedIncomingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupOutgoingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupOutgoingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupClassifiedOutgoingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedOutgoingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedOutgoingVideoRinging() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedOutgoingVideoRinging, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablished(mockUsers: mockUsers), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupClassifiedVideoEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedVideoEstablished(mockUsers: mockUsers), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedVideoEstablished() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedVideoEstablished(mockUsers: mockUsers), selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedScreenSharing() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedScreenSharing, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupClassifiedVideoEstablishedScreenSharing() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedVideoEstablishedScreenSharing, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedVideoEstablishedScreenSharing() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedVideoEstablishedScreenSharing, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedPoorConnection() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedPoorConnection, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupClassifiedVideoEstablishedPoorConnection() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedVideoEstablishedPoorConnection, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedVideoEstablishedPoorConnection() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedVideoEstablishedPoorConnection, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedCBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupClassifiedVideoEstablishedCBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedVideoEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedVideoEstablishedCBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedVideoEstablishedCBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedVBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupClassifiedVideoEstablishedVBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedVideoEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupNotClassifiedVideoEstablishedVBR() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedVideoEstablishedVBR, selfUser: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }


    // MARK: - Landscape
    func disable_testOneToOneAudioOutgoingLandscape() {
        testLandscape(configuration: defaultFixture.oneToOneOutgoingAudioRinging)
    }

    func disable_testOneToOneAudioIncomingLandscape() {
        testLandscape(configuration: defaultFixture.oneToOneIncomingAudioRinging)
    }

    func disable_testOneToOneAudioEstablishedLandscape() {
        testLandscape(configuration: defaultFixture.oneToOneAudioEstablished)
    }

    func testLandscape(configuration: CallInfoViewControllerInput, testName: String = #function) {
        sut = CallInfoRootViewController(configuration: configuration, selfUser: mockSelfUser)
        XCUIDevice.shared.orientation = .landscapeLeft
        let mockParentViewController = UIViewController()
        mockParentViewController.addToSelf(sut)
        mockParentViewController.setOverrideTraitCollection(UITraitCollection(verticalSizeClass: .compact), forChild: sut)

        // then
        verifyAllIPhoneSizes(matching: mockParentViewController, orientation: .landscape, testName: testName)
    }

    // MARK: - Missing Video Permissions

    func testGroupVideoUndeterminedVideoPermissions() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoIncomingUndeterminedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    func testGroupClassifiedVideoUndeterminedVideoPermissions() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedVideoIncomingUndeterminedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    func testGroupNotClassifiedVideoUndeterminedVideoPermissions() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedVideoIncomingUndeterminedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    func testGroupVideoDeniedVideoPermissions() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupVideoIncomingDeniedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    func testGroupClassifiedVideoDeniedVideoPermissions() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupClassifiedVideoIncomingDeniedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

    func testGroupNotClassifiedVideoDeniedVideoPermissions() {
        // when
        sut = CallInfoRootViewController(configuration: defaultFixture.groupNotClassifiedVideoIncomingDeniedPermissions, selfUser: mockSelfUser)

        // then
        verify(matching: sut)
    }

}
