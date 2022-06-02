//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireDataModel

class ZMUserLegalHoldTests: ModelObjectsTests {

    func testThatLegalHoldStatusIsDisabled_ByDefault() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
    }

    func testThatLegalHoldStatusIsDisabled_AfterCancelingRequest() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let request = LegalHoldRequest.mockRequest(for: selfUser)
        selfUser.userDidReceiveLegalHoldRequest(request)

        // WHEN
        selfUser.legalHoldRequestWasCancelled()

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
        XCTAssertFalse(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatLegalHoldStatusIsDisabled_AfterReceivingRequestTargetingAnotherUser() {
        // GIVEN
        let otherUser = createUser(in: uiMOC)
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        let request = LegalHoldRequest.mockRequest(for: otherUser)
        selfUser.userDidReceiveLegalHoldRequest(request)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
        XCTAssertFalse(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatLegalHoldStatusIsPending_AfterReceivingRequest() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        let request = LegalHoldRequest.mockRequest(for: selfUser)
        selfUser.userDidReceiveLegalHoldRequest(request)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .pending(request))
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatLegalHoldStatusIsEnabled_AfterAcceptingRequest() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        createSelfClient(onMOC: uiMOC)

        let conversation = createConversation(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        // WHEN
        let request = LegalHoldRequest.mockRequest(for: selfUser)
        selfUser.userDidReceiveLegalHoldRequest(request)

        performPretendingUiMocIsSyncMoc {
            _ = selfUser.addLegalHoldClient(from: request)
            selfUser.userDidAcceptLegalHoldRequest(request)
        }

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
        XCTAssertTrue(conversation.allMessages.contains(where: { ($0 as? ZMSystemMessage)?.systemMessageType == .legalHoldEnabled }))
        XCTAssertTrue(conversation.isUnderLegalHold)
    }

    func testThatLegalHoldStatusIsEnabled_AfterAddingClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        UserClient.createMockLegalHoldSelfUserClient(in: uiMOC)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatItDoesntClearNotificationFlag_AfterAddingNormalClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        UserClient.createMockLegalHoldSelfUserClient(in: uiMOC)
        UserClient.createMockPhoneUserClient(in: uiMOC)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatLegalHoldStatusIsDisabled_AfterRemovingClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        let legalHoldClient = UserClient.createMockLegalHoldSelfUserClient(in: uiMOC)
        XCTAssertEqual(selfUser.legalHoldStatus, .enabled)

        selfUser.acknowledgeLegalHoldStatus()
        XCTAssertFalse(selfUser.needsToAcknowledgeLegalHoldStatus)

        // WHEN
        performPretendingUiMocIsSyncMoc {
            legalHoldClient.deleteClientAndEndSession()
        }

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatItDoesntClearNotificationFlag_AfterRemovingNormalClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        let normalClient = UserClient.createMockPhoneUserClient(in: uiMOC)
        UserClient.createMockLegalHoldSelfUserClient(in: uiMOC)
        XCTAssertEqual(selfUser.legalHoldStatus, .enabled)

        // WHEN
        performPretendingUiMocIsSyncMoc {
            normalClient.deleteClientAndEndSession()
        }

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

}

extension LegalHoldRequest {

    static func mockRequest(for user: ZMUser) -> LegalHoldRequest {
        let prekey = LegalHoldRequest.Prekey(id: 65535, key: Data(base64Encoded: "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g==")!)
        return LegalHoldRequest(target: user.remoteIdentifier!, requester: UUID(), clientIdentifier: "eca3c87cfe28be49", lastPrekey: prekey)
    }

}

extension UserClient {

    @discardableResult
    static func createMockLegalHoldSelfUserClient(in moc: NSManagedObjectContext) -> UserClient {
        let payload: [String: AnyObject] = [
            "id": NSUUID().transportString() as NSString,
            "type": DeviceType.legalHold.rawValue as NSString,
            "class": DeviceClass.legalHold.rawValue as NSString,
            "time": NSDate()
        ]

        return createOrUpdateSelfUserClient(payload, context: moc)!
    }

    @discardableResult
    static func createMockPhoneUserClient(in moc: NSManagedObjectContext) -> UserClient {
        let payload: [String: AnyObject] = [
            "id": NSUUID().transportString() as NSString,
            "type": DeviceType.permanent.rawValue as NSString,
            "class": DeviceClass.phone.rawValue as NSString,
            "time": NSDate()
        ]

        return createOrUpdateSelfUserClient(payload, context: moc)!
    }

}
