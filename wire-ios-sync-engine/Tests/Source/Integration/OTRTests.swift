//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireSyncEngine
import WireMockTransport

class OTRTests: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    func testThatItSendsEncryptedTextMessage() {
        // given
        XCTAssert(login())
        guard let conversation = self.conversation(for: self.selfToUser1Conversation) else { return XCTFail()}

        // when
        var message: ZMConversationMessage?
        userSession?.perform {
            let text = "Foo bar, but encrypted"
            message = try! conversation.appendText(content: text)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message?.deliveryState, .sent)
    }

    func testThatItSendsEncryptedImageMessage() {
        // given
        XCTAssert(login())
        guard let conversation = self.conversation(for: self.selfToUser1Conversation) else { return XCTFail() }

        // when
        var message: ZMConversationMessage?
        userSession?.perform {
            let imageData = self.verySmallJPEGData()
             message = try! conversation.appendImage(from: imageData)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message?.deliveryState, .sent)
    }

    func testThatItSendsARequestToUpdateSignalingKeys() {

        // given
        XCTAssert(login())
        self.mockTransportSession.resetReceivedRequests()

        var didReregister = false
        self.mockTransportSession.responseGeneratorBlock = { response in
            if response.path.contains("/clients/") && response.payload?.asDictionary()?["sigkeys"] != nil {
                didReregister = true
                return ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            }
            return nil
        }

        // when
        self.userSession?.perform {
            UserClient.resetSignalingKeysInContext(self.userSession!.managedObjectContext)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didReregister)
    }

    func testThatItCreatesNewKeysIfReqeustToSyncSignalingKeysFailedWithBadRequest() {

        // given
        XCTAssert(login())
        self.mockTransportSession.resetReceivedRequests()

        var tryCount = 0
        var (firstMac, firstEnc) = (String(), String())
        self.mockTransportSession.responseGeneratorBlock = { response in
            guard let payload = response.payload?.asDictionary() else { return nil }

            if response.path.contains("/clients/") && payload["sigkeys"] != nil {
                let keys = payload["sigkeys"] as? [String: Any]
                let macKey = keys?["mackey"] as? String
                let encKey = keys?["enckey"] as? String

                if tryCount == 0 {
                    tryCount += 1
                    guard let mac = macKey, let enc = encKey else { XCTFail("No signaling keys in payload"); return nil }
                    (firstMac, firstEnc) = (mac, enc)
                    return ZMTransportResponse(payload: ["label": "bad-request"] as ZMTransportData, httpStatus: 400, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
                }
                tryCount += 1
                XCTAssertNotEqual(macKey, firstMac)
                XCTAssertNotEqual(encKey, firstEnc)
                return ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            }
            return nil
        }

        // when
        userSession?.perform {
            UserClient.resetSignalingKeysInContext(self.userSession!.managedObjectContext)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(tryCount, 2)
    }

}
