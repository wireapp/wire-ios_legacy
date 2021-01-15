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

import Foundation
import XCTest
@testable import Wire

final class AppLockModuleViewTests: XCTestCase {

    private var sut: AppLockModule.View!
    private var presenter: AppLockModule.MockPresenter!

    override func setUp() {
        super.setUp()
        sut = AppLockModule.View()
        presenter = AppLockModule.MockPresenter()

        sut.presenter = presenter
    }

    override func tearDown() {
        sut = nil
        presenter = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_ItStartsThePresenter() {
        // When
        sut.loadViewIfNeeded()

        // Then
        XCTAssertEqual(presenter.methodCalls.start.count, 1)
    }

}
