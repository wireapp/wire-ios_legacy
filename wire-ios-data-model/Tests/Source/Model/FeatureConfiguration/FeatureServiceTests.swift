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
@testable import WireDataModel

class FeatureServiceTests: ZMBaseManagedObjectTest {

    func testThatItStoresAppLockFeature() {
        // Given
        let sut = FeatureService(context: syncMOC)
        let appLock = Feature.AppLock(status: .disabled, config: .init(enforceAppLock: true, inactivityTimeoutSecs: 10))

        syncMOC.performGroupedAndWait { context -> Void in
            guard let existing = Feature.fetch(name: .appLock, context: context) else { return XCTFail() }
            XCTAssertNotEqual(existing.status, appLock.status)
            XCTAssertNotEqual(existing.config, appLock.configData)
        }

        // When
        syncMOC.performGroupedAndWait { _ in
            sut.storeAppLock(appLock)
        }

        // Then
        syncMOC.performGroupedAndWait { context -> Void in
            guard let result = Feature.fetch(name: .appLock, context: context) else { return XCTFail() }
            XCTAssertEqual(result.status, appLock.status)
            XCTAssertEqual(result.config, appLock.configData)
        }
    }

    func testItCreatesADefaultInstance() throws {
        // Given
        let sut = FeatureService(context: syncMOC)

        syncMOC.performGroupedAndWait { context in
            if let existingDefault = Feature.fetch(name: .appLock, context: context) {
                context.delete(existingDefault)
            }

            XCTAssertNil(Feature.fetch(name: .appLock, context: context))
        }

        // When
        syncMOC.performGroupedAndWait { _ in
            sut.createDefaultConfigsIfNeeded()
        }

        // Then
        syncMOC.performGroupedAndWait { context in
            XCTAssertNotNil(Feature.fetch(name: .appLock, context: context))
        }
    }

}

private extension Feature.AppLock {

    var configData: Data {
        return try! JSONEncoder().encode(config)
    }

}
