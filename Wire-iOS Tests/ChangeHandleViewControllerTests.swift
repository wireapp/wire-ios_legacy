//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class ChangeHandleViewControllerTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()

        let mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        mockSelfUser.handle = nil
        mockSelfUser.domain = "wire.com"
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)
        snapshotBackgroundColor = .darkGray
    }

    func testThatItRendersCorrectInitially() {
        let state = HandleChangeState(currentHandle: "bruno", newHandle: nil, availability: .unknown)
        let sut = ChangeHandleViewController(state: state)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectNewHandleUnavailable() {
        let state = HandleChangeState(currentHandle: "bruno", newHandle: "james", availability: .taken)
        let sut = ChangeHandleViewController(state: state)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectNewHandleAvailable() {
        let state = HandleChangeState(currentHandle: "bruno", newHandle: "james_xXx", availability: .available)
        let sut = ChangeHandleViewController(state: state)
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectNewHandleNotYetChecked() {
        let state = HandleChangeState(currentHandle: "bruno", newHandle: "vanessa92", availability: .unknown)
        let sut = ChangeHandleViewController(state: state)
        verify(view: sut.prepareForSnapshots())
    }

}

fileprivate extension UIViewController {

    func prepareForSnapshots() -> UIView {
        let navigationController = wrapInNavigationController(navigationControllerClass: ClearBackgroundNavigationController.self)
        navigationController.navigationBar.tintColor = .brightOrange

        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()

        view.setNeedsLayout()
        view.layoutIfNeeded()
        return navigationController.view
    }

}
