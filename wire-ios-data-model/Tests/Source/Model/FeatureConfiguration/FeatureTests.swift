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
@testable import WireDataModel

final class FeatureTests: ZMBaseManagedObjectTest {

    // MARK: - Tests

    func testThatItUpdatesFeature() {
        // given
        syncMOC.performGroupedAndWait { context in
            guard let defaultAppLock = Feature.fetch(name: .appLock, context: context) else {
                XCTFail()
                return
            }

            XCTAssertEqual(defaultAppLock.status, .enabled)
        }

        // when
        syncMOC.performGroupedAndWait { context in
            Feature.updateOrCreate(havingName: .appLock, in: context) {
                $0.status = .disabled
            }
        }

        // then
        syncMOC.performGroupedAndWait { context in
            let updatedAppLock = Feature.fetch(name: .appLock, context: context)
            XCTAssertEqual(updatedAppLock?.status, .disabled)
        }
    }

    func testThatItFetchesFeature() {
        syncMOC.performGroupedAndWait { context in
            // when
            let defaultAppLock = Feature.fetch(name: .appLock, context: context)

            // then
            XCTAssertNotNil(defaultAppLock)
        }
    }

    func testThatItUpdatesNeedsToNotifyUserFlag_IfAppLockBecameForced() {
        // given
        syncMOC.performGroupedAndWait { context in
            Feature.updateOrCreate(havingName: .appLock, in: context) {
                $0.config = self.configData(enforced: false)
                $0.hasInitialDefault = false
            }
        }

        syncMOC.performGroupedAndWait { context in
            guard let feature = Feature.fetch(name: .appLock, context: context) else {
                XCTFail()
                return
            }

            XCTAssertFalse(feature.needsToNotifyUser)
        }

        // when
        syncMOC.performGroupedAndWait { context in
            Feature.updateOrCreate(havingName: .appLock, in: context) {
                $0.config = self.configData(enforced: true)
            }
        }

        // then
        syncMOC.performGroupedAndWait { context in
            guard let feature = Feature.fetch(name: .appLock, context: context) else {
                XCTFail()
                return
            }

            XCTAssertTrue(feature.needsToNotifyUser)
        }
    }

    func testThatItUpdatesNeedsToNotifyUserFlag_IfAppLockBecameNonForced() {
        // given
        syncMOC.performGroupedAndWait { context in
            Feature.updateOrCreate(havingName: .appLock, in: context) {
                $0.config = self.configData(enforced: true)
                $0.needsToNotifyUser = false
                $0.hasInitialDefault = false
            }
        }

        syncMOC.performGroupedAndWait { context in
            guard let feature = Feature.fetch(name: .appLock, context: context) else {
                XCTFail()
                return
            }

            XCTAssertFalse(feature.needsToNotifyUser)
        }

        // when
        syncMOC.performGroupedAndWait { context in
            Feature.updateOrCreate(havingName: .appLock, in: context) {
                $0.config = self.configData(enforced: false)
            }
        }

        // then
        syncMOC.performGroupedAndWait { context in
            guard let feature = Feature.fetch(name: .appLock, context: context) else {
                XCTFail()
                return
            }

            XCTAssertTrue(feature.needsToNotifyUser)
        }
    }

    func testThatItNeedsToNotifyUser_AfterAChange() {
        // Given
        syncMOC.performGroupedAndWait { context in
            let defaultConferenceCalling = Feature.fetch(name: .conferenceCalling, context: self.syncMOC)
            defaultConferenceCalling?.status = .disabled
            defaultConferenceCalling?.hasInitialDefault = false
            XCTAssertNotNil(defaultConferenceCalling)
        }

        // When
        syncMOC.performGroupedAndWait { _ in
            Feature.updateOrCreate(havingName: .conferenceCalling, in: self.syncMOC) { (feature) in
                feature.needsToNotifyUser = false
                feature.status = .enabled
            }
        }

        // Then
        syncMOC.performGroupedAndWait { context in
            guard let feature = Feature.fetch(name: .conferenceCalling, context: context) else {
                XCTFail()
                return
            }

            XCTAssertTrue(feature.needsToNotifyUser)
        }
    }

    func testThatItDoesNotNeedToNotifyUser_IfThePreviousValueIsDefault() {
        // Given
        syncMOC.performGroupedAndWait { context in
            let defaultConferenceCalling = Feature.fetch(name: .conferenceCalling, context: self.syncMOC)
            XCTAssertNotNil(defaultConferenceCalling)
            XCTAssertTrue(defaultConferenceCalling!.hasInitialDefault)
        }

        // When
        syncMOC.performGroupedAndWait { _ in
            Feature.updateOrCreate(havingName: .conferenceCalling, in: self.syncMOC) { (feature) in
                feature.status = .enabled
            }
        }

        // Then
        syncMOC.performGroupedAndWait { context in
            guard let feature = Feature.fetch(name: .conferenceCalling, context: context) else {
                XCTFail()
                return
            }

            XCTAssertFalse(feature.needsToNotifyUser)
        }
    }
}

// MARK: - Helpers
extension FeatureTests {

    func configData(enforced: Bool) -> Data {
        let json = """
          {
            "enforceAppLock": \(enforced),
            "inactivityTimeoutSecs": 30
          }
          """

        return json.data(using: .utf8)!
    }
}

extension Feature {

    @discardableResult
    static func insert(name: Name,
                       status: Status,
                       config: Data?,
                       context: NSManagedObjectContext) -> Feature {

        let feature = Feature.insertNewObject(in: context)
        feature.name = name
        feature.status = status
        feature.config = config
        return feature
    }

}
