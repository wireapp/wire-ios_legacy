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

import XCTest
@testable import Wire

final class LicensesLoaderTests: XCTestCase {

    var memoryManager: NSObject!
    var loader: LicensesLoader!

    override func setUp() {
        super.setUp()
        memoryManager = NSObject()
        loader = LicensesLoader(memoryManager: memoryManager)
    }

    func testThatItCachesAndReturnsTheListOfLicensesWhenCacheIsEmpty() {
        // GIVEN
        XCTAssertNil(loader.cache)

        // WHEN
        guard let licenses = loader.loadLicenses() else {
            XCTFail("Cannot load licenses")
            return
        }

        // THEN
        XCTAssertFalse(licenses.isEmpty)
        XCTAssertEqual(licenses, loader.cache)
    }

    func testThatItReturnsTheListOfLicensesWhenTheCacheIsNotEmpty() {
        // GIVEN
        guard loader.loadLicenses() != nil else {
            XCTFail("Cannot load licenses")
            return
        }

        guard let cachedResults = loader.cache else {
            XCTFail("Results were not cached.")
            return

        }

        XCTAssertFalse(cachedResults.isEmpty)

        // WHEN
        guard let licenses = loader.loadLicenses() else {
            XCTFail("Cannot load licenses.")
            return
        }

        XCTAssertEqual(cachedResults, licenses)
    }

    func testThatItDeletesCacheWhenMemoryWarningIsSent() {
        // GIVEN
        guard let initialLicenses = loader.loadLicenses() else {
            XCTFail("Cannot load licenses")
            return
        }

        XCTAssertFalse(initialLicenses.isEmpty)
        XCTAssertEqual(initialLicenses, loader.cache)
        XCTAssertFalse(loader.cacheEmpty)

        // WHEN
        let predicate = NSPredicate(block: { _, _ in
            return self.loader.cacheEmpty
        })

        let deletedCacheExpectation = expectation(for: predicate, evaluatedWith: loader) {
            return self.loader.cache == nil
        }

        sendMemoryWarning()
        wait(for: [deletedCacheExpectation], timeout: 30)

        // THEN
        XCTAssert(loader.cacheEmpty)
        XCTAssertNil(loader.cache)
    }

    // MARK: - Helpers

    private func sendMemoryWarning() {
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: memoryManager)
    }
}
