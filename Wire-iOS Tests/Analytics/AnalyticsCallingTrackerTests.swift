// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import XCTest
@testable import Wire

final class AnalyticsCallingTrackerTests: XCTestCase, CoreDataFixtureTestHelper {

    var sut: AnalyticsCallingTracker!
    var analytics: Analytics!
    var coreDataFixture: CoreDataFixture!
    var mockConversation: ZMConversation!

    let clientId1: String = "ClientId1"
    let clientId2: String = "ClientId2"

    func callParticipant(clientId: String, videoState: VideoState) -> CallParticipant {
        return CallParticipant(user: otherUser, clientId: clientId, state: .connected(videoState: videoState, microphoneState: .unmuted), activeSpeakerState: .inactive)
    }

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()

        mockConversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC, otherUser: otherUser)

        analytics = Analytics(optedOut: true)
        sut = AnalyticsCallingTracker(analytics: analytics)
    }

    override func tearDown() {
        sut = nil
        analytics = nil
        coreDataFixture = nil
        mockConversation = nil

        super.tearDown()
    }

    func testThatMultipleScreenSharingEventFromDifferentClientsCanBeTagged() {
        // GIVEN
        XCTAssert(sut.screenSharingStartTimes.isEmpty)

        // WHEN
        sut.callParticipantsDidChange(conversation: mockConversation, participants: [callParticipant(clientId: clientId1, videoState: .screenSharing)])

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 1)

        // WHEN
        sut.callParticipantsDidChange(conversation: mockConversation, participants: [callParticipant(clientId: clientId2, videoState: .screenSharing)])

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 2)
    }

    func testThatStopStateRemovesAnItemFromScreenSharingInfos() {
        // GIVEN
        XCTAssert(sut.screenSharingStartTimes.isEmpty)

        // WHEN
        participantStartScreenSharing(callParticipant: callParticipant(clientId: clientId1, videoState: .screenSharing))
        participantStoppedVideo(callParticipant: callParticipant(clientId: clientId1, videoState: .stopped))

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 0)
    }

    func testThatMultipleScreenShareEventsCanBeTagged() {
        // GIVEN
        XCTAssert(sut.screenSharingStartTimes.isEmpty)

        // WHEN
        participantStartScreenSharing(callParticipant: callParticipant(clientId: clientId1, videoState: .screenSharing))
        participantStoppedVideo(callParticipant: callParticipant(clientId: clientId1, videoState: .stopped))

        // start screen sharing again
        participantStartScreenSharing(callParticipant: callParticipant(clientId: clientId1, videoState: .screenSharing))

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 1)

        // WHEN
        participantStoppedVideo(callParticipant: callParticipant(clientId: clientId1, videoState: .stopped))

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 0)
    }

    func testThatMultipleParticipantsScreenShareEventsCanBeTagged() {
        // GIVEN
        XCTAssert(sut.screenSharingStartTimes.isEmpty)

        // WHEN
        participantStartScreenSharing(callParticipant: callParticipant(clientId: clientId1, videoState: .screenSharing))
        participantStartScreenSharing(callParticipant: callParticipant(clientId: clientId2, videoState: .screenSharing))

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 2)

        // WHEN
        participantStoppedVideo(callParticipant: callParticipant(clientId: clientId1, videoState: .stopped))

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 1)

        // WHEN
        participantStoppedVideo(callParticipant: callParticipant(clientId: clientId2, videoState: .stopped))

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 0)
    }

    func testThatMultipleScreenShareEventsWouldNotBeTagged() {
        // GIVEN
        XCTAssert(sut.screenSharingStartTimes.isEmpty)

        // WHEN
        participantStartScreenSharing(callParticipant: callParticipant(clientId: clientId1, videoState: .screenSharing))
        participantStartScreenSharing(callParticipant: callParticipant(clientId: clientId1, videoState: .screenSharing))

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 1)

        // WHEN
        participantStoppedVideo(callParticipant: callParticipant(clientId: clientId1, videoState: .stopped))

        // THEN
        XCTAssertEqual(sut.screenSharingStartTimes.count, 0)
    }

    private func participantStartScreenSharing(callParticipant: CallParticipant) {
        sut.callParticipantsDidChange(conversation: mockConversation, participants: [callParticipant])
    }

    private func participantStoppedVideo(callParticipant: CallParticipant) {
        // insert an mock callInfo
        let callInfo = CallInfo(connectingDate: Date(), establishedDate: nil, maximumCallParticipants: 1, toggledVideo: false, outgoing: true, video: true)
        sut.callInfos[mockConversation.remoteIdentifier!] = callInfo

        sut.callParticipantsDidChange(conversation: mockConversation, participants: [callParticipant])

    }

}
