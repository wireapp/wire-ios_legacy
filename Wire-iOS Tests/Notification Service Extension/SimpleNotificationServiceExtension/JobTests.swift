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

class JobTests: XCTestCase {

    // Need to mock:
    // - network session
    // - accessAPIClient
    // - notificationsAPIClient

    // MARK: - Execute

    // if user is not authenticated, it throws `userNotAuthenticated` error
    func test_Execute_NotAuthenticated() async throws {
        // Given
        let userID = UUID.create()
        let eventID = UUID.create()

        let content = UNMutableNotificationContent()
        content.userInfo["data"] = [
            "user": userID.uuidString,
            "data": eventID.uuidString
        ]

        let request = UNNotificationRequest(
            identifier: "request",
            content: content,
            trigger: nil
        )
        
        // create sut with mocks

        // not authenticated

        // When
        // execute

        // Then
        // throws "userNotAuthenticated" error
    }

    // if we failed to fetch the access token, it throws an error.

    // if we failed to fetch an event, it throws 'noEvent' error

    // if the event type is `.conversationOtrMessageAdd`, it creates notification content

    // if the event type is something else, it returns empty content.

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
            fatalError("no mock for `fetchAccessToken")
        }

        return try await mock()
    }

}

class MockNotificationsAPIClient: NotificationsAPIClientProtocol {

    var mockFetchEvent: ((UUID) async throws -> ZMUpdateEvent)?

    func fetchEvent(eventID: UUID) async throws -> ZMUpdateEvent {
        guard let mock = mockFetchEvent else {
            fatalError("no mock for `fetchEvent")
        }

        return try await mock(eventID)
    }

}
