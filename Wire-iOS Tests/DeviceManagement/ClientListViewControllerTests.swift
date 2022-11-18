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

final class ClientListViewControllerTests: ZMSnapshotTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    var sut: ClientListViewController!
    var mockUser: MockUserType!
    var client: UserClient!
    var selfClient: UserClient!

    weak var clientRemovalObserver: ClientRemovalObserver!

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()

        mockUser = SwiftMockLoader.mockUsers().first
        selfClient = mockUserClient()
        client = mockUserClient()
    }

    override func tearDown() {
        sut = nil
        mockUser = nil
        client = nil
        selfClient = nil

        resetColorScheme()

        coreDataFixture = nil

        super.tearDown()
    }

    /// Prepare SUT for snapshot tests
    ///
    /// - Parameters:
    /// - mode: the color for UIUserInterfaceStyle
    /// - numberOfClients: number of clients other than self device. Default: display 3 cells, to show footer in same screen
    func prepareSut(mode: UIUserInterfaceStyle = .light, numberOfClients: Int = 3) {
        var clientsList: [UserClient]?

        for _ in 0 ..< numberOfClients {
            if clientsList == nil {
                clientsList = []
            }
            clientsList?.append(client)
        }

        sut = ClientListViewController(clientsList: clientsList,
                                       selfClient: selfClient,
                                       credentials: nil,
                                       detailedView: true,
                                       showTemporary: true)

        sut.isLoadingViewVisible = false
        sut.overrideUserInterfaceStyle = mode
    }

    func testThatObserverIsNonRetained() {
        prepareSut()

        let emailCredentials = ZMEmailCredentials(email: "foo@bar.com", password: "12345678")
        sut.deleteUserClient(client, credentials: emailCredentials)

        clientRemovalObserver = sut.removalObserver
        XCTAssertNotNil(clientRemovalObserver)

        sut.viewDidDisappear(false)
        XCTAssertNil(clientRemovalObserver)
    }

    func testForLightTheme() {
        prepareSut()
        verify(matching: sut)
    }

    func testForDarkTheme() {
        prepareSut(mode: .dark)
        verify(matching: sut)
    }

    func testForLightThemeWrappedInNavigationController() {
        prepareSut()
        let navWrapperController = sut.wrapInNavigationController()
        navWrapperController.navigationBar.tintColor = UIColor.accent()

        verify(matching: navWrapperController)
    }

    func testForOneDeviceWithNoEditButton() {
        prepareSut(numberOfClients: 0)
        let navWrapperController = sut.wrapInNavigationController()

        verify(matching: navWrapperController)
    }

    func testForOneDeviceWithBackButtonAndNoEditButton() {
        prepareSut(numberOfClients: 0)
        let mockRootViewController = UIViewController()
        let navWrapperController = mockRootViewController.wrapInNavigationController()
        navWrapperController.pushViewController(sut, animated: false)

        verify(matching: navWrapperController)
    }

    func testForEditMode() {
        prepareSut()
        let navWrapperController = sut.wrapInNavigationController()
        navWrapperController.navigationBar.tintColor = UIColor.accent()
        let editButton = sut.navigationItem.rightBarButtonItem!
        UIApplication.shared.sendAction(editButton.action!, to: editButton.target, from: nil, for: nil)

        verify(matching: navWrapperController)
    }
}
