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

final class CallQualityControllerTests: ZMSnapshotTestCase, CoreDataFixtureTestHelper {

    var sut: MockCallQualityController!
    var coreDataFixture: CoreDataFixture!
    var router: CallQualityRouterProtocolMock!
    var conversation: ZMConversation!
    var callConversationProvider: MockCallConversationProvider!
    var callQualityViewController: CallQualityViewController!

    override func setUp() {
        router = CallQualityRouterProtocolMock()
        coreDataFixture = CoreDataFixture()
        conversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                  otherUser: otherUser)
        callConversationProvider = MockCallConversationProvider()
        sut = MockCallQualityController()
        sut.router = router

        let questionLabelText = NSLocalizedString("calling.quality_survey.question", comment: "")
        callQualityViewController = CallQualityViewController(questionLabelText: questionLabelText, callDuration: 10)
        callQualityViewController?.delegate = sut

        super.setUp()
    }

    override func tearDown() {
        coreDataFixture = nil
        sut = nil
        router = nil
        conversation = nil
        callConversationProvider = nil
        callQualityViewController = nil
        super.tearDown()
    }

    // MARK: - SurveyRequestValidation Tests
    func testSurveyRequestValidation() {
        sut.usesCallSurveyBudget = true

        // When the survey was never presented, it is possible to request it
        let initialDate = Date()
        CallQualityController.resetSurveyMuteFilter()
        XCTAssertTrue(sut.canRequestSurvey(at: initialDate))

        CallQualityController.updateLastSurveyDate(initialDate)

        // During the mute time interval, it is not possible to request it
        let mutedRequestDate = Date()
        XCTAssertFalse(sut.canRequestSurvey(at: mutedRequestDate))

        // After the mute time interval, it is not possible to request it
        let postMuteDate = mutedRequestDate.addingTimeInterval(2)
        XCTAssertTrue(sut.canRequestSurvey(at: postMuteDate, muteInterval: 1))

    }

    // MARK: - SnapshotTests
    func testSurveyInterface() {
        CallQualityController.resetSurveyMuteFilter()
        verifyInAllDeviceSizes(view: callQualityViewController.view, configuration: configure)
    }

    // MARK: - CallQualitySurvey Presentation Tests
    func testThatCallQualitySurveyIsPresented_WhenCallStateIsTerminating_AndReasonIsNormal() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .normal)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation

        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertTrue(router.presentCallQualitySurveyIsCalled)
    }

    func testThatCallQualitySurveyIsPresented_WhenCallStateIsTerminating_AndReasonIsStillOngoing() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .stillOngoing)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation

        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertTrue(router.presentCallQualitySurveyIsCalled)
    }

    func testThatCallQualitySurveyIsNotPresented_WhenCallStateIsTerminating_AndReasonIsNotNormanlOrStillOngoing() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .timeout)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation

        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertFalse(router.presentCallQualitySurveyIsCalled)
    }

    func testThatCallQualitySurveyIsDismissed() {
        // WHEN
        callQualityViewController.delegate?.callQualityControllerDidFinishWithoutScore(callQualityViewController)

        // THEN
        XCTAssertTrue(router.dismissCallQualitySurveyIsCalled)
    }

    // MARK: - CallFailureDebugAlert Presentation Tests
    func testThatCallFailureDebugAlertIsPresented_WhenCallIsTerminated() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .internalError)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation

        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertTrue(router.presentCallFailureDebugAlertIsCalled)
    }

    func testThatCallFailureDebugAlertIsNotPresented_WhenCallIsTerminated() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .anweredElsewhere)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation

        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertFalse(router.presentCallFailureDebugAlertIsCalled)
    }

}

// MARK: - Helpers
extension CallQualityControllerTests {
    private func configure(view: UIView, isTablet: Bool) {
        callQualityViewController?.dimmingView.alpha = 1
        callQualityViewController?.updateLayout(isRegular: isTablet)
    }

    private func callQualityController_callCenterDidChange(callState: CallState, conversation: ZMConversation) {
        sut.callCenterDidChange(callState: callState,
                                conversation: conversation,
                                caller: otherUser,
                                timestamp: nil,
                                previousCallState: nil)
    }
}

// MARK: - ActiveCallRouterMock
class CallQualityRouterProtocolMock: CallQualityRouterProtocol {

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
class MockCallQualityController: CallQualityController {
    override var canPresentCallQualitySurvey: Bool {
        return true
    }
}
