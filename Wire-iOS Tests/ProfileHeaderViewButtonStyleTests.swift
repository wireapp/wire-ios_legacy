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

final class ProfileHeaderViewButtonStyleTests: XCTestCase {
    
    var sut: ProfileHeaderView!
    
    override func setUp() {
        super.setUp()

        let model = ProfileHeaderViewModel(user: nil, fallbackName: "Jose Luis", addressBookName: nil, navigationControllerViewControllerCount: 0)

        sut = ProfileHeaderView(with: model, MockIdiomSizeClassOrientation.self)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatDismissButtonSwitchesStyleWhenSizeClassChangeFromRegularToCompact() {
        // GIVEN
        MockIdiomSizeClassOrientation.currentHorizontalSizeClass = .regular
        MockIdiomSizeClassOrientation.currentOrientation = .portrait
        sut.traitCollectionDidChange(nil)
        XCTAssertEqual(sut.headerStyle, .noButton, "sut.headerStyle is \(sut.headerStyle)")

        // WHEN
        MockIdiomSizeClassOrientation.currentHorizontalSizeClass = .compact
        MockIdiomSizeClassOrientation.currentOrientation = .portrait
        sut.traitCollectionDidChange(nil)

        // THEN
        XCTAssertEqual(sut.headerStyle, .cancelButton, "sut.headerStyle is \(sut.headerStyle)")
    }

    func testThatDismissButtonSwitchesStyleWhenSizeClassChangeFromCompactToRegular() {
        // GIVEN
        MockIdiomSizeClassOrientation.currentHorizontalSizeClass = .compact
        MockIdiomSizeClassOrientation.currentOrientation = .portrait
        sut.traitCollectionDidChange(nil)
        XCTAssertEqual(sut.headerStyle, .cancelButton, "sut.headerStyle is \(sut.headerStyle)")

        // WHEN
        MockIdiomSizeClassOrientation.currentHorizontalSizeClass = .regular
        MockIdiomSizeClassOrientation.currentOrientation = .portrait
        sut.traitCollectionDidChange(nil)
        
        // THEN
        XCTAssertEqual(sut.headerStyle, .noButton, "sut.headerStyle is \(sut.headerStyle)")
    }

    func testThatDismissButtonStyleIsCancelWhenIdiomIsPhone() {
        // GIVEN
        MockIdiomSizeClassOrientation.currentIdiom = .phone
        MockIdiomSizeClassOrientation.currentHorizontalSizeClass = .compact
        MockIdiomSizeClassOrientation.currentOrientation = .portrait
        
        // WHEN
        sut.traitCollectionDidChange(nil)

        // THEN
        XCTAssertEqual(sut.headerStyle, .cancelButton, "sut.headerStyle is \(sut.headerStyle)")
    }
    
    func testThatDismissButtonStyleIsBackWhenNavControllerCountGreatThanOne() {
        // GIVEN
        let model = ProfileHeaderViewModel(user: nil, fallbackName: "Jose Luis", addressBookName: nil, navigationControllerViewControllerCount: 2)
        sut = ProfileHeaderView(with: model, MockIdiomSizeClassOrientation.self)
        MockIdiomSizeClassOrientation.currentHorizontalSizeClass = .regular
        MockIdiomSizeClassOrientation.currentOrientation = .portrait

        // WHEN
        sut.traitCollectionDidChange(nil)
        
        // THEN
        XCTAssertEqual(sut.headerStyle, .backButton, "sut.headerStyle is \(sut.headerStyle)")
    }
}
