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

    // MARK: - Request generation

    func test_RequestGeneration() {
        // Given
        let eventID = UUID.create()
        let sut = NotificationByIDEndpoint(eventID: eventID)

        // When
        let request = sut.request

        // Then
        XCTAssertEqual(request.path, "/notifications/\(eventID.uuidString.lowercased())")
        XCTAssertEqual(request.httpMethod, .get)
        XCTAssertEqual(request.contentType, .json)
        XCTAssertEqual(request.acceptType, .json)
    }

    // MARK: - Response parsing

    let eventID = UUID.create()
    let senderID = UUID.create()
    let senderDomain = "foo.com"
    let conversationID = UUID.create()
    let conversationDomain = "bar.com"
    let senderClientID = "fd27a34a42e5980"
    let recipientClientID = "b7d8296a54c49151"

    lazy var validPayload = """
        {
            "id": "\(eventID.uuidString.lowercased())",
            "payload": [
                {
                    "type": "conversation.otr-message-add",
                    "time": "2022-09-02T07:12:21.023Z",
                    "from": "\(senderID.uuidString.lowercased())",
                    "qualified_from": {
                        "id": "\(senderID.uuidString.lowercased())",
                        "domain": "\(senderDomain)"
                    },
                    "conversation": "\(conversationID.uuidString.lowercased())",
                    "qualified_conversation": {
                        "id": "\(conversationID.uuidString.lowercased())",
                        "domain": "\(conversationDomain)"
                    },
                    "data": {
                        "data": "",
                        "recipient": "\(recipientClientID)",
                        "sender": "\(senderClientID)",
                        "text": "some encrypted data"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

    lazy var validPayloadNoEvents = """
        {
            "id": "\(eventID.uuidString.lowercased())",
            "payload": []
        }
        """.data(using: .utf8)!

    let invalidPayload = """
        {
            "foo": "bar"
        }
        """.data(using: .utf8)!

    func test_ParseSuccessResponse() {
        // Given
        let sut = NotificationByIDEndpoint(eventID: eventID)
        let response = SuccessResponse(status: 200, data: validPayload)

        // When
        let result = sut.parseResponse(.success(response))

        // Then
        guard case .success(let event) = result else {
            XCTFail("expected success result")
            return
        }

        XCTAssertEqual(event.uuid, eventID)
        XCTAssertEqual(event.type, .conversationOtrMessageAdd)
        XCTAssertEqual(event.senderUUID, senderID)
        XCTAssertEqual(event.senderDomain, senderDomain)
        XCTAssertEqual(event.conversationUUID, conversationID)
        XCTAssertEqual(event.conversationDomain, conversationDomain)
        XCTAssertEqual(event.recipientClientID, recipientClientID)
        XCTAssertEqual(event.senderClientID, senderClientID)
    }

    func test_ParseSuccess_FailedToDecodeError() {
        // Given
        let sut = NotificationByIDEndpoint(eventID: eventID)
        let response = SuccessResponse(status: 200, data: invalidPayload)

        // When
        let result = sut.parseResponse(.success(response))

        // Then
        XCTAssertEqual(result, .failure(.failedToDecodePayload))
    }

    func test_ParseSuccess_NotificationNotFound() {
        // Given
        let sut = NotificationByIDEndpoint(eventID: eventID)
        let response = SuccessResponse(status: 200, data: validPayloadNoEvents)

        // When
        let result = sut.parseResponse(.success(response))

        // Then
        XCTAssertEqual(result, .failure(.notifcationNotFound))
    }

    func test_ParseSuccess_IncorrectEvent() {
        // Given
        let sut = NotificationByIDEndpoint(eventID: .create())
        let response = SuccessResponse(status: 200, data: validPayload)

        // When
        let result = sut.parseResponse(.success(response))

        // Then
        XCTAssertEqual(result, .failure(.incorrectEvent))
    }

    func test_ParseSuccess_InvalidResponse() {
        // Given
        let sut = NotificationByIDEndpoint(eventID: eventID)
        let response = SuccessResponse(status: 222, data: validPayload)

        // When
        let result = sut.parseResponse(.success(response))

        // Then
        XCTAssertEqual(result, .failure(.invalidResponse))
    }

    func test_ParseError_NotificationNotFound() {
        // Given
        let sut = NotificationByIDEndpoint(eventID: eventID)
        let response = ErrorResponse(code: 404, label: "not-found", message: "error")

        // When
        let result = sut.parseResponse(.failure(response))

        // Then
        XCTAssertEqual(result, .failure(.notifcationNotFound))
    }

    func test_ParseError_UnknownError() {
        // Given
        let sut = NotificationByIDEndpoint(eventID: eventID)
        let response = ErrorResponse(code: 500, label: "server-error", message: "error")

        // When
        let result = sut.parseResponse(.failure(response))

        // Then
        XCTAssertEqual(result, .failure(.unknownError(response)))
    }

}
