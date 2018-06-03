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

extension ZMSnapshotTestCase {
    func mockUserClient() -> UserClient {
        let client = UserClient.insertNewObject(in: uiMOC)
        client.remoteIdentifier = "102030405060708090"

        client.user = ZMUser.insertNewObject(in: uiMOC)
        client.deviceClass = "tablet"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let activationDate = formatter.date(from: "2018/05/01 14:31")

        client.activationDate = activationDate

        return client
    }
}

final class ClientListViewControllerTests: ZMSnapshotTestCase {
    
    var sut: ClientListViewController!
    var mockUser: MockUser!
    var client: UserClient!
    var selfClient: UserClient!

    override func setUp() {
        super.setUp()

        let user = MockUser.mockUsers()[0]
        mockUser = MockUser(for: user)

        selfClient = self.mockUserClient()
        client = self.mockUserClient()

        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        mockUser = nil
        client = nil
        selfClient = nil

        ColorScheme.default().variant = .light

        super.tearDown()
    }

    func prepareSut(variant: ColorSchemeVariant?) {
        sut = ClientListViewController(clientsList: [client, client, client, client, client, client],
                                       selfClient: selfClient,
                                       credentials: nil, detailedView: true, showTemporary: true, variant: variant)

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

        self.verify(view: navWrapperController.view)
    }
}
