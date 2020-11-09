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

final class CallRouterTests: XCTestCase {
    
    var sut: CallRouterMock!
    var callController: CallController!
    
    override func setUp() {
        super.setUp()
        sut = CallRouterMock()
        callController = CallController()
        callController.router = sut
    }

    override func tearDown() {
        sut = nil
        callController = nil
        super.tearDown()
    }
    
    func testThatVersionAlertIsNotPresented_WhenCallStateIsTerminatedAndReasonIsNotOutdatedClient() {
        // GIVEN
        let callState: CallState = .terminating(reason: .canceled)
        let conversation = ZMConversation()
        let caller = MockUserType.createSelfUser(name: "caller")
        
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: caller,
                                           timestamp: nil,
                                           previousCallState: nil)
        // THEN
        XCTAssertFalse(sut.presentUnsupportedVersionAlertIsCalled)
    }
    
    func testThatVersionAlertIsPresented_WhenCallStateIsTerminatedAndReasonIsOutdatedClient() {
        // GIVEN
        let callState: CallState = .terminating(reason: .outdatedClient)
        let conversation = ZMConversation()
        let caller = MockUserType.createSelfUser(name: "caller")
        
        // WHEN
        callController.callCenterDidChange(callState: callState,
                                           conversation: conversation,
                                           caller: caller,
                                           timestamp: nil,
                                           previousCallState: nil)
        
        // THEN
        XCTAssertTrue(sut.presentUnsupportedVersionAlertIsCalled)
    }
}

class CallRouterMock: CallRouterProtocol {
    var presentActiveCallIsCalled: Bool = false
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool) {
        presentActiveCallIsCalled = true
    }
    
    var dismissActiveCallIsCalled: Bool = false
    func dismissActiveCall(animated: Bool, completion: (() -> Void)?) {
        dismissActiveCallIsCalled = false
    }
    
    var minimizeCallIsCalled: Bool = false
    func minimizeCall(animated: Bool, completion: (() -> Void)?) {
        minimizeCallIsCalled = true
    }
    
    func showCallTopOverlayController(for conversation: ZMConversation) { }
    
    func hideCallTopOverlayController() { }
    
    var presentSecurityDegradedAlertIsCalled: Bool = false
    func presentSecurityDegradedAlert(degradedUser: UserType?) {
        presentSecurityDegradedAlertIsCalled = true
    }
    
    var presentUnsupportedVersionAlertIsCalled: Bool = false
    func presentUnsupportedVersionAlert() {
        presentUnsupportedVersionAlertIsCalled = true
    }
}

