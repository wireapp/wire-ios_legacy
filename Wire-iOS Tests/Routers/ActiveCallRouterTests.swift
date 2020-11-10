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

final class ActiveCallRouterTests: XCTestCase, CoreDataFixtureTestHelper {
    
    var coreDataFixture: CoreDataFixture!
    var sut: ActiveCallRouterMock!
    var callController: CallController!
    
    override func setUp() {
        super.setUp()
        sut = ActiveCallRouterMock()
        coreDataFixture = CoreDataFixture()
        callController = CallController()
        callController.router = sut
    }

    override func tearDown() {
        sut = nil
        callController = nil
        super.tearDown()
    }
    
    // MARK: - ActiveCall Presentation Tests
    func testThatActiveCallIsPresented_WhenMinimizedCallIsNil() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callController.testHelper_setPriorityCallConversation(conversation)
        callController.testHelper_setMinimizedCall(nil)
        
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertTrue(sut.presentActiveCallIsCalled)
    }
    
    func testThaActiveCallIsDismissed_WhenPriorityCallConversationIsNil() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callController.testHelper_setPriorityCallConversation(nil)
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertTrue(sut.dismissActiveCallIsCalled)
    }
    
    func testThatActiveCallIsMinimized_WhenPriorityCallConversationIsTheCallConversationMinimized() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callController.testHelper_setPriorityCallConversation(conversation)
        callController.testHelper_setMinimizedCall(conversation)
        
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertTrue(sut.minimizeCallIsCalled)
    }
    
    // MARK: - CallTopOverlay Presentation Tests
    func testThaCallTopOverlayIsShown_WhenPriorityCallConversationIsNotNil() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callController.testHelper_setPriorityCallConversation(conversation)
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertTrue(sut.showCallTopOverlayIsCalled)
    }
    
    func testThatCallTopOverlayIsHidded_WhenPriorityCallConversationIsNil() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callController.testHelper_setPriorityCallConversation(nil)
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertTrue(sut.hideCallTopOverlayIsCalled)
    }
    
    func testThatCallTopOverlayIsHidden_When() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callController.testHelper_setPriorityCallConversation(nil)
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertFalse(sut.showCallTopOverlayIsCalled)
    }
    
    // MARK: - Version Alert Presentation Tests
    func testThatVersionAlertIsPresented_WhenCallStateIsTerminatedAndReasonIsOutdatedClient() {
        // GIVEN
        let callState: CallState = .terminating(reason: .outdatedClient)
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertTrue(sut.presentUnsupportedVersionAlertIsCalled)
    }
    
    func testThatVersionAlertIsNotPresented_WhenCallStateIsTerminatedAndReasonIsNotOutdatedClient() {
        // GIVEN
        let callState: CallState = .terminating(reason: .canceled)
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                          otherUser: otherUser)
        
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        // THEN
        XCTAssertFalse(sut.presentUnsupportedVersionAlertIsCalled)
    }
    
    func testThatVersionAlertIsNotPresented_WhenCallStateIsNotTerminated() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertFalse(sut.presentUnsupportedVersionAlertIsCalled)
    }
    
    // MARK: - Degradation Alert Presentation Tests
    func testThatVersionDegradationAlertIsNotPresented_WhenVoiceChannelHasNotDegradationState() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertFalse(sut.presentSecurityDegradedAlertIsCalled)
    }
}

class ActiveCallRouterMock: ActiveCallRouterProtocol {
    
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

