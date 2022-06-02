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
import SnapshotTesting
@testable import Wire

class ChangeHandleViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        let mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        mockSelfUser.handle = nil
        mockSelfUser.domain = "wire.com"
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)
    }

    func testThatItRendersCorrectInitially() {
        verify(newHandle: nil, availability: .unknown)
    }

    func testThatItRendersCorrectInitially_Federated() {
        verify(newHandle: nil, availability: .unknown, federationEnabled: true)
    }

    func testThatItRendersCorrectNewHandleUnavailable() {
        verify(newHandle: "james", availability: .taken)
    }

    func testThatItRendersCorrectNewHandleAvailable() {
        verify(newHandle: "james_xXx", availability: .available)
    }

    func testThatItRendersCorrectNewHandleNotYetChecked() {
        verify(newHandle: "vanessa92", availability: .unknown)
    }

    private func verify(currentHandle: String = "bruno",
                        newHandle: String?,
                        availability: HandleChangeState.HandleAvailability,
                        federationEnabled: Bool = false,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {
        let state = HandleChangeState(currentHandle: currentHandle, newHandle: newHandle, availability: availability)
        let sut = ChangeHandleViewController(state: state, federationEnabled: federationEnabled)
        verify(matching: sut.prepareForSnapshots(), file: file, testName: testName, line: line)
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
        navigationController.view.backgroundColor = .darkGray
        return navigationController.view
    }

}
