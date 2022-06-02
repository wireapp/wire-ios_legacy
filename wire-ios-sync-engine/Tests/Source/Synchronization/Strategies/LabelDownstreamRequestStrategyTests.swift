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

import Foundation
@testable import WireSyncEngine

class LabelDownstreamRequestStrategyTests: MessagingTest {

    var sut: LabelDownstreamRequestStrategy!
    var mockSyncStatus: MockSyncStatus!
    var mockSyncStateDelegate: MockSyncStateDelegate!
    var mockApplicationStatus: MockApplicationStatus!

    var conversation1: ZMConversation!
    var conversation2: ZMConversation!

    override func setUp() {
        super.setUp()
        mockSyncStateDelegate = MockSyncStateDelegate()
        mockSyncStatus = MockSyncStatus(managedObjectContext: syncMOC, syncStateDelegate: mockSyncStateDelegate)
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .slowSyncing
        sut = LabelDownstreamRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus, syncStatus: mockSyncStatus)

        syncMOC.performGroupedBlockAndWait {
            self.conversation1 = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation1.remoteIdentifier = UUID()

            self.conversation2 = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation2.remoteIdentifier = UUID()
        }
    }

    override func tearDown() {
        sut = nil
        mockSyncStatus = nil
        mockApplicationStatus = nil
        mockSyncStateDelegate = nil
        conversation1 = nil
        conversation2 = nil
        super.tearDown()
    }

    func successfullFolderResponse() -> ZMTransportResponse {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self.folderResponse(name: "folder", conversations: []))
        let urlResponse = HTTPURLResponse(url: URL(string: "properties/labels")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return ZMTransportResponse(httpurlResponse: urlResponse, data: data, error: nil, apiVersion: APIVersion.v0.rawValue)
    }

    func favoriteResponse(identifier: UUID = UUID(), favorites: [UUID]) -> WireSyncEngine.LabelPayload {
        let update = WireSyncEngine.LabelUpdate(id: identifier, type: Label.Kind.favorite.rawValue, name: "", conversations: favorites)
        let response = WireSyncEngine.LabelPayload(labels: [update])
        return response
    }

    func folderResponse(identifier: UUID = UUID(), name: String, conversations: [UUID]) -> WireSyncEngine.LabelPayload {
        let update = WireSyncEngine.LabelUpdate(id: identifier, type: Label.Kind.folder.rawValue, name: name, conversations: conversations)
        let response = WireSyncEngine.LabelPayload(labels: [update])
        return response
    }

    func updateEvent(with labels: WireSyncEngine.LabelPayload) -> ZMUpdateEvent {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(labels)
        let dict = try! JSONSerialization.jsonObject(with: data, options: [])

        let payload = ["value": dict,
                       "key": "labels",
                       "type": ZMUpdateEvent.eventTypeString(for: .userPropertiesSet)!
            ] as [String: Any]

        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!
    }

    // MARK: - Slow Sync

    func testThatItRequestsLabels_DuringSlowSync() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.mockSyncStatus.mockPhase = .fetchingLabels

            // WHEN
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }

            // THEN
            XCTAssertEqual(request.path, "/properties/labels")
        }
    }

    func testThatItRequestsLabels_WhenRefetchingIsNecessary() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).needsToRefetchLabels = true

            // WHEN
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }

            // THEN
            XCTAssertEqual(request.path, "/properties/labels")
        }
    }

    func testThatItResetsFlag_WhenLabelsExist() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).needsToRefetchLabels = true
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }

            // WHEN
            request.complete(with: self.successfullFolderResponse())
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(ZMUser.selfUser(in: self.syncMOC).needsToRefetchLabels)
        }
    }

    func testThatItResetsFlag_WhenLabelsDontExist() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).needsToRefetchLabels = true
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }

            // WHEN
            request.complete(with: ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(ZMUser.selfUser(in: self.syncMOC).needsToRefetchLabels)
        }
    }

    func testThatItFinishSlowSyncPhase_WhenLabelsExist() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.mockSyncStatus.mockPhase = .fetchingLabels
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }

            // WHEN
            request.complete(with: self.successfullFolderResponse())
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    func testThatItFinishSlowSyncPhase_WhenLabelsDontExist() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.mockSyncStatus.mockPhase = .fetchingLabels
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }

            // WHEN
            request.complete(with: ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    // MARK: - Event Processing

    func testThatItUpdatesLabels_OnPropertiesUpdateEvent() {
        var conversation: ZMConversation!
        let conversationId = UUID()

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = conversationId
            self.syncMOC.saveOrRollback()
            let event = self.updateEvent(with: self.favoriteResponse(favorites: [conversationId]))

            // WHEN
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(conversation.isFavorite)
        }
    }

    // MARK: - Label Processing

    func testThatItIgnoresIdentifier_WhenUpdatingFavoritelabel() {
        let favoriteIdentifier = UUID()
        let responseIdentifier = UUID()

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let label = Label.insertNewObject(in: self.syncMOC)
            label.kind = .favorite
            label.remoteIdentifier = favoriteIdentifier
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.update(with: self.favoriteResponse(identifier: responseIdentifier, favorites: [self.conversation1.remoteIdentifier!]))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            let label = Label.fetchFavoriteLabel(in: self.syncMOC)
            XCTAssertEqual(label.remoteIdentifier, favoriteIdentifier)
            XCTAssertEqual(label.conversations, [self.conversation1])
        }
    }

    func testThatItResetsLocallyModifiedKeys_WhenUpdatingLabel() {
        let folderIdentifier = UUID()

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: folderIdentifier, create: true, in: self.syncMOC, created: &created)
            label?.name = "Folder A"
            label?.conversations = Set([self.conversation1])
            label?.modifiedKeys = Set(["conversations"])
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.update(with: self.folderResponse(identifier: folderIdentifier, name: "Folder A", conversations: [self.conversation2.remoteIdentifier!]))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: folderIdentifier, create: false, in: self.syncMOC, created: &created)!
            XCTAssertNil(label.modifiedKeys)
        }
    }

    func testThatItItUpdatesFolderName() {
        let folderIdentifier = UUID()
        let updatedName = "Folder B"

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: folderIdentifier, create: true, in: self.syncMOC, created: &created)
            label?.name = "Folder A"
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.update(with: self.folderResponse(identifier: folderIdentifier, name: updatedName, conversations: [self.conversation1.remoteIdentifier!]))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: folderIdentifier, create: false, in: self.syncMOC, created: &created)!
            XCTAssertEqual(label.name, updatedName)
        }

    }

    func testThatItItUpdatesFolderConversations() {
        let folderIdentifier = UUID()

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: folderIdentifier, create: true, in: self.syncMOC, created: &created)
            label?.name = "Folder A"
            label?.conversations = Set([self.conversation1])
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.update(with: self.folderResponse(identifier: folderIdentifier, name: "Folder A", conversations: [self.conversation2.remoteIdentifier!]))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: folderIdentifier, create: false, in: self.syncMOC, created: &created)!
            XCTAssertEqual(label.conversations, [self.conversation2])
        }
    }

    func testThatItDeletesLocalLabelsNotIncludedInResponse() {
        var label1: Label!
        var label2: Label!

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            var created = false
            label1 = Label.fetchOrCreate(remoteIdentifier: UUID(), create: true, in: self.syncMOC, created: &created)
            label1.name = "Folder A"
            label1.conversations = Set([self.conversation1])

            label2 = Label.fetchOrCreate(remoteIdentifier: UUID(), create: true, in: self.syncMOC, created: &created)
            label2.name = "Folder B"
            label2.conversations = Set([self.conversation2])

            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.update(with: self.folderResponse(identifier: label1.remoteIdentifier!, name: "Folder A", conversations: [self.conversation1.remoteIdentifier!]))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(label2.isZombieObject)
        }
    }

}
