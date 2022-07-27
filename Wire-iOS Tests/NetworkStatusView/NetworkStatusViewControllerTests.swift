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

final class MockConversationRootViewController: UIViewController, NetworkStatusBarDelegate {
    var bottomMargin: CGFloat = 0

    var shouldAnimateNetworkStatusView: Bool = true

    var networkStatusViewController: NetworkStatusViewController!

    func showInIPad(networkStatusViewController: NetworkStatusViewController, with orientation: UIInterfaceOrientation) -> Bool {
        return true
    }
}

final class MockConversationListViewController: UIViewController, NetworkStatusBarDelegate {
    var bottomMargin: CGFloat = 0

    var shouldAnimateNetworkStatusView: Bool = true

    var networkStatusViewController: NetworkStatusViewController!

    func showInIPad(networkStatusViewController: NetworkStatusViewController, with orientation: UIInterfaceOrientation) -> Bool {
        return false
    }
}

final class NetworkStatusViewControllerTests: XCTestCase {
    var sutRoot: NetworkStatusViewController!
    var sutList: NetworkStatusViewController!

    var mockDevice: MockDevice!
    var mockApplication: MockApplication!
    var mockConversationRoot: MockConversationRootViewController!
    var mockConversationList: MockConversationListViewController!

    override func setUp() {
        super.setUp()
        mockDevice = MockDevice()
        mockApplication = MockApplication()

        mockConversationList = MockConversationListViewController()
        sutList = NetworkStatusViewController(device: mockDevice, application: mockApplication)
        mockConversationList.networkStatusViewController = sutList
        mockConversationList.addToSelf(sutList)
        sutList.delegate = mockConversationList

        mockConversationRoot = MockConversationRootViewController()
        sutRoot = NetworkStatusViewController(device: mockDevice, application: mockApplication)
        mockConversationRoot.networkStatusViewController = sutRoot
        mockConversationRoot.addToSelf(sutRoot)
        sutRoot.delegate = mockConversationRoot
    }

    override func tearDown() {
        sutList = nil
        sutRoot = nil
        mockDevice = nil
        mockApplication = nil
        mockConversationRoot = nil
        mockConversationList = nil

        super.tearDown()
    }

    fileprivate func setUpSut(userInterfaceIdiom: UIUserInterfaceIdiom,
                              horizontalSizeClass: UIUserInterfaceSizeClass,
                              orientation: UIInterfaceOrientation,
                              listState: NetworkStatusViewState = .offlineExpanded,
                              rootState: NetworkStatusViewState = .offlineExpanded) {
        sutList.update(state: listState)
        sutRoot.update(state: rootState)

        mockDevice.userInterfaceIdiom = userInterfaceIdiom
        mockApplication.statusBarOrientation = orientation

        let traitCollection = UITraitCollection(horizontalSizeClass: horizontalSizeClass)
        mockConversationList.setOverrideTraitCollection(traitCollection, forChild: sutList)
        mockConversationRoot.setOverrideTraitCollection(traitCollection, forChild: sutRoot)

    }

    fileprivate func checkResult(listState: NetworkStatusViewState,
                                 rootState: NetworkStatusViewState,
                                 file: StaticString = #file, line: UInt = #line) {

        XCTAssertEqual(sutList.networkStatusView.state, listState, "List's networkStatusView.state should be equal to \(listState)", file: file, line: line)
        XCTAssertEqual(sutRoot.networkStatusView.state, rootState, "Root's networkStatusView.state should be equal to \(rootState)", file: file, line: line)
    }

    /// check for networkStatusView state is updated after device properties are changed
    ///
    /// - Parameters:
    ///   - userInterfaceIdiom: updated idiom
    ///   - horizontalSizeClass: updated size class
    ///   - orientation: updated orientation
    ///   - listState: expected networkStatusView state in conversation list
    ///   - rootState: expected networkStatusView state in conversation root
    fileprivate func checkForNetworkStatusViewState(userInterfaceIdiom: UIUserInterfaceIdiom,
                                                    horizontalSizeClass: UIUserInterfaceSizeClass,
                                                    orientation: UIInterfaceOrientation,
                                                    listState: NetworkStatusViewState,
                                                    rootState: NetworkStatusViewState,
                                                    file: StaticString = #file, line: UInt = #line) {
        // GIVEN & WHEN
        setUpSut(userInterfaceIdiom: userInterfaceIdiom, horizontalSizeClass: horizontalSizeClass, orientation: orientation)

        // THEN
        checkResult(listState: listState, rootState: rootState, file: file, line: line)
    }

    func testThatNetworkStatusViewShowsOnListButNotRootWhenDevicePropertiesIsIPadLandscapeRegularMode() {
        checkForNetworkStatusViewState(userInterfaceIdiom: .pad,
                                       horizontalSizeClass: .regular,
                                       orientation: .landscapeLeft,
                                       listState: .online,
                                       rootState: .offlineExpanded)
    }

    func testThatNetworkStatusViewShowsOnRootButNotListWhenDevicePropertiesIsIPadPortraitRegularMode() {
        checkForNetworkStatusViewState(userInterfaceIdiom: .pad,
                                       horizontalSizeClass: .regular,
                                       orientation: .portrait,
                                       listState: .online,
                                       rootState: .offlineExpanded)
    }

    func testThatNetworkStatusViewShowsOnListButNotRootWhenDevicePropertiesIsIPadLandscapeCompactMode() {
        checkForNetworkStatusViewState(userInterfaceIdiom: .pad,
                                       horizontalSizeClass: .compact,
                                       orientation: .landscapeLeft,
                                       listState: .offlineExpanded,
                                       rootState: .offlineExpanded)
    }

    func testThatNetworkStatusViewShowsOnBothWhenDevicePropertiesIsIPhonePortraitCompactMode() {
        checkForNetworkStatusViewState(userInterfaceIdiom: .phone,
                                       horizontalSizeClass: .compact,
                                       orientation: .portrait,
                                       listState: .offlineExpanded,
                                       rootState: .offlineExpanded)
    }

    func testThatIPadRespondsToScreenSizeChanging() {
        // GIVEN
        let userInterfaceIdiom: UIUserInterfaceIdiom = .pad
        let horizontalSizeClass: UIUserInterfaceSizeClass = .regular

        setUpSut(userInterfaceIdiom: userInterfaceIdiom, horizontalSizeClass: horizontalSizeClass, orientation: .portrait)
        checkResult(listState: .online, rootState: .offlineExpanded)

        // Portrait

        // WHEN
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // THEN
        checkResult(listState: .online, rootState: .offlineExpanded)

        // Landscape
        mockApplication.statusBarOrientation = .landscapeLeft

        // WHEN
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // THEN
        checkResult(listState: .online, rootState: .offlineExpanded)
    }
}

final class NetworkStatusViewControllerRetainTests: XCTestCase {

    weak var sut: NetworkStatusViewController! = nil

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testNetworkStatusViewControllerIsNotRetainedAfterPerformIsCalled() {
        autoreleasepool {
            // GIVEN
            var networkStatusViewController: NetworkStatusViewController! = NetworkStatusViewController()
            sut = networkStatusViewController

            // WHEN
            networkStatusViewController.viewDidLoad()

            networkStatusViewController.didChangeAvailability(newState: .online)
            NSObject.cancelPreviousPerformRequests(withTarget: networkStatusViewController!, selector: #selector(networkStatusViewController.applyPendingState), object: nil)

            networkStatusViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
    }
}
