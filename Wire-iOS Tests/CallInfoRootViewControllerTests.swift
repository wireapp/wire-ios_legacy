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

final class CallInfoRootViewControllerTests: XCTestCase, CoreDataFixtureTestHelper {

    var coreDataFixture: CoreDataFixture!
    var sut: CallInfoRootViewController!
    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()

        mockSelfUser = MockUserType.createSelfUser(name: "Bob")
        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        sut = nil
        coreDataFixture = nil
        mockSelfUser = nil

        super.tearDown()
    }

    // MARK: - OneToOne Audio

    func testOneToOneOutgoingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneOutgoingAudioRinging, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioConnecting, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablished, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedCBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedCBR, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }
    
    func testOneToOneAudioEstablishedVBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedVBR, user: mockSelfUser)
        
        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    @available(iOS 11.0, *)
    func testOneToOneAudioEstablishedPhoneX() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablished, user: mockSelfUser)

        // then
        _ = verifySnapshot(matching: sut, as: .image(on: SnapshotTesting.ViewImageConfig.iPhoneX))
    }

    func testOneToOneAudioEstablishedPoorConnection() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedPoorNetwork, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - OneToOne Video

    func testOneToOneIncomingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneIncomingVideoRinging, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneVideoConnecting, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneVideoEstablished, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - Group Audio

    func testGroupOutgoingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupOutgoingAudioRinging, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioConnecting, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_SmallGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser, groupSize: .small)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_LargeGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser, groupSize: .large)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished, user: mockSelfUser)

        // then
        verify(matching: sut)
    }

    // MARK: - Group Video

    func testGroupIncomingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupIncomingVideoRinging, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupOutgoingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupOutgoingVideoRinging, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablished, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }
    
    func testGroupVideoEstablishedScreenSharing() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedScreenSharing, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedPoorConnection() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedPoorConnection, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedCBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedCBR, user: mockSelfUser)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedVBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedVBR, user: mockSelfUser)
        
        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    
    // MARK: - Missing Video Permissions

    func testGroupVideoUndeterminedVideoPermissions() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoIncomingUndeterminedPermissions, user: mockSelfUser)

        //then
        verify(matching: sut)
    }

    func testGroupVideoDeniedVideoPermissions() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoIncomingDeniedPermissions, user: mockSelfUser)

        //then
        verify(matching: sut)
    }

}
