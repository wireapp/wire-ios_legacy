//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class FeatureConfigRequestStrategyTests: MessagingTestBase {

    // MARK: - Properties

    var sut: FeatureConfigRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var featureService: FeatureService!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .slowSyncing

        sut = FeatureConfigRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus
        )

        featureService = .init(context: syncMOC)
    }

    override func tearDown() {
        sut = nil
        mockApplicationStatus = nil
        featureService = nil
        super.tearDown()
    }

    // MARK: - Processing events

    func test_ItProcessesEvent_AppLock() {
        syncMOC.performGroupedAndWait { _ in
            // Given
            let appLock = Feature.AppLock(
                status: .disabled,
                config: .init(enforceAppLock: false, inactivityTimeoutSecs: 10)
            )

            self.featureService.storeAppLock(appLock)

            let data: NSDictionary = [
                "status": "enabled",
                "config": [
                    "enforceAppLock": true,
                    "inactivityTimeoutSecs": 60
                  ]
            ]
            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "appLock"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait { _ in
            let existingFeature = self.featureService.fetchAppLock()
            XCTAssertEqual(existingFeature.status, .enabled)
            XCTAssertEqual(existingFeature.config.enforceAppLock, true)
            XCTAssertEqual(existingFeature.config.inactivityTimeoutSecs, 60)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_FileSharing() {
        syncMOC.performGroupedAndWait { _ in
            // Given
            self.featureService.storeFileSharing(.init(status: .disabled))

            let data: NSDictionary = [
                "status": "enabled"
            ]
            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "fileSharing"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait { _ in
            let existingFeature = self.featureService.fetchFileSharing()
            XCTAssertEqual(existingFeature.status, .enabled)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_SelfDeletingMessages() {
        syncMOC.performGroupedAndWait { _ in
            // Given
            let selfDeletingMessages = Feature.SelfDeletingMessages(
                status: .disabled,
                config: .init(enforcedTimeoutSeconds: 0)
            )

            self.featureService.storeSelfDeletingMessages(selfDeletingMessages)

            let data: NSDictionary = [
                "status": "enabled",
                "config": [
                    "enforcedTimeoutSeconds": 60
                ]
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "selfDeletingMessages"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait { _ in
            let existingfeature = self.featureService.fetchSelfDeletingMesssages()
            XCTAssertEqual(existingfeature.status, .enabled)
            XCTAssertEqual(existingfeature.config.enforcedTimeoutSeconds, 60)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItProcessesEvent_ConferenceCalling() {
        syncMOC.performGroupedAndWait { _ in
            // Given
            self.featureService.storeConferenceCalling(.init(status: .disabled))

            let dict: NSDictionary = [
                "status": "enabled"
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "conferenceCalling"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait { _ in
            let existingFeature = self.featureService.fetchConferenceCalling()
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature.status, .enabled)
        }
    }

    func test_ItProcessesEvent_ConversationGuestLinks() {
        syncMOC.performGroupedAndWait { _ in
            // Given
            self.featureService.storeConversationGuestLinks(.init(status: .disabled))

            let dict: NSDictionary = [
                "status": "enabled"
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "conversationGuestLinks"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait { _ in
            let existingFeature = self.featureService.fetchConversationGuestLinks()
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature.status, .enabled)
        }
    }

    func test_ItProcessesEvent_DigitalSignature() {
        syncMOC.performGroupedAndWait { _ in
            // Given
            self.featureService.storeDigitalSignature(.init(status: .disabled))

            let dict: NSDictionary = [
                "status": "enabled"
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": dict,
                "name": "digitalSignature"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait { _ in
            let existingFeature = self.featureService.fetchDigitalSignature()
            XCTAssertNotNil(existingFeature)
            XCTAssertEqual(existingFeature.status, .enabled)
        }
    }

    func test_ItProcessesEvent_ClassifiedDomains() {
        syncMOC.performGroupedAndWait { _ in
            // Given
            let classifiedDomains = Feature.ClassifiedDomains(status: .disabled, config: .init())
            self.featureService.storeClassifiedDomains(classifiedDomains)

            let data: NSDictionary = [
                "status": "enabled",
                "config": [
                    "domains": ["a", "b", "c"]
                ]
            ]

            let payload: NSDictionary = [
                "type": "feature-config.update",
                "data": data,
                "name": "classifiedDomains"
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // When
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedAndWait { _ in
            let classifiedDomains = self.featureService.fetchClassifiedDomains()
            XCTAssertEqual(classifiedDomains.status, .enabled)
            XCTAssertEqual(classifiedDomains.config.domains, ["a", "b", "c"])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

}
