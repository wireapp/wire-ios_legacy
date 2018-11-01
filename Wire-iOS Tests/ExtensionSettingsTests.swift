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
@testable import WireExtensionComponents

class ExtensionSettingsTests: XCTestCase {

    var defaults: UserDefaults!
    var settings: ExtensionSettings!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: name)
        settings = ExtensionSettings(defaults: defaults)
    }

    override func tearDown() {
        settings.reset()
        settings = nil
        defaults = nil
        super.tearDown()
    }

    func testThatItDisablesAnalyticsByDefault() {
        XCTAssertTrue(settings.disableCrashAndAnalyticsSharing)
    }

    func testThatItHandlesAnalyticsPreferenceChange() {
        XCTAssertTrue(settings.disableCrashAndAnalyticsSharing)

        settings.disableCrashAndAnalyticsSharing = false
        XCTAssertFalse(settings.disableCrashAndAnalyticsSharing)

        settings.disableCrashAndAnalyticsSharing = true
        XCTAssertTrue(settings.disableCrashAndAnalyticsSharing)
    }

    func testThatItEnablesLinkPreviewsByDefault() {
        XCTAssertFalse(settings.disableLinkPreviews)
    }

    func testThatItHandlesLinkPreviewPreferenceChange() {
        XCTAssertFalse(settings.disableLinkPreviews)

        settings.disableLinkPreviews = true
        XCTAssertTrue(settings.disableLinkPreviews)

        settings.disableLinkPreviews = false
        XCTAssertFalse(settings.disableLinkPreviews)
    }
}
