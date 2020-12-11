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

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        sut = nil
        coreDataFixture = nil

        super.tearDown()
    }

    // MARK: - OneToOne Audio

    func testOneToOneOutgoingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneOutgoingAudioRinging)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioConnecting)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablished)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneAudioEstablishedCBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedCBR)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }
    
    func testOneToOneAudioEstablishedVBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedVBR)
        
        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    @available(iOS 11.0, *)
    func testOneToOneAudioEstablishedPhoneX() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablished)

        // then
        _ = verifySnapshot(matching: sut, as: .image(on: SnapshotTesting.ViewImageConfig.iPhoneX))
    }

    func testOneToOneAudioEstablishedPoorConnection() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedPoorNetwork)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - OneToOne Video

    func testOneToOneIncomingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneIncomingVideoRinging)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneVideoConnecting)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testOneToOneVideoEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.oneToOneVideoEstablished)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    // MARK: - Group Audio

    func testGroupOutgoingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupOutgoingAudioRinging)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioConnecting)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_SmallGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser, groupSize: .small)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupAudioEstablished_LargeGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser, groupSize: .large)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished)

        // then
        verify(matching: sut)
    }

    // MARK: - Group Video

    func testGroupIncomingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupIncomingVideoRinging)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupOutgoingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupOutgoingVideoRinging)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablished)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }
    
    func testGroupVideoEstablishedScreenSharing() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedScreenSharing)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedPoorConnection() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedPoorConnection)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedCBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedCBR)

        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    func testGroupVideoEstablishedVBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedVBR)
        
        // then
        verifyAllIPhoneSizes(matching: sut)
    }

    
    // MARK: - Missing Video Permissions

    func testGroupVideoUndeterminedVideoPermissions() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoIncomingUndeterminedPermissions)

        //then
        verify(matching: sut)
    }

    func testGroupVideoDeniedVideoPermissions() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        sut = CallInfoRootViewController(configuration: fixture.groupVideoIncomingDeniedPermissions)

        //then
        verify(matching: sut)
    }

}
