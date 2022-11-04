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

import WireDataModel
import WireRequestStrategy

@available(iOS 15, *)
class JobTests: XCTestCase {

    var mockNetworkSession: MockNetworkSession!
    var mockAccessAPIClient: MockAccessAPIClient!
    var mockNotificationsAPIClient: MockNotificationsAPIClient!
    var mockCallEventHandler: MockCallEventHandler!
    var sut: Job!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockNetworkSession = MockNetworkSession()
        mockAccessAPIClient = MockAccessAPIClient()
        mockNotificationsAPIClient = MockNotificationsAPIClient()
        mockCallEventHandler = MockCallEventHandler()

        sut = try Job(
            request: notificationRequest,
            eventDecoder: eventDecoder,
            networkSession: mockNetworkSession,
            accessAPIClient: mockAccessAPIClient,
            notificationsAPIClient: mockNotificationsAPIClient,
            notificationContentProvider: notificationContentProviderMock,
            callEventHandler: mockCallEventHandler
        )
    }

    override func tearDown() {
        mockNetworkSession = nil
        mockAccessAPIClient = nil
        mockNotificationsAPIClient = nil
        mockCallEventHandler = nil
        super.tearDown()
    }

    let userID = UUID.create()
    let eventID = UUID.create()

    lazy var notificationRequest: UNNotificationRequest = {
        let content = UNMutableNotificationContent()

        content.userInfo["data"] = [
            "user": userID.uuidString,
            "data": ["id": eventID.uuidString]
        ]

        return UNNotificationRequest(
            identifier: "request",
            content: content,
            trigger: nil
        )
    }()
    private static let mockPayload: [String: Any] = [
        "id": "cf51e6b1-39a6-11ed-8005-520924331b82",
        "time": "2022-09-21T12:13:32.173Z",
        "type": "conversation.otr-message-add",
        "payload": [
            "conversation": "c06684dd-2865-4ff8-aef5-e0b07ae3a4e0",
            "data": [
                "text": "CiQxMDU4MDQzYi01YzRkLTQ2MDItODI2ZS04MjI4NjZmZGM2MzISDAoGUVdFUlRZMAA4AQ=="
            ]
        ]
    ]

    lazy var eventDecoder: MockEventDecoder = {
        let decoder = MockEventDecoder()
        decoder.mockDecodeEvent = {
                        return ZMUpdateEvent(
                            uuid: self.eventID,
                            payload: JobTests.mockPayload,
                            transient: false,
                            decrypted: true,
                            source: .pushNotification
                        )!
        }
        return decoder
    }()

    var notificationContentProviderMock =  MockNotificationContentProvider()

    // MARK: - Execute

    func test_Execute_NotAuthenticated() async throws {
        // Given
        mockNetworkSession.isAuthenticated = false

        // Then
        await assertThrows(expectedError: NotificationServiceError.userNotAuthenticated) {
            // When
            _ = try await self.sut.execute()
        }
    }

    func test_Execute_FetchAccessTokenFailed() async throws {
        // Given
        mockAccessAPIClient.mockFetchAccessToken = {
            throw AccessTokenEndpoint.Failure.authenticationError
        }

        // Then
        await assertThrows(expectedError: AccessTokenEndpoint.Failure.authenticationError) {
            // When
            _ = try await self.sut.execute()
        }
    }

    func test_Execute_FetchEventFailed() async throws {
        // Given
        mockAccessAPIClient.mockFetchAccessToken = {
            AccessToken(token: "12345", type: "Bearer", expiresInSeconds: 10)
        }

        mockNotificationsAPIClient.mockFetchEvent = { _ in
            throw NotificationByIDEndpoint.Failure.notifcationNotFound
        }

        // Then
        await assertThrows(expectedError: NotificationByIDEndpoint.Failure.notifcationNotFound) {
            // When
            _ = try await self.sut.execute()
        }
    }

    func test_Execute_NewMessageEvent_Content() async throws {
        // Given
        mockAccessAPIClient.mockFetchAccessToken = {
            AccessToken(token: "12345", type: "Bearer", expiresInSeconds: 10)
        }

        mockNotificationsAPIClient.mockFetchEvent = { eventID in
            XCTAssertEqual(eventID, self.eventID)

            return ZMUpdateEvent(
                uuid: eventID,
                payload: JobTests.mockPayload,
                transient: false,
                decrypted: false,
                source: .pushNotification
            )!
        }
        notificationContentProviderMock.notificationMessage = "test123"

        // When
        let result = try await self.sut.execute()
        // Then
        XCTAssertEqual(result.body, "test123")
    }

    func test_Execute_NotNewMessageEvent_Content() async throws {
        // Given
        mockAccessAPIClient.mockFetchAccessToken = {
            AccessToken(token: "12345", type: "Bearer", expiresInSeconds: 10)
        }

        mockNotificationsAPIClient.mockFetchEvent = { eventID in
            XCTAssertEqual(eventID, self.eventID)

            let payload: [String: Any] = [
                "id": "cf51e6b1-39a6-11ed-8005-520924331b82",
                "time": "2022-09-21T12:13:32.173Z",
                "type": "conversation.member-join",
                "payload": [
                    "conversation": "c06684dd-2865-4ff8-aef5-e0b07ae3a4e0"
                ]
            ]

            return ZMUpdateEvent(
                uuid: eventID,
                payload: payload,
                transient: false,
                decrypted: false,
                source: .pushNotification
            )!
        }

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertFalse(mockCallEventHandler.didCallProcessCallEvent)
    }

    func test_Execute_EmptyContnentForCallEvent() async throws {
        // Given
        mockAccessAPIClient.mockFetchAccessToken = {
            AccessToken(token: "12345", type: "Bearer", expiresInSeconds: 10)
        }
        mockCallEventHandler.returnIsCorrectCallEvent = true

        mockNotificationsAPIClient.mockFetchEvent = { eventID in
            XCTAssertEqual(eventID, self.eventID)

            return ZMUpdateEvent(
                uuid: eventID,
                payload: JobTests.mockPayload,
                transient: false,
                decrypted: false,
                source: .pushNotification
            )!
        }
        notificationContentProviderMock.returnCallEvent = true

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertTrue(mockCallEventHandler.didCallProcessCallEvent)
    }
}

class MockCallEventHandler: CallEventHandlerProtocol {
    var returnIsCorrectCallEvent = false
    var didCallProcessCallEvent = false

    func isCorrectCallEvent(_ event: ZMUpdateEvent, accountIdentifier: UUID) -> Bool {
        return returnIsCorrectCallEvent
    }

    func processCallEvent(event: ZMUpdateEvent) throws {
        didCallProcessCallEvent = true
    }
}

class MockNotificationContentProvider: NotificationContentProviderProtocol {
    var notificationMessage = ""
    var returnCallEvent = false

    func notificationContent(fromEvent event: ZMUpdateEvent) throws -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.body = notificationMessage

        return content
    }

    func isCorrectCallEvent(_ event: ZMUpdateEvent, accountIdentifier: UUID) -> Bool {
        return returnCallEvent
    }
}

class MockEventDecoder: EventDecodingProtocol {
    var mockDecodeEvent: (() async -> ZMUpdateEvent)?

    func decryptAndStoreEvent(_ event: ZMUpdateEvent) async -> ZMUpdateEvent {
        guard let mock = mockDecodeEvent else {
            fatalError("no mock for `decodeEvent`")
        }
        return await mock()
    }
}

class MockNetworkSession: NetworkSessionProtocol {

    var accessToken: AccessToken?
    var isAuthenticated = true

    var mockExecuteFetchAccessToken: ((AccessTokenEndpoint) async throws -> AccessTokenEndpoint.Result)?
    var mockExecuteFetchNotification: ((NotificationByIDEndpoint) async throws -> NotificationByIDEndpoint.Result)?

    func execute<E>(endpoint: E) async throws -> E.Result where E: Endpoint {
        switch endpoint {
        case let accessEndpoint as AccessTokenEndpoint:
            guard let mock = mockExecuteFetchAccessToken else {
                fatalError("no mock for `mockExecuteFetchAccessToken`")
            }

            return try await mock(accessEndpoint) as! E.Result

        case let notificationEndpoint as NotificationByIDEndpoint:
            guard let mock = mockExecuteFetchNotification else {
                fatalError("no mock for `mockExecuteFetchNotification`")
            }

            return try await mock(notificationEndpoint) as! E.Result

        default:
            fatalError("unexpected endpoint which isn't mocked")
        }
    }

}

class MockAccessAPIClient: AccessAPIClientProtocol {

    var mockFetchAccessToken: (() async throws -> AccessToken)?

    func fetchAccessToken() async throws -> AccessToken {
        guard let mock = mockFetchAccessToken else {
            fatalError("no mock for `fetchAccessToken`")
        }

        return try await mock()
    }

}

class MockNotificationsAPIClient: NotificationsAPIClientProtocol {

    var mockFetchEvent: ((UUID) async throws -> ZMUpdateEvent)?

    func fetchEvent(eventID: UUID) async throws -> ZMUpdateEvent {
        guard let mock = mockFetchEvent else {
            fatalError("no mock for `fetchEvent`")
        }

        return try await mock(eventID)
    }

}
