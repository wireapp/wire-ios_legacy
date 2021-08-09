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

class ScalableViewTests: XCTestCase {
    var size = XCTestCase.DeviceSizeIPhone5
    var sut: ScalableView!

    override func setUp() {
        super.setUp()

        sut = ScalableView(isScalingEnabled: true)
        sut.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatPinchGestureScalesViewUp() {
        // given
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.width))
        let scale: CGFloat = 2

        let gestureRecognizer = MockPinchGestureRecognizer(
            location: .zero,
            view: view,
            state: .changed,
            scale: scale
        )

        let location = CGPoint(x: -view.bounds.midX, y: -view.bounds.midY)
        let expectedTransform = view.transform
            .translatedBy(x: location.x, y: location.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -location.x, y: -location.y)

        // when
        sut.handlePinchGesture(gestureRecognizer)

        // then
        XCTAssert(view.transform == expectedTransform)
    }

    func testThatPinchGestureDoesntScaleViewDown() {
        // given
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.width))
        let scale: CGFloat = 0.5

        let gestureRecognizer = MockPinchGestureRecognizer(
            location: .zero,
            view: view,
            state: .changed,
            scale: scale
        )

        // when
        sut.handlePinchGesture(gestureRecognizer)

        // then
        XCTAssert(view.transform == .identity)
    }

    func testThatPanGestureTranslatesView_WhenViewIsScaled() {
        // given
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.width))
        view.transform = view.transform.scaledBy(x: 1.1, y: 1.1)

        let translation = CGPoint(x: 10, y: 10)
        let gestureRecongnizer = MockPanGestureRecognizer(
            location: view.center,
            translation: translation,
            view: view,
            state: .changed
        )

        let expectedTransform = view.transform.translatedBy(x: translation.x, y: translation.y)

        // when
        sut.handlePanGesture(gestureRecongnizer)

        // then
        XCTAssert(view.transform == expectedTransform)
    }

    func testThatPanGestureDoesntTranslateView_WhenViewIsNotScaled() {
        // given
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.width))

        let gestureRecongnizer = MockPanGestureRecognizer(
            location: view.center,
            translation: CGPoint(x: 10, y: 10),
            view: view,
            state: .changed
        )

        // when
        sut.handlePanGesture(gestureRecongnizer)

        // then
        XCTAssert(view.transform == .identity)
    }

}
