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
    var callQualityController: CallQualityControllerMock!
    
    override func setUp() {
        super.setUp()
        sut = ActiveCallRouterMock()
        coreDataFixture = CoreDataFixture()
        callController = CallController()
        callController.router = sut
        callQualityController = CallQualityControllerMock()
        callQualityController.router = sut
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
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(sut.presentActiveCallIsCalled)
    }
    
    func testThatActiveCallIsDismissed_WhenPriorityCallConversationIsNil() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callController.testHelper_setPriorityCallConversation(nil)
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
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
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(sut.minimizeCallIsCalled)
    }
    
    // MARK: - CallTopOverlay Presentation Tests
    func testThatCallTopOverlayIsShown_WhenPriorityCallConversationIsNotNil() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callController.testHelper_setPriorityCallConversation(conversation)
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
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
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
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
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
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
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(sut.presentUnsupportedVersionAlertIsCalled)
    }
    
    func testThatVersionAlertIsNotPresented_WhenCallStateIsTerminatedAndReasonIsNotOutdatedClient() {
        // GIVEN
        let callState: CallState = .terminating(reason: .canceled)
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                          otherUser: otherUser)
        
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertFalse(sut.presentUnsupportedVersionAlertIsCalled)
    }
    
    func testThatVersionAlertIsNotPresented_WhenCallStateIsNotTerminated() {
        // GIVEN
        let callState: CallState = .established
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        // WHEN
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
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
        callController_callCenterDidChange(callState: callState, conversation: conversation)
        
        // THEN
        XCTAssertFalse(sut.presentSecurityDegradedAlertIsCalled)
    }
    
    // MARK: - CallQualitySurvey Presentation Tests
    func testThatCallQualitySurveyIsPresented_WhenCallStateIsTerminating_AndReasonIsNormal() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .normal)
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)
    
        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(sut.presentCallQualitySurveyIsCalled)
    }
    
    func testThatCallQualitySurveyIsPresented_WhenCallStateIsTerminating_AndReasonIsStillOngoing() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .stillOngoing)
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)
    
        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(sut.presentCallQualitySurveyIsCalled)
    }
    
    func testThatCallQualitySurveyIsNotPresented_WhenCallStateIsTerminating_AndReasonIsNotNormanlOrStillOngoing() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .timeout)
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)
    
        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)
        
        // THEN
        XCTAssertFalse(sut.presentCallQualitySurveyIsCalled)
    }
    
    func testThatCallQualitySurveyIsDismissed() {
        // GIVEN
        let questionLabelText = NSLocalizedString("calling.quality_survey.question", comment: "")
        let qualityController = CallQualityViewController(questionLabelText: questionLabelText, callDuration: 10)
        qualityController.delegate = callQualityController
        
        // WHEN
        qualityController.delegate?.callQualityControllerDidFinishWithoutScore(qualityController)
        
        // THEN
        XCTAssertTrue(sut.dismissCallQualitySurveyIsCalled)
    }
    
    // MARK: - CallFailureDebugAlert Presentation Tests
    func testThatCallFailureDebugAlertIsPresented_WhenCallIsTerminated() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .internalError)
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)
    
        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)
        
        // THEN
        XCTAssertTrue(sut.presentCallFailureDebugAlertIsCalled)
    }
    
    func testThatCallFailureDebugAlertIsNotPresented_WhenCallIsTerminated() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .anweredElsewhere)
        let conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                      otherUser: otherUser)
        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)
    
        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)
        
        // THEN
        XCTAssertFalse(sut.presentCallFailureDebugAlertIsCalled)
    }
}

// MARK: - Helpers
extension ActiveCallRouterTests {
    private func callController_callCenterDidChange(callState: CallState, conversation: ZMConversation) {
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: otherUser,
                                           timestamp: nil,
                                           previousCallState: nil)
    }
    
    private func callQualityController_callCenterDidChange(callState: CallState, conversation: ZMConversation) {
        callQualityController.callCenterDidChange(callState: callState,
                                                  conversation: conversation,
                                                  caller: otherUser,
                                                  timestamp: nil,
                                                  previousCallState: nil)
    }
}

// MARK: - ActiveCallRouterMock
class ActiveCallRouterMock: ActiveCallRouterProtocol, CallQualityRouterProtocol {
    
    // MARK: - ActiveCallRouterProtocol
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
    
    // MARK: - CallQualityRouterProtocol
    var presentCallQualitySurveyIsCalled: Bool = false
    func presentCallQualitySurvey(with callDuration: TimeInterval) {
        presentCallQualitySurveyIsCalled = true
    }
    
    var dismissCallQualitySurveyIsCalled: Bool = false
    func dismissCallQualitySurvey(completion: Completion?) {
        dismissCallQualitySurveyIsCalled = true
    }
    
    var presentCallFailureDebugAlertIsCalled: Bool = false
    func presentCallFailureDebugAlert() {
        presentCallFailureDebugAlertIsCalled = true
    }
    
    func presentCallQualityRejection() { }
}

// MARK: - ActiveCallRouterMock
class CallQualityControllerMock: CallQualityController {
    override var canPresentCallQualitySurvey: Bool {
        return true
    }
}
