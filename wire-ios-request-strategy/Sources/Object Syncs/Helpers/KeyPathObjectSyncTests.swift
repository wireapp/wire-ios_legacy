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
import WireTesting
@testable import WireRequestStrategy

class MockKeyPathObjectSyncTranscoder: KeyPathObjectSyncTranscoder {

    typealias T = MockEntity

    var objectsAskedToBeSynchronized: Set<MockEntity> = Set()
    var objectsAskedToBeCancelled: Set<MockEntity> = Set()

    var completionBlock: (() -> Void)?
    func synchronize(_ object: MockEntity, completion: @escaping () -> Void) {
        objectsAskedToBeSynchronized.insert(object)
        completionBlock = completion
    }

    func cancel(_ object: MockEntity) {
        objectsAskedToBeCancelled.insert(object)
    }

    func completeSynchronization() {
        completionBlock?()
        completionBlock = nil
    }

}

class KeyPathObjectSyncTests: ZMTBaseTest {

    var moc: NSManagedObjectContext!
    var transcoder: MockKeyPathObjectSyncTranscoder!
    var sut: KeyPathObjectSync<MockKeyPathObjectSyncTranscoder>!

    // MARK: - Life Cycle

    override func setUp() {
        super.setUp()

        moc = MockModelObjectContextFactory.testContext()
        transcoder = MockKeyPathObjectSyncTranscoder()
        sut = KeyPathObjectSync(entityName: MockEntity.entityName(), \.needsToBeUpdatedFromBackend)
        sut.transcoder = transcoder
    }

    override func tearDown() {
        transcoder = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Tests

    func testSyncAsksToSynchronizeObject_WhenKeyPathEvalutesToTrue() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]

        // when
        mockEntity.needsToBeUpdatedFromBackend = true
        sut.objectsDidChange(mockEntitySet)

        // then
        XCTAssertTrue(transcoder.objectsAskedToBeSynchronized.contains(mockEntity))
    }

    func testSyncAsksToSynchronizeObject_WhenPreviousSynchronizationIsCompleted() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]

        mockEntity.needsToBeUpdatedFromBackend = true
        sut.objectsDidChange(mockEntitySet)

        mockEntity.needsToBeUpdatedFromBackend = false
        sut.objectsDidChange(mockEntitySet)
        transcoder.objectsAskedToBeSynchronized.removeAll()

        // when
        mockEntity.needsToBeUpdatedFromBackend = true
        sut.objectsDidChange(mockEntitySet)

        // then
        XCTAssertTrue(transcoder.objectsAskedToBeSynchronized.contains(mockEntity))
    }

    func testSyncAsksToCancelObject_WhenObjectNoLongerMatchesKeyPath() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]
        mockEntity.needsToBeUpdatedFromBackend = true
        sut.objectsDidChange(mockEntitySet)

        // when
        mockEntity.needsToBeUpdatedFromBackend = false
        sut.objectsDidChange(mockEntitySet)

        // then
        XCTAssertTrue(transcoder.objectsAskedToBeCancelled.contains(mockEntity))
    }

    func testSyncDoesNotAsksoSynchronizeObject_WhenSynchronizationIsAlreadyInProgress() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]
        mockEntity.needsToBeUpdatedFromBackend = true
        sut.objectsDidChange(mockEntitySet)
        transcoder.objectsAskedToBeSynchronized.removeAll()

        // when
        sut.objectsDidChange(mockEntitySet)

        // then
        XCTAssertTrue(transcoder.objectsAskedToBeSynchronized.isEmpty)
    }

    func testSyncSetsKeyPathToFalse_WhenSynchronizationCompletes() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]
        mockEntity.needsToBeUpdatedFromBackend = true
        sut.objectsDidChange(mockEntitySet)

        // when
        transcoder.completeSynchronization()

        // then
        XCTAssertFalse(mockEntity.needsToBeUpdatedFromBackend)
    }

    func testFetchRequestForTrackedObjects() throws {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        mockEntity.needsToBeUpdatedFromBackend = true

        // when
        let fetchRequest = try XCTUnwrap(sut.fetchRequestForTrackedObjects())

        // then
        XCTAssertTrue(fetchRequest.predicate!.evaluate(with: mockEntity))
    }

}
