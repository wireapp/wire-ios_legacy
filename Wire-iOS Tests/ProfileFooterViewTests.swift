//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

class ProfileFooterViewTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
    }

    func testThatItOnlyAllowsEligibleActionsAsKey() {
        let view = ProfileFooterView()

        // WHEN: the first action is eligible
        view.configure(with: [.openOneToOne, .archive])
        XCTAssertEqual(view.leftAction, .openOneToOne)
        XCTAssertEqual(view.rightActions, [.archive])

        // WHEN: the first action is not eligible
        view.configure(with: [.archive, .openOneToOne])
        XCTAssertEqual(view.leftAction, nil)
        XCTAssertEqual(view.rightActions, [.archive, .openOneToOne])

        // WHEN: the only action is eligible
        view.configure(with: [.openOneToOne])
        XCTAssertEqual(view.leftAction, .openOneToOne)
        XCTAssertEqual(view.rightActions, [])

        // WHEN: the only action is not eligible
        view.configure(with: [.archive])
        XCTAssertEqual(view.leftAction, nil)
        XCTAssertEqual(view.rightActions, [.archive])
    }

    func testWithOneAction() {
        let view = ProfileFooterView()
        view.overrideUserInterfaceStyle = .light
        view.configure(with: [.openOneToOne])
        view.frame.size = view.systemLayoutSizeFitting(CGSize(width: 375, height: 0))
        verify(view: view)
    }

    func testWithMultipleActions() {
        let view = ProfileFooterView()
        view.overrideUserInterfaceStyle = .light
        view.configure(with: [.openOneToOne, .archive])
        view.frame.size = view.systemLayoutSizeFitting(CGSize(width: 375, height: 0))
        verify(view: view)
    }

    func testThatItUpdates() {
        let view = ProfileFooterView()
        view.overrideUserInterfaceStyle = .light
        view.configure(with: [.openOneToOne, .archive])
        view.configure(with: [.createGroup])
        view.frame.size = view.systemLayoutSizeFitting(CGSize(width: 375, height: 0))
        verify(view: view)
    }

}
