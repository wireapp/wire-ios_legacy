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
@testable import Wire

extension XCTestCase {

    static let lockQueue = DispatchQueue(label: "mediaCacheClean.lock.queue")

    func waitForMediaAssetCacheToBeEmpty(completion: Completion? = nil) {
        XCTestCase.lockQueue.async {
            _ = self.waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup])
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    func verifyAfterMediaAssetCacheEmptied(verifyClosure: @escaping Completion,
                named name: String? = nil,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {
        let expectation = XCTestExpectation(description: "snapshot is captured")
        waitForMediaAssetCacheToBeEmpty {
            verifyClosure()
            expectation.fulfill()
        }

        ///prevent calling teardown before snapshot is done
        wait(for: [expectation], timeout: 5)
    }
}
