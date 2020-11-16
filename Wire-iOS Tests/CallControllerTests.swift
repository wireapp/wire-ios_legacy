//
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

final class CallControllerTests: XCTestCase, CoreDataFixtureTestHelper {
    
    var coreDataFixture: CoreDataFixture!
    var sut: CallController!
    var router: ActiveCallRouterProtocolMock!
    var conversation: ZMConversation!
    var callConversationProvider: MockCallConversationProvider!
    
    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        router = ActiveCallRouterProtocolMock()
        conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                  otherUser: otherUser)
        callConversationProvider = MockCallConversationProvider()
        sut = CallController()
        sut.callConversationProvider = callConversationProvider
        sut.router = router
    }

    override func tearDown() {
        coreDataFixture = nil
        sut = nil
        router = nil
        conversation = nil
        callConversationProvider = nil
        super.tearDown()
    }
    
    // MARK: - ActiveCall Presentation Tests
    func testThatActiveCallIsPresented_WhenMinimizedCallIsNil() {
        // GIVEN
        let callState: CallState = .established
        sut.callConversationProvider?.priorityCallConversation = conversation
        sut.testHelper_setMinimizedCall(nil)
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(router.presentActiveCallIsCalled)
    }
    
    func testThatActiveCallIsDismissed_WhenPriorityCallConversationIsNil() {
        // GIVEN
        let callState: CallState = .established
        sut.callConversationProvider?.priorityCallConversation = nil
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(router.dismissActiveCallIsCalled)
    }
    
    func testThatActiveCallIsMinimized_WhenPriorityCallConversationIsTheCallConversationMinimized() {
        // GIVEN
        let callState: CallState = .established
        sut.callConversationProvider?.priorityCallConversation = conversation
        sut.testHelper_setMinimizedCall(conversation)
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(router.minimizeCallIsCalled)
    }
    
    // MARK: - CallTopOverlay Presentation Tests
    func testThatCallTopOverlayIsShown_WhenPriorityCallConversationIsNotNil() {
        // GIVEN
        let callState: CallState = .established
        sut.callConversationProvider?.priorityCallConversation = conversation
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(router.showCallTopOverlayIsCalled)
    }
    
    func testThatCallTopOverlayIsHidden_WhenPriorityCallConversationIsNil() {
        // GIVEN
        let callState: CallState = .established
        sut.callConversationProvider?.priorityCallConversation = nil
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(router.hideCallTopOverlayIsCalled)
    }
    
    // MARK: - Version Alert Presentation Tests
    func testThatVersionAlertIsPresented_WhenCallStateIsTerminatedAndReasonIsOutdatedClient() {
        // GIVEN
        let callState: CallState = .terminating(reason: .outdatedClient)
        sut.callConversationProvider?.priorityCallConversation = conversation
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(router.presentUnsupportedVersionAlertIsCalled)
    }
    
    func testThatVersionAlertIsNotPresented_WhenCallStateIsTerminatedAndReasonIsNotOutdatedClient() {
        // GIVEN
        let callState: CallState = .terminating(reason: .canceled)
        sut.callConversationProvider?.priorityCallConversation = conversation
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertFalse(router.presentUnsupportedVersionAlertIsCalled)
    }
    
    func testThatVersionAlertIsNotPresented_WhenCallStateIsNotTerminated() {
        // GIVEN
        let callState: CallState = .established
        sut.callConversationProvider?.priorityCallConversation = conversation
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertFalse(router.presentUnsupportedVersionAlertIsCalled)
    }
    
    // MARK: - Degradation Alert Presentation Tests
    func testThatVersionDegradationAlertIsNotPresented_WhenVoiceChannelHasNotDegradationState() {
        // GIVEN
        let callState: CallState = .established
        sut.callConversationProvider?.priorityCallConversation = conversation
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertFalse(router.presentSecurityDegradedAlertIsCalled)
    }
}

// MARK: - Helpers
extension CallControllerTests {
    private func callController_callCenterDidChange(callState: CallState, conversation: ZMConversation) {
        sut.callCenterDidChange(callState: callState,
                                conversation: conversation,
                                caller: otherUser,
                                timestamp: nil,
                                previousCallState: nil)
    }
}

// MARK: - ActiveCallRouterMock
class ActiveCallRouterProtocolMock: ActiveCallRouterProtocol {
    
    var presentActiveCallIsCalled: Bool = false
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool) {
        presentActiveCallIsCalled = true
    }
    
    var dismissActiveCallIsCalled: Bool = false
    func dismissActiveCall(animated: Bool, completion: Completion?) {
        dismissActiveCallIsCalled = true
        hideCallTopOverlay()
    }
    
    var minimizeCallIsCalled: Bool = false
    func minimizeCall(animated: Bool, completion: (() -> Void)?) {
        minimizeCallIsCalled = true
    }
    
    var showCallTopOverlayIsCalled: Bool = false
    func showCallTopOverlay(for conversation: ZMConversation) {
        showCallTopOverlayIsCalled = true
    }
    
    var hideCallTopOverlayIsCalled: Bool = false
    func hideCallTopOverlay() {
        hideCallTopOverlayIsCalled = true
    }
    
    var presentSecurityDegradedAlertIsCalled: Bool = false
    func presentSecurityDegradedAlert(degradedUser: UserType?) {
        presentSecurityDegradedAlertIsCalled = true
    }
    
    var presentUnsupportedVersionAlertIsCalled: Bool = false
    func presentUnsupportedVersionAlert() {
        presentUnsupportedVersionAlertIsCalled = true
    }
}

// MARK: - MockCallConversationProvider
class MockCallConversationProvider: CallConversationProvider {
    var priorityCallConversation: ZMConversation?
    var ongoingCallConversation: ZMConversation?
    var ringingCallConversation: ZMConversation?
}
