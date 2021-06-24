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

private class MockCallHapticsGenerator: CallHapticsGeneratorType {
    var triggeredEvents = [CallHapticsEvent]()

    func trigger(event: CallHapticsEvent) {
        triggeredEvents.append(event)
    }

    func reset() {
        triggeredEvents.removeAll()
    }
}

final class CallHapticsControllerTests: ZMSnapshotTestCase {

    private var sut: CallHapticsController!
    private var generator: MockCallHapticsGenerator!
    private var firstUser: ZMUser!
    private var secondUser: ZMUser!
    private var thirdUser: ZMUser!
    private var clientId1: String = "ClientId1"
    private var clientId2: String = "ClientId2"
    private var clientId3: String = "ClientId3"

    override func setUp() {
        super.setUp()
        generator = MockCallHapticsGenerator()
        sut = CallHapticsController(hapticGenerator: generator)
        firstUser = ZMUser.insertNewObject(in: uiMOC)
        firstUser.remoteIdentifier = UUID()
        secondUser = ZMUser.insertNewObject(in: uiMOC)
        secondUser.remoteIdentifier = UUID()
        thirdUser = ZMUser.insertNewObject(in: uiMOC)
        thirdUser.remoteIdentifier = UUID()
    }

    override func tearDown() {
        sut = nil
        generator = nil
        firstUser = nil
        secondUser = nil
        thirdUser = nil
        super.tearDown()
    }

    func testThat_ItTriggersCorrectEvent_WhenStartingACall() {
        // when
        sut.updateCallState(.established)

        // then
        XCTAssertEqual(generator.triggeredEvents, [.start])
    }

    func testThat_ItTriggersCorrectEvent_WhenEndingACall() {
        // when
        sut.updateCallState(.terminating(reason: .normal))

        // then
        XCTAssertEqual(generator.triggeredEvents, [.end])
    }

    func testThat_ItTriggersCorrectEvent_WhenAParticipantJoins() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let second = CallParticipant(user: secondUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)

        sut.updateParticipants([first])

        // when
        generator.reset()
        sut.updateParticipants([
            first,
            second
        ])

        // then
        XCTAssertEqual(generator.triggeredEvents, [.join])
    }

    func testThat_ItTriggersCorrectEvent_WhenTheSameUserJoins_WithDifferentDevice() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let second = CallParticipant(user: firstUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)

        sut.updateParticipants([first])

        // when
        generator.reset()
        sut.updateParticipants([
            first,
            second
        ])

        // then
        XCTAssertEqual(generator.triggeredEvents, [.join])
    }

    func testThat_ItDoesNotTriggerAnEvent_WhenAUserJoins_GroupCall() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let second = CallParticipant(user: secondUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let third = CallParticipant(user: thirdUser, clientId: clientId3, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)

        sut.updateParticipants([
            first,
            second
        ])

        // when
        generator.reset()
        sut.updateParticipants([first, second, third])

        // then
        XCTAssertTrue(generator.triggeredEvents.isEmpty)
    }

    func testThat_ItTriggersCorrectEvent_WhenAParticipantLeaves() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let second = CallParticipant(user: secondUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)

        sut.updateParticipants([
            first,
            second
        ])

        // when
        generator.reset()
        sut.updateParticipants([second])

        // then
        XCTAssertEqual(generator.triggeredEvents, [.leave])
    }

    func testThat_ItTriggersCorrectEvent_WhenAUserLeaves_FromOneOfItsDevices() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let second = CallParticipant(user: firstUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)

        sut.updateParticipants([
            first,
            second
        ])

        // when
        generator.reset()
        sut.updateParticipants([second])

        // then
        XCTAssertEqual(generator.triggeredEvents, [.leave])
    }

    func testThat_ItDoesNotTriggerAnEvent_WhenAUserLeaves_GroupCall() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let second = CallParticipant(user: secondUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let third = CallParticipant(user: thirdUser, clientId: clientId3, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)

        sut.updateParticipants([
            first,
            second,
            third
        ])

        // when
        generator.reset()
        sut.updateParticipants([first, second])

        // then
        XCTAssertTrue(generator.triggeredEvents.isEmpty)
    }

    func testThat_ItTriggersCorrectEvent_WhenAParticipantTurnsOnHerVideoStream() {
        // given
        let stopped = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .stopped, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let started = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        sut.updateParticipants([stopped])

        // when
        generator.reset()
        sut.updateParticipants([started])

        // then
        XCTAssertEqual(generator.triggeredEvents, [.toggleVideo])
    }

    func testThat_ItTriggersCorrectEvent_WhenAParticipantTurnsOffHerVideoStream() {
        // given
        let stopped = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .stopped, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let started = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        sut.updateParticipants([
            started
        ])

        // when
        generator.reset()
        sut.updateParticipants([
            stopped
        ])

        // then
        XCTAssertEqual(generator.triggeredEvents, [.toggleVideo])
    }

    func testThat_ItDoesNotTriggersAnEvent_WhenTheCallStateDoesNotChange() {
        // given
        sut.updateCallState(.established)

        // when
        generator.reset()
        sut.updateCallState(.established)

        // then
        XCTAssert(generator.triggeredEvents.isEmpty)
    }

    func testThat_ItDoesNotTriggerAnEvent_WhenTheParticipantsDoNotChange() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)
        let second = CallParticipant(user: secondUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)

        sut.updateParticipants([
            first,
            second
        ])

        // when
        generator.reset()
        sut.updateParticipants([
           first,
           second
        ])

        // then
        XCTAssert(generator.triggeredEvents.isEmpty)
    }

    func testThat_ItDoesNotTriggerAnEvent_WhenTheParticipantsVideoStateDoesNotChange() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted), activeSpeakerState: .inactive)

        sut.updateParticipants([
            first
        ])

        // when
        generator.reset()
        sut.updateParticipants([
            first
        ])

        // then
        XCTAssert(generator.triggeredEvents.isEmpty)
    }

}
