//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
@testable import Wire_Notification_Service_Extension

class NotificationByIDEndpointTests: XCTestCase {
    // swiftlint:disable:next line_length
    private let exampleEventJSON = """
        {"id":"96188b94-2a8e-11ed-8002-124b5cbe3b2d","payload":[{"conversation":"d7174dca-488b-463b-bb64-2c2bec442deb","data":{"data":"","recipient":"fd27d34a62e5980","sender":"b7d8296a54a59151","text":"owABAaEAWCC4Yoo+oc7/JLSHCih1oLjWah7e/A2amSVaeCX+Om4cngJYbwGlAFC/I/Rp7dx7VX5rGMfnxKV2AQACAQOhAFggxRJFDfIG6ds7GC90UZKoaBVgJrRQvqHGqh2xqS8eHeMEWC/W/eip/c2hCxfsF/Re5luDuINPLPEG+ErdhPFlQTjJFoDTtXutaXwkr8qVa+XeVQ=="},"from":"16b0c8ed-2026-4643-8c6e-4b7b7160890b","qualified_conversation":{"domain":"wire.com","id":"d7174dca-488b-463b-bb64-2c2bec442deb"},"qualified_from":{"domain":"wire.com","id":"16b0c8ed-2026-4643-8c6e-4b7b7160890b"},"time":"2022-09-02T07:12:21.023Z","type":"conversation.otr-message-add"}]}
        """

    func testRequestCorrectPath() {
        // given
        let endpoint = NotificationByIDEndpoint(eventID: UUID(uuidString: "16B0C8ed-2026-4643-8c6e-4b7b7160890b")!)
        // when
        let request = endpoint.request
        // then
        XCTAssertEqual(request.path, "/notifications/16b0c8ed-2026-4643-8c6e-4b7b7160890b")

    }

    func testParseResponseSuccess() {
        // given
        let successResponse = SuccessResponse(status: 200, data: exampleEventJSON.data(using: .utf8)!)
        let endpoint = NotificationByIDEndpoint(eventID: UUID(uuidString: "96188b94-2a8e-11ed-8002-124b5cbe3b2d")!)
        // when
        let result = endpoint.parseResponse(.success(successResponse))
        // then
        guard case .success(let notification) = result else {
            XCTFail("endpoint failed")
            return
        }
        XCTAssertEqual(notification.conversationUUID, UUID(uuidString: "d7174dca-488b-463b-bb64-2c2bec442deb"))
    }

    func testIncorrectEventFailure() {
        // given
        let successResponse = SuccessResponse(status: 200, data: exampleEventJSON.data(using: .utf8)!)
        let endpoint = NotificationByIDEndpoint(eventID: UUID())
        // when
        let result = endpoint.parseResponse(.success(successResponse))
        // then
        XCTAssertEqual(result, .failure(.incorrectEvent))
    }

    func testParsingErrorFailure() {
        // given
        let successResponse = SuccessResponse(status: 200, data: "".data(using: .utf8)!)
        let endpoint = NotificationByIDEndpoint(eventID: UUID())
        // when
        let result = endpoint.parseResponse(.success(successResponse))
        // then
        XCTAssertEqual(result, .failure(.failedToDecodePayload))
    }

    func testEventNotFoundFailure() {
        // given
        let failureResponse = ErrorResponse(code: 404, label: "not-found", message: "error")
        let endpoint = NotificationByIDEndpoint(eventID: UUID())
        // when
        let result = endpoint.parseResponse(.failure(failureResponse))
        // then
        XCTAssertEqual(result, .failure(.notifcationNotFound))
    }

    func testUnknownErrorFailure() {
        // given
        let failureResponse = ErrorResponse(code: 500, label: "server-error", message: "error")
        let endpoint = NotificationByIDEndpoint(eventID: UUID())
        // when
        let result = endpoint.parseResponse(.failure(failureResponse))
        // then
        XCTAssertEqual(result, .failure(.unknownError(failureResponse)))
    }
}
