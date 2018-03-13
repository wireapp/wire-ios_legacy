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

import Cartography

class MockContainerViewController: UIViewController, NetworkStatusBarDelegate {
    var shouldShowNetworkStatusUIInIPadRegularLandscape: Bool = true

    var shouldShowNetworkStatusUIInIPadRegularPortrait: Bool = true

    var isViewDidAppear: Bool = true
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
        mockContainerViewController.view.addSubview(sut.view)
        sut.delegate = mockContainerViewController

        mockContentView = UIView()
        mockContentView.backgroundColor = .white
        mockContainerViewController.view.addSubview(mockContentView)

        sut.createConstraints(bottomView: mockContentView, containerView: mockContainerViewController.view, topMargin: UIScreen.safeArea.top)

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

final class MockConversationRootViewController: UIViewController, NetworkStatusBarDelegate {
    var isViewDidAppear: Bool = true
    
    var networkStatusViewController: NetworkStatusViewController!
    
    var shouldShowNetworkStatusUIInIPadRegularLandscape: Bool {
        return false
    }
    
    var shouldShowNetworkStatusUIInIPadRegularPortrait: Bool {
        return true
    }
}

final class MockConversationListViewController: UIViewController, NetworkStatusBarDelegate {
    var isViewDidAppear: Bool = true
    
    var networkStatusViewController: NetworkStatusViewController!
    
    var shouldShowNetworkStatusUIInIPadRegularLandscape: Bool {
        return true
    }
    
    var shouldShowNetworkStatusUIInIPadRegularPortrait: Bool {
        return false
    }
}

final class NetworkStatusViewControllerTests: XCTestCase {
    var sutRoot: NetworkStatusViewController!
    var sutList: NetworkStatusViewController!
    
    var mockDevice: MockDevice!
    var mockConversationRoot: MockConversationRootViewController!
    var mockConversationList: MockConversationListViewController!
    
    override func setUp() {
        super.setUp()
        mockDevice = MockDevice()
        
        mockConversationList = MockConversationListViewController()
        sutList = NetworkStatusViewController(container: .conversationList, device: mockDevice)
        mockConversationList.networkStatusViewController = sutList
        mockConversationList.addToSelf(sutList)
        sutList.delegate = mockConversationList
        
        mockConversationRoot = MockConversationRootViewController()
        sutRoot = NetworkStatusViewController(container: .conversationRoot, device: mockDevice)
        mockConversationRoot.networkStatusViewController = sutRoot
        mockConversationRoot.addToSelf(sutRoot)
        sutRoot.delegate = mockConversationRoot
    }
    
    override func tearDown() {
        sutList = nil
        sutRoot = nil
        mockDevice = nil
        mockConversationRoot = nil
        mockConversationList = nil

        super.tearDown()
    }
    
    fileprivate func setUpSut(userInterfaceIdiom: UIUserInterfaceIdiom,
                              horizontalSizeClass: UIUserInterfaceSizeClass,
                              orientation: UIDeviceOrientation,
                              listState: NetworkStatusViewState = .offlineExpanded,
                              rootState: NetworkStatusViewState = .offlineExpanded) {
        sutList.update(state: listState)
        sutRoot.update(state: rootState)
        
        mockDevice.userInterfaceIdiom = userInterfaceIdiom
        mockDevice.orientation = orientation
        
        let traitCollection = UITraitCollection(horizontalSizeClass: horizontalSizeClass)
        mockConversationList.setOverrideTraitCollection(traitCollection, forChildViewController: sutList)
        mockConversationRoot.setOverrideTraitCollection(traitCollection, forChildViewController: sutRoot)
        
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
                                                    orientation: UIDeviceOrientation,
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
                                       listState: .offlineExpanded,
                                       rootState: .online)
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
    
    func testThatNotifyWhenOfflineShowsOneNetworkStatusViewOnIPad() {
        // GIVEN
        let userInterfaceIdiom: UIUserInterfaceIdiom = .pad
        let horizontalSizeClass: UIUserInterfaceSizeClass = .regular
        let orientation: UIDeviceOrientation = .landscapeLeft
        
        setUpSut(userInterfaceIdiom: userInterfaceIdiom,
                 horizontalSizeClass: horizontalSizeClass,
                 orientation: orientation,
                 listState: .offlineCollapsed,
                 rootState: .offlineCollapsed)

        // WHEN
        _ = NetworkStatusViewController.notifyWhenOffline()
        
        // THEN
        checkResult(listState: .offlineExpanded, rootState: .online)
    }

    func testThatNotifyWhenOfflineShowsBothNetworkStatusViewOnIPhone() {
        // GIVEN
        let userInterfaceIdiom: UIUserInterfaceIdiom = .phone
        let horizontalSizeClass: UIUserInterfaceSizeClass = .compact
        let orientation: UIDeviceOrientation = .portrait

        setUpSut(userInterfaceIdiom: userInterfaceIdiom,
                 horizontalSizeClass: horizontalSizeClass,
                 orientation: orientation,
                 listState: .offlineCollapsed,
                 rootState: .offlineCollapsed)

        // WHEN
        _ = NetworkStatusViewController.notifyWhenOffline()

        // THEN
        checkResult(listState: .offlineExpanded, rootState: .offlineExpanded)
    }

    func testThatIPadRespondsToScreenSizeChanging() {
        // GIVEN
        let userInterfaceIdiom: UIUserInterfaceIdiom = .pad
        let horizontalSizeClass: UIUserInterfaceSizeClass = .regular
        let orientation: UIDeviceOrientation = .landscapeLeft
        
        let listState = NetworkStatusViewState.offlineExpanded
        let rootState = NetworkStatusViewState.online
        
        setUpSut(userInterfaceIdiom: userInterfaceIdiom, horizontalSizeClass: horizontalSizeClass, orientation: orientation)
        checkResult(listState: listState, rootState: rootState)

        // Portrait
        
        // WHEN
        let portraitSize = CGSize(width: 768, height: 1024)
        sutList.viewWillTransition(to: portraitSize, with: nil)
        sutRoot.viewWillTransition(to: portraitSize, with: nil)

        // THEN
        checkResult(listState: NetworkStatusViewState.online, rootState: .offlineExpanded)

        // Landscape

        // WHEN
        let landscapeSize = CGSize(width: 1024, height: 768)
        sutList.viewWillTransition(to: landscapeSize, with: nil)
        sutRoot.viewWillTransition(to: landscapeSize, with: nil)
        
        // THEN
        checkResult(listState: NetworkStatusViewState.offlineExpanded, rootState: .online)
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

    func testNetworkStatusViewControllerIsNotRetainedAfterTimerIsScheduled(){
        autoreleasepool{
            // GIVEN
            var networkStatusViewController: NetworkStatusViewController! = NetworkStatusViewController(container: .conversationList)
            sut = networkStatusViewController


            // WHEN
            networkStatusViewController.viewDidLoad()
            let _ = NetworkStatusViewController.notifyWhenOffline()
            networkStatusViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
    }
}
