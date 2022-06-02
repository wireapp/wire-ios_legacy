//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import Foundation
@testable import WireSyncEngine

class VoiceChannelV3Tests: MessagingTest {

    var wireCallCenterMock: WireCallCenterV3Mock?
    var conversation: ZMConversation?
    var sut: VoiceChannelV3!

    override func setUp() {
        super.setUp()

        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()

        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation?.remoteIdentifier = UUID.create()

        wireCallCenterMock = WireCallCenterV3Mock(userId: selfUser.avsIdentifier, clientId: selfClient.remoteIdentifier!, uiMOC: uiMOC, flowManager: FlowManagerMock(), transport: WireCallCenterTransportMock())

        uiMOC.zm_callCenter = wireCallCenterMock

        sut = VoiceChannelV3(conversation: conversation!)
    }

    override func tearDown() {
        super.tearDown()

        wireCallCenterMock = nil
    }

    func testThatItStartsACall_whenTheresNotAnIncomingCall() {
        // given
        wireCallCenterMock?.removeMockActiveCalls()

        // when
        _ = sut.join(video: false)

        // then
        XCTAssertTrue(wireCallCenterMock!.didCallStartCall)
    }

    func testThatItAnswers_whenTheresAnIncomingCall() {
        // given
        wireCallCenterMock?.setMockCallState(.incoming(video: false, shouldRing: false, degraded: false), conversationId: conversation!.avsIdentifier!, callerId: AVSIdentifier.stub, isVideo: false)

        // when
        _ = sut.join(video: false)

        // then
        XCTAssertTrue(wireCallCenterMock!.didCallAnswerCall)
    }

    func testThatItForwardsNetworkQualityFromCallCenter() {
        // given
        let caller = AVSClient(userId: AVSIdentifier.stub, clientId: UUID().transportString())
        wireCallCenterMock?.setMockCallState(.established, conversationId: conversation!.avsIdentifier!, callerId: caller.avsIdentifier, isVideo: false)
        let quality = NetworkQuality.poor
        XCTAssertEqual(sut.networkQuality, .normal)

        // when

        wireCallCenterMock?.handleNetworkQualityChange(conversationId: conversation!.avsIdentifier!, userId: caller.userId, clientId: caller.clientId, quality: quality)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.networkQuality, quality)
    }

    func testThatItReturnsDegradedUser_IfSavedInCallCenter() {
        // Given
        let conversationId = conversation!.avsIdentifier!
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID()

        wireCallCenterMock?.callSnapshots = [
            conversationId: CallSnapshotTestFixture.degradedCallSnapshot(
                conversationId: conversationId,
                user: user,
                callCenter: wireCallCenterMock!
            )
        ]

        // When / Then
        XCTAssert(sut.firstDegradedUser as? ZMUser == user)
    }

    func testThatItUpdatesVideoGridPresentationMode() {
        // Given
        let conversationId = conversation!.avsIdentifier!
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID()

        wireCallCenterMock?.callSnapshots = [
            conversationId: CallSnapshotTestFixture.callSnapshot(
                conversationId: conversationId,
                callCenter: wireCallCenterMock!,
                clients: [])
        ]

        // When
        sut.videoGridPresentationMode = .activeSpeakers

        // Then
        let callSnapshot = wireCallCenterMock?.callSnapshots[conversationId]
        XCTAssert(sut.videoGridPresentationMode == callSnapshot?.videoGridPresentationMode)
    }

    func testThatItReturnsNil_IfNoDegradedUser() {
        XCTAssert(sut.firstDegradedUser == nil)
    }

    func testThatCallInitiatorIsFetchedCorrectly() {
        // Given
        let caller = ZMUser.insertNewObject(in: uiMOC)
        caller.remoteIdentifier = UUID()
        caller.domain = "wire.com"

        wireCallCenterMock?.setMockCallInitiator(
            callerId: AVSIdentifier(identifier: caller.remoteIdentifier, domain: caller.domain),
            conversationId: conversation!.avsIdentifier!
        )

        // When / Then
        XCTAssertEqual(sut.initiator as? ZMUser, caller)
    }
}
