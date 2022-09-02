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

//    func testCorrectRequest() {}

    func testParseResponseSuccess() {
        let JSON = """
        {"id":"96188b94-2a8e-11ed-8002-124b5cbe3b2d","payload":[{"conversation":"d7174dca-488b-463b-bb64-2c2bec442deb","data":{"data":"","recipient":"fd27d34a62e5980","sender":"b7d8296a54a59151","text":"owABAaEAWCC4Yoo+oc7/JLSHCih1oLjWah7e/A2amSVaeCX+Om4cngJYbwGlAFC/I/Rp7dx7VX5rGMfnxKV2AQACAQOhAFggxRJFDfIG6ds7GC90UZKoaBVgJrRQvqHGqh2xqS8eHeMEWC/W/eip/c2hCxfsF/Re5luDuINPLPEG+ErdhPFlQTjJFoDTtXutaXwkr8qVa+XeVQ=="},"from":"16b0c8ed-2026-4643-8c6e-4b7b7160890b","qualified_conversation":{"domain":"wire.com","id":"d7174dca-488b-463b-bb64-2c2bec442deb"},"qualified_from":{"domain":"wire.com","id":"16b0c8ed-2026-4643-8c6e-4b7b7160890b"},"time":"2022-09-02T07:12:21.023Z","type":"conversation.otr-message-add"}]}
        """
        let successResponse = SuccessResponse(status: 200, data: JSON.data(using: .utf8)!)
        let endpoint = NotificationByIDEndpoint(eventID: UUID())
        let result = endpoint.parseResponse(.success(successResponse))
//        XCTAssertTrue(case .success == result)
    }
//
    func testParsingErrorFailure() {
        let successResponse = SuccessResponse(status: 200, data: "".data(using: .utf8)!)
        let endpoint = NotificationByIDEndpoint(eventID: UUID())
        let result = endpoint.parseResponse(.success(successResponse))

        XCTAssertEqual(result, .failure(.failedToDecodePayload))
    }

    func testEventNotFoundFailure() {
        let failureResponse = ErrorResponse(code: 404, label: "not-found", message: "error")
        let endpoint = NotificationByIDEndpoint(eventID: UUID())
        let result = endpoint.parseResponse(.failure(failureResponse))

        XCTAssertEqual(result, .failure(.notifcationNotFound))
    }

    func testUnknownErrorFailure() {
        let failureResponse = ErrorResponse(code: 500, label: "server-error", message: "error")
        let endpoint = NotificationByIDEndpoint(eventID: UUID())
        let result = endpoint.parseResponse(.failure(failureResponse))

        XCTAssertEqual(result, .failure(.unknownError(failureResponse)))
    }
}
