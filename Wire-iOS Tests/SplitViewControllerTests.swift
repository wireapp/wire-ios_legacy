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

final class SplitViewControllerTests: XCTestCase {
    
    var sut: SplitViewController!
    var mockParentViewController: UIViewController!

    // simulate iPad Pro 12.9 inch portrait mode
    let iPadHeight: CGFloat = 1024
    let iPadWidth: CGFloat = 1366

    override func setUp() {
        super.setUp()

        sut = SplitViewController()
        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: iPadWidth, height: iPadHeight))
        sut.viewDidLoad()

        mockParentViewController = UIViewController()
        mockParentViewController.addToSelf(sut)

    }
    
    override func tearDown() {
        sut = nil
        mockParentViewController = nil
        super.tearDown()
    }

    func testThatWhenSwitchFromRegularModeToCompactModeChildViewsUpdatesTheirSize(){
        // GIVEN
        let regularTraitCollection = UITraitCollection(horizontalSizeClass: .regular)
        mockParentViewController.setOverrideTraitCollection(regularTraitCollection, forChildViewController: sut)
        sut.view.layoutIfNeeded()

        let leftViewWidth = sut.leftView.frame.width

        // check the value match the hard code value in SplitViewController
        XCTAssertEqual(leftViewWidth, 336)
        XCTAssertEqual(sut.rightView.frame.width, iPadWidth - leftViewWidth)

        // WHEN
        let compactWidth = round(iPadWidth / 3)
        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: compactWidth, height: iPadHeight))
        let compactTraitCollection = UITraitCollection(horizontalSizeClass: .compact)
        mockParentViewController.setOverrideTraitCollection(compactTraitCollection, forChildViewController: sut)
        sut.view.layoutIfNeeded()

        // THEN
        XCTAssertEqual(sut.leftView.frame.width, compactWidth)
        XCTAssertEqual(sut.rightView.frame.width, compactWidth)
    }
}
