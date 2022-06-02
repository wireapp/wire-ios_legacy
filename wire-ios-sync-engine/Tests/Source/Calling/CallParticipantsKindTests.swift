//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

@testable import WireSyncEngine

class CallParticipantsKindTests: XCTestCase {
    var client: AVSClient!

    override func setUp() {
        super.setUp()
        client = AVSClient(userId: AVSIdentifier.stub,
                           clientId: UUID().transportString())
    }

    private var realTimeActiveSpeaker: AVSActiveSpeakersChange.ActiveSpeaker {
        AVSActiveSpeakersChange.ActiveSpeaker(
            userId: client.userId,
            clientId: client.clientId,
            audioLevel: 0,
            audioLevelNow: 100
        )
    }

    private var smoothedActiveSpeaker: AVSActiveSpeakersChange.ActiveSpeaker {
        AVSActiveSpeakersChange.ActiveSpeaker(
            userId: client.userId,
            clientId: client.clientId,
            audioLevel: 100,
            audioLevelNow: 0
        )
    }

    func testThat_RealTimeActiveSpeaker_IsActive_WhenCase_All() {
        XCTAssertEqual(
            CallParticipantsListKind.all.state(ofActiveSpeaker: realTimeActiveSpeaker),
            ActiveSpeakerState.active(audioLevelNow: 100)
        )
    }

    func testThat_RealTimeActiveSpeaker_IsInactive_WhenCase_SmoothedActiveSpeakers() {
        XCTAssertEqual(
            CallParticipantsListKind.smoothedActiveSpeakers.state(ofActiveSpeaker: realTimeActiveSpeaker),
            ActiveSpeakerState.inactive
        )
    }

    func testThat_SmoothedActiveSpeaker_IsInactive_WhenCase_All() {
        XCTAssertEqual(
            CallParticipantsListKind.all.state(ofActiveSpeaker: smoothedActiveSpeaker),
            ActiveSpeakerState.inactive
        )
    }

    func testThat_SmoothedActiveSpeaker_IsActive_WhenCase_SmoothedActiveSpeakers() {
        XCTAssertEqual(
            CallParticipantsListKind.smoothedActiveSpeakers.state(ofActiveSpeaker: smoothedActiveSpeaker),
            ActiveSpeakerState.active(audioLevelNow: 0)
        )
    }

}
