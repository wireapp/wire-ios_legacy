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

fileprivate class MockCallHapticsGenerator: CallHapticsGeneratorType {
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
    private var clientId1: String = "ClientId1"
    private var clientId2: String = "ClientId2"
    
    override func setUp() {
        super.setUp()
        generator = MockCallHapticsGenerator()
        sut = CallHapticsController(hapticGenerator: generator)
        firstUser = ZMUser.insertNewObject(in: uiMOC)
        firstUser.remoteIdentifier = UUID()
        secondUser = ZMUser.insertNewObject(in: uiMOC)
        secondUser.remoteIdentifier = UUID()
    }
    
    override func tearDown() {
        sut = nil
        generator = nil
        firstUser = nil
        secondUser = nil
        super.tearDown()
    }
    
    func testThatItTriggersCorrectEventWhenStartingACall() {
        // when
        sut.updateCallState(.established)
        
        // then
        XCTAssertEqual(generator.triggeredEvents, [.start])
    }
    
    func testThatItTriggersCorrectEventWhenEndingACall() {
        // when
        sut.updateCallState(.terminating(reason: .normal))
        
        // then
        XCTAssertEqual(generator.triggeredEvents, [.end])
    }
    
    func testThatItTriggersCorrectEventWhenAParticipantJoins() {
        // given
    
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted))
        let second = CallParticipant(user: secondUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted))
        
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
    
    func testThatItTriggersCorrectEventWhenTheSameUserJoinsWithDifferentDevice() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted))
        let second = CallParticipant(user: firstUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted))
        
        sut.updateParticipants([first])

        //when
        generator.reset()
        sut.updateParticipants([
            first,
            second
        ])
        
        //then
        XCTAssertEqual(generator.triggeredEvents, [.join])
    }
    
    func testThatItTriggersCorrectEventWhenAParticipantLeaves() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted))
        let second = CallParticipant(user: secondUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted))
       
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
    
    func testThatItTriggersCorrectEventWhenAUserLeavesFromOneOfItsDevices() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted))
        let second = CallParticipant(user: firstUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted))
        
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
    
    func testThatItTriggersCorrectEventWhenAParticipantTurnsOnHerVideoStream() {
        // given
        let stopped = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .stopped, microphoneState: .unmuted))
        let started = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted))
        sut.updateParticipants([stopped])
        
        // when
        generator.reset()
        sut.updateParticipants([started])
        
        // then
        XCTAssertEqual(generator.triggeredEvents, [.toggleVideo])
    }
    
    func testThatItTriggersCorrectEventWhenAParticipantTurnsOffHerVideoStream() {
        // given
        let stopped = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .stopped, microphoneState: .unmuted))
        let started = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted))
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
    
    func testThatItDoesNotTriggersAnEventWhenTheCallStateDoesNotChange() {
        // given
        sut.updateCallState(.established)
        
        // when
        generator.reset()
        sut.updateCallState(.established)
        
        // then
        XCTAssert(generator.triggeredEvents.isEmpty)
    }
    
    func testThatItDoesNotTriggerAnEventWhenTheParticipantsDoNotChange() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted))
        let second = CallParticipant(user: secondUser, clientId: clientId2, state: .connected(videoState: .started, microphoneState: .unmuted))

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
    
    func testThatItDoesNotTriggerAnEventWhenTheParticipantsVideoStateDoesNotChange() {
        // given
        let first = CallParticipant(user: firstUser, clientId: clientId1, state: .connected(videoState: .started, microphoneState: .unmuted))

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
