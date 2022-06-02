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
import SnapshotTesting
@testable import Wire

final class ScreenCurtainTests: XCTestCase, ScreenCurtainDelegate {

    var sut: ScreenCurtain!
    var shouldShowScreenCurtain = false

    override func setUp() {
        super.setUp()
        sut = ScreenCurtain()
        sut.delegate = self
        shouldShowScreenCurtain = false
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Showing

    func test_ItIsVisible_IfNeeded() {
        // Given
        shouldShowScreenCurtain = true

        // When
        sut.applicationWillResignActive()

        // Then
        XCTAssertFalse(sut.isHidden)
    }

    func test_ItIsHidden_IfNeeded() {
        // Given
        shouldShowScreenCurtain = false

        // When
        sut.applicationWillResignActive()

        // Then
        XCTAssertTrue(sut.isHidden)
    }

    func test_ItIsHidden_IfNoDelegate() {
        // Given
        sut.delegate = nil

        // When
        sut.applicationWillResignActive()

        // Then
        XCTAssertTrue(sut.isHidden)
    }

    // MARK: - Hiding

    func test_ItIsHidden_WhenApplicationBecomesActive() {
        // Given
        sut.isHidden = false

        // When
        sut.applicationDidBecomeActive()

        // Then
        XCTAssertTrue(sut.isHidden)
    }

    // MARK: - UI

    func test_UI() {
        // Given
        sut.isHidden = false

        // Then
        verify(matching: sut.rootViewController!)
    }

}
