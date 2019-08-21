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

extension NSLayoutConstraint.Axis : CustomStringConvertible {
    public var description: String {
        switch self {
        case .horizontal : return "horizontal"
        case .vertical : return "vertical"
        @unknown default :
            return "unknown"
        }
    }
}

final class LandingViewControllerTests: XCTestCase {
    
    var sut: LandingViewController!
    var mockParentViewController: UIViewController! = UIViewController()

    override func setUp() {
        super.setUp()
        sut = LandingViewController()
        mockParentViewController.addChild(sut)
    }
    
    override func tearDown() {
        sut = nil
        mockParentViewController = nil
        super.tearDown()
    }
    
    func testThatStackViewAxisChanagesWhenSizeClassChanges() {
        // GIVEN
        sut.loadViewIfNeeded()
        
        var traitCollection = UITraitCollection(horizontalSizeClass: .regular)
        mockParentViewController.setOverrideTraitCollection(traitCollection, forChild: sut)
        sut.traitCollectionDidChange(nil)
        XCTAssertEqual(sut.buttonStackView.axis, .horizontal, "buttonStackView.axis is \(sut.buttonStackView.axis)")
        
        // WHEN
        traitCollection = UITraitCollection(horizontalSizeClass: .compact)
        mockParentViewController.setOverrideTraitCollection(traitCollection, forChild: sut)
        sut.traitCollectionDidChange(nil)
        
        // THEN
        XCTAssertEqual(sut.buttonStackView.axis, .vertical, "buttonStackView.axis is \(sut.buttonStackView.axis)")
    }

}
