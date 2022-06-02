//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class MockInsertedObjectSyncTranscoder: InsertedObjectSyncTranscoder {

    typealias Object = MockEntity

    var objectsAskedToBeInserted: [MockEntity] = []
    var pendingInsertions: [() -> Void] = []

    func completePendingInsertions() {
        pendingInsertions.forEach({ $0() })
        pendingInsertions.removeAll()
    }

    func insert(object: MockEntity, completion: @escaping () -> Void) {
        objectsAskedToBeInserted.append(object)
        pendingInsertions.append(completion)
    }

}

class InsertedObjectSyncTests: ZMTBaseTest {

    var moc: NSManagedObjectContext!
    var transcoder: MockInsertedObjectSyncTranscoder!
    var sut: InsertedObjectSync<MockInsertedObjectSyncTranscoder>!

    // MARK: - Life Cycle

    override func setUp() {
        super.setUp()

        moc = MockModelObjectContextFactory.testContext()
        transcoder = MockInsertedObjectSyncTranscoder()
        sut = InsertedObjectSync()
        sut.transcoder = transcoder
    }

    override func tearDown() {
        transcoder = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Tests

    func testThatItReturnsExpectedFetchRequest() {
        // when
        let fetchRequest = sut.fetchRequestForTrackedObjects()

        // then
        XCTAssertEqual(fetchRequest?.predicate, MockEntity.predicateForObjectsThatNeedToBeInsertedUpstream())
    }

    func testThatItAsksToInsertObject_WhenAddingTrackedObjects() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]

        // when
        mockEntity.remoteIdentifier = nil
        sut.addTrackedObjects(mockEntitySet)

        // then
        XCTAssertTrue(transcoder.objectsAskedToBeInserted.contains(mockEntity))
    }

    func testThatItAsksToInsertObject_WhenInsertPredicateEvalutesToTrue() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]

        // when
        mockEntity.remoteIdentifier = nil
        sut.objectsDidChange(mockEntitySet)

        // then
        XCTAssertTrue(transcoder.objectsAskedToBeInserted.contains(mockEntity))
    }

    func testThatItAsksToInsertObject_WhenInsertPredicateEvaluatesToTrueAfterBeingFalse() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]
        mockEntity.remoteIdentifier = nil
        sut.objectsDidChange(mockEntitySet)
        mockEntity.remoteIdentifier = UUID()
        sut.objectsDidChange(mockEntitySet)

        // when
        mockEntity.remoteIdentifier = nil
        sut.objectsDidChange(mockEntitySet)

        // then
        XCTAssertEqual(transcoder.objectsAskedToBeInserted, [mockEntity, mockEntity])
    }

    func testItDoesNotAskToInsertObject_WhenInsertPredicateEvaluatesToFalse() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]

        // when
        mockEntity.remoteIdentifier = UUID()
        sut.objectsDidChange(mockEntitySet)

        // then
        XCTAssertTrue(transcoder.objectsAskedToBeInserted.isEmpty)
    }

    func testItDoesNotAskToInsertObject_WhenInsertionIsPending() {
        // given
        let mockEntity = MockEntity.insertNewObject(in: moc)
        let mockEntitySet: Set<NSManagedObject> = [mockEntity]
        mockEntity.remoteIdentifier = nil
        sut.objectsDidChange(mockEntitySet)
        transcoder.objectsAskedToBeInserted.removeAll()

        // when
        sut.objectsDidChange(mockEntitySet)

        // then
        XCTAssertTrue(transcoder.objectsAskedToBeInserted.isEmpty)
    }

}
