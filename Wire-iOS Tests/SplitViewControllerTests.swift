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

class MockPanGestureRecognizer: UIPanGestureRecognizer {
    var testState: UIGestureRecognizerState?
    var testLocation: CGPoint?
    var testTranslation: CGPoint?

    init(location: CGPoint?, translation: CGPoint?, state: UIGestureRecognizerState) {
        testLocation = location
        testTranslation = translation
        testState = state

        super.init(target: nil, action: nil)
    }

    override func location(in view: UIView?) -> CGPoint {
        if let testLocation = testLocation {
            return testLocation
        }
        return super.location(in: view)
    }

    override func translation(in view: UIView?) -> CGPoint {
        if let testTranslation = testTranslation {
            return testTranslation
        }
        return super.translation(in: view)
    }

    override var state: UIGestureRecognizerState {
        if let testState = testState {
            return testState
        }
        return super.state
    }
}


final class MockSplitViewControllerDelegate: NSObject, SplitViewControllerDelegate {
    func splitViewControllerShouldMoveLeftViewController(_ splitViewController: SplitViewController) -> Bool {
        return true
    }
}

final class SplitViewControllerTests: XCTestCase {
    
    var sut: SplitViewController!
    var mockParentViewController: UIViewController!
    var mockSplitViewControllerDelegate: MockSplitViewControllerDelegate!

    // simulate iPad Pro 12.9 inch landscape mode
    let iPadHeight: CGFloat = 1024
    let iPadWidth: CGFloat = 1366
    let listViewWidth: CGFloat = 336

    override func setUp() {
        super.setUp()

        mockSplitViewControllerDelegate = MockSplitViewControllerDelegate()
        sut = SplitViewController()
        sut.delegate = mockSplitViewControllerDelegate
        mockParentViewController = UIViewController()
        mockParentViewController.addToSelf(sut) ///TODO: set size class before this line

    }
    
    override func tearDown() {
        sut = nil
        mockParentViewController = nil
        mockSplitViewControllerDelegate = nil

        super.tearDown()
    }

    func testThatWhenSwitchFromRegularModeToCompactModeChildViewsUpdatesTheirSize(){
        // GIVEN
        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: iPadWidth, height: iPadHeight))

        let regularTraitCollection = UITraitCollection(horizontalSizeClass: .regular)
        mockParentViewController.setOverrideTraitCollection(regularTraitCollection, forChildViewController: sut)
        sut.view.layoutIfNeeded()

        let leftViewWidth = sut.leftView.frame.width

        // check the width match the hard code value in SplitViewController
        XCTAssertEqual(leftViewWidth, listViewWidth)
        XCTAssertEqual(sut.rightView.frame.width, iPadWidth - listViewWidth)

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

    func testForPan(){
        // GIVEN
        sut.leftViewController = UIViewController()
        sut.rightViewController = UIViewController()

        let compactTraitCollection = UITraitCollection(horizontalSizeClass: .compact)
        mockParentViewController.setOverrideTraitCollection(compactTraitCollection, forChildViewController: sut)

        sut.isLeftViewControllerRevealed = false
        sut.view.layoutIfNeeded()

        XCTAssertEqual(sut.rightView.frame.origin.x, 0)

        // WHEN
        let beganGestureRecognizer = MockPanGestureRecognizer(location: nil, translation: nil, state: .began)
        sut.onHorizontalPan(beganGestureRecognizer)

        let panOffset: CGFloat = 100
        let gestureRecognizer = MockPanGestureRecognizer(location: nil, translation: CGPoint(x: panOffset, y: 0), state: .changed)
        sut.onHorizontalPan(gestureRecognizer)

        // THEN
        XCTAssertEqual(sut.rightView.frame.origin.x, panOffset)
    }
}
