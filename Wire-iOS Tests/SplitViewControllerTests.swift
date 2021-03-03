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

final class MockPanGestureRecognizer: UIPanGestureRecognizer {
    let mockState: UIGestureRecognizer.State
    var mockLocation: CGPoint?
    var mockTranslation: CGPoint?

    init(location: CGPoint?, translation: CGPoint?, state: UIGestureRecognizer.State) {
        mockLocation = location
        mockTranslation = translation
        mockState = state

        super.init(target: nil, action: nil)
    }

    override func location(in view: UIView?) -> CGPoint {
        if let mockLocation = mockLocation {
            return mockLocation
        }
        return super.location(in: view)
    }

    override func translation(in view: UIView?) -> CGPoint {
        if let mockTranslation = mockTranslation {
            return mockTranslation
        }
        return super.translation(in: view)
    }

    override var state: UIGestureRecognizer.State {
        get {
            return mockState
        }
        set {}
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

    override func setUp() {
        super.setUp()

        UIView.setAnimationsEnabled(false)

        mockSplitViewControllerDelegate = MockSplitViewControllerDelegate()
        sut = SplitViewController()

        sut.delegate = mockSplitViewControllerDelegate
        mockParentViewController = UIViewController()
        mockParentViewController.addToSelf(sut)
    }

    override func tearDown() {
        sut = nil
        mockParentViewController = nil
        mockSplitViewControllerDelegate = nil

        UIView.setAnimationsEnabled(true)

        super.tearDown()
    }

    func testThatSwitchFromRegularModeToCompactModeChildViewsUpdatesTheirSize() {
        // GIVEN

        // simulate iPad Pro 12.9 inch landscape mode
        let iPadHeight: CGFloat = 1024
        let iPadWidth: CGFloat = 1366
        let listViewWidth: CGFloat = 336
        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: iPadWidth, height: iPadHeight))

        let regularTraitCollection = UITraitCollection(horizontalSizeClass: .regular)
        mockParentViewController.setOverrideTraitCollection(regularTraitCollection, forChild: sut)
        sut.view.layoutIfNeeded()

        let leftViewWidth = sut.leftView.frame.width

        // check the width match the hard code value in SplitViewController
        XCTAssertEqual(leftViewWidth, listViewWidth)
        XCTAssertEqual(sut.rightView.frame.width, iPadWidth - listViewWidth)

        // WHEN
        let compactWidth = round(iPadWidth / 3)
        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: compactWidth, height: iPadHeight))
        let compactTraitCollection = UITraitCollection(horizontalSizeClass: .compact)
        mockParentViewController.setOverrideTraitCollection(compactTraitCollection, forChild: sut)
        sut.view.layoutIfNeeded()

        // THEN
        XCTAssertEqual(sut.leftView.frame.width, compactWidth)
        XCTAssertEqual(sut.rightView.frame.width, compactWidth)
    }

    fileprivate func setupLeftView(isLeftViewControllerRevealed: Bool,
                                   animated: Bool = true,
                                   file: StaticString = #file,
                                   line: UInt = #line) {
        sut.leftViewController = UIViewController()
        sut.rightViewController = UIViewController()

        let compactTraitCollection = UITraitCollection(horizontalSizeClass: .compact)
        mockParentViewController.setOverrideTraitCollection(compactTraitCollection, forChild: sut)

        sut.isLeftViewControllerRevealed = isLeftViewControllerRevealed
        sut.setLeftViewControllerRevealed(isLeftViewControllerRevealed, animated: animated)

        XCTAssertEqual(sut.rightView.frame.origin.x, isLeftViewControllerRevealed ? sut.leftView.frame.size.width : 0, file: file, line: line)
    }

    func testThatPanRightViewToLessThanHalfWouldBounceBack() {
        // GIVEN
        setupLeftView(isLeftViewControllerRevealed: false)

        // WHEN
        let beganGestureRecognizer = MockPanGestureRecognizer(location: nil, translation: nil, state: .began)
        sut.onHorizontalPan(beganGestureRecognizer)

        // if pans less than half of the width, the right view will bounce back
        let panOffset: CGFloat = sut.view.frame.size.width / 2 - 10
        let gestureRecognizer = MockPanGestureRecognizer(location: nil, translation: CGPoint(x: panOffset, y: 0), state: .changed)
        sut.onHorizontalPan(gestureRecognizer)

        // THEN
        XCTAssertEqual(sut.rightView.frame.origin.x, panOffset)

        // WHEN
        let endedGestureRecognizer = MockPanGestureRecognizer(location: nil, translation: nil, state: .ended)
        sut.onHorizontalPan(endedGestureRecognizer)

        // THEN
        XCTAssertEqual(sut.rightView.frame.origin.x, 0)
    }

    func testThatPanRightViewToMoreThanHalfWouldRevealLeftView() {
        // GIVEN
        setupLeftView(isLeftViewControllerRevealed: false)

        // WHEN
        let beganGestureRecognizer = MockPanGestureRecognizer(location: nil, translation: nil, state: .began)
        sut.onHorizontalPan(beganGestureRecognizer)

        // if pans more than half of the width, the left view will be revealed
        let panOffset: CGFloat = sut.view.frame.size.width / 2 + 10
        let gestureRecognizer = MockPanGestureRecognizer(location: nil, translation: CGPoint(x: panOffset, y: 0), state: .changed)
        sut.onHorizontalPan(gestureRecognizer)

        // THEN
        XCTAssertEqual(sut.rightView.frame.origin.x, panOffset)

        // WHEN
        let endedGestureRecognizer = MockPanGestureRecognizer(location: nil, translation: nil, state: .ended)
        sut.onHorizontalPan(endedGestureRecognizer)

        // THEN
        XCTAssertEqual(sut.rightView.frame.origin.x, sut.view.frame.size.width, "rightView should stop at the right edge of the sut.view!")
    }

    /// TODO
    func testThatSetLeftViewControllerUnrevealedWithoutAnimationHidesLeftView() {
        // GIVEN
        setupLeftView(isLeftViewControllerRevealed: true, animated: false)

        // WHEN
        sut.setLeftViewControllerRevealed(false, animated: false)

        // THEN
        XCTAssert(sut.leftView.isHidden)
    }
}
