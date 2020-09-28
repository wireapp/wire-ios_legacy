
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


final class AnalyticsCallingTrackerTests: XCTestCase , CoreDataFixtureTestHelper {
    
    var sut: AnalyticsCallingTracker!
    var analytics: Analytics!
    var coreDataFixture: CoreDataFixture!
    var mockConversation: ZMConversation!

    let clientId1: String = "ClientId1"
    var callParticipant1: CallParticipant!

    override func setUp() {
        super.setUp()
        
        coreDataFixture = CoreDataFixture()

        mockConversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC, otherUser: otherUser)

        analytics = Analytics(optedOut: true)
        sut = AnalyticsCallingTracker(analytics: analytics)
        
        
        callParticipant1 = CallParticipant(user: otherUser, clientId: clientId1, state: .connected(videoState: .screenSharing, microphoneState: .unmuted))
    }
    
    override func tearDown() {
        sut = nil
        analytics = nil
        coreDataFixture = nil
        mockConversation = nil
        callParticipant1 = nil
        
        super.tearDown()
    }

    
    func testThatMultipleScreenSharingEventFromDifferentClientsCanBeTagged() {
        //GIVEN
        XCTAssert(sut.screenSharingInfos.isEmpty)

        //WHEN
        sut.callParticipantsDidChange(conversation: mockConversation, participants: [callParticipant1])

        //THEN
        XCTAssertEqual(sut.screenSharingInfos.count, 1)

        //WHEN
        let clientId2: String = "ClientId2"
        
        let callParticipant2 = CallParticipant(user: otherUser, clientId: clientId2, state: .connected(videoState: .screenSharing, microphoneState: .unmuted))

        sut.callParticipantsDidChange(conversation: mockConversation, participants: [callParticipant2])

        //THEN
        XCTAssertEqual(sut.screenSharingInfos.count, 2)
    }

    func testThatStopStateRemovesAnItemFromScreenSharingInfos() {
        //GIVEN
        XCTAssert(sut.screenSharingInfos.isEmpty)
        
        //WHEN
        participantStartScreenSharing()
        participantStoppedVideo()
        
        //THEN
        XCTAssertEqual(sut.screenSharingInfos.count, 0)
    }
    
    private func participantStartScreenSharing() {
        sut.callParticipantsDidChange(conversation: mockConversation, participants: [callParticipant1])
    }
    
    private func participantStoppedVideo() {
        let callParticipantStopped = CallParticipant(user: otherUser, clientId: clientId1, state: .connected(videoState: .stopped, microphoneState: .unmuted))
        
        let callInfo = CallInfo(connectingDate: Date(), establishedDate: nil, maximumCallParticipants: 1, toggledVideo: false, outgoing: true, video: true)
        sut.callInfos[mockConversation.remoteIdentifier!] = callInfo
        
        sut.callParticipantsDidChange(conversation: mockConversation, participants: [callParticipantStopped])

    }

    func testThatMultipleScreenShareCanBeTagged() {
        //GIVEN
        XCTAssert(sut.screenSharingInfos.isEmpty)
        
        //WHEN
        participantStartScreenSharing()
        participantStoppedVideo()

        //start screen sharing again
        participantStartScreenSharing()
        
        //THEN
        XCTAssertEqual(sut.screenSharingInfos.count, 1)

        //WHEN
        participantStoppedVideo()

        //THEN
        XCTAssertEqual(sut.screenSharingInfos.count, 0)
    }
}


