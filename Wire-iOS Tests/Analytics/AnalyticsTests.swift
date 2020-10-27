//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import AppCenterCrashes
import WireCommonComponents

final class AnalyticsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let coreDataFixture = CoreDataFixture()
        SelfUser.provider = coreDataFixture.selfUserProvider
    }

    func testThatItSetsOptOutOnAppCenter() {
        // GIVEN
        // do not create third party Analytics provider, we are just testing AppCenter SDK here
        AnalyticsProviderFactory.shared.useConsoleAnalytics = true

        TrackingManager.shared.disableCrashSharing = false

        // WHEN
        TrackingManager.shared.disableCrashSharing = true

        // THEN
        XCTAssertFalse(MSCrashes.isEnabled())
    }

    func testThatItSetsOptOutCrashReportToSharedSettings() {
        // GIVEN
        TrackingManager.shared.disableCrashSharing = false
        // THEN
        XCTAssertFalse(ExtensionSettings.shared.disableCrashSharing)
        // WHEN
        TrackingManager.shared.disableCrashSharing = true
        // THEN
        XCTAssert(ExtensionSettings.shared.disableCrashSharing)
    }

    func testThatItSetsOptOutAnalyticsToSharedSettings() {
        // GIVEN
        TrackingManager.shared.disableAnalyticsSharing = false
        // THEN
        XCTAssertFalse(ExtensionSettings.shared.disableAnalyticsSharing)
        // WHEN
        TrackingManager.shared.disableAnalyticsSharing = true
        // THEN
        XCTAssert(ExtensionSettings.shared.disableAnalyticsSharing)
    }
}
