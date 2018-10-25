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

final class ClientListViewControllerTests: ZMSnapshotTestCase {
    
    var sut: ClientListViewController!
    var mockUser: MockUser!
    var client: UserClient!
    var selfClient: UserClient!

    override func setUp() {
        super.setUp()

        let user = MockUser.mockUsers()[0]
        mockUser = MockUser(for: user)

        selfClient = mockUserClient()
        client = mockUserClient()
    }
    
    override func tearDown() {
        sut = nil
        mockUser = nil
        client = nil
        selfClient = nil

        resetColorScheme()

        super.tearDown()
    }

    /// Prepare SUT for snapshot tests
    ///
    /// - Parameters:
    ///   - variant: the color cariant
    ///   - numberOfClients: number of clients other than self device. Default: display 3 cells, to show footer in same screen
    func prepareSut(variant: ColorSchemeVariant?, numberOfClients: Int = 3) {
        var clientsList: [UserClient]? = nil

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
                                       showTemporary: true,
                                       variant: variant)

        sut.showLoadingView = false
    }

    func testForTransparentBackground(){
        prepareSut(variant: nil)

        self.verify(view: sut.view)
    }

    func testForLightTheme(){
        prepareSut(variant: .light)

        self.verify(view: sut.view)
    }

    func testForDarkTheme(){
        prepareSut(variant: .dark)

        self.verify(view: sut.view)
    }

    func testForLightThemeWrappedInNavigationController(){
        prepareSut(variant: .light)
        let navWrapperController = sut.wrapInNavigationController()
        navWrapperController.navigationBar.tintColor = UIColor.accent()

        self.verify(view: navWrapperController.view)
    }

    func testForOneDeviceWithNoEditButton(){
        prepareSut(variant: .light, numberOfClients: 0)
        let navWrapperController = sut.wrapInNavigationController()

        self.verify(view: navWrapperController.view)
    }

    func testForOneDeviceWithBackButtonAndNoEditButton(){
        prepareSut(variant: .light, numberOfClients: 0)
        let mockRootViewController = UIViewController()
        let navWrapperController = mockRootViewController.wrapInNavigationController()
        navWrapperController.pushViewController(sut, animated: false)

        self.verify(view: navWrapperController.view)
    }

    func testForEditMode(){
        prepareSut(variant: .light)
        let navWrapperController = sut.wrapInNavigationController()
        navWrapperController.navigationBar.tintColor = UIColor.accent()
        let editButton = sut.navigationItem.rightBarButtonItem!
        UIApplication.shared.sendAction(editButton.action!, to: editButton.target, from: nil, for: nil)

        self.verify(view: navWrapperController.view)
    }
}
