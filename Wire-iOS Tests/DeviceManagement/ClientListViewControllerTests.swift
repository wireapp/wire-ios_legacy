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

    override func setUp() {
        super.setUp()

        let user = MockUser.mockUsers()[0]
        mockUser = MockUser(for: user)
        mockUser.feature(withUserClients: 6)

        client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "102030405060708090"

        client.user = ZMUser.insertNewObject(in: uiMOC)
        client.deviceClass = "tablet"

        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        mockUser = nil
        client = nil

        ColorScheme.default().variant = .light

        super.tearDown()
    }

    func prepareSut() {
        sut = ClientListViewController(clientsList: Array(mockUser.clients) as? [UserClient],
                                       selfClient: client,
                                       credentials: nil, detailedView: true, showTemporary: true)

        sut.showLoadingView = false
    }

    func testForLightTheme(){
        prepareSut()

        self.verify(view: sut.view)
    }

    func testForDarkTheme(){
        ColorScheme.default().variant = .dark

        prepareSut()

        self.verify(view: sut.view)
    }

    func testForWrapInNavigationController(){
        prepareSut()
        let navWrapperController = sut.wrapInNavigationController()

        self.verify(view: navWrapperController.view)
    }
}
