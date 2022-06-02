//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import WireDataModel
@testable import WireSyncEngine

// MARK: - Mocks

@objc class FakeGroupQueue: NSObject, ZMSGroupQueue {

    var dispatchGroup: ZMSDispatchGroup! {
        return nil
    }

    func performGroupedBlock(_ block : @escaping () -> Void) {
        block()
    }

}

class AssetDeletionStatusTests: MessagingTest {

    private var sut: AssetDeletionStatus!
    fileprivate var identifierProvider: DeletableAssetIdentifierProvider!

    override func setUp() {
        super.setUp()
        identifierProvider = IdentifierProvider()
        sut = AssetDeletionStatus(provider: identifierProvider, queue: FakeGroupQueue())
    }

    override func tearDown() {
        identifierProvider = nil
        sut = nil
        super.tearDown()
    }

    func testThatItDoesNotReturnAnyIdentifiersInitially() {
        // When
        let identifier = sut.nextIdentifierToDelete()

        // Then
        XCTAssertNil(identifier)
    }

    func testThatItAddsAnIdentifierToTheList() {
        // Given
        let identifier = UUID.create().transportString()

        // When
        NotificationCenter.default.post(name: .deleteAssetNotification, object: identifier)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(identifierProvider.assetIdentifiersToBeDeleted, [identifier])
    }

    func testThatItReturnsAnIdentifierWhenThereIsOne() {
        // Given
        let identifier = UUID.create().transportString()
        identifierProvider.assetIdentifiersToBeDeleted = [identifier]

        // When
        let nextIdentifierToDelete = sut.nextIdentifierToDelete()

        // Then
        XCTAssertEqual(nextIdentifierToDelete, identifier)
        XCTAssertNil(sut.nextIdentifierToDelete())
    }

    func testThatItReturnsAnIdentifierOnlyOnce() {
        // Given
        let identifier1 = UUID.create().transportString()
        let identifier2 = UUID.create().transportString()
        identifierProvider.assetIdentifiersToBeDeleted = [identifier1, identifier2]

        // When
        guard let first = sut.nextIdentifierToDelete() else { return XCTFail("no first identifier") }
        guard let second = sut.nextIdentifierToDelete() else { return XCTFail("no second identifier") }

        // Then
        let expected = Set([identifier1, identifier2])
        let actual = Set([first, second])
        XCTAssertEqual(actual, expected)
        XCTAssertNil(sut.nextIdentifierToDelete())
    }

    func testThatItFiresANextRequestNotificationIfAnIdentifierIsAdded() {
        // Given
        let identifier = UUID.create().transportString()

        // Expect
        let requestExpectation = expectation(description: "notification should be posted")
        let observer = MockRequestAvailableObserver(requestAvailable: requestExpectation.fulfill)

        // When
        NotificationCenter.default.post(name: .deleteAssetNotification, object: identifier)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.1))
        _ = observer
    }

    func testThatItDoesNotReturnAnIdentifierAgainAfterItSucceeded() {
        // Given
        let identifier1 = UUID.create().transportString()
        let identifier2 = UUID.create().transportString()
        identifierProvider.assetIdentifiersToBeDeleted = Set([identifier1, identifier2])
        guard let first = sut.nextIdentifierToDelete() else { return XCTFail("no first identifier") }

        // When
        sut.didDelete(identifier: first)

        // Then
        guard let second = sut.nextIdentifierToDelete() else { return XCTFail("no second identifier") }
        XCTAssertNotEqual(first, second)
        XCTAssertNil(sut.nextIdentifierToDelete())
    }

    func testThatItDoesNotReturnAnIdentifierAgainAfterItFailed() {
        // Given
        let identifier1 = UUID.create().transportString()
        let identifier2 = UUID.create().transportString()
        identifierProvider.assetIdentifiersToBeDeleted = Set([identifier1, identifier2])
        guard let first = sut.nextIdentifierToDelete() else { return XCTFail("no first identifier") }

        // When
        sut.didFailToDelete(identifier: first)

        // Then
        guard let second = sut.nextIdentifierToDelete() else { return XCTFail("no second identifier") }
        XCTAssertNotEqual(first, second)
        XCTAssertNil(sut.nextIdentifierToDelete())
    }

}

// MARK: - Helper

private class IdentifierProvider: NSObject, DeletableAssetIdentifierProvider {
    var assetIdentifiersToBeDeleted = Set<String>()
}

private class MockRequestAvailableObserver: NSObject, RequestAvailableObserver {

    private let requestAvailable: () -> Void

    init(requestAvailable: @escaping () -> Void) {
        self.requestAvailable = requestAvailable
        super.init()
        RequestAvailableNotification.addObserver(self)
    }

    deinit {
        RequestAvailableNotification.removeObserver(self)
    }

    func newRequestsAvailable() {
        requestAvailable()
    }
}
