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

import Foundation
@testable import WireRequestStrategy

class GetFeatureConfigsActionHandlerTests: MessagingTestBase {

    // MARK: - Helpers

    func mockResponse(status: Int, label: String) -> ZMTransportResponse {
        let payload = ["label": label] as ZMTransportData
        return mockResponse(status: status, payload: payload)
    }

    func mockResponse(status: Int, payload: ZMTransportData? = nil) -> ZMTransportResponse {
        return ZMTransportResponse(
            payload: payload,
            httpStatus: status,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    let successPayload: ZMTransportData = [

    ] as ZMTransportData

    // MARK: - Request generation

    func test_ItGeneratesARequest() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        let action = GetFeatureConfigsAction()

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v0))

        // Then
        XCTAssertEqual(request.path, "/feature-configs")
        XCTAssertEqual(request.method, .methodGET)
    }

    // MARK: - Response handling

    func test_ItHandlesResponse_200() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = expectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .success:
                break

            default:
                XCTFail("Expected 'success'")
            }

            gotResult.fulfill()
        }

        let payload = GetFeatureConfigsActionHandler.ResponsePayload(
            appLock: .init(status: .enabled, config: .init(enforceAppLock: true, inactivityTimeoutSecs: 11)),
            classifiedDomains: .init(status: .enabled, config: .init(domains: ["foo"])),
            conferenceCalling: .init(status: .enabled),
            conversationGuestLinks: .init(status: .enabled),
            digitalSignatures: .init(status: .enabled),
            fileSharing: .init(status: .enabled),
            selfDeletingMessages: .init(status: .enabled, config: .init(enforcedTimeoutSeconds: 22))
        )

        let payloadData = try JSONEncoder().encode(payload)
        let payloadString = String(data: payloadData, encoding: .utf8)!

        // When
        sut.handleResponse(mockResponse(status: 200, payload: payloadString as ZMTransportData), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedBlock {
            let featureService = FeatureService(context: self.syncMOC)

            let appLock = featureService.fetchAppLock()
            XCTAssertEqual(appLock.status, .enabled)
            XCTAssertEqual(appLock.config.enforceAppLock, true)
            XCTAssertEqual(appLock.config.inactivityTimeoutSecs, 11)

            let classifiedDomains = featureService.fetchClassifiedDomains()
            XCTAssertEqual(classifiedDomains.status, .enabled)
            XCTAssertEqual(classifiedDomains.config.domains, ["foo"])

            let conferenceCalling = featureService.fetchConferenceCalling()
            XCTAssertEqual(conferenceCalling.status, .enabled)

            let conversationGuestLinks = featureService.fetchConversationGuestLinks()
            XCTAssertEqual(conversationGuestLinks.status, .enabled)

            let digitalSignature = featureService.fetchDigitalSignature()
            XCTAssertEqual(digitalSignature.status, .enabled)

            let fileSharing = featureService.fetchFileSharing()
            XCTAssertEqual(fileSharing.status, .enabled)

            let selfDeletingMessage = featureService.fetchSelfDeletingMesssages()
            XCTAssertEqual(selfDeletingMessage.status, .enabled)
            XCTAssertEqual(selfDeletingMessage.config.enforcedTimeoutSeconds, 22)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_200_MalformedResponse() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = expectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.malformedResponse):
                break

            default:
                XCTFail("Expected 'malformed response'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 200, payload: nil), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_200_FailedToDecodeResponse() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = expectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.failedToDecodeResponse):
                break

            default:
                XCTFail("Expected 'failed to decode response'")
            }

            gotResult.fulfill()
        }

        let payload = ["foo": "bar"] as ZMTransportData

        // When
        sut.handleResponse(mockResponse(status: 200, payload: payload), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_403_InsuffientPermissions() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = expectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.insufficientPermissions):
                break

            default:
                XCTFail("Expected 'insufficient permissions'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 403, label: "operation-denied"), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_403_UserIsNotTeamMember() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = expectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.userIsNotTeamMember):
                break

            default:
                XCTFail("Expected 'user is not team member'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 403, label: "no-team-member"), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_404_TeamNotFound() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = expectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.teamNotFound):
                break

            default:
                XCTFail("Expected 'team not found'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 404, label: "no-team"), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_UnknownResponse() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = expectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case let .failure(.unknown(status, label)):
                XCTAssertEqual(status, 999)
                XCTAssertEqual(label, "foo")

            default:
                XCTFail("Expected 'unknown status: 999, label: foo'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 999, label: "foo"), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

}
