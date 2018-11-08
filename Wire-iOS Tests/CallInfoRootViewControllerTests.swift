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

class CallInfoRootViewControllerTests: CoreDataSnapshotTestCase {

    // MARK: - OneToOne Audio
    
    func testOneToOneIncomingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneIncomingAudioRinging)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testOneToOneOutgoingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneOutgoingAudioRinging)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testOneToOneAudioConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioConnecting)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testOneToOneAudioEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablished)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testOneToOneAudioEstablishedCBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedCBR)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    @available(iOS 11.0, *)
    func testOneToOneAudioEstablishedPhoneX() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablished)
        
        // then
        verifySafeAreas(viewController: sut)
    }

    func testOneToOneAudioEstablishedPoorConnection() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneAudioEstablishedPoorNetwork)

        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }

    
    // MARK: - OneToOne Video
    
    func testOneToOneIncomingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneIncomingVideoRinging)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testOneToOneVideoConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneVideoConnecting)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testOneToOneVideoEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.oneToOneVideoEstablished)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    // MARK: - Group Audio
    
    func testGroupOutgoingAudioRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupOutgoingAudioRinging)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testGroupAudioConnecting() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupAudioConnecting)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testGroupAudioEstablished_SmallGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser, groupSize: .small)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testGroupAudioEstablished_LargeGroup() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser, groupSize: .large)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupAudioEstablished)
        
        // then
        verifyInAllDeviceSizes(view: sut.view)
    }
    
    // MARK: - Group Video
    
    func testGroupIncomingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupIncomingVideoRinging)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testGroupOutgoingVideoRinging() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupOutgoingVideoRinging)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }

    func testGroupVideoEstablished() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablished)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }

    func testGroupVideoEstablishedPoorConnection() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedPoorConnection)

        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
    func testGroupVideoEstablishedCBR() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupVideoEstablishedCBR)
        
        // then
        verifyInAllIPhoneSizes(view: sut.view)
    }

    // MARK: - Missing Video Permissions

    func testGroupVideoUndeterminedVideoPermissions() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupVideoIncomingUndeterminedPermissions)

        //then
        verifyInAllIPhoneSizes(view: sut.view)
    }

    func testGroupVideoDeniedVideoPermissions() {
        // given
        let fixture = CallInfoTestFixture(otherUser: otherUser)

        // when
        let sut = CallInfoRootViewController(configuration: fixture.groupVideoIncomingDeniedPermissions)

        //then
        verifyInAllIPhoneSizes(view: sut.view)
    }
    
}
