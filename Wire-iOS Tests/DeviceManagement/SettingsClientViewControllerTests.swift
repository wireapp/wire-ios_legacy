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

final class SettingsClientViewControllerTests: ZMSnapshotTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    var sut: SettingsClientViewController!
    var client: UserClient!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()

        let otherYearFormatter =  WRDateFormatter.otherYearFormatter

        XCTAssertEqual(otherYearFormatter.locale.identifier, "en_US", "otherYearFormatter.locale.identifier is \(otherYearFormatter.locale.identifier)")

        client = mockUserClient()
    }

    override func tearDown() {
        sut = nil
        client = nil

        coreDataFixture = nil

        super.tearDown()
    }

    func prepareSut(mode: UIUserInterfaceStyle = .light) {
        sut = SettingsClientViewController(userClient: client)
        sut.overrideUserInterfaceStyle = mode
        sut.isLoadingViewVisible = false
    }

    func testForLightTheme() {
        prepareSut()

        verify(matching: sut)
    }

    func testForDarkTheme() {
        prepareSut(mode: .dark)

        verify(matching: sut)
    }

    func testForLightThemeWrappedInNavigationController() {
        prepareSut()
        let navWrapperController = sut.wrapInNavigationController()

        verify(matching: navWrapperController)
    }
}
