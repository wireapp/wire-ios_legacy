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

final class CallHapticsControllerTests: XCTestCase {
    
    private var sut: CallHapticsController!
    private var generator: MockCallHapticsGenerator!
    
    override func setUp() {
        super.setUp()
        generator = MockCallHapticsGenerator()
        sut = CallHapticsController(hapticGenerator: generator)
    }
    
    override func tearDown() {
        sut = nil
        generator = nil
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
        let (first, second) = (UUID.create(), UUID.create())
        sut.updateParticipants([(first, .connected(videoState: .started))])
        
        // when
        generator.reset()
        sut.updateParticipants([
            (first, .connected(videoState: .started)),
            (second, .connected(videoState: .started))
        ])
        
        // then
        XCTAssertEqual(generator.triggeredEvents, [.join])
    }
    
    func testThatItTriggersCorrectEventWhenAParticipantLeaves() {
        // given
        let (first, second) = (UUID.create(), UUID.create())
        sut.updateParticipants([
            (first, .connected(videoState: .started)),
            (second, .connected(videoState: .started))
        ])

        // when
        generator.reset()
        sut.updateParticipants([(second, .connected(videoState: .started))])
        
        // then
        XCTAssertEqual(generator.triggeredEvents, [.leave])
    }
    
    func testThatItTriggersCorrectEventWhenAParticipantTurnsOnHerVideoStream() {
        // given
        let first = UUID.create()
        sut.updateParticipants([
            (first, .connected(videoState: .stopped))
        ])
        
        // when
        generator.reset()
        sut.updateParticipants([
            (first, .connected(videoState: .started))
        ])
        
        // then
        XCTAssertEqual(generator.triggeredEvents, [.toggleVideo])
    }
    
    func testThatItTriggersCorrectEventWhenAParticipantTurnsOffHerVideoStream() {
        // given
        let first = UUID.create()
        sut.updateParticipants([
            (first, .connected(videoState: .started))
        ])
        
        // when
        generator.reset()
        sut.updateParticipants([
            (first, .connected(videoState: .stopped))
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
    
    func testThatItDoesNotTriggersAnEventWhenTheParticipantsDoNotChange() {
        // given
        let (first, second) = (UUID.create(), UUID.create())
        sut.updateParticipants([
            (first, .connected(videoState: .started)),
            (second, .connected(videoState: .started))
        ])
        
        // when
        generator.reset()
        sut.updateParticipants([
            (first, .connected(videoState: .started)),
            (second, .connected(videoState: .started))
        ])
        
        // then
        XCTAssert(generator.triggeredEvents.isEmpty)
    }
    
    func testThatItDoesNotTriggersAnEventWhenTheAParticipantsVideoStateDoesNotChange() {
        // given
        let first = UUID.create()
        sut.updateParticipants([
            (first, .connected(videoState: .started))
        ])
        
        // when
        generator.reset()
        sut.updateParticipants([
            (first, .connected(videoState: .started))
        ])
        
        // then
        XCTAssert(generator.triggeredEvents.isEmpty)
    }

}
