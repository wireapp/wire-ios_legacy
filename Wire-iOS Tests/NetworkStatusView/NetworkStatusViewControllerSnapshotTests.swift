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

import Foundation
import Cartography
@testable import Wire

class MockContainerViewController: UIViewController, NetworkStatusBarDelegate {
    var bottomMargin: CGFloat = CGFloat.NetworkStatusBar.bottomMargin

    func showInIPad(networkStatusViewController: NetworkStatusViewController, with orientation: UIInterfaceOrientation) -> Bool {
        return true
    }

    var shouldAnimateNetworkStatusView: Bool = true
}

/// Snapshot tests for differnt margin and size of NetworkStatusViewController.view for all value of ZMNetworkState with other UIView at the bottom.
final class NetworkStatusViewControllerSnapshotTests: ZMSnapshotTestCase {

    var sut: NetworkStatusViewController!
    var mockContainerViewController: MockContainerViewController!
    var mockContentView: UIView!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

        mockContainerViewController = MockContainerViewController()
        mockContainerViewController.view.bounds.size = CGSize(width: 375.0, height: 667.0)
        mockContainerViewController.view.backgroundColor = .lightGray

        sut = NetworkStatusViewController()
        sut.view.backgroundColor = .gray
        mockContainerViewController.view.addSubview(sut.view)
        sut.delegate = mockContainerViewController

        mockContentView = UIView()
        mockContentView.backgroundColor = .white
        mockContainerViewController.view.addSubview(mockContentView)

        sut.createConstraintsInParentController(bottomView: mockContentView, controller: mockContainerViewController)

        constrain(mockContentView, mockContainerViewController.view) { mockContentView, view in
            mockContentView.left == view.left
            mockContentView.right == view.right

            mockContentView.bottom == view.bottom - UIScreen.safeArea.bottom
        }
    }

    override func tearDown() {
        sut = nil
        mockContainerViewController = nil
        mockContentView = nil

        super.tearDown()
    }

    fileprivate func verify(for newState: ZMNetworkState, file: StaticString = #file, line: UInt = #line) {
        // GIVEN
        sut.didChangeAvailability(newState: newState)

        // WHEN
        sut.applyPendingState()
        sut.view.layer.speed = 0 // freeze animations for deterministic tests

        // THEN
        verify(view: mockContainerViewController.view, file: file, line: line)
    }

    func testOnlineState() {
        verify(for: .online)
    }

    func testOfflineState() {
        verify(for: .offline)
    }

    func testOnlineSynchronizing() {
        verify(for: .onlineSynchronizing)
    }

}
