//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension ZMUserSessionTestsBase {

    @objc
    public func createCallCenter() -> WireCallCenterV3Mock {
        let selfUser = ZMUser.selfUser(in: self.syncMOC)
        return WireCallCenterV3Factory.callCenter(withUserId: selfUser.avsIdentifier, clientId: selfUser.selfClient()!.remoteIdentifier!, uiMOC: uiMOC, flowManager: FlowManagerMock(), transport: WireCallCenterTransportMock()) as! WireCallCenterV3Mock
    }

    @objc
    public func simulateIncomingCall(fromUser user: ZMUser, conversation: ZMConversation) {
        guard let callCenter = user.managedObjectContext?.zm_callCenter as? WireCallCenterV3Mock else { XCTFail(); return }
        callCenter.setMockCallState(.incoming(video: false, shouldRing: true, degraded: false), conversationId: conversation.avsIdentifier!, callerId: user.avsIdentifier, isVideo: false)
    }

}
