//
//  CallTopOverlayControllerTests.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 04.09.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
@testable import Wire

class CallTopOverlayControllerTests: CoreDataSnapshotTestCase {
    
    var sut: CallTopOverlayController!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        self.recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testIncomingCalls_OneOnOne() {
        self.conversation = self.otherUserConversation!
        self.sut = CallTopOverlayController(conversation: conversation)
        self.sut.callCenterDidChange(callState: .incoming(video: false, shouldRing: true, degraded: false),
                                     conversation: self.conversation,
                                     caller: self.selfUser,
                                     timestamp: Date(),
                                     previousCallState: nil)
        verify(view: self.sut.view)
    }
}
